import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(final List<String> args) {
  // ignore: discarded_futures
  build(args, (final input, final output) async {
    // final archName = switch (input.config.code.targetArchitecture) {
    //   Architecture.x64 => 'x86_64',
    //   Architecture.arm64 => 'aarch64',
    //   _ => throw UnsupportedError('Unsupported target architecture $arch'),
    // };
    //

    final libtameryePath = switch (input.config.code.targetOS) {
      OS.android => Platform.environment['NIX_ANDROID_LIBTAMERYE_PATH']!,
      OS.linux => Platform.environment['NIX_NATIVE_LIBTAMERYE_PATH']!,
      _ => throw UnsupportedError(
        'Unsupported target os ${input.config.code.targetOS}',
      ),
    };

    if (!File(libtameryePath).existsSync()) {
      throw Exception('Could not find libtamerye at path: $libtameryePath.');
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
