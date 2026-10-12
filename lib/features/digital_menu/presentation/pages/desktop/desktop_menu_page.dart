import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../features/products/domain/usecases/products_usecases.dart';
import '../../../domain/entities/menu_entities.dart';
import '../../../domain/usecases/menu_usecases.dart';
import '../../cubit/menu_cubit.dart';
import '../../cubit/menu_state.dart';
import '../public/web_img_stub.dart' if (dart.library.js_interop) '../public/web_img_web.dart';

class DesktopMenuPage extends StatelessWidget {
  const DesktopMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MenuCubit(
        getSettings: getIt<GetMenuSettingsUseCase>(),
        getProductConfigs: getIt<GetMenuProductConfigsUseCase>(),
        saveSettings: getIt<SaveMenuSettingsUseCase>(),
        saveProductConfigs: getIt<SaveMenuProductConfigsUseCase>(),
        uploadLogo: getIt<UploadMenuLogoUseCase>(),
        getProducts: getIt<GetProductsUseCase>(),
        secureStorage: getIt<SecureStorage>(),
      )..load(),
      child: const _DesktopMenuView(),
    );
  }
}

class _DesktopMenuView extends StatefulWidget {
  const _DesktopMenuView();

  @override
  State<_DesktopMenuView> createState() => _DesktopMenuViewState();
}

