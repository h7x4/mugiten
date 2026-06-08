// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:sqlite3/sqlite3.dart';

@Native<Int Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)>()
external int sqlite3_tamerye_init(
  final Pointer<Void> db,
  final Pointer<Void> pzErrMsg,
  final Pointer<Void> pApi,
);

extension LoadVectorExtension on Sqlite3 {
  void loadSqliteTameryeExtension() {
    ensureExtensionLoaded(
      SqliteExtension(
        Native.addressOf<
              NativeFunction<
                Int Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)
              >
            >(sqlite3_tamerye_init)
            .cast(),
      ),
    );
  }
}
