import 'package:dart_mongo_lite/dart_mongo_lite.dart';

class Dialog {
  String dialog;
  String value;

  Dialog(this.dialog, this.value);

  factory Dialog.fromJson(Map<String, dynamic> json) {
    if (json == null) return null;
    return Dialog(json['dialog'], json['value']);
  }
}

class Trigger {
  String trigger;
  String value;

  Trigger(this.trigger, this.value);

  factory Trigger.fromJson(Map<String, dynamic> json) {
    if (json == null) return null;
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