class _DesktopMenuViewState extends State<_DesktopMenuView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _publicUrl(MenuSettings s) {
    if (kIsWeb) {
      final base = Uri.base;
      final port = base.port != 80 && base.port != 443 ? ':${base.port}' : '';
      // Flutter web uses hash routing — path must come after /#/
      return '${base.scheme}://${base.host}$port/#/menu/${s.slug}';
    }
    return 'http://localhost/#/menu/${s.slug}';
  }

  void _showPdfDesignPicker(BuildContext context, MenuSettings settings, List<MenuProductConfig> products) {
    showDialog(
      context: context,
      builder: (_) => _PdfDesignPickerDialog(settings: settings, products: products),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<MenuCubit, MenuState>(
      listener: (context, state) {
        if (state is MenuLoaded && state.isSaved) {
          AppSnackbar.success(context, l10n.t('menuSaved'));
        }
        if (state is MenuLoaded && state.error != null) {
          AppSnackbar.error(context, state.error!);
        }
      },
      builder: (context, state) {
        if (state is MenuLoading || state is MenuInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is MenuError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 16),
                  AppButton(
                    label: l10n.t('retry'),
                    onPressed: () => context.read<MenuCubit>().load(),
                  ),
                ],
              ),
            ),
          );
        }

        final loaded = state as MenuLoaded;
        final settings = loaded.settings;
        final products = loaded.products;
        final cubit = context.read<MenuCubit>();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _PageHeader(settings: settings, loaded: loaded, cubit: cubit),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Editor Panel (55%) ────────────────────────────────
                    Expanded(
                      flex: 55,
                      child: Column(
                        children: [
                          _EditorTabBar(tabs: _tabs, l10n: l10n),
                          Expanded(
                            child: TabBarView(
                              controller: _tabs,
                              children: [
                                _AppearanceTab(settings: settings, cubit: cubit),
                                _InfoTab(settings: settings, cubit: cubit, l10n: l10n),
                                _ProductsTab(products: products, settings: settings, cubit: cubit, l10n: l10n),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ─── Preview Panel (45%) ───────────────────────────────
                    Container(width: 1, color: AppColors.border),
                    Expanded(
                      flex: 45,
                      child: _PreviewPanel(
                        settings: settings,
                        products: products,
                        previewKey: _previewKey,
                        publicUrl: _publicUrl(settings),
                        onDownloadPdf: () =>
                            _showPdfDesignPicker(context, settings, products),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final MenuSettings settings;
  final MenuLoaded loaded;
  final MenuCubit cubit;

  const _PageHeader({required this.settings, required this.loaded, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.t('digitalMenu'), style: AppTextStyles.h5),
          const Spacer(),
          if (loaded.isSaved)
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
              const SizedBox(width: 4),
              Text(l10n.t('menuSaved'), style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              const SizedBox(width: AppSpacing.md),
            ]),
          AppButton(
            label: l10n.t('save'),
            isLoading: loaded.isSaving,
            onPressed: () => cubit.save(),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Bar ──────────────────────────────────────────────────────────────────

class _EditorTabBar extends StatelessWidget {
  final TabController tabs;
  final AppLocalizations l10n;

  const _EditorTabBar({required this.tabs, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: tabs,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.mutedForeground,
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(icon: const Icon(Icons.palette_rounded, size: 18), text: l10n.t('menuAppearance')),
          Tab(icon: const Icon(Icons.info_outline_rounded, size: 18), text: l10n.t('menuInfo')),
          Tab(icon: const Icon(Icons.fastfood_rounded, size: 18), text: l10n.t('menuProducts')),
        ],
      ),
    );
  }
}

// ─── Tab 1: Appearance ────────────────────────────────────────────────────────

class _AppearanceTab extends StatelessWidget {
  final MenuSettings settings;
  final MenuCubit cubit;

  const _AppearanceTab({required this.settings, required this.cubit});

  static const _themeData = [
    (id: 1, icon: Icons.grid_view_rounded, key: 'menuThemeModernGrid'),
    (id: 2, icon: Icons.format_list_bulleted_rounded, key: 'menuThemeClassicList'),
    (id: 3, icon: Icons.nights_stay_rounded, key: 'menuThemeDarkLuxury'),
    (id: 4, icon: Icons.text_fields_rounded, key: 'menuThemeMinimal'),
    (id: 5, icon: Icons.newspaper_rounded, key: 'menuThemeMagazine'),
    (id: 6, icon: Icons.campaign_rounded, key: 'menuThemeFlyer'),
    (id: 7, icon: Icons.view_agenda_rounded, key: 'menuThemeBillboard'),
    (id: 8, icon: Icons.style_rounded, key: 'menuThemeElegant'),
  ];

  static const _primaryPresets = [
    Color(0xFF0C2461), Color(0xFF1E3A8A), Color(0xFF7C3AED),
    Color(0xFFDC2626), Color(0xFF16A34A), Color(0xFFD97706),
    Color(0xFF0891B2), Color(0xFFDB2777), Color(0xFF374151), Color(0xFF000000),
  ];

  static const _bgPresets = [
    Color(0xFFFFFFFF), Color(0xFFF8F9FA), Color(0xFFFFF8F0),
    Color(0xFFF0FFF4), Color(0xFFF0F4FF), Color(0xFFFFF0F6),
  ];

  Color get _primaryColor {
    final hex = settings.primaryColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color get _bgColor {
    final hex = settings.backgroundColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _toHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Theme cards
        Text(l10n.t('menuDesign'), style: AppTextStyles.labelMd),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _themeData.map((t) {
            final selected = settings.themeId == t.id;
            return GestureDetector(
              onTap: () => cubit.updateSettings((s) => s.copyWith(themeId: t.id)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryMuted : AppColors.muted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon,
                        color: selected
                            ? AppColors.primary
                            : AppColors.mutedForeground,
                        size: 24),
                    const SizedBox(height: 4),
                    Text(l10n.t(t.key),
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? AppColors.primary
                              : AppColors.mutedForeground,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Primary color
        Text(l10n.t('menuPrimaryColor'), style: AppTextStyles.labelMd),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _primaryPresets.map((c) {
            final selected = _primaryColor.value == c.value;
            return GestureDetector(
              onTap: () =>
                  cubit.updateSettings((s) => s.copyWith(primaryColor: _toHex(c))),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.foreground : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)]
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Background color
        Text(l10n.t('menuBgColor'), style: AppTextStyles.labelMd),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bgPresets.map((c) {
            final selected = _bgColor.value == c.value;
            return GestureDetector(
              onTap: () =>
                  cubit.updateSettings((s) => s.copyWith(backgroundColor: _toHex(c))),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, color: AppColors.primary, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Logo
        Text(l10n.t('menuLogo'), style: AppTextStyles.labelMd),
        const SizedBox(height: AppSpacing.sm),
        _LogoPicker(settings: settings, cubit: cubit),
      ],
    );
  }
}

class _LogoPicker extends StatelessWidget {
  final MenuSettings settings;
  final MenuCubit cubit;

  const _LogoPicker({required this.settings, required this.cubit});

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    final ext = (file.extension ?? 'jpg').toLowerCase();
    if (!context.mounted) return;
    cubit.uploadLogo(file.bytes!, ext);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuCubit, MenuState>(
      builder: (context, state) {
        final loaded = state as MenuLoaded;
        return Row(
          children: [
            // Preview
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: loaded.isUploadingLogo
                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                  : loaded.settings.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: buildWebImg(loaded.settings.logoUrl!, BoxFit.cover, null))
                      : const Icon(Icons.add_photo_alternate_rounded,
                          color: AppColors.mutedForeground, size: 32),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppButton(
                  label: loaded.settings.logoUrl != null
                      ? AppLocalizations.of(context).t('menuChangeLogo')
                      : AppLocalizations.of(context).t('menuUploadLogo'),
                  variant: AppButtonVariant.outline,
                  leading: const Icon(Icons.upload_rounded, size: 16),
                  onPressed: () => _pick(context),
                ),
                if (loaded.settings.logoUrl != null) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: cubit.removeLogo,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.destructive, size: 16),
                    label: Text(AppLocalizations.of(context).t('menuRemoveLogo'),
                        style: const TextStyle(color: AppColors.destructive, fontSize: 13)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─── Tab 2: Info ──────────────────────────────────────────────────────────────

class _InfoTab extends StatefulWidget {
  final MenuSettings settings;
  final MenuCubit cubit;
  final AppLocalizations l10n;

  const _InfoTab({required this.settings, required this.cubit, required this.l10n});

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _instaCtrl;
  late final TextEditingController _waCtrl;
  late final TextEditingController _fbCtrl;
  late final TextEditingController _snapCtrl;
  late final TextEditingController _webCtrl;
  late final TextEditingController _currencyCtrl;
  late List<TextEditingController> _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _nameCtrl = TextEditingController(text: s.menuName);
    _slugCtrl = TextEditingController(text: s.slug);
    _descCtrl = TextEditingController(text: s.description ?? '');
    _addressCtrl = TextEditingController(text: s.address ?? '');
    _instaCtrl = TextEditingController(text: s.instagramUrl ?? '');
    _waCtrl = TextEditingController(text: s.whatsappNumber ?? '');
    _fbCtrl = TextEditingController(text: s.facebookUrl ?? '');
    _snapCtrl = TextEditingController(text: s.snapchatUrl ?? '');
    _webCtrl = TextEditingController(text: s.websiteUrl ?? '');
    _currencyCtrl = TextEditingController(text: s.currency);
    _phoneCtrl = s.phones.isEmpty
        ? [TextEditingController()]
        : s.phones.map((p) => TextEditingController(text: p)).toList();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _slugCtrl, _descCtrl, _addressCtrl,
          _instaCtrl, _waCtrl, _fbCtrl, _snapCtrl, _webCtrl,
          _currencyCtrl, ..._phoneCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _flush() {
    widget.cubit.updateSettings((s) => s.copyWith(
          menuName: _nameCtrl.text.trim(),
          slug: _slugCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '-'),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          instagramUrl: _instaCtrl.text.trim().isEmpty ? null : _instaCtrl.text.trim(),
          whatsappNumber: _waCtrl.text.trim().isEmpty ? null : _waCtrl.text.trim(),
          facebookUrl: _fbCtrl.text.trim().isEmpty ? null : _fbCtrl.text.trim(),
          snapchatUrl: _snapCtrl.text.trim().isEmpty ? null : _snapCtrl.text.trim(),
          websiteUrl: _webCtrl.text.trim().isEmpty ? null : _webCtrl.text.trim(),
          currency: _currencyCtrl.text.trim().isEmpty ? 'EGP' : _currencyCtrl.text.trim(),
          phones: _phoneCtrl.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _field(label: widget.l10n.t('menuName'), ctrl: _nameCtrl,
            hint: 'My Restaurant', onChanged: (_) => _flush()),
        _field(label: widget.l10n.t('menuSlug'), ctrl: _slugCtrl,
            hint: 'my-restaurant', onChanged: (_) => _flush(),
            helper: '/menu/your-slug'),
        _field(label: widget.l10n.t('menuDescription'), ctrl: _descCtrl,
            hint: '', onChanged: (_) => _flush(),
            maxLines: 3),
        _field(label: widget.l10n.t('menuAddress'), ctrl: _addressCtrl,
            hint: '', onChanged: (_) => _flush()),
        _field(label: widget.l10n.t('menuCurrency'), ctrl: _currencyCtrl,
            hint: 'EGP', onChanged: (_) => _flush()),
        const SizedBox(height: AppSpacing.md),
        // Phones
        Text(widget.l10n.t('menuPhones'), style: AppTextStyles.labelMd),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(_phoneCtrl.length, (i) => Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl[i],
                decoration: InputDecoration(
                  hintText: '+20 100 000 0000',
                  prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => _flush(),
              ),
            ),
            if (_phoneCtrl.length > 1) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _phoneCtrl[i].dispose();
                  setState(() => _phoneCtrl.removeAt(i));
                  _flush();
                },
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.destructive),
              ),
            ],
          ],
        ).let((w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w))),
        TextButton.icon(
          onPressed: () => setState(() => _phoneCtrl.add(TextEditingController())),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(widget.l10n.t('add')),
        ),
        const SizedBox(height: AppSpacing.md),
        // Social
        _field(label: widget.l10n.t('menuInstagram'), ctrl: _instaCtrl,
            hint: '@yourhandle', onChanged: (_) => _flush(),
            prefixIcon: Icons.camera_alt_rounded),
        _field(label: widget.l10n.t('menuWhatsapp'), ctrl: _waCtrl,
            hint: '+20 100 000 0000', onChanged: (_) => _flush(),
            prefixIcon: Icons.chat_rounded),
        _field(label: widget.l10n.t('menuFacebook'), ctrl: _fbCtrl,
            hint: 'https://facebook.com/yourpage', onChanged: (_) => _flush(),
            prefixIcon: Icons.facebook_rounded),
        _field(label: widget.l10n.t('menuSnapchat'), ctrl: _snapCtrl,
            hint: '@yoursnapchat', onChanged: (_) => _flush(),
            prefixIcon: Icons.camera_rounded),
        _field(label: widget.l10n.t('menuWebsite'), ctrl: _webCtrl,
            hint: 'https://yourwebsite.com', onChanged: (_) => _flush(),
            prefixIcon: Icons.language_rounded),
        const SizedBox(height: AppSpacing.md),
        // Show prices toggle
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.l10n.t('menuShowPrices'), style: AppTextStyles.labelMd),
                  Text(widget.l10n.t('menuShowPricesHint'),
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground)),
                ],
              ),
            ),
            Switch(
              value: widget.settings.showPrices,
              onChanged: (v) =>
                  widget.cubit.updateSettings((s) => s.copyWith(showPrices: v)),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required void Function(String) onChanged,
    String? helper,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelMd),
          const SizedBox(height: 4),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.subtleForeground),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 18)
                  : null,
              helperText: helper,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

// ─── Tab 3: Products ──────────────────────────────────────────────────────────

class _ProductsTab extends StatefulWidget {
  final List<MenuProductConfig> products;
  final MenuSettings settings;
  final MenuCubit cubit;
  final AppLocalizations l10n;

  const _ProductsTab({
    required this.products, required this.settings,
    required this.cubit, required this.l10n,
  });

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final _priceControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _priceControllers.values) c.dispose();
    super.dispose();
  }

  TextEditingController _ctrl(MenuProductConfig p) {
    return _priceControllers.putIfAbsent(
      p.productId,
      () => TextEditingController(
        text: p.menuPrice != null ? p.menuPrice!.toStringAsFixed(2) : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;

    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fastfood_rounded, size: 48, color: AppColors.mutedForeground),
            SizedBox(height: 12),
            Text('No products found', style: TextStyle(color: AppColors.mutedForeground)),
          ],
        ),
      );
    }

    // Group by category
    final grouped = <String, List<MenuProductConfig>>{};
    for (final p in products) {
      (grouped[p.categoryName ?? 'Uncategorized'] ??= []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Header
        Row(
          children: [
            const SizedBox(width: 48),
            Expanded(child: Text(widget.l10n.t('menuProducts'), style: AppTextStyles.labelMd)),
            const SizedBox(width: 8),
            SizedBox(width: 90, child: Text(widget.l10n.t('menuOriginalPrice'), style: AppTextStyles.labelMd, textAlign: TextAlign.end)),
            const SizedBox(width: 8),
            SizedBox(width: 110, child: Text(widget.l10n.t('menuOverridePrice'), style: AppTextStyles.labelMd, textAlign: TextAlign.center)),
            const SizedBox(width: 48),
          ],
        ),
        const Divider(height: 16),
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              entry.key,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
            ),
          ),
          ...entry.value.map((p) => _ProductRow(
                product: p,
                cubit: widget.cubit,
                priceCtrl: _ctrl(p),
                settings: widget.settings,
              )),
        ],
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final MenuProductConfig product;
  final MenuCubit cubit;
  final TextEditingController priceCtrl;
  final MenuSettings settings;

  const _ProductRow({
    required this.product,
    required this.cubit,
    required this.priceCtrl,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Visibility toggle
          SizedBox(
            width: 48,
            child: Switch(
              value: product.isVisible,
              onChanged: (_) => cubit.toggleProduct(product.productId),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          // Thumb
          product.productImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 36, height: 36,
                    child: buildWebImg(product.productImage!, BoxFit.cover, const _ProdPlaceholder()),
                  ))
              : const _ProdPlaceholder(),
          const SizedBox(width: 8),
          // Name
          Expanded(
            child: Opacity(
              opacity: product.isVisible ? 1 : 0.4,
              child: Text(product.productName,
                  style: AppTextStyles.bodySm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 8),
          // Original price
          SizedBox(
            width: 90,
            child: Opacity(
              opacity: product.isVisible ? 0.6 : 0.3,
              child: Text(
                '${product.originalPrice.toStringAsFixed(2)} ${settings.currency}',
                style: AppTextStyles.caption,
                textAlign: TextAlign.end,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Menu price override
          SizedBox(
            width: 110,
            child: TextFormField(
              controller: priceCtrl,
              enabled: product.isVisible,
              decoration: InputDecoration(
                hintText: product.originalPrice.toStringAsFixed(2),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                suffixText: settings.currency,
                suffixStyle: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
              ),
              style: const TextStyle(fontSize: 13),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                final val = double.tryParse(v.trim());
                cubit.updateMenuPrice(product.productId, val);
              },
            ),
          ),
          // Clear price override
          SizedBox(
            width: 36,
            child: product.menuPrice != null
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    color: AppColors.mutedForeground,
                    tooltip: 'Use original price',
                    onPressed: () {
                      priceCtrl.clear();
                      cubit.updateMenuPrice(product.productId, null);
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ProdPlaceholder extends StatelessWidget {
  const _ProdPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.fastfood_rounded,
          color: AppColors.mutedForeground, size: 18),
    );
  }
}

// ─── Preview Panel ────────────────────────────────────────────────────────────

class _PreviewPanel extends StatefulWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final GlobalKey previewKey;
  final String publicUrl;
  final VoidCallback onDownloadPdf;

  const _PreviewPanel({
    required this.settings,
    required this.products,
    required this.previewKey,
    required this.publicUrl,
    required this.onDownloadPdf,
  });

  @override
  State<_PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<_PreviewPanel> {
  bool _showMobile = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ViewToggleBtn(
                icon: Icons.smartphone_rounded,
                label: 'Mobile',
                selected: _showMobile,
                onTap: () => setState(() => _showMobile = true),
              ),
              const SizedBox(width: 8),
              _ViewToggleBtn(
                icon: Icons.desktop_mac_rounded,
                label: 'Web',
                selected: !_showMobile,
                onTap: () => setState(() => _showMobile = false),
              ),
            ],
          ),
        ),
        // Preview area
        Expanded(
          child: Container(
            color: const Color(0xFFE8EBF0),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: RepaintBoundary(
                key: widget.previewKey,
                child: _showMobile
                    ? _PhoneMockup(
                        settings: widget.settings,
                        products: widget.products,
                      )
                    : _BrowserMockup(
                        settings: widget.settings,
                        products: widget.products,
                      ),
              ),
            ),
          ),
        ),
        // URL bar
        _UrlBar(
          settings: widget.settings,
          publicUrl: widget.publicUrl,
          onDownloadPdf: widget.onDownloadPdf,
        ),
      ],
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleBtn({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: selected ? Colors.white : AppColors.mutedForeground),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppColors.mutedForeground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ─── Phone Mockup (theme-aware) ───────────────────────────────────────────────

class _PhoneMockup extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;

  const _PhoneMockup({required this.settings, required this.products});

  Color get _primary {
    final hex = settings.primaryColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color get _bg {
    final hex = settings.backgroundColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 460,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 32, offset: const Offset(0, 16)),
          BoxShadow(color: Colors.white.withOpacity(0.06), blurRadius: 1, offset: const Offset(-1, -1)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(7, 10, 7, 7),
      child: Column(
        children: [
          // Status bar notch
          Container(
            height: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          // Screen
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: _ThemePreviewContent(
                settings: settings,
                products: products,
                primary: _primary,
                bg: _bg,
              ),
            ),
          ),
          // Home bar
          const SizedBox(height: 6),
          Center(
            child: Container(
              width: 80,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Browser Mockup ───────────────────────────────────────────────────────────

class _BrowserMockup extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;

  const _BrowserMockup({required this.settings, required this.products});

  Color get _primary {
    final hex = settings.primaryColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color get _bg {
    final hex = settings.backgroundColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Browser chrome
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF3C3C3C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Traffic lights
                Row(children: [
                  _dot(const Color(0xFFFF5F57)),
                  const SizedBox(width: 6),
                  _dot(const Color(0xFFFFBD2E)),
                  const SizedBox(width: 6),
                  _dot(const Color(0xFF28CA41)),
                ]),
                const SizedBox(width: 12),
                // URL bar
                Expanded(
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, size: 10, color: Color(0xFF6B9E6B)),
                        const SizedBox(width: 4),
                        Text(
                          'menu/${settings.slug.isEmpty ? 'your-slug' : settings.slug}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFBBBBBB)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF888888)),
              ],
            ),
          ),
          // Page content
          SizedBox(
            height: 380,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: _ThemePreviewContent(
                settings: settings,
                products: products,
                primary: _primary,
                bg: _bg,
                isWeb: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

// ─── Theme-aware Preview Content ─────────────────────────────────────────────

class _ThemePreviewContent extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final Color primary;
  final Color bg;
  final bool isWeb;

  const _ThemePreviewContent({
    required this.settings,
    required this.products,
    required this.primary,
    required this.bg,
    this.isWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    final visible = products.where((p) => p.isVisible).toList();
    final grouped = <String, List<MenuProductConfig>>{};
    for (final p in visible) {
      (grouped[p.categoryName ?? ''] ??= []).add(p);
    }

    return switch (settings.themeId) {
      2 => _ClassicPreview(settings: settings, grouped: grouped, primary: primary, bg: bg, isWeb: isWeb),
      3 => _DarkLuxuryPreview(settings: settings, grouped: grouped, isWeb: isWeb),
      4 => _MinimalPreview(settings: settings, grouped: grouped, primary: primary, isWeb: isWeb),
      5 => _MagazinePreview(settings: settings, grouped: grouped, primary: primary, bg: bg, isWeb: isWeb),
      6 => _FlyerPreview(settings: settings, grouped: grouped, primary: primary, isWeb: isWeb),
      7 => _BillboardPreview(settings: settings, grouped: grouped, primary: primary, isWeb: isWeb),
      8 => _ElegantCardsPreview(settings: settings, grouped: grouped, primary: primary, isWeb: isWeb),
      _ => _ModernGridPreview(settings: settings, grouped: grouped, primary: primary, bg: bg, isWeb: isWeb),
    };
  }
}

// Theme 1: Modern Grid
class _ModernGridPreview extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary;
  final Color bg;
  final bool isWeb;

  const _ModernGridPreview({
    required this.settings, required this.grouped,
    required this.primary, required this.bg, required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 10, vertical: isWeb ? 18 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.8)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isWeb ? 24 : 16,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.restaurant_rounded, color: Colors.white, size: isWeb ? 20 : 14),
                ),
                SizedBox(width: isWeb ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.menuName.isEmpty ? 'My Menu' : settings.menuName,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                            fontSize: isWeb ? 16 : 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (settings.description != null)
                        Text(settings.description!,
                            style: TextStyle(color: Colors.white70, fontSize: isWeb ? 11 : 8),
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Grid content
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(isWeb ? 16 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in grouped.entries) ...[
                    if (entry.key.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: isWeb ? 10 : 6, top: isWeb ? 12 : 6),
                        child: Row(children: [
                          Container(width: 3, height: isWeb ? 16 : 10,
                              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2))),
                          SizedBox(width: isWeb ? 8 : 5),
                          Text(entry.key, style: TextStyle(color: primary,
                              fontWeight: FontWeight.bold, fontSize: isWeb ? 13 : 9)),
                        ]),
                      ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWeb ? 4 : 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: isWeb ? 10 : 6,
                        mainAxisSpacing: isWeb ? 10 : 6,
                      ),
                      itemCount: entry.value.take(isWeb ? 8 : 4).length,
                      itemBuilder: (_, i) {
                        final p = entry.value[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isWeb ? 10 : 6),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(isWeb ? 10 : 6)),
                                  ),
                                  child: Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.4),
                                      size: isWeb ? 28 : 18),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(isWeb ? 6 : 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.productName,
                                        style: TextStyle(fontSize: isWeb ? 10 : 7, fontWeight: FontWeight.w600),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (settings.showPrices)
                                      Text('${p.effectivePrice.toStringAsFixed(0)} ${settings.currency}',
                                          style: TextStyle(fontSize: isWeb ? 10 : 7, color: primary,
                                              fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Theme 2: Classic List
class _ClassicPreview extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary;
  final Color bg;
  final bool isWeb;

  const _ClassicPreview({
    required this.settings, required this.grouped,
    required this.primary, required this.bg, required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 12, vertical: isWeb ? 20 : 12),
            color: primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: isWeb ? 50 : 32, height: isWeb ? 50 : 32,
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: isWeb ? 24 : 16),
                ),
                SizedBox(height: isWeb ? 8 : 4),
                Text(settings.menuName.isEmpty ? 'Menu' : settings.menuName,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isWeb ? 18 : 12),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(isWeb ? 20 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in grouped.entries) ...[
                    if (entry.key.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: isWeb ? 10 : 6, top: isWeb ? 14 : 8),
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 6 : 4),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: primary, width: 2),
                          ),
                        ),
                        child: Text(entry.key,
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: isWeb ? 14 : 9)),
                      ),
                    for (final p in entry.value.take(isWeb ? 6 : 3))
                      Padding(
                        padding: EdgeInsets.only(bottom: isWeb ? 8 : 5),
                        child: Row(
                          children: [
                            Container(
                              width: isWeb ? 40 : 24, height: isWeb ? 40 : 24,
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isWeb ? 6 : 4),
                              ),
                              child: Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.5),
                                  size: isWeb ? 20 : 12),
                            ),
                            SizedBox(width: isWeb ? 10 : 6),
                            Expanded(child: Text(p.productName,
                                style: TextStyle(fontSize: isWeb ? 12 : 8, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis)),
                            if (settings.showPrices)
                              Text('${p.effectivePrice.toStringAsFixed(0)} ${settings.currency}',
                                  style: TextStyle(fontSize: isWeb ? 12 : 8, color: primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Theme 3: Dark Luxury
class _DarkLuxuryPreview extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final bool isWeb;

  const _DarkLuxuryPreview({
    required this.settings, required this.grouped, required this.isWeb,
  });

  static const _gold = Color(0xFFD4A017);
  static const _darkBg = Color(0xFF0A0A0A);
  static const _cardBg = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _darkBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 12, vertical: isWeb ? 20 : 12),
            decoration: BoxDecoration(
              color: _cardBg,
              border: const Border(bottom: BorderSide(color: _gold, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 1, height: isWeb ? 24 : 14,
                  color: _gold,
                ),
                SizedBox(width: isWeb ? 12 : 8),
                Text(settings.menuName.isEmpty ? 'Fine Dining' : settings.menuName,
                    style: TextStyle(color: _gold, fontWeight: FontWeight.w600,
                        fontSize: isWeb ? 18 : 11, letterSpacing: 2)),
                SizedBox(width: isWeb ? 12 : 8),
                Container(width: 1, height: isWeb ? 24 : 14, color: _gold),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(isWeb ? 20 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in grouped.entries) ...[
                    if (entry.key.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 6),
                        child: Row(
                          children: [
                            Text('— ', style: TextStyle(color: _gold, fontSize: isWeb ? 12 : 8)),
                            Text(entry.key.toUpperCase(),
                                style: TextStyle(color: _gold, fontWeight: FontWeight.w500,
                                    fontSize: isWeb ? 11 : 7, letterSpacing: 1.5)),
                            Text(' —', style: TextStyle(color: _gold, fontSize: isWeb ? 12 : 8)),
                          ],
                        ),
                      ),
                    for (final p in entry.value.take(isWeb ? 5 : 3))
                      Container(
                        margin: EdgeInsets.only(bottom: isWeb ? 8 : 5),
                        padding: EdgeInsets.all(isWeb ? 10 : 6),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(isWeb ? 6 : 4),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(p.productName,
                                style: TextStyle(color: Colors.white70, fontSize: isWeb ? 12 : 8),
                                overflow: TextOverflow.ellipsis)),
                            if (settings.showPrices) ...[
                              Container(width: 1, height: isWeb ? 16 : 10, color: _gold.withOpacity(0.3),
                                  margin: EdgeInsets.symmetric(horizontal: isWeb ? 8 : 5)),
                              Text('${p.effectivePrice.toStringAsFixed(0)}',
                                  style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: isWeb ? 12 : 8)),
                            ],
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Theme 4: Minimal
class _MinimalPreview extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary;
  final bool isWeb;

  const _MinimalPreview({
    required this.settings, required this.grouped,
    required this.primary, required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 16, vertical: isWeb ? 24 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(settings.menuName.isEmpty ? 'Menu' : settings.menuName,
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w300,
                        fontSize: isWeb ? 28 : 16, letterSpacing: -0.5)),
                if (settings.description != null)
                  Text(settings.description!,
                      style: TextStyle(color: Colors.black38, fontSize: isWeb ? 12 : 8)),
                SizedBox(height: isWeb ? 10 : 6),
                Container(width: 32, height: 2, color: primary),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in grouped.entries) ...[
                    if (entry.key.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: isWeb ? 16 : 10, bottom: isWeb ? 8 : 4),
                        child: Text(entry.key.toUpperCase(),
                            style: TextStyle(color: Colors.black38,
                                fontSize: isWeb ? 10 : 7, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      ),
                    for (final p in entry.value.take(isWeb ? 5 : 3)) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 7 : 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(p.productName,
                                style: TextStyle(color: Colors.black87, fontSize: isWeb ? 13 : 8,
                                    fontWeight: FontWeight.w400),
                                overflow: TextOverflow.ellipsis)),
                            if (settings.showPrices)
                              Text('${p.effectivePrice.toStringAsFixed(0)} ${settings.currency}',
                                  style: TextStyle(color: Colors.black54, fontSize: isWeb ? 12 : 8)),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.black.withOpacity(0.06)),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Theme 5: Magazine
class _MagazinePreview extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary;
  final Color bg;
  final bool isWeb;

  const _MagazinePreview({
    required this.settings, required this.grouped,
    required this.primary, required this.bg, required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    final entries = grouped.entries.toList();
    return ColoredBox(
      color: bg,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header
            Container(
              height: isWeb ? 120 : 70,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary.withOpacity(0.9), primary],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: GridView.count(
                    crossAxisCount: isWeb ? 8 : 5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(40, (_) => Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  )),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(settings.menuName.isEmpty ? 'Menu' : settings.menuName,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                                fontSize: isWeb ? 24 : 14, letterSpacing: -0.5)),
                        if (settings.address != null)
                          Text(settings.address!,
                              style: TextStyle(color: Colors.white60, fontSize: isWeb ? 11 : 7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Category sections
            for (final entry in entries.take(isWeb ? 3 : 2)) ...[
              if (entry.key.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: isWeb ? 14 : 8),
                  padding: EdgeInsets.symmetric(horizontal: isWeb ? 16 : 10, vertical: isWeb ? 6 : 4),
                  color: primary,
                  child: Text(entry.key,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isWeb ? 12 : 8)),
                ),
              for (final p in entry.value.take(isWeb ? 3 : 2))
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWeb ? 16 : 10, vertical: isWeb ? 6 : 4),
                  child: Row(
                    children: [
                      Container(
                        width: isWeb ? 48 : 28, height: isWeb ? 48 : 28,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isWeb ? 6 : 4),
                        ),
                        child: Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.5),
                            size: isWeb ? 24 : 14),
                      ),
                      SizedBox(width: isWeb ? 10 : 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.productName,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: isWeb ? 12 : 8),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (settings.showPrices)
                        Text('${p.effectivePrice.toStringAsFixed(0)} ${settings.currency}',
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: isWeb ? 12 : 8)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// Theme 6: Flyer Preview
class _FlyerPreview extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary;
  final bool isWeb;

  const _FlyerPreview({required this.settings, required this.grouped, required this.primary, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF8E7),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 10, vertical: isWeb ? 16 : 10),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                width: isWeb ? 48 : 28, height: isWeb ? 48 : 28,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.restaurant_rounded, color: Colors.white, size: isWeb ? 24 : 14),
              ),
              SizedBox(width: isWeb ? 12 : 7),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(settings.menuName.isEmpty ? 'My Menu' : settings.menuName,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: isWeb ? 18 : 10), overflow: TextOverflow.ellipsis),
                if (settings.description != null)
                  Text(settings.description!, style: TextStyle(color: Colors.white70, fontSize: isWeb ? 11 : 7), overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(isWeb ? 14 : 7),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final entry in grouped.entries) ...[
                  if (entry.key.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: isWeb ? 8 : 5, top: isWeb ? 10 : 6),
                      padding: EdgeInsets.symmetric(horizontal: isWeb ? 12 : 7, vertical: isWeb ? 5 : 3),
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(isWeb ? 6 : 4)),
                      child: Text(entry.key, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isWeb ? 12 : 8)),
                    ),
                  for (final p in entry.value.take(isWeb ? 5 : 2))
                    Container(
                      margin: EdgeInsets.only(bottom: isWeb ? 6 : 4),
                      padding: EdgeInsets.symmetric(horizontal: isWeb ? 10 : 6, vertical: isWeb ? 8 : 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isWeb ? 8 : 5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                      ),
                      child: Row(children: [
                        Expanded(child: Text(p.productName, style: TextStyle(fontSize: isWeb ? 11 : 7, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                        if (settings.showPrices)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: isWeb ? 8 : 4, vertical: isWeb ? 3 : 2),
                            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(isWeb ? 5 : 3)),
                            child: Text('${p.effectivePrice.toStringAsFixed(0)}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isWeb ? 10 : 7)),
                          ),
                      ]),
                    ),
                ],
              ]),
            ),
          ),
          if (settings.phones.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: isWeb ? 14 : 8, vertical: isWeb ? 8 : 5),
              color: primary.withOpacity(0.1),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.phone_rounded, color: primary, size: isWeb ? 14 : 9),
                SizedBox(width: isWeb ? 6 : 3),
                Text(settings.phones.first, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: isWeb ? 11 : 7)),
              ]),
            ),
        ],
      ),
    );
  }
}

