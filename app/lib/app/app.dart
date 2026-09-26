import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/main/phone_frame.dart';

/// Uygulamanın kökü.
///
/// Tek, sabit bir light tema var: hedef referans PNG'ye piksel yakınlığı,
/// o yüzden widget'lar renkleri Theme üzerinden değil DOĞRUDAN
/// [AppColors]'tan okuyor.
class VardigoApp extends StatelessWidget {
  const VardigoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Vardigo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Urbanist',
          scaffoldBackgroundColor: AppColors.slate100,
        ),
        home: const Scaffold(
          // Tarayıcı penceresi 844 px'ten kısaysa telefon orantılı küçülür.
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                // Ekranlar sonraki adımlarda.
                child: PhoneFrame(child: SizedBox.shrink()),
              ),
            ),
          ),
        ),
      );
}
