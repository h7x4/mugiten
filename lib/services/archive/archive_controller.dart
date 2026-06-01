import 'dart:core';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/services/archive/archive_dispatcher.dart';
import 'package:sqflite/sqlite_api.dart';

/// The archive controller is a singleton-like class that keeps track of whether the
/// application is currently importing or exporting data. This is used to prevent
/// the user from starting multiple imports/exports at the same time, as well as
/// to keep the state available when the user navigates away from the widget that
/// started the import/export process.
class ArchiveController extends Cubit<ArchiveState> {
  ArchiveController() : super(const IdleState());

  Future<void> startImport(final File archive) async {
    if (state is! IdleState) {
      throw StateError('Already importing or exporting data');
    }

    emit(
      const ImportingState(progress: 0, total: 0, status: 'Counting data...'),
    );

    final database = GetIt.instance.get<Database>();

    final totalChunks = await totalAmountOfChunksFromArchive(archive);

    emit(
      ImportingState(
        progress: 0,
        total: totalChunks,
        status: 'Starting import...',
      ),
    );

    int i = 0;
    await for (final event in importBackupArchive(database, archive)) {
      i += 1;
      final status = switch (event.type) {
        'history' => 'Importing history: ${event.progress}/${event.total}',
        'library' =>
          'Importing library list "${event.name}": ${event.subProgress}/${event.subTotal}',
        _ => 'Importing unknown data: ${event.progress}/${event.total}',
      };

      emit(ImportingState(progress: i, total: totalChunks, status: status));
    }

    emit(const IdleState());
  }

  Future<void> startExport(final File archive) async {
    if (state is! IdleState) {
      throw StateError('Already importing or exporting data');
    }

    emit(
      const ExportingState(progress: 0, total: 0, status: 'Counting data...'),
    );

    final database = GetIt.instance.get<Database>();

    final totalChunks = await totalAmountOfChunksFromDatabase(database);

    emit(
      ExportingState(
        progress: 0,
        total: totalChunks,
        status: 'Starting export...',
      ),
    );

    int i = 0;
    await for (final event in exportBackupArchive(database, archive)) {
      i += 1;
      final status = switch (event.type) {
        'history' => 'Exporting history: ${event.progress}/${event.total}',
        'library' =>
          'Exporting library list "${event.name}": ${event.subProgress}/${event.subTotal}',
        _ => 'Exporting unknown data: ${event.progress}/${event.total}',
      };

      emit(ExportingState(progress: i, total: totalChunks, status: status));
    }

    emit(const IdleState());
  }
}

abstract class ArchiveState {
  const ArchiveState();
}

class IdleState extends ArchiveState {
  const IdleState();
}

class ImportingState extends ArchiveState {
  final int progress;
  final int total;
  final String status;

  const ImportingState({
    required this.progress,
    required this.total,
    required this.status,
  });
}

class ExportingState extends ArchiveState {
  final int progress;
  final int total;
  final String status;

  const ExportingState({
    required this.progress,
    required this.total,
    required this.status,
  });
}
