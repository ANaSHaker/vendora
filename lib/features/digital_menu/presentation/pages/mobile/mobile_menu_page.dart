import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../features/products/domain/usecases/products_usecases.dart';
import '../../../domain/entities/menu_entities.dart';
import '../../../domain/usecases/menu_usecases.dart';
import '../../cubit/menu_cubit.dart';
import '../../cubit/menu_state.dart';

class MobileMenuPage extends StatelessWidget {
  const MobileMenuPage({super.key});

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
      child: const _MobileMenuView(),
    );
  }
}

class _MobileMenuView extends StatelessWidget {
  const _MobileMenuView();

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
            appBar: AppBar(title: Text(l10n.t('digitalMenu'))),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.destructive),
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
        final cubit = context.read<MenuCubit>();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.t('digitalMenu')),
              actions: [
                if (loaded.isSaving)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.save_rounded),
                    tooltip: l10n.t('save'),
                    onPressed: cubit.save,
                  ),
              ],
              bottom: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.mutedForeground,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: l10n.t('menuInfo')),
                  Tab(text: l10n.t('menuProducts')),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _MobileInfoTab(settings: loaded.settings, cubit: cubit),
                _MobileProductsTab(
                    products: loaded.products,
                    settings: loaded.settings,
                    cubit: cubit),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileInfoTab extends StatefulWidget {
  final MenuSettings settings;
  final MenuCubit cubit;
  const _MobileInfoTab({required this.settings, required this.cubit});

  @override
  State<_MobileInfoTab> createState() => _MobileInfoTabState();
}

class _MobileInfoTabState extends State<_MobileInfoTab> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.settings.menuName);
    _slugCtrl = TextEditingController(text: widget.settings.slug);
    _descCtrl = TextEditingController(text: widget.settings.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _flush() {
    widget.cubit.updateSettings((s) => s.copyWith(
          menuName: _nameCtrl.text.trim(),
          slug: _slugCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '-'),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _field('Menu Name', _nameCtrl),
        _field('Slug', _slugCtrl),
        _field('Description', _descCtrl, maxLines: 3),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          const Expanded(child: Text('Show Prices')),
          Switch(
            value: widget.settings.showPrices,
            onChanged: (v) =>
                widget.cubit.updateSettings((s) => s.copyWith(showPrices: v)),
            activeColor: AppColors.primary,
          ),
        ]),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (_) => _flush(),
      ),
    );
  }
}

class _MobileProductsTab extends StatelessWidget {
  final List<MenuProductConfig> products;
  final MenuSettings settings;
  final MenuCubit cubit;

  const _MobileProductsTab({
    required this.products, required this.settings, required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('No products'));
    }
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return ListTile(
          leading: Switch(
            value: p.isVisible,
            onChanged: (_) => cubit.toggleProduct(p.productId),
            activeColor: AppColors.primary,
          ),
          title: Text(p.productName,
              style: TextStyle(
                  color: p.isVisible
                      ? null
                      : AppColors.mutedForeground)),
          subtitle: Text(p.categoryName ?? ''),
          trailing: Text(
            '${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
