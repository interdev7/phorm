# Validators

SQFlow provides a declarative validation system that allows you to enforce data integrity both at the database level (SQLite `CHECK` constraints) and the application level (Dart-side validation).

---

## Usage

Validators are defined using the `validators` parameter in the `@Column` annotation.

```dart
@Column(
  validators: [
    NotEmptyValidator(),
    LengthValidator(min: 3, max: 50),
    EmailValidator(constraint: 'email_format_check'),
  ],
)
final String email;
```

When you call `toJson()` on a generated model mixin, SQFlow automatically runs these validators. If any validator fails, an exception is thrown.

---

## Types of Validators

There are two primary interfaces for validators:

### 1. `ICheckValidator` (Database + Dart)
These validators enforce constraints in both SQLite and Dart.
- **SQL**: The generator adds a `CHECK (column_name ...)` constraint to the `CREATE TABLE` statement.
- **Dart**: The generated `toJson()` method verifies the value before it's sent to the database.

**Built-in `ICheckValidator`s:**
| Validator | Description | SQL Example |
| :--- | :--- | :--- |
| `NotEmptyValidator()` | Ensures the string is not empty. | `col <> ""` |
| `LengthValidator(min, max)` | Checks string length. | `LENGTH(col) BETWEEN min AND max` |
| `RangeValidator(min, max)` | Checks numeric range. | `col BETWEEN min AND max` |
| `ComparisonValidator(val, op)` | Compares value using `>`, `<`, `>=`, `<=`, `=`, `!=`. | `col > 10` |
| `ContainsValidator([values])` | Ensures value is in a list (Enum-like). | `col IN ('A', 'B')` |
| `NotContainsValidator(inner)` | Negates another `ICheckValidator`. | `NOT (col IN ('A'))` |
| `CustomSqlValidator(sql)` | Injects raw SQL `CHECK` condition. | `col % 2 = 0` |

### 2. `IJsonValidator` (Dart Only)
These validators only run in Dart and do not affect the SQLite schema. They are useful for complex logic that is difficult or impossible to express in pure SQL (like Regex or URL parsing).

**Built-in `IJsonValidator`s:**
| Validator | Description |
| :--- | :--- |
| `EmailValidator()` | Validates email format using Regex. |
| `RegExpValidator(pattern)` | Validates against a custom Regular Expression. |
| `URLValidator()` | Validates string as a valid URI. |

---

## Error Handling

When validation fails, SQFlow throws one of the following exceptions:

- **`SqflowCHECKValidatorException`**: Thrown when an `ICheckValidator` fails.
- **`SqflowJSONValidatorException`**: Thrown when an `IJsonValidator` fails.

Both exceptions contain the `constraint` name (if provided) and the invalid `value`.

```dart
try {
  final json = user.toJson();
} on SqflowCHECKValidatorException catch (e) {
  print('Validation failed for constraint: ${e.constraint}');
  print('Invalid value: ${e.value}');
}
```

---

## Configuration

You can disable the generation of validation logic globally or per-schema:

```dart
@Schema(
  useValidator: false, // Default is true
)
class MyModel extends Model ...
```

If `useValidator` is `false`, the generator will still add `CHECK` constraints to the SQL schema, but will not include the `if (...) throw ...` checks in the `toJson()` method.

> [!TIP]
> **Dynamic Code Optimization:** You don't need to manually configure `useValidator: false` if your model has no validators declared on its fields. The generator dynamically detects the presence of validators and automatically omits the validator helper method and call if none are found.

---

## Custom Validators

You can create your own validators by implementing `IJsonValidator` or `ICheckValidator`.

### Custom Dart Validator
```dart
class MyPasswordValidator implements IJsonValidator {
  @override
  final String? constraint = 'password_complexity';

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    final s = value.toString();
    return s.contains(RegExp(r'[A-Z]')) && s.length > 8;
  }
}
```

### Custom SQL + Dart Validator
```dart
class IsEvenValidator implements ICheckValidator {
  @override
  final String? constraint = 'must_be_even';

  @override
  String toSql(String columnName) => '$columnName % 2 = 0';

  @override
  bool isValid(dynamic value) => value is int && value % 2 == 0;
}
```
