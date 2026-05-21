# Known Limitations & Pitfalls

This page documents the known limitations, gotchas, and design trade-offs in SQFlow. Understanding these will help you avoid surprises in production.

---

## Query Builder

### `eq()` and `ne()` silently skip `null`

```dart
String? filter = null;
WhereBuilder().eq('status', filter); // No condition added!
```

This is intentional for convenient optional filter patterns. If you need to match `NULL` explicitly, use `.isNull('column')`.

---

### `inList()` with empty list → always false

```dart
WhereBuilder().inList('status', []); // Produces: 1 = 0
```

This is a safe default — an empty `IN ()` is invalid SQL. But it means **zero records are returned** when you pass an empty filter list. Guard it:

```dart
// Use the extension method instead
WhereBuilder().inListIfNotEmpty('status', statusList);
```

---

### `notInList()` with empty list → no condition

```dart
WhereBuilder().notInList('id', []); // No condition added — all records match
```

This is asymmetric behavior compared to `inList`. Intentional for safety (excluding nothing = no restriction).

---

### Dot-notation column names require registered relationships

```dart
// Silently produces broken SQL if 'comments' is not in relationships[]
WhereBuilder().eq('comments.status', 'approved');
```

No error is thrown at build time. The generated SQL will reference a table that was not joined, causing a SQLite "no such column" error at runtime.

### Custom SQL Functions & `regexp()` Setup

The `REGEXP` operator (and other custom SQL functions) is **not available** in standard `sqlite3` builds by default. Using `.regexp()` or custom functions without setup will throw a `DatabaseException` at runtime.

However, SQFlow provides an elegant built-in way to register custom SQL functions and regular expressions via the `SqlFunction` utility.

#### How to configure:
1. Provide `customFunctions` when initializing your `DB` manager:
```dart
final db = DB(
  databaseName: 'app.db',
  version: 1,
  tables: [usersTable],
  customFunctions: [
    SqlFunction.regexp(), // Registers the standard REGEXP function
    SqlFunction.custom(
      name: 'DOUBLE',
      argumentCount: 1,
      function: (args) {
        if (args[0] == null) return null;
        return (args[0] as int) * 2;
      },
    ),
  ],
);
```

2. Once registered, these functions are fully available inside isolate database sessions, custom raw queries, and `WhereBuilder` clauses:
```dart
// 1. Using built-in regexp helper
final users = await userService.readAll(
  where: WhereBuilder().regexp('email', r'.*@gmail\.com'),
);

// 2. Using custom functions via safe raw queries
final olderUsers = await userService.readAll(
  where: WhereBuilder().raw('DOUBLE(age) > ?', [50]),
);
```

---

### `SortBuilder` requires joined tables for dot notation

```dart
SortBuilder().asc('orders.created_at'); 
```

While `SortBuilder` supports dot notation, the query will fail at runtime if the `orders` table is not joined. Joins are automatically triggered by adding a condition on the related table in `WhereBuilder`.

---

## CRUD Operations

### `upsert` deletes and re-inserts rows

SQLite's `INSERT OR REPLACE` deletes the existing row and inserts a new one when there's a conflict. This means:
- The internal `rowid` changes.
- `ON DELETE CASCADE` foreign key constraints may trigger.
- Any columns not present in `toJson()` are lost.

Use `update` for partial updates.

---

### `insertBatch` uses `ConflictAlgorithm.replace`

The batch insert silently replaces existing rows with the same primary key. This may be surprising if you expect duplicate key errors.

---

### Transactions require passing the `executor`

```dart
// WRONG — operations inside transaction() must use the txn object
await db.transaction((txn) async {
  await userService.insert(user); // ← This uses the global connection, NOT txn!
});

// CORRECT — pass the txn as executor
await db.transaction((txn) async {
  await userService.insert(user, executor: txn);
});
```

---

### Timestamps are always UTC

`DateTime.now().toIso8601String()` produces a local time string without timezone info. If your app uses multiple timezones, consider using `DateTime.now().toUtc().toIso8601String()` in your models manually, since SQFlow injects `DateTime.now()` directly.

---

## Relationships

### Soft-deleted related records are included in `include`

When using eager loading (`include`), the generated subquery does NOT filter by `deleted_at`. If your related records use soft deletes, deleted ones will appear in the `HasMany` list.

**Workaround:** Filter them out in Dart after fetching:
```dart
user.orders.where((o) => o.deletedAt == null).toList()
```

---

