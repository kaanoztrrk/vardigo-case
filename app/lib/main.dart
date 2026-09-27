import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/injection.dart';

void main() {
  setupDependencies();
  runApp(const VardigoApp());
}
