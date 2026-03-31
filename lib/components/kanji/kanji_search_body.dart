import 'dart:async';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jadb/search.dart';
import 'package:mugiten/components/kanji/kanji_search_body/kanji_grid.dart';
import 'package:mugiten/components/kanji/kanji_search_body/kanji_search_bar.dart';
import 'package:mugiten/components/kanji/kanji_search_body/kanji_search_options_bar.dart';
import 'package:sqflite/sqflite.dart';

class KanjiSearchBody extends StatefulWidget {
  const KanjiSearchBody({super.key});

  @override
  State<KanjiSearchBody> createState() => _KanjiSearchBodyState();
}

class _KanjiSearchBodyState extends State<KanjiSearchBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation _searchbarMovementAnimation;
  bool _isFocused = false;
  final FocusNode focus = FocusNode();
  final GlobalKey<KanjiSearchBarState> _kanjiSearchBarState =
      GlobalKey<KanjiSearchBarState>();
  List<String> suggestions = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _searchbarMovementAnimation = AlignmentTween(
      begin: Alignment.center,
      end: Alignment.topCenter,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return PopScope(
      canPop: !_isFocused,
      onPopInvokedWithResult: (final didPop, final result) {
        if (!didPop) {
          focus.unfocus();
          _kanjiSearchBarState.currentState!.clearText();
        }
      },
      child: InkWell(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedBuilder(
            animation: _searchbarMovementAnimation,
            builder: (final context, _) {
              return Container(
                alignment: _searchbarMovementAnimation.value,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Focus(
                      focusNode: focus,
                      onFocusChange: (final hasFocus) {
                        if (hasFocus) {
                          unawaited(
                            _controller.forward().then(
                              (_) => setState(() => _isFocused = true),
                            ),
                          );
                        } else {
                          unawaited(
                            _controller.reverse().then(
                              (_) => setState(() {
                                _isFocused = false;
                              }),
                            ),
                          );
                        }
                      },
                      child: KanjiSearchBar(
                        key: _kanjiSearchBarState,
                        onChanged: (final text) => setState(() async {
                          suggestions = await GetIt.instance
                              .get<Database>()
                              .filterKanji(text.characters.toList());
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSizeAndFade(
                      fadeDuration: const Duration(milliseconds: 200),
                      sizeDuration: const Duration(milliseconds: 300),
                      child: (_controller.value == 1 && suggestions.isNotEmpty)
                          ? KanjiGrid(suggestions: suggestions)
                          : (_controller.value == 1)
                          ? const Text(
                              'Type a kanji to start searching',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            )
                          : const KanjiSearchOptionsBar(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
