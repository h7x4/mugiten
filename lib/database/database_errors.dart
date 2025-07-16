abstract class DatabaseError implements ArgumentError {
  final String? tableName;
  final Map<String, dynamic>? illegalArguments;

  const DatabaseError({this.tableName, this.illegalArguments});

  @override
  dynamic get invalidValue => illegalArguments;

  @override
  StackTrace? get stackTrace => null;
}

class DataAlreadyExistsError extends DatabaseError {
  const DataAlreadyExistsError({super.tableName, super.illegalArguments});

  @override
  String? get name => illegalArguments?.keys.join(', ');

  String get _inTableName => tableName != null ? ' in "$tableName"' : '';
  String get _invalidArgs => illegalArguments != null ? ': ($name)' : '';

  @override
  String get message => 'Data already exists$_inTableName$_invalidArgs';
}

class DataNotFoundError extends DatabaseError {
  const DataNotFoundError({super.tableName, super.illegalArguments});

  @override
  String? get name => illegalArguments?.keys.join(', ');

  String get _inTableName => tableName != null ? ' in "$tableName"' : '';
  String get _invalidArgs => illegalArguments != null ? ': ($name)' : '';

  @override
  String get message => 'Data not found$_inTableName$_invalidArgs';
}

class IllegalDeletionError extends DatabaseError {
  const IllegalDeletionError({super.tableName, super.illegalArguments});

  @override
  String? get name => illegalArguments?.keys.join(', ');

  String get _fromTableName => tableName != null ? ' from "$tableName"' : '';
  String get _args => illegalArguments != null ? '($name)' : '';

  @override
  String get message => 'Deleting $_args$_fromTableName is not allowed.';
}

// class IllegalInsertionError extends DatabaseError {}
