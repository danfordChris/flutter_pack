import 'dart:convert';

import 'package:flutter_pack/flutter_pack.dart';
import 'package:http/http.dart';

class APIResponseUtility<T> {
  APIResponseUtility._(this._response, this._error, this._hasDataKey);
  final Response? _response;
  final String? _error;
  final bool _hasDataKey;
  final List<String> _expectedBodyErrors = [];
  List<String> get expectedBodyErrors => _expectedBodyErrors;

  factory APIResponseUtility.of(Response response) {
    dynamic data = jsonDecode(response.body);
    bool hasDataKey = data is Map<String, dynamic> && data.containsKey("data");
    List<int> successStatuses = List.generate(100, (index) => 200 + index);
    if (!successStatuses.contains(response.statusCode)) {
      AppUtility.log("[${response.statusCode}] ${response.request?.url.path ?? "-"} => ${response.body}");
      bool hasMessage = data is Map<String, dynamic> && data.containsKey("message");
      String message = hasMessage ? data["message"] : null;
      return APIResponseUtility._(response, message, hasDataKey);
    }
    return APIResponseUtility._(response, null, hasDataKey);
  }

  void expect(Map<String, Type> expectation) {
    if (_response == null) throw Exception("Response is NULL");
    if (!isSuccessful) throw Exception("Response was not successful");
    dynamic responseBody = jsonDecode(_response.body);
    if (responseBody == null) throw Exception("Response body is null");
    _expectedBodyErrors.clear();
    if (responseBody is Map<String, dynamic>) {
      _parseExpectation(responseBody, expectation);
    }
    if (responseBody is List<dynamic>) {
      for (Map<String, dynamic> map in responseBody) {
        _parseExpectation(map, expectation);
      }
    }
    if (_expectedBodyErrors.isNotEmpty) throw Exception(_expectedBodyErrors);
  }

  void _parseExpectation(Map<String, dynamic> responseBody, Map<String, Type> expectation) {
    for (MapEntry<String, Type> entry in expectation.entries) {
      dynamic target = responseBody[entry.key];
      if (target == null) {
        String reason = "${entry.key} is missing";
        if (_expectedBodyErrors.contains(reason)) continue;
        _expectedBodyErrors.add(reason);
        continue;
      }
      if (target.runtimeType != entry.value) {
        String reason = "${entry.key} does not match its type, expected ${entry.value}, found ${target.runtimeType}";
        if (_expectedBodyErrors.contains(reason)) continue;
        _expectedBodyErrors.add(reason);
        continue;
      }
    }
  }

  void showError(String? Function(int statusCode) function) {
    if (_response == null) throw Exception("Response is NULL");
    String? serverMessage = this.message;
    if (serverMessage != null) throw Exception(serverMessage);
    String? message = function(_response.statusCode);
    if (message == null) throw Exception("No message has been found");
    throw Exception(message);
  }

  void raiseOnError() {
    if (isSuccessful) return;
    showError((status) => message);
  }

  void log() {
    if (_response == null) return;
    AppUtility.log("${_response.statusCode} => ${_response.body}");
  }

  int get statusCode {
    if (_response == null) throw Exception("Response is NULL");
    return _response.statusCode;
  }

  Map<String, String> get headers {
    if (_response == null) throw Exception("Response is NULL");
    return _response.headers;
  }

  bool get isSuccessful {
    if (_response == null || (_error != null && _error.isNotEmpty)) return false;
    List<int> statuses = List.generate(99, (index) => 200 + index);
    return statuses.contains(_response.statusCode);
  }

  String? get message {
    if (_error != null) return _error;
    Map<String, dynamic>? response = responseBody as Map<String, dynamic>;
    if (!response.containsKey("message")) throw Exception("No message found in response");
    return response["message"];
  }

  Map<String, dynamic> get mapData {
    if (_response == null) throw Exception("Response is NULL");
    return responseBody["data"];
  }

  dynamic get responseBody {
    if (_response == null) throw Exception("Response is NULL");
    return jsonDecode(_response.body);
  }

  T transform(T Function(Map<String, dynamic> map) generator) {
    try {
      if (_response == null) throw Exception("Response is NULL");
      Map<String, dynamic>? responseData = jsonDecode(_response.body);
      if (responseData == null) throw Exception("Response data is NULL");
      if (!_hasDataKey) return generator(responseData);
      return generator(responseData["data"]);
    } catch (exception) {
      AppUtility.log("[-] ${_response?.request?.url.path ?? "-"} => ${_response?.body} => ${exception}");
      throw exception;
    }
  }

  List<T> transformMany(T Function(Map<String, dynamic> map) generator) {
    try {
      if (_response == null) throw Exception("Response is NULL");
      dynamic responseData = jsonDecode(_response.body);
      if (responseData == null) throw Exception("Response data is NULL");
      if (!_hasDataKey) {
        List<dynamic>? listData = responseData as List<dynamic>?;
        if (listData == null) throw Exception("Unkeyed list data is NULL");
        return List.generate(listData.length, (index) => generator(listData[index]));
      }
      List<dynamic>? listData = responseData["data"];
      if (listData == null) throw Exception("Keyed list data is NULL");
      return List.generate(listData.length, (index) => generator(listData[index]));
    } catch (exception) {
      AppUtility.log("[-] ${_response?.request?.url.path ?? "-"} => ${_response?.body} => ${exception}");
      throw exception;
    }
  }
}
