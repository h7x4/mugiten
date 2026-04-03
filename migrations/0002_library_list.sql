CREATE TABLE "Mugiten_LibraryList" (
  "name" TEXT PRIMARY KEY NOT NULL,
  "prevList" TEXT UNIQUE

  -- This is true for all lists except the first one in the order.
  -- FOREIGN KEY ("prevList") REFERENCES "Mugiten_LibraryList"("name"),

  -- The list can't link to itself
  CHECK("prevList" != "name"),

  -- 'favourites' should always be the first list
  CHECK (NOT (("name" = 'favourites') <> ("prevList" IS NULL)))
);

-- This entry should always exist
INSERT INTO "Mugiten_LibraryList"("name") VALUES ('favourites');

-- Useful for the view below
CREATE INDEX "Mugiten_LibraryList_byPrevList" ON "Mugiten_LibraryList"("prevList");

-- A view that sorts the LibraryLists in their custom order.
CREATE VIEW "Mugiten_LibraryList_Ordered" AS
  WITH RECURSIVE "RecursionTable"("name") AS (
    SELECT "name"
    FROM "Mugiten_LibraryList" AS "I"
    WHERE "I"."prevList" IS NULL

    UNION ALL

    SELECT "R"."name"
    FROM "Mugiten_LibraryList" AS "R"
    JOIN "RecursionTable" ON
      ("R"."prevList" = "RecursionTable"."name")
  )
  SELECT * FROM "RecursionTable";

CREATE TABLE "Mugiten_LibraryListEntry" (
  "listName" TEXT NOT NULL REFERENCES "Mugiten_LibraryList"("name") ON DELETE CASCADE,
  "jmdictEntryId" INTEGER REFERENCES "JMdict_Entry"("entryId") ON DELETE CASCADE,
  "kanji" CHAR(1) REFERENCES "KANJIDIC_Character"("literal") ON DELETE CASCADE,
  -- Defaults to unix timestamp in milliseconds
  "lastModified" INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  "prevEntryJmdictEntryId" INTEGER,
  "prevEntryKanji" CHAR(1),

  -- The entry cannot show up more than once in the same list
  PRIMARY KEY ("listName", "jmdictEntryId", "kanji"),

  -- This is true for all other entries than the first one in the list.
  -- FOREIGN KEY ("listName", "prevEntryJmdictEntryId", "prevEntryKanji")
  --   REFERENCES "Mugiten_LibraryListEntry"("listName", "jmdictEntryId", "kanji"),

  -- Two entries can not appear directly after the same entry
  UNIQUE("listName", "prevEntryJmdictEntryId", "prevEntryKanji"),

  -- The entry can't link to itself
  CHECK(NOT ("prevEntryJmdictEntryId" == "jmdictEntryId" AND "prevEntryKanji" == "kanji")),

  -- Only one of the fields must be non-null
  CHECK (("jmdictEntryId" IS NOT NULL) <> ("kanji" IS NOT NULL))
);

-- Useful when doing the recursive ordering statement
CREATE INDEX "Mugiten_LibraryListEntry_byListNameAndPrevEntry"
  ON "Mugiten_LibraryListEntry"("listName", "prevEntryJmdictEntryId", "prevEntryKanji");
