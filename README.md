# Dart Mongo Lite

Dart Mongo Lite is a library which emulates MongoDB in a very simple way.\
It doesn't require any server setup, data will be saved on a local file (specified in Database constructor).\
It's not optimized for huge quantity of data.

## Usage

A simple usage example:

```dart
void main() {
  var db = Database('resources/db.json');

  var dialogsCollection = db['dialogs'];
  var triggersCollection = db['triggers'];

  print('Dropped ${dialogsCollection.drop()} dialogs');
  print('Dropped ${triggersCollection.drop()} triggers');

  dialogsCollection.insertMany([
    {'dialog': 'Hello!', 'id': 1},
    {'dialog': 'Hi!', 'id': 0}
  ]);
  triggersCollection.insertMany([
    {'trigger': 'Hello', 'id': 1},
    {'trigger': 'Hi', 'id': 0}
  ]);

  triggersCollection.update({'id': 0}, {'trigger': 'Hiii trigger!'});
  dialogsCollection.update({'id': 1}, {'dialog': 'Hiii dialog!'});

  var dialog = dialogsCollection.findOneAs(
        (d) => Dialog.fromJson(d),
    filter: {'dialog': 'Hiii dialog!'},
  );
  print(dialog?.dialog);

  var trigger = triggersCollection.findOneAs(
        (t) => Trigger.fromJson(t),
    filter: {'trigger': 'Hiii trigger!'},
  );
}
```