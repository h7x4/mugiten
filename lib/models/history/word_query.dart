class WordQuery {
  final String query;

  // TODO: Link query with results that the user clicks onto.
  // final List<WordResult> chosenResults;

  WordQuery({
    required this.query,
  });

  Map<String, Object?> toJson() => {'query': query};

  factory WordQuery.fromJson(Map<String, Object?> json) =>
      WordQuery(query: json['query'] as String);
}
