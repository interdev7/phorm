# Query Builder (Fluent API)

PHORM provides a fluent, type-safe query builder that allows you to chain conditions, sorting, and pagination in a readable way. This is the recommended way to perform read operations.

---

## Starting a Query

You can start a query from any pluralized service class (e.g., `Users`, `Posts`).

### `.query`

Returns an empty query builder.

```dart
final allUsers = await Users.query.get();
```

### `.where(condition)`

Starts a query with an initial condition.

```dart
final activeUsers = await Users.where(Users.isActive.eq(true)).get();
```

---

## Chaining Methods

The query builder allows chaining multiple methods. Each method returns the query builder instance (`this`).

### `.where(condition)`

Adds a filter condition. You can call it multiple times; conditions are joined with `AND`.

```dart
final result = await Users.query
    .where(Users.city.eq('Sofia'))
    .where(Users.age.gt(18))
    .get();
```

### Combining conditions with `&` and `|`

Typed conditions compose into AND/OR groups directly — no need to drop down
to `WhereBuilder` for OR logic:

```dart
// WHERE age > ? AND (city = ? OR city = ?)
final result = await Users.query
    .where(Users.age.gt(18) & (Users.city.eq('Sofia') | Users.city.eq('Plovdiv')))
    .get();
```

Groups nest freely and consecutive same-operator combinations flatten into a
single group. Dart's operator precedence (`&` binds tighter than `|`) matches
SQL's `AND`/`OR`, but parenthesize mixed expressions for readability.

### `.whereIf(flag, conditionBuilder)`

Adds a filter condition only if the provided boolean `flag` is true. This helps avoid complex conditional blocks when constructing dynamic filters.

```dart
final result = await Users.query
    .whereIf(onlyActive, () => Users.isActive.isTrue())
    .get();
```

### `.whereNotNull(value, conditionBuilder)`

Adds a filter condition only if the provided `value` is not null. Extremely useful for handling optional query parameters or search filters.

```dart
final result = await Users.query
    .whereNotNull(searchQuery, (val) => Users.name.like('%$val%'))
    .get();
```

### `.orderBy(column, {bool descending = false})`

Adds an `ORDER BY` clause.

```dart
final latestPosts = await Posts.query
    .orderBy(Posts.createdAt, descending: true)
    .get();
```

### `.limit(count)` and `.offset(count)`

Control pagination.

```dart
final page2 = await Users.query
    .limit(10)
    .offset(10)
    .get();
```

> [!IMPORTANT]
> The default limit is **20 rows**. Use `.noLimit()` to fetch everything.

### `.after(lastModel)` — keyset (cursor) pagination

Returns rows strictly **after** the given model in the current `orderBy`
ordering. Unlike `offset`, a keyset page stays stable when rows are inserted
or deleted before it, and the database serves it from the index without
scanning skipped rows — ideal for infinite lists in Flutter.

```dart
final firstPage = await Users.query
    .orderBy(Users.createdAt, descending: true)
    .limit(20)
    .get();

final nextPage = await Users.query
    .orderBy(Users.createdAt, descending: true)
    .after(firstPage.last) // cursor = last model of the previous page
    .limit(20)
    .get();
```

The primary key is appended automatically as a tiebreaker (to both `ORDER BY`
and the cursor), so duplicate sort values and mixed ASC/DESC orderings are
handled correctly. Requires at least one `orderBy(...)` before it and non-null
values in the cursor model for every sort column.

### `.noLimit()`

Removes the default limit of 20 rows — the query returns all matches.

```dart
final everyone = await Users.query.noLimit().get();
```

### `.distinct()`

Deduplicates result rows (`SELECT DISTINCT`).

```dart
final cities = await Users.query.distinct().select([Users.city]).rows();
```

### `.select(columns)`

Selects only the given columns — a shorthand for
`.attributes(Attributes.include([...]))`. Accepts `PhormColumn`s or plain
names.

```dart
final names = await Users.query.select([Users.firstName, 'city']).get();
```

### `.groupBy(columns)` and `.having(condition)`

