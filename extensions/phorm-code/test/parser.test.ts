import { describe, it, expect } from 'vitest';
import { parseFile, camelToSnake, pluralize } from '../src/parser';

describe('camelToSnake', () => {
  it('converts camelCase to snake_case', () => {
    expect(camelToSnake('firstName')).toBe('first_name');
    expect(camelToSnake('User')).toBe('user');
    expect(camelToSnake('isActive')).toBe('is_active');
  });
});

describe('pluralize', () => {
  it('handles regular plurals', () => {
    expect(pluralize('user')).toBe('users');
  });
  it('handles -y → -ies (consonant before y)', () => {
    expect(pluralize('category')).toBe('categories');
  });
  it('keeps vowel+y words', () => {
    expect(pluralize('day')).toBe('days');
  });
  it('handles sibilants', () => {
    expect(pluralize('box')).toBe('boxes');
    expect(pluralize('class')).toBe('classes');
  });
});

describe('parseFile', () => {
  it('finds plain classes and their fields', () => {
    const src = `class User {
  final String name;
  final String? email;

  User({required this.name, this.email});
}`;
    const parsed = parseFile(src, 'user');
    expect(parsed.classes).toHaveLength(1);
    const cls = parsed.classes[0];
    expect(cls.name).toBe('User');
    expect(cls.alreadyConverted).toBe(false);
    expect(cls.fields.map(f => f.name)).toEqual(['name', 'email']);
    expect(cls.fields[1].isNullable).toBe(true);
  });

  it('marks classes that already extend Model as converted', () => {
    const src = `class User extends Model with _$PhormUserMixin {
  final String name;
  User({required this.name});
}`;
    expect(parseFile(src, 'user').classes[0].alreadyConverted).toBe(true);
  });

  it('does not capture top-level code after the last class', () => {
    const src = `class User {
  final String name;
  User({required this.name});
}

void helper() {
  print('keep me');
}`;
    const parsed = parseFile(src, 'user');
    expect(parsed.classes).toHaveLength(1);
    // The helper function must NOT be part of the class text.
    expect(parsed.classes[0].fullText).not.toContain('helper');
    expect(parsed.classes[0].endIndex).toBeLessThan(src.indexOf('void helper'));
  });

  it('preserves top-level code between two classes', () => {
    const src = `class A {
  final int x;
  A({required this.x});
}

const answer = 42;

class B {
  final int y;
  B({required this.y});
}`;
    const parsed = parseFile(src, 'ab');
    expect(parsed.classes.map(c => c.name)).toEqual(['A', 'B']);
    expect(parsed.classes[0].fullText).not.toContain('answer');
    expect(parsed.classes[1].fullText).not.toContain('answer');
  });

  it('ignores getters, methods and static fields', () => {
    const src = `class User {
  final String name;
  static const table = 'users';
  String get display => name;
  int compute() {
    final int local = 1;
    return local;
  }

  User({required this.name});
}`;
    const cls = parseFile(src, 'user').classes[0];
    expect(cls.fields.map(f => f.name)).toEqual(['name']);
  });

  it('skips abstract classes and mixins', () => {
    const src = `abstract class Base {
  final int id;
}

mixin Helper {
  void doIt() {}
}`;
    expect(parseFile(src, 'base').classes).toHaveLength(0);
  });

  it('detects an existing fromJson factory', () => {
    const src = `class User {
  final String name;
  User({required this.name});
  factory User.fromJson(Map<String, dynamic> json) => User(name: json['name']);
}`;
    expect(parseFile(src, 'user').classes[0].hasFromJson).toBe(true);
  });

  it('handles braces inside string literals without losing the body', () => {
    const src = `class User {
  final String tpl;
  User({required this.tpl});
  String render() => "value: { not a brace }";
}

const after = 1;`;
    const parsed = parseFile(src, 'user');
    expect(parsed.classes).toHaveLength(1);
    expect(parsed.classes[0].fullText).not.toContain('after');
  });
});
