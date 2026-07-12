# План улучшений PHORM

Составлен по итогам ревью кодовой базы (2026-07-11). Пункты упорядочены по приоритету.

## 1. UTC-таймстемпы ✅ (сделано)

**Проблема:** `DateTime.now().toIso8601String()` пишет локальное время без смещения.
Записи с устройств в разных таймзонах несортируемы между собой; перевод часов (DST)
может дать `updated_at < created_at`.

**Решение:** писать `DateTime.now().toUtc().toIso8601String()` везде, где ORM
генерирует таймстемпы:

- [x] `packages/phorm/lib/src/core.dart` — `created_at` / `updated_at` / `deleted_at` (3 места)
- [x] `packages/phorm_sqlite/lib/src/db.dart` — `applied_at` миграций (2 места)
- [x] Прогнать тесты (phorm: 123, phorm_sqlite: 222 — все зелёные, правок не потребовалось)
- [x] Отмечено в CHANGELOG обоих пакетов как breaking change

## 2. Melos для monorepo ✅ (сделано)

**Проблема:** monorepo из 6 пакетов управляется вручную (Makefile только для тегов).

**Сделано:**

- [x] `melos.yaml` (workspace: `packages/*`) + корневой `pubspec.yaml`
- [x] Скрипты: `analyze`, `test`, `format`, `build_runner`
- [x] README: раздел Contributing с `melos bootstrap`
- [ ] (Опционально) перевести релизный процесс на `melos version` / `melos publish`

**Нюансы окружения:**

- `examples/` исключён из workspace: `flutter_test` на текущем Flutter stable
  (3.44.4) пиннит `meta 1.18.0`, а `analyzer ^13.3.0` из локального
  `phorm_generator` требует `meta ^1.18.3` — example не резолвится и без melos.
- По той же причине в `phorm_sqlite/pubspec.yaml` добавлен явный
  `dependency_overrides: phorm_generator: ">=1.3.0 <1.4.0"` — иначе melos
  path-линкует локальный generator в обход уже существующего пина `<1.4.0`.
  Оба обхода снять, когда Flutter начнёт поставлять `meta >=1.18.3`.

## 3. Экранирование колонок в WhereBuilder

`_Condition.compile` подставляет имя колонки в SQL через `replaceAll(RegExp('\b…\b'))` —
хрупко при совпадении имени колонки со словом в строковом литерале или ключевым словом.
Строить условия структурно (колонка/оператор/значение отдельно), regex оставить только для `raw()`.

## 4. Драйверы postgres/mysql — довести или пометить experimental

Генераторы полны TODO (AUTO_INCREMENT, backticks, ON UPDATE CURRENT_TIMESTAMP,
генерация функций не реализована). Либо доделать schema-генерацию, либо явно
пометить пакеты как preview в README/pubspec.

## 5. Разбить крупные файлы

`core.dart` (~1300 строк) и `where_builder.dart` (~1100 строк): разнести CRUD,
JOIN/JSON-агрегацию и подготовку данных по отдельным файлам.

## 6. Вернуть отключённые линты

Постепенно включить обратно правила very_good_analysis, в первую очередь
`public_member_api_docs` (pub points) и `cast_nullable_to_non_nullable`.

## 7. Типизировать `_Condition.condition`

Заменить `dynamic` («String или WhereBuilder») на sealed-иерархию.

## 8. Интеграционные тесты драйверов в CI

Поднимать реальные PostgreSQL/MySQL через `services:` в GitHub Actions и гонять
сгенерированный SQL против них.

## 9. Гигиена репозитория

Добавить `.vscode/flutter-translator/` в `.gitignore` (или закоммитить осознанно).