// Theme 7: Billboard Preview
class _BillboardPreview extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary;
  final bool isWeb;

  const _BillboardPreview({required this.settings, required this.grouped, required this.primary, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: primary,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isWeb ? 16 : 9),
            child: Column(children: [
              Icon(Icons.restaurant_rounded, color: Colors.white54, size: isWeb ? 24 : 14),
              SizedBox(height: isWeb ? 6 : 4),
              Text(settings.menuName.isEmpty ? 'MENU' : settings.menuName.toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: isWeb ? 18 : 10, fontWeight: FontWeight.w900, letterSpacing: 1.5), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
              padding: EdgeInsets.all(isWeb ? 14 : 8),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final entry in grouped.entries) ...[
                    if (entry.key.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: isWeb ? 8 : 4, top: isWeb ? 10 : 6),
                        child: Text(entry.key, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: isWeb ? 13 : 8, letterSpacing: -0.3)),
                      ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWeb ? 3 : 2, childAspectRatio: 1.4,
                        crossAxisSpacing: isWeb ? 8 : 4, mainAxisSpacing: isWeb ? 8 : 4,
                      ),
                      itemCount: entry.value.take(isWeb ? 6 : 4).length,
                      itemBuilder: (_, i) {
                        final p = entry.value[i];
                        return Container(
                          padding: EdgeInsets.all(isWeb ? 8 : 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isWeb ? 8 : 5),
                            border: Border.all(color: primary.withOpacity(0.15)),
                            boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 4)],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(p.productName, style: TextStyle(fontSize: isWeb ? 10 : 7, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (settings.showPrices)
                              Text('${p.effectivePrice.toStringAsFixed(0)} ${settings.currency}',
                                  style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: isWeb ? 10 : 7)),
                          ]),
                        );
                      },
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Theme 8: Elegant Cards Preview
class _ElegantCardsPreview extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary;
  final bool isWeb;

  const _ElegantCardsPreview({required this.settings, required this.grouped, required this.primary, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 10, vertical: isWeb ? 16 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primary, primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(settings.menuName.isEmpty ? 'Menu' : settings.menuName,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isWeb ? 16 : 10), overflow: TextOverflow.ellipsis),
              if (settings.address != null)
                Text(settings.address!, style: TextStyle(color: Colors.white70, fontSize: isWeb ? 10 : 7), overflow: TextOverflow.ellipsis),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(isWeb ? 12 : 7),
              child: Column(children: [
                for (final entry in grouped.entries) ...[
                  if (entry.key.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isWeb ? 8 : 4, top: isWeb ? 10 : 6),
                        child: Text(entry.key, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: isWeb ? 12 : 8)),
                      ),
                    ),
                  for (final p in entry.value.take(isWeb ? 4 : 2))
                    Container(
                      margin: EdgeInsets.only(bottom: isWeb ? 8 : 5),
                      padding: EdgeInsets.all(isWeb ? 10 : 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isWeb ? 10 : 6),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                      ),
                      child: Row(children: [
                        Container(
                          width: isWeb ? 40 : 22, height: isWeb ? 40 : 22,
                          decoration: BoxDecoration(color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(isWeb ? 8 : 5)),
                          child: Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.5), size: isWeb ? 20 : 12),
                        ),
                        SizedBox(width: isWeb ? 10 : 6),
                        Expanded(child: Text(p.productName, style: TextStyle(fontSize: isWeb ? 12 : 7, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        if (settings.showPrices)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: isWeb ? 8 : 4, vertical: isWeb ? 3 : 2),
                            decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(isWeb ? 6 : 3)),
                            child: Text('${p.effectivePrice.toStringAsFixed(0)}', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: isWeb ? 11 : 7)),
                          ),
                      ]),
                    ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlBar extends StatefulWidget {
  final MenuSettings settings;
  final String publicUrl;
  final VoidCallback onDownloadPdf;

  const _UrlBar({
    required this.settings,
    required this.publicUrl,
    required this.onDownloadPdf,
  });

  @override
  State<_UrlBar> createState() => _UrlBarState();
}

