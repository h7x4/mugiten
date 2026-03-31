import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DataSourcesView extends StatelessWidget {
  const DataSourcesView({super.key});

  static final List<Widget> dataSources = [
    const ListTile(
      subtitle: Text(
        'Mugiten is made up of data from various sources, each with their own licenses and copyrights. '
        'Below is a list detailing the data sources used. '
        'You can find more detailed information on the data sources by following the links provided.',
      ),
    ),
    DataSource(
      title: 'JMDICT',
      url: Uri.parse(
        'https://www.edrdg.org/wiki/JMdict-EDICT_Dictionary_Project.html',
      ),
      licenseIdentifier: 'edrdg',
      licenseAssetPath: 'assets/licenses/edrdg.txt',
      copyright:
          '© James Breen and the Electronic Dictionary Research & Development Group, April 1999',
      description:
          'The EDRDG\'s Japanese-Multilingual Dictionary (JMdict) is a comprehensive dictionary containing over 200,000 entries. '
          'This is what makes up the base of the word data in this application.',
    ),
    DataSource(
      title: 'KANJIDIC2',
      url: Uri.parse('https://www.edrdg.org/wiki/KANJIDIC_Project.html'),
      licenseIdentifier: 'edrdg',
      licenseAssetPath: 'assets/licenses/edrdg.txt',
      copyright:
          '© James Breen and the Electronic Dictionary Research & Development Group, April 2008',
      description:
          'The EDRDG\'s KANJIDIC2 is a comprehensive kanji dictionary containing over 13,000 entries.'
          'This is what makes up the base of the kanji data in this application.',
    ),
    DataSource(
      title: 'RADKFILE/KRADFILE',
      url: Uri.parse('https://www.edrdg.org/krad/kradinf.html'),
      licenseIdentifier: 'edrdg',
      licenseAssetPath: 'assets/licenses/edrdg.txt',
      copyright:
          '© Michael Raine, James Breen and the Electronic Dictionary Research & Development Group, 2001/2007',
      description:
          'The EDRDG\'s RADKFILE/KRADFILE is a mapping of kanji to their radicals. '
          'This is used for searching kanji by their radicals.',
    ),
    DataSource(
      title: 'Jonathan Waller\'s JLPT resources',
      url: Uri.parse('https://www.tanos.co.uk/jlpt/'),
      licenseIdentifier: 'CC-BY-4.0',
      licenseAssetPath: 'assets/licenses/cc-by-4.0.txt',
      copyright: '© Jonathan Waller, 2011',
      description:
          'Jonathan Waller\'s JLPT resources include lists of vocabulary, kanji, and grammar points by JLPT level. '
          'This is used for the JLPT tags spread throughout the app.'
          '\n\n'
          'Do note that this data was last updated in 2011, so the accuracy of the JLPT tags might have shifted slightly over time.',
    ),
    DataSource(
      title: 'KanjiVG',
      url: Uri.parse('https://github.com/KanjiVG/kanjivg'),
      licenseIdentifier: 'CC-BY-SA-3.0',
      licenseAssetPath: 'assets/licenses/cc-by-sa-3.0.txt',
      copyright: '© Ulrich Apel, 2009-2013',
      description:
          'KanjiVG is a collection of SVG files representing the stroke order and radicals of kanji. '
          'This is used for rendering the kanji stroke order diagrams.',
    ),
  ];

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datasources')),
      body: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ListView.separated(
          itemCount: dataSources.length,
          itemBuilder: (final context, final index) => dataSources[index],
          separatorBuilder: (final context, final index) => const Divider(),
        ),
      ),
    );
  }
}

class DataSource extends StatelessWidget {
  final String title;
  final String? description;
  final Uri url;
  final String licenseIdentifier;
  final String? licenseAssetPath;
  final String copyright;

  const DataSource({
    super.key,
    required this.title,
    required this.url,
    required this.licenseIdentifier,
    required this.copyright,
    this.description,
    this.licenseAssetPath,
  });

  @override
  Widget build(final BuildContext context) {
    return ListTile(
      title: Text(title),
      titleTextStyle: Theme.of(context).textTheme.titleLarge,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () async {
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch URL')),
                  );
                }
              }
            },
            child: Text(
              url.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 20),
            Text(description!),
            const SizedBox(height: 20),
          ],
          TextButton(
            onPressed: licenseAssetPath == null
                ? null
                : () async {
                    final licenseText = await DefaultAssetBundle.of(
                      context,
                    ).loadString(licenseAssetPath!);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (final context) => Scaffold(
                          appBar: AppBar(
                            title: Text('License: $licenseIdentifier'),
                          ),
                          body: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SingleChildScrollView(
                              child: Text(licenseText),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
            child: Text('License: $licenseIdentifier'),
          ),
          const SizedBox(height: 10),
          Text(
            copyright,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
