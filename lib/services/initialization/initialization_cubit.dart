import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mugiten/database/database.dart'
    show
        DatabaseMigration,
        databaseNeedsInitialization,
        databasePath,
        extractJadbFromAssets,
        openAndMigrateDatabase,
        openDatabaseWithoutMigrations,
        readMigrationsFromAssets;
import 'package:mugiten/services/archive/v1/format.dart';
import 'package:mugiten/services/initialization/initialization_status.dart';
import 'package:path_provider/path_provider.dart';

class InitializationCubit extends Cubit<InitializationStatus> {
  final bool deleteDatabase;

  InitializationCubit(this.deleteDatabase) : super(InitializationNotStarted());

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
    if (deleteDatabase || await databaseNeedsInitialization()) {
      final String dbPath = await databasePath();
      final databaseAlreadyExists = File(dbPath).existsSync();

      late final File? tmpdirDataDump;

      if (!databaseAlreadyExists) {
        await extractJadbFromAssets(dbPath);
      } else {
        emit(BackupUserData(total: 2, progress: 1));
        final tempDir = await getTemporaryDirectory();
        final database = await openDatabaseWithoutMigrations(dbPath);

        final dataDump = await exportData(database);

        await database.close();

        tmpdirDataDump = await dataDump.copy(
          '${tempDir.path}/mugiten_data_backup.zip',
        );
        emit(BackupUserData(total: 2, progress: 2));
      }

      if (deleteDatabase) {
        await File(dbPath).delete();
        await extractJadbFromAssets(dbPath);
      }

      emit(MigrateDatabase(total: 2, progress: 1));

      final List<DatabaseMigration> migrations =
          await readMigrationsFromAssets();
      final database = await openAndMigrateDatabase(dbPath, migrations);

      emit(MigrateDatabase(total: 2, progress: 2));

      if (databaseAlreadyExists) {
        emit(RestoreUserData(total: 2, progress: 1));

        await importData(database, tmpdirDataDump!);

        emit(RestoreUserData(total: 2, progress: 2));
      }

      database.close();
    }
    emit(DatabaseUpdateFinished());

    // Initialization complete
    emit(InitializationComplete());
  }
}
