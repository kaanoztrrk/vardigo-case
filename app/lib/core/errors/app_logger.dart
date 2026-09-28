import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Colored, tagged console logging.
///
/// ```dart
/// AppLogger.debug(tag: 'Auth', message: 'Login started');
/// AppLogger.error(tag: 'Auth', message: 'Login failed', error: e, stackTrace: st);
/// ```
///
/// The tag tells you where a log came from, e.g. 'Api', 'Candidates',
/// 'Offers'.
class AppLogger {
  AppLogger._();

  // ANSI colors. Consoles that don't support them just print the codes,
  // which is harmless.
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
    // Release builds only log errors.
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

    // Also send it to DevTools, where logs can be filtered and the
    // error/stackTrace are kept as structured fields.
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

  // developer.log takes an int level (0-2000, higher is more severe).
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
