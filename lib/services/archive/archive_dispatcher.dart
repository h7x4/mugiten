import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:mugiten/services/archive/sql/export_db_v1.dart' as schema_v1;
import 'package:mugiten/services/archive/sql/export_db_v2.dart' as schema_v2;
import 'package:mugiten/services/archive/v1/format.dart' as archive_v1;
import 'package:mugiten/services/archive/v2/format.dart' as archive_v2;
import 'package:sqflite/sqlite_api.dart';

class ArchiveTransferEvent {
  final String type;
  final int progress;
  final int total;

  final String? name;
  final int? subProgress;
  final int? subTotal;

  const ArchiveTransferEvent({
    required this.type,
    required this.progress,
    required this.total,
    this.name,
    this.subProgress,
    this.subTotal,
  }) : assert(
         progress > 0 && total > 0 && progress <= total,
         '0 < progress <= total must hold',
       ),
       assert(
         (subProgress == null && subTotal == null) ||
             (subProgress != null &&
                 subTotal != null &&
                 subProgress > 0 &&
                 subTotal > 0 &&
                 subProgress <= subTotal),
         'subProgress and subTotal must both be null or both be positive integers with subProgress <= subTotal',
       );

  bool get hasSubProgress => subProgress != null && subTotal != null;

  factory ArchiveTransferEvent.fromArchiveV2StreamEvent(
    final archive_v2.ArchiveV2StreamEvent event,
  ) => ArchiveTransferEvent(
    type: event.type,
    progress: event.progress,
    total: event.total,
    name: event.name,
    subProgress: event.subProgress,
    subTotal: event.subTotal,
  );

  @override
  String toString() {
    if (!hasSubProgress) {
      return 'ArchiveTransferEvent(type: $type, progress: $progress/$total)';
    }

    return 'ArchiveTransferEvent(type: $type, name: $name, progress: $progress/$total, subProgress: $subProgress/$subTotal)';
  }
}

abstract interface class SchemaArchiveExportStrategy {
  int get schemaVersion;
  int get archiveFormatVersion;

  Future<int> totalAmountOfChunks(final Database db);

  Stream<ArchiveTransferEvent> export(
    final Database db,
    final File archiveFile,
  );
}

abstract base class ArchiveV2SchemaExportStrategy
    implements SchemaArchiveExportStrategy {
  const ArchiveV2SchemaExportStrategy();

  archive_v2.ArchiveV2ExportAdapter get adapter;

  @override
  int get archiveFormatVersion => archive_v2.expectedDataFormatVersion;

  @override
  Future<int> totalAmountOfChunks(final Database db) {
    return archive_v2.totalAmountOfChunksFromDatabaseWithAdapter(
      db,
      adapter: adapter,
    );
  }

  @override
  Stream<ArchiveTransferEvent> export(
    final Database db,
    final File archiveFile,
  ) {
    return archive_v2
        .exportDataWithAdapter(db, archiveFile, adapter: adapter)
        .map(ArchiveTransferEvent.fromArchiveV2StreamEvent);
  }
}

final class SchemaV1ToArchiveV2ExportStrategy
    extends ArchiveV2SchemaExportStrategy {
  const SchemaV1ToArchiveV2ExportStrategy();

  @override
  int get schemaVersion => 1;

  @override
  archive_v2.ArchiveV2ExportAdapter get adapter =>
      schema_v1.archiveExportAdapter;
}

final class SchemaV2ToArchiveV2ExportStrategy
    extends ArchiveV2SchemaExportStrategy {
  const SchemaV2ToArchiveV2ExportStrategy();

  @override
  int get schemaVersion => 2;

  @override
  archive_v2.ArchiveV2ExportAdapter get adapter =>
      schema_v2.archiveExportAdapter;
}

abstract interface class ArchiveImportStrategy {
  int get archiveFormatVersion;

  Stream<ArchiveTransferEvent> importArchive(
    final DatabaseExecutor db,
    final File archiveFile,
  );
}

final class ArchiveV1ImportStrategy implements ArchiveImportStrategy {
  const ArchiveV1ImportStrategy();

  @override
  int get archiveFormatVersion => archive_v1.expectedDataFormatVersion;

  @override
  Stream<ArchiveTransferEvent> importArchive(
    final DatabaseExecutor db,
    final File archiveFile,
  ) async* {
    if (db is! Database) {
      throw ArgumentError.value(
        db,
        'db',
        'Archive V1 import requires a Database instance',
      );
    }

    await archive_v1.importData(db, archiveFile);
  }
}

final class ArchiveV2ImportStrategy implements ArchiveImportStrategy {
  const ArchiveV2ImportStrategy();

  @override
  int get archiveFormatVersion => archive_v2.expectedDataFormatVersion;

