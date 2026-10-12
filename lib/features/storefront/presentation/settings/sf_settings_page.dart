import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/usecases/sf_usecases.dart';
import '../theme/sf_theme_data.dart';
import '../theme/sf_themes.dart';
import 'sf_settings_cubit.dart';

class SfSettingsPage extends StatelessWidget {
  const SfSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SfSettingsCubit(
        getSettings:    getIt<GetStorefrontSettingsUseCase>(),
        updateSettings: getIt<UpdateStorefrontSettingsUseCase>(),
      )..load(),
      child: const _SfSettingsView(),
    );
  }
}

class _SfSettingsView extends StatelessWidget {
  const _SfSettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<SfSettingsCubit, SfSettingsState>(
      listener: (ctx, state) {
        if (state is SfSettingsLoaded && state.saveSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(l10n.t('settingsSaved')),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (ctx, state) {
        if (state is SfSettingsLoading || state is SfSettingsInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SfSettingsError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            const Text('Could not load settings'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ctx.read<SfSettingsCubit>().load(),
              child: const Text('Retry'),
            ),
          ]));
        }

        final loaded = state as SfSettingsLoaded;
        final vendor = loaded.vendor;
        final isWide = MediaQuery.sizeOf(context).width >= 900;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48 : 16, vertical: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ───────────────────────────────────────────────────────
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.sfStoreSettings,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                if (vendor.slug.isNotEmpty)
                  SelectableText('/store/${vendor.slug}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ])),
              if (loaded.isSaving)
                const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ]),

            // ── Backend warning (soft, non-blocking) ─────────────────────────
            if (loaded.errorMessage != null && !loaded.isSaving && !loaded.saveSuccess) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Changes saved locally. Connect backend to persist across devices.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 24),

            // ── 1. Activate Store ─────────────────────────────────────────────
            _Section(
              title: l10n.sfStoreActive,
              child: SwitchListTile(
                value: vendor.isActive,
                onChanged: (v) =>
                    ctx.read<SfSettingsCubit>().save(isActive: v),
                title: Text(l10n.sfStoreActive),
                subtitle: Text(
                  vendor.isActive ? l10n.sfStoreActiveOn : l10n.sfStoreActiveOff,
                  style: TextStyle(
                    color: vendor.isActive
                        ? Colors.green.shade700
                        : Colors.red.shade400,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 2. Dark Mode ──────────────────────────────────────────────────
            _Section(
              title: l10n.sfDarkMode,
              child: SwitchListTile(
                value: vendor.darkMode,
                onChanged: (v) =>
                    ctx.read<SfSettingsCubit>().save(darkMode: v),
                title: Text(l10n.sfDarkMode),
                subtitle: Text(
                  vendor.darkMode ? l10n.sfDarkModeOn : l10n.sfDarkModeOff,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 3. Theme Picker ───────────────────────────────────────────────
            _Section(
              title: l10n.sfTheme,
              child: _ThemePicker(
                currentTheme: vendor.storeTheme,
                darkMode: vendor.darkMode,
                onSelect: (id) => ctx.read<SfSettingsCubit>().save(theme: id),
              ),
            ),
            const SizedBox(height: 24),

            // ── 4. Reservations ───────────────────────────────────────────────
            _Section(
              title: l10n.sfReservationsSection,
              child: SwitchListTile(
                value: vendor.reservationsEnabled,
                onChanged: (v) =>
                    ctx.read<SfSettingsCubit>().save(reservationsEnabled: v),
                title: Text(l10n.sfEnableReservations),
                subtitle: Text(
                  vendor.reservationsEnabled
                      ? l10n.sfReservationsOn
                      : l10n.sfReservationsOff,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 5. Store URL ──────────────────────────────────────────────────
            _Section(
              title: l10n.sfStoreUrl,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: SelectableText(
                    '/store/${vendor.slug}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  )),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: '/store/${vendor.slug}'));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    tooltip: l10n.sfPreviewStore,
                    onPressed: vendor.slug.isNotEmpty
                        ? () => ctx.go('/store/${vendor.slug}')
                        : null,
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ── Theme Picker ──────────────────────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  final String currentTheme;
  final bool darkMode;
  final ValueChanged<String> onSelect;
  const _ThemePicker(
      {required this.currentTheme, required this.darkMode, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: SfThemes.all.length,
        itemBuilder: (_, i) {
          final theme  = SfThemes.all[i];
          final id     = theme.id;
          final data   = darkMode ? theme.dark : theme.light;
          final active = id == currentTheme;

          return GestureDetector(
            onTap: () => onSelect(id),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? data.primary : Colors.grey.shade300,
                  width: active ? 2.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _ThemePreview(data: data, id: id, active: active),
            ),
          );
        },
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final SfThemeData data;
  final String id;
  final bool active;
  const _ThemePreview(
      {required this.data, required this.id, required this.active});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        color: data.background,
        child: Column(children: [
          // Nav bar preview
          Container(
            height: 12,
            color: data.surface,
            child: Row(children: [
              const SizedBox(width: 6),
              Container(
                  width: 20, height: 5,
                  color: data.primary,
                  margin: const EdgeInsets.only(top: 3)),
              const Spacer(),
              Container(
                  width: 8, height: 5,
                  color: data.primary.withAlpha(100),
                  margin: const EdgeInsets.only(top: 3, right: 4)),
            ]),
          ),
          // Hero
          Container(
            height: 28,
            decoration: BoxDecoration(
              gradient: data.heroGradient ??
                  LinearGradient(colors: [data.primary, data.accent]),
            ),
            child: Center(child: Container(
              height: 5, width: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(2)),
            )),
          ),
          // Cards row
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                for (int j = 0; j < 3; j++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Container(
                        decoration: BoxDecoration(
                          color: data.surface,
                          borderRadius:
                              BorderRadius.circular(data.radius / 4),
                          border: data.cardStyle == SfCardStyle.outlined
                              ? Border.all(color: data.border)
                              : null,
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ]),
      ),
      // Label + checkmark
      Positioned(
        bottom: 4, left: 6, right: 6,
        child: Row(children: [
          Expanded(child: Text(id,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: data.text))),
          if (active)
            Container(
              width: 14, height: 14,
              decoration:
                  BoxDecoration(color: data.primary, shape: BoxShape.circle),
              child:
                  const Icon(Icons.check, size: 9, color: Colors.white),
            ),
        ]),
      ),
    ]);
  }
}

// ── Section container ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: Colors.grey)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      ),
    ],
  );
}
