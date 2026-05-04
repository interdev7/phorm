# WhereBuilder — Query Filtering

`WhereBuilder` is a fluent, SQL-injection safe builder for `WHERE` clauses. All values are passed as `?` placeholders — never interpolated into the SQL string directly.

---

## Basic Usage

```dart
final where = WhereBuilder()
  .eq('status', 'active')
  .gt('age', 18)
  .like('name', 'John%');

// Produces: status = ? AND age > ? AND name LIKE ?
// Args:     ['active', 18, 'John%']
```

All conditions are joined by `AND` by default. To use `OR` as the default separator:

```dart
final where = WhereBuilder(separator: ' OR ');
```

---

## Method Reference

### Comparison Operators

| Method | SQL | Note |
| :--- | :--- | :--- |
| `.eq('col', val)` | `col = ?` | Skipped silently if `val` is `null` |
| `.ne('col', val)` | `col != ?` | Skipped silently if `val` is `null` |
| `.gt('col', val)` | `col > ?` | |
| `.gte('col', val)` | `col >= ?` | |
| `.lt('col', val)` | `col < ?` | |
| `.lte('col', val)` | `col <= ?` | |

```dart
WhereBuilder()
  .eq('status', 'active')    // status = ?
  .ne('role', 'banned')      // role != ?
  .gt('age', 18)             // age > ?
  .lte('price', 99.99);      // price <= ?
```

> [!NOTE]
> `.eq()` and `.ne()` silently skip the condition when `value == null`. This is intentional for optional filter patterns. `.gt()`, `.gte()`, `.lt()`, `.lte()` do NOT accept null.

---

### Pattern Matching

| Method | SQL | Case sensitive |
| :--- | :--- | :--- |
| `.like('col', pattern)` | `col LIKE ?` | ✅ Yes |
| `.notLike('col', pattern)` | `col NOT LIKE ?` | ✅ Yes |
| `.ilike('col', pattern)` | `LOWER(col) LIKE LOWER(?)` | ❌ No |
| `.notIlike('col', pattern)` | `LOWER(col) NOT LIKE LOWER(?)` | ❌ No |
| `.regexp('col', pattern)` | `col REGEXP ?` | depends on SQLite config |

```dart
WhereBuilder()
  .like('name', 'John%')         // Starts with 'John'
  .like('email', '%@gmail.com')  // Ends with domain
  .ilike('city', '%sofia%')      // Case-insensitive contains
  .regexp('phone', '^[0-9]+$');  // Numbers only
```

> [!WARNING]
> `REGEXP` requires SQLite to have a regexp function registered. In standard `sqflite`, this is **not available** by default. Use `.like()` or `.raw()` for pattern matching without external plugins.

---

### NULL Checks

```dart
WhereBuilder()
  .isNull('deleted_at')     // deleted_at IS NULL
  .isNotNull('email');      // email IS NOT NULL
```

---

### Boolean Checks

SQLite stores booleans as `1` (true) or `0` (false).

```dart
WhereBuilder()
  .isTrue('is_active')      // is_active = 1
  .isFalse('is_deleted');   // is_deleted = 0
```

---

### Range & Set Operations

```dart
// BETWEEN
WhereBuilder().between('age', 18, 65);
// Produces: age BETWEEN ? AND ?  Args: [18, 65]

// IN list
WhereBuilder().inList('status', ['active', 'pending']);
// Produces: status IN (?, ?)  Args: ['active', 'pending']

// NOT IN list
WhereBuilder().notInList('role', ['admin', 'superuser']);
// Produces: role NOT IN (?, ?)
```

> [!IMPORTANT]
> Calling `.inList()` with an **empty list** produces `1 = 0` (always false — matches nothing). Calling `.notInList()` with an **empty list** adds **no condition** (matches everything). This is deliberate behavior.

---

### Logical Groups (AND/OR Nesting)

```dart
// AND group
WhereBuilder()
  .eq('country', 'Bulgaria')
  .andGroup((g) {
    g.gt('age', 18).lt('age', 65);
  });
// Produces: country = ? AND (age > ? AND age < ?)
// Args: ['Bulgaria', 18, 65]   ← order is preserved!

// OR group
WhereBuilder()
  .isTrue('is_active')
  .orGroup((g) {
    g.eq('city', 'Sofia').eq('city', 'Plovdiv');
  });
// Produces: is_active = 1 AND (city = ? OR city = ?)
// Args: ['Sofia', 'Plovdiv']
```

> [!NOTE]
> Arguments are collected in the **exact order conditions are added**, including inside nested groups. This means the `args` list always matches the `?` placeholders in the built SQL.

---

### Date/Time Operations

Dates in SQFlow are stored as ISO-8601 strings. These helpers extract the date or time part for comparison.

```dart
// Date-only equality (ignores time)
WhereBuilder().dateOnlyEq('created_at', DateTime(2024, 1, 15));
// Produces: DATE(created_at) = ?  Args: ['2024-01-15']

// Date range
WhereBuilder().dateOnlyBetween(
  'created_at',
  DateTime(2024, 1, 1),
  DateTime(2024, 12, 31),
);
// Produces: DATE(created_at) BETWEEN ? AND ?

// Date comparisons
WhereBuilder()
  .dateOnlyGt('birth_date', DateTime(2000, 1, 1))  // DATE(col) > ?
  .dateOnlyLt('expiry_date', DateTime(2025, 12, 31)); // DATE(col) < ?

// Time-only equality
WhereBuilder().timeOnlyEq('start_time', DateTime(2024, 1, 1, 9, 0));
// Produces: TIME(start_time) = ?  Args: ['09:00:00']
```

