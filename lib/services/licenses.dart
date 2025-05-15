import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

void registerExtraLicenses() => LicenseRegistry.addLicense(() async* {
      final jsonString = await rootBundle.loadString('assets/licenses.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      for (final license in jsonData.entries) {
        yield LicenseEntryWithLineBreaks(
          [license.key],
          await rootBundle.loadString(license.value as String),
        );
      }
    });
