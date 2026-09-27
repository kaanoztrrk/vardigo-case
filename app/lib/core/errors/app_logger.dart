import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Terminalde renkli, etiketli log çıktısı üreten merkezi logger.
///
/// Kullanım:
/// ```dart
/// AppLogger.debug(tag: 'Auth', message: 'Kullanıcı kaydı başlatıldı');
/// AppLogger.error(tag: 'Auth', message: 'Giriş başarısız', error: e, stackTrace: st);
/// ```
///
/// Etiket (tag), hatanın hangi katmandan/feature'dan geldiğini hızlıca
/// ayırt etmek için kullanılıyor — örn. 'Api', 'Candidates', 'Offers'.
class AppLogger {
  AppLogger._();

  // ANSI renk kodları — terminal/IDE console'da çalışır. Bazı IDE
  // konsolları ANSI'yi desteklemeyebilir, o durumda kod olduğu gibi
  // (renksiz) görünür, işlevi bozmaz.
  static const String _reset = '\x1B[0m';
  static const String _grey = '\x1B[90m';
  static const String _cyan = '\x1B[36m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _bold = '\x1B[1m';

  static void debug({String tag = 'App', String message = ''}) {
    _log(LogLevel.debug, tag, message);
  }

  static void info({String tag = 'App', String message = ''}) {
    _log(LogLevel.info, tag, message);
  }

  static void warning({String tag = 'App', String message = ''}) {
    _log(LogLevel.warning, tag, message);
  }

  static void error({
    String tag = 'App',
    String message = '',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Release build'de debug/info/warning seviyeleri boğuluyor, sadece
    // error her zaman loglanır.
    if (!kDebugMode && level != LogLevel.error) return;

    final color = _colorFor(level);
    final levelLabel = _labelFor(level);
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);

    final buffer = StringBuffer()
      ..write(color)
      ..write('$_bold[$levelLabel]$_reset$color ')
      ..write('$timestamp [$tag] ')
      ..write(message)
      ..write(_reset);

    // ignore: avoid_print
    print(buffer.toString());

    // dart:developer.log DevTools'ta yapılandırılmış/filtrelenebilir log
    // görünümü sağlıyor, ayrıca error/stackTrace alanlarını native olarak
    // taşıyor.
    developer.log(
      message,
      name: tag,
      level: _severityFor(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _colorFor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return _grey;
      case LogLevel.info:
        return _cyan;
      case LogLevel.warning:
        return _yellow;
      case LogLevel.error:
        return _red;
    }
  }

  static String _labelFor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO ';
      case LogLevel.warning:
        return 'WARN ';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  // dart:developer.log'un level parametresi int bekliyor (0-2000 arası,
  // yüksek değer = daha ciddi).
  static int _severityFor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
