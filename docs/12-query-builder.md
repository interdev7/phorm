# Query Builder (Fluent API)

SQFlow provides a fluent, type-safe query builder that allows you to chain conditions, sorting, and pagination in a readable way. This is the recommended way to perform read operations.

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

| Feature | Fluent API (`Users.query...`) | Method API (`userService.readAll(...)`) |
| :--- | :--- | :--- |
| **Readability** | ✅ High (chains) | ⚠️ Moderate (many parameters) |
| **Type Safety** | ✅ Full | ✅ Full |
| **Total Count** | ❌ Not supported | ✅ Supported via `readAllWithCount` |
| **Complexity** | Best for simple to moderate queries | Best for advanced pagination with total count |

> [!TIP]
> Use the **Fluent API** for most of your application logic as it is much more expressive. Use `readAllWithCount` only when you explicitly need the total number of matching rows for a pagination UI.
