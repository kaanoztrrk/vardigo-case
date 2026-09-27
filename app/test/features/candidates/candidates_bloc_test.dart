import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vardigo_app/core/services/api_service.dart';
import 'package:vardigo_app/features/candidates/bloc/candidates/candidates_bloc.dart';
import 'package:vardigo_app/features/candidates/bloc/candidates/candidates_event.dart';
import 'package:vardigo_app/features/candidates/bloc/candidates/candidates_state.dart';
import 'package:vardigo_app/features/candidates/data/enum/candidate_sort.dart';
import 'package:vardigo_app/features/candidates/data/enum/candidate_tab.dart';
import 'package:vardigo_app/features/candidates/data/repository/candidate_repository.dart';
import 'package:vardigo_app/features/offers/data/repository/offer_repository.dart';

const _base = 'http://api.test';

const _names = {
  'w_merve': 'Merve Y.',
  'w_ferhat': 'Ferhat C.',
  'w_derya': 'Derya A.',
  'w_ayse': 'Ayşe K.',
};

Map<String, Object> _candidate(String id) => {
  'id': id,
  'name': _names[id]!,
  'rating': '4.9',
  'attend': '%100 katılım',
  'km': '4.9 km',
  'photo': '/assets/photos/$id.png',
  'online': true,
  'expectedPay': '25.000',
  'payMatch': true,
};

// Sunucudaki sekme ayrımının kısaltılmışı (bkz. server/data/seed.json).
const _byTab = {
  'perfect': ['w_merve', 'w_ferhat'],
  'similar': ['w_derya', 'w_ayse'],
};

/// Sahte sunucu: GET'te sekmeye göre liste döner, gelen istekleri
/// [sent]'e yazar. [fail] true iken 500 döner; [delays] sekme başına
/// gecikme. POST /offers gövdelerini [posted]'a yazar; [busy]'deki
/// adaylar için gerçek sunucu gibi atomik 409 döner.
class _Server {
  final sent = <Uri>[];
  bool fail = false;
  Map<String, Duration> delays = {};
  final posted = <List<String>>[];
  Set<String> busy = {};

  http.Client get client => MockClient((request) async {
    if (request.method == 'POST') return _offers(request);
    sent.add(request.url);
    final tab = request.url.queryParameters['tab']!;
    await Future.delayed(delays[tab] ?? Duration.zero);
    if (fail) {
      return _json(500, {
        'ok': false,
        'error': {'code': 'INTERNAL', 'message': 'Sunucu hatası'},
      });
    }
    return _json(200, {
      'ok': true,
      'data': {
        'totalPerfect': 26,
        'totalSimilar': 16,
        'selectedHint': 1,
        'candidates': _byTab[tab]!.map(_candidate).toList(),
      },
    });
  });

  Future<http.Response> _offers(http.Request request) async {
    final ids = List<String>.from(jsonDecode(request.body)['workerIds']);
    posted.add(ids);
    // İstek sürerken ikinci dokunuşu deneyebilmek için.
    await Future.delayed(const Duration(milliseconds: 10));
    final conflicts = ids.where(busy.contains).toList();
    if (conflicts.isNotEmpty) {
      return _json(409, {
        'ok': false,
        'error': {
          'code': 'OFFER_EXISTS',
          'message': 'Bu adaylara zaten bekleyen bir talep var: $conflicts',
          'ids': conflicts,
        },
      });
    }
    return _json(201, {
      'ok': true,
      'data': {
        'created': ids.map((id) => {'workerId': id}).toList(),
      },
    });
  }

