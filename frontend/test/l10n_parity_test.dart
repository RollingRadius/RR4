import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads the real ARB files, so every string added later is checked
/// automatically — nothing here lists keys by name.
Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  final en = _arb('app_en.arb');
  final hi = _arb('app_hi.arb');
  final enKeys = _keys(en);
  final hiKeys = _keys(hi);

  test('every English string has a Hindi translation', () {
    expect(enKeys.difference(hiKeys).toList()..sort(), isEmpty,
        reason: 'Missing in app_hi.arb');
  });

  test('Hindi has no strings that English does not have', () {
    expect(hiKeys.difference(enKeys).toList()..sort(), isEmpty,
        reason: 'Orphan keys in app_hi.arb');
  });

  test('no translation is empty', () {
    final empty = [
      for (final k in enKeys)
        if ((en[k] as String).trim().isEmpty) 'en:$k',
      for (final k in hiKeys)
        if ((hi[k] as String).trim().isEmpty) 'hi:$k',
    ];
    expect(empty, isEmpty);
  });

  test('every placeholder declared in English is used in the Hindi text', () {
    final problems = <String>[];
    for (final k in enKeys) {
      final placeholders = (en['@$k'] as Map<String, dynamic>?)?['placeholders']
          as Map<String, dynamic>?;
      if (placeholders == null || !hiKeys.contains(k)) continue;
      for (final name in placeholders.keys) {
        if (!(hi[k] as String).contains('{$name')) {
          problems.add('$k is missing {$name} in Hindi');
        }
      }
    }
    expect(problems, isEmpty);
  });

  test('Hindi text uses 0-9, not Devanagari digits', () {
    final digits = RegExp(r'[०-९]');
    final bad = [
      for (final k in hiKeys)
        if (digits.hasMatch(hi[k] as String)) k,
    ];
    expect(bad, isEmpty);
  });

  test('generated localizations are up to date (run flutter gen-l10n)', () {
    for (final lang in ['en', 'hi']) {
      final generated =
          File('lib/l10n/app_localizations_$lang.dart').readAsStringSync();
      final stale = [
        for (final k in enKeys)
          if (!RegExp('\\b$k\\b').hasMatch(generated)) k,
      ];
      expect(stale, isEmpty,
          reason: 'app_localizations_$lang.dart is missing these keys');
    }
  });
}
