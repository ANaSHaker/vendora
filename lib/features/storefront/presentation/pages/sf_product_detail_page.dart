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
import '../widgets/sf_button.dart';

class SfProductDetailPage extends StatefulWidget {
  final String slug;
  final String productId;
  const SfProductDetailPage({super.key, required this.slug, required this.productId});

  @override
  State<SfProductDetailPage> createState() => _SfProductDetailPageState();
}

class _SfProductDetailPageState extends State<SfProductDetailPage> {
  SfProduct? _product;
  bool       _loading = true;
  String?    _error;
  int        _quantity = 1;
  int        _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await getIt<GetSfProductUseCase>()(widget.slug, widget.productId);
    res.fold((f) => _error = f.message, (v) => _product = v);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final l10n   = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final currency = context.read<StorefrontCubit>().state is StorefrontLoaded
        ? (context.read<StorefrontCubit>().state as StorefrontLoaded).vendor.currency
        : '';

    if (_loading) return const Center(child: Padding(
        padding: EdgeInsets.all(64), child: CircularProgressIndicator()));

    if (_error != null || _product == null) return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: t.textMuted),
          const SizedBox(height: 12),
          Text(_error ?? 'Product not found', style: TextStyle(color: t.textMuted)),
          const SizedBox(height: 12),
          TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
        ]),
      ),
    );

    final p = _product!;
    final allImages = [
      if (p.image != null) p.image!,
      ...p.images.map((i) => i.url),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 16, vertical: 32),
      child: isWide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: _Gallery(images: allImages, t: t,
                  index: _imageIndex, onSelect: (i) => setState(() => _imageIndex = i))),
              const SizedBox(width: 48),
              Expanded(flex: 5, child: _Info(p: p, t: t, l10n: l10n,
                  currency: currency, quantity: _quantity,
                  onQtyChange: (v) => setState(() => _quantity = v),
                  onAddToCart: _addToCart)),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Gallery(images: allImages, t: t,
                  index: _imageIndex, onSelect: (i) => setState(() => _imageIndex = i)),
              const SizedBox(height: 24),
              _Info(p: p, t: t, l10n: l10n,
                  currency: currency, quantity: _quantity,
                  onQtyChange: (v) => setState(() => _quantity = v),
                  onAddToCart: _addToCart),
            ]),
    );
  }

  void _addToCart() {
    if (_product == null) return;
    context.read<StorefrontCubit>().addToCart(_product!, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product!.name} added to cart'),
        backgroundColor: StorefrontTheme.of(context).primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StorefrontTheme.of(context).radius)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  final List<String> images;
  final SfThemeData t;
  final int index;
  final ValueChanged<int> onSelect;
  const _Gallery({required this.images, required this.t,
    required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final main = images.isNotEmpty ? images[index] : null;
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(t.radius),
        child: AspectRatio(
          aspectRatio: 1,
          child: main != null
              ? Image.network(main, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: t.surfaceHigh,
                    child: Icon(Icons.image_outlined, size: 64, color: t.textSubtle)))
              : Container(color: t.surfaceHigh,
                  child: Icon(Icons.image_outlined, size: 64, color: t.textSubtle)),
        ),
      ),
      if (images.length > 1) ...[
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: images.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onSelect(i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(t.radius / 2),
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    border: i == index
                        ? Border.all(color: t.primary, width: 2)
                        : Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(t.radius / 2),
                  ),
                  child: Image.network(images[i], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: t.surfaceHigh)),
                ),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _Info extends StatelessWidget {
  final SfProduct p;
  final SfThemeData t;
  final AppLocalizations l10n;
  final String currency;
  final int quantity;
  final ValueChanged<int> onQtyChange;
  final VoidCallback onAddToCart;
  const _Info({required this.p, required this.t, required this.l10n,
    required this.currency, required this.quantity,
    required this.onQtyChange, required this.onAddToCart});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (p.category != null)
        Text(p.category!.name,
          style: TextStyle(fontSize: 12, color: t.primary, fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
      const SizedBox(height: 6),
      Text(p.name,
        style: TextStyle(fontSize: 28, fontWeight: t.headingWeight,
            color: t.text, height: 1.15)),
      const SizedBox(height: 12),
      Row(children: [
        Text('$currency ${p.price.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: t.primary)),
        if (p.hasDiscount) ...[
          const SizedBox(width: 10),
          Text('$currency ${p.oldPrice!.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, color: t.textMuted,
                decoration: TextDecoration.lineThrough)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
            child: Text('-${p.discountPercent.round()}%',
              style: const TextStyle(color: Colors.red, fontSize: 12,
                  fontWeight: FontWeight.w700)),
          ),
        ],
      ]),
      if (p.description != null && p.description!.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(p.description!,
          style: TextStyle(fontSize: 14, color: t.textMuted, height: 1.7)),
      ],
      const SizedBox(height: 24),
      Row(children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(t.radius)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: Icon(Icons.remove, size: 16, color: t.text),
              onPressed: quantity > 1 ? () => onQtyChange(quantity - 1) : null,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('$quantity', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700, color: t.text)),
            ),
            IconButton(
              icon: Icon(Icons.add, size: 16, color: t.text),
              onPressed: () => onQtyChange(quantity + 1),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SfButton(
            label: l10n.sfAddToCart,
            onPressed: p.stock > 0 ? onAddToCart : null,
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
          ),
        ),
      ]),
      if (p.stock <= 0) ...[
        const SizedBox(height: 8),
        Text('Out of stock', style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
      ],
    ],
  );
}
