import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mugiten/services/archive/archive_dispatcher.dart'
    as archive_dispatcher;
import 'package:mugiten/services/database/database.dart'
    show databaseNeedsReset, databasePath, resetDatabase;
import 'package:mugiten/services/initialization/initialization_status.dart';
import 'package:mugiten/services/initialization/pending_user_data_backup.dart';
import 'package:sqflite/sqflite.dart';

class InitializationCubit extends Cubit<InitializationStatus> {
  final bool deleteDatabase;

  InitializationCubit(this.deleteDatabase) : super(InitializationNotStarted());

  Future<void> _backupUserData(
    final Database database,
    final File archiveFile,
  ) async {
    final int rawTotal = await archive_dispatcher
        .totalAmountOfChunksFromDatabase(database);
    final int total = rawTotal > 0 ? rawTotal : 1;

    emit(BackupUserData(progress: 0, total: total));

    int progress = 0;
    await for (final _ in archive_dispatcher.exportBackupArchive(
      database,
      archiveFile,
    )) {
      progress += 1;
      emit(
        BackupUserData(
          progress: progress <= total ? progress : total,
          total: total,
        ),
      );
    }

    emit(BackupUserData(progress: total, total: total));
  }

  Future<PendingUserDataBackup> _createPendingUserDataBackup(
    final Database database,
  ) async {
    final backup = await PendingUserDataBackup.locate();
    await backup.clear();
    await backup.ensureDirectoryExists();

    try {
      await _backupUserData(database, backup.temporaryArchiveFile);
      await backup.temporaryArchiveFile.rename(backup.archiveFile.path);
      await backup.markReady();
      return backup;
    } catch (_) {
      if (backup.temporaryArchiveFile.existsSync()) {
        await backup.temporaryArchiveFile.delete();
      }
      rethrow;
    }
  }

  Future<void> _restoreUserData(
    final Database database,
    final File archiveFile,
  ) async {
    final int rawTotal = await archive_dispatcher
        .totalAmountOfChunksFromArchive(archiveFile);
    final int total = rawTotal > 0 ? rawTotal : 1;

    emit(RestoreUserData(progress: 0, total: total));

    int progress = 0;
    await for (final _ in archive_dispatcher.importBackupArchive(
      database,
      archiveFile,
    )) {
      progress += 1;
      emit(
        RestoreUserData(
          progress: progress <= total ? progress : total,
          total: total,
        ),
      );
    }

    emit(RestoreUserData(progress: total, total: total));
  }

  Future<void> start() async {
    emit(InitializationPending());

    emit(CheckMLKitDigitalInkModel());
    final modelManager = DigitalInkRecognizerModelManager();
    final isDownloaded = await modelManager.isModelDownloaded('ja');

    if (!isDownloaded) {
      emit(DownloadMLKitDigitalInkModel());
      await modelManager.downloadModel('ja');
    }

    emit(FinishDownloadMLKitDigitalInkModel());

    emit(CheckDatabase());
    PendingUserDataBackup? backup = await getPendingUserDataBackup();
    final bool needsDatabaseReset =
        deleteDatabase || backup != null || await databaseNeedsReset();
    if (needsDatabaseReset) {
      final String dbPath = await databasePath();
      final bool databaseAlreadyExists = File(dbPath).existsSync();

      Database? migratedDatabase;

      try {
        if (backup != null) {
          await archive_dispatcher.detectArchiveVersion(backup.archiveFile);
        } else if (databaseAlreadyExists) {
          final existingDatabase = await openDatabase(
            dbPath,
            readOnly: true,
            singleInstance: false,
          );
          try {
            backup = await _createPendingUserDataBackup(existingDatabase);
          } finally {
            await existingDatabase.close();
          }
        }

        emit(MigrateDatabase(total: 2, progress: 1));
        migratedDatabase = await resetDatabase(dbPath);
        emit(MigrateDatabase(total: 2, progress: 2));

        if (backup != null) {
          await _restoreUserData(migratedDatabase, backup.archiveFile);
          await backup.clear();
        }
      } finally {
        if (migratedDatabase != null) {
          await migratedDatabase.close();
        }
      }
    }
    emit(DatabaseUpdateFinished());

    // Initialization complete
    emit(InitializationComplete());
  }
}
