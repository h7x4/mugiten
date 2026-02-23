import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' show ExtensionSet;
import 'package:url_launcher/url_launcher.dart';

class ChangelogView extends StatelessWidget {
  const ChangelogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Changelog')),
      body: FutureBuilder<List<String>>(
        future: _fetchChangelogs(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final versions = snapshot.data!;
          return _buildChangelogList(versions);
        },
      ),
    );
  }

  Future<List<String>> _fetchChangelogs() async {
    final String assetManifest = await rootBundle.loadString(
      'AssetManifest.json',
    );

    final List<String> changelogs =
        (jsonDecode(assetManifest) as Map<String, Object?>).keys
            .where(
              (assetPath) =>
                  RegExp(r'^docs/changelog/.*\.md$').hasMatch(assetPath),
            )
            .map(
              (assetPath) => assetPath
                  .replaceFirst('docs/changelog/', '')
                  .replaceFirst('.md', ''),
            )
            .toList();

    changelogs.sort((a, b) {
      final aVersion = a
          .replaceFirst(RegExp('^v'), '')
          .replaceFirst(RegExp(r' - .*$'), '') // Replace date
          .split('.')
          .map(int.parse)
          .toList();
      final bVersion = b
          .replaceFirst(RegExp('^v'), '')
          .replaceFirst(RegExp(r' - .*$'), '') // Replace date
          .split('.')
          .map(int.parse)
          .toList();
      for (int i = 0; i < aVersion.length && i < bVersion.length; i++) {
        if (aVersion[i] != bVersion[i]) {
          return bVersion[i].compareTo(aVersion[i]);
        }
      }
      return bVersion.length.compareTo(aVersion.length);
    });

    return changelogs;
  }

  Widget _buildChangelogList(List<String> versions) {
    return ListView.builder(
      itemCount: versions.length,
      itemBuilder: (context, index) {
        final version = versions[index];
        return ListTile(
          key: ValueKey(version),
          title: Text(version),
          onTap: () {
            Navigator.push(context, _buildChangelogDetailRoute(version));
          },
        );
      },
    );
  }

  String _removeHeaders(String markdown) {
    final lines = markdown.split('\n');
    final filteredLines = lines.where((line) => !line.startsWith('# '));
    return filteredLines.join('\n');
  }

  MaterialPageRoute _buildChangelogDetailRoute(String versionAndDate) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(versionAndDate)),
        body: FutureBuilder<String>(
          future: rootBundle.loadString('docs/changelog/$versionAndDate.md'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                child: MarkdownBody(
                  data: _removeHeaders(snapshot.data!),
                  selectable: true,
                  onTapLink: (text, href, title) {
                    if (href != null && href.isNotEmpty) {
                      launchUrl(Uri.parse(href));
                    }
                  },
                  extensionSet: ExtensionSet.gitHubFlavored,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
