import 'dart:convert';
import 'dart:io';

import 'package:dart_mongo_lite/src/exceptions/corrupted_db_exception.dart';

class Database {
  final String _dbPath;

  File _dbFile;
  Map<String, List<Map<String, dynamic>>> _dbContent;

  String get dbPath => _dbPath;

  Database(this._dbPath) {
    _dbFile = File(_dbPath);
    if (!_dbFile.existsSync()) {
      _dbFile.createSync(recursive: true);
      _dbFile.writeAsStringSync('{}');
    }
    var content = _dbFile.readAsStringSync();
    try {
      _dbContent = (json.decode(content) as Map<String, dynamic>).map((k, v) => MapEntry(k, List.from(v)));
    } on FormatException {
      throw CorruptedDBException('The database file exists and is not valid');
    }
  }

  void _commit() {
    var content = json.encode(_dbContent);
    _dbFile.writeAsStringSync(content);
  }

  Collection operator [](String collection) {
    if (!_dbContent.containsKey(collection)) {
      _dbContent[collection] = [];
    }
    return Collection(collection, this);
  }
}

class Collection {
  final String _name;
  final Database _db;

  Collection(this._name, this._db);

  /// Supports only not nested objects for now
  bool _applyFilter(Map<String, dynamic> value, Map<String, dynamic> filter) {
    if (filter == null) return true;
    for (var entry in filter.entries) {
      if (!value.containsKey(entry.key)) {
        return false;
      }
      if (value[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  int count() {
    return _db._dbContent[_name].length;
  }

  int drop() {
    var size = _db._dbContent[_name].length;
    _db._dbContent[_name] = [];
    _db._commit();
    return size;
  }

  List<Map<String, dynamic>> find({Map<String, dynamic> filter}) {
    return List.from(_db._dbContent[_name].where((e) => _applyFilter(e, filter)));
  }

  Map<String, dynamic> findOne({Map<String, dynamic> filter}) {
    return find().firstWhere((e) => _applyFilter(e, filter));
  }

  List<T> findAs<T>(T Function(Map<String, dynamic> v) predicate, {Map<String, dynamic> filter}) {
    return List.from(find(filter: filter).map(predicate));
  }

  T findOneAs<T>(T Function(Map<String, dynamic> v) predicate, {Map<String, dynamic> filter}) {
    return predicate(findOne(filter: filter));
  }

  void insert(Map<String, dynamic> entry) {
    _db._dbContent[_name].add(entry);
    _db._commit();
  }

  void insertMany(List<Map<String, dynamic>> entries) {
    _db._dbContent[_name].addAll(entries);
    _db._commit();
  }
}
