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
