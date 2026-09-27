import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vardigo_app/core/services/api_service.dart';
import 'package:vardigo_app/features/offers/bloc/offers/offers_bloc.dart';
import 'package:vardigo_app/features/offers/bloc/offers/offers_event.dart';
import 'package:vardigo_app/features/offers/bloc/offers/offers_state.dart';
import 'package:vardigo_app/features/offers/data/enum/offer_sort.dart';
import 'package:vardigo_app/features/offers/data/enum/offer_status.dart';
import 'package:vardigo_app/features/offers/data/enum/offer_tab.dart';
import 'package:vardigo_app/features/offers/data/models/offer_model.dart';
import 'package:vardigo_app/features/offers/data/repository/offer_repository.dart';

const _base = 'http://api.test';

final _now = DateTime.utc(2026, 9, 27, 12);

/// Sunucunun sırasıyla (en yeni üstte) bekleyen üç talep. Barista en
/// yeni, süresi en yakın dolan Komi, ücreti en yüksek Garson.
Map<String, Object?> _offer(String id, int pay, Duration left) => {
  'id': id,
  'title': id,
  'place': 'Zarif Cheff Restaurant',
  'pay': '$pay',
  'payValue': pay,
  'logo': '/assets/logos/zarif.svg',
  'district': 'Kadıköy',
  'when': '16 Ağu · 12:00 - 16:00',
  'status': 'pending',
  'remain': '${left.inHours} saat 0 dakika',
  'expiresAt': _now.add(left).toIso8601String(),
};

final _pending = [
  _offer('o_barista', 38000, const Duration(hours: 21)),
  _offer('o_garson', 45000, const Duration(hours: 10)),
  _offer('o_komi', 32000, const Duration(hours: 5)),
];

/// Sahte sunucu. [answerErrors] talep id'si → accept/reject'in döneceği
/// hata (status, code, message); yoksa başarı. [detailFails] true ise
/// GET /offers/:id 500 döner. Gelen istekler [sent]'e yazılır.
class _Server {
  final sent = <String>[];
  final answerErrors = <String, (int, String, String)>{};
  bool detailFails = false;

  http.Client get client => MockClient((request) async {
    final path = request.url.path;
    sent.add(
      '${request.method} ${request.url.path}${request.url.query.isEmpty ? '' : '?${request.url.query}'}',
    );

    if (request.method == 'POST') {
      final id = path.split('/')[3];
      final err = answerErrors[id];
      if (err != null) return _error(err.$1, err.$2, err.$3);
      return _json(200, {'ok': true, 'data': {}});
    }
    if (path == '/api/offers') {
      final status = request.url.queryParameters['status'];
      return _json(200, {
        'ok': true,
        'data': {
          'pendingCount': 12,
          'offers': status == 'pending' ? _pending : [],
        },
      });
    }
    // GET /api/offers/:id
    if (detailFails) return _error(500, 'INTERNAL', 'Sunucu hatası');
    return _json(200, {
      'ok': true,
      'data': {'city': 'İstanbul', 'note': 'Şube: Sinanpaşa Mah.'},
    });
  });

  static http.Response _error(int status, String code, String message) =>
      _json(status, {
        'ok': false,
        'error': {'code': code, 'message': message},
      });

