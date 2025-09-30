import 'package:database_manager_package/extensions/string_generator_extension.dart';
import 'package:database_manager_package/generators/base_repository_generator.dart';
import 'package:database_manager_package/generators/project_model_generator.dart';

enum _RelationType { _one, _many }

class ModelRelation {
  final String _title;
  final List<BaseModelGenerator> _relations;
  final _RelationType _relationType;

  ModelRelation.one(this._title, this._relations) : _relationType = _RelationType._one;
  ModelRelation.many(this._title, this._relations) : _relationType = _RelationType._many;
}

abstract class BaseModelGenerator {
  final Map<String, Type> _properties;
  String? _table;
  List<ModelRelation>? _relations;

  BaseModelGenerator(this._properties);

  BaseModelGenerator.database(this._table, this._properties, {List<ModelRelation>? relations}) : _relations = relations;

  String? get tableName => _table;
  Map<String, Type> get properties => _properties;

  String get targetClassName => "${_formattedClassName}Model";

  String get _className => "${targetClassName}Gen";

  String? get fileName => targetClassName.toSnakeCase;

  String get _formattedClassName {
    String className = this.runtimeType.toString();
    if (!className.startsWith("_")) return className;
    return className.substring(1, className.length);
  }

  bool get _hasDatabaseTable => this._table != null;

  RepositoryGenerator get repositoryGenerator => RepositoryGenerator.of(this);

  ProjectModelGenerator get projectModelGenerator => ProjectModelGenerator.of(this);

  DAOGenerator get daoGenerator => DAOGenerator.of(this);

  String template(String packageName) {
    StringBuffer buffer = StringBuffer();
    buffer.write("import 'package:$packageName/models/${fileName}.dart';\n");
    buffer.write("import 'package:ipf_flutter_starter_pack/ipf_flutter_starter_pack.dart';");
    if (_relations != null) {
      buffer.write("\n");
      buffer.write(_generateRelationImports(packageName));
    }
    buffer.write("\n\n");
    buffer.write("/// * ---------- Auto Generated Code ---------- * ///");
    buffer.write("\n\n");
    buffer.write("class $_className ${_hasDatabaseTable ? "extends BaseDatabaseModel " : ""}{\n");
    buffer.write("\t");
    buffer.write(_generateFields);
    buffer.write("\n\t");
    buffer.write(_generateConstructor);
    buffer.write("\n\n\t");
    buffer.write(_generateGettersAndSetters);
    buffer.write("\n\t");
    buffer.write(_generateFromJSON);
    buffer.write("\n\n\t");
    if (_hasDatabaseTable) {
      buffer.write(_generateFromMapper);
      buffer.write("\n\n\t");
      buffer.write(_generateTableName);
      buffer.write("\n\n\t");
      buffer.write(_generateToMap);
      buffer.write("\n\n\t");
    }
    buffer.write(_generateToJSON);
    buffer.write("\n\n\t");
    if (_hasDatabaseTable) {
      buffer.write(_generateToSchema);
      buffer.write("\n\n\t");
    }
    buffer.write(_generateMerger);
    if (_hasDatabaseTable) {
      buffer.write("\n\n\t");
      buffer.write(_generateRelations);
    }
    String? relationQueries = _generateRelationQueries;
    if (relationQueries != null) {
      buffer.write("\n\n\t");
      buffer.write(relationQueries);
    }
    buffer.write("\n\n");
    buffer.write("}");
    return buffer.toString();
  }

  String _generateRelationImports(String packageName) {
    StringBuffer buffer = StringBuffer();
    for (ModelRelation modelRelation in _relations!) {
      for (BaseModelGenerator generator in modelRelation._relations) {
        String repositoryFile = "${generator.targetClassName.replaceAll("Model", "")}Repository";
        buffer.write("import 'package:$packageName/models/${generator.targetClassName.toSnakeCase}.dart';\n");
        buffer.write("import 'package:$packageName/repositories/${repositoryFile.toSnakeCase}.dart';\n");
      }
    }
    return buffer.toString();
  }

  String get _generateFields {
    StringBuffer buffer = StringBuffer();
    for (MapEntry<String, Type> entry in _properties.entries) {
      buffer.write("${entry.value.toString()}? _${entry.key};");
      buffer.write("\n\t");
    }
    return buffer.toString();
  }

  String get _generateConstructor {
    StringBuffer buffer = StringBuffer();
    buffer.write("$_className(");
    for (String key in _properties.keys) {
      buffer.write("this._$key, ");
    }
    buffer.write(");");
    return buffer.toString();
  }

  String get _generateGettersAndSetters {
    StringBuffer buffer = StringBuffer();
    Iterable<MapEntry<String, Type>> entries = _properties.entries;
    for (MapEntry<String, Type> entry in entries) {
      buffer.write("${entry.value.toString()}? get ${entry.key} => _${entry.key};");
      buffer.write("\n\t");
    }
    buffer.write("\n\t");
    for (MapEntry<String, Type> entry in entries) {
      buffer.write("set ${entry.key}(${entry.value.toString()}? ${entry.key}) => this._${entry.key} = ${entry.key};");
      buffer.write("\n\t");
    }
    return buffer.toString();
  }

  String get _generateFromMapper {
    return _generateFrom(true);
  }

  String get _generateFromJSON {
    return _generateFrom(false);
  }

