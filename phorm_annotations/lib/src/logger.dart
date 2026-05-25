/// Interface for PHORM logging.
///
/// Implement this to route PHORM logs to your preferred logging service
/// (e.g. Firebase Crashlytics, Datadog, or custom file loggers).
abstract interface class PhormLogger {
  /// Logs an informational message.
  void info(String message);

  /// Logs a database query, execution time, and arguments.
  void query(String sql, List<Object?>? arguments, Duration duration);

  /// Logs a slow query that exceeded the defined threshold.
  void slowQuery(String sql, List<Object?>? arguments, Duration duration);

  /// Logs an error with optional stack trace.
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// A default colored console logger for PHORM.
class PhormConsoleLogger implements PhormLogger {
  final bool enableColors;

  const PhormConsoleLogger({this.enableColors = true});

  static const String _reset = '\x1B[0m';
  static const String _blue = '\x1B[34m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _gray = '\x1B[90m';

  String _color(String color, String text) {
    if (!enableColors) return text;
    return '$color$text$_reset';
  }

  @override
  void info(String message) {
    print('${_color(_blue, '💡 [Phorm Info]')} $message');
  }

  @override
  void query(String sql, List<Object?>? arguments, Duration duration) {
    final argsStr = arguments != null && arguments.isNotEmpty
        ? ' ${_color(_gray, 'Args: $arguments')}'
        : '';
    print(
        '${_color(_green, '⚡ [Phorm Query]')} ${_color(_gray, '(${duration.inMilliseconds}ms)')} $sql$argsStr');
  }

  @override
  void slowQuery(String sql, List<Object?>? arguments, Duration duration) {
    final argsStr = arguments != null && arguments.isNotEmpty
        ? ' ${_color(_gray, 'Args: $arguments')}'
        : '';
    print(
        '${_color(_yellow, '⚠️ [Phorm Slow Query]')} ${_color(_red, '(${duration.inMilliseconds}ms)')} $sql$argsStr');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('${_color(_red, '❌ [Phorm Error]')} $message');
    if (error != null) {
      print(_color(_red, 'Details: $error'));
    }
    if (stackTrace != null) {
      print(_color(_gray, stackTrace.toString()));
    }
  }
}
