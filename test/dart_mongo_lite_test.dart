import 'package:dart_mongo_lite/dart_mongo_lite.dart';
import 'package:test/test.dart';

void main() {
  late Database db;

  group('Smoke Tests', () {
    setUp(() {
      db = Database('resources/db.json');
      db.clear();
    });

    test('Database clear works', () {
      var coll = db['${DateTime.now()}'];
      coll.insert({'hello': 'world'});
      expect(coll.findOne(), isNotNull);
      db.clear();
      expect(coll.findOne(), isNull);
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
          'numbers': {
            'series': 1,
            'percentages': [
              {
                'values': [
                  {'first': 10, 'second': 20}
                ]
              }
            ]
          },
        },
        {
          'numbers': {
            'series': 2,
            'percentages': [
              {
                'values': [
                  {'first': 20, 'second': 30}
                ]
              }
            ]
          },
        },
        {
          'numbers': {
            'series': 3,
            'percentages': [
              {
                'values': [
                  {'first': 20, 'second': 30}
                ]
              }
            ]
          },
        },
      ]);
      var entries = coll.find(filter: {
        'numbers': {
          'percentages': [
            {
              'values': [
                {'first': 20, 'second': 30}
              ]
            }
          ]
        }
      });
      expect(entries.length, equals(2));
    });

    test('Counting with filter callback', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {"key": 1, "value": 2},
        {"key": 1, "value": 7}
      ]);
      expect(coll.count(callback: (e) => e['value'] > 5), equals(1));
    });

    test('Counting with filter', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {"key": 1, "value": 2},
        {"key": 1, "value": 7}
      ]);
      expect(coll.count(filter: {'value': 7}), equals(1));
    });

    test('Counting with filter and filter callback', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {"key": 1, "value": 2},
        {"key": 1, "value": 7},
        {"key": 2, "value": 0}
      ]);
      expect(
        coll.count(
          filter: {'key': 1},
          callback: (e) => e['value'] < 5,
        ),
        equals(1),
      );
    });

    test('Update existing value', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {"key": 1, "value": 2},
        {"key": 2, "value": 7}
      ]);
      coll.update({'key': 1}, {"key": 1, "value": 3}, upsert: false);
      var key1 = coll.findOne(filter: {'key': 1});
      expect(key1, isNotNull);
      expect(key1!['value'], equals(3));
    });

    test('Update existing complex', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {
          "key": 1,
          "value": ['a']
        },
        {
          "key": 2,
          "value": ['c']
        },
        {
          "key": 3,
          "value": [2]
        }
      ]);
      coll.update(
        {'key': 2},
        {
          "key": 2,
          "value": [4]
        },
        upsert: false,
      );
      var key1 = coll.findOne(filter: {'key': 2});
      expect(key1, isNotNull);
      expect(key1!['value'], equals([4]));
    });

    test('Update existing more complex', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {
          "key": 1,
          "value": ['a']
        },
        {
          "key": 2,
          "value": ['c', 'd', 7]
        },
        {
          "key": 2,
          "value": ['c', 'd', 7]
        },
        {
          "key": 3,
          "value": [2]
        }
      ]);
      coll.update(
        {
          'key': 2,
        },
        {
          "key": 3,
          "value": [
            {'test': true}
          ]
        },
        upsert: false,
        multi: false,
      );
      var results = coll.find(
        filter: {
          'key': 3,
          'value': [
            {'test': true}
          ]
        },
      );
      expect(results.length, equals(1));
      expect(results[0]['value'][0]['test'], equals(true));
    });

    test('Filter delete works', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {"key": 1, "value": 2},
        {"key": 2, "value": 7}
      ]);
      coll.delete(filter: {'key': 2});
      var result = coll.findOne(filter: {'key': 2});
      expect(result, isNull);
    });

    test('Callback delete works', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {"key": 1, "value": 2},
        {"key": 2, "value": 7}
      ]);
      var deleted = coll.delete(callback: (e) => e['key'] > 1);
      var result = coll.findOne(filter: {'key': 2});
      expect(deleted, true);
      expect(result, isNull);
    });

    test('Callback delete works', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {"key": 1, "value": 2},
        {"key": 2, "value": 7}
      ]);
      var deleted = coll.delete(callback: (e) => e['key'] > 1);
      var result = coll.findOne(filter: {'key': 2});
      expect(deleted, true);
      expect(result, isNull);
    });

    test('Callback and Filter delete works', () {
      var coll = db['${DateTime.now()}'];
      coll.insertMany([
        {"key": 1, "value": 2},
        {"key": 2, "value": 7}
      ]);
      var deleted = coll.delete(
        callback: (e) => e['key'] > 1,
        filter: {'key': 1},
      );
      expect(deleted, true);
      expect(coll.count(), 0);
    });
  });
}
