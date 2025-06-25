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
}
