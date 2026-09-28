import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/error_mapper.dart';
import '../errors/failures.dart';

/// All HTTP calls go through here, so repositories don't have to:
///  - add the session token as `Authorization: Bearer`,
///  - unwrap the `{ ok, data }` envelope and return `data`,
///  - turn every error into a [Failure], so blocs only need
///    `on Failure catch` and never see raw http/FormatException errors.
class ApiService {
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  /// Set by AuthRepository on login, null on logout.
  String? _token;

  ApiService({
    required http.Client client,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client,
       _baseUrl = baseUrl,
       _timeout = timeout;

  set token(String? value) => _token = value;

  /// Turns a relative image path from the API (`/assets/photos/merve.png`)
  /// into a full URL for Image.network.
  String assetUrl(String path) => '$_baseUrl$path';

  Future<Object?> get(
    String path, {
    Map<String, String>? query,
    String tag = 'Api',
  }) {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    return _send(() => _client.get(uri, headers: _headers()), tag: tag);
  }

  Future<Object?> post(String path, {Object? body, String tag = 'Api'}) {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(
      () => _client.post(
        uri,
        headers: _headers(json: body != null),
        body: body == null ? null : jsonEncode(body),
      ),
      tag: tag,
    );
  }

  Map<String, String> _headers({bool json = false}) => {
    if (_token != null) 'Authorization': 'Bearer $_token',
    if (json) 'Content-Type': 'application/json',
  };

  Future<Object?> _send(
    Future<http.Response> Function() request, {
    required String tag,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } catch (e, st) {
      // No response at all: server down, no connection, or timeout.
      throw ErrorMapper.fromException(
        e,
        st,
        tag: tag,
        fallback: const NetworkFailure(),
      );
    }

    final Object? decoded;
    try {
      // Decode bodyBytes as UTF-8 ourselves instead of relying on charset
      // detection, otherwise Turkish characters (ı, ş, ğ) can break.
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e, st) {
      throw ErrorMapper.fromException(
        e,
        st,
        tag: tag,
        fallback: const ServerFailure('Sunucudan anlaşılamayan bir cevap geldi.'),
      );
    }

    if (decoded is Map<String, dynamic> && decoded['ok'] == true) {
      return decoded['data'];
    }
    throw ErrorMapper.fromResponse(
      response.statusCode,
      decoded is Map<String, dynamic> ? decoded['error'] : null,
      tag: tag,
    );
  }
}
