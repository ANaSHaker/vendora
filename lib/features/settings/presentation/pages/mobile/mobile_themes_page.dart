import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../widgets/theme_picker_dialog.dart';

class MobileThemesPage extends StatelessWidget {
  const MobileThemesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appearance),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.palette_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(l10n.appearance,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                l10n.livePreviewHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ThemePickerDialog.show(context),
                icon: const Icon(Icons.tune_rounded),
                label: Text(l10n.t('customizeTheme')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
