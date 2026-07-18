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

Apple M3, Flutter 3.44.4, median of 5 runs after warmup, averaged over two
harness runs (ms, lower is better). `drift-bg` = drift over
`NativeDatabase.createInBackground` (the apples-to-apples config vs PHORM's
always-on background isolate):

<style>
table.benchmark {
    border-collapse: collapse;
    width: 100%;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    font-size: 14px;
}

.benchmark th,
.benchmark td {
    border: 1px solid #d0d7de;
    padding: 10px 14px;
}

.benchmark th {
    background: #f6f8fa;
    font-weight: 600;
    text-align: left;
}

.benchmark td:not(:first-child),
.benchmark th:not(:first-child) {
    text-align: right;
    font-variant-numeric: tabular-nums;
}

.best {
    background: #dcfce7;
    color: #166534;
    font-weight: 700;
}

.good {
    background: #fef9c3;
    color: #854d0e;
    font-weight: 600;
}

.ok {
    background: #ffedd5;
    color: #9a3412;
}

.raw {
    background: #f8fafc;
    color: #475569;
}
</style>

<table class="benchmark">
<thead>
<tr>
    <th>Scenario</th>
    <th>PHORM</th>
    <th>drift</th>
    <th>drift-bg</th>
    <th>raw sqlite3</th>
</tr>
</thead>

<tbody>

<tr>
    <td>insert 5k users (single txn)</td>
    <td class="good">7.1 ms</td>
    <td class="ok">12.3 ms</td>
    <td class="ok">12.0 ms</td>
    <td class="best">2.7 ms</td>
</tr>

<tr>
    <td>read + map 5k users</td>
    <td class="good">2.7 ms</td>
    <td class="ok">3.6 ms</td>
    <td class="ok">4.0 ms</td>
    <td class="best">1.7 ms</td>
</tr>

<tr>
    <td>filtered read (~1/6 of 5k)</td>
    <td class="good">0.7 ms</td>
    <td class="good">0.7 ms</td>
    <td class="ok">0.8 ms</td>
    <td class="best">0.3 ms</td>
</tr>

<tr>
    <td>load 500 users × 10 posts each</td>
    <td class="good">4.1 ms</td>
    <td class="ok">11.5 ms</td>
    <td class="ok">11.9 ms</td>
    <td class="best">3.2 ms</td>
</tr>

</tbody>
</table>

History of optimizations this harness has driven (phorm_sqlite 1.8.0+, phorm 1.9.0–1.10.0):

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

5. Reads without `include` go through the core's `ColumnarQueryExecutor`
   fast path (phorm 1.9.0): positional rows are mapped directly, without the
   per-row map copy/rescan of the executor boundary (5.5 → 3.3ms).
6. Generated positional row binders (`Table.rowBinder`, phorm 1.10.0 +
   generator 1.6.0) drop the per-row map entirely — column indices resolve
   once, fields read by position (read+map 3.3 → 2.7ms, ahead of
   same-thread drift; filtered read at parity, with the fixed isolate
   round-trip that keeps SQLite off the UI thread included).

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
