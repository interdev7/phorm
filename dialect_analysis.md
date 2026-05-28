# Анализ поддержки диалектов и валидаторов в PHORM

Я провел детальный анализ кодовой базы проектов `phorm`, `phorm_sqlite`, `phorm_annotations`, `phorm_generator`, сравнил реализацию с документацией и выявил ряд критических расхождений, связанных с поддержкой SQL-диалектов и генерацией ограничений базы данных.

---

## 1. Проблема с плейсхолдерами (Positional Placeholders)

### Что заявляет документация:
В `docs/01-overview.md` (раздел *Dialects & Pluggable SQL Architecture*) утверждается:
> *Positional Placeholders: SQLite uses `?`, Postgres uses `$1`, `$2`, etc.*
> *The query builder, JSON eager loading system, and column compiler in phorm never generate hardcoded database-specific SQL strings. Instead, they delegate to the active SqlDialect...*

### Реальное положение дел:
- Метод `compilePlaceholder(int index)` действительно объявлен в интерфейсе `SqlDialect` и реализован в `SqliteDialect`, но **он ни разу не вызывается во всем проекте**.
- Класс `WhereBuilder` в `lib/src/where_builder.dart` **жестко кодирует плейсхолдер `?`** во всех методах фильтрации:
  ```dart
  WhereBuilder eq(Object column, Object? value) {
    ...
    _addCondition('$column = ?', [_prepareValue(value)], column);
    return this;
  }
  ```
- В ядре `lib/src/core.dart` CRUD-операции (такие как `update`, `delete`, `restore`, `updateBatch` и т.д.) также имеют жестко прописанные `?`:
  ```dart
  where: '${table.primaryKey} = ?'
  ```
- **Следствие**: Из-за жестко зашитого `?` библиотека в текущем состоянии не сможет работать с СУБД вроде PostgreSQL (где требуются плейсхолдеры `$1`, `$2`), так как драйверы PostgreSQL не умеют работать с `?` без предварительного парсинга и замены на стороне ORM.

---

## 2. Экранирование идентификаторов (Identifier Escaping)

### Что заявляет документация:
В `docs/01-overview.md` утверждается:
> *Identifier Escaping: SQLite/Postgres uses `"table"."column"`, while MySQL uses `` `table`.`column` ``.*

В `docs/09-pitfalls-and-limitations.md`:
> *Let `SqlDialect.escapeIdentifier` handle it programmatically...*

### Реальное положение дел:
- Метод `escapeIdentifier(String name)` объявлен в интерфейсе `SqlDialect` и реализован в `SqliteDialect` (оборачивая части в двойные кавычки `"`), но **он также нигде не используется**.
- В `lib/src/core.dart` при сборке JOIN-запросов и JSON-агрегации имена колонок и таблиц объединяются обычным соединением строк через точку без вызова экранирования:
  ```dart
  fields[c] = '${currentTable.name}.$c';
  selectFields.addAll(effectiveColumns.map((c) => '${table.name}.$c'));
  ```
- **Следствие**: Если имя таблицы или колонки совпадет с зарезервированным словом SQL (например, `user`, `order`), это приведет к ошибкам синтаксиса в SQLite/Postgres, так как реального экранирования идентификаторов на уровне сборщика запросов не происходит.

---

## 3. Специфика генератора схем и триггеров

### Что заявляет документация:
PHORM позиционируется как независимая от конкретной СУБД (driver-agnostic) библиотека.

### Реальное положение дел:
- В `phorm_generator` генератор схем называется `SqliteSchemaGenerator` и жестко генерирует SQLite-специфичный SQL:
  - Типы полей по умолчанию маппятся в SQLite-типы (например, `TEXT` для DateTime).
  - Генерация триггеров обновления дат (`updated_at`) жестко прописана под синтаксис SQLite с использованием встроенной функции `datetime('now')`:
    ```dart
    String _generateTrigger(String tableName) {
      return '''
    CREATE TRIGGER update_${tableName}_timestamp
    AFTER UPDATE ON $tableName
    FOR EACH ROW
    BEGIN
        UPDATE $tableName SET updated_at = datetime('now') WHERE id = OLD.id;
    END;''';
    }
    ```
