// Release consistency checker for the PHORM monorepo.
//
// For every publishable package under packages/ it verifies that:
//   1. pubspec.yaml version == the top CHANGELOG.md section version;
//   2. the version relates sanely to pub.dev (equal = published,
//      greater = pending publish, lower = error);
//   3. a pending package has a clean git tree (so the publish archive
//      matches the commit that will be tagged);
//   4. a published package has no uncommitted lib/ or pubspec changes
//      (which would mean a forgotten version bump);
//   5. the release tag `<package>-v<version>` for a pending package does
//      not already exist on a different commit.
//
// For pending packages it prints the publish commands in dependency order
// (workspace dependencies first). Exits non-zero when any check fails.
//
// Usage: melos run release-check   (or: dart run tool/release_check.dart)

import 'dart:convert';
import 'dart:io';

const _packagesDir = 'packages';

class PackageState {
  PackageState(this.name, this.dir);

  final String name;
  final String dir;
  String local = '?';
  String? changelogTop;
  String? pubDev;
  List<String> workspaceDeps = [];
  final List<String> errors = [];
  final List<String> warnings = [];

  bool get pending =>
      pubDev != null && local != pubDev && _isNewer(local, pubDev!);
}

bool _isNewer(String a, String b) {
  List<int> parse(String v) =>
      v.split('+').first.split('.').map(int.parse).toList();
  final pa = parse(a);
  final pb = parse(b);
  for (var i = 0; i < 3; i++) {
    if (pa[i] != pb[i]) return pa[i] > pb[i];
  }
  return false;
}

Future<String?> _pubDevLatest(String package) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('https://pub.dev/api/packages/$package'),
    );
    final response = await request.close();
    if (response.statusCode != 200) return null;
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return (json['latest'] as Map<String, dynamic>)['version'] as String;
  } finally {
    client.close();
  }
}

String? _match(String content, RegExp re) => re.firstMatch(content)?.group(1);

Future<String> _git(List<String> args) async {
  final result = await Process.run('git', args);
  return (result.stdout as String).trim();
}

