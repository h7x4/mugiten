CREATE TABLE "Mugiten_LibraryList" (
  "name" TEXT PRIMARY KEY NOT NULL,
  "orderNum" INTEGER NOT NULL UNIQUE CHECK ("orderNum" >= 0),

  -- 'favourites' should always be the first list
  CHECK ("name" != 'favourites' OR "orderNum" = 0)
);

-- CREATE INDEX "Mugiten_LibraryList_byOrderNum" ON "Mugiten_LibraryList"("orderNum");

-- This entry should always exist
INSERT INTO "Mugiten_LibraryList"("name", "orderNum") VALUES ('favourites', 0);

CREATE TABLE "Mugiten_LibraryListEntry" (
  "listName" TEXT NOT NULL REFERENCES "Mugiten_LibraryList"("name") ON DELETE CASCADE,
  "orderNum" INTEGER NOT NULL CHECK ("orderNum" >= 0),
  -- TODO: When we update database data, these should not be silently deleted without notifying
  --       the user.
  "jmdictEntryId" INTEGER REFERENCES "JMdict_Entry"("entryId") ON DELETE CASCADE,
  "kanji" CHAR(1) REFERENCES "KANJIDIC_Character"("literal") ON DELETE CASCADE,
  -- Defaults to unix timestamp in milliseconds
  "lastModified" INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),

  PRIMARY KEY ("listName", "orderNum"),

  -- The same entry cannot show up more than once in the same list
  UNIQUE ("listName", "kanji"),
  UNIQUE ("listName", "jmdictEntryId"),

  -- Only one of the fields must be non-null
  CHECK (("jmdictEntryId" IS NOT NULL) <> ("kanji" IS NOT NULL))
);

-- CREATE INDEX "Mugiten_LibraryListEntry_byListNameAndOrderNum" ON "Mugiten_LibraryListEntry"("listName", "orderNum");