  // Response(String) gövdeyi latin1 kodluyor, "katılım" sığmıyor.
  static http.Response _json(int status, Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  late _Server server;
  late CandidatesBloc bloc;

  setUp(() {
    server = _Server();
    final api = ApiService(client: server.client, baseUrl: _base);
    bloc = CandidatesBloc(CandidateRepository(api), OfferRepository(api));
  });

  tearDown(() => bloc.close());

  /// Olayı atar ve yükleme bitene kadar bekler. Önce yüklemenin
  /// BAŞLAMASI bekleniyor: sekme/sıralama değişimi, yükleme başlamadan
  /// önce loading=false olan bir state daha yayıyor.
  Future<CandidatesState> send(CandidatesEvent event) {
    final done = bloc.stream
        .skipWhile((s) => !s.loading)
        .firstWhere((s) => !s.loading);
    bloc.add(event);
    return done;
  }

  /// Gönderimi başlatır ve bitene kadar bekler.
  Future<CandidatesState> sendOffers() {
    final done = bloc.stream
        .skipWhile((s) => !s.sending)
        .firstWhere((s) => !s.sending);
    bloc.add(CandidatesOffersSendRequested());
    return done;
  }

  List<String> ids(CandidatesState s) => s.candidates.map((c) => c.id).toList();

  test('ilk yükleme: liste, sayılar ve ilk aday seçili', () async {
    final state = await send(CandidatesRequested());

    expect(server.sent.single.queryParameters, {
      'tab': 'perfect',
      'sort': 'recommended',
    });
    expect(ids(state), ['w_merve', 'w_ferhat']);
    expect(state.totalPerfect, 26);
    expect(state.totalSimilar, 16);
    expect(state.selectedIds, {'w_merve'});
    expect(state.candidates.first.photoUrl, '$_base/assets/photos/w_merve.png');
  });

  test('seçim eklenip çıkarılabilir', () async {
    await send(CandidatesRequested());

    bloc.add(CandidateSelectionToggled('w_ferhat'));
    bloc.add(CandidateSelectionToggled('w_merve'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.selectedIds, {'w_ferhat'});
  });

  test('sekme değişince liste değişir, seçim korunur', () async {
    await send(CandidatesRequested());

    final state = await send(CandidatesTabChanged(CandidateTab.similar));

    expect(server.sent.last.queryParameters['tab'], 'similar');
    expect(ids(state), ['w_derya', 'w_ayse']);
    expect(state.selectedIds, {'w_merve'});
    expect(state.activeTotal, 16);
  });

  test('sort chip döngüsü: Önerilen → En Yakın → Puan → Önerilen', () async {
    await send(CandidatesRequested());

    final sorts = <CandidateSort>[];
    for (var i = 0; i < 3; i++) {
      sorts.add((await send(CandidatesSortCycled())).sort);
    }

    expect(sorts, [
      CandidateSort.near,
      CandidateSort.rating,
      CandidateSort.recommended,
    ]);
    expect(server.sent.map((u) => u.queryParameters['sort']), [
      'recommended',
      'near',
      'rating',
      'recommended',
    ]);
  });

  test('ilk yükleme başarısız: error, liste yok', () async {
    server.fail = true;

    final state = await send(CandidatesRequested());

    expect(state.loaded, isFalse);
    expect(state.error, 'Sunucu hatası');
    expect(state.actionError, isNull);
  });

  test(
    'liste varken yenileme başarısız: eski liste kalır, actionError',
    () async {
      await send(CandidatesRequested());
      server.fail = true;

      final state = await send(CandidatesSortCycled());

      expect(ids(state), ['w_merve', 'w_ferhat']);
      expect(state.error, isNull);
      expect(state.actionError, 'Sunucu hatası');
    },
  );

  test('geç gelen eski cevap güncel sekmenin listesini ezmez', () async {
    await send(CandidatesRequested());
    server.delays = {'similar': const Duration(milliseconds: 50)};

    // Benzer'e geçip cevap gelmeden %100'e geri dön.
    bloc.add(CandidatesTabChanged(CandidateTab.similar));
    bloc.add(CandidatesTabChanged(CandidateTab.perfect));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.tab, CandidateTab.perfect);
    expect(ids(bloc.state), ['w_merve', 'w_ferhat']);
  });

  group('talep gönderme', () {
    test('seçilenleri gönderir, seçimi temizler, bilgi mesajı', () async {
      await send(CandidatesRequested());
      bloc.add(CandidateSelectionToggled('w_ferhat'));

      final state = await sendOffers();

      expect(server.posted.single, unorderedEquals(['w_merve', 'w_ferhat']));
      expect(state.selectedIds, isEmpty);
      expect(state.actionMessage, '2 kişiye görüşme talebi gönderildi.');
      expect(state.actionError, isNull);
    });

    test(
      '409: çakışan isimle bildirilir ve seçimden çıkar, diğeri kalır',
      () async {
        await send(CandidatesRequested());
        // Seçim sekmeler arası ortak: Derya diğer sekmeden.
        await send(CandidatesTabChanged(CandidateTab.similar));
        bloc.add(CandidateSelectionToggled('w_derya'));
        server.busy = {'w_merve'};

        final state = await sendOffers();

        expect(state.selectedIds, {'w_derya'});
        expect(
          state.actionError,
          'Merve Y. için zaten bekleyen bir talep var, seçimden çıkarıldı.',
        );
        expect(state.actionMessage, isNull);
      },
    );

    test('istek sürerken ikinci dokunuş yeni istek atmaz', () async {
      await send(CandidatesRequested());

      final done = sendOffers();
      bloc.add(CandidatesOffersSendRequested());
      await done;

      expect(server.posted, hasLength(1));
    });

    test('seçim boşken istek atılmaz', () async {
      await send(CandidatesRequested());
      bloc.add(CandidateSelectionToggled('w_merve'));
      bloc.add(CandidatesOffersSendRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(server.posted, isEmpty);
    });
  });
}
