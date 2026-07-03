# PHORM benchmarks

Microbenchmarks that back the runtime-behaviour claims in the docs (and the
default value of `DB.isolateThreshold`).

## `parse_benchmark.dart` — inline vs. isolate row parsing

`PhormCore.readAll()` maps the raw SQL rows into model objects. When the result
set is larger than `isolateThreshold`, that mapping is offloaded to a background
isolate (`Isolate.run`) so the UI thread stays free of jank. Spawning an isolate
and copying the rows across the isolate boundary has a **fixed cost**, so below
some row count it is cheaper to parse inline on the current thread.

This benchmark drives the real `readAll()` path against a fake executor that
returns _N_ pre-built rows, once with the isolate path forced on and once with
it forced off, across a range of _N_.

### Run

```sh
dart run benchmark/parse_benchmark.dart
```

`phorm/lib` imports no Flutter, so a plain `dart run` works (no `flutter test`
harness required).

### Method

- Model: `_User` with 5 typed fields (`int`/`String`/`bool`), so `fromJson`
  does real per-row coercion.
- Each measurement warms up once (JIT + first isolate spawn), then times
  _iterations_ back-to-back `readAll()` calls and reports **ms per call**
  (200 iterations for small sets, down to 20 for the largest).
- `inline` = `isolateThreshold` forced very high; `isolate` = forced to `0`
  (every call spawns an `Isolate.run`, matching production behaviour).

### Results

Measured on Apple Silicon (macos_arm64), Dart 3.12.2. Absolute numbers are
machine-specific; the **shape** is what matters.

| rows  | inline (ms) | isolate (ms) | winner |
| ----: | ----------: | -----------: | :----- |
|   100 |       0.108 |        0.142 | inline |
|   200 |       0.115 |        0.206 | inline |
|   500 |       0.283 |        0.397 | inline |
|  1000 |       0.553 |        0.710 | inline |
|  2000 |       1.151 |        1.410 | inline |
|  5000 |       2.818 |        3.595 | inline |
| 20000 |      11.752 |       17.932 | inline |
| 50000 |      30.665 |       52.380 | inline |

(Row counts start at 100; below that both paths are sub-0.1 ms and dominated by
timer jitter, so the comparison is not meaningful.)

### Interpretation

The isolate path is **slower in total wall-clock time at every size** — the
spawn + row-copy overhead is never recovered. That is expected: the isolate's
job is not to be faster, it is to **keep the main thread free**. The `inline`
column _is_ the main-thread blocking time.

So the threshold should be chosen against the **frame budget** (~16 ms at
60fps), not against total time:

- ≤ 5000 rows → inline parse ≤ ~3 ms: no jank, isolate is pure overhead.
- ~20000 rows → inline ~12 ms: approaching a dropped frame.
- ≥ 50000 rows → inline ~30 ms: janks; the isolate earns its cost.

On a dev machine the break-even (inline crossing ~8 ms of one frame) is around
15–20k rows. Low-end mobile CPUs are ~3–5× slower, which pulls the crossover
down to a few thousand rows.

### Chosen default

`DB.isolateThreshold` defaults to **2000**. Inline parsing of 2000 typical rows
is ~1 ms on this machine (≈ 3–5 ms on low-end mobile — comfortably within one
frame), while anything larger — where a low-end device would start to jank —
goes to the isolate. The previous default of `50` spawned an isolate for
sub-millisecond work, adding latency and transient memory with no jank benefit.
Callers with an unusual row/parse profile can still override `isolateThreshold`.
