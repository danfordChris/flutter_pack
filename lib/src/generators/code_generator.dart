import 'dart:io';

import 'package:flutter_pack/src/generators/api_manager_generator.dart';
import 'package:flutter_pack/src/generators/base_model_generator.dart';
import 'package:flutter_pack/src/generators/base_repository_generator.dart';
import 'package:flutter_pack/src/generators/preference_generator.dart';
import 'package:flutter_pack/src/generators/project_model_generator.dart';

class CodeGenerator {
  CodeGenerator._(this._packageName, this._generators);
  final String _packageName;
  final List<BaseModelGenerator> _generators;
  List<_FileMeta>? _files;

  factory CodeGenerator.of(String packageName, List<BaseModelGenerator> generators) {
    return CodeGenerator._(packageName, generators);
  }

  static String get modelFolder => "starter_models";

  void generate() {
    _generateModels();
  }

  void _generateModels() {
    _addFileMeta(_FileMeta._database(DatabaseGenerator.of(_generators)));
    _addFileMeta(_FileMeta._baseRepo(BaseRepositoryGenerator.instance));
    // _addFileMeta(_FileMeta._daoService(DAOClassGenerator.of(_generators)));
    _addFileMeta(_FileMeta._api(APIManagerGenerator.instance));
    _addFileMeta(_FileMeta._preferences(PreferencesGenerator.instance));
    // _addFileMeta(_FileMeta._workDispatcher(WorkDispatcherGenerator.instance));
    // _addFileMeta(_FileMeta._notification(NotificationServiceGenerator.instance));
    // _addFileMeta(_FileMeta._strings(StringsGenerator.instance));
    for (BaseModelGenerator generator in _generators) {
      _addModelGenerator(generator);
      _addProjectModelGenerator(generator.projectModelGenerator);
      if (generator.tableName == null) continue;
      _addRepositories(generator.repositoryGenerator);
      _addDAOs(generator.daoGenerator);
    }
    _generate();
  }

  void _addFileMeta(_FileMeta fileMeta) {
    this._files ??= [];
    this._files?.add(fileMeta);
  }

  void _addModelGenerator(BaseModelGenerator generator) {
    this._files ??= [];
    this._files?.add(_FileMeta._generator(generator));
  }

  void _addProjectModelGenerator(ProjectModelGenerator generator) {
    this._files ??= [];
    this._files?.add(_FileMeta._project(generator));
  }

  void _addRepositories(RepositoryGenerator generator) {
    this._files ??= [];
    this._files?.add(_FileMeta._repository(generator));
  }

  void _addDAOs(DAOGenerator generator) {
    _files ??= [];
    _files?.add(_FileMeta._dao(generator));
  }

  void _generate() {
    if (_files == null || _files!.isEmpty) return;
    for (_FileMeta fileMeta in _files!) {
      String? path = fileMeta._buildFolder;
      if (path == null) continue;
      Directory directory = Directory(path);
      directory.createSync(recursive: true);
      File output = File("${directory.path}/${fileMeta._fileName}.dart");
      if (fileMeta._ignoreExisting && output.existsSync()) continue;
      String? content = fileMeta._content(_packageName);
      if (content == null) continue;
      output.writeAsStringSync(content);
      print("[+] Generated File: ${output.path}");
    }
  }
}

class _FileMeta {
  BaseModelGenerator? _modelGenerator;
  ProjectModelGenerator? _projectModelGenerator;
  RepositoryGenerator? _repositoryGenerator;
  DAOGenerator? _daoGenerator;
  DatabaseGenerator? _databaseGenerator;
  BaseRepositoryGenerator? _baseRepositoryGenerator;
  DAOClassGenerator? _daoClassGenerator;
  APIManagerGenerator? _apiManagerGenerator;
  PreferencesGenerator? _preferencesGenerator;
  // WorkDispatcherGenerator? _workDispatcherGenerator;
  // NotificationServiceGenerator? _notificationServiceGenerator;
  // StringsGenerator? _stringsGenerator;

  _FileMeta._generator(this._modelGenerator);
  _FileMeta._project(this._projectModelGenerator);
  _FileMeta._repository(this._repositoryGenerator);
  _FileMeta._dao(this._daoGenerator);
  _FileMeta._database(this._databaseGenerator);
  _FileMeta._baseRepo(this._baseRepositoryGenerator);
  // _FileMeta._daoService(this._daoClassGenerator);
  _FileMeta._api(this._apiManagerGenerator);
  _FileMeta._preferences(this._preferencesGenerator);
  // _FileMeta._workDispatcher(this._workDispatcherGenerator);
  // _FileMeta._notification(this._notificationServiceGenerator);
  // _FileMeta._strings(this._stringsGenerator);

  bool get _ignoreExisting {
    if (_modelGenerator != null) return false;
    if (_daoGenerator != null) return false;
    if (_databaseGenerator != null) return false;
    if (_daoClassGenerator != null) return false;
    return true;
  }

  String? get _buildFolder {
    if (_modelGenerator != null) return "lib/${CodeGenerator.modelFolder}";
    if (_projectModelGenerator != null) return "lib/models";
    if (_repositoryGenerator != null) return "lib/repositories";
    if (_daoGenerator != null) return "lib/dao";
    if (_databaseGenerator != null) return "lib/services";
    if (_baseRepositoryGenerator != null) return "lib/repositories";
    if (_daoClassGenerator != null) return "lib/services";
    if (_preferencesGenerator != null) return "lib/services";
    if (_apiManagerGenerator != null) return "lib/services";
    // if (_workDispatcherGenerator != null) return "lib/services";
    // if (_notificationServiceGenerator != null) return "lib/services";
    // if (_stringsGenerator != null) return "lib/services";
    return null;
  }

  String? _content(String packageName) {
    if (_modelGenerator != null) return _modelGenerator?.template(packageName);
    if (_projectModelGenerator != null) return _projectModelGenerator?.template(packageName);
    if (_repositoryGenerator != null) return _repositoryGenerator?.template(packageName);
    if (_daoGenerator != null) return _daoGenerator?.template(packageName);
    if (_databaseGenerator != null) return _databaseGenerator?.template(packageName);
    if (_baseRepositoryGenerator != null) return _baseRepositoryGenerator?.template(packageName);
    if (_daoClassGenerator != null) return _daoClassGenerator?.template(packageName);
    if (_preferencesGenerator != null) return _preferencesGenerator?.template(packageName);
    if (_apiManagerGenerator != null) return _apiManagerGenerator?.template(packageName);
    // if (_workDispatcherGenerator != null) return _workDispatcherGenerator?.template(packageName);
    // if (_notificationServiceGenerator != null) return _notificationServiceGenerator?.template(packageName);
    // if (_stringsGenerator != null) return _stringsGenerator?.template(packageName);
    return null;
  }

  String? get _fileName {
    if (_modelGenerator != null) return "${_modelGenerator?.fileName}.g";
    if (_projectModelGenerator != null) return _projectModelGenerator?.fileName;
    if (_repositoryGenerator != null) return _repositoryGenerator?.fileName;
    if (_daoGenerator != null) return _daoGenerator?.fileName;
    if (_databaseGenerator != null) return "database_manager";
    if (_baseRepositoryGenerator != null) return "base_repository";
    if (_daoClassGenerator != null) return "dao_service";
    if (_preferencesGenerator != null) return "preferences";
    if (_apiManagerGenerator != null) return "api_manager";
    // if (_workDispatcherGenerator != null) return "work_dispatcher";
    // if (_notificationServiceGenerator != null) return "notification_service";
    // if (_stringsGenerator != null) return "localization_service";
    return null;
  }
}
