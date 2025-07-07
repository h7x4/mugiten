import 'dart:io';
import 'dart:developer';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:mdi/mdi.dart';
import 'package:mugiten/bloc/theme/theme_bloc.dart';
import 'package:mugiten/components/common/denshi_jisho_background.dart';
import 'package:mugiten/database/database.dart';
import 'package:mugiten/database/history/table_names.dart';
import 'package:mugiten/models/history/history_entry.dart';
import 'package:mugiten/models/library/library_list.dart';
import 'package:mugiten/routing/routes.dart';
import 'package:mugiten/services/data_export_import.dart';
import 'package:mugiten/services/snackbar.dart';
import 'package:mugiten/settings.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final Database db = GetIt.instance.get<Database>();
  bool dataExportIsLoading = false;
  bool dataImportIsLoading = false;

  // Future<bool?> assertExternalStorePermissions() async {
  //   final permissionStatus = await Permission.storage.status;

  //   if (permissionStatus.isGranted) return null;

  //   final permissionResult = await Permission.storage.request();

  //   return permissionResult.isGranted;
  // }

  Future<void> clearHistory(context) async {
    final historyCount = await HistoryEntry.amountOfEntries();

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

  Future<void> clearFavourites(context) async {
    final favouritesCount = await LibraryList.favourites.length;

    if (!context.mounted) return;

    final bool userIsSure = await confirm(
      context,
      content: Text(
        'Are you sure that you want to clear all $favouritesCount entries in favourites?',
      ),
    );
    if (!userIsSure) return;

    await LibraryList.favourites.deleteAllEntries();

    if (!context.mounted) return;

    showSnackbar(context, 'Cleared favourites');
  }

  Future<void> clearAll(context) async {
    int? historyCount;
    int? libraryCount;
    try {
      historyCount = await HistoryEntry.amountOfEntries();
      libraryCount = await LibraryList.libraryCount();
    } catch (e) {
      log('Error getting counts: $e');
    }

    final bool userIsSure = await confirm(
      context,
      content: Text(
        'Are you sure you want to delete ${historyCount ?? '?'} history entries '
        'and ${libraryCount ?? '?'} libraries?',
      ),
    );

    if (!userIsSure) return;
    await resetDatabase();

    if (!context.mounted) return;

    showSnackbar(
      context,
      'Database reset successfully.',
    );
  }

  // ignore: avoid_positional_boolean_parameters
  void toggleAutoTheme(bool b) {
    final bool newThemeIsDark = b
        ? WidgetsBinding.instance.window.platformBrightness == Brightness.dark
        : darkThemeEnabled;

    BlocProvider.of<ThemeBloc>(context)
        .add(SetTheme(themeIsDark: newThemeIsDark));

    setState(() => autoThemeEnabled = b);
  }

  Future<void> changeFont(context) async {
    final int? i = await _chooseFromList(
      list: [for (final font in JapaneseFont.values) font.name],
      chosen: japaneseFont.index,
    )(context);
    if (i != null) {
      setState(() {
        japaneseFont = JapaneseFont.values[i];
      });
    }
  }

  Future<void> exportHandler(context) async {
    late final File zipfile;
    try {
      setState(() => dataExportIsLoading = true);
      final db = GetIt.instance.get<Database>();
      zipfile = await exportData(db);
    } catch (e) {
      if (!context.mounted) return;
      showSnackbar(context, 'Error exporting data: $e');
    } finally {
      setState(() => dataExportIsLoading = false);
    }

    final saveFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Export data',
      fileName: getExportFileNameNoSuffix(),
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: zipfile.readAsBytesSync(),
    );

    if (!context.mounted) return;
    showSnackbar(context, 'Exported data to $saveFile');
  }

  Future<void> importHandler(context) async {
    final saveFile = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import data',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (saveFile == null || saveFile.files.isEmpty) {
      return;
    }

    assert(saveFile.files.length == 1);

    final filepath = saveFile.files.first.path;

    final db = GetIt.instance.get<Database>();

    try {
      setState(() => dataImportIsLoading = true);
      await importData(db, File(filepath!));
      if (!context.mounted) return;
      showSnackbar(context, 'Data imported successfully');
    } catch (e) {
      if (!context.mounted) return;
      showSnackbar(context, 'Error importing data: $e');
    } finally {
      setState(() => dataImportIsLoading = false);
    }
  }

  Future<int?> Function(BuildContext) _chooseFromList({
    required List<String> list,
    int? chosen,
    String? title,
  }) =>
      (context) => Navigator.push<int>(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: title == null ? null : Text(title)),
                body: DenshiJishoBackground(
                  child: ListView.builder(
                    itemBuilder: (context, i) => ListTile(
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
  Widget build(BuildContext context) => BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          final TextStyle titleTextStyle = TextStyle(
            color: state is DarkThemeState
                ? AppTheme.mugitenWheat.background
                : null,
          );

          return SettingsList(
            // backgroundColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            sections: <SettingsSection>[
              SettingsSection(
                title: Text('Dictionary', style: titleTextStyle),
                // titleTextStyle: _titleTextStyle,
                tiles: <SettingsTile>[
                  SettingsTile.switchTile(
                    title: const Text('Use romaji'),
                    leading: const Icon(Mdi.alphabetical),
                    onToggle: (b) => setState(() => romajiEnabled = b),
                    initialValue: romajiEnabled,
                    // theme: theme,
                    activeSwitchColor: AppTheme.mugitenWheat.background,
                  ),
                  SettingsTile(
                    title: const Text('Japanese font'),
                    leading: const Icon(Icons.format_size),
                    onPressed: changeFont,
                    // theme: theme,
                    trailing: Text(japaneseFont.name),
                    // subtitle:
                    //     'Which font to use for japanese text. This might be useful if your phone shows kanji with a Chinese font.',
                    // subtitleMaxLines: 3,
                  ),
                ],
              ),
              SettingsSection(
                title: Text('Theme', style: titleTextStyle),
                tiles: <SettingsTile>[
                  SettingsTile.switchTile(
                    title: const Text('Automatic theme'),
                    leading: const Icon(Icons.brightness_auto),
                    onToggle: toggleAutoTheme,
                    initialValue: autoThemeEnabled,
                    // theme: theme,
                    activeSwitchColor: AppTheme.mugitenWheat.background,
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Dark Theme'),
                    leading: const Icon(Icons.dark_mode),
                    onToggle: (b) {
                      BlocProvider.of<ThemeBloc>(context)
                          .add(SetTheme(themeIsDark: b));
                      setState(() => darkThemeEnabled = b);
                    },
                    initialValue: darkThemeEnabled,
                    enabled: !autoThemeEnabled,
                    // theme: theme,
                    activeSwitchColor: AppTheme.mugitenWheat.background,
                  ),
                ],
              ),
              SettingsSection(
                title: Text('Data', style: titleTextStyle),
                tiles: <SettingsTile>[
                  SettingsTile(
                    enabled: true,
                    leading: const Icon(Icons.file_upload),
                    title: const Text('Import Data'),
                    onPressed: importHandler,
                    value: dataImportIsLoading
                        ? const LinearProgressIndicator()
                        : null,
                  ),
                  SettingsTile(
                    enabled: true,
                    leading: const Icon(Icons.file_download),
                    title: const Text('Export Data'),
                    onPressed: exportHandler,
                    value: dataExportIsLoading
                        ? const LinearProgressIndicator()
                        : null,
                  ),
                  SettingsTile(
                    enabled: true,
                    leading: const Icon(Icons.delete),
                    title: const Text(
                      'Clear History',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: clearHistory,
                  ),
                  SettingsTile(
                    enabled: true,
                    leading: const Icon(Icons.delete),
                    title: const Text(
                      'Clear Favourites',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: clearFavourites,
                  ),
                  SettingsTile(
                    enabled: true,
                    leading: const Icon(Icons.delete),
                    title: const Text(
                      'Reset database',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: clearAll,
                  ),
                ],
              ),
              SettingsSection(
                title: Text('Misc', style: titleTextStyle),
                tiles: <SettingsTile>[
                  SettingsTile.switchTile(
                    leading: const Icon(Mdi.incognito),
                    title: const Text('Disable history tracking'),
                    onToggle: (b) => setState(() => incognitoModeEnabled = b),
                    initialValue: incognitoModeEnabled,
                    activeSwitchColor: AppTheme.mugitenWheat.background,
                  ),
                ],
              ),
              SettingsSection(
                title: Text('Info', style: titleTextStyle),
                tiles: <SettingsTile>[
                  SettingsTile(
                    leading: const Icon(Icons.copyright),
                    title: const Text('Licenses'),
                    onPressed: (c) =>
                        Navigator.pushNamed(context, Routes.aboutLicenses),
                  ),
                  SettingsTile(
                    leading: const Icon(Icons.notes),
                    title: const Text('Changelog'),
                    onPressed: (c) =>
                        Navigator.pushNamed(context, Routes.aboutChangelog),
                  ),
                  SettingsTile(
                    leading: const Icon(Mdi.git),
                    title: const Text('Repository'),
                    onPressed: (c) => launchUrl(
                      Uri.parse('https://git.pvv.ntnu.no/mugiten'),
                    ),
                  )
                ],
              ),
            ],
          );
        },
      );
}
