import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vardigo_app/core/services/api_service.dart';
import 'package:vardigo_app/features/auth/bloc/auth_bloc.dart';
import 'package:vardigo_app/features/auth/bloc/auth_event.dart';
import 'package:vardigo_app/features/auth/data/enum/user_role.dart';
import 'package:vardigo_app/features/auth/data/repository/auth_repository.dart';
import 'package:vardigo_app/features/auth/widget/role_switch.dart';

void main() {
  late List<String> logins;
  late AuthBloc bloc;

  setUp(() {
    logins = [];
    // Sahte sunucu: her girişi kaydeder, 50 ms sonra token döner.
    final client = MockClient((request) async {
      final role = jsonDecode(request.body)['role'] as String;
      logins.add(role);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return http.Response(
        jsonEncode({
          'ok': true,
          'data': {'token': 'dev-$role', 'role': role},
        }),
        200,
      );
    });
    bloc = AuthBloc(
      AuthRepository(ApiService(client: client, baseUrl: 'http://api.test')),
    );
  });

  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Center(child: RoleSwitch(bloc: bloc)),
    ),
  );

  testWidgets('İş arayan\'a dokununca worker olarak giriş yapar', (
    tester,
  ) async {
    bloc.add(AuthRoleSelected(UserRole.employer));
    await pump(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    // Giriş bitti; anahtar yeniden çizilsin (yoksa hâlâ "sürüyor" sanır).
    await tester.pump();

    await tester.tap(find.text('İş arayan'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(logins, ['employer', 'worker']);
    expect(bloc.state.role, UserRole.worker);
  });

  testWidgets('aktif role ya da giriş sürerken dokunmak istek atmaz', (
    tester,
  ) async {
    bloc.add(AuthRoleSelected(UserRole.employer));
    await pump(tester);
    await tester.pump();

    // Giriş sürüyor: İş arayan'a dokunmak yok sayılır.
    await tester.tap(find.text('İş arayan'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    // Giriş bitti; aktif role (İşveren) dokunmak da yok sayılır.
    await tester.tap(find.text('İşveren'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(logins, ['employer']);
    expect(bloc.state.role, UserRole.employer);
  });
}