  String _generateFrom(bool fromDatabase) {
    StringBuffer buffer = StringBuffer();
    String targetFileName = targetClassName;
    buffer.write("static $targetFileName ${fromDatabase ? "fromDatabase" : "fromJson"}(Map<String, dynamic> map) {\n");
    buffer.write("\t\treturn $targetFileName(");
    for (MapEntry<String, Type> entry in _properties.entries) {
      String? mapField = fromDatabase ? entry.key.toSnakeCase : entry.key;
      if (mapField == null) continue;
      String mapper = "map['$mapField']";
      String defineType() {
        switch (entry.value) {
          case int:
            return "BaseModel.castToInt($mapper)";
          case double:
            return "BaseModel.castToDouble($mapper)";
          case bool:
            return "BaseModel.castToBool($mapper)";
          default:
            return mapper;
        }
      }

      buffer.write("${entry.key}: ${defineType()}");
      buffer.write(", ");
    }
    buffer.write(");\n\t}");
    return buffer.toString();
  }

  String get _generateTableName {
    StringBuffer buffer = StringBuffer();
    buffer.write("@override\n\t");
    buffer.write("String get tableName => \"$_table\";");
    return buffer.toString();
  }

  String get _generateToMap {
    return _generateTo(true);
  }

  String get _generateToJSON {
    return _generateTo(false);
  }

  String _generateTo(bool toDatabase) {
    StringBuffer buffer = StringBuffer();
    if (toDatabase) buffer.write("@override\n\t");
    buffer.write("Map<String, dynamic> get ${toDatabase ? "toMap" : "toJson"} {\n");
    buffer.write("\t\treturn { ");
    for (MapEntry<String, Type> entry in _properties.entries) {
      String? field = toDatabase ? entry.key.toSnakeCase : entry.key;
      if (field == null) continue;
      bool isBooleanDatabase = toDatabase && entry.value == bool;
      String targetValue = isBooleanDatabase ? "${entry.key} == null ? null : (${entry.key} != null && ${entry.key}!) ? 1 : 0" : entry.key;
      buffer.write("\"$field\": $targetValue, ");
    }
    buffer.write("};\n\t}");
    return buffer.toString();
  }

  String get _generateToSchema {
    StringBuffer buffer = StringBuffer();
    buffer.write("@override\n\t");
    buffer.write("Map<String, String> get toSchema {\n");
    buffer.write("\t\treturn { ");
    for (MapEntry<String, Type> entry in _properties.entries) {
      String? field = entry.key.toSnakeCase;
      if (field == null) continue;
      String fieldType = _defineField(entry.value);
      if (entry.key == "id") {
        String withPrimaryKey = (entry.value is int) ? "PRIMARY KEY AUTOINCREMENT" : "PRIMARY KEY";
        buffer.write("\"$field\": \"$fieldType $withPrimaryKey\", ");
        continue;
      }
      buffer.write("\"$field\": \"$fieldType\", ");
    }
    buffer.write("};\n\t}");
    return buffer.toString();
  }

  String get _generateRelations {
    StringBuffer buffer = StringBuffer();
    buffer.write("@override\n\t");
    buffer.write("Map<String, Map<String, String>>? get dataRelation => null;");
    return buffer.toString();
  }

  String get _generateMerger {
    StringBuffer buffer = StringBuffer();
    buffer.write("$targetClassName merge($targetClassName model) {\n");
    buffer.write("\t\treturn $targetClassName(\n\t\t\t");
    String mappedProperties = _properties.entries.map((entry) => "${entry.key}: model.${entry.key} ?? this._${entry.key}").join(",\n\t\t\t");
    buffer.write(mappedProperties);
    buffer.write("\n\t\t);\n\t}");
    return buffer.toString();
  }

  String? get _generateRelationQueries {
    if (_relations == null) return null;
    StringBuffer buffer = StringBuffer();
    for (ModelRelation relation in _relations!) {
      for (BaseModelGenerator generator in relation._relations) {
        String repositoryName = "${generator.targetClassName.replaceAll("Model", "")}Repository";
        String variableRepository = repositoryName.toSnakeCase.toCamelCase;
        if (relation._relationType == _RelationType._one) {
          buffer.write(
            "Future<${generator.targetClassName}?> get ${generator.targetClassName.replaceAll("Model", "").toSnakeCase.toCamelCase} async {\n\t\t",
          );
          buffer.write("$repositoryName $variableRepository = $repositoryName.instance;\n\t\t");
          buffer.write("return await $variableRepository.findWhere(\"${relation._title.toSnakeCase} = ?\", [_id]);\n\t");
          buffer.write("}\n\n\t");
          continue;
        }
        buffer.write(
          "Future<List<${generator.targetClassName}>> get ${generator.targetClassName.replaceAll("Model", "").toSnakeCase.toCamelCase}Many async {\n\t\t",
        );
        buffer.write("$repositoryName $variableRepository = $repositoryName.instance;\n\t\t");
        buffer.write("return await $variableRepository.findAllWhere(\"${relation._title.toSnakeCase} = ?\", [_id]);\n\t");
        buffer.write("}\n\n\t");
      }
    }
    String result = buffer.toString();
    return result.substring(0, result.length - 3);
  }

  String _defineField(Type field) {
    switch (field) {
      case String:
        return "TEXT";
      case int:
      case bool:
        return "INTEGER";
      case double:
        return "REAL";
      default:
        return "NULL";
    }
  }
}