### `Includable.model<T>()` resolution

The generator sets up the model-to-table mapping automatically. Only a concern when creating `Table` manually.

---

### `HasMany` performance on large datasets

JSON aggregation with `json_group_array` builds the entire related collection in-memory within SQLite. For large `HasMany` relationships (thousands of rows), consider:
1. Using `Attributes.include(...)` on the relationship to limit columns.
2. Paginating the related records with a separate query.
3. Loading related data separately instead of using `include`.

---

### `GROUP BY` changes aggregation behavior

When cross-table filtering generates a `LEFT JOIN`, `GROUP BY users.id` is automatically added. This means `COUNT(*) OVER()` (used by `readAllWithCount`) counts **distinct primary keys**, not raw rows. This is the desired behavior, but be aware of it if you're using custom aggregation via `.raw()`.

---

## Schema & Generation

### `Table.columns` must match actual SQL columns

`Attributes.include(['col1', 'col2'])` applies against `table.columns`. If you pass a column name that's not in that list, it will simply not appear in the query (no error). The generator populates `table.columns` automatically. If you create `Table` manually, you must provide it correctly.

---

### `timestamps: true` does not add Dart fields

The generator adds `created_at`, `updated_at` to the SQL schema when `timestamps: true`, but does **NOT** generate Dart fields for them automatically. Declare them manually if you need to read them in your code.

---

### `paranoid: true` requires `deleted_at` in schema

If you set `paranoid: true` but your `CREATE TABLE` SQL doesn't have a `deleted_at TEXT` column, soft delete operations (`delete`, `readAll` filter) will fail silently or throw a database error.

The generator adds this automatically. Only a concern when creating `Table` manually.

---

## DB & Migrations

### Downgrade destroys all data

Decreasing `DB.version` below the file version triggers `onDowngrade`, which **deletes and recreates** the entire database. This is irreversible.

---

### Modifying a migration re-applies it

Migration idempotency is based on a hash of `{table, version, description, priority}`. If you change the `description` of an existing migration, the hash changes and it will be re-applied. If the migration is `ALTER TABLE ADD COLUMN` and the column already exists, this will throw a `DatabaseException`.

---

### `autoVersion` minimum is `1`

Even if no migrations are defined, `DB.autoVersion` returns version `1` as the minimum. This is by design.

---

## Testing

### Use `:memory:` for test isolation

```dart
setUp(() {
  db = DB(databaseName: ':memory:', version: 1, tables: [usersTable]);
  userService = SqflowCore<User>(dbManager: db, table: usersTable);
});

tearDown(() async {
  await db.close();
});
```

In-memory databases are destroyed when closed, ensuring test isolation.

---

### `@visibleForTesting` on `buildJoinQuery`

`SqflowCore.buildJoinQuery` is exposed with `@visibleForTesting` to allow unit testing of the SQL generation logic. It is not part of the public API and may change without notice.
---

## SQL Dialect & Database Specifics

### Pluggable Dialect Differences

Because SQFlow compiles queries dynamically using the `SqlDialect` defined by the driver, minor syntax differences exist when executing raw SQL queries (`db.rawQuery()` or `WhereBuilder().raw()`) across different database drivers:

- **Placeholders**: SQLite (`sqflow_lite`) utilizes standard `?` positional parameters. PostgreSQL (`sqflow_postgres`) uses `$1`, `$2` positional arguments.
- **Identifiers**: Avoid hardcoded identifier escapes (backticks or double quotes) inside raw strings where possible. Let `SqlDialect.escapeIdentifier` handle it programmatically, or use the generated table/column attributes.

---

### SQLite Specifics (`sqflow_lite`)

#### SQLite is weakly typed

Unlike other relational databases (like PostgreSQL or MySQL) which fail fast on mismatched types, SQLite does **not** strictly enforce column types. You can technically insert a string into an integer column without database-level errors.

**Recommendation:** Always perform validation at the application layer using `sqflow_generator`'s built-in validators or custom logic in `fromJson`.

#### Booleans are stored as Integers

SQLite does not have a native `BOOLEAN` type. SQFlow stores them as `1` (true) and `0` (false) on disk. The generator automatically handles the boolean conversion in `toJson` and `fromJson`, but if you are writing raw SQLite queries, you must filter using `1` and `0`.

> [!NOTE]
> Future drivers like `sqflow_postgres` will map Booleans directly to PostgreSQL's native `boolean` type, handled transparently by its custom dialect.
