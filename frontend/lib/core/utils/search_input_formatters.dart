import 'package:flutter/services.dart';

/// Input rules for the RR typeahead searches (security audit V-12 follow-up).
/// The server cleans the same way, so old APKs and programmatic searches
/// (e.g. a place name picked from address suggestions) are covered too.

/// City search: letters in any language (Hindi included, with its vowel
/// signs), spaces, "-" and "." (e.g. "Pimpri-Chinchwad", "S.A.S. Nagar").
final List<TextInputFormatter> cityNameInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[\p{L}\p{M} .\-]', unicode: true)),
  LengthLimitingTextInputFormatter(50),
];

/// Vehicle RC search: capitals A-Z and digits only, at most 12 (e.g. "UP78AB1234").
final List<TextInputFormatter> rcNumberInputFormatters = [
  const _UpperCaseFormatter(),
  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
  LengthLimitingTextInputFormatter(12),
];

class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
