import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

final SharedPreferences _prefs = GetIt.instance.get<SharedPreferences>();

enum JapaneseFont {
  system,
  droidSansJapanese,
  hinaMincho,
  ibmPlexSansJP,
  kleeOne,
  kosugi,
  mPlus2,
  mPlusRounded1c,
  notoSansJapanese,
  notoSerifJapanese,
  zenKurenaido,
}

extension Methods on JapaneseFont {
  TextStyle get textStyle {
    switch (this) {
      case JapaneseFont.droidSansJapanese:
        TextStyle(fontFamily: 'Droid Sans Japanese');
      case JapaneseFont.notoSansJapanese:
        return GoogleFonts.notoSansJp();
      case JapaneseFont.notoSerifJapanese:
        return GoogleFonts.notoSerifJp();
      case JapaneseFont.hinaMincho:
        return GoogleFonts.hinaMincho();
      case JapaneseFont.ibmPlexSansJP:
        return GoogleFonts.ibmPlexSansJp();
      case JapaneseFont.kleeOne:
        return GoogleFonts.kleeOne();
      case JapaneseFont.kosugi:
        return GoogleFonts.kosugi();
      case JapaneseFont.mPlus2:
        return GoogleFonts.mPlus2();
      case JapaneseFont.mPlusRounded1c:
        return GoogleFonts.mPlusRounded1c();
      case JapaneseFont.zenKurenaido:
        return GoogleFonts.zenTokyoZoo();
      case JapaneseFont.system:
    }

    return const TextStyle();
  }

  String get name => switch (this) {
    JapaneseFont.system => 'System Default',
    JapaneseFont.droidSansJapanese => 'Droid Sans Japanese',
    JapaneseFont.notoSansJapanese => 'Noto Sans Japanese',
    JapaneseFont.notoSerifJapanese => 'Noto Serif Japanese',
    JapaneseFont.hinaMincho => 'Hina Mincho',
    JapaneseFont.ibmPlexSansJP => 'IBM Plex Sans JP',
    JapaneseFont.kleeOne => 'Klee One',
    JapaneseFont.kosugi => 'Kosugi',
    JapaneseFont.mPlus2 => 'M PLUS 2',
    JapaneseFont.mPlusRounded1c => 'M PLUS Rounded 1c',
    JapaneseFont.zenKurenaido => 'Zen Kurenaido',
  };
}

const Map<String, dynamic> _defaults = {
  'incognitoModeEnabled': false,
  'romajiEnabled': false,
  'darkThemeEnabled': false,
  'autoThemeEnabled': true,
  'japaneseFont': JapaneseFont.droidSansJapanese,
  'reduceKanjiDrawingBoardSize': false,
  'quickAddLibraryList': null,
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

String? get quickAddLibraryList =>
    _prefs.getString('quickAddLibraryList') ?? _defaults['quickAddLibraryList'];

set incognitoModeEnabled(bool b) => _prefs.setBool('incognitoModeEnabled', b);
set romajiEnabled(bool b) => _prefs.setBool('romajiEnabled', b);
set darkThemeEnabled(bool b) => _prefs.setBool('darkThemeEnabled', b);
set autoThemeEnabled(bool b) => _prefs.setBool('autoThemeEnabled', b);
set reduceKanjiDrawingBoardSize(bool b) =>
    _prefs.setBool('reduceKanjiDrawingBoardSize', b);
set japaneseFont(JapaneseFont jf) => _prefs.setInt('japaneseFont', jf.index);
set quickAddLibraryList(String? s) => s == null
    ? _prefs.remove('quickAddLibraryList')
    : _prefs.setString('quickAddLibraryList', s);
