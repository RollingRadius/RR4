import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/screen_registry.dart';

/// Stops a new screen from being forgotten by the Hindi overflow test.
///
/// Every .dart file under lib/presentation/screens must be in exactly one of:
///  - [coveredScreens]  (built by test/hindi_overflow_test.dart), or
///  - [skippedScreens]  (not built, with the reason).
/// Both lists are in test/support/screen_registry.dart.
///
/// A new screen fails this test until its author picks one. A skipped screen
/// does not fail it.
const _screensDir = 'lib/presentation/screens';

List<String> _screenFiles() {
  final root = Directory(_screensDir);
  final prefix = '${root.path}/';
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => p.endsWith('.dart'))
      .map((p) => p.substring(p.indexOf(prefix) + prefix.length))
      .toList()
    ..sort();
}

void main() {
  final files = _screenFiles();

  test('every screen file is covered by the overflow test or skipped on purpose',
      () {
    final undecided = files
        .where((f) =>
            !coveredScreens.containsKey(f) && !skippedScreens.containsKey(f))
        .toList();
    expect(undecided, isEmpty,
        reason: 'New screen file(s) not known to the Hindi overflow test.\n'
            'Add each one to coveredScreens (so it is built in Hindi) or to '
            'skippedScreens with a reason, in test/support/screen_registry.dart:\n'
            '${undecided.map((f) => '  $f').join('\n')}');
  });

  test('no screen is both covered and skipped', () {
    final both =
        coveredScreens.keys.where(skippedScreens.containsKey).toList();
    expect(both, isEmpty,
        reason: 'Remove these from skippedScreens, they are covered:\n'
            '${both.join('\n')}');
  });

  test('the registry has no files that were renamed or deleted', () {
    final known = files.toSet();
    final missing = [...coveredScreens.keys, ...skippedScreens.keys]
        .where((f) => !known.contains(f))
        .toList();
    expect(missing, isEmpty,
        reason: 'These registry entries point to files that no longer exist:\n'
            '${missing.join('\n')}');
  });

  test('every skipped screen has a reason', () {
    final empty = skippedScreens.entries
        .where((e) => e.value.trim().length < 10)
        .map((e) => e.key)
        .toList();
    expect(empty, isEmpty, reason: 'Give these a real reason:\n${empty.join('\n')}');
  });

  test('TODO skips are listed so the gaps stay visible', () {
    final todos = skippedScreens.entries
        .where((e) => e.value.startsWith('TODO'))
        .map((e) => '  ${e.key}: ${e.value}')
        .toList();
    if (todos.isNotEmpty) {
      // ignore: avoid_print
      print('${todos.length} screen(s) still to add to the overflow test:\n'
          '${todos.join('\n')}');
    }
  });
}
