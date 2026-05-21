# Flutter Web Support (WebAssembly)

The SQLite driver for SQFlow (`sqflow_lite`) supports Flutter Web out of the box via **WebAssembly (WASM)**.  
The correct backend is selected **automatically** by the driver — no conditional imports or platform checks needed in your application code.

| Platform | Backend | Storage |
|---|---|---|
| Android / iOS | `dart:isolate` + native SQLite | App data directory |
| macOS / Windows / Linux | `dart:isolate` + native SQLite | App data directory |
| **Flutter Web** | **WasmSqlite3** (WebAssembly) | **IndexedDB** (persists across reloads) |

---

## How it works

SQFlow uses Dart's [conditional imports](https://dart.dev/guides/libraries/create-packages#conditional-imports) inside **`sqflow_lite`** to automatically switch between two implementations:

```
sqflow_lite
  └── lib/src/database_isolate.dart  ← entry point (router)
        ├── non-web  → database_isolate_io.dart   (dart:isolate + sqlite3)
        └── web      → database_isolate_web.dart  (WasmSqlite3)
```

Your application code is **identical** on all platforms:

```dart
import 'package:sqflow_lite/sqflow_lite.dart';

// Same code on iOS, Android, Desktop, and Web — nothing changes
final db = DB(
  databaseName: 'myapp.db',
  version: 1,
  tables: [usersTable, postsTable],
);

final users = await Users.query.get();
```

---

## Setup for Flutter Web

### Step 1 — Add sqflow_core and sqflow_lite

```yaml
# pubspec.yaml of your Flutter application
dependencies:
  sqflow_core: ^latest
  sqflow_lite: ^latest # SQLite driver containing WASM web support
```

The `sqlite3_web` transitive dependency is pulled in automatically by `sqflow_lite`.

### Step 2 — Download `sqlite3.wasm`

The WASM binary must be served alongside your web app. Run this once in your project root:

```bash
curl -L \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm" \
  -o web/sqlite3.wasm
```

> **Why can't sqflow_lite include this automatically?**  
> `.wasm` is a binary web asset. Dart packages cannot inject files into the `web/` directory  
> of a consuming application — this is a Flutter Web platform constraint (similar to fonts and icons  
> that you also register manually in `pubspec.yaml`).

### Step 3 — Build for web

```bash
flutter build web
# or for development:
flutter run -d chrome
```

That's it. No additional configuration is needed.

---

## Project structure

After setup, your project looks like this:

```
my_flutter_app/
  lib/
    main.dart
  web/
    index.html
    favicon.png
    sqlite3.wasm    ← add this file (Step 2)
  pubspec.yaml
```

---

## Data persistence

On Flutter Web, SQFlow uses **IndexedDB** via `IndexedDbFileSystem` (from `sqlite3_web`).

- Data persists across **page reloads** and **browser sessions**
- Each database file gets its own IndexedDB store: `sqflow_<filename>`
- In-memory databases (`:memory:`) work as expected — no persistence

```dart
// Persistent — survives page reloads
final db = DB(databaseName: 'myapp.db', version: 1, tables: [...]);

// In-memory — cleared on page reload (same as native)
final db = DB(databaseName: ':memory:', version: 1, tables: [...]);
```

---

## Limitations on Flutter Web

| Feature | Native | Web |
|---|---|---|
| Background isolate | ✅ Non-blocking | ⚠️ Runs on main thread* |
| Custom SQL functions | ✅ | ✅ |
| Transactions | ✅ | ✅ |
| Batch operations | ✅ | ✅ |
| Migrations | ✅ | ✅ |
| Reactive streams | ✅ | ✅ |
| Encryption (SQLCipher) | ✅ | ❌ Not supported |

> *On Flutter Web, Dart isolates are simulated as microtasks — they do not run on a true background thread.  
> For heavy read/write workloads on web, consider using a [SharedWorker](https://developer.mozilla.org/en-US/docs/Web/API/SharedWorker) — this is an optional future optimisation.

---

## Troubleshooting

### `Failed to fetch sqlite3.wasm`

The WASM binary is missing from your `web/` directory. Run Step 2 above.

### `MissingPluginException` on web (when migrating from `sqflite`)

If you are migrating to SQFlow from standard `sqflite` (or `sqflite_common_ffi`), you might encounter a `MissingPluginException` on Web because those packages rely on native method channels which are not supported in browsers.

**Solution:** Ensure you are using `sqflow_lite`'s `DB` class rather than standard `sqflite` APIs. You can safely remove the `sqflite` package from your dependencies. Note that you **must keep** `sqlite3_flutter_libs` (or `sqlcipher_flutter_libs` if using encryption) in your `pubspec.yaml` if your application also targets native platforms (iOS, Android, Desktop), as they are required to bundle the native SQLite binaries. They will be safely ignored when compiling for Web.

### `SharedArrayBuffer` warning in browser console

Some WASM features require `SharedArrayBuffer`. Add these headers to your web server:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

For Flutter's built-in dev server, this is handled automatically by `flutter run`.

---

## Version compatibility

| sqflow_lite | sqlite3 | sqlite3_web | Dart SDK |
|---|---|---|---|
| 1.1.x | ^2.9.4 | ^0.3.1 | >=3.5.0 |

> **Note on sqlite3 3.x:**  
> `sqlite3: ^3.x.x` requires Dart SDK `>=3.9.999` (not yet released as of May 2026).  
> `sqflow_lite` stays on `^2.9.4` until the stable Dart SDK supports it.  
> When Dart SDK 3.10+ is released, `sqlite3_flutter_libs` and `sqlite3_native_assets`  
> will no longer be needed on any platform — the sqlite3 package will bundle everything natively.