class _UrlBarState extends State<_UrlBar> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.publicUrl));
    setState(() => _copied = true);
    if (mounted) {
      AppSnackbar.success(context, AppLocalizations.of(context).t('menuLinkCopied'));
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _open() async {
    final uri = Uri.parse(widget.publicUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    }
  }

  void _showQr() {
    showDialog(
      context: context,
      builder: (_) => _QrDialog(url: widget.publicUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: AppColors.mutedForeground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.publicUrl,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Action buttons
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _ActionBtn(
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                label: _copied ? AppLocalizations.of(context).t('menuLinkCopied') : AppLocalizations.of(context).t('menuCopyLink'),
                onTap: _copy,
                color: _copied ? AppColors.success : null,
              ),
              _ActionBtn(
                icon: Icons.open_in_browser_rounded,
                label: AppLocalizations.of(context).t('menuOpenLink'),
                onTap: _open,
              ),
              _ActionBtn(
                icon: Icons.qr_code_rounded,
                label: AppLocalizations.of(context).t('menuQrCode'),
                onTap: _showQr,
              ),
              _ActionBtn(
                icon: Icons.picture_as_pdf_rounded,
                label: AppLocalizations.of(context).t('menuDownloadPdf'),
                onTap: widget.onDownloadPdf,
                highlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool highlighted;

  const _ActionBtn({
    required this.icon, required this.label,
    required this.onTap, this.color, this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (highlighted ? Colors.white : AppColors.foreground);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: highlighted ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, color: c, fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ─── PDF Design Picker ────────────────────────────────────────────────────────

class _PdfCustom {
  final Color headerBg;
  final Color headerText;
  final Color accentColor;
  final Color itemText;
  final Color priceColor;
  final double titleSize;
  final double catSize;
  final double itemSize;
  final double priceSize;

  const _PdfCustom({
    required this.headerBg,
    required this.headerText,
    required this.accentColor,
    required this.itemText,
    required this.priceColor,
    this.titleSize = 36,
    this.catSize = 14,
    this.itemSize = 12,
    this.priceSize = 13,
  });

  _PdfCustom copyWith({
    Color? headerBg, Color? headerText, Color? accentColor,
    Color? itemText, Color? priceColor,
    double? titleSize, double? catSize, double? itemSize, double? priceSize,
  }) => _PdfCustom(
    headerBg: headerBg ?? this.headerBg,
    headerText: headerText ?? this.headerText,
    accentColor: accentColor ?? this.accentColor,
    itemText: itemText ?? this.itemText,
    priceColor: priceColor ?? this.priceColor,
    titleSize: titleSize ?? this.titleSize,
    catSize: catSize ?? this.catSize,
    itemSize: itemSize ?? this.itemSize,
    priceSize: priceSize ?? this.priceSize,
  );

  PdfColor toPdf(Color c) => PdfColor(c.r, c.g, c.b);
}

const _kSwatchColors = [
  Color(0xFF0C2461), Color(0xFF1E3799), Color(0xFF4A90D9), Color(0xFF48C9B0),
  Color(0xFF2ECC71), Color(0xFF27AE60), Color(0xFFE74C3C), Color(0xFFC0392B),
  Color(0xFFE67E22), Color(0xFFF39C12), Color(0xFF9B59B6), Color(0xFF8E44AD),
  Color(0xFF1ABC9C), Color(0xFF16213E), Color(0xFF2C3E50), Color(0xFF1A1A1A),
];

class _PdfDesignPickerDialog extends StatefulWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  const _PdfDesignPickerDialog({required this.settings, required this.products});

  @override
  State<_PdfDesignPickerDialog> createState() => _PdfDesignPickerDialogState();
}

class _PdfDesignPickerDialogState extends State<_PdfDesignPickerDialog> {
  int _selected = 0;
  bool _printing = false;
  late _PdfCustom _custom;

  static const _designs = [
    (name: 'Grand Luxe', nameAr: 'جراند لوكس', desc: 'هيدر فاخر + خطوط ناعمة', accent: Color(0xFF0C2461), icon: Icons.auto_awesome_rounded),
    (name: 'Street Bold', nameAr: 'ستريت بولد', desc: 'ألوان جامدة + بادجات سعر', accent: Color(0xFFE74C3C), icon: Icons.local_fire_department_rounded),
    (name: 'Clean Editorial', nameAr: 'كلين ادتوريال', desc: 'عمودان + typography فاخر', accent: Color(0xFF2ECC71), icon: Icons.article_rounded),
    (name: 'Dark Luxury', nameAr: 'دارك لوكشري', desc: 'خلفية داكنة + تفاصيل ذهبية', accent: Color(0xFFD4AC0D), icon: Icons.nights_stay_rounded),
    (name: 'Flyer Pro', nameAr: 'فلاير برو', desc: 'إطار زخرفي + تصميم ترويجي', accent: Color(0xFF8E44AD), icon: Icons.campaign_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _resetCustom();
  }

  void _resetCustom() {
    final c = _designs[_selected].accent;
    _custom = _PdfCustom(
      headerBg: c,
      headerText: Colors.white,
      accentColor: c,
      itemText: const Color(0xFF2C3E50),
      priceColor: c,
    );
  }

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      final regular = await PdfGoogleFonts.notoNaskhArabicRegular();
      final bold = await PdfGoogleFonts.notoNaskhArabicBold();
      final grouped = <String, List<MenuProductConfig>>{};
      for (final p in widget.products.where((p) => p.isVisible)) {
        (grouped[p.categoryName ?? ''] ??= []).add(p);
      }
      final doc = switch (_selected) {
        1 => _buildPdfStreetBold(widget.settings, grouped, _custom, regular, bold),
        2 => _buildPdfCleanEditorial(widget.settings, grouped, _custom, regular, bold),
        3 => _buildPdfDarkLuxury(widget.settings, grouped, _custom, regular, bold),
        4 => _buildPdfFlyerPro(widget.settings, grouped, _custom, regular, bold),
        _ => _buildPdfGrandLuxe(widget.settings, grouped, _custom, regular, bold),
      };
      if (mounted) Navigator.of(context).pop();
      await Printing.layoutPdf(onLayout: (_) => doc.save());
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = _designs[_selected];
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 640),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(children: [
                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text(l10n.t('menuSelectPdfDesign'), style: AppTextStyles.h5),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, size: 20)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: design list
                  Container(
                    width: 220,
                    decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _designs.length,
                      itemBuilder: (_, i) {
                        final di = _designs[i];
                        final sel = _selected == i;
                        return GestureDetector(
                          onTap: () => setState(() { _selected = i; _resetCustom(); }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? AppColors.primary : Colors.transparent, width: 1.5),
                            ),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  width: 52, height: 64,
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: SizedBox(
                                      width: 130, height: 160,
                                      child: _PdfDesignThumbnail(index: i, primary: di.accent),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(di.nameAr, style: AppTextStyles.labelSm.copyWith(
                                    color: sel ? AppColors.primary : AppColors.foreground, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(di.desc, style: AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              ])),
                              if (sel) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  // Right: customization panel
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(d.icon, color: d.accent, size: 18),
                            const SizedBox(width: 8),
                            Text(d.nameAr, style: AppTextStyles.labelMd.copyWith(color: d.accent, fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 4),
                          Text(d.desc, style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedForeground)),
                          const SizedBox(height: 20),
                          Text('الألوان', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _ColorSwatchRow(label: 'لون الهيدر', selected: _custom.headerBg,
                              onPick: (c) => setState(() => _custom = _custom.copyWith(headerBg: c))),
                          const SizedBox(height: 10),
                          _ColorSwatchRow(label: 'نص الهيدر', selected: _custom.headerText,
                              onPick: (c) => setState(() => _custom = _custom.copyWith(headerText: c))),
                          const SizedBox(height: 10),
                          _ColorSwatchRow(label: 'لون التمييز', selected: _custom.accentColor,
                              onPick: (c) => setState(() => _custom = _custom.copyWith(accentColor: c))),
                          const SizedBox(height: 10),
                          _ColorSwatchRow(label: 'نص الأصناف', selected: _custom.itemText,
                              onPick: (c) => setState(() => _custom = _custom.copyWith(itemText: c))),
                          const SizedBox(height: 10),
                          _ColorSwatchRow(label: 'لون السعر', selected: _custom.priceColor,
                              onPick: (c) => setState(() => _custom = _custom.copyWith(priceColor: c))),
                          const SizedBox(height: 24),
                          Text('أحجام الخطوط', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _SizeControl(label: 'حجم الاسم', value: _custom.titleSize, min: 20, max: 56,
                              onChanged: (v) => setState(() => _custom = _custom.copyWith(titleSize: v))),
                          const SizedBox(height: 8),
                          _SizeControl(label: 'حجم الفئة', value: _custom.catSize, min: 10, max: 24,
                              onChanged: (v) => setState(() => _custom = _custom.copyWith(catSize: v))),
                          const SizedBox(height: 8),
                          _SizeControl(label: 'حجم الصنف', value: _custom.itemSize, min: 8, max: 20,
                              onChanged: (v) => setState(() => _custom = _custom.copyWith(itemSize: v))),
                          const SizedBox(height: 8),
                          _SizeControl(label: 'حجم السعر', value: _custom.priceSize, min: 8, max: 20,
                              onChanged: (v) => setState(() => _custom = _custom.copyWith(priceSize: v))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.t('cancel'))),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _printing ? null : _print,
                  icon: _printing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.print_rounded, size: 16),
                  label: Text(l10n.t('menuPrintPdf')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  final String label;
  final Color selected;
  final ValueChanged<Color> onPick;
  const _ColorSwatchRow({required this.label, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedForeground))),
      const SizedBox(width: 8),
      Wrap(spacing: 5, runSpacing: 5, children: _kSwatchColors.map((c) {
        final isSel = c.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () => onPick(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: c, shape: BoxShape.circle,
              border: Border.all(color: isSel ? AppColors.foreground : Colors.transparent, width: 2.5),
              boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : [],
            ),
            child: isSel ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
          ),
        );
      }).toList()),
    ]);
  }
}

class _SizeControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _SizeControl({required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedForeground))),
      const SizedBox(width: 8),
      InkWell(
        onTap: value > min ? () => onChanged((value - 1).clamp(min, max)) : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(6)),
          child: Icon(Icons.remove_rounded, size: 14, color: value > min ? AppColors.foreground : AppColors.mutedForeground),
        ),
      ),
      SizedBox(width: 38, child: Text('${value.toInt()}', style: AppTextStyles.labelSm, textAlign: TextAlign.center)),
      InkWell(
        onTap: value < max ? () => onChanged((value + 1).clamp(min, max)) : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(6)),
          child: Icon(Icons.add_rounded, size: 14, color: value < max ? AppColors.foreground : AppColors.mutedForeground),
        ),
      ),
    ]);
  }
}

