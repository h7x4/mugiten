import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final SharedPreferences _prefs = GetIt.instance.get<SharedPreferences>();

enum JapaneseFont {
  none,
  droidSansJapanese,
  notoSansCJK,
  notoSerifCJK,
}

extension Methods on JapaneseFont {
  TextStyle get textStyle {
    String? fontFamily;
    switch (this) {
      case JapaneseFont.droidSansJapanese:
        fontFamily = 'Droid Sans Japanese';
        break;
      case JapaneseFont.notoSansCJK:
        fontFamily = 'Noto Sans CJK';
        break;
      case JapaneseFont.notoSerifCJK:
        fontFamily = 'Noto Serif CJK';
        break;
      case JapaneseFont.none:
    }
    return TextStyle(fontFamily: fontFamily);
  }

  String get name =>
      {
        JapaneseFont.none: 'Default',
        JapaneseFont.droidSansJapanese: 'Droid Sans Japanese',
        JapaneseFont.notoSansCJK: 'Noto Sans CJK',
        JapaneseFont.notoSerifCJK: 'Noto Serif CJK',
      }[this] ??
      '';
}

const String appVersion = '0.1 Beta';

const Map<String, dynamic> _defaults = {
  'romajiEnabled': false,
  'darkThemeEnabled': false,
  'autoThemeEnabled': false,
  'japaneseFont': JapaneseFont.droidSansJapanese,
};

bool _getSettingOrDefault(String settingName) =>
    _prefs.getBool(settingName) ?? _defaults[settingName];

bool get romajiEnabled => _getSettingOrDefault('romajiEnabled');
bool get darkThemeEnabled => _getSettingOrDefault('darkThemeEnabled');
bool get autoThemeEnabled => _getSettingOrDefault('autoThemeEnabled');
JapaneseFont get japaneseFont {
  final int? i = _prefs.getInt('japaneseFont');
  return (i != null) ? JapaneseFont.values[i] : _defaults['japaneseFont'];
}

set romajiEnabled(b) => _prefs.setBool('romajiEnabled', b);
set darkThemeEnabled(b) => _prefs.setBool('darkThemeEnabled', b);
set autoThemeEnabled(b) => _prefs.setBool('autoThemeEnabled', b);
set japaneseFont(JapaneseFont jf) => _prefs.setInt('japaneseFont', jf.index);
