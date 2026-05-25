import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:phorm_annotations/phorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for custom SQL functions annotated with [SqlFunc].
class SqlFunctionGenerator extends Generator {
  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();
    final functions = <_SqlFuncData>[];

    const sqlFuncChecker = TypeChecker.fromUrl(
        'package:sqflow_platform_interface/src/annotations.dart#SqlFunc');

    // Find all top-level functions in the library
    for (final element in library.allElements) {
      if (element is FunctionElement) {
        final annotation = sqlFuncChecker.firstAnnotationOf(element);
        if (annotation == null) continue;

        final reader = ConstantReader(annotation);
        final explicitName = reader.read('name').literalValue as String?;
        final sqlName = explicitName ?? element.name.toUpperCase();

        functions.add(_SqlFuncData(
          element: element,
          sqlName: sqlName,
        ));
      }
    }

    if (functions.isEmpty) {
      return '';
    }

    // Write the part of header to bind the generated file with the source file
    final fileName = p.basename(buildStep.inputId.path);
    buffer
      ..writeln("part of '$fileName';\n")

      // 1. Generate Custom SQL functions list registration

      ..writeln('// Custom SQL function registrations')
      ..writeln('final customSqlFunctions = [');
    for (final fn in functions) {
      final name = fn.sqlName;
      final dartName = fn.element.name;
      final argCount = fn.element.parameters.length;

      buffer
        ..writeln('  SqlFunction.custom(')
        ..writeln("    name: '$name',")
        ..writeln('    argumentCount: $argCount,')
        ..writeln('    function: (args) {');

      final argsInvocation = <String>[];
      for (var i = 0; i < argCount; i++) {
        final param = fn.element.parameters[i];
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

      // 2. Generate Type-safe Extensions on SqflowColumn
      ..writeln('// Type-safe column extensions for custom SQL functions');
    for (final fn in functions) {
      final sqlName = fn.sqlName;
      final dartMethodName = fn.element.name;
      final returnType = fn.element.returnType;

      // Determine target column type from the first parameter of the Dart function
      String targetTypeStr = 'dynamic';
      if (fn.element.parameters.isNotEmpty) {
        final firstParamType = fn.element.parameters.first.type;
        targetTypeStr = _getNonNullableTypeName(firstParamType);
      }

      final returnTypeStr = _getNonNullableTypeName(returnType);
      // Function name to capitalize first letter
      final functionName =
          "${fn.element.name[0].toUpperCase()}${fn.element.name.substring(1)}";
      buffer
        ..writeln(
            'extension ${functionName}SqflowColumnExtension on SqflowColumn<$targetTypeStr> {')
        ..writeln(
            '  /// Applies the custom SQL function `$sqlName` to this column.')
        ..writeln('  SqflowColumn<$returnTypeStr> $dartMethodName() {')
        ..writeln("    return sqlFunction<$returnTypeStr>('$sqlName');")
        ..writeln('  }')
        ..writeln('}\n');
    }

    return buffer.toString();
  }

  String _getTypeNameWithNullability(DartType type) {
    final baseName = type.getDisplayString();
    final cleanBase = baseName.endsWith('?')
        ? baseName.substring(0, baseName.length - 1)
        : baseName;
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return '$cleanBase?';
    }
    return cleanBase;
  }

  String _getNonNullableTypeName(DartType type) {
    final baseName = type.getDisplayString();
    final cleanBase = baseName.endsWith('?')
        ? baseName.substring(0, baseName.length - 1)
        : baseName;
    if (cleanBase == 'void') return 'dynamic';
    return cleanBase;
  }
}

class _SqlFuncData {
  final FunctionElement element;
  final String sqlName;

  _SqlFuncData({
    required this.element,
    required this.sqlName,
  });
}
