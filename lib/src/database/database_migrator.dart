import 'package:flutter_pack/src/app_utility/app_utility.dart';
import 'package:flutter_pack/src/model_manager.dart';
import 'package:sqflite/sqflite.dart';

abstract class BaseDatabaseMigrator {
  BaseDatabaseMigrator(this._models);
  final List<BaseDatabaseModel> _models;

  Future<void> syncTables(Database database) async {
    await _syncTables(database);
  }

  Future<void> _syncTables(Database database) async {
    List<String> currentTables = await _existingTables(database);
    for (BaseDatabaseModel model in _models) {
      if (!currentTables.contains(model.tableName)) await _createTable(database, model);
      List<String> currentColumns = await _existingColumns(database, model.tableName);
      List<MapEntry<String, String>> newColumns = model.toSchema.entries.toList();
      List<String> queries = [];
      for (MapEntry<String, String> entry in newColumns) {
        bool columnExists = currentColumns.contains(entry.key);
        if (columnExists) continue;
        queries.add("ALTER TABLE ${model.tableName} ADD COLUMN ${entry.key} ${entry.value};");
      }
      if (queries.isEmpty) continue;
      for (String query in queries) {
        await database.execute(query);
        AppUtility.log(query);
      }
    }
  }

  Future<void> _createTable<T extends BaseDatabaseModel>(Database db, T model) async {
    String query = _createTableQuery(model);
    await db.execute(query);
    AppUtility.log(query);
  }

  String _createTableQuery<T extends BaseDatabaseModel>(T model) {
    StringBuffer buffer = StringBuffer();
    Map<String, String> modelMap = model.toSchema;
    for (MapEntry<String, String> entry in modelMap.entries) {
      if (entry.value.contains("INTEGER PRIMARY KEY")) {
        buffer.write('${entry.key} ${entry.value} AUTOINCREMENT, ');
        continue;
      }
      buffer.write('${entry.key} ${entry.value}, ');
    }
    Map<String, Map<String, String>>? relations = model.dataRelation;
    if (relations != null) {
      for (MapEntry<String, Map<String, String>> entry in relations.entries) {
        buffer.write("FOREIGN KEY(${entry.key}) REFERENCES ${entry.value.keys.first}(${entry.value.values.first}), ");
      }
    }
    String tableValues = buffer.toString().replaceRange(buffer.length - 2, buffer.length, '');
    return 'CREATE TABLE IF NOT EXISTS ${model.tableName} ($tableValues);';
  }

  Future<List<String>> _existingTables(Database database) async {
    List<Map<String, dynamic>> tables = await database.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    return tables.map((table) => table["name"].toString()).toList();
  }

  Future<List<String>> _existingColumns(Database database, String table) async {
    List<Map<String, dynamic>> columns = await database.rawQuery("PRAGMA table_info($table)");
    return columns.map((column) => column["name"].toString()).toList();
  }
}
