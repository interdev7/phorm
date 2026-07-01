# Many-to-Many Relationships

A `ManyToMany` relationship represents a mapping where multiple records in one table can be associated with multiple records in another table. This is achieved through a **pivot table** (also known as a junction or join table).

---

## Defining Many-to-Many

To define a Many-to-Many relationship, you must specify the `pivotTable` and the keys that link the tables.

### Example: Users and Roles

A User can have many Roles, and a Role can be assigned to many Users.

#### 1. Define the Models

```dart
@Schema(
  tableName: 'users',
  relationships: [
    ManyToMany(
      model: Role,
      pivotTable: 'user_roles',
      foreignKey: 'user_id',    // Column in pivotTable pointing to THIS table (users)
      relatedKey: 'role_id',    // Column in pivotTable pointing to RELATED table (roles)
    ),
  ],
)
class User extends Model with _$PhormUserMixin {
  @ID()
  final String id;

  @Column()
  final String name;

  // ManyToMany returns a List of related objects
  final List<Role> roles;

  User({required this.id, required this.name, this.roles = const []});

  factory User.fromJson(Map<String, dynamic> json) => _$PhormUserFromJson(json);
}

@Schema(
  tableName: 'roles',
  relationships: [
    ManyToMany(
      model: User,
      pivotTable: 'user_roles',
      foreignKey: 'role_id',    // Column in pivotTable pointing to THIS table (roles)
      relatedKey: 'user_id',    // Column in pivotTable pointing to RELATED table (users)
    ),
  ],
)
class Role extends Model with _$PhormRoleMixin {
  @ID()
  final String id;

  @Column()
  final String title;

  final List<User> users;

  Role({required this.id, required this.title, this.users = const []});

  factory Role.fromJson(Map<String, dynamic> json) => _$PhormRoleFromJson(json);
}
```

---

## The Pivot Table

> [!IMPORTANT]
> **Manual Setup Required (by default)**: unless you opt in with `createPivot: true` (see below), `phorm_generator` does **not** automatically generate the SQL for the pivot table. In that case you must define it yourself in a migration or in the `schema` string of one of your models.

### Automatic Pivot Table (`createPivot`)

Set `createPivot: true` on the `ManyToMany` annotation to let `phorm_generator` emit the pivot table automatically:

```dart
ManyToMany(
  model: 'roles',
  pivotTable: 'user_roles',
  foreignKey: 'user_id',
  relatedKey: 'role_id',
  createPivot: true, // 👈 auto-create the pivot table
),
```

The generator appends a statement like this to the model's schema:

```sql
CREATE TABLE IF NOT EXISTS user_roles (
  user_id TEXT NOT NULL,   -- typed from the owning model's primary key
  role_id TEXT NOT NULL,   -- typed from the related model's primary key
  PRIMARY KEY (user_id, role_id)
);
```

Notes:

- Column types are inferred from each model's primary key type.
- By default it emits a **minimal** pivot: two FK columns plus a composite primary key, without `FOREIGN KEY (...) REFERENCES` constraints or timestamps. To add referential integrity, set `pivotForeignKeys: true` (see below). For timestamps, define the pivot manually instead.

#### Foreign key constraints (`pivotForeignKeys`)

Set `pivotForeignKeys: true` (together with `createPivot: true`) to also emit `FOREIGN KEY ... ON DELETE CASCADE` constraints on both pivot columns:

```dart
ManyToMany(
  model: 'roles',
  pivotTable: 'user_roles',
  foreignKey: 'user_id',
  relatedKey: 'role_id',
  createPivot: true,
  pivotForeignKeys: true, // 👈 add FK constraints
),
```

Generates:

```sql
CREATE TABLE IF NOT EXISTS user_roles (
  user_id TEXT NOT NULL,
  role_id TEXT NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);
```

