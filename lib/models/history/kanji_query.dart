class KanjiQuery {
  final String kanji;

  KanjiQuery({
    required this.kanji,
  });

  Map<String, Object?> toJson() => {'kanji': kanji};

  factory KanjiQuery.fromJson(Map<String, Object?> json) =>
      KanjiQuery(kanji: json['kanji'] as String);
}
