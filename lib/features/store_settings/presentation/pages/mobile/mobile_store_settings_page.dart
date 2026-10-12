import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../cubit/store_settings_cubit.dart';
import '../../cubit/store_settings_state.dart';

class MobileStoreSettingsPage extends StatelessWidget {
  const MobileStoreSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StoreSettingsCubit(
        getStoreSettings: getIt(),
        updateStoreSettings: getIt(),
      )..load(),
      child: const _MobileStoreSettingsContent(),
    );
  }
}

class _MobileStoreSettingsContent extends StatelessWidget {
  const _MobileStoreSettingsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('storeSettings'))),
      body: BlocConsumer<StoreSettingsCubit, StoreSettingsState>(
        listener: (context, state) {
          if (state is StoreSettingsLoaded && state.saveSuccess) {
            AppSnackbar.success(context, l10n.t('settingsSaved'));
          }
        },
        builder: (context, state) {
          if (state is StoreSettingsLoading) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
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
            return _MobileStoreSettingsForm(settings: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MobileStoreSettingsForm extends StatefulWidget {
  final StoreSettingsLoaded settings;
  const _MobileStoreSettingsForm({required this.settings});

  @override
  State<_MobileStoreSettingsForm> createState() =>
      _MobileStoreSettingsFormState();
}

class _MobileStoreSettingsFormState extends State<_MobileStoreSettingsForm> {
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
    final isSaving = widget.settings.isSaving;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionHeader(title: l10n.t('storeInfoSection')),
          _MobileField(
            label: l10n.t('labelStoreName'),
            controller: _nameCtrl,
            hint: l10n.t('storeNameHint'),
          ),
          _MobileField(
            label: l10n.t('labelEmail'),
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          _MobileField(
            label: l10n.t('labelPhone'),
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          _MobileField(
            label: l10n.t('address'),
            controller: _addressCtrl,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(title: l10n.t('storeFinanceSection')),
          _MobileField(
            label: l10n.t('menuCurrency'),
            controller: _currencyCtrl,
            hint: 'SAR',
          ),
          _MobileField(
            label: l10n.t('taxRate'),
            controller: _taxRateCtrl,
            keyboardType: TextInputType.number,
            hint: '15',
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(title: l10n.t('storeSocialSection')),
          _MobileField(
            label: l10n.t('menuWebsite'),
            controller: _websiteCtrl,
            keyboardType: TextInputType.url,
          ),
          _MobileField(
            label: l10n.t('menuInstagram'),
            controller: _instagramCtrl,
          ),
          _MobileField(
            label: l10n.t('menuWhatsapp'),
            controller: _whatsappCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: isSaving ? null : _submit,
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.t('save')),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.bodySm
            .copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MobileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hint;
  final int? minLines;
  final int? maxLines;

  const _MobileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.hint,
    this.minLines,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyXs.copyWith(color: muted)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines ?? 1,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
