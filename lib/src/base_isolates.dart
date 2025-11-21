import 'package:flutter/cupertino.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

abstract class BaseIsolate {
  BaseIsolate._();

  static Future<T?> executeBackground<T>(Future<T?> function) async {
    try {
      return await flutterCompute<T?, bool>((result) async => await function, true);
    } catch (exception) {
      debugPrint("ISOLATE EXCEPTION: $exception");
      return null;
    }
  }
}
