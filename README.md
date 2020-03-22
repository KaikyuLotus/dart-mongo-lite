A library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
void main() {
  var db = Database('resources/db');

  var dialogsCollection = db['dialogs'];
  var triggersCollection = db['triggers'];

  print('Dropped ${dialogsCollection.drop()} dialogs');
  print('Dropped ${triggersCollection.drop()} triggers');

  dialogsCollection.insertMany([
    {'dialog': 'Ciao!'},
    {'dialog': 'Salve!'}
  ]);
  triggersCollection.insertMany([
    {'trigger': 'Ciao'},
    {'trigger': 'Salve'}
  ]);

  var dialog = dialogsCollection.findOneAs((d) => Dialog.fromJson(d), filter: {'dialog': 'Ciao!'});
  print(dialog.dialog);

  var trigger = triggersCollection.findOneAs((t) => Trigger.fromJson(t), filter: {'trigger': 'Salve'});
  print(trigger.trigger);
}
```