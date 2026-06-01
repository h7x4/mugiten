# Database and archives

Mugiten uses a SQLite database to store information like history and library lists. The tables are added to an already existing [jadb][jadb] instance.

## Schemas and database versioning

The database version number is an integer that is stored in SQLite's `user_version` pragma. The version number is incremented whenever there are changes to the database schema, which does not necessarily correspond to the version number of the app. The `user_version` is constructed by bit-packing the version numbers of both mugiten and [jadb][jadb], ensuring that an update is triggered whenever either of them has a schema change.

The database is not designed to be updated in-place with traditional migrations. Instead, when there are changes to the database schema, the app will export an archive of the current database (see `Archive` further down for details), completely reset the database (usually by deleting the file and creating a new copy of jadb), applying the new schema, and then restoring the data from the archive. This approach was chosen because we need the archive functionality anyway, and it works around some of the quirks of editing tables in SQLite.

Each database schema is stored as a directory of SQL files under `lib/services/database/schemas/v{version}/`. The sql files inside each schema directory are prefixed with a number to indicate the order in which they should be applied. The older schema versions are kept around for testing purposes, so that the tests can initialize older versions of the database to test exporting archives from older versions of the database.

> [!CAUTION]
> New schema versions are not considered stable until they have been released. You should not rely on incremental updates to the database schema during development.

## Archive

The archive functionality is used to export and import user data. This has two main purposes:

1. Letting the user backup their data and transferring it between devices.
2. Automatic backups between database migrations, so that the app can completely reset the database and restore the data from the backup.

The archival format is mostly based on zip archives containing JSON files. There are multiple versions of the archive format.

- When exporting, the latest version of the archive format is preferred.
  - When exporting the data for manual user backups, the app will expect to be on the latest version of the database schema, so it will use the latest version of the archive format.
  - When exporting the data for backups between app updates, the app might contain a database with an older database schema. In this case, the app might need to use an older version of the archive format (see `Versioned SQL queries` below).
- When importing, the version of the archive is detected and the appropriate import function is used.
  - The import functions are all designed to insert the data into the latest version of the database schema.

Keeping all import functions up to date might become a bit of a chore. In the future, there might be a need to start deprecating older versions of the archive format to reduce the amount of maintenance work needed for these functions.

### Versioned SQL queries

Although importing data always expects the latest version of the database schema, the export functionality needs to be able to export data from older versions of the database, for whenever it is used as a backup between app updates. For this reason, the export functionality uses versioned SQL queries, which are stored under `lib/services/archive/sql/`. Each query file is named `v{version}.dart`, and contains all functions required to query data from a database with the corresponding schema version.

In order to export the data, there is an export function for each version of the database schema. Each export function uses the appropriate version of the SQL queries combined with the latest version of the archive format.

### Full exports

> [!NOTE]
> Not implemented yet, see https://git.pvv.ntnu.no/mugiten/mugiten/issues/72

There is a feature to let the user export their data along with data from jadb, which is called a "full" export. This lets the user export data that can be played around with in a programming language or similar, without needing any knowledge about the inner workings of mugiten. In order to not deal with versioning SQL queries for both mugiten and jadb at the same time, the full export only supports the latest version of the database schema (and thus also only the latest version of the archive format). The full export is never going to be used for backups between app updates.

[jadb]: https://git.pvv.ntnu.no/mugiten/jadb
