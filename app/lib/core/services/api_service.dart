import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/error_mapper.dart';
import '../errors/failures.dart';

/// Sunucuyla konuşmanın tek kapısı.
///
/// Üç işi var, repository'ler bunların hiçbirini bilmiyor:
///  - Oturum token'ını her isteğe `Authorization: Bearer` olarak ekler.
///  - Sunucunun `{ ok, data }` zarfını açar, yalnızca `data`'yı döner.
///  - Her hatayı [Failure]'a çevirir — bloc'lar `on Failure catch`
///    konvansiyonuyla çalışabilsin, ham `http`/`FormatException` sızmasın.
class ApiService {
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  /// Giriş yapılınca AuthRepository tarafından set edilir; çıkışta null.
  String? _token;

  ApiService({
    required http.Client client,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client,
       _baseUrl = baseUrl,
       _timeout = timeout;

  set token(String? value) => _token = value;

  /// Sunucunun döndüğü göreli görsel yolunu (`/assets/photos/merve.png`)
  /// tam adrese çevirir — Image.network için.
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
      // Sunucu kapalı, bağlantı yok ya da zaman aşımı: sunucudan hiçbir
      // cevap gelmedi.
      throw ErrorMapper.fromException(
        e,
        st,
        tag: tag,
        fallback: const NetworkFailure(),
      );
    }

    final Object? decoded;
    try {
      // body değil bodyBytes: Türkçe karakterler (ı, ş, ğ) charset
      // tahminine bırakılmadan UTF-8 çözülsün.
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
