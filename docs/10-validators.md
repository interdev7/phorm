# Validators

PHORM provides a declarative validation system that allows you to enforce data integrity both at the database level (SQL `CHECK` constraints) and the application level (Dart-side validation).

---

## Usage

Validators are defined using the `validators` parameter in the `@Column` annotation.

```dart
@Column(
  validators: [
    LengthValidator(min: 3, max: 50, constraint: 'email_length_check'),
    EmailValidator(constraint: 'email_format_check'),
    NotEmptyValidator(),
  ],
)
final String email;
```

When you call `toJson()` on a generated model mixin, PHORM automatically runs these validators. If any validator fails, an exception is thrown.

---

## Types of Validators

There are two primary interfaces for validators:

### 1. `ISqlValidator` (Database + Dart)

These validators enforce constraints in both the SQL schema and Dart.

- **SQL**: The generator adds `CHECK` constraints to the `CREATE TABLE` statement.
- **Dart**: The generated `toJson()` method verifies the value before it's sent to the database.

**Built-in `ISqlValidator`s:**
| Validator | Description | SQL generated |
| :--- | :--- | :--- |
| `NotEmptyValidator()` | Ensures the string is not empty. | `col <> ''` |
| `LengthValidator(min, max)` | Checks string length. | `LENGTH(col) BETWEEN min AND max` |
| `ContainsValidator([values])` | Ensures value is in a list. | `col IN ('A', 'B')` |
| `CustomSqlValidator(sql)` | Injects raw SQL `CHECK` condition. | _(your expression)_ |

### 2. `IJsonValidator` (Dart Only)

These validators only run in Dart and do not affect the SQL schema. Use them for logic that is difficult to express in pure SQL (e.g. Regex or URL parsing).

**Built-in `IJsonValidator`s:**
| Validator | Description |
| :--- | :--- |
| `EmailValidator()` | Validates email format using Regex. |
| `RegExpValidator(pattern)` | Validates against a custom Regular Expression. |

---

## CHECK Constraint Generation

Each `ISqlValidator` with a `constraint` name generates its own **named** `CONSTRAINT`:

```sql
-- For: LengthValidator(min: 3, max: 30, constraint: 'first_name_length_check')
first_name TEXT NOT NULL CONSTRAINT first_name_length_check CHECK(LENGTH(first_name) BETWEEN 3 AND 30)

-- For: NotEmptyValidator() (no constraint name → combined into anonymous CHECK)
CHECK(first_name <> '')
```

Validators **without** a `constraint` name are combined into a single anonymous `CHECK(...)`:

```sql
-- Two anonymous validators → CHECK(expr1 AND expr2)
some_col TEXT CHECK((some_col > 0) AND (some_col < 100))
```

---

## Error Handling

When validation fails, PHORM throws:

- **`PhormJSONValidatorException`**: thrown when any validator (`ISqlValidator` or `IJsonValidator`) fails in the Dart-side `toJson()` check.

The exception carries the `table`, `column`, `constraint` name (if provided), and the invalid `value`.

```dart
try {
  final json = user.toJson();
} on PhormJSONValidatorException catch (e) {
  print('Failed: ${e.table}.${e.column} [${e.constraint}]');
  print('Value: ${e.message}');
}
```

---

## Configuration

You can disable Dart-side validation logic per schema:

```dart
@Schema(
  useValidator: false, // Default is true
)
class MyModel extends Model ...
```

> [!NOTE]
> Setting `useValidator: false` suppresses the generated `if (...) throw ...` checks in `toJson()`, but **does not** remove `CHECK` constraints from the SQL schema.

> [!TIP]
> If a model has no validators at all, the generator automatically omits the validator helper method and call — no manual configuration needed.

---

## Custom Validators

### Custom Dart Validator (`IJsonValidator`)

```dart
class MyPasswordValidator implements IJsonValidator {
  @override
  final String? constraint = 'password_complexity';

  const MyPasswordValidator();

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    final s = value.toString();
    return s.contains(RegExp(r'[A-Z]')) && s.length > 8;
  }
}
```

### Custom SQL + Dart Validator (`ISqlValidator`)

> [!IMPORTANT]
> The `sql` property **MUST be a `final String sql` field**, not a computed getter.
> This is required for the code generator to read it via Dart's constant evaluation at build time.

```dart
// ✅ CORRECT — final field, readable at build time
class IsEvenValidator implements ISqlValidator {
  @override
  final String? constraint;

  @override
  final String sql; // must be a final field!

  const IsEvenValidator({this.constraint}) : sql = '{column} % 2 = 0';

  @override
  String toSql(String columnName) => sql.replaceAll('{column}', columnName);

  @override
  bool isValid(dynamic value) => value is int && value % 2 == 0;
}
```

For **parameterized** validators, use ternary operators in the initializer list (they are valid `const` expressions in Dart):

```dart
// ✅ CORRECT — ternary in initializer list is a const expression
class RangeValidator implements ISqlValidator {
  final num min;
  final num max;

  @override
  final String? constraint;

  @override
  final String sql;

  const RangeValidator(this.min, this.max, {this.constraint})
      : sql = '{column} BETWEEN $min AND $max';

  @override
  String toSql(String columnName) => sql.replaceAll('{column}', columnName);

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    final n = num.tryParse(value.toString());
    return n != null && n >= min && n <= max;
  }
}
```

> [!WARNING]
> **Computed getters are not supported for SQL generation.**
> If `sql` is a computed getter (using `if`/`else`, method calls, etc.), the generator **cannot** read it and will skip the `CHECK` constraint for that validator.
>
> ```dart
> // ❌ WRONG — computed getter, no CHECK will be generated
> @override
> String get sql {
>   if (min != null && max != null) return 'LENGTH({column}) BETWEEN $min AND $max';
>   return '';
> }
> ```

### Validators with `IN (...)` lists (`ContainsValidator`)

For validators that check membership in a list of values, the generator automatically reads the `values` field and builds the `IN (...)` clause — even if `sql` cannot be expressed as a const field:

```dart
class ContainsValidator implements ISqlValidator, IJsonValidator {
  final List<dynamic> values;

  @override
  final String? constraint;

  // sql getter is computed at runtime from values,
  // but the generator falls back to reading the `values` field directly.
  @override
  String get sql {
    final formatted = values.map((v) => v is String ? "'$v'" : '$v').join(', ');
    return '{column} IN ($formatted)';
  }

  const ContainsValidator(this.values, {this.constraint});

  @override
  String toSql(String columnName) => sql.replaceAll('{column}', columnName);

  @override
  bool isValid(dynamic value) => values.contains(value);
}
```

The generator produces: `CONSTRAINT gender_check CHECK(gender IN ('M', 'F', 'Other'))`.
