import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/di/injection.dart';
import '../../../../../../design_system/widgets/images/app_network_image.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../../domain/entities/product_entities.dart';
import '../../../cubit/product_form_cubit.dart';
import '../../../cubit/product_form_state.dart';

class ProductFormDialog extends StatelessWidget {
  final ProductEntity? editing;
  final List<CategoryEntity> categories;
  final VoidCallback onSaved;

  const ProductFormDialog({
    super.key,
    this.editing,
    required this.categories,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    ProductEntity? editing,
    required List<CategoryEntity> categories,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(
        editing: editing,
        categories: categories,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductFormCubit(
        create: getIt(),
        update: getIt(),
        editing: editing,
      ),
      child: _ProductFormContent(
        isEditing: editing != null,
        categories: categories,
        onSaved: onSaved,
      ),
    );
  }
}

class _ProductFormContent extends StatefulWidget {
  final bool isEditing;
  final List<CategoryEntity> categories;
  final VoidCallback onSaved;

  const _ProductFormContent({
    required this.isEditing,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<_ProductFormContent> createState() => _ProductFormContentState();
}

class _ProductFormContentState extends State<_ProductFormContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

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

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<ProductFormCubit>();
    final ok = await cubit.submit();
    if (ok && context.mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ProductFormCubit, ProductFormState>(
      builder: (context, formState) {
        final cubit = context.read<ProductFormCubit>();
        return Dialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
          child: SizedBox(
            width: 580,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.isEditing ? l10n.editProduct : l10n.addProduct,
                        style: AppTextStyles.h5,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                // Tabs
                TabBar(
                  controller: _tabs,
                  labelStyle: AppTextStyles.labelSm,
                  tabs: [
                    Tab(text: l10n.t('basicInfo')),
                    Tab(text: l10n.t('visibilityTab')),
                    Tab(text: l10n.t('storeOptionsTab')),
                  ],
                ),
                const Divider(height: 1, color: AppColors.border),
                // Content
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _BasicInfoTab(
                        cubit: cubit,
                        formState: formState,
                        categories: widget.categories,
                      ),
                      _VisibilityTab(
                        formState: formState,
                        cubit: cubit,
                      ),
                      widget.isEditing
                          ? _StoreOptionsTab(productId: cubit.editingId!)
                          : _StoreOptionsDisabled(l10n: l10n),
                    ],
                  ),
                ),
                // Error
                if (formState.serverError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      formState.serverError!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.destructive),
                    ),
                  ),
                const Divider(height: 1, color: AppColors.border),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton.outline(
                        label: l10n.cancel,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton.primary(
                        label: widget.isEditing ? l10n.saveChanges : l10n.t('createProduct'),
                        isLoading:
                            formState.status == ProductFormStatus.submitting,
                        onPressed:
                            formState.status == ProductFormStatus.submitting
                                ? null
                                : () => _submit(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BasicInfoTab extends StatefulWidget {
  final ProductFormCubit cubit;
  final ProductFormState formState;
  final List<CategoryEntity> categories;

  const _BasicInfoTab({
    required this.cubit,
    required this.formState,
    required this.categories,
  });

  @override
  State<_BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends State<_BasicInfoTab> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _unitCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.cubit.state;
    _nameCtrl = TextEditingController(text: s.name)
      ..selection = TextSelection.collapsed(offset: s.name.length);
    _skuCtrl = TextEditingController(text: s.sku);
    _barcodeCtrl = TextEditingController(text: s.barcode);
    _priceCtrl = TextEditingController(text: s.price);
    _descCtrl = TextEditingController(text: s.description);
    _unitCtrl = TextEditingController(text: s.unit);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    widget.cubit.setImageBytes(result.files.single.bytes!.toList());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ProductFormCubit, ProductFormState>(
      buildWhen: (p, c) =>
          p.errors != c.errors ||
          p.categoryId != c.categoryId ||
          p.imageBytes != c.imageBytes,
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              AppTextField(
                label: '${l10n.t("productName")} *',
                hint: l10n.t('productNameHint'),
                errorText: state.errors['name'],
                onChanged: widget.cubit.setName,
                controller: _nameCtrl,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: l10n.colSku,
                      hint: 'COF-001',
                      onChanged: widget.cubit.setSku,
                      controller: _skuCtrl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: l10n.t('barcode'),
                      hint: '123456789',
                      onChanged: widget.cubit.setBarcode,
                      controller: _barcodeCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: '${l10n.colPrice} *',
                      hint: '0.00',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      errorText: state.errors['price'],
                      onChanged: widget.cubit.setPrice,
                      controller: _priceCtrl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: l10n.t('unit'),
                      hint: l10n.t('unitHint'),
                      onChanged: widget.cubit.setUnit,
                      controller: _unitCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppSelectField<String>(
                label: l10n.colCategory,
                hint: l10n.allCategories,
                value: state.categoryId,
                options: widget.categories
                    .map((c) => AppSelectOption(value: c.id, label: c.name))
                    .toList(),
                onChanged: widget.cubit.setCategory,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.t('description'),
                hint: l10n.t('descriptionHint'),
                maxLines: 2,
                onChanged: widget.cubit.setDescription,
                controller: _descCtrl,
              ),
              const SizedBox(height: AppSpacing.md),
              // Image picker
              _ImagePickerSection(
                imageBytes: state.imageBytes,
                existingImageUrl: state.existingImageUrl,
                onPick: _pickImage,
                onRemove: widget.cubit.clearImage,
                l10n: l10n,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  final List<int>? imageBytes;
  final String? existingImageUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final AppLocalizations l10n;

  const _ImagePickerSection({
    required this.imageBytes,
    required this.existingImageUrl,
    required this.onPick,
    required this.onRemove,
    required this.l10n,
  });

  static String? _resolve(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '$kApiBaseUrl${raw.startsWith('/') ? '' : '/'}$raw';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;

    final hasNewImage = imageBytes != null;
    final resolvedUrl = _resolve(existingImageUrl);
    final hasExistingImage = resolvedUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('productImage'),
          style: AppTextStyles.labelSm.copyWith(color: muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (hasNewImage)
          Stack(
            children: [
              ClipRRect(
                borderRadius: AppRadius.brMd,
                child: Image.memory(
                  Uint8List.fromList(imageBytes!),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else if (hasExistingImage)
          Stack(
            children: [
              SizedBox(
                height: 100,
                width: double.infinity,
                child: AppNetworkImage(
                  url: resolvedUrl,
                  height: 100,
                  borderRadius: 8,
                  fallbackColor: bg,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onPick,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          l10n.t('changeImage'),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border),
                borderRadius: AppRadius.brMd,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 24, color: muted),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t('selectImage'),
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _VisibilityTab extends StatelessWidget {
  final ProductFormState formState;
  final ProductFormCubit cubit;

  const _VisibilityTab({required this.formState, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _ToggleRow(
          title: l10n.t('availableOnline'),
          subtitle: l10n.t('availableOnlineHint'),
          value: formState.isOnline,
          onChanged: cubit.setIsOnline,
        ),
        const Divider(height: AppSpacing.xl, color: AppColors.border),
        _ToggleRow(
          title: l10n.t('published'),
          subtitle: l10n.t('publishedHint'),
          value: formState.isPublished,
          onChanged: cubit.setIsPublished,
        ),
        const Divider(height: AppSpacing.xl, color: AppColors.border),
        _ToggleRow(
          title: l10n.t('featured'),
          subtitle: l10n.t('featuredHint'),
          value: formState.isFeatured,
          onChanged: cubit.setIsFeatured,
        ),
        const Divider(height: AppSpacing.xl, color: AppColors.border),
        _ToggleRow(
          title: l10n.t('trackStock'),
          subtitle: l10n.t('trackStockHint'),
          value: formState.trackStock,
          onChanged: cubit.setTrackStock,
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelMd),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}

// ─── Store Options Tab ────────────────────────────────────────────────────────

class _OptionValue {
  TextEditingController valueCtrl;
  TextEditingController priceCtrl;
  TextEditingController skuCtrl;

  _OptionValue({String value = '', double priceDelta = 0, String skuSuffix = ''})
      : valueCtrl = TextEditingController(text: value),
        priceCtrl = TextEditingController(
            text: priceDelta == 0 ? '' : priceDelta.toStringAsFixed(2)),
        skuCtrl = TextEditingController(text: skuSuffix);

  void dispose() {
    valueCtrl.dispose();
    priceCtrl.dispose();
    skuCtrl.dispose();
  }

  Map<String, dynamic> toJson(int sortOrder) => {
        'value': valueCtrl.text.trim(),
        'price_delta': double.tryParse(priceCtrl.text) ?? 0,
        'sku_suffix': skuCtrl.text.trim(),
        'sort_order': sortOrder,
      };
}

class _OptionGroup {
  TextEditingController nameCtrl;
  String type;
  bool isRequired;
  bool expanded = true;
  List<_OptionValue> values;

  _OptionGroup({
    String name = '',
    this.type = 'select',
    this.isRequired = false,
    List<_OptionValue>? values,
  })  : nameCtrl = TextEditingController(text: name),
        values = values ?? [_OptionValue()];

  void dispose() {
    nameCtrl.dispose();
    for (final v in values) {
      v.dispose();
    }
  }

  Map<String, dynamic> toJson(int sortOrder) => {
        'name': nameCtrl.text.trim(),
        'type': type,
        'is_required': isRequired,
        'sort_order': sortOrder,
        'values': values
            .asMap()
            .entries
            .map((e) => e.value.toJson(e.key))
            .toList(),
      };
}

class _StoreOptionsTab extends StatefulWidget {
  final String productId;

  const _StoreOptionsTab({required this.productId});

  @override
  State<_StoreOptionsTab> createState() => _StoreOptionsTabState();
}

class _StoreOptionsTabState extends State<_StoreOptionsTab> {
  final _client = getIt<ApiClient>();
  final List<_OptionGroup> _groups = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final g in _groups) {
      g.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _client
          .get<Map<String, dynamic>>('/api/products/${widget.productId}/options');
      final data = res.data;
      if (!mounted) return;
      final rawList =
          (data?['options'] ?? data?['data'] ?? []) as List<dynamic>;
      setState(() {
        _groups.clear();
        for (final raw in rawList) {
          final values = (raw['values'] as List<dynamic>?)
              ?.map((v) => _OptionValue(
                    value: v['value'] as String? ?? '',
                    priceDelta: (v['price_delta'] as num?)?.toDouble() ?? 0,
                    skuSuffix: v['sku_suffix'] as String? ?? '',
                  ))
              .toList();
          _groups.add(_OptionGroup(
            name: raw['name'] as String? ?? '',
            type: raw['type'] as String? ?? 'select',
            isRequired: raw['is_required'] as bool? ?? false,
            values: values ?? [_OptionValue()],
          ));
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    // Validate
    for (final g in _groups) {
      if (g.nameCtrl.text.trim().isEmpty) {
        setState(() => _error = l10n.t('optionNameRequired'));
        return;
      }
      if (g.values.isEmpty ||
          g.values.every((v) => v.valueCtrl.text.trim().isEmpty)) {
        setState(() => _error = l10n.t('optionValueRequired'));
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _client.put<dynamic>(
        '/api/products/${widget.productId}/options',
        data: {
          'options': _groups
              .asMap()
              .entries
              .map((e) => e.value.toJson(e.key))
              .toList(),
        },
      );
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('saveOptions'))),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Column(
      children: [
        Expanded(
          child: _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 40, color: muted),
                      const SizedBox(height: AppSpacing.sm),
                      Text(l10n.t('noOptionsYet'),
                          style:
                              AppTextStyles.labelMd.copyWith(color: muted)),
                      const SizedBox(height: 4),
                      Text(l10n.t('addFirstOption'),
                          style:
                              AppTextStyles.bodySm.copyWith(color: muted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _groups.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) =>
                      _buildGroupCard(i, border, bg, fg, muted, l10n),
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(_error!,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.destructive)),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() =>
                    _groups.add(_OptionGroup())),
                icon: const Icon(Icons.add, size: 16),
                label: Text(l10n.t('addOption')),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(l10n.t('saveOptions')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(
    int i,
    Color border,
    Color bg,
    Color fg,
    Color muted,
    AppLocalizations l10n,
  ) {
    final g = _groups[i];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: g.nameCtrl,
                    style: AppTextStyles.labelMd.copyWith(color: fg),
                    decoration: InputDecoration(
                      hintText: l10n.t('optionName'),
                      hintStyle:
                          AppTextStyles.labelMd.copyWith(color: muted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                // Type toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypeChip(
                      label: l10n.t('optionTypeSelect'),
                      selected: g.type == 'select',
                      onTap: () => setState(() => g.type = 'select'),
                    ),
                    const SizedBox(width: 4),
                    _TypeChip(
                      label: l10n.t('optionTypeMulti'),
                      selected: g.type == 'multi',
                      onTap: () => setState(() => g.type = 'multi'),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.xs),
                // Required toggle
                Tooltip(
                  message: l10n.t('optionRequired'),
                  child: GestureDetector(
                    onTap: () => setState(() => g.isRequired = !g.isRequired),
                    child: Icon(
                      g.isRequired
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 18,
                      color: g.isRequired
                          ? AppColors.primary
                          : muted,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 16, color: muted),
                  onPressed: () {
                    setState(() {
                      _groups[i].dispose();
                      _groups.removeAt(i);
                    });
                  },
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: Icon(
                    g.expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: muted,
                  ),
                  onPressed: () => setState(() => g.expanded = !g.expanded),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (g.expanded) ...[
            Divider(height: 1, color: border),
            // Values header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, 4),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(l10n.t('optionValue'),
                          style:
                              AppTextStyles.labelXs.copyWith(color: muted))),
                  Expanded(
                      child: Text(l10n.t('priceDelta'),
                          style:
                              AppTextStyles.labelXs.copyWith(color: muted))),
                  SizedBox(
                      width: 80,
                      child: Text(l10n.t('skuSuffix'),
                          style:
                              AppTextStyles.labelXs.copyWith(color: muted))),
                  const SizedBox(width: 28),
                ],
              ),
            ),
            // Values list
            for (int j = 0; j < g.values.length; j++)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 2, AppSpacing.xs, 2),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: g.values[j].valueCtrl,
                        style: AppTextStyles.bodySm.copyWith(color: fg),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'e.g. Large',
                          hintStyle: AppTextStyles.bodySm
                              .copyWith(color: muted),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 6),
                          isDense: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: g.values[j].priceCtrl,
                        style: AppTextStyles.bodySm.copyWith(color: fg),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '+0.00',
                          hintStyle: AppTextStyles.bodySm
                              .copyWith(color: muted),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 6),
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: g.values[j].skuCtrl,
                        style: AppTextStyles.bodySm.copyWith(color: fg),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '-L',
                          hintStyle: AppTextStyles.bodySm
                              .copyWith(color: muted),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 6),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          size: 14, color: muted),
                      onPressed: g.values.length > 1
                          ? () => setState(() {
                                g.values[j].dispose();
                                g.values.removeAt(j);
                              })
                          : null,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            // Add value button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 4, AppSpacing.md, AppSpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() => g.values.add(_OptionValue())),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(l10n.t('addValue'),
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: AppRadius.brSm,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyXs.copyWith(
            color: selected ? AppColors.primary : AppColors.mutedForeground,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StoreOptionsDisabled extends StatelessWidget {
  final AppLocalizations l10n;

  const _StoreOptionsDisabled({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.save_outlined, size: 40, color: muted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.t('saveProductFirst'),
            style: AppTextStyles.labelMd.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('saveProductFirstHint'),
            style: AppTextStyles.bodySm.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