Future<void> main(List<String> args) async {
  final allowDirty = args.contains('--allow-dirty');
  final states = <PackageState>[];
  final dirs =
      Directory(_packagesDir).listSync().whereType<Directory>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final workspaceNames = <String>{};
  for (final dir in dirs) {
    final pubspecFile = File('${dir.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) continue;
    final pubspec = pubspecFile.readAsStringSync();
    if (pubspec.contains('publish_to: none')) continue;
    final name = _match(pubspec, RegExp(r'^name:\s*(\S+)', multiLine: true))!;
    workspaceNames.add(name);
    states.add(PackageState(name, dir.path));
  }

  for (final state in states) {
    final pubspec = File('${state.dir}/pubspec.yaml').readAsStringSync();
    state.local =
        _match(pubspec, RegExp(r'^version:\s*(\S+)', multiLine: true)) ?? '?';

    // Workspace deps (hosted references to sibling packages).
    for (final dep in workspaceNames) {
      if (dep == state.name) continue;
      if (RegExp('^  $dep:', multiLine: true).hasMatch(pubspec)) {
        state.workspaceDeps.add(dep);
      }
    }

    // 1. CHANGELOG top section.
    final changelogFile = File('${state.dir}/CHANGELOG.md');
    if (changelogFile.existsSync()) {
      state.changelogTop = _match(
        changelogFile.readAsStringSync(),
        RegExp(r'^##\s*\[?([0-9]+\.[0-9]+\.[0-9]+[^\]\s]*)', multiLine: true),
      );
      if (state.changelogTop != state.local) {
        state.errors.add(
          'CHANGELOG top section is ${state.changelogTop ?? 'missing'}, '
          'pubspec is ${state.local} — they must match',
        );
      }
    } else {
      state.errors.add('CHANGELOG.md is missing');
    }

    // 2. pub.dev state.
    state.pubDev = await _pubDevLatest(state.name);
    if (state.pubDev == null) {
      state.warnings.add('could not reach pub.dev (offline?)');
    } else if (state.local != state.pubDev &&
        !_isNewer(state.local, state.pubDev!)) {
      state.errors.add(
        'local version ${state.local} is OLDER than pub.dev ${state.pubDev}',
      );
    }

    // 3/4. Git cleanliness.
    final dirty = await _git(['status', '--porcelain', state.dir]);
    if (state.pending && dirty.isNotEmpty) {
      (allowDirty ? state.warnings : state.errors).add(
        'pending publish but the package tree has uncommitted changes — '
        'commit first so the tag matches the published archive',
      );
    } else if (!state.pending && dirty.isNotEmpty) {
      final libTouched = dirty
          .split('\n')
          .any((l) => l.contains('/lib/') || l.endsWith('pubspec.yaml'));
      if (libTouched) {
        state.warnings.add(
          'lib/ or pubspec changed but the version equals pub.dev — '
          'did you forget to bump the version and CHANGELOG?',
        );
      }
    }

    // 5. Tag placement for pending releases.
    final tag = '${state.name}-v${state.local}';
    final tagCommit = await _git(['rev-list', '-n', '1', tag]);
    if (state.pending && tagCommit.isNotEmpty) {
      final tagged = await _git(
        ['show', '$tag:${state.dir}/pubspec.yaml'],
      );
      final taggedVersion = _match(
        tagged,
        RegExp(r'^version:\s*(\S+)', multiLine: true),
      );
      if (taggedVersion != state.local) {
        state.errors.add(
          'tag $tag already exists but points at a commit with version '
          '$taggedVersion — re-point it after committing the bump',
        );
      }
    }
  }

  // Report.
  stdout
    ..writeln('Package             pub.dev     local       status')
    ..writeln('─' * 62);
  var failed = false;
  for (final state in states) {
    final status = state.errors.isNotEmpty
        ? '❌ inconsistent'
        : state.pending
        ? '🚀 pending publish'
        : '✅ published';
    stdout.writeln(
      '${state.name.padRight(20)}'
      '${(state.pubDev ?? '?').padRight(12)}'
      '${state.local.padRight(12)}'
      '$status',
    );
    for (final e in state.errors) {
      failed = true;
      stdout.writeln('    ❌ $e');
    }
    for (final w in state.warnings) {
      stdout.writeln('    ⚠️  $w');
    }
  }

  // Publish plan in dependency order (workspace deps first).
  final pendingStates = states
      .where((s) => s.pending && s.errors.isEmpty)
      .toList();
  if (pendingStates.isNotEmpty && !failed) {
    final ordered = <PackageState>[];
    void visit(PackageState s) {
      if (ordered.contains(s)) return;
      for (final dep in s.workspaceDeps) {
        final depState = pendingStates.where((p) => p.name == dep).firstOrNull;
        if (depState != null) visit(depState);
      }
      ordered.add(s);
    }

    pendingStates.forEach(visit);

    stdout
      ..writeln()
      ..writeln('Publish plan (dependency order):');
    for (final s in ordered) {
      final flutter = File(
        '${s.dir}/pubspec.yaml',
      ).readAsStringSync().contains('sdk: flutter');
      final cmd = flutter ? 'flutter' : 'dart';
      stdout
        ..writeln('  # ${s.name} ${s.local}')
        ..writeln('  (cd ${s.dir} && $cmd pub publish)');
    }
    stdout.writeln(
      '\nNotes:\n'
      '  - commit and push the version bumps first: CI (auto_tag in '
      'main.yml) creates the ${ordered.map((s) => '${s.name}-v${s.local}').join(', ')} '
      'tag(s) and GitHub Release(s) automatically — do not tag manually;\n'
      '  - wait until each package appears on pub.dev before publishing '
      'the next one that depends on it.',
    );
  }

  if (failed) {
    stdout.writeln('\nRelease check FAILED — fix the ❌ items above.');
    exitCode = 1;
  } else {
    stdout.writeln('\nRelease check passed.');
  }
}
