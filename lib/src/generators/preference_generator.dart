class PreferencesGenerator {
  PreferencesGenerator._();
  static final PreferencesGenerator _instance = PreferencesGenerator._();
  static PreferencesGenerator get instance => _instance;

  String template(String packageName) {
    StringBuffer buffer = StringBuffer();
    buffer.write("import 'package:flutter_pack/flutter_pack.dart';\n\n");
    buffer.write("class PrefKeys {\n\t");
    buffer.write("PrefKeys._();\n\n\t");
    buffer.write("static const String apiToken = \"api_token\";\n\t");
    buffer.write("static const String language = \"language\";\n\t");
    buffer.write("static const String darkMode = \"dark_mode\";\n");
    buffer.write("}\n\n");
    buffer.write("class Preferences extends BasePreferences {\n\t");
    buffer.write("Preferences._();\n\t");
    buffer.write("static final Preferences _instance = Preferences._();\n\t");
    buffer.write("static Preferences get instance => _instance;\n\n\t");
    buffer.write("Future<String?> get apiToken async => await fetch<String?>(PrefKeys.apiToken);\n\n\t");
    buffer.write("Future<String?> get language async => await fetch<String?>(PrefKeys.language);\n\n\t");
    buffer.write("Future<bool?> get darkMode async => await fetch<bool?>(PrefKeys.darkMode);\n");
    buffer.write("}");
    return buffer.toString();
  }
}
