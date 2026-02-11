import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_pack/flutter_pack.dart';
import 'package:flutter_pack/src/api_manager/api_response.dart';
import 'package:flutter_pack/src/app_utility/starter_scroll_controller.dart';
import 'package:flutter_pack/src/security/signature_config.dart';
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
  final Future<Map<String, String>?>? authorization;
  final Future<bool>? refreshOnUnauthorized;
  final List<String>? allowedSHAFingerprints;
  final String? privateKeyPEM;
  final String? publicKeyPEM;

  /// Map of status codes to their respective handler functions
  /// Example: {403: () async => print('Forbidden'), 429: () async => handleRateLimit()}
  final Map<int, Future<void> Function()>? statusCodeActions;

  late final DigitalSignature digitalSignature;

  StarterAPIManagement({
    this.authorization,
    this.refreshOnUnauthorized,
    this.allowedSHAFingerprints,
    this.privateKeyPEM,
    this.publicKeyPEM,
    this.statusCodeActions,
  }) {
    digitalSignature = DigitalSignature(
      privateKeyPEM: privateKeyPEM,
      publicKeyPEM: publicKeyPEM,
    );
  }
}

abstract class BaseAPIManager {
  bool get isUsingDigitalSignature {
    return _starterAPIManagement?.privateKeyPEM != null && _starterAPIManagement?.publicKeyPEM != null;
  }

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
    return Uri.parse("$_baseURL$endpoint");
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
    Object? requestBody;
    if (isUsingDigitalSignature) {
      // Encode the signed body as JSON string
      if (body == null) {
        body = <String, dynamic>{};
      }
      requestBody = json.encode(await _signedBody(body));
    } else {
      if (body is Map<String, dynamic>) {
        requestBody = json.encode(body);
      } else {
        requestBody = body;
      }
    }
    switch (type) {
      case _ResponseType._get:
        return await _client.get(_uri(_formattedParams(url, params)), headers: authHeaders);
      case _ResponseType._post:
        return await _client.post(_uri(url), headers: authHeaders, body: requestBody, encoding: encoding);
      case _ResponseType._put:
        return await _client.put(_uri(url), headers: authHeaders, body: requestBody, encoding: encoding);
      case _ResponseType._patch:
        return await _client.patch(_uri(url), headers: authHeaders, body: requestBody, encoding: encoding);
      case _ResponseType._delete:
        return await _client.delete(_uri(url), headers: authHeaders, body: requestBody, encoding: encoding);
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

  /// Execute status code action if defined for the given status code
  Future<void> _executeStatusCodeAction(int statusCode) async {
    final action = _starterAPIManagement?.statusCodeActions?[statusCode];
    if (action != null) {
      try {
        AppUtility.log('[StatusCodeAction] Executing action for status code: $statusCode');
        await action();
      } catch (e) {
        AppUtility.log('[StatusCodeAction] Error executing action for status code $statusCode: $e');
      }
    }
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
      ).timeout(const Duration(minutes: 1));

      // Execute status code action if defined
      await _executeStatusCodeAction(response.statusCode);

      // If the server returns 401, trigger the optional unauthorized handler.
      if (response.statusCode == 401 && _starterAPIManagement?.refreshOnUnauthorized != null) {
        try {
          bool? shouldRetry = await _starterAPIManagement?.refreshOnUnauthorized;
          if (shouldRetry == true) {
            // Retry the request once after the handler (e.g., token refresh).
            response = await _response(
              type,
              url,
              headers: headers,
              params: params,
              body: body,
              encoding: encoding,
            ).timeout(const Duration(minutes: 1));

            // Execute status code action again for the retry response
            await _executeStatusCodeAction(response.statusCode);
          }
        } catch (e) {
          AppUtility.log('[refreshOnUnauthorized] handler threw an exception: $e');
        }
      }

      // Validate JSON content type before decoding
      final contentType = response.headers['content-type'];
      if (contentType == null || !contentType.toLowerCase().contains('application/json')) {
        AppUtility.log("[Format] $url => Unexpected content-type: $contentType");
        throw Exception("The server did not return a JSON response (content-type: $contentType)");
      }
      Map<String, dynamic> responseBody = json.decode(response.body);
      // If backend explicitly returns an error message, surface it immediately
      if (responseBody.containsKey('error') && responseBody['error'] != null) {
        final error = responseBody['error'];
        String errorMessage = _errorHandling(error);

        AppUtility.log("[API Error] $url => $errorMessage");
        throw Exception(errorMessage);
      }

      /*
      No need to check for signature if response is an error, as the error message from the server should be trusted and surfaced regardless of signature validity.
       This also prevents potential infinite loops of invalid signature errors when the server returns an error response that isn't signed or has an invalid signature.
      */
      // if (isUsingDigitalSignature) {
      //   if (!responseBody.containsKey('signature')) {
      //     throw Exception("Invalid signature response format: missing 'signature' field");
      //   }
      //   if (!responseBody.containsKey('data')) {
      //     throw Exception("Invalid signature response format: missing 'data' field");
      //   }
      //   bool isSignatureValid = _starterAPIManagement!.digitalSignature.verify(canonicalStringify(responseBody["data"]), responseBody['signature']);
      //   if (!isSignatureValid) {
      //     AppUtility.log("[Signature] $url => Invalid Signature");
      //     throw Exception("Invalid server response signature. The response may have been tampered");
      //   }
      // }

      return APIResponse.of(response);
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
      // throw Exception("An error occurred, please contact the developer for assistance");
      rethrow;
    }
  }

  Future<Map<String, String>?> _endpointHeaders(Map<String, String>? other) async {
    Map<String, String> defaultHeaders = {
      "Content-Type": "application/json",
    };
    if (other != null) defaultHeaders.addAll(other);
    if (_starterAPIManagement?.authorization == null) return defaultHeaders;
    Map<String, String>? authHeaders = await _starterAPIManagement?.authorization;
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

  Future<Map<String, dynamic>> _signedBody(Object? body) async {
    // Ensure body is a Map
    if (body is! Map<String, dynamic>) {
      if (body is String) {
        body = json.decode(body) as Map<String, dynamic>;
      } else {
        AppUtility.log("Invalid body type for signing: ${body}");
        throw ArgumentError('Body must be a Map or JSON string');
      }
    }

    // Use canonical stringify instead of json.encode
    final canonical = canonicalStringify(body);

    // Generate signature
    final signature = _starterAPIManagement!.digitalSignature.sign(canonical);

    return {"data": body, "signature": signature};
  }

  String canonicalStringify(dynamic obj) {
    if (obj == null) return "null";

    if (obj is bool || obj is int) return obj.toString();

    if (obj is double) {
      // Match jsonEncode behavior exactly
      if (obj % 1 == 0) {
        return obj.toInt().toString(); // 10.0 => "10"
      }
      return obj.toString(); // 12.1 => "12.1"
    }

    if (obj is String) return '"${_escapeString(obj)}"';

    if (obj is DateTime) return '"${obj.toUtc().toIso8601String()}"';

    if (obj is List) {
      final items = obj.map((e) => canonicalStringify(e)).join(',');
      return '[$items]';
    }

    if (obj is Map) {
      final sortedKeys = obj.keys.map((e) => e.toString()).toList()..sort();

      final entries = sortedKeys.map((key) {
        final value = canonicalStringify(obj[key]);
        return '"$key":$value';
      }).join(',');

      return '{$entries}';
    }

    throw ArgumentError("Unsupported type: ${obj.runtimeType}");
  }

  /// Safe JSON string escape
  String _escapeString(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n').replaceAll('\r', r'\r').replaceAll('\t', r'\t');
  }

  String _errorHandling(dynamic error) {
    if (error == null) return '';

    if (error is String) {
      return error;
    }

    if (error is Map) {
      final messages = <String>[];
      error.forEach((_, value) {
        if (value is List) {
          for (final item in value) {
            messages.add(item.toString());
          }
        } else {
          messages.add(value.toString());
        }
      });
      return messages.join('\n');
    }

    return error.toString();
  }
}
