import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const String _backupDirectoryName = 'mugiten_initialization_backup';
const String _backupArchiveFileName = 'user_data_backup.zip';
const String _temporaryBackupArchiveFileName = 'user_data_backup.tmp.zip';
const String _pendingBackupMarkerFileName = 'pending_restore.json';

class PendingUserDataBackup {
  final Directory directory;

  const PendingUserDataBackup(this.directory);

  static Future<PendingUserDataBackup> locate() async {
    final tempDir = await getTemporaryDirectory();
    return PendingUserDataBackup(
      Directory(path.join(tempDir.path, _backupDirectoryName)),
    );
  }

  File get archiveFile =>
      File(path.join(directory.path, _backupArchiveFileName));

  File get temporaryArchiveFile =>
      File(path.join(directory.path, _temporaryBackupArchiveFileName));

  File get markerFile =>
      File(path.join(directory.path, _pendingBackupMarkerFileName));

  bool get isPending => markerFile.existsSync() && archiveFile.existsSync();

  Future<void> ensureDirectoryExists() => directory.create(recursive: true);

  Future<void> markReady() async {
    await ensureDirectoryExists();
    await markerFile.writeAsString(
      jsonEncode({
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'archiveFileName': _backupArchiveFileName,
      }),
    );
  }

  Future<void> clear() async {
    if (markerFile.existsSync()) {
      await markerFile.delete();
    }
    if (archiveFile.existsSync()) {
      await archiveFile.delete();
    }
    if (temporaryArchiveFile.existsSync()) {
      await temporaryArchiveFile.delete();
    }
    if (directory.existsSync() && directory.listSync().isEmpty) {
      await directory.delete();
    }
  }
}

Future<PendingUserDataBackup?> getPendingUserDataBackup() async {
  final backup = await PendingUserDataBackup.locate();
  return backup.isPending ? backup : null;
}

Future<bool> hasPendingUserDataBackup() async {
  return (await getPendingUserDataBackup()) != null;
}
