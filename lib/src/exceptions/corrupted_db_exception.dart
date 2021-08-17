class CorruptedDBException implements Exception {
  final String description;

  CorruptedDBException(this.description);

  @override
  String toString() => 'CorruptedDBException: $description';
}
