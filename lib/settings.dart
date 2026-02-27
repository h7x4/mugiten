import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

final SharedPreferences _prefs = GetIt.instance.get<SharedPreferences>();

abstract interface class StringifySharedPrefItem<T> {
  String serializeSetting(T value) => value.toString();
  T deserializeSetting(String s);
}

abstract class SharedPrefItem<T> extends ValueNotifier<T> {
  final String key;
  final T defaultValue;

  SharedPrefItem(this.key, this.defaultValue)
    : super(_getValue<T>(key, defaultValue));

  static T _getValue<T>(String key, T defaultValue) {
    Object? result = _prefs.get(key);

    switch (defaultValue) {
      case StringifySharedPrefItem():
        if (result is String) {
          try {
            result = (defaultValue as StringifySharedPrefItem)
                .deserializeSetting(result);
          } catch (e) {
            // If deserialization fails, reset to default value.
            _setValue<T>(key, defaultValue);
            result = defaultValue;
          }
        } else {
          // If the stored value is not a String, reset to default value.
          _setValue<T>(key, defaultValue);
          result = defaultValue;
        }
      default:
    }

    return result as T;
  }

  static void _setValue<T>(String key, T value) {
    switch (value) {
      case null:
        _prefs.remove(key);
      case bool():
        _prefs.setBool(key, value);
      case int():
        _prefs.setInt(key, value);
      case double():
        _prefs.setDouble(key, value);
      case String():
        _prefs.setString(key, value);
      case List<String>():
        _prefs.setStringList(key, value);
      case StringifySharedPrefItem():
        _prefs.setString(
          key,
          (value as StringifySharedPrefItem).serializeSetting(value),
        );
      default:
        throw Exception(
          'Unsupported type for SharedPrefItem: ${value.runtimeType}',
        );
    }
  }

  @override
  T get value => _getValue<T>(key, defaultValue);

  @override
  set value(T newValue) {
    final oldValue = _getValue<T>(key, defaultValue);
    _setValue<T>(key, newValue);

    if (oldValue != newValue) {
      notifyListeners();
    }
  }
}

/// Whether to save search history and other data to the database.
class IncognitoModeEnabled extends SharedPrefItem<bool> {
  IncognitoModeEnabled() : super('incognitoModeEnabled', false);
}

final incognitoModeEnabled = IncognitoModeEnabled();

/// Whether to show romaji readings in the word search results and elsewhere.
class RomajiEnabled extends SharedPrefItem<bool> {
  RomajiEnabled() : super('romajiEnabled', false);
}

final romajiEnabled = RomajiEnabled();

/// Whether to use a dark theme.
class DarkThemeEnabled extends SharedPrefItem<bool> {
  DarkThemeEnabled() : super('darkThemeEnabled', false);
}

final darkThemeEnabled = DarkThemeEnabled();

/// Whether to let the system control which theme to use.
class AutoThemeEnabled extends SharedPrefItem<bool> {
  AutoThemeEnabled() : super('autoThemeEnabled', true);
}

final autoThemeEnabled = AutoThemeEnabled();

/// Whether to reduce the size of the kanji drawing board.
///
/// This is a workaround for an issue where it's easy to activate the 'go back' gesture when
/// drawing a little too close to the edge of the screen.
class ReduceKanjiDrawingBoardSize extends SharedPrefItem<bool> {
  ReduceKanjiDrawingBoardSize() : super('reduceKanjiDrawingBoardSize', false);
}

final reduceKanjiDrawingBoardSize = ReduceKanjiDrawingBoardSize();

class QuickAddLibraryList extends SharedPrefItem<String?> {
  QuickAddLibraryList() : super('quickAddLibraryList', null);
}

final quickAddLibraryList = QuickAddLibraryList();

enum JapaneseFontChoice implements StringifySharedPrefItem<JapaneseFontChoice> {
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
  zenKurenaido;

  TextStyle get textStyle => switch (this) {
    JapaneseFontChoice.droidSansJapanese => const TextStyle(
      fontFamily: 'Droid Sans Japanese',
    ),
    JapaneseFontChoice.notoSansJapanese => GoogleFonts.notoSansJp(),
    JapaneseFontChoice.notoSerifJapanese => GoogleFonts.notoSerifJp(),
    JapaneseFontChoice.hinaMincho => GoogleFonts.hinaMincho(),
    JapaneseFontChoice.ibmPlexSansJP => GoogleFonts.ibmPlexSansJp(),
    JapaneseFontChoice.kleeOne => GoogleFonts.kleeOne(),
    JapaneseFontChoice.kosugi => GoogleFonts.kosugi(),
    JapaneseFontChoice.mPlus2 => GoogleFonts.mPlus2(),
    JapaneseFontChoice.mPlusRounded1c => GoogleFonts.mPlusRounded1c(),
    JapaneseFontChoice.zenKurenaido => GoogleFonts.zenTokyoZoo(),
    JapaneseFontChoice.system => const TextStyle(),
  };

  static Map<JapaneseFontChoice, String> get _fontToName => {
    JapaneseFontChoice.system: 'System Default',
    JapaneseFontChoice.droidSansJapanese: 'Droid Sans Japanese',
    JapaneseFontChoice.notoSansJapanese: 'Noto Sans Japanese',
    JapaneseFontChoice.notoSerifJapanese: 'Noto Serif Japanese',
    JapaneseFontChoice.hinaMincho: 'Hina Mincho',
    JapaneseFontChoice.ibmPlexSansJP: 'IBM Plex Sans JP',
    JapaneseFontChoice.kleeOne: 'Klee One',
    JapaneseFontChoice.kosugi: 'Kosugi',
    JapaneseFontChoice.mPlus2: 'M PLUS 2',
    JapaneseFontChoice.mPlusRounded1c: 'M PLUS Rounded 1c',
    JapaneseFontChoice.zenKurenaido: 'Zen Kurenaido',
  };

  static Map<String, JapaneseFontChoice> get _nameToFont =>
      _fontToName.map((k, v) => MapEntry(v, k));

  String get name => _fontToName[this]!;

  @override
  String serializeSetting(JapaneseFontChoice value) => _fontToName[value]!;

  @override
  JapaneseFontChoice deserializeSetting(String s) => _nameToFont[s]!;
}

class JapaneseFont extends SharedPrefItem<JapaneseFontChoice> {
  JapaneseFont() : super('japaneseFont', JapaneseFontChoice.droidSansJapanese);
}

final japaneseFont = JapaneseFont();