class _PdfDesignThumbnail extends StatelessWidget {
  final int index;
  final Color primary;
  const _PdfDesignThumbnail({required this.index, required this.primary});

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      1 => _StreetBoldThumb(primary: primary),
      2 => _CleanGridThumb(primary: primary),
      3 => _DarkLuxuryThumb(primary: primary),
      4 => _FlyerProThumb(primary: primary),
      _ => _GrandLuxeThumb(primary: primary),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THUMBNAILS
// ─────────────────────────────────────────────────────────────────────────────

// ─── Thumbnail 1: Grand Luxe ──────────────────────────────────────────────────

class _GrandLuxeThumb extends StatelessWidget {
  final Color primary;
  const _GrandLuxeThumb({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: const Color(0xFFF8F8F8),
      child: Column(children: [
        // Header block
        Container(
          color: primary, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.6))),
              const SizedBox(width: 6),
              Container(width: 68, height: 9, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.6))),
            ]),
            const SizedBox(height: 4),
            Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 6),
            Container(width: 80, height: 1, color: Colors.white38),
            const SizedBox(height: 5),
            Container(width: 60, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
          ]),
        ),
        Container(height: 4, color: primary.withOpacity(0.4)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _thumbCatRow(primary, label: true),
              _thumbItemRow(primary, wide: true),
              _thumbItemRow(primary, wide: false),
              const SizedBox(height: 6),
              _thumbCatRow(primary, label: true),
              _thumbItemRow(primary, wide: true),
              const Spacer(),
              Container(
                height: 18, decoration: BoxDecoration(color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: primary.withOpacity(0.2))),
                alignment: Alignment.center,
                child: Container(width: 56, height: 4, decoration: BoxDecoration(color: primary.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _thumbCatRow(Color c, {required bool label}) => Container(
    height: 11, margin: const EdgeInsets.only(bottom: 4, top: 2),
    decoration: BoxDecoration(
      color: c.withOpacity(0.09),
      border: Border(right: BorderSide(color: c, width: 3)),
    ),
    padding: const EdgeInsets.only(right: 6),
    alignment: Alignment.centerRight,
    child: Container(width: 40, height: 5, decoration: BoxDecoration(color: c.withOpacity(0.7), borderRadius: BorderRadius.circular(2))),
  );

  Widget _thumbItemRow(Color c, {required bool wide}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(width: 8),
      Container(width: wide ? 24 : 18, height: 4, decoration: BoxDecoration(color: c.withOpacity(0.6), borderRadius: BorderRadius.circular(2))),
    ]),
  );
}

// ─── Thumbnail 2: Street Bold ─────────────────────────────────────────────────

class _StreetBoldThumb extends StatelessWidget {
  final Color primary;
  const _StreetBoldThumb({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, color: Colors.white,
      child: Column(children: [
        // Big header
        Container(
          color: primary, padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 5, height: 5, margin: const EdgeInsets.only(right: 6), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white54)),
              Container(width: 60, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3))),
              Container(width: 5, height: 5, margin: const EdgeInsets.only(left: 6), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white54)),
            ]),
            const SizedBox(height: 3),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 5),
            Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
          ]),
        ),
        Container(height: 5, color: Color.lerp(primary, Colors.black, 0.25)!),
        Expanded(
          child: Column(children: [
            for (int cat = 0; cat < 2; cat++) ...[
              Container(
                height: 13, color: primary,
                alignment: Alignment.center,
                child: Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
              ),
              for (int j = 0; j < 2; j++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: Row(children: [
                    Container(width: 4, height: 4, margin: const EdgeInsets.only(right: 3), color: primary),
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)),
                      child: Container(width: 16, height: 4, color: Colors.white),
                    ),
                  ]),
                ),
            ],
            const Spacer(),
            Container(
              height: 16, color: primary,
              alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Container(width: 24, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Thumbnail 3: Clean Grid (2-column) ──────────────────────────────────────

class _CleanGridThumb extends StatelessWidget {
  final Color primary;
  const _CleanGridThumb({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header: vertical bar + name + phone
          Row(children: [
            Container(width: 4, height: 28, color: primary, margin: const EdgeInsets.only(right: 8)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 64, height: 8, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 4),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(width: 32, height: 5, decoration: BoxDecoration(color: primary.withOpacity(0.7), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 3),
              Container(width: 24, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ]),
          ]),
          const SizedBox(height: 5),
          Container(height: 1.5, color: primary),
          const SizedBox(height: 7),
          // 2-column grid
          for (int cat = 0; cat < 1; cat++) ...[
            Row(children: [
              Container(width: 36, height: 5, decoration: BoxDecoration(color: primary.withOpacity(0.8), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Expanded(child: Container(height: 0.5, color: Colors.grey.shade300)),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              Expanded(child: Column(children: [
                _gridItem(primary),
                _gridItem(primary),
              ])),
              Container(width: 0.5, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 6)),
              Expanded(child: Column(children: [
                _gridItem(primary),
                _gridItem(primary),
              ])),
            ]),
            const SizedBox(height: 4),
          ],
          for (int cat = 0; cat < 1; cat++) ...[
            Row(children: [
              Container(width: 28, height: 5, decoration: BoxDecoration(color: primary.withOpacity(0.8), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Expanded(child: Container(height: 0.5, color: Colors.grey.shade300)),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              Expanded(child: Column(children: [
                _gridItem(primary),
              ])),
              Container(width: 0.5, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 6)),
              Expanded(child: Column(children: [
                _gridItem(primary),
              ])),
            ]),
          ],
          const Spacer(),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 4),
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: primary.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Container(width: 28, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Container(width: 20, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ])),
        ]),
      ),
    );
  }

  Widget _gridItem(Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(width: 4),
      Container(width: 16, height: 4, decoration: BoxDecoration(color: c.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
    ]),
  );
}

// ─── Thumbnail 4: Dark Luxury ─────────────────────────────────────────────────

class _DarkLuxuryThumb extends StatelessWidget {
  final Color primary;
  const _DarkLuxuryThumb({required this.primary});