---

### String Function Helpers (LENGTH, SUBSTR)

```dart
// LENGTH comparisons
WhereBuilder()
  .lengthEq('first_name', 5)   // LENGTH(first_name) = ?
  .lengthNe('code', 6)         // LENGTH(code) != ?
  .lengthGt('nickname', 2)     // LENGTH(nickname) > ?
  .lengthGte('password', 8)    // LENGTH(password) >= ?
  .lengthLt('slug', 100)       // LENGTH(slug) < ?
  .lengthLte('bio', 500);      // LENGTH(bio) <= ?

// SUBSTR comparisons (start, len, value)
WhereBuilder()
  .substrEq('last_name', 1, 1, 'S')       // SUBSTR(last_name, ?, ?) = ?
  .substrLike('email', 1, 3, 'adm%')      // SUBSTR(email, ?, ?) LIKE ?
  .substrIlike('first_name', 1, 2, 'jo'); // LOWER(SUBSTR(...)) LIKE LOWER(?)
```

---

### Cross-Table Filtering (Dot Notation)

When a filter references a related table column, SQFlow **automatically generates a `LEFT JOIN`**. No manual configuration needed.

```dart
// Find users who have posts with 'Dart' in the title
final result = await userService.readAll(
  where: WhereBuilder().like('posts.title', '%Dart%'),
);
```

Behind the scenes:
```sql
SELECT users.* FROM users
LEFT JOIN posts ON posts.user_id = users.id
WHERE posts.title LIKE ?
GROUP BY users.id   -- Prevents duplicates from HasMany JOINs
```

> [!IMPORTANT]
> **Automatic JOIN requirements:**
> 1. The dot-notation column must reference a table that is in the `relationships` list of the model's `@Schema`.
> 2. The related table must be registered in `DB(tables: [...])`.
> 3. `GROUP BY` is automatically added on the primary table's key to prevent row duplication.

---

### Raw SQL (Escape Hatch)

For complex cases not covered by the builder.

```dart
WhereBuilder().raw('LENGTH(name) > ?', [3]);
WhereBuilder().raw('julianday("now") - julianday(created_at) > ?', [30]);
```

> [!CAUTION]
> The placeholder count (`?`) must **exactly match** the number of arguments. SQFlow validates this and throws `ArgumentError` if they don't match. Never interpolate user input into raw conditions.

---

## Extension Methods (Conditional Helpers)

Useful for search forms where filters are optional.

```dart
// Only adds condition if value is not null and not empty
WhereBuilder().eqIfNotNull('city', selectedCity);

// Only adds IN condition if list has items
WhereBuilder().inListIfNotEmpty('category', selectedCategories);

// Smart date range — handles one-sided or both-sided ranges
WhereBuilder().dateRangeIfProvided('created_at', startDate, endDate);
// If both: BETWEEN ? AND ?
// If only from: >= ?
// If only to: <= ?
// If neither: no condition added
```

---

## Factory Helpers (`WhereBuilders` class)

```dart
// Soft-delete aware clause
final where = WhereBuilders.softDelete(
  paranoid: true,
  withDeleted: false,   // Exclude deleted records
  onlyDeleted: false,   // Fetch only deleted records
);
// When paranoid=true, withDeleted=false, onlyDeleted=false:
// Produces: deleted_at IS NULL

// Multi-column text search
final where = WhereBuilders.multiColumnSearch(
  'john',
  ['first_name', 'last_name', 'email'],
  caseSensitive: false,
);
// Produces: (LOWER(first_name) LIKE LOWER(?) OR LOWER(last_name) LIKE LOWER(?) OR LOWER(email) LIKE LOWER(?))
// Args: ['%john%', '%john%', '%john%']
```

---

## Utility Methods

```dart
final where = WhereBuilder().eq('status', 'active').gt('age', 18);

// Get the built SQL string
where.build(); // "status = ? AND age > ?"

// Get all args in order
where.args; // ['active', 18]

// Check if a column is referenced
where.hasConditionOn('status'); // true
where.hasConditionOn('email');  // false

// Get all referenced columns
where.usedColumns; // {'status', 'age'}

// Check if empty
where.isEmpty;    // false
where.isNotEmpty; // true

// Deep copy (does NOT share internal state)
final copy = where.copy();
// Alias:
final clone = where.clone();

// Debug print (development only)
where.debugPrint();
// WhereBuilder:
//   Separator: " AND "
//   Conditions: 2
//   Used columns: {status, age}
//   Built SQL: "status = ? AND age > ?"
//   Args: ['active', 18]
```

---

## Common Pitfalls

### 1. `eq()` with null silently skips

```dart
String? filter = null;
WhereBuilder().eq('status', filter); // ← No condition added!
```

If you want null to match `IS NULL`, use `.isNull()` explicitly.

### 2. Column names with spaces or special characters

```dart
WhereBuilder().eq('first name', 'John'); // ← Throws ArgumentError!
WhereBuilder().eq('first_name', 'John'); // ✅ OK
```

Only letters, numbers, underscores, and dots (for cross-table) are allowed.

### 3. Dot-notation without a registered relationship

```dart
// This will NOT generate a JOIN if 'comments' is not in relationships[]
WhereBuilder().eq('comments.status', 'approved');
```

No error is thrown, but the `comments.status` column will not resolve correctly. Always define relationships in `@Schema`.

### 4. `GROUP BY` side effect with cross-table filtering

When a dot-notation filter is used, `GROUP BY` is added automatically. This means:
- `SELECT COUNT(*)` columns in your query may behave differently.
- Any aggregation in `readAll` is on the grouped (deduplicated) result.
