import 'dart:convert';
import 'dart:io';

import 'package:dart_mongo_lite/src/exceptions/corrupted_db_exception.dart';

typedef JsonObject = Map<String, dynamic>;

typedef JsonArray = List<dynamic>;

typedef FilterCallback = bool Function(JsonObject);

class Database {
  final JsonEncoder _encoder;
  final String _dbPath;
  final File _dbFile;
  late Map<String, List<JsonObject>> _dbContent;

  List<String> get collectionsNames => _dbContent.keys.toList();

  List<Collection> get collections {
    return collectionsNames.map((c) => Collection(c, this)).toList();
  }

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

  void clear() {
    _dbContent = {};
    _commit();
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

  Iterable<JsonObject> _applyFilters({
    JsonObject? filter,
    FilterCallback? callback,
  }) {
    if (filter == null && callback == null) {
      return _db.dbContent(_name);
    }
    Iterable<JsonObject> content = _db.dbContent(_name);
    if (filter != null) {
      content = content.where((e) => _applyFilter(e, filter));
    }
    if (callback != null) {
      content = content.where(callback);
    }
    return content;
  }

  int count({JsonObject? filter, FilterCallback? callback}) {
    return _applyFilters(filter: filter, callback: callback).length;
  }

  int drop() {
    var size = _db.dbContent(_name).length;
    _db._dbContent[_name] = [];
    _db._commit();
    return size;
  }

  List<JsonObject> find({JsonObject? filter, FilterCallback? callback}) {
    return _applyFilters(filter: filter, callback: callback).toList();
  }

  JsonObject? findOne({JsonObject? filter, FilterCallback? callback}) {
    try {
      return _applyFilters(filter: filter, callback: callback).first;
    } on StateError {
      return null;
    }
  }

  List<T> findAs<T>(
    T Function(JsonObject v) predicate, {
    JsonObject? filter,
    FilterCallback? callback,
  }) {
    return find(filter: filter, callback: callback).map(predicate).toList();
  }

  T? findOneAs<T>(
    T Function(JsonObject v) predicate, {
    JsonObject? filter,
    FilterCallback? callback,
  }) {
    var found = findOne(filter: filter, callback: callback);
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

  List<JsonObject> update(
    JsonObject filter,
    JsonObject update, {
    FilterCallback? callback,
    bool upsert = false,
    bool multi = true,
  }) {
    var changes = <JsonObject>[];
    for (var element in _applyFilters(filter: filter, callback: callback)) {
      var index = _db.dbContent(_name).indexOf(element);
      changes.add(element);
      _db.dbContent(_name)[index] = update;
      _db._commit();
      if (!multi) {
        return changes;
      }
    }

    if (changes.isNotEmpty) return changes;

    if (upsert) {
      _db[_name].insert(update);
      return [];
    }

    return [];
  }

  bool delete({JsonObject? filter, FilterCallback? callback}) {
    if (filter == null && callback == null) return false;
    var lenBefore = _db.dbContent(_name).length;

    if (filter != null) {
      _db.dbContent(_name).removeWhere((e) => _applyFilter(e, filter));
    }
    if (callback != null) {
      _db.dbContent(_name).removeWhere(callback);
    }

    bool anyDeleted = lenBefore > _db.dbContent(_name).length;
    if (anyDeleted) {
      _db._commit();
    }
    return anyDeleted;
  }
}
