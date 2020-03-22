class CorruptedDBException implements Exception {
  String description;

  CorruptedDBException(this.description);

  @override
  String toString() => 'CorruptedDBException: $description';
}
