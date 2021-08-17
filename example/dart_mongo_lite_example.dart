import 'package:dart_mongo_lite/dart_mongo_lite.dart';

class Dialog {
  String? dialog;
  String? value;

  Dialog(this.dialog, this.value);

  factory Dialog.fromJson(Map<String, dynamic> json) {
    return Dialog(json['dialog'], json['value']);
  }
}

class Trigger {
  String? trigger;
  String? value;

  Trigger(this.trigger, this.value);

  factory Trigger.fromJson(Map<String, dynamic> json) {
    return Trigger(json['trigger'], json['value']);
  }
}

void main() {
  var db = Database('resources/db');

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

  var done = triggersCollection.modify({'id': 0}, {'trigger': 'Hiii trigger!'});
  print(done ? 'Trigger updated!' : 'Trigger not updated...');

  done = dialogsCollection.modify({'id': 1}, {'dialog': 'Hiii dialog!'});
  print(done ? 'Dialog updated!' : 'Dialog not updated...');

  var dialog = dialogsCollection.findOneAs(
    (d) => Dialog.fromJson(d),
    filter: {'dialog': 'Hiii dialog!'},
  );
  print(dialog?.dialog);

  var trigger = triggersCollection.findOneAs(
    (t) => Trigger.fromJson(t),
    filter: {'trigger': 'Hiii trigger!'},
  );
  print(trigger?.trigger);
}
