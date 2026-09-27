import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/main/phone_frame.dart';
import 'router/app_router.dart';

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
    // Telefon çerçevesi `builder`'da: Navigator'ın ÜSTÜNDE, böylece
    // snackbar / diyalog gibi Navigator üzerinden açılan her şey de
    // çerçevenin İÇİNDE kalıyor.
    //
    // Material: çerçeve Navigator'ın dışında kaldığı için status bar'daki
    // saat bir Material'ın altında değil — yoksa metin varsayılan sarı
    // alt çizgiyle çiziliyor.
    builder: (context, child) => Material(
      color: AppColors.slate100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          // Tarayıcı penceresi 844 px'ten kısaysa telefon orantılı
          // küçülür.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: PhoneFrame(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    ),
  );
}
