import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mugiten/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final SharedPreferences prefs = GetIt.instance.get<SharedPreferences>();
  late List<bool> isSelected;

  @override
  void initState() {
    super.initState();
    isSelected = _getSelectedStatus() ?? [false, false, false];
  }

  Future<void> _updateSelectedStatus() async => prefs.setStringList(
    'languageSelectorStatus',
    isSelected.map((b) => b ? '1' : '0').toList(),
  );

  List<bool>? _getSelectedStatus() => prefs
      .getStringList('languageSelectorStatus')
      ?.map((s) => s == '1')
      .toList();

  Widget _languageOption(String language, {TextStyle? style}) => Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
    child: Text(language, style: style),
  );

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      selectedColor: mugitenWheatBackground,
      isSelected: isSelected,
      children: [
        _languageOption('Auto'),
        _languageOption('日本語', style: japaneseFont.value.textStyle),
        _languageOption('English'),
      ],
      onPressed: (buttonIndex) {
        setState(() {
          for (final int i in Iterable.generate(isSelected.length)) {
            isSelected[i] = i == buttonIndex;
          }
          _updateSelectedStatus();
        });
      },
    );
  }
}
