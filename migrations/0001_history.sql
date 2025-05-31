CREATE TABLE "Mugiten_HistoryEntry" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE "Mugiten_HistoryEntryKanji" (
  "entryId" INTEGER NOT NULL REFERENCES "Mugiten_HistoryEntry"("id") ON DELETE CASCADE,
  "kanji" CHAR(1) NOT NULL,
  PRIMARY KEY ("entryId", "kanji")
);

CREATE TABLE "Mugiten_HistoryEntryWord" (
  "entryId" INTEGER NOT NULL REFERENCES "Mugiten_HistoryEntry"("id") ON DELETE CASCADE,
  "word" TEXT NOT NULL,
  "language" CHAR(1) CHECK ("language" IN ('e', 'j')),
  PRIMARY KEY ("entryId", "word")
);

CREATE TABLE "Mugiten_HistoryEntryTimestamp" (
  "entryId" INTEGER NOT NULL REFERENCES "Mugiten_HistoryEntry"("id") ON DELETE CASCADE,
  -- Defaults to unix timestamp in milliseconds
  "timestamp" INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  PRIMARY KEY ("entryId", "timestamp")
);

-- Useful when ordering entries by the timestamps
CREATE INDEX "Mugiten_HistoryEntryTimestamp_byTimestamp" ON "Mugiten_HistoryEntryTimestamp"("timestamp");

CREATE VIEW "Mugiten_HistoryEntry_orderedByTimestamp" AS
  SELECT * FROM "Mugiten_HistoryEntryTimestamp"
  LEFT JOIN "Mugiten_HistoryEntryWord" USING ("entryId")
  LEFT JOIN "Mugiten_HistoryEntryKanji" USING ("entryId")
  GROUP BY "entryId"
  ORDER BY MAX("timestamp") DESC;
