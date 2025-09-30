import 'package:database_manager_package/generators/base_model_generator.dart';
import 'package:database_manager_package/generators/code_generator.dart';

class ProjectModelGenerator {
  ProjectModelGenerator._(this._generator);
  final BaseModelGenerator _generator;

  factory ProjectModelGenerator.of(BaseModelGenerator generator) {
    return ProjectModelGenerator._(generator);
  }

  String? get fileName => _generator.fileName;

  String template(String packageName) {
    StringBuffer buffer = StringBuffer();
    buffer.write("import 'package:$packageName/${CodeGenerator.modelFolder}/${_generator.fileName}.g.dart';");
    buffer.write("\n\n");
    buffer.write("/// * ---------- Auto Generated Code ---------- * ///");
    buffer.write("\n\n");
    buffer.write("class ${_generator.targetClassName} extends ${_generator.targetClassName}Gen {\n");
    buffer.write("\t");
    buffer.write(_generateConstructor);
    buffer.write("\n\n\t");
    if (_generator.tableName != null) {
      buffer.write(_generateFromMapper);
      buffer.write("\n\n\t");
    }
    buffer.write(_generateFromJson);
    buffer.write("\n\n");
    buffer.write("}");
    return buffer.toString();
  }

  String get _generateConstructor {
    Map<String, Type> properties = _generator.properties;
    StringBuffer buffer = StringBuffer();
    buffer.write("${_generator.targetClassName}({\n\t\t");
    String fields = properties.entries.map((entry) => "${entry.value.toString()}? ${entry.key}").join(",\n\t\t");
    buffer.write(fields);
    buffer.write("\n\t}): super(");
    String superFields = properties.entries.map((entry) => "${entry.key}").join(", ");
    buffer.write(superFields);
    buffer.write(");");
    return buffer.toString();
  }

  String get _generateFromMapper {
    StringBuffer buffer = StringBuffer();
    String targetFileName = _generator.targetClassName;
    buffer.write("factory $targetFileName.fromDatabase(Map<String, dynamic> map) {\n");
    buffer.write("\t\treturn ${targetFileName}Gen.fromDatabase(map);");
    buffer.write("\n\t}");
    return buffer.toString();
  }

  String get _generateFromJson {
    StringBuffer buffer = StringBuffer();
    String targetFileName = _generator.targetClassName;
    buffer.write("factory $targetFileName.fromJson(Map<String, dynamic> map) {\n");
    buffer.write("\t\treturn ${targetFileName}Gen.fromJson(map);");
    buffer.write("\n\t}");
    return buffer.toString();
  }
}
