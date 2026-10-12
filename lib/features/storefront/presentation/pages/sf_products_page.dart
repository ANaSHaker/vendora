import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/sf_entities.dart';
import '../../domain/usecases/sf_usecases.dart';
import '../../../../core/di/injection.dart';
import '../cubit/storefront_cubit.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';
import '../widgets/sf_product_card.dart';

class SfProductsPage extends StatefulWidget {
  final String slug;
  const SfProductsPage({super.key, required this.slug});

  @override
  State<SfProductsPage> createState() => _SfProductsPageState();
}

class _SfProductsPageState extends State<SfProductsPage> {
  List<SfProduct>    _products   = [];
  List<SfCategory>   _categories = [];
  String?            _activeCat;
  String             _search     = '';
  bool               _loading    = true;
  String?            _error;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cats = await getIt<GetSfCategoriesUseCase>()(widget.slug);
      final prods = await getIt<GetSfProductsUseCase>()(
        widget.slug, search: _search, categoryId: _activeCat);
      cats.fold((f) => _error = f.message, (v) => _categories = v);
      prods.fold((f) => _error = f.message, (v) => _products = v);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final l10n   = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 16, vertical: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title
        Text(l10n.sfProducts,
          style: TextStyle(fontSize: 28, fontWeight: t.headingWeight,
              color: t.text, letterSpacing: t.headingLetterSpacing)),
        const SizedBox(height: 20),
        // Search
        TextField(
          controller: _ctrl,
          style: TextStyle(color: t.text),
          decoration: InputDecoration(
            hintText: l10n.sfSearch,
            hintStyle: TextStyle(color: t.textMuted),
            prefixIcon: Icon(Icons.search, color: t.textMuted),
            suffixIcon: _search.isNotEmpty
                ? IconButton(icon: Icon(Icons.close, color: t.textMuted),
                    onPressed: () { _ctrl.clear(); setState(() => _search = ''); _load(); })
                : null,
            filled: true, fillColor: t.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radius),
              borderSide: BorderSide(color: t.border)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radius),
              borderSide: BorderSide(color: t.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radius),
              borderSide: BorderSide(color: t.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: (v) { setState(() => _search = v); _load(); },
          onChanged: (v) { if (v.isEmpty) { setState(() => _search = ''); _load(); } },
        ),
        const SizedBox(height: 16),
        // Category filter chips
        if (_categories.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CatChip(
                  label: l10n.sfAllCategories,
                  selected: _activeCat == null,
                  t: t,
                  onTap: () { setState(() => _activeCat = null); _load(); },
                ),
                ..._categories.map((c) => _CatChip(
                  label: c.name, selected: _activeCat == c.id, t: t,
                  onTap: () { setState(() => _activeCat = c.id); _load(); },
                )),
              ],
            ),
          ),
        const SizedBox(height: 24),
        // Grid
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Center(child: Text(_error!, style: TextStyle(color: t.textMuted)))
        else if (_products.isEmpty)
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: t.textSubtle),
            const SizedBox(height: 12),
            Text(l10n.sfNoProducts, style: TextStyle(color: t.textMuted, fontSize: 16)),
          ]))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 16, mainAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: _products.length,
            itemBuilder: (_, i) {
              final p = _products[i];
              return SfProductCard(
                product: p,
                currency: context.read<StorefrontCubit>().state is StorefrontLoaded
                    ? (context.read<StorefrontCubit>().state as StorefrontLoaded).vendor.currency
                    : '',
                onTap: () => context.go('/store/${widget.slug}/products/${p.id}'),
                onAddToCart: () =>
                    context.read<StorefrontCubit>().addToCart(p),
              );
            },
          ),
      ]),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final SfThemeData t;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.selected,
    required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? t.primary : t.surface,
          borderRadius: BorderRadius.circular(t.buttonRadius.clamp(4, 999)),
          border: selected ? null : Border.all(color: t.border),
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? t.primaryFg : t.text,
            fontSize: 13, fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}
