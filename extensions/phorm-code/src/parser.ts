// Dart class parser — extracts class structure from raw text

export interface DartField {
  name: string;
  type: string;
  isNullable: boolean;
  rawLine: string;          // original line for preserving existing annotations
  annotations: string[];    // existing annotations like @Column(), @ID() etc.
  hasColumnAnnotation: boolean;
  hasIdAnnotation: boolean;
}

export interface DartClass {
  name: string;
  fields: DartField[];
  constructorParams: string[];
  hasIdField: boolean;
  idField?: DartField;
  alreadyConverted: boolean;  // already has "extends Model"
  startIndex: number;         // char index in source where class starts
  endIndex: number;           // char index in source where class ends
  fullText: string;           // original class text
}

export interface ParsedFile {
  classes: DartClass[];
  hasImport: boolean;
  hasPart: boolean;
  source: string;
  fileName: string;           // e.g. "user"
}

/**
 * Parses all Dart classes from source text.
 * Uses regex-based approach — covers 90%+ of real-world classes.
 */
export function parseFile(source: string, fileName: string): ParsedFile {
  const hasImport = source.includes("package:phorm/phorm.dart") ||
                     source.includes("package:phorm_sqlite/phorm_sqlite.dart") ||
                     source.includes("package:phorm_postgres/phorm_postgres.dart") ||
                     source.includes("package:phorm_mysql/phorm_mysql.dart");
  const hasPart = source.includes(".sql.g.dart'") || source.includes('.sql.g.dart"');

  const classes = extractClasses(source);

  return { classes, hasImport, hasPart, source, fileName };
}

/**
 * Finds all top-level class declarations in source and parses each one.
 */
function extractClasses(source: string): DartClass[] {
  const result: DartClass[] = [];

  // Match class declarations (including those with extends/with)
  // Captures: class Name [extends X] [with Y] [implements Z] {
  const classPattern = /^(class\s+(\w+)(?:\s+extends\s+[\w<>, ]+)?(?:\s+with\s+[\w<>, ]+)?(?:\s+implements\s+[\w<>, ]+)?\s*\{)/gm;

  let match: RegExpExecArray | null;
  const classStarts: Array<{ index: number; name: string; header: string }> = [];

  while ((match = classPattern.exec(source)) !== null) {
    classStarts.push({
      index: match.index,
      name: match[2],
      header: match[1],
    });
  }

  for (let i = 0; i < classStarts.length; i++) {
    const start = classStarts[i].index;
    const end = i + 1 < classStarts.length
      ? classStarts[i + 1].index
      : source.length;

    const classText = source.substring(start, end).trimEnd();
    const parsed = parseClass(classStarts[i].name, classText, start, start + classText.length);
    if (parsed) {
      result.push(parsed);
    }
  }

  return result;
}

/**
 * Parses a single class block into DartClass structure.
 */
function parseClass(
  name: string,
  classText: string,
  startIndex: number,
  endIndex: number
): DartClass | null {
  // Skip abstract classes and mixins
  if (/^\s*(abstract|mixin)\s+class/.test(classText)) {
    return null;
  }

  const alreadyConverted = /extends\s+Model/.test(classText);

  // Extract fields: lines with "final Type name;" pattern
  const fields = extractFields(classText);

  const hasIdField = fields.some(f => f.name === 'id');
  const idField = fields.find(f => f.name === 'id');

  // Extract constructor param names (to detect which fields are in constructor)
  const constructorParams = extractConstructorParams(name, classText);

  return {
    name,
    fields,
    constructorParams,
    hasIdField,
    idField,
    alreadyConverted,
    startIndex,
    endIndex,
    fullText: classText,
  };
}

/**
 * Extracts field declarations from a class body.
 * Handles:
 *   @Annotation()
 *   @Annotation()
 *   final Type fieldName;
 */
function extractFields(classText: string): DartField[] {
  const fields: DartField[] = [];

  // Split into lines and process annotation + field pairs
  const lines = classText.split('\n');

  let pendingAnnotations: string[] = [];

  for (const line of lines) {
    const trimmed = line.trim();

    // Collect annotations (lines starting with @)
    if (trimmed.startsWith('@')) {
      pendingAnnotations.push(trimmed);
      continue;
    }

    // Match field declaration: [late] [final/var] Type? name;
    const fieldMatch = trimmed.match(
      /^(?:late\s+)?(?:final\s+|var\s+)?([\w<>?, ]+?)\s+(\w+)\s*;/
    );

    if (fieldMatch) {
      const rawType = fieldMatch[1].trim();
      const fieldName = fieldMatch[2];

      // Skip common non-field patterns
      if (fieldName === 'class' || rawType.includes('(') || rawType.includes(')')) {
        pendingAnnotations = [];
        continue;
      }

      const isNullable = rawType.endsWith('?');
      const type = isNullable ? rawType.slice(0, -1) : rawType;

      const annotations = [...pendingAnnotations];
      const hasColumnAnnotation = annotations.some(a => a.startsWith('@Column'));
      const hasIdAnnotation = annotations.some(a => a.startsWith('@ID'));

      fields.push({
        name: fieldName,
        type,
        isNullable,
        rawLine: trimmed,
        annotations,
        hasColumnAnnotation,
        hasIdAnnotation,
      });

      pendingAnnotations = [];
      continue;
    }

    // Non-field, non-annotation line — reset pending annotations
    if (
      trimmed !== '' &&
      !trimmed.startsWith('//') &&
      !trimmed.startsWith('*') &&
      !trimmed.startsWith('@override')
    ) {
      pendingAnnotations = [];
    }
  }

  return fields;
}

/**
 * Extracts parameter names from the default constructor.
 */
function extractConstructorParams(className: string, classText: string): string[] {
  // Match: ClassName({...}) or ClassName(...) possibly multiline
  const ctorPattern = new RegExp(
    `${className}\\s*\\(([\\s\\S]*?)\\)\\s*(?::|;|\\{)`,
    'm'
  );
  const match = ctorPattern.exec(classText);
  if (!match) { return []; }

  const paramsText = match[1];
  const params: string[] = [];

  // Extract "required this.name", "this.name", "Type name"
  const paramPattern = /(?:required\s+)?(?:this\.(\w+)|(\w+)\s+(\w+))/g;
  let m: RegExpExecArray | null;
  while ((m = paramPattern.exec(paramsText)) !== null) {
    params.push(m[1] ?? m[3]);
  }

  return params;
}

/**
 * Converts camelCase → snake_case  (e.g. "firstName" → "first_name")
 */
export function camelToSnake(str: string): string {
  return str
    .replace(/([a-z])([A-Z])/g, '$1_$2')
    .toLowerCase();
}

/**
 * Pluralizes a snake_case table name  (e.g. "user" → "users", "category" → "categories")
 */
export function pluralize(word: string): string {
  if (word.endsWith('y')) {
    return word.slice(0, -1) + 'ies';
  }
  if (
    word.endsWith('s') ||
    word.endsWith('sh') ||
    word.endsWith('ch') ||
    word.endsWith('x') ||
    word.endsWith('z')
  ) {
    return word + 'es';
  }
  return word + 's';
}