  static const _dark = Color(0xFF0D0D0D);
  static const _gold = Color(0xFFD4AC0D);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, color: _dark,
      child: Column(children: [
        // Header
        Container(
          color: _dark,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(children: [
            Container(width: 80, height: 1, color: _gold),
            const SizedBox(height: 4),
            Container(width: 58, height: 9, decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 4),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _gold.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 4),
            Container(width: 80, height: 1, color: _gold),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(children: [
              for (int cat = 0; cat < 2; cat++) ...[
                Container(
                  height: 10, margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(border: Border.all(color: _gold, width: 0.5)),
                  alignment: Alignment.center,
                  child: Container(width: 34, height: 3, color: _gold),
                ),
                for (int j = 0; j < 2; j++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Container(width: 4, height: 4, margin: const EdgeInsets.only(right: 3), color: _gold),
                      Expanded(child: Container(height: 3, color: Colors.white24)),
                      const SizedBox(width: 4),
                      Container(width: 18, height: 4, decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2))),
                    ]),
                  ),
              ],
              const Spacer(),
              Container(width: 80, height: 1, color: _gold.withOpacity(0.4)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Thumbnail 5: Flyer Pro ───────────────────────────────────────────────────

class _FlyerProThumb extends StatelessWidget {
  final Color primary;
  const _FlyerProThumb({required this.primary});

  @override
  Widget build(BuildContext context) {
    final border = primary.withOpacity(0.8);
    return Container(
      height: 160, color: Colors.white,
      child: Stack(children: [
        // Decorative corner borders
        Positioned(top: 4, left: 4, child: _corner(border, true, true)),
        Positioned(top: 4, right: 4, child: _corner(border, true, false)),
        Positioned(bottom: 4, left: 4, child: _corner(border, false, true)),
        Positioned(bottom: 4, right: 4, child: _corner(border, false, false)),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)),
              child: Column(children: [
                Container(width: 56, height: 9, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 3),
                Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(2))),
              ]),
            ),
            const SizedBox(height: 6),
            // Items in ornate boxes
            for (int cat = 0; cat < 2; cat++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 3),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(border: Border.all(color: primary.withOpacity(0.3), width: 0.5)),
                child: Column(children: [
                  Container(height: 7, color: primary.withOpacity(0.12),
                      alignment: Alignment.center,
                      child: Container(width: 32, height: 3, color: primary.withOpacity(0.7))),
                  const SizedBox(height: 2),
                  Row(children: [
                    Expanded(child: Container(height: 3, color: Colors.grey.shade200)),
                    const SizedBox(width: 4),
                    Container(width: 14, height: 3, color: primary.withOpacity(0.5)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Expanded(child: Container(height: 3, color: Colors.grey.shade200)),
                    const SizedBox(width: 4),
                    Container(width: 12, height: 3, color: primary.withOpacity(0.5)),
                  ]),
                ]),
              ),
            ],
            const Spacer(),
            Container(height: 14, decoration: BoxDecoration(color: primary.withOpacity(0.08),
                border: Border.all(color: primary.withOpacity(0.3), width: 0.5)),
                alignment: Alignment.center,
                child: Container(width: 50, height: 3, color: primary.withOpacity(0.4))),
          ]),
        ),
      ]),
    );
  }

  Widget _corner(Color c, bool top, bool left) => SizedBox(
    width: 8, height: 8,
    child: CustomPaint(painter: _CornerPainter(color: c, top: top, left: left)),
  );
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;
  const _CornerPainter({required this.color, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;
    canvas.drawLine(Offset(x, y), Offset(x + dx, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), p);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// ─── PDF Builder: Design 1 — Grand Luxe ─────────────────────────────────────
// فاخر — هيدر داكن كامل العرض، صفوف متناوبة، فوتر elegante

pw.Document _buildPdfGrandLuxe(
  MenuSettings s, Map<String, List<MenuProductConfig>> grouped,
  _PdfCustom custom, pw.Font regular, pw.Font bold,
) {
  final doc = pw.Document();
  final primary = custom.toPdf(custom.headerBg);
  final accent = custom.toPdf(custom.accentColor);
  final priceC = custom.toPdf(custom.priceColor);
  final itemC = custom.toPdf(custom.itemText);
  final headerTextC = custom.toPdf(custom.headerText);
  final dim = PdfColor(primary.red * 0.72, primary.green * 0.72, primary.blue * 0.72);
  final pale = PdfColor(accent.red, accent.green, accent.blue, 0.07);
  final paleBorder = PdfColor(accent.red, accent.green, accent.blue, 0.18);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    textDirection: pw.TextDirection.rtl,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    build: (ctx) => [
      // ━━━ HEADER ━━━
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(44, 38, 44, 32),
        decoration: pw.BoxDecoration(color: primary),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Container(width: 44, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.4))),
            pw.SizedBox(width: 10),
            pw.Container(width: 44, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.4))),
          ]),
          pw.SizedBox(height: 10),
          pw.Text(
            s.menuName.isEmpty ? 'قائمة الطعام' : s.menuName,
            style: pw.TextStyle(font: bold, fontSize: custom.titleSize, color: headerTextC, letterSpacing: 1.0),
            textAlign: pw.TextAlign.center,
          ),
          if (s.description != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(s.description!,
                style: pw.TextStyle(font: regular, fontSize: 12, color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.72)),
                textAlign: pw.TextAlign.center),
          ],
          pw.SizedBox(height: 14),
          // Decorative divider
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Container(width: 40, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.35))),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10),
              child: pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.5))),
            ),
            pw.Container(width: 40, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.35))),
          ]),
          pw.SizedBox(height: 12),
          // Contact chips
          pw.Wrap(spacing: 24, alignment: pw.WrapAlignment.center, children: [
            if (s.phones.isNotEmpty)
              _luxeChip(s.phones.first, regular, headerTextC),
            if (s.phones.length > 1)
              _luxeChip(s.phones[1], regular, headerTextC),
            if (s.address != null)
              _luxeChip(s.address!, regular, headerTextC),
          ]),
        ]),
      ),
      // Accent stripe
      pw.Container(height: 6, decoration: pw.BoxDecoration(color: dim)),
      pw.SizedBox(height: 28),

      // ━━━ PRODUCTS ━━━
      for (final entry in grouped.entries) ...[
        if (entry.key.isNotEmpty) ...[
          // Category header
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 2, top: 14),
            padding: const pw.EdgeInsets.fromLTRB(20, 10, 16, 10),
            decoration: pw.BoxDecoration(
              color: pale,
              border: pw.Border(right: pw.BorderSide(color: primary, width: 6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(entry.key,
                    style: pw.TextStyle(font: bold, fontSize: custom.catSize, color: accent)),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(12)),
                  child: pw.Text('${entry.value.length}',
                      style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white)),
                ),
              ],
            ),
          ),
        ],
        // Product rows (alternating bg)
        ...entry.value.asMap().entries.map((me) {
          final p = me.value;
          final isEven = me.key.isEven;
          return pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(20, 9, 20, 9),
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColor(0.975, 0.975, 0.982),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(p.productName,
                      style: pw.TextStyle(font: regular, fontSize: custom.itemSize, color: itemC)),
                ),
                if (s.showPrices) ...[
                  pw.SizedBox(width: 16),
                  pw.Text(
                    '${p.effectivePrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: bold, fontSize: custom.priceSize, color: priceC),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(s.currency,
                      style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey500)),
                ],
              ],
            ),
          );
        }),
        pw.Container(
            height: 0.5,
            margin: const pw.EdgeInsets.symmetric(horizontal: 20),
            decoration: const pw.BoxDecoration(color: PdfColors.grey200)),
      ],
      pw.SizedBox(height: 32),

      // ━━━ FOOTER ━━━
      pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20),
        padding: const pw.EdgeInsets.all(18),
        decoration: pw.BoxDecoration(
          color: pale,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: paleBorder),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (s.phones.isNotEmpty)
            pw.Text(s.phones.join('   ·   '),
                style: pw.TextStyle(font: bold, fontSize: 16, color: primary),
                textAlign: pw.TextAlign.center),
          if (s.address != null) ...[
            pw.SizedBox(height: 5),
            pw.Text(s.address!,
                style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center),
          ],
          if (s.whatsappNumber != null || s.instagramUrl != null ||
              s.facebookUrl != null || s.websiteUrl != null) ...[
            pw.SizedBox(height: 8),
            pw.Container(height: 0.5, decoration: pw.BoxDecoration(color: paleBorder)),
            pw.SizedBox(height: 8),
            pw.Wrap(spacing: 18, alignment: pw.WrapAlignment.center, children: [
              if (s.whatsappNumber != null)
                pw.Text('WhatsApp  ${s.whatsappNumber!}',
                    style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600)),
              if (s.instagramUrl != null)
                pw.Text('Instagram  ${s.instagramUrl!}',
                    style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600)),
              if (s.facebookUrl != null)
                pw.Text('Facebook  ${s.facebookUrl!}',
                    style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600)),
              if (s.websiteUrl != null)
                pw.Text(s.websiteUrl!,
                    style: pw.TextStyle(font: regular, fontSize: 9, color: primary)),
            ]),
          ],
        ]),
      ),
      pw.SizedBox(height: 28),
    ],
  ));
  return doc;
}

pw.Text _luxeChip(String text, pw.Font font, PdfColor textColor) => pw.Text(
  '- $text',
  style: pw.TextStyle(font: font, fontSize: 10, color: PdfColor(textColor.red, textColor.green, textColor.blue, 0.78)),
);

// ─── PDF Builder: Design 2 — Street Bold ─────────────────────────────────────
// تسويقي — هيدر ضخم + كاتيجوري bands ملونة + سعر في badge + فوتر بارز

pw.Document _buildPdfStreetBold(
  MenuSettings s, Map<String, List<MenuProductConfig>> grouped,
  _PdfCustom custom, pw.Font regular, pw.Font bold,
) {
  final doc = pw.Document();
  final primary = custom.toPdf(custom.headerBg);
  final accent = custom.toPdf(custom.accentColor);
  final priceC = custom.toPdf(custom.priceColor);
  final itemC = custom.toPdf(custom.itemText);
  final headerTextC = custom.toPdf(custom.headerText);
  final dark = PdfColor(primary.red * 0.65, primary.green * 0.65, primary.blue * 0.65);
  final pale = PdfColor(accent.red, accent.green, accent.blue, 0.06);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    textDirection: pw.TextDirection.rtl,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    build: (ctx) => [
      // ━━━ MEGA HEADER ━━━
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(40, 40, 40, 32),
        decoration: pw.BoxDecoration(color: primary),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Container(width: 56, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.35))),
            pw.SizedBox(width: 12),
            pw.Container(width: 56, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.35))),
          ]),
          pw.SizedBox(height: 12),
          pw.Text(
            s.menuName.isEmpty ? 'قائمة الطعام' : s.menuName,
            style: pw.TextStyle(font: bold, fontSize: custom.titleSize, color: headerTextC),
            textAlign: pw.TextAlign.center,
          ),
          if (s.description != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(s.description!,
                style: pw.TextStyle(font: regular, fontSize: 13, color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.72)),
                textAlign: pw.TextAlign.center),
          ],
          pw.SizedBox(height: 16),
          // Phone prominent
          if (s.phones.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                s.phones.first,
                style: pw.TextStyle(font: bold, fontSize: 18, color: primary),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          if (s.address != null)
            pw.Text(s.address!,
                style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColor(1, 1, 1, 0.65)),
                textAlign: pw.TextAlign.center),
        ]),
      ),
      // Dark accent stripe
      pw.Container(height: 8, decoration: pw.BoxDecoration(color: dark)),
      pw.SizedBox(height: 20),

      // ━━━ PRODUCTS ━━━
      for (final entry in grouped.entries) ...[
        if (entry.key.isNotEmpty)
          // Full-width category band
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(top: 16, bottom: 4),
            padding: const pw.EdgeInsets.fromLTRB(28, 12, 28, 12),
            decoration: pw.BoxDecoration(color: primary),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text(entry.key,
                  style: pw.TextStyle(font: bold, fontSize: custom.catSize, color: headerTextC,
                      letterSpacing: 0.8)),
              pw.Text('${entry.value.length} أصناف',
                  style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.65))),
            ]),
          ),
        ...entry.value.asMap().entries.map((me) {
          final p = me.value;
          final even = me.key.isEven;
          return pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(28, 10, 28, 10),
            decoration: pw.BoxDecoration(color: even ? PdfColors.white : pale),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Bullet + name
                pw.Row(children: [
                  pw.Container(width: 5, height: 5, margin: const pw.EdgeInsets.only(left: 6, top: 2), decoration: pw.BoxDecoration(color: accent)),
                  pw.SizedBox(width: 6),
                  pw.Text(p.productName,
                      style: pw.TextStyle(font: regular, fontSize: custom.itemSize, color: itemC)),
                ]),
                if (s.showPrices) ...[
                  pw.SizedBox(width: 16),
                  // Price badge
                  pw.Container(
                    padding: const pw.EdgeInsets.fromLTRB(12, 5, 12, 5),
                    decoration: pw.BoxDecoration(
                      color: priceC,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      '${p.effectivePrice.toStringAsFixed(0)} ${s.currency}',
                      style: pw.TextStyle(font: bold, fontSize: custom.priceSize, color: PdfColors.white),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
      pw.SizedBox(height: 28),

      // ━━━ FOOTER ━━━
      pw.Container(height: 6, decoration: pw.BoxDecoration(color: dark)),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(40, 20, 40, 20),
        decoration: pw.BoxDecoration(color: primary),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (s.phones.length > 1)
            pw.Text(s.phones.skip(1).join('  |  '),
                style: pw.TextStyle(font: regular, fontSize: 11, color: PdfColor(1, 1, 1, 0.7)),
                textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 8),
          pw.Text('- تواصل معنا -',
              style: pw.TextStyle(font: bold, fontSize: 11, color: PdfColor(1, 1, 1, 0.55)),
              textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 8),
          pw.Wrap(spacing: 20, alignment: pw.WrapAlignment.center, children: [
            if (s.instagramUrl != null)
              pw.Text('Instagram: ${s.instagramUrl!}',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor(1, 1, 1, 0.75))),
            if (s.whatsappNumber != null)
              pw.Text('WhatsApp: ${s.whatsappNumber!}',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor(1, 1, 1, 0.75))),
            if (s.facebookUrl != null)
              pw.Text('Facebook: ${s.facebookUrl!}',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor(1, 1, 1, 0.75))),
            if (s.snapchatUrl != null)
              pw.Text('Snapchat: ${s.snapchatUrl!}',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor(1, 1, 1, 0.75))),
            if (s.websiteUrl != null)
              pw.Text(s.websiteUrl!,
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.white)),
          ]),
        ]),
      ),
    ],
  ));
  return doc;
}

// ─── PDF Builder: Design 3 — Clean Grid ──────────────────────────────────────
// عمودان + هيدر editorial + typography فاخر

