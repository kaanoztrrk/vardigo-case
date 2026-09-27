import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_scroll_behavior.dart';
import '../core/widgets/main/phone_frame.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/widget/role_switch.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'router/route.dart';

/// Uygulamanın kökü.
///
/// Tek, sabit bir light tema var: hedef referans PNG'ye piksel yakınlığı,
/// o yüzden widget'lar renkleri Theme üzerinden değil DOĞRUDAN
/// [AppColors]'tan okuyor.
class VardigoApp extends StatelessWidget {
  const VardigoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Vardigo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'Urbanist',
      scaffoldBackgroundColor: AppColors.slate100,
    ),
    routerConfig: router,
    // Fareyle sürükleyerek kaydırma (bkz. AppScrollBehavior).
    scrollBehavior: const AppScrollBehavior(),
    // Telefon çerçevesi `builder`'da: Navigator'ın ÜSTÜNDE, böylece
    // snackbar / diyalog gibi Navigator üzerinden açılan her şey de
    // çerçevenin İÇİNDE kalıyor.
    //
    // Material: çerçeve Navigator'ın dışında kaldığı için status bar'daki
    // saat bir Material'ın altında değil — yoksa metin varsayılan sarı
    // alt çizgiyle çiziliyor.
    //
    // Rol anahtarı çerçevenin ÜSTÜNDE, sayfa zemininde: uygulamanın değil
    // demonun kontrolü (bkz. RoleSwitch).
    builder: (context, child) => Material(
      color: AppColors.slate100,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RoleSwitch(bloc: getIt<AuthBloc>()),
            const SizedBox(height: 20),
            // Tarayıcı penceresi kısaysa telefon orantılı küçülür.
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _Frame(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Telefon çerçevesi + aktif route'a göre home indicator.
///
/// Referans 2'de home indicator yok ve kartlar alt bezel'e kadar iniyor
/// (spec 02: "home bar zorunlu değil"). Çerçeve route ağacının dışında,
/// o yüzden aktif route'u router'dan okuyor. Router build SIRASINDA da
/// haber verebildiği için güncelleme bir sonraki kareye erteleniyor.
class _Frame extends StatefulWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  bool _showHomeIndicator = true;

  @override
  void initState() {
    super.initState();
    router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final show =
        router.routerDelegate.currentConfiguration.uri.path !=
        AppRoutes.offersView;
    if (show == _showHomeIndicator) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showHomeIndicator = show);
    });
  }

  @override
  Widget build(BuildContext context) =>
      PhoneFrame(showHomeIndicator: _showHomeIndicator, child: widget.child);
}
