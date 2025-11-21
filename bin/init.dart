import 'dart:io';

import 'package:yaml/yaml.dart';

void main(List<String> args) {
  createCodeGeneratorIfMissing();
}

void createCodeGeneratorIfMissing() {
  final generatorFile = File('code_generator.dart');

  if (generatorFile.existsSync()) {
    print('code_generator.dart already exists. Skipping creation.');
    return;
  }

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found in current directory.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final pubspecYaml = loadYaml(pubspecContent);

  final appName = pubspecYaml['name'] ?? 'MyApp';
  print('App name detected: $appName');

  generatorFile.writeAsStringSync('''
import 'package:flutter_pack/flutter_pack.dart';

void main() {
  List<BaseModelGenerator> generator = [
  
  
    // .....................List of generator models......................... //
    
    // _SampleModel(),
    
    
  ];

  CodeGenerator.of('$appName', generator).generate();
}

// Example model generator template to get full reference, uncomment and modify as needed


// class _SampleModel extends BaseModelGenerator {
//   _SampleModel()
//       : super.database('dbTableName', {
//           'id': int,
//           'name': String,
//           // ...
//         });
// }
''');

  print('✅ code_generator.dart created successfully at project root.');
}