  // Response(String) gövdeyi latin1 kodluyor, "Kadıköy" sığmıyor.
  static http.Response _json(int status, Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  late _Server server;
  late OffersBloc bloc;

  setUp(() {
    server = _Server();
    bloc = OffersBloc(
      OfferRepository(ApiService(client: server.client, baseUrl: _base)),
    );
  });

  tearDown(() => bloc.close());

  /// Olayı atar ve yükleme bitene kadar bekler (bkz. candidates testi).
  Future<OffersState> load(OffersEvent event) {
    final done = bloc.stream
        .skipWhile((s) => !s.loading)
        .firstWhere((s) => !s.loading);
    bloc.add(event);
    return done;
  }

  /// Olayı atar ve kuyruktaki işler bitene kadar bekler.
  Future<OffersState> act(OffersEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return bloc.state;
  }

  List<String> ids(List<OfferModel> offers) => offers.map((o) => o.id).toList();

  test('ilk yükleme: bekleyenler, sunucu sırası, alt başlık', () async {
    final state = await load(OffersRequested());

    expect(server.sent.single, 'GET /api/offers?status=pending');
    expect(ids(state.visibleOffers), ['o_barista', 'o_garson', 'o_komi']);
    expect(state.subtitle, '12 talep yanıt bekliyor');
  });

  test('sıralama istemcide: Önerilen → Süre → Ücret → Önerilen', () async {
    await load(OffersRequested());

    final orders = <OfferSort, List<String>>{};
    for (var i = 0; i < 3; i++) {
      final state = await act(OffersSortCycled());
      orders[state.sort] = ids(state.visibleOffers);
    }

    expect(orders[OfferSort.time], ['o_komi', 'o_garson', 'o_barista']);
    expect(orders[OfferSort.pay], ['o_garson', 'o_barista', 'o_komi']);
    expect(orders[OfferSort.recommended], ['o_barista', 'o_garson', 'o_komi']);
    // Yalnızca ilk yükleme: sıralama sunucuya gitmiyor.
    expect(server.sent, hasLength(1));
  });

  test('sekme değişince o sekme yüklenir, boş state alt başlığı', () async {
    await load(OffersRequested());

    final state = await load(OffersTabChanged(OfferTab.answered));

    expect(server.sent.last, 'GET /api/offers?status=answered');
    expect(state.offers, isEmpty);
    expect(state.subtitle, 'Cevaplanan talepler');
  });

  group('yanıtlama (iyimser)', () {
    test('İlgileniyorum: kart hemen düşer, accept gider', () async {
      await load(OffersRequested());

      bloc.add(OfferAnswerRequested('o_garson', accept: true));
      await Future<void>.delayed(Duration.zero);
      // İstek henüz bitmeden kart listede yok.
      expect(ids(bloc.state.offers), ['o_barista', 'o_komi']);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      final state = bloc.state;
      expect(server.sent.last, 'POST /api/offers/o_garson/accept');
      expect(ids(state.offers), ['o_barista', 'o_komi']);
      expect(state.actionError, isNull);
    });

    test('ağ/sunucu hatası: kart aynı yerine geri konur + toast', () async {
      await load(OffersRequested());
      server.answerErrors['o_garson'] = (500, 'INTERNAL', 'Sunucu hatası');

      final state = await act(OfferAnswerRequested('o_garson', accept: false));

      expect(server.sent.last, 'POST /api/offers/o_garson/reject');
      expect(ids(state.offers), ['o_barista', 'o_garson', 'o_komi']);
      expect(state.actionError, 'Sunucu hatası');
    });

    test('409 süresi doldu: kart geri KONMAZ, sebep gösterilir', () async {
      await load(OffersRequested());
      server.answerErrors['o_komi'] = (
        409,
        'OFFER_EXPIRED',
        'Teklifin süresi doldu.',
      );

      final state = await act(OfferAnswerRequested('o_komi', accept: true));

      expect(ids(state.offers), ['o_barista', 'o_garson']);
      expect(state.actionError, 'Teklifin süresi doldu.');
    });
  });

  group('Detayları Gör', () {
    test('ilk açılışta çekilir, sonra önbellekten', () async {
      await load(OffersRequested());

      var state = await act(OfferDetailToggled('o_garson'));
      expect(state.expandedIds, {'o_garson'});
      expect(state.details['o_garson']!.city, 'İstanbul');

      state = await act(OfferDetailToggled('o_garson'));
      expect(state.expandedIds, isEmpty);
      state = await act(OfferDetailToggled('o_garson'));
      expect(state.expandedIds, {'o_garson'});

      expect(
        server.sent.where((s) => s == 'GET /api/offers/o_garson'),
        hasLength(1),
      );
    });

    test('çekilemezse kapanır + toast', () async {
      await load(OffersRequested());
      server.detailFails = true;

      final state = await act(OfferDetailToggled('o_garson'));

      expect(state.expandedIds, isEmpty);
      expect(state.actionError, 'Sunucu hatası');
    });
  });

  test('6 saatten az kaldıysa acil (kırmızı geri sayım)', () async {
    final state = await load(OffersRequested());
    final byId = {for (final o in state.offers) o.id: o};

    expect(byId['o_komi']!.isUrgent(_now), isTrue);
    expect(byId['o_garson']!.isUrgent(_now), isFalse);
    expect(byId['o_komi']!.status, OfferStatus.pending);
  });
}
