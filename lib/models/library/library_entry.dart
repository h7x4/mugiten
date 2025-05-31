class LibraryEntry {
  DateTime lastModified;
  String? kanji;
  int? jmdictEntryId;

  LibraryEntry({
    DateTime? lastModified,
    this.kanji,
    this.jmdictEntryId,
  })  : lastModified = lastModified ?? DateTime.now(),
        assert(
          kanji != null || jmdictEntryId != null,
          "Library entry can't be empty",
        ),
        assert(
          !(kanji != null && jmdictEntryId != null),
          "Library entry can't have both kanji and jmdictEntryId",
        );

  LibraryEntry.fromJmdictId({
    required int this.jmdictEntryId,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  LibraryEntry.fromKanji({
    required String this.kanji,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, Object?> toJson() => {
        'kanji': kanji,
        'jmdictEntryId': jmdictEntryId,
        'lastModified': lastModified.millisecondsSinceEpoch,
      };

  factory LibraryEntry.fromJson(Map<String, Object?> json) {
    assert(
      (json.containsKey('kanji') && json['kanji'] != null) ||
          (json.containsKey('jmdictEntryId') && json['jmdictEntryId'] != null),
      "Library entry can't be empty",
    );
    assert(
      json.containsKey('lastModified'),
      "Library entry must have a lastModified timestamp",
    );

    if (json.containsKey('kanji') && json['kanji'] != null) {
      return LibraryEntry.fromKanji(
        kanji: json['kanji']! as String,
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          json['lastModified']! as int,
        ),
      );
    } else {
      return LibraryEntry.fromJmdictId(
        jmdictEntryId: json['jmdictEntryId']! as int,
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          json['lastModified']! as int,
        ),
      );
    }
  }

  // NOTE: this just happens to be the same as the logic in `fromJson`
  factory LibraryEntry.fromDBMap(Map<String, Object?> dbObject) =>
      LibraryEntry.fromJson(dbObject);
}
