abstract class HistoryTableNames {
  /// Attributes:
  /// - id INTEGER
  static const String historyEntry = 'Mugiten_HistoryEntry';

  /// Attributes:
  /// - entryId INTEGER
  /// - kanji CHAR(1)
  static const String historyEntryKanji = 'Mugiten_HistoryEntryKanji';

  /// Attributes:
  /// - entryId INTEGER
  /// - timestamp INTEGER
  static const String historyEntryTimestamp = 'Mugiten_HistoryEntryTimestamp';

  /// Attributes:
  /// - entryId INTEGER
  /// - word TEXT
  /// - language CHAR(1)?
  static const String historyEntryWord = 'Mugiten_HistoryEntryWord';

  ///////////
  // VIEWS //
  ///////////

  /// Attributes:
  /// - entryId INTEGER
  /// - timestamp INTEGER
  /// - word TEXT?
  /// - kanji CHAR(1)?
  /// - language CHAR(1)?
  static const String historyEntryOrderedByTimestamp =
      'Mugiten_HistoryEntry_orderedByTimestamp';

  static Set<String> get allTables => {
    historyEntry,
    historyEntryKanji,
    historyEntryTimestamp,
    historyEntryWord,
    historyEntryOrderedByTimestamp,
  };
}

abstract class LibraryListTableNames {
  /// Attributes:
  /// - name TEXT
  /// - prevList TEXT
  static const String libraryList = 'Mugiten_LibraryList';

  /// Attributes:
  /// - listName TEXT
  /// - jmdictEntryId INTEGER
  /// - kanji TEXT
  /// - lastModified TIMESTAMP
  /// - prevJmdictEntryId INTEGER
  /// - prevEntryKanji TEXT
  static const String libraryListEntry = 'Mugiten_LibraryListEntry';

  ///////////
  // VIEWS //
  ///////////

  /// Attributes:
  /// - name TEXT
  static const String libraryListOrdered = 'Mugiten_LibraryList_Ordered';

  static Set<String> get allTables => {
    libraryList,
    libraryListEntry,
    libraryListOrdered,
  };
}
