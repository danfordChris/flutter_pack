import 'dart:io';

import 'package:database_manager_package/app_utility/app_utility_logging.dart';
import 'package:database_manager_package/database/database_migrator.dart';
import 'package:database_manager_package/model_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

// import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite_encrypted;

abstract class BaseDatabaseManager extends BaseDatabaseMigrator {
  BaseDatabaseManager(this._dbName, this._dbVersion, this._models) : _encrypted = false, super(_models);
  // BaseDatabaseManager.encrypted(this._dbName, this._dbVersion, this._models): _encrypted = true, super(_models);

  sqflite.Database? _database;
  final String _dbName;
  final int _dbVersion;
  final List<BaseDatabaseModel> _models;
  final bool _encrypted;

  Future<sqflite.Database> get _instanceDatabase async {
    if (_database != null) return _database!;
    // if (_encrypted) return _encryptedDatabase;
    String databasePath = join(await sqflite.getDatabasesPath(), _dbName);
    _database = await sqflite.openDatabase(
      databasePath,
      onCreate: (db, version) async => await _onCreate(db, version),
      onUpgrade: (db, oldVersion, newVersion) async => await _onUpgrade(db, oldVersion, newVersion),
      onOpen: (db) async => await _onOpen(db),
      version: _dbVersion,
    );
    return _database!;
  }

  // Future<sqflite_encrypted.Database> get _encryptedDatabase async {
  //   if (_database != null) return _database!;
  //   String databasePath = join(await sqflite_encrypted.getDatabasesPath(), _dbName);
  //   _database = await sqflite_encrypted.openDatabase(databasePath,
  //       onCreate: (db, version) async => await _onCreate(db, version),
  //       onUpgrade: (db, oldVersion, newVersion) async => await _onUpgrade(db, oldVersion, newVersion),
  //       onOpen: (db) async => await _onOpen(db),
  //       password: "#StandOut2015",
  //       version: _dbVersion,
  //   );
  //   return _database!;
  // }

  void init() async {
    await _instanceDatabase;
    _backupDatabase();
  }

  void _backupDatabase() async {
    try {
      if (!Platform.isAndroid) return;
      String databasePath = join(await sqflite.getDatabasesPath(), _dbName);
      File databaseFile = File(databasePath);
      if (!await databaseFile.exists()) {
        AppUtility.log("Database file does not exist");
        return;
      }
      Directory targetDirectoryPath = await StarterStorage.storagePath(suffix: "database", file: _dbName);
      File copiedDatabase = await databaseFile.copy(targetDirectoryPath.path);
      if (!await copiedDatabase.exists()) {
        AppUtility.log("Database failed to export");
        return;
      }
      AppUtility.log("Database Exported Successfully");
    } catch (exception) {
      AppUtility.log(exception);
    }
  }

  Future<void> _onCreate(sqflite.Database db, int _) async {
    await syncTables(db);
  }

  Future<void> _onUpgrade(sqflite.Database db, int _, int __) async {
    await syncTables(db);
  }

  Future<void> _onOpen(sqflite.Database db) async {
    await syncTables(db);
  }

  void _logError(Object error) {
    AppUtility.log("[ DATABASE ] - $error");
  }

  Future<List<T>> all<T extends BaseDatabaseModel>(String table, T Function(Map<String, dynamic> map) generator) async {
    sqflite.Database db = await _instanceDatabase;
    List<Map<String, dynamic>> results = await db.query(table);
    if (results.isEmpty) return [];
    return List.generate(results.length, (index) => generator(results[index]));
  }

  Future<List<Map<String, dynamic>>> rawQuery(String query, [List<Object?>? args]) async {
    sqflite.Database db = await _instanceDatabase;
    return await db.rawQuery(query, args);
  }

  Future<List<T>> fromQuery<T extends BaseDatabaseModel>(String query, T Function(Map<String, dynamic> map) generator) async {
    sqflite.Database db = await _instanceDatabase;
    List<Map<String, dynamic>> results = await db.rawQuery(query);
    if (results.isEmpty) return [];
    return List.generate(results.length, (index) => generator(results[index]));
  }

