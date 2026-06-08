import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(final List<String> args) {
  build(args, (input, output) async {
    // final targetOS = input.config.code.targetOS;
    // final arch = input.config.code.targetArchitecture;

    // final (osName, fileName) = switch (targetOS) {
    //   OS.linux => ('linux', 'vec0.so'),
    //   OS.macOS => ('macos', 'vec0.dylib'),
    //   OS.windows => ('windows', 'vec0.dll'),
    //   _ => throw UnsupportedError('Unsupported target os $targetOS'),
    // };
    // final archName = switch (arch) {
    //   Architecture.x64 => 'x86_64',
    //   Architecture.arm64 => 'aarch64',
    //   _ => throw UnsupportedError('Unsupported target architecture $arch'),
    // };

    final libtameryePath = Platform.environment['NIX_LIBTAMERYE_PATH'] ?? 'assets/libtamerye.so';
    if (!File(libtameryePath).existsSync()) {
      throw Exception('Could not find libtamerye at path: $libtameryePath. Please set the NIX_LIBTAMERYE_PATH environment variable to the correct path.');
    }

    final targetFilePath = input.outputDirectory.resolve('libtamerye.so');
    final targetFile = File(targetFilePath.toFilePath());
    await targetFile.create(recursive: true);
    await File(libtameryePath).copy(targetFile.path);

    output.assets.code.add(
      CodeAsset(
        package: 'mugiten',
        name: 'libtamerye.dart',
        file: targetFilePath,
        linkMode: DynamicLoadingBundled(),
      ),
    );
  });
}
