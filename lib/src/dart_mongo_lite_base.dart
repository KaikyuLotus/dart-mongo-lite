import 'dart:convert';
import 'dart:io';

import 'package:dart_mongo_lite/src/exceptions/corrupted_db_exception.dart';

class Database {
  late final String _dbPath;
  late File _dbFile;
  late Map<String, List<Map<String, dynamic>>> _dbContent;

  String get dbPath => _dbPath;

  Database(this._dbPath) {
    _dbFile = File(_dbPath);
    if (!_dbFile.existsSync()) {
      _dbFile.createSync(recursive: true);
      _dbFile.writeAsStringSync('{}');
    }
    _loadFileContent();
  }

  void _loadFileContent() {
    var content = _dbFile.readAsStringSync();
    try {
      _dbContent = (json.decode(content) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List.from(v)),
      );
    } on FormatException {
      throw CorruptedDBException('The database file exists and is not valid');
    }
  }

  void sync() {
    _loadFileContent();
  }

  void _commit() {
    var content = json.encode(_dbContent);
    _dbFile.writeAsStringSync(content);
  }

  List<Map<String, dynamic>> dbContent(String collection) {
    if (!_dbContent.containsKey(collection)) {
      _dbContent[collection] = [];
      _commit(); // Save the new collection, even if empty
    }

    return _dbContent[collection]!;
  }

  Collection operator [](String collection) {
    if (!_dbContent.containsKey(collection)) {
      _dbContent[collection] = [];
      _commit(); // Save the new collection, even if empty
    }
    return Collection(collection, this);
  }
}

class Collection {
  final String _name;
  final Database _db;

  Collection(this._name, this._db);

  /// Supports only not nested objects for now
  bool _applyFilter(Map<String, dynamic> value, Map<String, dynamic>? filter) {
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

  int count({Map<String, dynamic>? filter}) {
    return _db.dbContent(_name).where((e) => _applyFilter(e, filter)).length;
  }

  int drop() {
    var size = _db.dbContent(_name).length;
    _db._dbContent[_name] = [];
    _db._commit();
    return size;
  }

  List<Map<String, dynamic>> find({Map<String, dynamic>? filter}) {
    return List.from(
      _db.dbContent(_name).where((e) => _applyFilter(e, filter)),
    );
  }

  Map<String, dynamic>? findOne({Map<String, dynamic>? filter}) {
    try {
      return find().firstWhere(
        (e) => _applyFilter(e, filter),
      );
    } on StateError {
      return null;
    }
  }

  List<T> findAs<T>(
    T Function(Map<String, dynamic> v) predicate, {
    Map<String, dynamic>? filter,
  }) {
    return List.from(find(filter: filter).map(predicate));
  }

  T? findOneAs<T>(
    T Function(Map<String, dynamic> v) predicate, {
    Map<String, dynamic>? filter,
  }) {
    var found = findOne(filter: filter);
    if (found == null) return null;
    return predicate(found);
  }

  void insert(Map<String, dynamic> entry) {
    _db.dbContent(_name).add(entry);
    _db._commit();
  }

  void insertMany(List<Map<String, dynamic>> entries) {
    _db.dbContent(_name).addAll(entries);
    _db._commit();
  }

  bool update(
      Map<String, dynamic> filter, Map<String, dynamic> update, bool upsert) {
    for (var index = 0; index < _db.dbContent(_name).length; index++) {
      if (_applyFilter(_db.dbContent(_name)[index], filter)) {
        _db.dbContent(_name)[index] = update;
        _db._commit();
        return true;
      }
    }
    if (upsert) {
      _db[_name].insert(update);
      _db._commit();
      return true;
    }
    return false;
  }

  // Fined every document that matches filter and updates
  // all the fields based on update document
  bool modify(Map<String, dynamic> filter, Map<String, dynamic> update) {
    for (var index = 0; index < _db.dbContent(_name).length; index++) {
      if (_applyFilter(_db.dbContent(_name)[index], filter)) {
        for (var entry in update.entries) {
          _db.dbContent(_name)[index][entry.key] = entry.value;
        }
        _db._commit();
        return true;
      }
    }
    return false;
  }

  bool delete(Map<String, dynamic> filter) {
    var lenBefore = _db.dbContent(_name).length;
    _db.dbContent(_name).retainWhere((e) => !_applyFilter(e, filter));
    _db._commit();
    return lenBefore > _db.dbContent(_name).length;
  }
}
