import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/providers/locale_provider.dart';

/// Language picker (splash on first launch, Settings, and the language button on the login page and dashboards).
/// Deliberately bilingual and not localized: on first launch no language has been chosen yet, so it reads in both.
/// [firstLaunch] makes it non-dismissible so a choice is always made.
///
/// Rules (user, 2026-11-21): shown after the splash only while no language is saved - a first download, a reinstall
/// (Android backup is off, so nothing is restored) or users updating from before the Hindi version (asked once);
/// never again after a choice. First launch / reinstall: nothing pre-selected and the user MUST pick - Continue without
/// a pick shakes the card and asks to choose (nothing saved; closing the app asks again next time). Opened later: the
/// saved language is pre-selected and the dialog can be closed.
Future<void> showLanguageDialog(
  BuildContext context, {
  bool firstLaunch = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    // Taps outside the card and Back are handled by the dialog itself: first launch -> shake + message, later -> close.
    barrierDismissible: false,
    barrierLabel: 'language',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => _LanguageDialog(firstLaunch: firstLaunch),
    // Pops in: fades and grows slightly, settling with a soft overshoot.
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
        child: child,
      ),
    ),
  );
}

class _LanguageDialog extends ConsumerStatefulWidget {
  final bool firstLaunch;
  const _LanguageDialog({required this.firstLaunch});

  @override
  ConsumerState<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends ConsumerState<_LanguageDialog> with SingleTickerProviderStateMixin {
  static const _options = [
    (locale: Locale('en'), badge: 'A', label: 'English', sample: 'Continue in English'),
    (locale: Locale('hi'), badge: 'अ', label: 'हिंदी', sample: 'हिंदी में जारी रखें'),
  ];

  /// First launch / reinstall: nothing pre-selected - the user must pick. Opened later: the saved language.
  late Locale? _selected = ref.read(localeProvider);
  bool _saving = false;

  /// The message shown inside the dialog after a nudge (null = none).
  String? _nudgeMsg;
  static const _pickMsg = 'Please choose a language · कृपया एक भाषा चुनें';
  static const _pressContinueMsg = 'Press Continue to go on · आगे बढ़ने के लिए जारी रखें दबाएं';

  /// Side-to-side shake of the card (on screen only, no phone vibration).
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Shake the card side to side and show [msg] inside the dialog.
  void _nudge(String msg) {
    setState(() => _nudgeMsg = msg);
    _shake.forward(from: 0);
  }

  /// A tap outside the card or Back: first launch / reinstall -> nudge (the user must pick and press Continue);
  /// opened later -> close, changing nothing (user, 2026-11-21).
  void _tryToLeave() {
    if (_saving) return;
    if (widget.firstLaunch) {
      _nudge(_selected == null ? _pickMsg : _pressContinueMsg);
    } else {
      Navigator.of(context).pop();
    }
  }

  /// No pick yet -> the card shakes and asks to choose; nothing is saved (user, 2026-11-21, option A).
  Future<void> _continue() async {
    final choice = _selected;
    if (choice == null) {
      _nudge(_pickMsg);
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    await ref.read(localeProvider.notifier).setLocale(choice);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _tryToLeave(); // Back button
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tryToLeave, // a tap outside the card
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _shake,
              // 3 swings left-right, fading out: sin(t * 6pi) * 12px * (1 - t)
              builder: (_, child) => Transform.translate(
                offset: Offset(math.sin(_shake.value * math.pi * 6) * 12 * (1 - _shake.value), 0),
                child: child,
              ),
              // Taps on the card itself never count as "outside".
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Material(
                  color: Colors.white,
                  elevation: 12,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          const Spacer(),
                          Image.asset('assest/images/app-logo-bgremoved.png', width: 64, height: 64),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: widget.firstLaunch
                                  ? const SizedBox.shrink()
                                  : IconButton(
                                      tooltip: 'Close · बंद करें',
                                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        const Text('Choose your language',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        const Text('अपनी भाषा चुनें',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        const SizedBox(height: 18),
                        for (final o in _options) ...[
                          _OptionCard(
                            badge: o.badge,
                            label: o.label,
                            sample: o.sample,
                            selected: _selected == o.locale,
                            onTap: _saving
                                ? null
                                : () => setState(() {
                                      _selected = o.locale;
                                      _nudgeMsg = null;
                                    }),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Shown after a nudge: Continue without a pick, a tap outside or Back (first launch / reinstall).
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _nudgeMsg != null
                              ? Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF4E5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFB74D)),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.touch_app_rounded, size: 18, color: Color(0xFFE65100)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(_nudgeMsg!,
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                                    ),
                                  ]),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _saving ? null : _continue,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Continue · जारी रखें',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('You can change this any time · इसे कभी भी बदल सकते हैं',
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String badge;
  final String label;
  final String sample;
  final bool selected;
  final VoidCallback? onTap;

  const _OptionCard(
      {required this.badge, required this.label, required this.sample, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppTheme.primaryBlue.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppTheme.primaryBlue : const Color(0xFFE2E0E0),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppTheme.primaryBlue : const Color(0xFFF1F3F5),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppTheme.textPrimary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(sample, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ]),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: selected ? 1 : 0,
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 24),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
