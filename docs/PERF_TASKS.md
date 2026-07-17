# Performance: оставшиеся задачи

Продолжение оптимизаций по итогам `benchmarks/` (phorm_sqlite 1.9.0 закрыл
изолятный протокол: колоночные батчи, буферизация уведомлений, колоночный
SELECT). Остались две задачи уровня генератора.

## (a) Автоиндексы на FK отношений ✅ (сделано: annotations 1.7.0 + generator 1.5.0)

**Проблема.** Загрузка дерева отношений (Single-Query JSON Aggregation)
без индекса на FK-колонке ребёнка деградирует квадратично: коррелированный
подзапрос сканирует таблицу детей для каждого родителя (в бенчмарке
51ms → 4.2ms после добавления индекса). Сейчас генератор индексы на FK
не создаёт — пользователь должен догадаться сам.

**Что сделать:**

- [x] `phorm_generator`: при генерации схемы таблицы, объявившей
      `BelongsTo`, автоматически эмитить
      `CREATE INDEX IF NOT EXISTS <table>_<fk>_idx ON <table>(<fk>);`
      для колонки `foreignKey`.
- [x] То же для автосоздаваемых pivot-таблиц `@ManyToMany(createPivot:)` —
      индексы на обе FK-колонки pivot.
- [x] Опция отключения: `@Schema(indexForeignKeys: false)` (по умолчанию
      `true`) в `phorm_annotations`.
- [x] Существующие базы получают индексы автоматически: `IF NOT EXISTS` +
      `_ensureIdempotentSchemaObjects` на upgrade, а с `autoMigrate: true` —
      при любом открытии (AutoMigrator уже создаёт недостающие индексы).
- [x] Ограничение (задокументировано в docs/05-relationships.md): если ребёнок не объявляет `BelongsTo`
      (только родитель `HasMany`), генератор ребёнка не знает о FK — индекс
      объявить явно через `@Schema(indexes:)`.
- [x] Тесты генератора (e2e в phorm_sqlite невозможен: generator запиннен <1.4.0 из-за meta-конфликта) в phorm_sqlite; раздел в docs/05-relationships.md.

**Версии:** phorm_annotations (новая опция) + phorm_generator (эмиссия).

## (b) Позиционный `fromRow` в генераторе

**Проблема.** Маппинг строк идёт через `fromJson(Map<String, dynamic>)`:
на каждую строку — построение мапы и поиски по строковым ключам. Это
последние ~15% отставания на чтении (5.5ms против 4.8ms у drift-bg на 5k
строк); drift читает колонки позиционно.

**Что сделать:**

- [ ] `phorm_generator`: дополнительно к `fromJson` эмитить
      `static T _$PhormFromRow(List<Object?> row, Map<String, int> columnIndex)`
      с позиционным чтением и теми же преобразованиями типов (enum,
      DateTime, bool 0/1, nullable).
- [ ] `phorm_annotations.Table`: опциональное поле `fromRow` (nullable —
      обратная совместимость с рукописными таблицами).
- [ ] `phorm` core: путь чтения (`readAll`/`_fetchRows`) при наличии
      `table.fromRow` использует его, минуя построение мап (сейчас изолят
      уже отдаёт колоночные данные — мапы можно не собирать вовсе).
- [ ] Внимание: JSON-агрегированные колонки отношений (`posts`) приходят
      строкой — `fromRow` должен их декодировать так же, как `fromJson`.
- [ ] Бенчмарк до/после; цель — паритет или лучше drift-bg на «read + map 5k».

**Версии:** phorm_annotations + phorm_generator + phorm (согласованный релиз).
