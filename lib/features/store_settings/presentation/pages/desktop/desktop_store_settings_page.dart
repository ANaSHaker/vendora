import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../cubit/store_settings_cubit.dart';
import '../../cubit/store_settings_state.dart';

class DesktopStoreSettingsPage extends StatelessWidget {
  const DesktopStoreSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StoreSettingsCubit(
        getStoreSettings: getIt(),
        updateStoreSettings: getIt(),
      )..load(),
      child: const _DesktopStoreSettingsContent(),
    );
  }
}

class _DesktopStoreSettingsContent extends StatelessWidget {
  const _DesktopStoreSettingsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return ColoredBox(
      color: bg,
      child: Column(
        children: [
          // Page header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.desktopContentPadding,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.t('storeSettings'),
                        style: AppTextStyles.h5.copyWith(color: fg)),
                    Text(l10n.t('storeSettingsSubtitle'),
                        style: AppTextStyles.bodySm.copyWith(color: muted)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: BlocConsumer<StoreSettingsCubit, StoreSettingsState>(
              listener: (context, state) {
                if (state is StoreSettingsLoaded && state.saveSuccess) {
                  AppSnackbar.success(context, l10n.t('settingsSaved'));
                }
              },
              builder: (context, state) {
                if (state is StoreSettingsLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: ShimmerTableRows(),
                  );
                }
                if (state is StoreSettingsError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<StoreSettingsCubit>().load(),
                  );
                }
                if (state is StoreSettingsLoaded) {
                  return _StoreSettingsForm(settings: state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreSettingsForm extends StatefulWidget {
  final StoreSettingsLoaded settings;
  const _StoreSettingsForm({required this.settings});

  @override
  State<_StoreSettingsForm> createState() => _StoreSettingsFormState();
}

class _StoreSettingsFormState extends State<_StoreSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _taxRateCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _whatsappCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.settings.settings;
    _nameCtrl = TextEditingController(text: s.storeName ?? '');
    _emailCtrl = TextEditingController(text: s.storeEmail ?? '');
    _phoneCtrl = TextEditingController(text: s.storePhone ?? '');
    _addressCtrl = TextEditingController(text: s.storeAddress ?? '');
    _currencyCtrl = TextEditingController(text: s.currency ?? '');
    _taxRateCtrl = TextEditingController(
        text: s.taxRate != null ? s.taxRate!.toString() : '');
    _websiteCtrl = TextEditingController(text: s.website ?? '');
    _instagramCtrl = TextEditingController(text: s.instagramHandle ?? '');
    _whatsappCtrl = TextEditingController(text: s.whatsappNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currencyCtrl.dispose();
    _taxRateCtrl.dispose();
    _websiteCtrl.dispose();
    _instagramCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{};
    if (_nameCtrl.text.isNotEmpty) data['name'] = _nameCtrl.text.trim();
    if (_emailCtrl.text.isNotEmpty) data['email'] = _emailCtrl.text.trim();
    if (_phoneCtrl.text.isNotEmpty) data['phone'] = _phoneCtrl.text.trim();
    if (_addressCtrl.text.isNotEmpty) data['address'] = _addressCtrl.text.trim();
    if (_currencyCtrl.text.isNotEmpty) data['currency'] = _currencyCtrl.text.trim();
    if (_taxRateCtrl.text.isNotEmpty) {
      data['tax_rate'] = double.tryParse(_taxRateCtrl.text.trim()) ?? 0;
    }
    if (_websiteCtrl.text.isNotEmpty) data['website'] = _websiteCtrl.text.trim();
    if (_instagramCtrl.text.isNotEmpty) {
      data['instagram'] = _instagramCtrl.text.trim();
    }
    if (_whatsappCtrl.text.isNotEmpty) {
      data['whatsapp'] = _whatsappCtrl.text.trim();
    }
    await context.read<StoreSettingsCubit>().save(data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaving = widget.settings.isSaving;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
      child: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: l10n.t('storeInfoSection'),
                isDark: isDark,
                fg: fg,
                children: [
                  _FieldRow(
                    label: l10n.t('labelStoreName'),
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: l10n.t('storeNameHint'),
                      ),
                    ),
                  ),
                  _FieldRow(
                    label: l10n.t('labelEmail'),
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  _FieldRow(
                    label: l10n.t('labelPhone'),
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  _FieldRow(
                    label: l10n.t('address'),
                    child: TextFormField(
                      controller: _addressCtrl,
                      minLines: 2,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: l10n.t('storeFinanceSection'),
                isDark: isDark,
                fg: fg,
                children: [
                  _FieldRow(
                    label: l10n.t('menuCurrency'),
                    child: TextFormField(
                      controller: _currencyCtrl,
                      decoration: const InputDecoration(hintText: 'SAR'),
                    ),
                  ),
                  _FieldRow(
                    label: l10n.t('taxRate'),
                    child: TextFormField(
                      controller: _taxRateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '15'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: l10n.t('storeSocialSection'),
                isDark: isDark,
                fg: fg,
                children: [
                  _FieldRow(
                    label: l10n.t('menuWebsite'),
                    child: TextFormField(
                      controller: _websiteCtrl,
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  _FieldRow(
                    label: l10n.t('menuInstagram'),
                    child: TextFormField(controller: _instagramCtrl),
                  ),
                  _FieldRow(
                    label: l10n.t('menuWhatsapp'),
                    child: TextFormField(
                      controller: _whatsappCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: isSaving ? null : _submit,
                    child: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.t('save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color fg;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.isDark,
    required this.fg,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Text(title,
                style: AppTextStyles.bodySm
                    .copyWith(color: fg, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(color: muted),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