pw.Document _buildPdfCleanEditorial(
  MenuSettings s, Map<String, List<MenuProductConfig>> grouped,
  _PdfCustom custom, pw.Font regular, pw.Font bold,
) {
  final doc = pw.Document();
  final primary = custom.toPdf(custom.headerBg);
  final accent = custom.toPdf(custom.accentColor);
  final priceC = custom.toPdf(custom.priceColor);
  final itemC = custom.toPdf(custom.itemText);
  const hPad = 44.0;
  const vPad = 40.0;

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    textDirection: pw.TextDirection.rtl,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    build: (ctx) => [
      // ━━━ HEADER ━━━
      pw.Container(
        width: double.infinity,
        padding: pw.EdgeInsets.fromLTRB(hPad, vPad, hPad, 24),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Name + description
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                // Vertical bar + name
                pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                  pw.Container(width: 6, height: 44, decoration: pw.BoxDecoration(color: primary)),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Text(
                      s.menuName.isEmpty ? 'قائمة الطعام' : s.menuName,
                      style: pw.TextStyle(font: bold, fontSize: custom.titleSize, color: primary),
                    ),
                  ),
                ]),
                if (s.description != null) ...[
                  pw.SizedBox(height: 6),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 20),
                    child: pw.Text(s.description!,
                        style: pw.TextStyle(font: regular, fontSize: 11, color: PdfColors.grey600)),
                  ),
                ],
              ]),
            ),
            pw.SizedBox(width: 20),
            // Contact block on the left (RTL = left side visually)
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              if (s.phones.isNotEmpty) ...[
                pw.Text(s.phones.first,
                    style: pw.TextStyle(font: bold, fontSize: 15, color: primary)),
                if (s.phones.length > 1)
                  pw.Text(s.phones[1],
                      style: pw.TextStyle(font: regular, fontSize: 12, color: PdfColors.grey600)),
              ],
              if (s.address != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(s.address!,
                    style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey500),
                    textAlign: pw.TextAlign.right),
              ],
            ]),
          ],
        ),
      ),
      // Bold rule
      pw.Container(
        height: 3, margin: pw.EdgeInsets.symmetric(horizontal: hPad),
        decoration: pw.BoxDecoration(color: primary),
      ),
      pw.Container(
        height: 1, margin: pw.EdgeInsets.fromLTRB(hPad, 3, hPad, 0),
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      ),
      pw.SizedBox(height: 20),

      // ━━━ PRODUCTS — 2-column grid ━━━
      pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: hPad),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            for (final entry in grouped.entries) ...[
              if (entry.key.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                // Category label with dots
                pw.Row(children: [
                  pw.Text(
                    entry.key.toUpperCase(),
                    style: pw.TextStyle(font: bold, fontSize: custom.catSize, color: accent, letterSpacing: 2.0),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(height: 1, decoration: const pw.BoxDecoration(color: PdfColors.grey300)),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text('${entry.value.length} صنف',
                      style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey500)),
                ]),
                pw.SizedBox(height: 8),
              ],
              // 2-column layout
              ..._pairChunks(entry.value).map((pair) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Column A
                    pw.Expanded(child: _editorialItem(pair[0], s, regular, bold, priceC, itemC, custom.itemSize, custom.priceSize)),
                    pw.Container(
                      width: 1, height: 28,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    ),
                    // Column B
                    pw.Expanded(
                      child: pair.length > 1
                          ? _editorialItem(pair[1], s, regular, bold, priceC, itemC, custom.itemSize, custom.priceSize)
                          : pw.SizedBox(),
                    ),
                  ],
                ),
              )),
              pw.Container(
                height: 1, margin: const pw.EdgeInsets.only(top: 6, bottom: 2),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(height: 30),

      // ━━━ FOOTER ━━━
      pw.Container(
        height: 1,
        margin: pw.EdgeInsets.symmetric(horizontal: hPad),
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      ),
      pw.Container(
        height: 3,
        margin: pw.EdgeInsets.fromLTRB(hPad, 2, hPad, 0),
        decoration: pw.BoxDecoration(color: primary),
      ),
      pw.SizedBox(height: 14),
      pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: hPad),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Wrap(spacing: 24, alignment: pw.WrapAlignment.center, children: [
            if (s.phones.isNotEmpty)
              pw.Text(s.phones.join('  •  '),
                  style: pw.TextStyle(font: bold, fontSize: 14, color: primary),
                  textAlign: pw.TextAlign.center),
            if (s.address != null)
              pw.Text(s.address!,
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey500)),
          ]),
          pw.SizedBox(height: 6),
          pw.Wrap(spacing: 16, alignment: pw.WrapAlignment.center, children: [
            if (s.instagramUrl != null)
              _editFooterItem('Instagram', s.instagramUrl!, regular, primary),
            if (s.whatsappNumber != null)
              _editFooterItem('WhatsApp', s.whatsappNumber!, regular, primary),
            if (s.facebookUrl != null)
              _editFooterItem('Facebook', s.facebookUrl!, regular, primary),
            if (s.snapchatUrl != null)
              _editFooterItem('Snapchat', s.snapchatUrl!, regular, primary),
            if (s.websiteUrl != null)
              pw.Text(s.websiteUrl!,
                  style: pw.TextStyle(font: regular, fontSize: 8, color: primary)),
          ]),
        ]),
      ),
      pw.SizedBox(height: 28),
    ],
  ));
  return doc;
}

pw.Widget _editorialItem(
  MenuProductConfig p, MenuSettings s,
  pw.Font regular, pw.Font bold,
  PdfColor priceC, PdfColor itemC, double itemSize, double priceSize,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(p.productName,
              style: pw.TextStyle(font: regular, fontSize: itemSize, color: itemC)),
        ),
        if (s.showPrices) ...[
          pw.SizedBox(width: 8),
          pw.Text(
            '${p.effectivePrice.toStringAsFixed(0)}',
            style: pw.TextStyle(font: bold, fontSize: priceSize, color: priceC),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _editFooterItem(String label, String value, pw.Font font, PdfColor primary) =>
    pw.Text('$label: $value',
        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500));

List<List<MenuProductConfig>> _pairChunks(List<MenuProductConfig> items) {
  final result = <List<MenuProductConfig>>[];
  for (int i = 0; i < items.length; i += 2) {
    result.add(items.sublist(i, i + 2 > items.length ? items.length : i + 2));
  }
  return result;
}

// ─── PDF Builder: Design 4 — Dark Luxury ─────────────────────────────────────
// خلفية داكنة كاملة + نص ذهبي + إطارات زخرفية للكاتيجوري

pw.Document _buildPdfDarkLuxury(
  MenuSettings s, Map<String, List<MenuProductConfig>> grouped,
  _PdfCustom custom, pw.Font regular, pw.Font bold,
) {
  final doc = pw.Document();
  final bgColor = PdfColor(0.05, 0.05, 0.05);
  final gold = custom.toPdf(custom.accentColor);
  final headerTextC = custom.toPdf(custom.headerText);
  final priceC = custom.toPdf(custom.priceColor);
  final itemC = custom.toPdf(custom.itemText);
  final goldDim = PdfColor(gold.red * 0.6, gold.green * 0.6, gold.blue * 0.6);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    textDirection: pw.TextDirection.rtl,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    build: (ctx) => [
      // ━━━ HEADER ━━━
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(44, 42, 44, 36),
        decoration: pw.BoxDecoration(color: bgColor),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          // Top rule
          pw.Container(width: double.infinity, height: 1, decoration: pw.BoxDecoration(color: gold)),
          pw.SizedBox(height: 16),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Container(width: 40, height: 1, decoration: pw.BoxDecoration(color: PdfColor(gold.red, gold.green, gold.blue, 0.5))),
            pw.SizedBox(width: 8),
            pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: PdfColor(gold.red, gold.green, gold.blue, 0.6))),
            pw.SizedBox(width: 8),
            pw.Container(width: 40, height: 1, decoration: pw.BoxDecoration(color: PdfColor(gold.red, gold.green, gold.blue, 0.5))),
          ]),
          pw.SizedBox(height: 12),
          pw.Text(
            s.menuName.isEmpty ? 'قائمة الطعام' : s.menuName,
            style: pw.TextStyle(font: bold, fontSize: custom.titleSize, color: gold, letterSpacing: 2.0),
            textAlign: pw.TextAlign.center,
          ),
          if (s.description != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(s.description!,
                style: pw.TextStyle(font: regular, fontSize: 12, color: PdfColor(gold.red, gold.green, gold.blue, 0.6)),
                textAlign: pw.TextAlign.center),
          ],
          pw.SizedBox(height: 14),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Container(width: 60, height: 1, decoration: pw.BoxDecoration(color: goldDim)),
            pw.SizedBox(width: 10),
            pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: goldDim)),
            pw.SizedBox(width: 10),
            pw.Container(width: 60, height: 1, decoration: pw.BoxDecoration(color: goldDim)),
          ]),
          pw.SizedBox(height: 12),
          if (s.phones.isNotEmpty)
            pw.Text(s.phones.first,
                style: pw.TextStyle(font: bold, fontSize: 14, color: headerTextC),
                textAlign: pw.TextAlign.center),
          if (s.address != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(s.address!,
                style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColor(gold.red, gold.green, gold.blue, 0.5)),
                textAlign: pw.TextAlign.center),
          ],
          pw.SizedBox(height: 16),
          pw.Container(width: double.infinity, height: 1, decoration: pw.BoxDecoration(color: gold)),
        ]),
      ),

      // ━━━ PRODUCTS ━━━
      pw.Container(
        decoration: pw.BoxDecoration(color: bgColor),
        padding: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 20),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          for (final entry in grouped.entries) ...[
            if (entry.key.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              // Ornate category box
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: gold, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key,
                        style: pw.TextStyle(font: bold, fontSize: custom.catSize, color: gold)),
                    pw.Text('${entry.value.length} صنف',
                        style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor(gold.red, gold.green, gold.blue, 0.5))),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
            ],
            ...entry.value.asMap().entries.map((me) {
              final p = me.value;
              return pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(8, 9, 8, 9),
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColor(gold.red, gold.green, gold.blue, 0.12))),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(children: [
                      pw.Container(width: 4, height: 4, margin: const pw.EdgeInsets.only(left: 4, top: 2), decoration: pw.BoxDecoration(color: PdfColor(gold.red, gold.green, gold.blue, 0.5))),
                      pw.Text(p.productName,
                          style: pw.TextStyle(font: regular, fontSize: custom.itemSize, color: itemC)),
                    ]),
                    if (s.showPrices)
                      pw.Text('${p.effectivePrice.toStringAsFixed(0)}  ${s.currency}',
                          style: pw.TextStyle(font: bold, fontSize: custom.priceSize, color: priceC)),
                  ],
                ),
              );
            }),
          ],
        ]),
      ),

      // ━━━ FOOTER ━━━
      pw.Container(
        decoration: pw.BoxDecoration(color: bgColor),
        padding: const pw.EdgeInsets.fromLTRB(44, 10, 44, 32),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Container(width: double.infinity, height: 1, decoration: pw.BoxDecoration(color: goldDim)),
          pw.SizedBox(height: 14),
          pw.Wrap(spacing: 20, alignment: pw.WrapAlignment.center, children: [
            if (s.instagramUrl != null)
              pw.Text('Instagram: ${s.instagramUrl!}',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor(gold.red, gold.green, gold.blue, 0.6))),
            if (s.whatsappNumber != null)
              pw.Text('WhatsApp: ${s.whatsappNumber!}',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor(gold.red, gold.green, gold.blue, 0.6))),
            if (s.facebookUrl != null)
              pw.Text('Facebook: ${s.facebookUrl!}',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor(gold.red, gold.green, gold.blue, 0.6))),
            if (s.websiteUrl != null)
              pw.Text(s.websiteUrl!,
                  style: pw.TextStyle(font: regular, fontSize: 9, color: gold)),
          ]),
          pw.SizedBox(height: 14),
          pw.Container(width: double.infinity, height: 1, decoration: pw.BoxDecoration(color: goldDim)),
        ]),
      ),
    ],
  ));
  return doc;
}

// ─── PDF Builder: Design 5 — Flyer Pro ───────────────────────────────────────
// هيدر ترويجي + منتجات كاملة متعددة الصفحات + فوتر تواصل

