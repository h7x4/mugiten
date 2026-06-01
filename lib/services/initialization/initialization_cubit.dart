import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mugiten/services/archive/archive_dispatcher.dart'
    as archive_dispatcher;
import 'package:mugiten/services/database/database.dart'
    show databaseNeedsReset, databasePath, resetDatabase;
import 'package:mugiten/services/initialization/initialization_status.dart';
import 'package:path_provider/path_provider.dart';
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
    if (deleteDatabase || await databaseNeedsReset()) {
      final String dbPath = await databasePath();
      final bool databaseAlreadyExists = File(dbPath).existsSync();

      File? backupArchive;
      Database? migratedDatabase;

      try {
        if (databaseAlreadyExists) {
          final tempDir = await getTemporaryDirectory();
          backupArchive = File('${tempDir.path}/mugiten_data_backup.zip');
          if (backupArchive.existsSync()) {
            await backupArchive.delete();
          }

          final existingDatabase = await openDatabase(
            dbPath,
            readOnly: true,
            singleInstance: false,
          );
          try {
            await _backupUserData(existingDatabase, backupArchive);
          } finally {
            await existingDatabase.close();
          }
        }

        emit(MigrateDatabase(total: 2, progress: 1));
        migratedDatabase = await resetDatabase(dbPath);
        emit(MigrateDatabase(total: 2, progress: 2));

        if (databaseAlreadyExists) {
          await _restoreUserData(migratedDatabase, backupArchive!);
        }
      } finally {
        if (migratedDatabase != null) {
          await migratedDatabase.close();
        }

        if (backupArchive != null && backupArchive.existsSync()) {
          await backupArchive.delete();
        }
      }
    }
    emit(DatabaseUpdateFinished());

    // Initialization complete
    emit(InitializationComplete());
  }
}
