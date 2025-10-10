class APIManagerGenerator {
  APIManagerGenerator._();
  static final APIManagerGenerator _instance = APIManagerGenerator._();
  static APIManagerGenerator get instance => _instance;

  String template(String packageName) {
    StringBuffer buffer = StringBuffer();
    buffer.write("import 'package:flutter_pack/flutter_pack.dart';\n");
    buffer.write("import 'package:$packageName/services/preferences.dart';\n");
    buffer.write("import 'package:flutter/foundation.dart';\n\n");
    buffer.write("class APIManager extends BaseAPIManager {\n\t");
    buffer.write("APIManager._(): super(_currentURL, _authorization);\n\t");
    buffer.write("static APIManager get instance => APIManager._();\n\n\t");
    buffer.write("static const String _localURL = \"http://127.0.0.1:8000/api/v1\";\n\t");
    buffer.write("static const String _baseURL = \"<Insert URL Here>/api/v1\";\n\t");
    buffer.write("static const String _releaseURL = \"<Insert URL Here>/api/v1\";\n\t");
    buffer.write("static const String _currentURL = kDebugMode ? _localURL : _releaseURL;\n\n\t");
    buffer.write("static Future<Map<String, String>?> _authorization() async {\n\t\t");
    buffer.write("Preferences preferences = Preferences.instance;\n\t\t");
    buffer.write("String? token = await preferences.fetch(PrefKeys.apiToken);\n\t\t");
    buffer.write("if (token == null) return null;\n\t\t");
    buffer.write("return {\"Authorization\": \"Bearer \$token\"};\n\t");
    buffer.write("}\n}");
    return buffer.toString();
  }
}
