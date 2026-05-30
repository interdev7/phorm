// Transforms a parsed Dart file into a SQFlow model file

import { ParsedFile, DartClass, DartField, camelToSnake, pluralize } from './parser';

/**
 * Main entry point.
 * Returns the fully transformed source code.
 */
export function transformFile(parsed: ParsedFile): string {
  let source = parsed.source;

  // Process each class separately, working from the END backwards
  // to preserve correct character indices after each replacement
  const classesToConvert = parsed.classes.filter(c => !c.alreadyConverted);

  if (classesToConvert.length === 0) {
    return source; // nothing to do
  }

  // Sort descending by startIndex so replacements don't shift earlier indices
  const sorted = [...classesToConvert].sort((a, b) => b.startIndex - a.startIndex);

  for (const cls of sorted) {
    const newClassText = transformClass(cls);
    source =
      source.substring(0, cls.startIndex) +
      newClassText +
      source.substring(cls.endIndex);
  }

  // Prepend header (import + part) after all class transformations
  source = buildHeader(parsed, source);

  return source;
}

// ---------------------------------------------------------------------------
// Header (import + part directive)
// ---------------------------------------------------------------------------

function buildHeader(parsed: ParsedFile, source: string): string {
  const lines: string[] = [];

  // Add phorm import if missing
  if (!parsed.hasImport) {
    lines.push("import 'package:phorm/phorm.dart';");
    lines.push('');
  }

  // Add part directive if missing
  if (!parsed.hasPart) {
    lines.push(`part '${parsed.fileName}.sql.g.dart';\n`);
    lines.push('');
    lines.push('');  // extra blank line before first class
  }

  if (lines.length === 0) {
    return source;
  }

  // Insert after existing imports (find last import line)
  const lastImportMatch = [...source.matchAll(/^import\s+.+;/gm)].pop();
  if (lastImportMatch?.index !== undefined) {
    const insertAt = lastImportMatch.index + lastImportMatch[0].length;
    return (
      source.substring(0, insertAt) +
      '\n' +
      lines.join('\n') +
      source.substring(insertAt)
    );
  }

  // No imports found — prepend everything
  return lines.join('\n') + source;
}

// ---------------------------------------------------------------------------
// Single class transformation
// ---------------------------------------------------------------------------

function transformClass(cls: DartClass): string {
  const { name, fields } = cls;
  const tableName = pluralize(camelToSnake(name));

  const buf: string[] = [];

  // @Schema annotation
  buf.push(`@Schema(tableName: '${tableName}')`);

  // Class declaration line
  buf.push(`class ${name} extends Model with _\$Phorm${name}Mixin {`);

  // --- Fields ---

  // If no id field exists → inject one at the top
  if (!cls.hasIdField) {
    buf.push('  @ID(autoIncrement: true)');
    buf.push('  final int id;');
    buf.push('');
  }

  for (const field of fields) {
    // Skip fields that already have @override (e.g. manually overridden id)
    const isOverridden = field.annotations.some(a => a === '@override');

    if (field.name === 'id') {
      // Build @ID annotation based on type
      if (!field.hasIdAnnotation) {
        if (field.type === 'String') {
          buf.push('  @ID(autoIncrement: false, unique: true)');
        } else {
          buf.push('  @ID(autoIncrement: true)');
        }
      } else {
        // Already has @ID — preserve existing annotations as-is
        for (const ann of field.annotations) {
          buf.push(`  ${ann}`);
        }
      }
    } else {
      // Non-id field: preserve existing annotations, add @Column() if missing
      if (!field.hasColumnAnnotation && !isOverridden) {
        buf.push('  @Column()');
      }
      for (const ann of field.annotations) {
        if (ann !== '@override') { // @override on a regular field is unusual, skip
          buf.push(`  ${ann}`);
        }
      }
    }

    // Write the field declaration itself
    const nullable = field.isNullable ? '?' : '';
    buf.push(`  final ${field.type}${nullable} ${field.name};`);
    buf.push('');
  }

  // --- Constructor ---
  buf.push(`  ${name}({`);

  // If id was injected, add it as first required param
  if (!cls.hasIdField) {
    buf.push('    required this.id,');
  }

  for (const field of fields) {
    if (field.isNullable) {
      buf.push(`    this.${field.name},`);
    } else {
      buf.push(`    required this.${field.name},`);
    }
  }
  buf.push('  });');
  buf.push('');

  // --- factory fromJson ---
  buf.push(`  factory ${name}.fromJson(Map<String, dynamic> json) =>`);
  buf.push(`      _\$Phorm${name}FromJson(json);`);

  buf.push('}');

  return buf.join('\n');
}
