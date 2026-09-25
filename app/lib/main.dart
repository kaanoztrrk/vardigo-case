import 'package:flutter/material.dart';

import 'theme/colors.dart';

void main() => runApp(const VardigoApp());

class VardigoApp extends StatelessWidget {
  const VardigoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Vardigo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Urbanist',
          scaffoldBackgroundColor: AppColors.white,
        ),
        // Telefon çerçevesi ve ekranlar sonraki adımlarda.
        home: const Scaffold(body: SizedBox.shrink()),
      );
}