- `user_id` references the owning model's `localKey`; `role_id` references the related model's `relatedLocalKey`.
- Both use `ON DELETE CASCADE`, so deleting a user or role automatically removes its pivot rows. PHORM enables `PRAGMA foreign_keys = ON`, so the constraints are enforced.
- **Insert order matters**: the referenced parent rows (user/role) must exist before inserting the pivot row.
- **Cannot be retrofitted**: SQLite can't add foreign keys to an existing table. Enabling `pivotForeignKeys` on a pivot that was already created without them requires a manual table-recreation migration — bumping the DB version alone won't add the constraints.
- `CREATE TABLE IF NOT EXISTS` is used, so declaring `createPivot: true` on both sides of the relationship is safe (no duplicate-table error).
- The pivot is created both on initial database creation **and** on upgrade — if you add `createPivot: true` to an existing model and bump the DB version, the pivot is created during the upgrade.

### Recommended Pivot Table Schema (manual)

It is best practice to define a composite primary key and foreign key constraints on the pivot table.

```sql
CREATE TABLE user_roles (
  user_id TEXT NOT NULL,
  role_id TEXT NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);
```

You can add this to your `DB` initialization via a migration:

```dart
final usersTable = Table<User>(...).migrate()
  .custom(
    description: 'Create user_roles pivot table',
    version: 1,
    migrate: (executor, table) async {
      await executor.execute('''
        CREATE TABLE user_roles (
          user_id TEXT NOT NULL,
          role_id TEXT NOT NULL,
          PRIMARY KEY (user_id, role_id),
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
        )
      ''');
    },
  ).build();
```

---

## Eager Loading (Include)

To load the related data, use `Includable.model<T>()`.

```dart
// Fetch user with their roles
final user = await Users.query
    .where(Users.id.eq('u1'))
    .include([Includable.model<Role>()])
    .first();

print(user?.roles.map((r) => r.title));
```

### Deep Loading

You can also load relationships of the related models.

```dart
// Fetch user -> roles -> permissions
final user = await Users.readOne('u1', include: [
  Includable.model<Role>(include: [
    Includable.model<Permission>(),
  ]),
]);
```

---

## Filtering by Many-to-Many

You can filter records based on columns in the related table using dot notation. PHORM will automatically generate a `LEFT JOIN` through the pivot table.

```dart
// Find all users who have the 'Admin' role
final admins = await Users.where(
  const PhormColumn<String>('roles.title').eq('Admin')
).get();
```

**Generated SQL:**

```sql
SELECT users.*
FROM users
LEFT JOIN user_roles ON user_roles.user_id = users.id
LEFT JOIN roles ON roles.id = user_roles.role_id
WHERE roles.title = 'Admin'
GROUP BY users.id
```

---

## How It Works (JSON Aggregation)

When you include a `ManyToMany` relationship, PHORM performs a correlated subquery using `json_group_array` and `json_object`.

```sql
SELECT
  users.*,
  (SELECT json_group_array(json_object('id', roles.id, 'title', roles.title))
   FROM roles
   INNER JOIN user_roles ON user_roles.role_id = roles.id
   WHERE user_roles.user_id = users.id) AS roles
FROM users
```

This approach allows fetching all many-to-many relationships in a **single query**, regardless of how many records or relationships are involved.

---

## Parameters Reference

| Parameter         | Type               | Required | Description                                                        |
| :---------------- | :----------------- | :------- | :----------------------------------------------------------------- |
| `model`           | `Type` or `String` | Yes      | The related model class or table name                              |
| `pivotTable`      | `String`           | Yes      | Name of the join table                                             |
| `foreignKey`      | `String`           | Yes      | Column in `pivotTable` pointing to the current model               |
| `relatedKey`      | `String`           | Yes      | Column in `pivotTable` pointing to the related model               |
| `localKey`        | `String`           | No       | Column in current table referenced by `foreignKey` (default: `id`) |
| `relatedLocalKey` | `String`           | No       | Column in related table referenced by `relatedKey` (default: `id`) |
| `createPivot`     | `bool`             | No       | Auto-generate a minimal pivot table in the schema (default: `false`) |
| `pivotForeignKeys`| `bool`             | No       | Add `FOREIGN KEY ... ON DELETE CASCADE` to the auto pivot (needs `createPivot`, default: `false`) |
