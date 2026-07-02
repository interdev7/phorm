import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../function_generator.dart';

/// SQLite custom function emission.
///
/// Registers each annotated Dart function as a native SQLite callback
/// (`SqlFunction.custom`) and emits type-safe `PhormColumn` extensions that call
/// the function via `sqlFunction<T>('NAME')`. This is the reference (fully
/// implemented) dialect.
class SqliteFunctionGenerator extends FunctionGenerator {
  const SqliteFunctionGenerator();

  @override
  String get name => 'sqlite';

  @override
  String generate(List<SqlFuncData> functions) {
    if (functions.isEmpty) return '';

    final buffer =
        StringBuffer()
          // 1. Generate Custom SQL functions list registration
          ..writeln('// Custom SQL function registrations')
          ..writeln('final customSqlFunctions = [');
    for (final fn in functions) {
      final name = fn.sqlName;
      final dartName = fn.element.name ?? '';
      final argCount = fn.element.formalParameters.length;

      buffer
        ..writeln('  SqlFunction.custom(')
        ..writeln("    name: '$name',")
        ..writeln('    argumentCount: $argCount,')
        ..writeln('    function: (args) {');

      final argsInvocation = <String>[];
      for (var i = 0; i < argCount; i++) {
        final param = fn.element.formalParameters[i];
        final paramType = _getTypeNameWithNullability(param.type);
        argsInvocation.add('args[$i] as $paramType');
      }

      buffer
        ..writeln('      return $dartName(${argsInvocation.join(', ')});')
        ..writeln('    },')
        ..writeln('  ),');
    }
    buffer
      ..writeln('];\n')
      // 2. Generate Type-safe Extensions on PhormColumn
      ..writeln('// Type-safe column extensions for custom SQL functions');
    for (final fn in functions) {
      final sqlName = fn.sqlName;
      final dartMethodName = fn.element.name ?? '';
      final returnType = fn.element.returnType;

      // Determine target column type from the first parameter of the Dart function
      String targetTypeStr = 'dynamic';
      if (fn.element.formalParameters.isNotEmpty) {
        final firstParamType = fn.element.formalParameters.first.type;
        targetTypeStr = _getNonNullableTypeName(firstParamType);
      }

      final returnTypeStr = _getNonNullableTypeName(returnType);
      // Function name to capitalize first letter
      final functionName =
          "${dartMethodName[0].toUpperCase()}${dartMethodName.substring(1)}";
      buffer
        ..writeln(
          'extension ${functionName}PhormColumnExtension on PhormColumn<$targetTypeStr> {',
        )
        ..writeln(
          '  /// Applies the custom SQL function `$sqlName` to this column.',
        )
        ..writeln('  PhormColumn<$returnTypeStr> $dartMethodName() {')
        ..writeln("    return sqlFunction<$returnTypeStr>('$sqlName');")
        ..writeln('  }')
        ..writeln('}\n');
    }

    return buffer.toString();
  }

  String _getTypeNameWithNullability(DartType type) {
    final baseName = type.getDisplayString();
    final cleanBase =
        baseName.endsWith('?')
            ? baseName.substring(0, baseName.length - 1)
            : baseName;
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return '$cleanBase?';
    }
    return cleanBase;
  }

  String _getNonNullableTypeName(DartType type) {
    final baseName = type.getDisplayString();
    final cleanBase =
        baseName.endsWith('?')
            ? baseName.substring(0, baseName.length - 1)
            : baseName;
    if (cleanBase == 'void') return 'dynamic';
    return cleanBase;
  }
}