pw.Document _buildPdfFlyerPro(
  MenuSettings s, Map<String, List<MenuProductConfig>> grouped,
  _PdfCustom custom, pw.Font regular, pw.Font bold,
) {
  final doc = pw.Document();
  final primary = custom.toPdf(custom.headerBg);
  final accent = custom.toPdf(custom.accentColor);
  final priceC = custom.toPdf(custom.priceColor);
  final itemC = custom.toPdf(custom.itemText);
  final headerTextC = custom.toPdf(custom.headerText);
  final borderC = PdfColor(accent.red, accent.green, accent.blue, 0.2);
  const hPad = 32.0;

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    textDirection: pw.TextDirection.rtl,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    // ── HEADER (repeats on every page) ──
    header: (ctx) => pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(color: primary),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(hPad, 22, hPad, 18),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
              pw.Container(width: 44, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.4))),
              pw.SizedBox(width: 10),
              pw.Container(width: 44, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.4))),
            ]),
            pw.SizedBox(height: 8),
            pw.Text(
              s.menuName.isEmpty ? 'قائمة الطعام' : s.menuName,
              style: pw.TextStyle(font: bold, fontSize: custom.titleSize, color: headerTextC),
              textAlign: pw.TextAlign.center,
            ),
            if (s.description != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(s.description!,
                  style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.7)),
                  textAlign: pw.TextAlign.center),
            ],
            if (s.phones.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: pw.BoxDecoration(color: headerTextC, borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Text(s.phones.first,
                    style: pw.TextStyle(font: bold, fontSize: 14, color: primary),
                    textAlign: pw.TextAlign.center),
              ),
            ],
            pw.SizedBox(height: 8),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
              pw.Container(width: 44, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.4))),
              pw.SizedBox(width: 10),
              pw.Container(width: 44, height: 1, decoration: pw.BoxDecoration(color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.4))),
            ]),
          ]),
        ),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(border: pw.Border(
            top: pw.BorderSide(color: accent, width: 3),
          )),
        ),
      ]),
    ),
    // ── FOOTER (repeats on every page) ──
    footer: (ctx) => pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(color: primary),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(border: pw.Border(
            bottom: pw.BorderSide(color: accent, width: 3),
          )),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(hPad, 10, hPad, 12),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.Text('تواصل معنا',
                style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.6)),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 4),
            pw.Wrap(spacing: 16, alignment: pw.WrapAlignment.center, children: [
              if (s.phones.length > 1)
                pw.Text(s.phones.skip(1).join('  |  '),
                    style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.75))),
              if (s.address != null)
                pw.Text(s.address!,
                    style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.6))),
              if (s.instagramUrl != null)
                pw.Text('Instagram: ${s.instagramUrl!}',
                    style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.7))),
              if (s.whatsappNumber != null)
                pw.Text('WhatsApp: ${s.whatsappNumber!}',
                    style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColor(headerTextC.red, headerTextC.green, headerTextC.blue, 0.7))),
              if (s.websiteUrl != null)
                pw.Text(s.websiteUrl!,
                    style: pw.TextStyle(font: regular, fontSize: 8, color: headerTextC)),
            ]),
          ]),
        ),
      ]),
    ),
    // ── PRODUCTS (all items as separate list entries — MultiPage paginates) ──
    build: (ctx) {
      final items = <pw.Widget>[pw.SizedBox(height: 8)];
      for (final entry in grouped.entries) {
        if (entry.key.isNotEmpty) {
          items.add(pw.Container(
            margin: const pw.EdgeInsets.fromLTRB(hPad, 8, hPad, 4),
            child: pw.Row(children: [
              pw.Container(width: 3, height: 20, decoration: pw.BoxDecoration(color: accent)),
              pw.SizedBox(width: 8),
              pw.Text(entry.key,
                  style: pw.TextStyle(font: bold, fontSize: custom.catSize, color: accent)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.Container(height: 1, decoration: pw.BoxDecoration(color: borderC))),
              pw.SizedBox(width: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Text('${entry.value.length}',
                    style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white)),
              ),
            ]),
          ));
        }
        for (int i = 0; i < entry.value.length; i++) {
          final p = entry.value[i];
          items.add(pw.Container(
            margin: const pw.EdgeInsets.fromLTRB(hPad, 0, hPad, 2),
            padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 7),
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : PdfColor(accent.red, accent.green, accent.blue, 0.04),
              border: pw.Border(
                left: pw.BorderSide(color: borderC, width: 1),
                right: pw.BorderSide(color: borderC, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(p.productName,
                    style: pw.TextStyle(font: regular, fontSize: custom.itemSize, color: itemC)),
                if (s.showPrices)
                  pw.Container(
                    padding: const pw.EdgeInsets.fromLTRB(10, 4, 10, 4),
                    decoration: pw.BoxDecoration(color: priceC, borderRadius: pw.BorderRadius.circular(14)),
                    child: pw.Text(
                      '${p.effectivePrice.toStringAsFixed(0)} ${s.currency}',
                      style: pw.TextStyle(font: bold, fontSize: custom.priceSize, color: PdfColors.white),
                    ),
                  ),
              ],
            ),
          ));
        }
      }
      items.add(pw.SizedBox(height: 12));
      return items;
    },
  ));
  return doc;
}

// ─── QR Dialog ────────────────────────────────────────────────────────────────

class _QrDialog extends StatelessWidget {
  final String url;
  const _QrDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.t('menuQrCode'), style: AppTextStyles.h5),
            const SizedBox(height: 16),
            Container(
              width: 240,
              height: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.t('close')),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullPageHeader extends StatelessWidget {
  final MenuSettings settings;
  final Color primary;

  const _FullPageHeader({required this.settings, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.85)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settings.menuName.isEmpty ? 'Menu' : settings.menuName,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    if (settings.description != null)
                      Text(settings.description!, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          if (settings.address != null || settings.phones.isNotEmpty ||
              settings.instagramUrl != null || settings.whatsappNumber != null ||
              settings.facebookUrl != null || settings.snapchatUrl != null ||
              settings.websiteUrl != null) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 6, children: [
              if (settings.address != null)
                _FullPageInfoChip(Icons.location_on_rounded, settings.address!),
              ...settings.phones.map((p) => _FullPageInfoChip(Icons.phone_rounded, p)),
              if (settings.whatsappNumber != null)
                _FullPageInfoChip(Icons.chat_rounded, settings.whatsappNumber!),
              if (settings.instagramUrl != null)
                _FullPageInfoChip(Icons.camera_alt_rounded, settings.instagramUrl!),
              if (settings.facebookUrl != null)
                _FullPageInfoChip(Icons.facebook_rounded, settings.facebookUrl!),
              if (settings.snapchatUrl != null)
                _FullPageInfoChip(Icons.camera_rounded, settings.snapchatUrl!),
              if (settings.websiteUrl != null)
                _FullPageInfoChip(Icons.language_rounded, settings.websiteUrl!),
            ]),
          ],
        ],
      ),
    );
  }
}

class _FullPageInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FullPageInfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
    ]);
  }
}

// ignore: unused_element
class _FullPageModernGrid extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary, bg;

  const _FullPageModernGrid({required this.settings, required this.grouped, required this.primary, required this.bg});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FullPageHeader(settings: settings, primary: primary),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in grouped.entries) ...[
                  if (entry.key.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 16),
                      child: Row(children: [
                        Container(width: 4, height: 18, color: primary, margin: const EdgeInsets.only(right: 8)),
                        Text(entry.key, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                    ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, childAspectRatio: 0.85,
                      crossAxisSpacing: 12, mainAxisSpacing: 12,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (_, i) {
                      final p = entry.value[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(child: Container(
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.08),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            ),
                            child: Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.4), size: 32),
                          )),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.productName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (settings.showPrices)
                                Text('${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
                                    style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _FullPageDarkLuxury extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;

  const _FullPageDarkLuxury({required this.settings, required this.grouped});

  static const _gold = Color(0xFFD4A017);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 28),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(bottom: BorderSide(color: _gold, width: 1)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 2, height: 24, color: _gold),
                const SizedBox(width: 12),
                Text(settings.menuName, style: const TextStyle(color: _gold, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 3)),
                const SizedBox(width: 12),
                Container(width: 2, height: 24, color: _gold),
              ]),
              if (settings.description != null) ...[
                const SizedBox(height: 8),
                Text(settings.description!, style: const TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
              ],
              if (settings.address != null) ...[
                const SizedBox(height: 6),
                Text(settings.address!, style: const TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final entry in grouped.entries) ...[
                if (entry.key.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(children: [
                      Text('— ', style: const TextStyle(color: _gold, fontSize: 14)),
                      Text(entry.key.toUpperCase(), style: const TextStyle(color: _gold, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 2)),
                      Text(' —', style: const TextStyle(color: _gold, fontSize: 14)),
                    ]),
                  ),
                ...entry.value.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(p.productName, style: const TextStyle(color: Colors.white70, fontSize: 14))),
                    if (settings.showPrices) ...[
                      Container(width: 1, height: 16, color: _gold.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Text('${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
                          style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ]),
                )),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _FullPageMinimal extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary;

  const _FullPageMinimal({required this.settings, required this.grouped, required this.primary});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 48, 48, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(settings.menuName, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w200, letterSpacing: -1)),
              if (settings.description != null)
                Text(settings.description!, style: const TextStyle(color: Colors.black45, fontSize: 15)),
              if (settings.address != null)
                Text(settings.address!, style: const TextStyle(color: Colors.black38, fontSize: 13)),
              const SizedBox(height: 12),
              Container(width: 40, height: 2, color: primary),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final entry in grouped.entries) ...[
                if (entry.key.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    child: Text(entry.key.toUpperCase(), style: const TextStyle(color: Colors.black38, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
                  ),
                ...entry.value.map((p) => Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Expanded(child: Text(p.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400))),
                      if (settings.showPrices)
                        Text('${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
                            style: TextStyle(color: Colors.black54, fontSize: 14)),
                    ]),
                  ),
                  Divider(height: 1, color: Colors.black.withOpacity(0.06)),
                ])),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

// Theme 6 Full Page: Promotional Flyer
// ignore: unused_element
class _FullPageFlyer extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary, bg;

  const _FullPageFlyer({required this.settings, required this.grouped, required this.primary, required this.bg});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg == Colors.white ? const Color(0xFFFFF8E7) : bg,
      child: Column(
        children: [
          // Bold header band
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(settings.menuName, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    if (settings.description != null)
                      Text(settings.description!, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                  ]),
                ),
              ],
            ),
          ),
          // Products
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in grouped.entries) ...[
                  if (entry.key.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10, top: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ...entry.value.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.5), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                      if (settings.showPrices)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(6)),
                          child: Text('${p.effectivePrice.toStringAsFixed(0)} ${settings.currency}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                    ]),
                  )),
                ],
              ],
            ),
          ),
          // Footer contact strip
          if (settings.phones.isNotEmpty || settings.address != null || settings.whatsappNumber != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.2)),
              ),
              child: Wrap(
                spacing: 24, runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (settings.phones.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.phone_rounded, color: primary, size: 16),
                      const SizedBox(width: 6),
                      Text(settings.phones.first, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                  if (settings.address != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on_rounded, color: primary, size: 16),
                      const SizedBox(width: 6),
                      Text(settings.address!, style: TextStyle(color: primary, fontSize: 13)),
                    ]),
                  if (settings.instagramUrl != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.camera_alt_rounded, color: primary, size: 16),
                      const SizedBox(width: 6),
                      Text(settings.instagramUrl!, style: TextStyle(color: primary, fontSize: 13)),
                    ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

}

// Theme 7 Full Page: Billboard
// ignore: unused_element
class _FullPageBillboard extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary;

  const _FullPageBillboard({required this.settings, required this.grouped, required this.primary});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: primary,
      child: Column(
        children: [
          // Hero
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
            child: Column(children: [
              const Icon(Icons.restaurant_rounded, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              Text(settings.menuName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2), textAlign: TextAlign.center),
              if (settings.description != null) ...[
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 8),
                Text(settings.description!, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              ],
            ]),
          ),
          // Cards on white
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final entry in grouped.entries) ...[
                if (entry.key.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 16),
                    child: Text(entry.key, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.3)),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 1.4,
                    crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (_, i) {
                    final p = entry.value[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primary.withOpacity(0.15)),
                        boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 8)],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(p.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (settings.showPrices)
                          Text('${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
                              style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                    );
                  },
                ),
              ],
              if (settings.phones.isNotEmpty || settings.address != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Wrap(spacing: 20, runSpacing: 6, children: [
                  ...settings.phones.map((p) => Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.phone_rounded, color: primary, size: 14),
                    const SizedBox(width: 4),
                    Text(p, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ])),
                  if (settings.address != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on_rounded, color: Colors.black45, size: 14),
                      const SizedBox(width: 4),
                      Text(settings.address!, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                    ]),
                ]),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

// Theme 8 Full Page: Elegant Cards
// ignore: unused_element
class _FullPageCards extends StatelessWidget {
  final MenuSettings settings;
  final Map<String, List<MenuProductConfig>> grouped;
  final Color primary, bg;

  const _FullPageCards({required this.settings, required this.grouped, required this.primary, required this.bg});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _FullPageHeader(settings: settings, primary: primary),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                for (final entry in grouped.entries) ...[
                  if (entry.key.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 16),
                        child: Text(entry.key, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: -0.3)),
                      ),
                    ),
                  ...entry.value.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.5), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        if (p.categoryName != null)
                          Text(p.categoryName!, style: const TextStyle(fontSize: 11, color: Colors.black38)),
                      ])),
                      if (settings.showPrices)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
                              style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                    ]),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
