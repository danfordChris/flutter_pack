import 'package:collection/collection.dart';

abstract class BaseModel extends ModelMapMixin {
  static final List<String?> _exclusions = [null, "null", ""];

  static T? valueOrNull<T>(Map<String, dynamic> map, String key, T Function(Map<String, dynamic> map) generator) {
    if (map[key] is String) return null;
    return (map[key] == null) ? null : generator(map[key]);
  }

  static T? enumOrNull<T>(Map<String, dynamic> map, String key, List<T> enumValues) {
    if (map[key] == null) return null;
    int? index = castToInt(map[key]);
    if (index == null) return null;
    return enumValues[index];
  }

  static T? valuedEnum<T extends Enum, V>(V value, List<T> enumValues, int Function(T target) selector) {
    return enumValues.firstWhereOrNull((element) => selector(element) == BaseModel.castToInt(value));
  }

  static String castToString<T>(T cast) {
    if (_exclusions.contains(cast)) return "";
    return cast.toString();
  }

  static int? castToInt<T>(T cast) {
    if (cast == null) return null;
    if (cast is int) return cast;
    if (cast is double) return cast.toInt();
    if (cast is String) {
      final formatted = cast.replaceAll(RegExp(r"[^\d.]"), "");
      return int.parse(formatted);
    }
    return int.parse(cast.toString());
  }

  static double? castToDouble<T>(T cast) {
    if (cast == null) return null;
    if (cast is double) return cast;
    if (cast is int) return cast.toDouble();
    if (cast is String) {
      final formatted = cast.replaceAll(RegExp(r"[^\d.]"), "");
      return double.parse(formatted);
    }
    return double.parse(cast.toString());
  }

  static bool? castToBool<T>(T cast) {
    if (cast == null) return null;
    if (cast is bool) return cast;
    if (cast is String) return cast == "true";
    return cast == 1;
  }

  static T? parse<T>(Map<String, dynamic>? map, T Function(Map<String, dynamic> map) generator) {
    if (map == null) return null;
    return generator(map);
  }

  static List<T> parseList<T>(List<dynamic>? map, T Function(Map<String, dynamic> map) generator) {
    if (map == null) return [];
    return List.generate(map.length, (index) => generator(map[index]));
  }

  List<String?> get searchTerms => [];

  bool toSearch(String term) {
    bool matches = false;
    for (String? target in searchTerms) {
      if (target == null) continue;
      matches = target.toLowerCase().contains(term.toLowerCase());
      if (matches) break;
    }
    return matches;
  }

  String baseNameInitial(String? name) {
    if (name == null) return "-";
    List<String> separators = name.split(" ").take(2).toList();
    StringBuffer buffer = StringBuffer();
    for (String separator in separators) {
      if (separator.isEmpty) continue;
      String initial = separator.substring(0, 1);
      buffer.write(initial.toUpperCase());
    }
    return buffer.toString();
  }
}

// abstract class BaseDatabaseModel extends BaseModel implements ModelDatabaseMapMixin {}

abstract class ModelMapMixin {
  Map<String, dynamic> get toMap;

  Map<String, dynamic> get mapWithoutId {
    Map<String, dynamic> map = toMap;
    map.removeWhere((key, value) => key == "id");
    return map;
  }
}

abstract class ModelDatabaseMapMixin extends ModelMapMixin {
  String get tableName;
  Map<String, String> get toSchema;
  Map<String, Map<String, String>>? get dataRelation => null;
}
