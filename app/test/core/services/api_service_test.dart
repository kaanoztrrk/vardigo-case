import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vardigo_app/core/errors/failures.dart';
import 'package:vardigo_app/core/services/api_service.dart';

const _base = 'http://api.test';

/// Sunucu açmadan: MockClient her isteği yakalayıp verilen cevabı döner.
/// Gönderilen isteği de [sent]'e yazar, header/gövde kontrol edilebilsin.
ApiService _service(
  int status,
  Object? body, {
  List<http.Request>? sent,
}) {
  final client = MockClient((request) async {
    sent?.add(request);
    return http.Response.bytes(
      utf8.encode(body is String ? body : jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  return ApiService(client: client, baseUrl: _base);
}

Map<String, Object?> _error(String code, String message, [List<String>? ids]) => {
  'ok': false,
  'error': {'code': code, 'message': message, 'ids': ?ids},
};

void main() {
  group('başarılı cevap', () {
    test('zarfı açar, yalnızca data döner', () async {
      final api = _service(200, {
        'ok': true,
        'data': {'token': 'dev-worker', 'role': 'worker'},
      });

      final data = await api.post('/api/auth/login', body: {'role': 'worker'});

      expect(data, {'token': 'dev-worker', 'role': 'worker'});
    });

    test('token ve JSON header\'ı eklenir, sorgu parametreleri URL\'e girer', () async {
      final sent = <http.Request>[];
      final api = _service(200, {'ok': true, 'data': null}, sent: sent)
        ..token = 'dev-employer';

      await api.get('/api/candidates', query: {'tab': 'perfect', 'sort': 'near'});
      await api.post('/api/offers', body: {'workerIds': ['w_merve']});

      expect(
        sent[0].url.toString(),
        '$_base/api/candidates?tab=perfect&sort=near',
      );
      expect(sent[0].headers['Authorization'], 'Bearer dev-employer');
      expect(sent[0].headers.containsKey('Content-Type'), isFalse);
      expect(sent[1].headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(sent[1].body), {'workerIds': ['w_merve']});
    });

    test('token yoksa Authorization gönderilmez', () async {
      final sent = <http.Request>[];
      final api = _service(200, {'ok': true, 'data': null}, sent: sent);

      await api.get('/api/health');

      expect(sent.single.headers.containsKey('Authorization'), isFalse);
    });

    test('Türkçe karakterler bozulmadan çözülür', () async {
      final api = _service(200, {'ok': true, 'data': 'Ayşe K. · Kadıköy'});

      expect(await api.get('/x'), 'Ayşe K. · Kadıköy');
    });
  });

  group('sunucu hatası → Failure', () {
    final cases = <(int, String, Matcher)>[
      (400, 'EMPTY_SELECTION', isA<ValidationFailure>()),
      (401, 'FORBIDDEN_ROLE', isA<AuthFailure>()),
      (404, 'OFFER_NOT_FOUND', isA<NotFoundFailure>()),
      (409, 'OFFER_EXPIRED', isA<ConflictFailure>()),
      (500, 'INTERNAL', isA<ServerFailure>()),
    ];
    for (final (status, code, type) in cases) {
      test('$status → ${type.describe(StringDescription())}', () async {
        final api = _service(status, _error(code, 'Sunucu mesajı'));

        await expectLater(
          api.get('/x'),
          throwsA(
            allOf(
              type,
              isA<Failure>()
                  .having((f) => f.code, 'code', code)
                  .having((f) => f.message, 'message', 'Sunucu mesajı'),
            ),
          ),
        );
      });
    }

    test('409 ids alanı taşınır', () async {
      final api = _service(
        409,
        _error('OFFER_EXISTS', 'Bekleyen talep var', ['w_merve']),
      );

      await expectLater(
        api.post('/api/offers', body: {'workerIds': ['w_merve']}),
        throwsA(isA<ConflictFailure>().having((f) => f.ids, 'ids', ['w_merve'])),
      );
    });
  });

  group('cevap alınamadı', () {
    test('bağlantı hatası → NetworkFailure', () async {
      final api = ApiService(
        client: MockClient((_) => throw http.ClientException('bağlanamadı')),
        baseUrl: _base,
      );

      await expectLater(api.get('/x'), throwsA(isA<NetworkFailure>()));
    });

    test('zaman aşımı → NetworkFailure', () async {
      final api = ApiService(
        client: MockClient((_) => Future.delayed(
          const Duration(seconds: 1),
          () => http.Response('{}', 200),
        )),
        baseUrl: _base,
        timeout: const Duration(milliseconds: 10),
      );

      await expectLater(api.get('/x'), throwsA(isA<NetworkFailure>()));
    });

    test('JSON olmayan cevap → ServerFailure', () async {
      final api = _service(502, '<html>Bad Gateway</html>');

      await expectLater(api.get('/x'), throwsA(isA<ServerFailure>()));
    });
  });

  test('assetUrl göreli görsel yolunu tam adrese çevirir', () {
    final api = _service(200, null);

    expect(
      api.assetUrl('/assets/photos/merve.png'),
      '$_base/assets/photos/merve.png',
    );
  });
}
