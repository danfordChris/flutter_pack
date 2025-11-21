import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_pack/flutter_pack.dart';
import 'package:flutter_pack/src/api_manager/api_response.dart';
import 'package:flutter_pack/src/app_utility/starter_scroll_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

enum _ResponseType {
  _get,
  _post,
  _put,
  _patch,
  _delete;

  String get label {
    switch (this) {
      case _get:
        return "GET";
      case _post:
        return "POST";
      case _put:
        return "PUT";
      case _patch:
        return "PATCH";
      case _delete:
        return "DELETE";
    }
  }
}

mixin PaginationMixin {
  StarterPagination<T>? pagination<T>(Map<String, dynamic> map);
}

class StarterAPIManagement {
  final Future<Map<String, String>?> Function()? authorization;
  final Future<bool> Function()? refreshOnUnauthorized;
  final List<String>? allowedSHAFingerprints;
  final PaginationMixin? paginationMixin;

  StarterAPIManagement({
    this.authorization,
    this.refreshOnUnauthorized,
    this.allowedSHAFingerprints,
    this.paginationMixin,
  });
}

abstract class BaseAPIManager {
  /// [refreshOnUnauthorized] will be invoked whenever a response with status code 401 0r 403
  /// is received. The callback should return `true` if the manager should retry
  /// the failed request (for example after refreshing an access token).
  BaseAPIManager(this._baseURL, [this._starterAPIManagement]) {
    _client = _createClient();
  }
  final String _baseURL;
  StarterAPIManagement? _starterAPIManagement;

  late final http.Client _client;

  http.Client _createClient() {
    if (_starterAPIManagement?.allowedSHAFingerprints == null) return http.Client();
    return SecureHttpClient.build(_starterAPIManagement!.allowedSHAFingerprints!);
  }

  Uri _uri(String endpoint) {
    return Uri.parse("${_baseURL}${endpoint}");
  }

  Future<http.Response> get(String url, {Map<String, String>? headers, Map<String, dynamic>? params}) async {
    return await _response(_ResponseType._get, url, headers: headers, params: params);
  }

  Future<http.Response> authGet(String url, {Map<String, String>? headers, Map<String, dynamic>? params}) async {
    return await _response(_ResponseType._get, url, headers: headers, params: params);
  }

