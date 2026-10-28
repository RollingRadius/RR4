import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/providers/locale_provider.dart';

/// Language picker. Deliberately bilingual and not localized: on first launch
/// no language has been chosen yet, so the dialog has to read in both.
/// [firstLaunch] makes it non-dismissible so a choice is always made.
Future<void> showLanguageDialog(
  BuildContext context, {
  bool firstLaunch = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !firstLaunch,
    builder: (_) => PopScope(
      canPop: !firstLaunch,
      child: const _LanguageDialog(),
    ),
  );
}

class _LanguageDialog extends ConsumerWidget {
  const _LanguageDialog();

  static const _options = [
    (locale: Locale('en'), label: 'English'),
    (locale: Locale('hi'), label: 'हिंदी'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Choose your language\nअपनी भाषा चुनें',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _options)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: current == option.locale
                          ? AppTheme.primaryBlue
                          : const Color(0xFFE2E0E0),
                      width: current == option.locale ? 2 : 1,
                    ),
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await ref
                        .read(localeProvider.notifier)
                        .setLocale(option.locale);
                    navigator.pop();
                  },
                  child: Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
