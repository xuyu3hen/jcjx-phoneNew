import 'dart:async';
import 'package:scan_gun/binding/scan_input_binding.dart';
import 'index.dart';

FutureOr<void> main() async {
    TextInputBinding();
    Global.init().then((e) => runApp(const MyApp()));
}