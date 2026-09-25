import 'package:flutter/material.dart';

import 'theme/colors.dart';
import 'widgets/phone_frame.dart';

void main() => runApp(const VardigoApp());

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
