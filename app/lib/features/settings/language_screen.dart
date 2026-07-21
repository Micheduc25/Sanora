import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/l10n/locale_controller.dart';
import '../../core/widgets/sanora_card.dart';
import '../../l10n/app_localizations.dart';

/// Language is a device preference, not part of the health profile — someone
/// restoring onto a French phone should get French before anything syncs.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final selected = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsLanguage)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            l.settingsLanguageSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SanoraCard(
            padding: EdgeInsets.zero,
            // Empty string stands for "follow the device" so the radio group
            // has a non-null value to compare against.
            child: RadioGroup<String>(
              groupValue: selected?.languageCode ?? '',
              onChanged: (code) => controller.set(
                code == null || code.isEmpty ? null : Locale(code),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: '',
                    title: Text(l.languageSystem),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    value: 'en',
                    title: Text(l.languageEnglish),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    value: 'fr',
                    title: Text(l.languageFrench),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
