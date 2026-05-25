# SQFlow — Overview

SQFlow (Single Query Flow) is a lightweight, type-safe, driver-agnostic ORM for Dart and Flutter. It is designed to separate model definitions and fluent query building from database-specific SQL grammar using a pluggable **Dialect system**. This allows you to write one unified set of models and type-safe query calls, and execute them seamlessly across SQLite (via `sqflow_lite`), PostgreSQL, or MySQL, utilizing background isolates and asynchronous connection pooling without raw SQL concatenation.

## Motivation

Modern database management in Flutter often forces a trade-off between **performance** and **developer experience**. SQFlow is designed to eliminate that trade-off by focusing on four core pillars:

### 1. Zero N+1 Queries (JSON Aggregation)

Traditional ORMs often fetch related data by running multiple queries (the N+1 problem) or using complex JOINs that duplicate parent data.

- **SQFlow Solution**: It leverages the database's native JSON aggregation capabilities (such as SQLite's `json_group_array`/`json_object` or PostgreSQL's `jsonb_agg`/`jsonb_build_object`, compiled dynamically by the active `SqlDialect`) to fetch a primary record and all its related nested structures (HasMany, HasOne, BelongsTo) in **one single, highly-optimized SQL query**. The database compiles this tree natively and returns it in a single trip, avoiding any network or driver roundtrips.

### 2. Fluent Type Safety

Writing SQL queries as strings is error-prone and hard to maintain.

- **SQFlow Solution**: The generator creates static typed columns for every model. Instead of `where: "name LIKE 'A%'"`, you write `Users.name.like('A%')`. This gives you autocomplete, compile-time checks, and prevents SQL injection by default.

### 3. Automatic Lifecycle Management

Most apps need the same patterns: "When was this created?", "Don't actually delete it, just mark it as deleted", "Validate this email before saving".

- **SQFlow Solution**: By adding a few parameters to the `@Schema` annotation, SQFlow automatically handles:
  - **Timestamps**: Injects `created_at` and `updated_at` without manual fields.
  - **Soft Deletes**: Automatically filters out "deleted" records and provides a `restore()` API.
  - **Validation**: Enforces rules (email, length, ranges) in both Dart and the SQL schema.

### 4. Boilerplate-Free Workflow

- **SQFlow Solution**: The generator doesn't just create `toJson/fromJson`. It generates a full **Service Class** (e.g., `Users`) with static methods for CRUD, transactions, and reactive streams (`watch`). No more manual repository patterns or DAOs.

---

## Architecture

```mermaid
graph TD
    %% Styles and colors
    classDef dev fill:#e1f5fe,stroke:#03a9f4,stroke-width:2px,color:#01579b;
    classDef gen fill:#e8f5e9,stroke:#4caf50,stroke-width:2px,color:#1b5e20;
    classDef core fill:#fff3e0,stroke:#ff9800,stroke-width:2px,color:#e65100;
    classDef driver fill:#f3e5f5,stroke:#9c27b0,stroke-width:2px,color:#4a148c;
    classDef db fill:#ffebee,stroke:#f44336,stroke-width:2px,color:#b71c1c;

    subgraph "1. Descriptions of Models (Developer)"
        Model["@Schema Class User<br/>(Defines fields and relationships HasMany/BelongsTo)"]:::dev
    end

    subgraph "2. Code Generation (sqflow_generator)"
        Generator["build_runner"]:::gen
        Mixin["_$SQFlowUserMixin<br/>(toJson, copyWith methods)"]:::gen
        Service["class Users (Service)<br/>(Typed columns and CRUD API)"]:::gen

        Model -->|Static analysis| Generator
        Generator --> Mixin
        Generator --> Service
    end

    subgraph "3. Building a Request (sqflow)"
        AppCall["Users.where(Users.age.gt(18))<br/>.include([Includable.model<Post>()])<br/>.get()"]:::dev
        QueryBuilder["WhereBuilder & Include Resolver<br/>(Linking tables by foreign keys)"]:::core
        Dialect["SqlDialect (sqlite/postgres)<br/>(Building into Single SQL with JSON Aggregation)"]:::core

        Service -->|Calling from application| AppCall
        AppCall --> QueryBuilder
        QueryBuilder --> Dialect
    end

    subgraph "4. Executing a Query (sqflow_lite)"
        Driver["Database Connection Manager<br/>(Connection pool management)"]:::driver
        Isolate["Background Isolate / Web WASM<br/>(Execution in a separate thread without UI freezes)"]:::driver
        SQLite[("Database SQLite")]:::db

        Dialect -->|Compiled SQL + parameters| Driver
        Driver --> Isolate
        Isolate -->|Execute a query| SQLite
    end

    subgraph "5. Result and Mapping"
        RawResult["Single Nested JSON Result<br/>(Parent and child data in one response!)"]:::db
        Parser["JSON Parser & Model Factory<br/>(Fast model assembly from JSON)"]:::core
        AppModels["List of Dart models<br/>List<User>"]:::dev

        SQLite -->|Returns| RawResult
        RawResult --> Parser
        Mixin -.->|Provides JSON factory| Parser
        Parser --> AppModels
    end
```

