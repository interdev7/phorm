import { describe, it, expect } from 'vitest';
import { parseFile } from '../src/parser';
import { transformFile, TransformOptions } from '../src/transformer';

const defaults: TransformOptions = {
  generateFullService: true,
  timestamps: true,
  paranoid: false,
  addFromJson: true,
};

function convert(src: string, fileName = 'user', opts: TransformOptions = defaults): string {
  return transformFile(parseFile(src, fileName), opts);
}

describe('transformFile', () => {
  it('converts a plain class into a Phorm model', () => {
    const out = convert(`class User {
  final String name;
  User({required this.name});
}`);
    expect(out).toContain("import 'package:phorm/phorm.dart';");
    expect(out).toContain("part 'user.sql.g.dart';");
    expect(out).toContain("@Schema(tableName: 'users')");
    expect(out).toContain('class User extends Model with _$PhormUserMixin {');
    expect(out).toContain('@ID(autoIncrement: true)');
    expect(out).toContain('final int id;');
    expect(out).toContain('@Column()');
    expect(out).toContain('factory User.fromJson(');
  });

  it('does not duplicate an existing fromJson', () => {
    const out = convert(`class User {
  final String name;
  User({required this.name});
  factory User.fromJson(Map<String, dynamic> json) => User(name: json['name']);
}`);
    const count = out.split('fromJson').length - 1;
    // one in the existing factory declaration only (no generated one added)
    expect(out).not.toContain('_$PhormUserFromJson');
    expect(count).toBeGreaterThanOrEqual(1);
  });

  it('preserves top-level code after the class', () => {
    const out = convert(`class User {
  final String name;
  User({required this.name});
}

void helper() {
  print('keep me');
}`);
    expect(out).toContain('void helper()');
    expect(out).toContain("print('keep me')");
  });

  it('uses a String @ID for String id fields', () => {
    const out = convert(`class User {
  final String id;
  final String name;
  User({required this.id, required this.name});
}`);
    expect(out).toContain('@ID(autoIncrement: false, unique: true)');
  });

  it('emits non-default @Schema options from settings', () => {
    const out = convert(
      `class User {
  final String name;
  User({required this.name});
}`,
      'user',
      { generateFullService: false, timestamps: false, paranoid: true, addFromJson: false }
    );
    expect(out).toContain("@Schema(tableName: 'users', timestamps: false, paranoid: true, generateFullService: false)");
    expect(out).not.toContain('factory User.fromJson');
  });

  it('is idempotent for already-converted classes', () => {
    const src = `import 'package:phorm/phorm.dart';

part 'user.sql.g.dart';

@Schema(tableName: 'users')
class User extends Model with _$PhormUserMixin {
  @ID(autoIncrement: true)
  final int id;
  User({required this.id});
}`;
    expect(convert(src)).toBe(src);
  });
});
