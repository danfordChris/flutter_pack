import 'dart:io';

import 'init.dart' as init;

Future<void> main(List<String> args) async {
  // 🟢 1. Get the current working directory (the project using the package)
  final projectRoot = Directory.current.path;
  final generatorFile = File('$projectRoot/code_generator.dart');

  // 🟢 2. Check if code_generator.dart exists at project root
  if (!generatorFile.existsSync()) {
    print('⚠️  code_generator.dart not found at project root. Running init...');
    init.createCodeGeneratorIfMissing();
  } else {
    print('✅ code_generator.dart exists at project root. Skipping init.');
  }

  // 🟢 3. Determine Flutter executable (cross-platform)
  final flutterExec = _getFlutterExecutable();

  // 🟢 4. Run the project’s code_generator.dart
  print('\n🚀 Running code_generator.dart from: $projectRoot\n');
  final result = await Process.run(
    flutterExec,
    ['test', 'code_generator.dart'],
    workingDirectory: projectRoot,
    runInShell: true,
  );

  // 🟢 5. Output logs to console
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  // 🟢 6. Exit with proper code
  if (result.exitCode != 0) {
    print('\n❌ Error: code_generator.dart failed with exit code ${result.exitCode}.');
    exit(result.exitCode);
  }

  print('\n✅ Code generation complete.');
}

String _getFlutterExecutable() {
  // Cross-platform detection
  return Platform.isWindows ? 'flutter.bat' : 'flutter';
}