---

## Dialects & Pluggable SQL Architecture

To ensure the library is future-proof and database-agnostic, SQFlow separates query building and model mapping from the specific SQL grammar of target databases. It accomplishes this through the **`SqlDialect`** interface defined in `sqflow`.

The query builder, JSON eager loading system, and column compiler in `sqflow` never generate hardcoded database-specific SQL strings. Instead, they delegate to the active `SqlDialect` to resolve details like:

- **Identifier Escaping**: SQLite/Postgres uses `"table"."column"`, while MySQL uses `` `table`.`column` ``.
- **Positional Placeholders**: SQLite uses `?`, Postgres uses `$1`, `$2`, etc.
- **JSON Object Construction**: SQLite compiles to `json_object('key', val)`, while Postgres compiles to `jsonb_build_object('key', val)`.
- **JSON Array Aggregation**: SQLite compiles to `(SELECT json_group_array(...) FROM ...)`, while Postgres compiles to `coalesce((SELECT jsonb_agg(...) FROM ...), '[]'::jsonb)`.

This makes it exceptionally easy to swap the underlying database driver without changing a single line of your application models or query builders.

---

## Future Database Roadmap

SQFlow's modularity paves the way for cross-platform, enterprise-ready database adapters:

| Driver Package        | Target Database     | Status                        | Dialect Implementation                                                                             | Under-the-Hood Driver     |
| :-------------------- | :------------------ | :---------------------------- | :------------------------------------------------------------------------------------------------- | :------------------------ |
| **`sqflow_lite`**     | **SQLite**          | **Stable (Production-ready)** | `SqliteDialect` (Single-query JSON aggregation, isolate ports, WebAssembly WASM, IndexedDB)        | `sqlite3` & `sqlite3_web` |
| **`sqflow_postgres`** | **PostgreSQL**      | **Planned**                   | `PostgresDialect` (Positional `$1` parameters, schema namespaces, JSONB arrays, binary aggregates) | `postgres` (Dart)         |
| **`sqflow_mysql`**    | **MySQL / MariaDB** | **Planned**                   | `MysqlDialect` (Backtick escapes, `json_object`, limit offsets)                                    | `mysql_client` / `mysql1` |

When a new driver is introduced, your declarative schemas `@Schema(...)` and code-generated services (like `Users`) remain **100% identical**. Only the database initialization (`DB` manager instantiation) changes!

---

## Package Structure

| Package                     | Role                                                                            |
| :-------------------------- | :------------------------------------------------------------------------------ |
| `sqflow_platform_interface` | Annotations (`@Schema`, `@Column`, `@ID`), data types, relationship definitions |
| `sqflow`                    | Driver-agnostic runtime: `SqflowCore<T>`, `WhereBuilder`, `SortBuilder`         |
| `sqflow_lite`               | SQLite driver & connection manager: `DB`, isolates, WASM, custom SQL functions  |
| `sqflow_generator`          | `build_runner` plugin that generates mixins, SQL, and serialization code        |

---

## Quick Install

```yaml
# pubspec.yaml
dependencies:
  sqflow: ^latest
  sqflow_lite: ^latest # SQLite driver and connection lifecycle manager

dev_dependencies:
  sqflow_platform_interface: ^latest
  sqflow_generator: ^latest
  build_runner: ^latest
```

---

## Minimal Example

```dart
import 'package:sqflow_lite/sqflow_lite.dart';

// 1. Annotate your model
@Schema(tableName: 'users')
class User extends Model with _$SQFlowUserMixin {
  @ID()
  final String id;

  @Column()
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
}

// 2. Run the generator
// dart run build_runner build

// 3. Initialize app database once (from sqflow_lite)
final appDb = DB(databaseName: 'app.db', version: 1, tables: [usersTable]);

// 4. Use the generated service class
await Users.insert(User(id: 'u1', name: 'Alice'));

final user = await Users.readOne('u1');

final list = await Users.where(Users.name.like('A%')).get();

final paged = await Users.readAllWithCount(limit: 20);
print('Page: ${paged.data.length} / Total: ${paged.count}');
```
