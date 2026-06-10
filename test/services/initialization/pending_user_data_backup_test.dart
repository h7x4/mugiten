import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mugiten/services/initialization/pending_user_data_backup.dart';

import '../../testutils.dart';

void main() {
  late Directory tempDir;
  late PendingUserDataBackup backup;

  setUp(() async {
    tempDir = await testTmpdir();
    backup = PendingUserDataBackup(
      Directory(tempDir.uri.resolve('pending_user_data_backup/').toFilePath()),
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('backup is only pending when both archive and marker exist', () async {
    expect(backup.isPending, isFalse);

    await backup.ensureDirectoryExists();
    await backup.archiveFile.create();
    expect(backup.isPending, isFalse);

    await backup.markReady();
    expect(backup.isPending, isTrue);
  });

  test('markReady writes marker metadata', () async {
    await backup.markReady();

    final markerContent =
        jsonDecode(await backup.markerFile.readAsString())
            as Map<String, Object?>;

    expect(markerContent['archiveFileName'], 'user_data_backup.zip');
    expect(markerContent['createdAt'], isA<String>());
  });

  test(
    'clear removes marker, archive, temporary archive and directory',
    () async {
      await backup.ensureDirectoryExists();
      await backup.archiveFile.create();
      await backup.temporaryArchiveFile.create();
      await backup.markReady();

      await backup.clear();

      expect(backup.markerFile.existsSync(), isFalse);
      expect(backup.archiveFile.existsSync(), isFalse);
      expect(backup.temporaryArchiveFile.existsSync(), isFalse);
      expect(backup.directory.existsSync(), isFalse);
    },
  );
}
