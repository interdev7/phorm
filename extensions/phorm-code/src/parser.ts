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
  hasFromJson: boolean;       // already declares a fromJson factory/constructor
  otherMembers: string[];     // members to preserve verbatim (methods, getters, …)
  startIndex: number;         // char index in source where class starts
  endIndex: number;           // char index in source where class ends (after closing brace)
  fullText: string;           // original class text
}

/** A top-level member of a class body (with its leading annotations). */
interface ClassMember {
  annotations: string[];   // trimmed annotation lines preceding the declaration
  text: string;            // verbatim declaration text (may span lines)
  firstLine: string;       // trimmed first declaration line
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
 * Uses a regex to locate declarations and brace-counting to find their exact
 * bounds, so top-level code between/after classes is never captured.
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
 * The end of a class is determined by matching braces (respecting strings and
 * comments) rather than the start of the next class, so intervening top-level
 * declarations are preserved.
 */
function extractClasses(source: string): DartClass[] {
  const result: DartClass[] = [];

  // Captures: class Name [extends X] [with Y] [implements Z] {
  const classPattern =
    /^(class\s+(\w+)(?:<[\w$<>, ]+>)?(?:\s+extends\s+[\w$<>, ]+)?(?:\s+with\s+[\w$<>, ]+)?(?:\s+implements\s+[\w$<>, ]+)?\s*)\{/gm;

  let match: RegExpExecArray | null;
  while ((match = classPattern.exec(source)) !== null) {
    const name = match[2];
    // Index of the opening brace that starts the class body.
    const braceIndex = match.index + match[1].length;
    const bodyEnd = findMatchingBrace(source, braceIndex);
    if (bodyEnd === -1) {
      continue; // unbalanced — skip rather than corrupt the file
    }

    const endIndex = bodyEnd + 1; // include the closing brace
    const classText = source.substring(match.index, endIndex);
    const parsed = parseClass(name, classText, match.index, endIndex);
    if (parsed) {
      result.push(parsed);
    }

    // Continue scanning after this class body.
    classPattern.lastIndex = endIndex;
  }

  return result;
}

/**
 * Given the index of an opening brace, returns the index of the matching
 * closing brace, skipping over strings, chars and comments. Returns -1 if
 * the braces are unbalanced.
 */
function findMatchingBrace(source: string, openIndex: number): number {
  let depth = 0;
  for (let i = openIndex; i < source.length; i++) {
    const ch = source[i];
    const next = source[i + 1];

    // Line comment
    if (ch === '/' && next === '/') {
      const nl = source.indexOf('\n', i);
      if (nl === -1) { return -1; }
      i = nl;
      continue;
    }
    // Block comment
    if (ch === '/' && next === '*') {
      const close = source.indexOf('*/', i + 2);
      if (close === -1) { return -1; }
      i = close + 1;
      continue;
    }
    // String literals (single/double, incl. raw)
    if (ch === '"' || ch === "'") {
      i = skipString(source, i);
      continue;
    }

    if (ch === '{') { depth++; }
    else if (ch === '}') {
      depth--;
      if (depth === 0) { return i; }
    }
  }
  return -1;
}

/**
 * Skips a Dart string literal starting at `start` (the opening quote).
 * Handles escapes and triple-quoted strings. Returns the index of the closing
 * quote (so the caller's loop increments past it).
 */
function skipString(source: string, start: number): number {
  const quote = source[start];
  const triple = source.substr(start, 3) === quote.repeat(3);
  const delim = triple ? quote.repeat(3) : quote;

  let i = start + delim.length;
  while (i < source.length) {
    if (source[i] === '\\') { i += 2; continue; }
    if (source.substr(i, delim.length) === delim) {
      return i + delim.length - 1;
    }
    i++;
  }
  return source.length - 1;
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
  if (/^\s*(abstract|mixin)\s+class/.test(classText) || /^\s*mixin\s+/.test(classText)) {
    return null;
  }

  const alreadyConverted = /extends\s+Model\b/.test(classText);

  // Work only inside the class body, split into top-level members.
  const body = classBody(classText);
  const members = splitMembers(body);

  const fields: DartField[] = [];
  const otherMembers: string[] = [];
  let hasFromJson = false;

  for (const m of members) {
    const field = asField(m);
    if (field) {
      fields.push(field);
      continue;
    }
    // The default constructor is regenerated, so it is not preserved here.
    if (isDefaultConstructor(name, m.firstLine)) {
      continue;
    }
    if (new RegExp(`${name}\\.fromJson\\s*\\(`).test(m.firstLine)) {
      hasFromJson = true;
    }
    otherMembers.push(m.text.trimEnd());
  }

  const hasIdField = fields.some(f => f.name === 'id');
  const idField = fields.find(f => f.name === 'id');
  const constructorParams = extractConstructorParams(name, body);

  return {
    name,
    fields,
    constructorParams,
    hasIdField,
    idField,
    alreadyConverted,
    hasFromJson,
    otherMembers,
    startIndex,
    endIndex,
    fullText: classText,
  };
}

/**
 * Returns the text between the outermost braces of a class declaration.
 */
function classBody(classText: string): string {
  const open = classText.indexOf('{');
  const close = classText.lastIndexOf('}');
  if (open === -1 || close === -1 || close <= open) { return classText; }
  return classText.substring(open + 1, close);
}

/** Net brace depth contributed by a line, ignoring strings and comments. */
function netBraces(line: string): number {
  let depth = 0;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    const next = line[i + 1];
    if (ch === '/' && next === '/') { break; }
    if (ch === '"' || ch === "'") {
      // skip to closing quote on this line (best-effort, single line)
      i++;
      while (i < line.length && line[i] !== ch) {
        if (line[i] === '\\') { i++; }
        i++;
      }
      continue;
    }
    if (ch === '{') { depth++; }
    else if (ch === '}') { depth--; }
  }
  return depth;
}

/**
 * Splits a class body into top-level members, grouping leading annotations
 * with their declaration. Only members at brace-depth 0 are considered, so
 * statements inside method bodies are never mistaken for class members.
 */
function splitMembers(body: string): ClassMember[] {
  const members: ClassMember[] = [];
  const lines = body.split('\n');

  let depth = 0;
  let pending: string[] = [];
  let current: string[] = [];

  for (const line of lines) {
    const trimmed = line.trim();

    // At the member level, collect leading annotations.
    if (depth === 0 && current.length === 0) {
      if (trimmed === '' || trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('/*')) {
        continue;
      }
      if (trimmed.startsWith('@')) {
        pending.push(trimmed);
        continue;
      }
    }

    current.push(line);
    depth += netBraces(line);

    // A member ends when we are back to depth 0 and the line terminates a
    // declaration (`;`) or closes a block (`}`).
    if (depth <= 0 && (trimmed.endsWith(';') || trimmed.endsWith('}'))) {
      members.push({
        annotations: pending,
        text: current.join('\n'),
        firstLine: current.map(l => l.trim()).find(l => l !== '' && !l.startsWith('@')) ?? '',
      });
      pending = [];
      current = [];
      depth = 0;
    }
  }

  return members;
}

/** Returns true if the member's first line is the default (generative) constructor. */
function isDefaultConstructor(className: string, firstLine: string): boolean {
  // e.g. "User({" or "User(this.x)" — but not "User.fromJson(" or "factory User("
  return new RegExp(`^${className}\\s*\\(`).test(firstLine);
}

/** Interprets a member as a data field, or returns null if it is not one. */
function asField(m: ClassMember): DartField | null {
  const decl = m.firstLine;

  // Reject getters/setters, methods, expression bodies, statics, multi-line bodies.
  if (
    /\bget\s+\w+/.test(decl) ||
    /\bset\s+\w+/.test(decl) ||
    /\bstatic\b/.test(decl) ||
    decl.includes('=>') ||
    decl.includes('(') ||
    m.text.includes('{')
  ) {
    return null;
  }

  // [late] [final/var/const] Type? name; (no initializer)
  const fieldMatch = decl.match(
    /^(?:late\s+)?(?:final\s+|var\s+|const\s+)?([\w<>?, ]+?)\s+(\w+)\s*;$/
  );
  if (!fieldMatch) { return null; }

  const rawType = fieldMatch[1].trim();
  const fieldName = fieldMatch[2];
  if (!rawType || rawType === 'final' || rawType === 'var' || rawType === 'const') {
    return null;
  }

  const isNullable = rawType.endsWith('?');
  const type = isNullable ? rawType.slice(0, -1).trim() : rawType;
  const annotations = [...m.annotations];

  return {
    name: fieldName,
    type,
    isNullable,
    rawLine: decl,
    annotations,
    hasColumnAnnotation: annotations.some(a => a.startsWith('@Column')),
    hasIdAnnotation: annotations.some(a => a.startsWith('@ID')),
  };
}

/**
 * Extracts parameter names from the default constructor.
 */
function extractConstructorParams(className: string, body: string): string[] {
  // Match: ClassName({...}) or ClassName(...) possibly multiline
  const ctorPattern = new RegExp(
    `(?<!\\.)\\b${className}\\s*\\(([\\s\\S]*?)\\)\\s*(?::|;|\\{|=>)`,
    'm'
  );
  const match = ctorPattern.exec(body);
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
    .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
    .toLowerCase();
}

/**
 * Pluralizes a snake_case table name  (e.g. "user" → "users", "category" → "categories")
 */
export function pluralize(word: string): string {
  if (word.endsWith('y') && !/[aeiou]y$/.test(word)) {
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
