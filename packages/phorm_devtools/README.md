# phorm_devtools

Debug bridge that exposes running [PHORM](https://pub.dev/packages/phorm) databases to the **Phorm Studio** DevTools extension: database inspector, query profiler, migrations status and reactive stream monitor.

## Usage

```dart
import 'package:phorm_devtools/phorm_devtools.dart';

final db = DB(tables: [...]);
enablePhormDevtools(db); // no-op in release/profile builds
```

The call body runs inside an `assert`, so the bridge is compiled out of release and profile builds entirely — zero overhead in production.

Multiple databases are supported:

```dart
enablePhormDevtools(mainDb, id: 'main', label: 'app.db');
enablePhormDevtools(cacheDb, id: 'cache', label: 'cache.db');
```
