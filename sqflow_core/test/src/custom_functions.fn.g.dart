// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// SqlFunctionGenerator
// **************************************************************************

part of 'custom_functions.dart';

// Custom SQL function registrations
final customSqlFunctions = [
  SqlFunction.custom(
    name: 'DOUBLE',
    argumentCount: 1,
    function: (args) {
      return doubleValue(args[0] as int?);
    },
  ),
  SqlFunction.custom(
    name: 'TO_SLUG',
    argumentCount: 1,
    function: (args) {
      return toSlug(args[0] as String?);
    },
  ),
  SqlFunction.custom(
    name: 'IS_ADULT',
    argumentCount: 1,
    function: (args) {
      return isAdult(args[0] as int?);
    },
  ),
];

// Type-safe column extensions for custom SQL functions
extension DoubleValueSqflowColumnExtension on SqflowColumn<int> {
  /// Applies the custom SQL function `DOUBLE` to this column.
  SqflowColumn<int> doubleValue() {
    return sqlFunction<int>('DOUBLE');
  }
}

extension ToSlugSqflowColumnExtension on SqflowColumn<String> {
  /// Applies the custom SQL function `TO_SLUG` to this column.
  SqflowColumn<String> toSlug() {
    return sqlFunction<String>('TO_SLUG');
  }
}

extension IsAdultSqflowColumnExtension on SqflowColumn<int> {
  /// Applies the custom SQL function `IS_ADULT` to this column.
  SqflowColumn<bool> isAdult() {
    return sqlFunction<bool>('IS_ADULT');
  }
}