  Future<T?> save<T extends BaseDatabaseModel>(T model) async {
    return await _transactOrFail((transaction) async {
      try {
        int result = await transaction.insert(model.tableName, model.toMap, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
        return result != null ? model : null;
      } catch (exception) {
        _logError(exception);
        return null;
      }
    });
  }

  Future<bool> saveBatch<T extends BaseDatabaseModel>(List<T> models) async {
    return await _transactOrFail((transaction) async {
      try {
        for (T model in models) {
          await transaction.insert(model.tableName, model.toMap, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
        }
        return true;
      } catch (exception) {
        _logError(exception);
        return false;
      }
    });
  }

  Future<bool> replaceBatch<T extends BaseDatabaseModel>(List<T> models) async {
    return await _transactOrFail((transaction) async {
      try {
        await transaction.delete(models.first.tableName);
        for (T model in models) {
          await transaction.insert(model.tableName, model.toMap, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
        }
        return true;
      } catch (exception) {
        _logError(exception);
        return false;
      }
    });
  }

  Future<bool> insertOrUpdateBy<T extends BaseDatabaseModel>(List<T> models, String key) async {
    return await _transactOrFail((transaction) async {
      try {
        for (T model in models) {
          Map<String, dynamic> data = model.mapWithoutId;
          String targetValue = data[key];
          List<Map<String, dynamic>> results = await transaction.query(model.tableName, where: "$key = ?", whereArgs: [targetValue]);
          if (results.isEmpty) {
            await transaction.insert(model.tableName, data, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
          } else {
            await transaction.update(
              model.tableName,
              data,
              where: "$key = ?",
              whereArgs: [targetValue],
              conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
            );
          }
        }
        return true;
      } catch (exception) {
        _logError(exception);
        return false;
      }
    });
  }

  Future<T> _transactOrFail<T>(Future<T> Function(sqflite.Transaction transaction) function) async {
    sqflite.Database db = await _instanceDatabase;
    return await db.transaction((txn) async => await function(txn));
  }

  Future<T?> update<T extends BaseDatabaseModel>(T model, String where, List<Object?> values) async {
    return await _transactOrFail((transaction) async {
      try {
        int result = await transaction.update(
          model.tableName,
          model.mapWithoutId,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
          where: where,
          whereArgs: values,
        );
        return result != null ? model : null;
      } catch (exception) {
        _logError(exception);
        return null;
      }
    });
  }

  Future<bool> updateWhere<T extends BaseDatabaseModel>(String table, Map<String, dynamic> values, String where, List<Object?> args) async {
    return await _transactOrFail((transaction) async {
      try {
        await transaction.update(table, values, conflictAlgorithm: sqflite.ConflictAlgorithm.replace, where: where, whereArgs: args);
        return true;
      } catch (exception) {
        _logError(exception);
        return false;
      }
    });
  }

  Future<List<T>> findAllBy<T>(String table, String where, List<Object?> values, T Function(Map<String, dynamic> map) generator) async {
    sqflite.Database db = await _instanceDatabase;
    List<Map<String, dynamic>> results = await db.query(table, where: where, whereArgs: values);
    if (results.isEmpty) return [];
    return List.generate(results.length, (index) => generator(results[index]));
  }

  Future<T?> findBy<T>(String table, String where, List<Object?> values, T Function(Map<String, dynamic> map) generator) async {
    List<T> results = await findAllBy(table, where, values, (map) => generator(map));
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<T?> delete<T extends BaseDatabaseModel>(T model) async {
    return await _transactOrFail((transaction) async {
      try {
        int? result = await transaction.delete(model.tableName, where: "id = ?", whereArgs: [model.toMap["id"]]);
        return result == 1 ? model : null;
      } catch (exception) {
        _logError(exception);
        return null;
      }
    });
  }

  Future<int?> deleteWhere<V>(String table, String column, V id) async {
    return await _transactOrFail((transaction) async {
      try {
        return await transaction.delete(table, where: "$column = ?", whereArgs: [id]);
      } catch (exception) {
        _logError(exception);
        return null;
      }
    });
  }

  Future<int?> deleteTableData(String table) async {
    return await _transactOrFail((transaction) async {
      try {
        return await transaction.delete(table);
      } catch (exception) {
        _logError(exception);
        return null;
      }
    });
  }

  Future<T> transact<T>(Future<T> Function(sqflite.Transaction transaction) function) async {
    return await _transactOrFail((transaction) async => await function(transaction));
  }

  Future<bool> get deleteAll async {
    return await _transactOrFail((transaction) async {
      try {
        for (BaseDatabaseModel model in _models) {
          await transaction.delete(model.tableName);
        }
        return true;
      } catch (exception) {
        _logError(exception);
        return false;
      }
    });
  }
}

class StarterStorage {
  StarterStorage._();

  static Future<Directory> storagePath({String? suffix, String? file}) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String basePath = "/storage/emulated/0/Documents/flutter_pack/${packageInfo.packageName}";
    Directory directory = Directory(basePath);
    if (!await directory.exists()) await directory.create(recursive: true);
    if (suffix == null && file == null) return directory;
    Directory pathedDirectory = Directory("${directory.path}/$suffix");
    if (!await pathedDirectory.exists()) await pathedDirectory.create(recursive: true);
    if (file == null) return pathedDirectory;
    return Directory("${pathedDirectory.path}/$file");
  }
}
