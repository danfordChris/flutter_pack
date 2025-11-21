// base_repository.dart

import 'package:flutter_pack/flutter_pack.dart';

abstract class BaseDataRepository<T extends BaseDatabaseModel> {
  final T _model;
  final T Function(Map<String, dynamic> map) _generator;
  final BaseDatabaseManager _databaseManager;

  BaseDataRepository(this._databaseManager, this._model, this._generator);

  Future<List<T>> get all async {
    return await _databaseManager.all(_model.tableName, (map) => _generator(map));
  }

  Future<List<Map<String, dynamic>>> rawQuery(String query, [List<Object?>? args]) async {
    return await _databaseManager.rawQuery(query, args);
  }

  Future<List<T>> findAllWhere(String where, List<Object?> values) async {
    return await _databaseManager.findAllBy(_model.tableName, where, values, (map) => _generator(map));
  }

  Future<T?> findWhere(String where, List<Object?> values) async {
    return await _databaseManager.findBy(_model.tableName, where, values, (map) => _generator(map));
  }

  Future<T?> findById(Object? id) async {
    return findWhere("id = ?", [id]);
  }

  Future<T?> save(T model) async {
    return await _databaseManager.save(model);
  }

  Future<bool> saveBatch(List<T> models) async {
    return await _databaseManager.saveBatch(models);
  }

  Future<bool> replaceBatch(List<T> models) async {
    return await _databaseManager.replaceBatch(models);
  }

  Future<bool> insertOrUpdateBy(List<T> models, String key) async {
    return await _databaseManager.insertOrUpdateBy(models, key);
  }

  Future<T?> update(T model) async {
    return await _databaseManager.update(
      model,
      "id = ?",
      [model.toMap["id"]],
    );
  }

  Future<T?> updateWhere(T model, String where, List<Object?> args) async {
    return await _databaseManager.update(model, where, args);
  }

  Future<T?> delete(T model) async {
    return await _databaseManager.delete(model);
  }

  Future<int?> deleteWhereId<V>(V id) async {
    return await _databaseManager.deleteWhere<V>(_model.tableName, "id", id);
  }
}
