import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:mdi/mdi.dart';
import 'package:mugiten/components/common/denshi_jisho_background.dart';
import 'package:mugiten/main.dart';
import 'package:mugiten/models/history_entry.dart';
import 'package:mugiten/models/library_list.dart';
import 'package:mugiten/routing/routes.dart';
import 'package:mugiten/services/archive/archive_controller.dart';
import 'package:mugiten/services/archive/v1/format.dart';
import 'package:mugiten/services/database/database.dart';
import 'package:mugiten/services/snackbar.dart';
import 'package:mugiten/settings.dart';
import 'package:mugiten/theme.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  Future<bool> confirm(
    final BuildContext context, {
    required final Widget content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (final context) => AlertDialog(
            content: content,
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> clearHistory(final BuildContext context) async {
    final historyCount = await GetIt.instance
        .get<Database>()
        .historyEntryAmount();

    if (!context.mounted) return;

    final bool userIsSure = await confirm(
      context,
      content: Text(
        'Are you sure that you want to clear all $historyCount entries in history?',
      ),
    );
    if (!userIsSure) return;

    await GetIt.instance.get<Database>().delete(HistoryTableNames.historyEntry);

    if (!context.mounted) return;

    showSnackbar(context, 'Cleared history');
  }

  Future<void> changeFont(final BuildContext context) async {
    final int? i = await _chooseFromList(
      list: [for (final font in JapaneseFontChoice.values) font.name],
      chosen: japaneseFont.value.index,
    )(context);
    if (i != null) {
      setState(() {
        japaneseFont.value = JapaneseFontChoice.values[i];
      });
    }
  }

  Future<void> changeQuickAddLibraryList(final BuildContext context) async {
    final libraryLists = await GetIt.instance
        .get<Database>()
        .libraryListGetLists();
    if (!context.mounted) return;
    final int? i = await _chooseFromList(
      list: ['None', ...libraryLists.map((final e) => e.name)],
      chosen: quickAddLibraryList.value == null
          ? 0
          : libraryLists.indexWhere(
                  (final l) => l.name == quickAddLibraryList.value,
                ) +
                1,
      title: 'Choose library for quick add',
    )(context);
    if (i != null) {
      setState(() {
        quickAddLibraryList.value = i == 0 ? null : libraryLists[i - 1].name;
      });
    }
  }

  Future<void> exportHandler(final BuildContext context) async {
    final tmpfile = File(
      Directory.systemTemp
          .createTempSync('mugiten_data_')
          .uri
          .resolve('mugiten_data.zip')
          .toFilePath(),
    );

    await BlocProvider.of<ArchiveController>(context).startExport(tmpfile);

    final saveFile = await FilePicker.saveFile(
      dialogTitle: 'Export data',
      fileName: getExportFileNameNoSuffix(),
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: tmpfile.readAsBytesSync(),
    );

    if (!context.mounted) return;

    if (saveFile == null) {
      showSnackbar(context, 'Export cancelled');
    } else {
      showSnackbar(context, 'Exported data to $saveFile');
    }
  }

  Future<void> importHandler(final BuildContext context) async {
    final saveFile = await FilePicker.pickFiles(
      dialogTitle: 'Import data',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (saveFile == null || saveFile.files.isEmpty) {
      return;
    }

    assert(saveFile.files.length == 1, 'Multiple files selected for import');

    final filepath = saveFile.files.first.path;

    if (!context.mounted) return;

    await BlocProvider.of<ArchiveController>(
      context,
    ).startImport(File(filepath!));
  }

  Future<int?> Function(BuildContext) _chooseFromList({
    required final List<String> list,
    final int? chosen,
    final String? title,
  }) =>
      (final context) => Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (final context) => Scaffold(
            appBar: AppBar(title: title == null ? null : Text(title)),
            body: DenshiJishoBackground(
              child: ListView.builder(
                itemBuilder: (final context, final i) => ListTile(
                  title: Text(list[i]),
                  trailing: (chosen != null && chosen == i)
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, i),
                ),
                itemCount: list.length,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<ArchiveController, ArchiveState>(
        builder: (final context, final archiveState) => SettingsList(
          lightTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          ),
          darkTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
            titleTextColor: mugitenWheatBackground,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          sections: _sections(context, archiveState),
        ),
      );

  List<SettingsSection> _sections(
    final BuildContext context,
    final ArchiveState archiveState,
  ) => [
    SettingsSection(
      title: const Text('Dictionary'),
      tiles: <SettingsTile>[
        SettingsTile.switchTile(
          title: const Text('Romaji mode'),
          description: const Text(
            'Display romaji instead of kana for word readings',
          ),
          leading: const Icon(Mdi.alphabetical),
          onToggle: (final b) => setState(() => romajiEnabled.value = b),
          initialValue: romajiEnabled.value,
          activeSwitchColor: mugitenWheatBackground,
        ),
        SettingsTile(
          title: const Text('Japanese font'),
          leading: const Icon(Icons.format_size),
          onPressed: changeFont,
          trailing: Text(japaneseFont.value.name),
          // subtitle:
          //     'Which font to use for japanese text. This might be useful if your phone shows kanji with a Chinese font.',
          // subtitleMaxLines: 3,
        ),

        SettingsTile.switchTile(
          title: const Text('Emphasize search matches'),
          description: const Text(
            'Underline the part of the word that matched the search query.',
          ),
          leading: const Icon(Icons.horizontal_rule),
          onToggle: (final b) => setState(() => emphasizeMatchSpans.value = b),
          initialValue: emphasizeMatchSpans.value,
          activeSwitchColor: mugitenWheatBackground,
        ),
        SettingsTile(
          title: const Text('Quick Add Library List'),
          leading: const Icon(Icons.bookmark),
          onPressed: changeQuickAddLibraryList,
          trailing: Text(quickAddLibraryList.value ?? 'None'),
          description: const Text(
            'Which library to add words on double tapping in search results',
          ),
        ),
      ],
    ),
    SettingsSection(
      title: const Text('Theme'),
      tiles: <SettingsTile>[
        SettingsTile.switchTile(
          title: const Text('Automatic theme'),
          description: const Text('Let theme be determined by system'),
          leading: const Icon(Icons.brightness_auto),
          onToggle: (final b) {
            setState(() => autoThemeEnabled.value = b);
            GetIt.instance.get<ThemeController>().updateThemeMode();
          },
          initialValue: autoThemeEnabled.value,
          activeSwitchColor: mugitenWheatBackground,
        ),
        SettingsTile.switchTile(
          title: const Text('Dark Theme'),
          leading: const Icon(Icons.dark_mode),
          onToggle: (final b) {
            setState(() => darkThemeEnabled.value = b);
            GetIt.instance.get<ThemeController>().updateThemeMode();
          },
          initialValue: darkThemeEnabled.value,
          enabled: !autoThemeEnabled.value,
          activeSwitchColor: mugitenWheatBackground,
        ),
      ],
    ),
    SettingsSection(
      title: const Text('Data'),
      tiles: <SettingsTile>[
        SettingsTile(
          enabled: archiveState is IdleState,
          leading: const Icon(Icons.file_upload),
          title: const Text('Import Data'),
          description: const Text('Import user data from a file'),
          onPressed: importHandler,
          trailing: archiveState is ImportingState
              ? CircularProgressIndicator(
                  value: archiveState.total > 0
                      ? archiveState.progress / archiveState.total
                      : null,
                )
              : null,
          value: archiveState is ImportingState
              ? Text(archiveState.status)
              : null,
        ),
        SettingsTile(
          enabled: archiveState is IdleState,
          leading: const Icon(Icons.file_download),
          title: const Text('Export Data'),
          description: const Text('Export user data to a file'),
          onPressed: exportHandler,
          trailing: archiveState is ExportingState
              ? CircularProgressIndicator(
                  value: archiveState.total > 0
                      ? archiveState.progress / archiveState.total
                      : null,
                )
              : null,
          value: archiveState is ExportingState
              ? Text(archiveState.status)
              : null,
        ),
        SettingsTile(
          enabled: archiveState is IdleState,
          leading: const Icon(Icons.delete),
          title: const Text(
            'Clear History',
            style: TextStyle(color: Colors.red),
          ),
          description: const Text('Delete all search history'),
          onPressed: clearHistory,
        ),
      ],
    ),
    SettingsSection(
      title: const Text('Misc'),
      tiles: <SettingsTile>[
        SettingsTile.switchTile(
          leading: const Icon(Mdi.incognito),
          title: const Text('Disable history tracking'),
          description: const Text(
            'Useful for reviewing search history without creating clutter',
          ),
          onToggle: (final b) => setState(() => incognitoModeEnabled.value = b),
          initialValue: incognitoModeEnabled.value,
          activeSwitchColor: mugitenWheatBackground,
        ),
        SettingsTile.switchTile(
          leading: const Icon(Icons.close_fullscreen),
          title: const Text('Shrink kanji drawing board'),
          description: const Text(
            'Useful if you keep accidentally activating system gestures',
          ),
          onToggle: (final b) =>
              setState(() => reduceKanjiDrawingBoardSize.value = b),
          initialValue: reduceKanjiDrawingBoardSize.value,
          activeSwitchColor: mugitenWheatBackground,
        ),
        SettingsTile(
          enabled: archiveState is IdleState,
          leading: const Icon(Icons.cached),
          title: const Text(
            'Reinitialize application',
            style: TextStyle(color: Colors.red),
          ),
          description: const Text('Reinstall dictionary data and reset state'),
          onPressed: (_) async {
            if (!await confirm(
              context,
              content: const Text(
                'Are you sure you want to reinitialize the application?'
                '\n\n'
                'Note that this will attempt not to delete user data, but it is recommended to backup data before proceeding.',
              ),
            )) {
              return;
            }

            GetIt.instance.get<Database>().close();
            GetIt.instance.reset();
            runInitializationScreen(true);
          },
        ),
      ],
    ),
    SettingsSection(
      title: const Text('Info'),
      tiles: <SettingsTile>[
        SettingsTile(
          leading: const Icon(Icons.copyright),
          title: const Text('About'),
          description: const Text('Info about Mugiten and its dependencies'),
          onPressed: (final c) =>
              Navigator.pushNamed(context, Routes.aboutLicenses),
        ),
        SettingsTile(
          leading: const Icon(Mdi.database),
          title: const Text('Datasources'),
          description: const Text('List of datasources used in Mugiten'),
          onPressed: (final c) =>
              Navigator.pushNamed(context, Routes.aboutDatasources),
        ),
        SettingsTile(
          leading: const Icon(Icons.notes),
          title: const Text('Changelog'),
          description: const Text(
            'See what changed between different versions of the application',
          ),
          onPressed: (final c) =>
              Navigator.pushNamed(context, Routes.aboutChangelog),
        ),
        SettingsTile(
          leading: const Icon(Mdi.git),
          title: const Text('Repository'),
          description: const Text('https://git.pvv.ntnu.no/mugiten'),
          onPressed: (final c) =>
              launchUrl(Uri.parse('https://git.pvv.ntnu.no/mugiten')),
        ),
      ],
    ),
  ];
}
