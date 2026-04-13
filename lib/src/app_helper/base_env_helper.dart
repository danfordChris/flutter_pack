import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pack/flutter_pack.dart';

abstract class BaseEnvHelper {
  void init({String fileName = ".env"}) async {
    try {
      await dotenv.load(fileName: fileName);
      AppUtility.log("$fileName loaded");
    } catch (exception) {
      
      AppUtility.log(exception);
    }
  }

  static String? read(String key) {
    String? content = dotenv.env[key];
    if (content == null) throw new Exception("Key not set");
    return content;
  }

  static int? readInt(String key, {int? orElse}) {
    return dotenv.getInt(key, fallback: orElse);
  }

  static double? readDouble(String key, {double? orElse}) {
    return dotenv.getDouble(key, fallback: orElse);
  }

  static bool? readBool(String key, {bool? orElse}) {
    return dotenv.getBool(key, fallback: orElse);
  }
}
