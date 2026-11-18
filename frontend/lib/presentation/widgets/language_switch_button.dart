import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleet_management/presentation/widgets/language_dialog.dart';
import 'package:fleet_management/providers/locale_provider.dart';

/// Small top-right language switch for the login page and every dashboard.
/// Shows the current language ("EN" / "हि") and opens the same picker as the
/// first-launch dialog and Settings (dismissible here). The tooltip is
/// bilingual on purpose, like the picker itself, so it reads in either language.
class LanguageSwitchButton extends ConsumerWidget {
  final Color color;

  const LanguageSwitchButton({super.key, this.color = const Color(0xFF546067)});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(localeProvider)?.languageCode == 'hi';
    return Tooltip(
      message: 'Language / भाषा',
      child: InkWell(
        key: const Key('languageSwitchButton'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => showLanguageDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded, color: color, size: 20),
              const SizedBox(width: 4),
              Text(
                isHindi ? 'हि' : 'EN',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
