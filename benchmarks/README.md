# PHORM Benchmarks (internal)

Cross-ORM benchmark harness: **PHORM vs [drift](https://pub.dev/packages/drift)
(same-thread and background-isolate configs) vs raw `sqlite3`**. Internal
performance-tracking tooling — used to find regressions and guide
optimization, not a marketing artifact. It already paid for itself: the first
run exposed a per-operation isolate round-trip in `Batch.commit()`
(5k inserts: 457ms → 41ms after the fix).

## Run

```bash
cd benchmarks
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter test test/orm_benchmark_test.dart
```

## Current numbers

Apple M3, Flutter 3.44.4, median of 5 runs after warmup (ms, lower is
better). `drift-bg` = drift over `NativeDatabase.createInBackground`
(the apples-to-apples config vs PHORM's always-on background isolate):

| Scenario                        | PHORM   | drift | drift-bg | raw sqlite3 |
| :------------------------------ | ------: | ----: | -------: | ----------: |
| insert 5k users (single txn)    | **6.6** |  13.2 |     11.8 |         2.7 |
| read + map 5k users             |     5.5 |   3.7 |      4.8 |         2.0 |
| filtered read (~1/6 of 5k)      |     1.0 |   0.7 |      1.1 |         0.3 |
| load 500 users × 10 posts each  | **4.2** |  12.2 |     12.0 |         3.6 |

History of optimizations this harness has driven (phorm_sqlite 1.8.0–1.9.0):

1. `Batch.commit()` per-operation isolate round-trips → single message
   (457ms → 41ms for 5k inserts).
2. Update-hook notifications sent per affected row across the isolate →
   buffered per batch/transaction, flushed once per distinct table
   (41ms → ~7ms; this was the dominant remaining cost).
3. Columnar `BatchInsertMany` + single prepared statement per batch;
   columnar SELECT transfer (column names cross the boundary once).
4. Relationship tree: the benchmark initially missed an index on the child
   foreign key — with it, Single-Query JSON Aggregation beats join+group
   (51ms → 4.2ms). **Index your FK columns.**

Remaining gap: read+map trails drift-bg by ~15% (`fromJson` map lookups vs
positional reads) — a generator-emitted positional `fromRow` could close it.

## Methodology & fairness notes

- All timings are **end-to-end from the caller**. PHORM always crosses its
  background database isolate; `drift` runs on the calling thread
  (`NativeDatabase.memory()`), `drift-bg` crosses drift's background isolate
  over a temp file — the fair comparison for PHORM.
- The relationship scenario is PHORM's headline feature: **one SQL query**
  with JSON aggregation returns the whole tree, while the drift and raw
  variants use the idiomatic `LEFT JOIN` + manual row grouping in Dart. All
  three produce the same 500-parent / 5000-child structure.
- Raw `sqlite3` is the theoretical floor: prepared statements, no mapping
  abstractions, same thread — no ORM can beat it, the question is how close
  the convenience layers stay.
- Numbers vary between machines and runs; treat relative order, not absolute
  values, as the signal. Re-run locally with the commands above.
