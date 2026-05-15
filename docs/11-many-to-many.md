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
class User extends Model with _$SQFlowUserMixin {
  @ID()
  final String id;
  
  @Column()
  final String name;

  // ManyToMany returns a List of related objects
  final List<Role> roles;

  User({required this.id, required this.name, this.roles = const []});
  
  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
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
class Role extends Model with _$SQFlowRoleMixin {
  @ID()
  final String id;

  @Column()
  final String title;

  final List<User> users;

  Role({required this.id, required this.title, this.users = const []});

  factory Role.fromJson(Map<String, dynamic> json) => _$SQFlowRoleFromJson(json);
}
```

---

## The Pivot Table

> [!IMPORTANT]
> **Manual Setup Required**: `sqflow_generator` does **not** automatically generate the SQL for the pivot table. You must define it yourself in a migration or in the `schema` string of one of your models.

### Recommended Pivot Table Schema

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

You can filter records based on columns in the related table using dot notation. SQFlow will automatically generate a `LEFT JOIN` through the pivot table.

```dart
// Find all users who have the 'Admin' role
final admins = await Users.where(
  const SqflowColumn<String>('roles.title').eq('Admin')
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

When you include a `ManyToMany` relationship, SQFlow performs a correlated subquery using `json_group_array` and `json_object`.

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

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `model` | `Type` or `String` | Yes | The related model class or table name |
| `pivotTable` | `String` | Yes | Name of the join table |
| `foreignKey` | `String` | Yes | Column in `pivotTable` pointing to the current model |
| `relatedKey` | `String` | Yes | Column in `pivotTable` pointing to the related model |
| `localKey` | `String` | No | Column in current table referenced by `foreignKey` (default: `id`) |
| `relatedLocalKey` | `String` | No | Column in related table referenced by `relatedKey` (default: `id`) |
