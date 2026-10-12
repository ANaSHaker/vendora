import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/di/injection.dart';
import '../../../domain/entities/menu_entities.dart';
import '../../../domain/usecases/menu_usecases.dart';
import 'web_img_stub.dart' if (dart.library.js_interop) 'web_img_web.dart';

class PublicMenuPage extends StatefulWidget {
  final String slug;
  const PublicMenuPage({super.key, required this.slug});

  @override
  State<PublicMenuPage> createState() => _PublicMenuPageState();
}

class _PublicMenuPageState extends State<PublicMenuPage> {
  MenuSettings? _settings;
  List<MenuProductConfig> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settingsResult =
        await getIt<GetPublicMenuBySlugUseCase>()(widget.slug);
    final productsResult =
        await getIt<GetPublicMenuProductsUseCase>()(widget.slug);

    if (!mounted) return;

    settingsResult.fold(
      (f) => setState(() { _error = f.message; _loading = false; }),
      (s) {
        if (s == null) {
          setState(() { _error = 'Menu not found'; _loading = false; });
          return;
        }
        productsResult.fold(
          (_) => setState(() { _settings = s; _loading = false; }),
          (products) => setState(() {
            _settings = s;
            _products = products.where((p) => p.isVisible).toList()
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            _loading = false;
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _settings == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu_rounded,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_error ?? 'Menu not found',
                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return _MenuThemeView(settings: _settings!, products: _products);
  }
}

// ─── Theme Router ─────────────────────────────────────────────────────────────

class _MenuThemeView extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;

  const _MenuThemeView({required this.settings, required this.products});

  Color get primaryColor => _hexColor(settings.primaryColor);
  Color get bgColor => _hexColor(settings.backgroundColor);
  Color get textColor => _hexColor(settings.textColor);

  Map<String?, List<MenuProductConfig>> get _grouped {
    final map = <String?, List<MenuProductConfig>>{};
    for (final p in products) {
      (map[p.categoryName] ??= []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return switch (settings.themeId) {
      2 => _ClassicListTheme(
          settings: settings, products: products, grouped: _grouped,
          primary: primaryColor, bg: bgColor, text: textColor),
      3 => _DarkLuxuryTheme(
          settings: settings, products: products, grouped: _grouped),
      4 => _MinimalTheme(
          settings: settings, products: products, grouped: _grouped,
          primary: primaryColor, bg: bgColor, text: textColor),
      5 => _MagazineTheme(
          settings: settings, products: products, grouped: _grouped,
          primary: primaryColor, bg: bgColor, text: textColor),
      6 => _FlyerTheme(
          settings: settings, products: products, grouped: _grouped,
          primary: primaryColor),
      7 => _BillboardTheme(
          settings: settings, products: products, grouped: _grouped,
          primary: primaryColor),
      8 => _ElegantCardsTheme(
          settings: settings, products: products, grouped: _grouped,
          primary: primaryColor, bg: bgColor, text: textColor),
      _ => _ModernGridTheme(
          settings: settings, products: products, grouped: _grouped,
          primary: primaryColor, bg: bgColor, text: textColor),
    };
  }
}

// ─── Theme 1: Modern Grid ─────────────────────────────────────────────────────

class _ModernGridTheme extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final Map<String?, List<MenuProductConfig>> grouped;
  final Color primary, bg, text;

  const _ModernGridTheme({
    required this.settings, required this.products,
    required this.grouped, required this.primary,
    required this.bg, required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _MenuHeader(settings: settings, primaryColor: primary),
            ),
          ),
          for (final entry in grouped.entries) ...[
            if (entry.key != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    entry.key!,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _GridCard(
                    product: entry.value[i],
                    primary: primary,
                    bg: bg,
                    text: text,
                    showPrice: settings.showPrices,
                    currency: settings.currency,
                  ),
                  childCount: entry.value.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: _MenuFooter(settings: settings, primary: primary)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final MenuProductConfig product;
  final Color primary, bg, text;
  final bool showPrice;
  final String currency;

  const _GridCard({
    required this.product, required this.primary,
    required this.bg, required this.text,
    required this.showPrice, required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: product.productImage != null
                ? _WebSafeImage(
                    url: product.productImage!,
                    fit: BoxFit.cover,
                    fallback: _PlaceholderImage(color: primary))
                : _PlaceholderImage(color: primary),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.productName,
                    style: TextStyle(
                        color: text, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (showPrice) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${product.effectivePrice.toStringAsFixed(2)} $currency',
                    style: TextStyle(
                        color: primary, fontWeight: FontWeight.bold, fontSize: 12),
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

// ─── Theme 2: Classic List ────────────────────────────────────────────────────

class _ClassicListTheme extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final Map<String?, List<MenuProductConfig>> grouped;
  final Color primary, bg, text;

  const _ClassicListTheme({
    required this.settings, required this.products,
    required this.grouped, required this.primary,
    required this.bg, required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _MenuHeader(settings: settings, primaryColor: primary),
            ),
          ),
          for (final entry in grouped.entries) ...[
            if (entry.key != null)
              SliverToBoxAdapter(
                child: Container(
                  color: primary.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    entry.key!.toUpperCase(),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final p = entry.value[i];
                  return Column(
                    children: [
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: p.productImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(width: 60, height: 60,
                                    child: _WebSafeImage(url: p.productImage!, fit: BoxFit.cover,
                                        fallback: _SmallPlaceholder(color: primary))))
                            : _SmallPlaceholder(color: primary),
                        title: Text(p.productName,
                            style: TextStyle(
                                color: text, fontWeight: FontWeight.w600)),
                        trailing: settings.showPrices
                            ? Text(
                                '${p.effectivePrice.toStringAsFixed(2)}\n${settings.currency}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: primary, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      Divider(height: 1, color: text.withOpacity(0.1)),
                    ],
                  );
                },
                childCount: entry.value.length,
              ),
            ),
          ],
          SliverToBoxAdapter(child: _MenuFooter(settings: settings, primary: primary)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ─── Theme 3: Dark Luxury ─────────────────────────────────────────────────────

class _DarkLuxuryTheme extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final Map<String?, List<MenuProductConfig>> grouped;

  const _DarkLuxuryTheme({
    required this.settings, required this.products, required this.grouped,
  });

  static const Color _gold = Color(0xFFD4A017);
  static const Color _darkBg = Color(0xFF0A0A0A);
  static const Color _cardBg = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              child: Column(
                children: [
                  if (settings.logoUrl != null)
                    ClipOval(
                      child: SizedBox(
                        width: 88, height: 88,
                        child: _WebSafeImage(
                          url: settings.logoUrl!,
                          fit: BoxFit.cover,
                          fallback: Container(width: 88, height: 88, color: _gold.withOpacity(0.2)),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _gold, width: 2),
                      ),
                      child: const Icon(Icons.restaurant_menu_rounded,
                          color: _gold, size: 40),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    settings.menuName,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (settings.description != null) ...[
                    const SizedBox(height: 8),
                    Text(settings.description!,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  Container(height: 1, color: _gold.withOpacity(0.4)),
                ],
              ),
            ),
          ),
          for (final entry in grouped.entries) ...[
            if (entry.key != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(children: [
                    Container(width: 3, height: 18, color: _gold),
                    const SizedBox(width: 10),
                    Text(entry.key!,
                        style: const TextStyle(
                            color: _gold, fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final p = entry.value[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _gold.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          if (p.productImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(width: 56, height: 56,
                                  child: _WebSafeImage(url: p.productImage!, fit: BoxFit.cover,
                                      fallback: Container(width: 56, height: 56,
                                          color: _gold.withOpacity(0.1)))),
                            ),
                          if (p.productImage != null) const SizedBox(width: 12),
                          Expanded(
                            child: Text(p.productName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                          ),
                          if (settings.showPrices)
                            Text(
                              '${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
                              style: const TextStyle(
                                  color: _gold, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: _MenuFooter(settings: settings, primary: const Color(0xFFD4A017))),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ─── Theme 4: Minimal ─────────────────────────────────────────────────────────

class _MinimalTheme extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final Map<String?, List<MenuProductConfig>> grouped;
  final Color primary, bg, text;

  const _MinimalTheme({
    required this.settings, required this.products,
    required this.grouped, required this.primary,
    required this.bg, required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              if (settings.logoUrl != null)
                SizedBox(height: 56, child: _WebSafeImage(url: settings.logoUrl!, fit: BoxFit.contain,
                    fallback: const SizedBox.shrink())),
              const SizedBox(height: 16),
              Text(
                settings.menuName,
                style: TextStyle(
                  color: text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (settings.description != null) ...[
                const SizedBox(height: 8),
                Text(settings.description!,
                    style: TextStyle(color: text.withOpacity(0.5), fontSize: 14)),
              ],
              const SizedBox(height: 32),
              for (final entry in grouped.entries) ...[
                if (entry.key != null) ...[
                  Text(entry.key!,
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 2)),
                  const SizedBox(height: 12),
                ],
                ...entry.value.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.productName,
                                    style: TextStyle(
                                        color: text, fontWeight: FontWeight.w500,
                                        fontSize: 15)),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  height: 1,
                                  color: text.withOpacity(0.1),
                                ),
                              ],
                            ),
                          ),
                          if (settings.showPrices) ...[
                            const SizedBox(width: 16),
                            Text(
                              '${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
                              style: TextStyle(
                                  color: text.withOpacity(0.7),
                                  fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Theme 5: Magazine ────────────────────────────────────────────────────────

class _MagazineTheme extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final Map<String?, List<MenuProductConfig>> grouped;
  final Color primary, bg, text;

  const _MagazineTheme({
    required this.settings, required this.products,
    required this.grouped, required this.primary,
    required this.bg, required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _MenuHeader(settings: settings, primaryColor: primary),
            ),
          ),
          for (final entry in grouped.entries) ...[
            if (entry.key != null)
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    if (entry.value.isNotEmpty && entry.value.first.productImage != null)
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: _WebSafeImage(
                          url: entry.value.first.productImage!,
                          fit: BoxFit.cover,
                          fallback: Container(height: 140, color: primary.withOpacity(0.2)),
                        ),
                      )
                    else
                      Container(
                        height: 140,
                        color: primary.withOpacity(0.15),
                        child: Center(
                          child: Icon(Icons.restaurant_rounded,
                              color: primary.withOpacity(0.4), size: 48),
                        ),
                      ),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Text(entry.key!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                    ),
                  ],
                ),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final p = entry.value[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: p.productImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(width: 52, height: 52,
                                child: _WebSafeImage(url: p.productImage!, fit: BoxFit.cover,
                                    fallback: _SmallPlaceholder(color: primary))))
                        : _SmallPlaceholder(color: primary),
                    title: Text(p.productName,
                        style: TextStyle(color: text, fontWeight: FontWeight.w500)),
                    trailing: settings.showPrices
                        ? Text(
                            '${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                          )
                        : null,
                  );
                },
                childCount: entry.value.length,
              ),
            ),
            const SliverToBoxAdapter(child: Divider()),
          ],
          SliverToBoxAdapter(child: _MenuFooter(settings: settings, primary: primary)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ─── Theme 6: Promo Flyer ────────────────────────────────────────────────────

class _FlyerTheme extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final Map<String?, List<MenuProductConfig>> grouped;
  final Color primary;

  const _FlyerTheme({
    required this.settings, required this.products,
    required this.grouped, required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
              child: Row(children: [
                if (settings.logoUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(width: 72, height: 72,
                        child: _WebSafeImage(url: settings.logoUrl!, fit: BoxFit.cover,
                            fallback: Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 36),
                            ))),
                  ),
                  const SizedBox(width: 16),
                ] else ...[
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white38, width: 2)),
                    child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(settings.menuName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  if (settings.description != null)
                    Text(settings.description!, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                ])),
              ]),
            ),
          ),
          for (final entry in grouped.entries) ...[
            if (entry.key != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(entry.key!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final p = entry.value[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: p.productImage != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(10),
                                  child: _WebSafeImage(url: p.productImage!, fit: BoxFit.cover,
                                      fallback: Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.5), size: 22)))
                              : Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.5), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(p.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                        if (settings.showPrices)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
                            child: Text('${p.effectivePrice.toStringAsFixed(2)}\n${settings.currency}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                      ]),
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: _MenuFooter(settings: settings, primary: primary)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Theme 7: Billboard ───────────────────────────────────────────────────────

class _BillboardTheme extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final Map<String?, List<MenuProductConfig>> grouped;
  final Color primary;

  const _BillboardTheme({
    required this.settings, required this.products,
    required this.grouped, required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: primary,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              child: Column(children: [
                if (settings.logoUrl != null) ...[
                  CircleAvatar(radius: 44, backgroundImage: NetworkImage(settings.logoUrl!), backgroundColor: Colors.white24),
                  const SizedBox(height: 12),
                ] else ...[
                  const Icon(Icons.restaurant_rounded, color: Colors.white54, size: 52),
                  const SizedBox(height: 10),
                ],
                Text(settings.menuName.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
                    textAlign: TextAlign.center),
                if (settings.description != null) ...[
                  const SizedBox(height: 6),
                  Container(height: 1, color: Colors.white24),
                  const SizedBox(height: 6),
                  Text(settings.description!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14), textAlign: TextAlign.center),
                ],
                if (settings.address != null) ...[
                  const SizedBox(height: 6),
                  Text(settings.address!, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12), textAlign: TextAlign.center),
                ],
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              height: 28,
            ),
          ),
          for (final entry in grouped.entries) ...[
            if (entry.key != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Text(entry.key!,
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.3)),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, childAspectRatio: 1.3,
                  crossAxisSpacing: 10, mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final p = entry.value[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primary.withOpacity(0.15)),
                        boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 8)],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(p.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (settings.showPrices)
                          Text('${p.effectivePrice.toStringAsFixed(2)} ${settings.currency}',
                              style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14)),
                      ]),
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: _MenuFooter(settings: settings, primary: primary)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Theme 8: Elegant Cards ───────────────────────────────────────────────────

class _ElegantCardsTheme extends StatelessWidget {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final Map<String?, List<MenuProductConfig>> grouped;
  final Color primary, bg, text;

  const _ElegantCardsTheme({
    required this.settings, required this.products,
    required this.grouped, required this.primary,
    required this.bg, required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _MenuHeader(settings: settings, primaryColor: primary),
            ),
          ),
          for (final entry in grouped.entries) ...[
            if (entry.key != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                  child: Text(entry.key!, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.3)),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final p = entry.value[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: p.productImage != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(12),
                                  child: _WebSafeImage(url: p.productImage!, fit: BoxFit.cover,
                                      fallback: Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.5), size: 28)))
                              : Icon(Icons.fastfood_rounded, color: primary.withOpacity(0.5), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.productName, style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w700)),
                          if (p.categoryName != null)
                            Text(p.categoryName!, style: TextStyle(color: text.withOpacity(0.4), fontSize: 11)),
                        ])),
                        if (settings.showPrices)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${p.effectivePrice.toStringAsFixed(2)}\n${settings.currency}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                      ]),
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: _MenuFooter(settings: settings, primary: primary)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _MenuHeader extends StatelessWidget {
  final MenuSettings settings;
  final Color primaryColor;

  const _MenuHeader({required this.settings, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (settings.logoUrl != null) ...[
                ClipOval(
                  child: SizedBox(
                    width: 64, height: 64,
                    child: _WebSafeImage(
                      url: settings.logoUrl!,
                      fit: BoxFit.cover,
                      fallback: Container(color: Colors.white24,
                          child: const Icon(Icons.restaurant_rounded, color: Colors.white54, size: 28)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.menuName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (settings.description != null) ...[
                      const SizedBox(height: 2),
                      Text(settings.description!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
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
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),
            Wrap(spacing: 16, runSpacing: 6, children: [
              if (settings.address != null)
                _HeaderChip(icon: Icons.location_on_rounded, text: settings.address!),
              ...settings.phones.map((p) => _HeaderChip(icon: Icons.phone_rounded, text: p)),
              if (settings.whatsappNumber != null)
                _HeaderChip(icon: Icons.chat_rounded, text: settings.whatsappNumber!),
              if (settings.instagramUrl != null)
                _HeaderChip(icon: Icons.camera_alt_rounded, text: settings.instagramUrl!),
              if (settings.facebookUrl != null)
                _HeaderChip(icon: Icons.facebook_rounded, text: settings.facebookUrl!),
              if (settings.snapchatUrl != null)
                _HeaderChip(icon: Icons.camera_rounded, text: settings.snapchatUrl!),
              if (settings.websiteUrl != null)
                _HeaderChip(icon: Icons.language_rounded, text: settings.websiteUrl!),
            ]),
          ],
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeaderChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 13),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}

class _MenuFooter extends StatelessWidget {
  final MenuSettings settings;
  final Color primary;

  const _MenuFooter({required this.settings, required this.primary});

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wa = settings.whatsappNumber;
    final waUrl = wa != null
        ? 'https://wa.me/${wa.replaceAll(RegExp(r'[^0-9]'), '')}'
        : null;
    final snap = settings.snapchatUrl;
    final snapUrl = snap != null
        ? (snap.startsWith('http')
            ? snap
            : 'https://snapchat.com/add/${snap.replaceAll('@', '')}')
        : null;
    final insta = settings.instagramUrl;
    final instaUrl = insta != null
        ? (insta.startsWith('http')
            ? insta
            : 'https://instagram.com/${insta.replaceAll('@', '')}')
        : null;

    final buttons = <Widget>[
      for (final p in settings.phones)
        _SocialButton(
          icon: Icons.phone_rounded,
          label: 'اتصل بنا',
          bg: primary,
          onTap: () => _launch('tel:$p'),
        ),
      if (waUrl != null)
        _SocialButton(
          icon: Icons.chat_bubble_rounded,
          label: 'واتساب',
          bg: const Color(0xFF25D366),
          onTap: () => _launch(waUrl),
        ),
      if (instaUrl != null)
        _SocialButton(
          icon: Icons.camera_alt_rounded,
          label: 'إنستجرام',
          bg: const Color(0xFFE1306C),
          onTap: () => _launch(instaUrl),
        ),
      if (settings.facebookUrl != null)
        _SocialButton(
          icon: Icons.facebook,
          label: 'فيسبوك',
          bg: const Color(0xFF1877F2),
          onTap: () => _launch(settings.facebookUrl!),
        ),
      if (snapUrl != null)
        _SocialButton(
          icon: Icons.camera_rounded,
          label: 'سناب شات',
          bg: const Color(0xFFFFFC00),
          iconColor: const Color(0xFF212121),
          onTap: () => _launch(snapUrl),
        ),
      if (settings.websiteUrl != null)
        _SocialButton(
          icon: Icons.language_rounded,
          label: 'موقعنا',
          bg: const Color(0xFF0097A7),
          onTap: () => _launch(settings.websiteUrl!),
        ),
      if (settings.address != null)
        _SocialButton(
          icon: Icons.location_on_rounded,
          label: 'عنواننا',
          bg: const Color(0xFF546E7A),
          onTap: () => _launch(
              'https://maps.google.com/?q=${Uri.encodeComponent(settings.address!)}'),
        ),
    ];

    if (buttons.isEmpty) return const SizedBox.shrink();

    final hsl = HSLColor.fromColor(primary);
    final darker =
        hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, darker],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'تواصل معنا',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.45),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: buttons,
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.bg,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              boxShadow: [
                BoxShadow(
                  color: bg.withOpacity(0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black38, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Uses native HTML <img> on web (bypasses CanvasKit CORS) or Image.network on native.
class _WebSafeImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget? fallback;
  const _WebSafeImage({required this.url, this.fit = BoxFit.cover, this.fallback});

  @override
  Widget build(BuildContext context) => buildWebImg(url, fit, fallback);
}

class _PlaceholderImage extends StatelessWidget {
  final Color color;
  const _PlaceholderImage({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.08),
      child: Center(child: Icon(Icons.fastfood_rounded, color: color.withOpacity(0.4))),
    );
  }
}

class _SmallPlaceholder extends StatelessWidget {
  final Color color;
  const _SmallPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.fastfood_rounded, color: color.withOpacity(0.4), size: 24),
    );
  }
}

Color _hexColor(String hex) {
  final clean = hex.startsWith('#') ? hex.substring(1) : hex;
  final padded = clean.padLeft(6, '0');
  return Color(int.parse('FF$padded', radix: 16));
}
