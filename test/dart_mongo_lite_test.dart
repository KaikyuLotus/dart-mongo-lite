import 'package:dart_mongo_lite/dart_mongo_lite.dart';
import 'package:test/test.dart';

void main() {
  late Database db;

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

    test('Filtering nested objects', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {
          'test': 'nested',
          'numbers': {
            'series': 1,
            'percentages': {
              'perc': 10,
            },
          },
        },
        {
          'test': 'nested',
          'numbers': {
            'series': 2,
            'percentages': {
              'perc': 20,
            },
          },
        },
      ]);
      var entries = coll.find(filter: {
        'test': 'nested',
        'numbers': {
          'percentages': {
            'perc': 20,
          },
        },
      });
      expect(entries.length, equals(1));
      expect(entries.first['numbers']['series'], equals(2));
    });
  });
}
