abstract class InitializationStatus {}

class InitializationNotStarted extends InitializationStatus {}

class InitializationPending extends InitializationStatus {}

//

class CheckMLKitDigitalInkModel extends InitializationStatus {}

class DownloadMLKitDigitalInkModel extends InitializationStatus {}

class FinishDownloadMLKitDigitalInkModel extends InitializationStatus {}

//

class CheckDatabase extends InitializationStatus {}

class BackupUserData extends InitializationStatus {
  final int progress;
  final int total;

  BackupUserData({
    required this.progress,
    required this.total,
  });
}

class MigrateDatabase extends InitializationStatus {
  final int progress;
  final int total;

  MigrateDatabase({
    required this.progress,
    required this.total,
  });
}

class RestoreUserData extends InitializationStatus {
  final int progress;
  final int total;

  RestoreUserData({
    required this.progress,
    required this.total,
  });
}

class DatabaseUpdateFinished extends InitializationStatus {}

//

class InitializationComplete extends InitializationStatus {}