- **Следствие**: Для поддержки других СУБД (PostgreSQL / MySQL) потребуется абстрагировать генератор схем, так как текущий SQL-код триггеров и типов данных не запустится на PostgreSQL (где для аналогичного поведения используются функции и триггеры `BEFORE UPDATE`, а также тип `TIMESTAMP` / функция `NOW()`).

---

## 4. Проблемы с валидатором `NotEmptyValidator`

При анализе валидаторов были обнаружены две важные проблемы.

### А. Ошибка в генерируемом SQL-синтаксисе
В `phorm_annotations/lib/src/check_validators.dart`:
```dart
class NotEmptyValidator implements ISqlValidator, IJsonValidator {
  ...
  @override
  String toSql(String columnName) => '$columnName <> ""';
}
```
- Использование двойных кавычек `""` для пустой строки нарушает стандарт SQL (в большинстве СУБД, включая PostgreSQL, двойные кавычки обозначают имена колонок/таблиц, а строковые литералы должны оборачиваться в одинарные кавычки `''`). Должно быть: `'$columnName <> \'\''`.
- Интересно, что в документации `docs/10-validators.md` эта несовместимость зафиксирована как норма:
  `| NotEmptyValidator() | Ensures the string is not empty. | col <> "" |`

### Б. Пропуск генерации CHECK-ограничения в БД
В `phorm_generator/lib/src/sqlite_schema_generator.dart` метод `_getCheckSql` отвечает за генерацию CHECK-ограничений на основе аннотаций:
```dart
  String? _getCheckSql(ConstantReader reader, String columnName) {
    if (reader.isNull) return null;

    if (_checkInListChecker.isExactlyType(reader.objectValue.type!)) { ... }
    if (_checkRangeChecker.isExactlyType(reader.objectValue.type!)) { ... }
    if (_checkComparisonChecker.isExactlyType(reader.objectValue.type!)) { ... }
    if (_checkLengthChecker.isExactlyType(reader.objectValue.type!)) { ... }
    if (_checkNotChecker.isExactlyType(reader.objectValue.type!)) { ... }
    if (_customSqlChecker.isExactlyType(reader.objectValue.type!)) { ... }

    // Fallback for custom ISqlValidator that declares a 'sql' string field
    final type = reader.objectValue.type;
    if (type != null && const TypeChecker.fromRuntime(ISqlValidator).isAssignableFromType(type)) {
      final sqlField = reader.peek('sql');
      if (sqlField != null && sqlField.isString) {
        return sqlField.stringValue.replaceAll('{column}', columnName);
      }
    }
    return null;
  }
```
- **Проблема**: `NotEmptyValidator` не сопоставляется ни с одним из `_check*Checker` условий. Кроме того, класс `NotEmptyValidator` **не имеет строкового поля `sql`** (у него есть только метод `toSql()`, который во время генерации кода вызвать невозможно, так как генератор работает через статический анализ AST без создания живых инстансов классов Dart).
- **Результат**: Метод `_getCheckSql` возвращает `null` для `NotEmptyValidator`. Из-за этого CHECK-ограничение для пустых строк **никогда не попадает в итоговую SQL-схему БД**.
- При этом валидация на стороне Dart генерируется успешно, так как в генерируемом `toJson()` напрямую вызывается `.isValid(...)`:
  ```dart
  if (!const NotEmptyValidator().isValid(json['first_name'])) { ... }
  ```

---

## Резюме

В текущей версии PHORM **архитектура диалектов не интегрирована в сборщик запросов (Query Builder)**:
1. `SqlDialect.escapeIdentifier` и `SqlDialect.compilePlaceholder` никак не используются.
2. Вся кодовая база ядра жестко завязана на синтаксис SQLite/MySQL (плейсхолдеры `?` и отсутствие экранирования).
3. Валидатор `NotEmptyValidator` полностью игнорируется генератором при создании ограничений базы данных (`CHECK`), а его строковое представление содержит некорректные для многих СУБД двойные кавычки.