  @override
  Stream<ArchiveTransferEvent> importArchive(
    final DatabaseExecutor db,
    final File archiveFile,
  ) {
    return archive_v2
        .importData(db, archiveFile)
        .map(ArchiveTransferEvent.fromArchiveV2StreamEvent);
  }
}

final Map<int, SchemaArchiveExportStrategy> _latestExportStrategyBySchema = {
  1: const SchemaV1ToArchiveV2ExportStrategy(),
  2: const SchemaV2ToArchiveV2ExportStrategy(),
};

final Map<int, ArchiveImportStrategy> _importStrategiesByArchiveVersion = {
  archive_v1.expectedDataFormatVersion: const ArchiveV1ImportStrategy(),
  archive_v2.expectedDataFormatVersion: const ArchiveV2ImportStrategy(),
};

Future<int?> _detectLegacySchemaVersionFromTables(
  final DatabaseExecutor db,
) async {
  final columns = await db.rawQuery('PRAGMA table_info("Mugiten_LibraryList")');
  final columnNames = columns
      .map((final row) => row['name'])
      .whereType<String>()
      .toSet();

  if (columnNames.contains('orderNum')) {
    return 2;
  }
  if (columnNames.contains('prevList')) {
    return 1;
  }

  return null;
}

/// Extracts Mugiten's schema version from SQLite's `user_version`.
///
/// Older development databases may still store a plain integer in
/// `user_version` instead of the packed Mugiten+jadb version. Some of those
/// databases also have an incorrect plain value, so legacy values are validated
/// against the actual Mugiten tables before being trusted.
Future<int> detectMugitenSchemaVersion(final Database db) async {
  final userVersion = await db.getVersion();

  if (userVersion > 0xFFFF) {
    return userVersion >> 16;
  }

  final inferredVersion = await _detectLegacySchemaVersionFromTables(db);
  return inferredVersion ?? userVersion;
}

SchemaArchiveExportStrategy _exportStrategyForSchema(final int schemaVersion) {
  final strategy = _latestExportStrategyBySchema[schemaVersion];
  if (strategy == null) {
    throw UnsupportedError(
      'No archive export strategy registered for Mugiten schema version $schemaVersion',
    );
  }

  return strategy;
}

Future<int> totalAmountOfChunksFromDatabase(final Database db) async {
  final schemaVersion = await detectMugitenSchemaVersion(db);
  final strategy = _exportStrategyForSchema(schemaVersion);
  return strategy.totalAmountOfChunks(db);
}

Future<int> totalAmountOfChunksFromArchive(final File archiveFile) async {
  final archiveVersion = await detectArchiveVersion(archiveFile);

  return switch (archiveVersion) {
    archive_v2.expectedDataFormatVersion =>
      archive_v2.totalAmountOfChunksFromArchive(archiveFile),
    archive_v1.expectedDataFormatVersion => 1,
    _ => throw UnsupportedError(
      'No archive chunk counter registered for archive version $archiveVersion',
    ),
  };
}

Future<int> detectArchiveVersion(final File archiveFile) async {
  if (!archiveFile.existsSync()) {
    throw Exception('Archive file does not exist: ${archiveFile.path}');
  }

  final archive = ZipDecoder().decodeStream(InputFileStream(archiveFile.path));

  try {
    for (final file in archive) {
      if (!file.isFile || file.name != 'version.txt') {
        continue;
      }

      final bytes = file.readBytes();
      if (bytes == null) {
        throw FormatException(
          'Archive version file is empty: ${archiveFile.path}',
        );
      }

      return int.parse(String.fromCharCodes(bytes).trim());
    }
  } finally {
    for (final file in archive) {
      file.closeSync();
    }
  }

  return archive_v1.expectedDataFormatVersion;
}

ArchiveImportStrategy _importStrategyForArchiveVersion(
  final int archiveVersion,
) {
  final strategy = _importStrategiesByArchiveVersion[archiveVersion];
  if (strategy == null) {
    throw UnsupportedError(
      'No archive import strategy registered for archive version $archiveVersion',
    );
  }

  return strategy;
}

/// Exports a migration backup using the newest archive format that the source
/// database schema supports.
Stream<ArchiveTransferEvent> exportBackupArchive(
  final Database db,
  final File archiveFile,
) async* {
  final schemaVersion = await detectMugitenSchemaVersion(db);
  final strategy = _exportStrategyForSchema(schemaVersion);

  yield* strategy.export(db, archiveFile);
}

/// Imports an archive into the latest database schema.
///
/// Migration backups are normally written using the latest archive format, but
/// older archive versions are also accepted here so that old user archives can
/// be restored through the same dispatcher.
Stream<ArchiveTransferEvent> importBackupArchive(
  final DatabaseExecutor db,
  final File archiveFile,
) async* {
  final archiveVersion = await detectArchiveVersion(archiveFile);
  final strategy = _importStrategyForArchiveVersion(archiveVersion);

  yield* strategy.importArchive(db, archiveFile);
}
