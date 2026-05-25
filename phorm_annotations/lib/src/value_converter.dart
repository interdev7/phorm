/// Base class for converting between a Dart type [T] and a database-compatible type [S].
///
/// Usage:
/// ```dart
/// class DateTimeConverter extends ValueConverter<DateTime, int> {
///   const DateTimeConverter();
///   @override
///   DateTime fromSql(int sqlValue) => DateTime.fromMillisecondsSinceEpoch(sqlValue);
///   @override
///   int toSql(DateTime value) => value.millisecondsSinceEpoch;
/// }
/// ```
abstract class ValueConverter<T, S> {
  const ValueConverter();

  /// Converts the database value [S] back to the Dart type [T].
  T fromSql(S sqlValue);

  /// Converts the Dart value [T] to a database-compatible type [S].
  S toSql(T value);
}