  Future<http.Response> post(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _response(_ResponseType._post, url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> authPost(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _response(_ResponseType._post, url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> patch(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _response(_ResponseType._patch, url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> authPatch(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _response(_ResponseType._patch, url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> put(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _response(_ResponseType._put, url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> authPut(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _response(_ResponseType._put, url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> delete(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _response(_ResponseType._delete, url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> authDelete(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _response(_ResponseType._delete, url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> _response(
    _ResponseType type,
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    Object? body,
    Encoding? encoding,
  }) async {
    AppUtility.log("[*] ${type.label} => $_baseURL${_formattedParams(url, params)}");
    Map<String, String>? authHeaders = await _endpointHeaders(headers);
    switch (type) {
      case _ResponseType._get:
        return await _client.get(_uri(_formattedParams(url, params)), headers: authHeaders);
      case _ResponseType._post:
        return await _client.post(_uri(url), headers: authHeaders, body: body, encoding: encoding);
      case _ResponseType._put:
        return await _client.put(_uri(url), headers: authHeaders, body: body, encoding: encoding);
      case _ResponseType._patch:
        return await _client.patch(_uri(url), headers: authHeaders, body: body, encoding: encoding);
      case _ResponseType._delete:
        return await _client.delete(_uri(url), headers: authHeaders, body: body, encoding: encoding);
    }
  }

  Future<APIResponse<T>> apiGet<T>(String url, {Map<String, String>? headers, Map<String, dynamic>? params}) async {
    return await _apiResponse(_ResponseType._get, url, headers: headers, params: params);
  }

  Future<APIResponse<T>> apiAuthGet<T>(String url, {Map<String, String>? headers, Map<String, dynamic>? params}) async {
    return await _apiResponse(_ResponseType._get, url, headers: headers, params: params);
  }

  Future<APIResponse<T>> apiPost<T>(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _apiResponse(_ResponseType._post, url, headers: headers, body: body, encoding: encoding);
  }

  Future<APIResponse<T>> apiAuthPost<T>(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _apiResponse(_ResponseType._post, url, headers: headers, body: body, encoding: encoding);
  }

  Future<APIResponse<T>> apiPatch<T>(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _apiResponse(_ResponseType._patch, url, headers: headers, body: body, encoding: encoding);
  }

  Future<APIResponse<T>> apiAuthPatch<T>(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _apiResponse(_ResponseType._patch, url, headers: headers, body: body, encoding: encoding);
  }

  Future<APIResponse<T>> apiPut<T>(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _apiResponse(_ResponseType._put, url, headers: headers, body: body, encoding: encoding);
  }

  Future<APIResponse<T>> apiAuthPut<T>(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _apiResponse(_ResponseType._put, url, headers: headers, body: body, encoding: encoding);
  }

  Future<APIResponse<T>> apiDelete<T>(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _apiResponse(_ResponseType._delete, url, headers: headers, body: body, encoding: encoding);
  }

  Future<APIResponse<T>> apiAuthDelete<T>(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _apiResponse(_ResponseType._delete, url, headers: headers, body: body, encoding: encoding);
  }

  Future<APIResponse<T>> _apiResponse<T>(
    _ResponseType type,
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      http.Response response = await _response(
        type,
        url,
        headers: headers,
        params: params,
        body: body,
        encoding: encoding,
      ).timeout(Duration(minutes: 1));
      // If the server returns 401, trigger the optional unauthorized handler.
      if (response.statusCode == 401 || response.statusCode == 403 /*&& _starterAPIManagement?.refreshOnUnauthorized != null*/) {
        try {
          bool? shouldRetry = await _starterAPIManagement?.refreshOnUnauthorized?.call();
          if (shouldRetry == true) {
            // Retry the request once after the handler (e.g., token refresh).
            response = await _response(
              type,
              url,
              headers: headers,
              params: params,
              body: body,
              encoding: encoding,
            ).timeout(Duration(minutes: 1));
          }
        } catch (e) {
          AppUtility.log('[refreshOnUnauthorized] handler threw an exception: $e');
        }
      }
      return APIResponse.of(response, _starterAPIManagement?.paginationMixin);
    } on SocketException catch (exception) {
      AppUtility.log("[Socket] $url => $exception");
      throw Exception("No Internet Connection Found");
    } on TimeoutException catch (exception) {
      AppUtility.log("[Timeout] $url => $exception");
      throw Exception("A request took too long to complete. Please check your internet connection");
    } on FormatException catch (exception) {
      AppUtility.log("[Format] $url => $exception");
      throw Exception("The server returned an unexpected format");
    } catch (exception) {
      AppUtility.log("[Exception] $url => $exception");
      throw Exception("An error occurred, please contact the developer for assistance");
    }
  }

  Future<Map<String, String>?> _endpointHeaders(Map<String, String>? other) async {
    Map<String, String> defaultHeaders = {
      "Content-Type": "application/json",
    };
    if (other != null) defaultHeaders.addAll(other);
    if (_starterAPIManagement?.authorization == null) return defaultHeaders;
    Map<String, String>? authHeaders = await _starterAPIManagement?.authorization?.call();
    if (authHeaders == null) return defaultHeaders;
    defaultHeaders.addAll(authHeaders);
    return defaultHeaders;
  }

  String _formattedParams(String url, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return url;
    String questionedParam = url + "?";
    List<String> addedParams = [];
    for (MapEntry<String, dynamic> entry in params.entries) {
      addedParams.add("${entry.key}=${entry.value}");
    }
    return "${questionedParam}${addedParams.join("&")}";
  }

  // static Future<Map<String, String>> instanceAuthorizationHeader() async {
  //   final headers = await _authorization();
  //   return {
  //     'Content-Type': 'multipart/form-data',
  //     if (headers != null) ...headers,
  //   };
  // }
}
