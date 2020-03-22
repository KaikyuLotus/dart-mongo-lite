import 'package:dart_mongo_lite/dart_mongo_lite.dart';
import 'package:test/test.dart';

void main() {

  Database db;

  group('Smoke Tests', () {
    setUp(() {
      db = Database('resources/db');
    });

    test('A new collection should be empty', () {
      var coll = db['${DateTime.now()}'];
      expect(coll.count(), equals(0));
      expect(coll.find(), equals([]));
    });

    test('Inserting an item in a collection', () {
      var coll = db['${DateTime.now()}'];
      coll.insert({'test': 'value'});
      var entries = coll.find();
      expect(entries.length, equals(1));
      expect(entries.first['test'], equals('value'));
    });

  });
}
