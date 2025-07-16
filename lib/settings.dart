import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final SharedPreferences _prefs = GetIt.instance.get<SharedPreferences>();

enum JapaneseFont { none, droidSansJapanese, notoSansCJK, notoSerifCJK }

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

const Map<String, dynamic> _defaults = {
  'incognitoModeEnabled': false,
  'romajiEnabled': false,
  'darkThemeEnabled': false,
  'autoThemeEnabled': false,
  'japaneseFont': JapaneseFont.droidSansJapanese,
  'reduceKanjiDrawingBoardSize': false,
};

bool _getSettingOrDefault(String settingName) =>
    _prefs.getBool(settingName) ?? _defaults[settingName];

bool get incognitoModeEnabled => _getSettingOrDefault('incognitoModeEnabled');
bool get romajiEnabled => _getSettingOrDefault('romajiEnabled');
bool get darkThemeEnabled => _getSettingOrDefault('darkThemeEnabled');
bool get autoThemeEnabled => _getSettingOrDefault('autoThemeEnabled');
bool get reduceKanjiDrawingBoardSize =>
    _getSettingOrDefault('reduceKanjiDrawingBoardSize');
JapaneseFont get japaneseFont {
  final int? i = _prefs.getInt('japaneseFont');
  return (i != null) ? JapaneseFont.values[i] : _defaults['japaneseFont'];
}

set incognitoModeEnabled(bool b) => _prefs.setBool('incognitoModeEnabled', b);
set romajiEnabled(bool b) => _prefs.setBool('romajiEnabled', b);
set darkThemeEnabled(bool b) => _prefs.setBool('darkThemeEnabled', b);
set autoThemeEnabled(bool b) => _prefs.setBool('autoThemeEnabled', b);
set reduceKanjiDrawingBoardSize(bool b) =>
    _prefs.setBool('reduceKanjiDrawingBoardSize', b);
set japaneseFont(JapaneseFont jf) => _prefs.setInt('japaneseFont', jf.index);
