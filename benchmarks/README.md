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

| Scenario                        | PHORM | drift | drift-bg | raw sqlite3 |
| :------------------------------ | ----: | ----: | -------: | ----------: |
| insert 5k users (single txn)    |  44.3 |  11.8 |     10.8 |         2.6 |
| read + map 5k users             |   6.7 |   3.3 |      3.9 |         1.7 |
| filtered read (~1/6 of 5k)      |   1.1 |   0.6 |      0.8 |         0.3 |
| load 500 users × 10 posts each  |  50.5 |  12.2 |     12.1 |         3.2 |

Known optimization targets (in rough order of impact):

1. **Bulk insert path** (~4× gap): per-row `_prepareDataForDb` map copies and
   per-row map serialization across the isolate boundary.
2. **Relationship tree** (~4× gap): `json_group_array` string parsing via
   `jsonDecode` per parent row; a row-shape protocol would avoid the
   stringify/parse round trip.
3. **Row mapping** (~2× gap): `fromJson` on `Map<String, dynamic>` vs drift's
   positional column reads.

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
