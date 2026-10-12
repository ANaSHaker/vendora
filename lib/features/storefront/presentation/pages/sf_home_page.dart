import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/sf_mock_data.dart';
import '../../domain/entities/sf_entities.dart';
import '../cubit/storefront_cubit.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_image.dart';

class SfHomePage extends StatelessWidget {
  final String slug;
  const SfHomePage({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StorefrontCubit, StorefrontState>(
      builder: (ctx, state) {
        if (state is! StorefrontLoaded) return const SizedBox.shrink();
        return _HomeContent(slug: slug, vendor: state.vendor);
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String slug;
  final SfVendorInfo vendor;
  const _HomeContent({required this.slug, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(children: [
      _HeroSection(slug: slug, vendor: vendor),
      _FeaturedSection(slug: slug, l10n: l10n),
      _CategoriesSection(slug: slug, l10n: l10n),
      _PromoSection(slug: slug, vendor: vendor, l10n: l10n),
    ]);
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String slug;
  final SfVendorInfo vendor;
  const _HeroSection({required this.slug, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final l10n   = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return switch (t.heroStyle) {
      SfHeroStyle.fullscreen => _FullscreenHero(slug: slug, vendor: vendor, t: t, l10n: l10n, isWide: isWide),
      SfHeroStyle.split      => _SplitHero(slug: slug, vendor: vendor, t: t, l10n: l10n, isWide: isWide),
      SfHeroStyle.minimal    => _MinimalHero(slug: slug, vendor: vendor, t: t, l10n: l10n),
      _                      => _CenteredHero(slug: slug, vendor: vendor, t: t, l10n: l10n, isWide: isWide),
    };
  }
}

class _FullscreenHero extends StatelessWidget {
  final String slug; final SfVendorInfo vendor;
  final SfThemeData t; final AppLocalizations l10n; final bool isWide;
  const _FullscreenHero({required this.slug, required this.vendor, required this.t, required this.l10n, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isWide ? 580 : 380,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        SfImage(
          url: 'https://picsum.photos/seed/${vendor.slug}hero/1200/600',
          fit: BoxFit.cover,
          fallback: Container(
            decoration: BoxDecoration(
              gradient: t.heroGradient ?? LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [t.primary, t.accent],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black.withAlpha(30), Colors.black.withAlpha(160)],
            ),
          ),
        ),
        Positioned(
          bottom: isWide ? 64 : 40,
          left: isWide ? 64 : 24,
          right: isWide ? 64 : 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(vendor.displayTitle,
              style: TextStyle(
                fontSize: isWide ? 52 : 34, color: Colors.white,
                fontWeight: t.headingWeight, letterSpacing: t.headingLetterSpacing,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'اكتشف مجموعتنا الحصرية من أجود المنتجات',
              style: TextStyle(fontSize: isWide ? 18 : 14, color: Colors.white.withAlpha(220), height: 1.5),
            ),
            const SizedBox(height: 28),
            SfButton(
              label: t.uppercaseLabels ? l10n.sfShopNow.toUpperCase() : l10n.sfShopNow,
              onPressed: () => context.go('/store/$slug/products'),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _CenteredHero extends StatelessWidget {
  final String slug; final SfVendorInfo vendor;
  final SfThemeData t; final AppLocalizations l10n; final bool isWide;
  const _CenteredHero({required this.slug, required this.vendor, required this.t, required this.l10n, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24, vertical: isWide ? 72 : 48),
      decoration: BoxDecoration(
        gradient: t.heroGradient ?? LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [t.primary, t.accent],
        ),
      ),
      child: Column(children: [
        Text(vendor.displayTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWide ? 48 : 32, color: Colors.white,
            fontWeight: t.headingWeight, letterSpacing: t.headingLetterSpacing, height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Text('اكتشف مجموعتنا الحصرية من أجود المنتجات',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(220), height: 1.5)),
        const SizedBox(height: 32),
        SfButton(
          label: t.uppercaseLabels ? l10n.sfShopNow.toUpperCase() : l10n.sfShopNow,
          onPressed: () => context.go('/store/$slug/products'),
          inverted: true,
        ),
      ]),
    );
  }
}

class _SplitHero extends StatelessWidget {
  final String slug; final SfVendorInfo vendor;
  final SfThemeData t; final AppLocalizations l10n; final bool isWide;
  const _SplitHero({required this.slug, required this.vendor, required this.t, required this.l10n, required this.isWide});

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return _CenteredHero(slug: slug, vendor: vendor, t: t, l10n: l10n, isWide: false);
    }
    return SizedBox(
      height: 520,
      child: Row(children: [
        Expanded(
          child: Container(
            color: t.surfaceHigh,
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vendor.displayTitle,
                style: TextStyle(fontSize: 44, fontWeight: t.headingWeight,
                    color: t.text, letterSpacing: t.headingLetterSpacing, height: 1.1)),
              const SizedBox(height: 14),
              Text('اكتشف مجموعتنا الحصرية',
                style: TextStyle(fontSize: 16, color: t.textMuted, height: 1.6)),
              const SizedBox(height: 32),
              SfButton(label: l10n.sfShopNow, onPressed: () => context.go('/store/$slug/products')),
            ]),
          ),
        ),
        Expanded(
          child: SfImage(
            url: 'https://picsum.photos/seed/${vendor.slug}split/800/520',
            fit: BoxFit.cover,
            fallback: Container(
              decoration: BoxDecoration(
                gradient: t.heroGradient ?? LinearGradient(
                  colors: [t.primary, t.accent],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _MinimalHero extends StatelessWidget {
  final String slug; final SfVendorInfo vendor;
  final SfThemeData t; final AppLocalizations l10n;
  const _MinimalHero({required this.slug, required this.vendor, required this.t, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: t.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('مرحباً بك',
            style: TextStyle(fontSize: 12, color: t.primary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        Text(vendor.displayTitle,
          style: TextStyle(fontSize: 38, fontWeight: t.headingWeight,
              color: t.text, letterSpacing: t.headingLetterSpacing, height: 1.1)),
        const SizedBox(height: 12),
        Text('اكتشف مجموعتنا الحصرية من أجود المنتجات',
          style: TextStyle(fontSize: 16, color: t.textMuted, height: 1.6)),
        const SizedBox(height: 24),
        SfButton(label: l10n.sfShopNow, onPressed: () => context.go('/store/$slug/products'), small: true),
      ]),
    );
  }
}

// ── Featured Products ─────────────────────────────────────────────────────────

class _FeaturedSection extends StatelessWidget {
  final String slug;
  final AppLocalizations l10n;
  const _FeaturedSection({required this.slug, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final cols   = isWide ? 4 : 2;
    final products = SfMockData.featuredProducts;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 16, vertical: 48),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(l10n.sfFeaturedProducts,
            style: TextStyle(fontSize: 24, fontWeight: t.headingWeight,
                color: t.text, letterSpacing: t.headingLetterSpacing))),
          TextButton(
            onPressed: () => context.go('/store/$slug/products'),
            child: Text(l10n.sfViewDetails, style: TextStyle(color: t.primary, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols, crossAxisSpacing: 14, mainAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => _ProductCard(product: products[i], slug: slug, t: t),
        ),
      ]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final SfProduct product;
  final String    slug;
  final SfThemeData t;
  const _ProductCard({required this.product, required this.slug, required this.t});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock == 0;

    return GestureDetector(
      onTap: () => context.go('/store/$slug/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.radius),
          border: t.cardStyle == SfCardStyle.outlined
              ? Border.all(color: t.border) : null,
          boxShadow: t.cardStyle == SfCardStyle.elevated
              ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              SfImage(
                url: product.primaryImage,
                fit: BoxFit.cover,
                fallback: Container(
                  color: t.surfaceHigh,
                  child: Center(child: Icon(Icons.image_outlined, color: t.textSubtle, size: 36)),
                ),
              ),
              // Discount badge
              if (product.hasDiscount)
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '-${product.discountPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              // Out of stock overlay
              if (outOfStock)
                Container(
                  color: Colors.black.withAlpha(100),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('نفذ المخزون',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ]),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text, height: 1.3)),
              const SizedBox(height: 6),
              Row(children: [
                Text('${product.price.toStringAsFixed(0)} ر.س',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.primary)),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 6),
                  Text('${product.oldPrice!.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 11, color: t.textSubtle,
                        decoration: TextDecoration.lineThrough)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Categories ────────────────────────────────────────────────────────────────

class _CategoriesSection extends StatelessWidget {
  final String slug;
  final AppLocalizations l10n;
  const _CategoriesSection({required this.slug, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final cats   = SfMockData.categories;

    return Container(
      color: t.surfaceHigh,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 16, vertical: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.sfCategories,
          style: TextStyle(fontSize: 24, fontWeight: t.headingWeight,
              color: t.text, letterSpacing: t.headingLetterSpacing)),
        const SizedBox(height: 20),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: cats.length,
            itemBuilder: (_, i) => _CategoryCard(cat: cats[i], slug: slug, t: t),
          ),
        ),
      ]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final SfCategory  cat;
  final String      slug;
  final SfThemeData t;
  const _CategoryCard({required this.cat, required this.slug, required this.t});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/store/$slug/products'),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.radius),
          border: t.cardStyle == SfCardStyle.outlined
              ? Border.all(color: t.border) : null,
          boxShadow: t.cardStyle == SfCardStyle.elevated
              ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Expanded(
            child: SfImage(
              url: cat.imageUrl,
              fit: BoxFit.cover,
              fallback: Container(
                color: t.primary.withAlpha(30),
                child: Center(child: Icon(Icons.grid_view_rounded, color: t.primary, size: 24)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Text(cat.name,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t.text)),
          ),
        ]),
      ),
    );
  }
}

// ── Promo Banner ──────────────────────────────────────────────────────────────

class _PromoSection extends StatelessWidget {
  final String slug;
  final SfVendorInfo vendor;
  final AppLocalizations l10n;
  const _PromoSection({required this.slug, required this.vendor, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 48 : 16, vertical: 40),
      height: isWide ? 200 : 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radius * 1.5),
        gradient: t.heroGradient ?? LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [t.primary, t.accent],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: -20, top: -20,
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(15),
            ),
          ),
        ),
        Positioned(
          right: 40, bottom: -30,
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(10),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 24, vertical: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('عروض حصرية لفترة محدودة!',
              style: TextStyle(
                fontSize: isWide ? 24 : 18,
                color: Colors.white, fontWeight: t.headingWeight,
                letterSpacing: t.headingLetterSpacing,
              ),
            ),
            const SizedBox(height: 8),
            Text('خصومات تصل إلى 40% على منتجات مختارة',
              style: TextStyle(fontSize: isWide ? 14 : 12,
                  color: Colors.white.withAlpha(210))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/store/$slug/products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: t.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(t.buttonRadius)),
                elevation: 0,
              ),
              child: Text(
                t.uppercaseLabels ? l10n.sfShopNow.toUpperCase() : l10n.sfShopNow,
                style: TextStyle(fontWeight: t.headingWeight, fontSize: 13),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
