import 'package:flutter_pack/src/extensions/string_generator_extension.dart';
import 'package:flutter_pack/src/generators/base_model_generator.dart';

class BaseRepositoryGenerator {
  BaseRepositoryGenerator._();
  static final BaseRepositoryGenerator _instance = BaseRepositoryGenerator._();
  static BaseRepositoryGenerator get instance => _instance;

  String template(String packageName) {
    StringBuffer buffer = StringBuffer();
    buffer.write("import 'package:flutter_pack/flutter_pack.dart';\n");
    buffer.write("import 'package:$packageName/services/database_manager.dart';");
    buffer.write("\n\n");
    buffer.write("/// * ---------- Auto Generated Code ---------- * ///");
    buffer.write("\n\n");
    buffer.write("abstract class BaseRepository<T extends BaseDatabaseModel> extends BaseDataRepository<T> {\n");
    buffer.write("\t");
    buffer.write(_generateConstructor);
    buffer.write("\n\n");
    buffer.write("}");
    return buffer.toString();
  }

  String get _generateConstructor {
    StringBuffer buffer = StringBuffer();
    buffer.write("BaseRepository(T model, T Function(Map<String, dynamic> map) generator): super(DatabaseManager.instance, model, generator);\n\t");
    return buffer.toString();
  }
}

class RepositoryGenerator {
  RepositoryGenerator._(this._modelGenerator);
  final BaseModelGenerator _modelGenerator;

  factory RepositoryGenerator.of(BaseModelGenerator generator) {
    return RepositoryGenerator._(generator);
  }

  String get _targetClassName => "${_modelGenerator.targetClassName.replaceAll("Model", "")}Repository";

  String? get fileName => _targetClassName.toSnakeCase;

  String template(String packageName) {
    StringBuffer buffer = StringBuffer();
    buffer.write("import 'package:$packageName/repositories/base_repository.dart';\n");
    buffer.write("import 'package:$packageName/models/${_modelGenerator.fileName}.dart';\n\n");
    buffer.write("/// * ---------- Auto Generated Code ---------- * ///\n\n");
    buffer.write("class ${_targetClassName} extends BaseRepository<${_modelGenerator.targetClassName}> {\n");
    buffer.write("\t");
    buffer.write(_generateConstructor);
    buffer.write("\n\n");
    buffer.write("}");
    return buffer.toString();
  }

  String get _generateConstructor {
    StringBuffer buffer = StringBuffer();
    buffer.write(
      "$_targetClassName._(): super(${_modelGenerator.targetClassName}(), (map) => ${_modelGenerator.targetClassName}.fromDatabase(map));\n\t",
    );
    buffer.write("static final $_targetClassName _instance = $_targetClassName._();\n\t");
    buffer.write("static $_targetClassName get instance => _instance;");
    return buffer.toString();
  }
}

class DatabaseGenerator {
  DatabaseGenerator._(this._generators);
  final List<BaseModelGenerator> _generators;

  factory DatabaseGenerator.of(List<BaseModelGenerator> generators) {
    return DatabaseGenerator._(generators);
  }

  String template(String packageName) {
    StringBuffer buffer = StringBuffer();
    buffer.write("import 'package:flutter_pack/flutter_pack.dart';\n");
    for (BaseModelGenerator generator in _generators) {
      if (generator.tableName == null) continue;
      buffer.write("import 'package:$packageName/models/${generator.fileName}.dart';\n");
    }
    buffer.write("\n");
    buffer.write("class DatabaseManager extends BaseDatabaseManager {\n\t");
    buffer.write("DatabaseManager._(): super(\"$packageName.db\", 1, _tables);\n\t");
    buffer.write("static final DatabaseManager _instance = DatabaseManager._();\n\t");
    buffer.write("static DatabaseManager get instance => _instance;\n\n\t");
    buffer.write("static List<BaseDatabaseModel> get _tables {\n\t\t");
    buffer.write("return [\n\t\t\t");
    String classes = _generators.where((element) => element.tableName != null).map((element) => "${element.targetClassName}()").join(",\n\t\t\t");
    buffer.write(classes);
    buffer.write("\n\t\t];\n\t}\n");
    buffer.write("}");
    return buffer.toString();
  }
}

class DAOGenerator {
  DAOGenerator._(this._generator);
  final BaseModelGenerator _generator;

  factory DAOGenerator.of(BaseModelGenerator generator) {
    return DAOGenerator._(generator);
  }

  String? get fileName => "${_generator.targetClassName}Dao".toSnakeCase;

  String template(String packageName) {
    StringBuffer buffer = StringBuffer();
    buffer.write("class ${_generator.targetClassName}DAO {\n\t");
    buffer.write("${_generator.targetClassName}DAO._();\n\n\t");
    if (_generator.tableName != null) buffer.write("static const String table = \"${_generator.tableName}\";\n\t");
    Map<String, Type> properties = _generator.properties;
    String fields = properties.entries.map((entry) => "static const String ${entry.key} = \"${entry.key.toSnakeCase}\";").join("\n\t");
    buffer.write(fields);
    buffer.write("\n");
    buffer.write("}");
    return buffer.toString();
  }
}

class DAOClassGenerator {
  DAOClassGenerator._(this._generators);
  final List<BaseModelGenerator> _generators;

  factory DAOClassGenerator.of(List<BaseModelGenerator> generators) {
    return DAOClassGenerator._(generators);
  }

  String template(String packageName) {
    StringBuffer buffer = StringBuffer();
    for (BaseModelGenerator generator in _generators) {
      String repoName = "${generator.targetClassName.replaceAll("Model", "")}Repository";
      buffer.write("import 'package:$packageName/repositories/${repoName.toSnakeCase}.dart';\n");
    }
    buffer.write("\n");
    buffer.write("class DAOService {\n\t");
    buffer.write("DAOService._();\n\n\t");
    for (BaseModelGenerator generator in _generators) {
      String repoName = "${generator.targetClassName.replaceAll("Model", "")}Repository";
      buffer.write("static $repoName get ${repoName.toSnakeCase.toCamelCase} => ${repoName}.instance;\n\t");
    }
    buffer.write("\n}");
    return buffer.toString();
  }
}
