// /// Can assume Android for time being
// Future<void> exportData(context) async {
//   // setState(() => dataExportIsLoading = true);

//   final path = (await getExternalStorageDirectory())!;
//   final dbData = await exportDatabase(db);
//   final file = File('${path.path}/jisho_data.json');
//   file.createSync(recursive: true);
//   await file.writeAsString(jsonEncode(dbData));

//   setState(() => dataExportIsLoading = false);
//   ScaffoldMessenger.of(context)
//       .showSnackBar(SnackBar(content: Text('Data exported to ${file.path}')));
// }

// /// Can assume Android for time being
// Future<void> importData(context) async {
//   // setState(() => dataImportIsLoading = true);

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

//   // print(mergedSearches);

//   await GetIt.instance.get<Database>().close();
//   GetIt.instance.unregister<Database>();

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
