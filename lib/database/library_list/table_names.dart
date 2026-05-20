abstract class LibraryListTableNames {
  /// Attributes:
  /// - name TEXT
  /// - orderNum INTEGER
  static const String libraryList = 'Mugiten_LibraryList';

  /// Attributes:
  /// - listName TEXT
  /// - orderNum INTEGER
  /// - jmdictEntryId INTEGER
  /// - kanji TEXT
  /// - lastModified TIMESTAMP
  static const String libraryListEntry = 'Mugiten_LibraryListEntry';

  ///////////
  // VIEWS //
  ///////////

  static Set<String> get allTables => {
    libraryList,
    libraryListEntry,
  };
}
