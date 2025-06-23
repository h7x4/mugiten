import 'dart:convert';
import 'dart:io';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:mdi/mdi.dart';
import 'package:mugiten/database/database.dart';
import 'package:mugiten/models/history/history_entry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../bloc/theme/theme_bloc.dart';
import '../components/common/denshi_jisho_background.dart';
import '../models/history/search.dart';
import '../routing/routes.dart';
// import '../services/database.dart';
import '../services/snackbar.dart';
import '../settings.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final Database db = GetIt.instance.get<Database>();
  bool dataExportIsLoading = false;
  bool dataImportIsLoading = false;

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

  // /// Can assume Android for time being
  // Future<void> exportData(context) async {
  //   setState(() => dataExportIsLoading = true);

  // final path = (await getExternalStorageDirectory())!;
  // final dbData = await exportDatabase(db);
  // final file = File('${path.path}/mugiten_data.json');
  // file.createSync(recursive: true);
  // await file.writeAsString(jsonEncode(dbData));

  //   setState(() => dataExportIsLoading = false);
  //   ScaffoldMessenger.of(context)
  //       .showSnackBar(SnackBar(content: Text('Data exported to ${file.path}')));
  // }

  // /// Can assume Android for time being
  // Future<void> importData(context) async {
  //   setState(() => dataImportIsLoading = true);

  //   final path = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['json'],
  //   );
  //   final file = File(path!.files[0].path!);

  //   final List<Search> prevSearches = (await Search.store.find(db))
  //       .map((e) => Search.fromJson(e.value! as Map<String, Object?>))
  //       .toList();
  //   late final List<Search> importedSearches;
  //   try {
  //     importedSearches = (jsonDecode(await file.readAsString())
  //             as List<dynamic>)
  //         // importedSearches = (((jsonDecode(await file.readAsString())
  //         //             as Map<String, Object?>)['stores']! as List<Object?>)
  //         //         .map((e) => e! as Map<String, Object?>)
  //         //         .where((e) => e['name'] == 'search')
  //         //         .first['values'] as List<dynamic>)
  //         .map((item) => Search.fromJson(item))
  //         .toList();
  //   } catch (e) {
  //     debugPrint(e.toString());
  //     showSnackbar(
  //       context,
  //       "Couldn't read file. Did you choose the right one?",
  //     );
  //     return;
  //   }

  //   final List<Search> mergedSearches =
  //       mergeSearches(prevSearches, importedSearches);

  // await GetIt.instance.get<Database>().close();
  // GetIt.instance.unregister<Database>();

  //   final importedDb = await importDatabase(
  //     {
  //       'sembast_export': 1,
  //       'version': 1,
  //       'stores': [
  //         {
  //           'name': 'search',
  //           'keys': [for (var i = 1; i <= mergedSearches.length; i++) i],
  //           'values': mergedSearches.map((e) => e.toJson()).toList(),
  //         }
  //       ]
  //     },
  //     databaseFactoryIo,
  //     await databasePath(),
  //   );
  //   GetIt.instance.registerSingleton<Database>(importedDb);

  //   setState(() => dataImportIsLoading = false);
  //   showSnackbar(context, 'Data imported successfully');
  // }

  // Future<void> clearHistory(context) async {
  //   final historyCount = await HistoryEntry.amountOfEntries();

  //   final bool userIsSure = await confirm(
  //     context,
  //     content: Text(
  //       'Are you sure that you want to clear all $historyCount entries in history?',
  //     ),
  //   );

  //   if (userIsSure) {
  //     await Search.store.delete(db);
  //   }
  // }

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
                    enabled: false,
                    // enabled: Platform.isAndroid,
                    leading: const Icon(Icons.file_upload),
                    title: const Text('Import Data'),
                    description: Platform.isAndroid
                        ? null
                        : Text('Not available on iOS yet'),
                    onPressed: (c) {},
                    value: dataImportIsLoading
                        ? const LinearProgressIndicator()
                        : null,
                  ),
                  SettingsTile(
                    enabled: false,
                    // enabled: Platform.isAndroid,
                    leading: const Icon(Icons.file_download),
                    title: const Text('Export Data'),
                    description: Platform.isAndroid
                        ? null
                        : Text('Not available on iOS yet'),
                    onPressed: (c) {},
                    value: dataExportIsLoading
                        ? const LinearProgressIndicator()
                        : null,
                  ),
                  SettingsTile(
                    enabled: false,
                    leading: const Icon(Icons.delete),
                    title: const Text(
                      'Clear History',
                      style: TextStyle(color: Colors.red),
                    ),
                    // onPressed: clearHistory,
                    onPressed: (c) {
                      showSnackbar(
                        context,
                        'This feature is not implemented yet',
                      );
                    },
                  ),
                  SettingsTile(
                    enabled: false,
                    leading: const Icon(Icons.delete),
                    title: const Text(
                      'Clear Favourites',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: (c) {},
                  ),
                  SettingsTile(
                    enabled: true,
                    leading: const Icon(Icons.delete),
                    title: const Text(
                      'Reset database',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: (ctx) async {
                      // TODO: confirmation dialog

                      showSnackbar(
                        ctx,
                        'Resetting the database...',
                      );

                      await resetDatabase();

                      if (!ctx.mounted) return;

                      showSnackbar(
                        ctx,
                        'Database reset successfully.',
                      );
                    },
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
                ],
              ),
            ],
          );
        },
      );
}
