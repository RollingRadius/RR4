import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hindi texts are usually longer than English. A text that is much longer can
/// overflow a button, tab or chip. This test reads only the ARB files:
///  - ratio above [_warnRatio]: printed as a warning, the test still passes;
///  - ratio above [_failRatio]: the test fails, unless the key is in [_skip].
/// Fix a failure by shortening the Hindi, or add the key to [_skip] with the
/// reason it is safe (for example "sits in a full-width paragraph").
const double _warnRatio = 1.6;
const double _failRatio = 3.0;

/// English texts shorter than this are ignored: "OK" vs a longer Hindi word
/// gives a big ratio but a tiny absolute difference.
const int _minEnglishLength = 10;

/// key -> reason it is safe. Skipped keys give no warning and cannot fail.
const Map<String, String> _skip = {};

Map<String, dynamic> _arb(String file) =>
    jsonDecode(File('lib/l10n/$file').readAsStringSync())
        as Map<String, dynamic>;

/// The text as shown: placeholders count as two digits, and a plural or select
/// counts as its longest branch.
String _shown(String message) {
  var text = message;
  if (RegExp(r'^\{\w+,\s*(plural|select)\s*,').hasMatch(text.trim())) {
    final branches = RegExp(r'\w+\{((?:[^{}]|\{[^{}]*\})*)\}')
        .allMatches(text.substring(text.indexOf(',', text.indexOf(',') + 1) + 1))
        .map((m) => m.group(1)!)
        .toList();
    if (branches.isNotEmpty) {
      text = branches.reduce((a, b) => a.length >= b.length ? a : b);
    }
  }
  return text.replaceAll(RegExp(r'\{[^{}]*\}'), '00').trim();
}

void main() {
  final en = _arb('app_en.arb');
  final hi = _arb('app_hi.arb');

  final ratios = <String, double>{};
  for (final key in en.keys) {
    if (key.startsWith('@') || !hi.containsKey(key)) continue;
    final english = _shown(en[key] as String);
    final hindi = _shown(hi[key] as String);
    if (english.length < _minEnglishLength) continue;
    ratios[key] = hindi.length / english.length;
  }

  test('Hindi texts are not far longer than English (warn ${_warnRatio}x, '
      'fail ${_failRatio}x)', () {
    final warnings = ratios.entries
        .where((e) => e.value > _warnRatio && !_skip.containsKey(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (warnings.isNotEmpty) {
      // ignore: avoid_print
      print('WARNING: ${warnings.length} Hindi text(s) are more than '
          '${_warnRatio}x the English length (check them on a small phone):\n'
          '${warnings.map((e) => '  ${e.value.toStringAsFixed(2)}x  ${e.key}').join('\n')}');
    }

    final tooLong = warnings.where((e) => e.value > _failRatio).toList();
    expect(tooLong, isEmpty,
        reason: 'Hindi is more than ${_failRatio}x the English length. '
            'Shorten the Hindi, or add the key to _skip with a reason:\n'
            '${tooLong.map((e) => '  ${e.value.toStringAsFixed(2)}x  ${e.key}').join('\n')}');
  });

  test('the skip list has no old or unneeded entries', () {
    final stale = _skip.keys.where((k) => !en.containsKey(k)).toList();
    expect(stale, isEmpty,
        reason: 'These skipped keys no longer exist in app_en.arb:\n'
            '${stale.join('\n')}');
    final unneeded = _skip.keys
        .where((k) => (ratios[k] ?? 0) <= _warnRatio)
        .toList();
    expect(unneeded, isEmpty,
        reason: 'These skipped keys are no longer long (remove them):\n'
            '${unneeded.join('\n')}');
  });
}
