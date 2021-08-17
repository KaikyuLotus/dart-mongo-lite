import 'dart:convert';
import 'dart:io';

import 'package:dart_mongo_lite/src/exceptions/corrupted_db_exception.dart';

typedef JsonObject = Map<String, dynamic>;

typedef JsonArray = List<dynamic>;

class Database {
  final JsonEncoder _encoder;
  final String _dbPath;
  final File _dbFile;
  late Map<String, List<JsonObject>> _dbContent;

  String get dbPath => _dbPath;

  Database(
    this._dbPath, {
    bool pretty = false,
  })  : _encoder = JsonEncoder.withIndent(pretty ? '  ' : null),
        _dbFile = File(_dbPath) {
    if (!_dbFile.existsSync()) {
      _dbFile.createSync(recursive: true);
      _dbFile.writeAsStringSync('{}');
    }
    _loadFileContent();
  }

  void _loadFileContent() {
    var content = _dbFile.readAsStringSync();
    try {
      _dbContent = (json.decode(content) as JsonObject).map(
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
    var content = _encoder.convert(_dbContent);
    _dbFile.writeAsStringSync(content);
  }

  List<JsonObject> dbContent(String collection) {
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

  bool _compareArrays(JsonArray value, JsonArray filter) {
    if (filter.length > value.length) return false;
    if (filter is List<JsonObject>) {
      for (var i = 0; i < filter.length; i++) {
        var filterResult = _applyFilter(value[i], filter[i]);
        if (filterResult) continue;
        return false;
      }
      return true;
    }

    return filter.every((e) => value.contains(e));
  }

  bool _applyFilter(JsonObject value, JsonObject filter) {
    for (var entry in filter.entries) {
      var filterKey = entry.key;
      if (!value.containsKey(filterKey)) return false;

      var filterValue = entry.value;
      if (filterValue is JsonObject && value[filterKey] is JsonObject) {
        var nestedResult = _applyFilter(value[filterKey], filterValue);
        if (nestedResult) continue;
        return false;
      }
      if (filterValue is JsonArray && value[filterKey] is JsonArray) {
        var arrayComparison = _compareArrays(filterValue, value[filterKey]);
        if (arrayComparison) continue;
        return false;
      }
      if (value[filterKey] != filterValue) return false;
    }
    return true;
  }

  int count({JsonObject? filter}) {
    if (filter == null) {
      return _db.dbContent(_name).length;
    }
    return _db.dbContent(_name).where((e) => _applyFilter(e, filter)).length;
  }

  int drop() {
    var size = _db.dbContent(_name).length;
    _db._dbContent[_name] = [];
    _db._commit();
    return size;
  }

  List<JsonObject> find({JsonObject? filter}) {
    if (filter == null) {
      return _db.dbContent(_name);
    }
    return _db.dbContent(_name).where((e) => _applyFilter(e, filter)).toList();
  }

  JsonObject? findOne({JsonObject? filter}) {
    try {
      if (filter == null) {
        return find().first;
      }
      return find().firstWhere((e) => _applyFilter(e, filter));
    } on StateError {
      return null;
    }
  }

  List<T> findAs<T>(T Function(JsonObject v) predicate, {JsonObject? filter}) {
    return find(filter: filter).map(predicate).toList();
  }

  T? findOneAs<T>(T Function(JsonObject v) predicate, {JsonObject? filter}) {
    var found = findOne(filter: filter);
    if (found == null) return null;
    return predicate(found);
  }

  void insert(JsonObject entry) {
    _db.dbContent(_name).add(entry);
    _db._commit();
  }

  void insertMany(List<JsonObject> entries) {
    _db.dbContent(_name).addAll(entries);
    _db._commit();
  }

  bool update(JsonObject filter, JsonObject update, bool upsert) {
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

  // Find every document that matches filter and updates
  // all the fields based on update document
  bool modify(JsonObject filter, JsonObject update) {
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

  bool delete(JsonObject filter) {
    var lenBefore = _db.dbContent(_name).length;
    _db.dbContent(_name).removeWhere((e) => _applyFilter(e, filter));
    _db._commit();
    return lenBefore > _db.dbContent(_name).length;
  }
}