Groups rows (`GROUP BY`) with an optional typed `HAVING` condition. Grouped
rows are usually not full models — read them with [`.rows()`](#rows) instead
of `.get()`. An explicit `groupBy` replaces the automatic primary-key grouping
PHORM uses to deduplicate joined rows.

```dart
final perCity = await Users.query
    .where(Users.isActive.isTrue())
    .groupBy([Users.city])
    .having(Users.age.gt(30))
    .noLimit()
    .rows();
```

### `.include(List<Includable> relations)`

Eager-loads relationships.

```dart
final user = await Users.query
    .where(Users.id.eq('u1'))
    .include([Includable.model<Order>()])
    .first();
```

### `.attributes(Attributes attr)`

Selects specific columns to reduce memory usage.

```dart
final names = await Users.query
    .attributes(Attributes.include(['id', 'first_name']))
    .get();
```

### `.withDeleted()`

Includes soft-deleted records in the result (only works if `paranoid: true` is enabled in the schema).

```dart
final allIncludingDeleted = await Users.query.withDeleted().get();
```

---

## Executing the Query

There are two main methods to execute the query and fetch results.

### `.get()`

Executes the query and returns a **`List<T>`**. If no records match, it returns an empty list.

```dart
List<User> users = await Users.query.where(Users.age.gt(18)).get();
```

### `.first()`

Executes the query (automatically adding `LIMIT 1`) and returns the **first result** or **`null`** if no records match.

```dart
User? user = await Users.query.where(Users.email.eq('john@example.com')).first();
```

### `.rows()`

Executes the query and returns raw rows (`List<Map<String, Object?>>`) without
mapping them into models. Use it for `groupBy`/`having` and aggregate
selections, where result rows do not correspond to full models.

```dart
final perCity = await Users.query.groupBy([Users.city]).rows();
```

### `.count({Object? column})`

Executes the query and returns the **total count of rows** matching the filtering conditions.

```dart
int activeCount = await Users.query.where(Users.isActive.isTrue()).count();
```

### `.getWithCount()`

Executes the query with pagination and simultaneously returns the **current page of results** and the **total matching rows** (extremely useful for paginated lists).

```dart
ResultWithCount<User> result = await Users.query.where(Users.city.eq('Sofia')).limit(10).getWithCount();
print('Loaded ${result.data.length} of ${result.count}');
```

### Aggregations (`.sum()`, `.avg()`, `.min()`, `.max()`)

Executes the respective SQL aggregations directly on the database level for the specified column:

```dart
// Sum up column values
num totalAge = await Users.query.where(Users.city.eq('Sofia')).sum(Users.age);

// Calculate the average
num averageAge = await Users.query.where(Users.city.eq('Sofia')).avg(Users.age);

// Find minimum and maximum values
num minAge = await Users.query.where(Users.city.eq('Sofia')).min(Users.age);
num maxAge = await Users.query.where(Users.city.eq('Sofia')).max(Users.age);
```

---

## Example: Complex Query

```dart
final users = await Users.query
    .where(Users.isActive.isTrue())
    .where(Users.city.inList(['Sofia', 'Plovdiv']))
    .include([
      Includable.model<Post>(
        attributes: Attributes.include(['id', 'title']),
      ),
    ])
    .orderBy(Users.firstName)
    .limit(5)
    .get();
```

---

## Fluent API vs. Method-Based API

| Feature         | Fluent API (`Users.query...`)             | Method API (`userService.readAll(...)`)   |
| :-------------- | :---------------------------------------- | :---------------------------------------- |
| **Readability** | ✅ High (chains)                          | ⚠️ Moderate (many parameters)             |
| **Type Safety** | ✅ Full                                   | ✅ Full                                   |
| **Total Count** | ✅ Supported via `.getWithCount()`        | ✅ Supported via `readAllWithCount`       |
| **Aggregates**  | ✅ Supported (`.count()`, `.sum()`, etc.) | ✅ Supported (`.count()`, `.sum()`, etc.) |
| **Complexity**  | Best for almost all query scenarios       | Alternative fallback                      |

> [!TIP]
> Use the **Fluent API** for the primary business logic of your application—it is far more expressive, flexible, and fully supports retrieval, aggregation, and pagination.
