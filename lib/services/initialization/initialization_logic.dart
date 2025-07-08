import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mugiten/database/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Determine whether the application needs to show the initialization screen.
Future<bool> needsInitialization() async {
  final modelManager = DigitalInkRecognizerModelManager();
  if (!await modelManager.isModelDownloaded('ja')) {
    return true;
  }

  if (await databaseNeedsInitialization()) {
    return true;
  }

  return false;
}

/// Quick initialization used for normal startup without initialization screen.
Future<void> quickInitialization() async {
  databaseFactory = databaseFactoryFfi;

  await Future.wait([
    quickInitializeDatabase(),
    setupSharedPreferences(),
    (() async {
      final modelManager = DigitalInkRecognizerModelManager();
      final isDownloaded = await modelManager.isModelDownloaded('ja');
      assert(isDownloaded, 'Japanese model should be downloaded at this point');
    })(),
  ]);

  registerExtraLicenses();
}

// TODO: should this be deferred in case preferences are modified externally?
Future<void> setupSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  GetIt.instance.registerSingleton<SharedPreferences>(prefs);
}

void registerExtraLicenses() => LicenseRegistry.addLicense(
      () async* {
        final jsonString = await rootBundle.loadString('assets/licenses.json');
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        for (final license in jsonData.entries) {
          yield LicenseEntryWithLineBreaks(
            [license.key],
            await rootBundle.loadString(license.value as String),
          );
        }
      },
    );
