import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/sf_entities.dart';
import '../../domain/usecases/sf_usecases.dart';
import '../cubit/storefront_cubit.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';
import '../theme/sf_themes.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class StorefrontPage extends StatelessWidget {
  final String slug;
  final Widget child;
  const StorefrontPage({super.key, required this.slug, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StorefrontCubit(
        getStorefront: getIt<GetStorefrontUseCase>(),
      )..load(slug),
      child: _StorefrontShell(slug: slug, child: child),
    );
  }
}

// ── Shell ─────────────────────────────────────────────────────────────────────

class _StorefrontShell extends StatelessWidget {
  final String slug;
  final Widget child;
  const _StorefrontShell({required this.slug, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StorefrontCubit, StorefrontState>(
      builder: (ctx, state) {
        if (state is StorefrontLoading || state is StorefrontInitial) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (state is StorefrontError) {
          final l10n = AppLocalizations.of(ctx);
          return Scaffold(
            body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(l10n.sfStoreUnavailable,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                l10n.sfStoreUnavailableHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => ctx.read<StorefrontCubit>().load(slug),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.sfRetry),
              ),
            ])),
          );
        }

        final loaded    = state as StorefrontLoaded;
        final sfTheme   = SfThemes.byId(loaded.vendor.storeTheme);
        final themeData = loaded.vendor.darkMode ? sfTheme.dark : sfTheme.light;
        final resolved  = themeData.withPrimaryOverride(loaded.vendor.primaryOverride);

        return StorefrontTheme(
          data: resolved,
          child: _ShellScaffold(loaded: loaded, slug: slug, child: child),
        );
      },
    );
  }
}

// ── Scaffold with scrolling + nav overlay ─────────────────────────────────────

class _ShellScaffold extends StatefulWidget {
  final StorefrontLoaded loaded;
  final String slug;
  final Widget child;
  const _ShellScaffold({required this.loaded, required this.slug, required this.child});

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  bool _scrolled = false;
  final _ctrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final s = _ctrl.offset > 40;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final vendor = widget.loaded.vendor;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(children: [
        SingleChildScrollView(
          controller: _ctrl,
          child: Column(children: [
            if (t.navStyle != SfNavStyle.transparent)
              SizedBox(height: t.navStyle == SfNavStyle.floating ? 88 : 64),
            widget.child,
            _SfFooter(vendor: vendor, slug: widget.slug),
          ]),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: _SfNav(
            vendor: vendor, slug: widget.slug,
            scrolled: _scrolled, isWide: isWide,
          ),
        ),
      ]),
    );
  }
}

// ── Navigation bar ─────────────────────────────────────────────────────────────

class _SfNav extends StatelessWidget {
  final SfVendorInfo vendor;
  final String slug;
  final bool scrolled, isWide;
  const _SfNav({
    required this.vendor, required this.slug,
    required this.scrolled, required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final t          = StorefrontTheme.of(context);
    final cubit      = context.watch<StorefrontCubit>();
    final cartCount  = cubit.state is StorefrontLoaded
        ? (cubit.state as StorefrontLoaded).cartItemCount : 0;

    final isTransparent = t.navStyle == SfNavStyle.transparent;
    final isFloating    = t.navStyle == SfNavStyle.floating;
    final showSolid     = !isTransparent || scrolled;

    final navBg = showSolid
        ? (t.glassNav ? t.surface.withAlpha(200) : t.surface)
        : Colors.transparent;

    Widget container = Container(
      margin: isFloating
          ? const EdgeInsets.fromLTRB(16, 12, 16, 0)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: navBg,
        borderRadius: isFloating ? BorderRadius.circular(20) : null,
        border: showSolid && (isFloating || t.glassNav)
            ? Border.all(color: t.border.withAlpha(60))
            : null,
        boxShadow: showSolid
            ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 16)]
            : null,
      ),
      child: _NavRow(
        vendor: vendor, slug: slug, cartCount: cartCount,
        isWide: isWide, textWhite: isTransparent && !scrolled,
      ),
    );

    if (t.glassNav && showSolid) {
      container = ClipRRect(
        borderRadius: isFloating ? BorderRadius.circular(20) : BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: container,
        ),
      );
    }

    return container;
  }
}

class _NavRow extends StatelessWidget {
  final SfVendorInfo vendor;
  final String slug;
  final int  cartCount;
  final bool isWide, textWhite;
  const _NavRow({
    required this.vendor, required this.slug, required this.cartCount,
    required this.isWide, required this.textWhite,
  });

  @override
  Widget build(BuildContext context) {
    final t    = StorefrontTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final fg   = textWhite ? Colors.white : t.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 64,
        child: Row(children: [
          // Logo
          GestureDetector(
            onTap: () => context.go('/store/$slug'),
            child: Row(children: [
              if (vendor.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    vendor.logoUrl!,
                    height: 32, width: 32, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _logoBox(vendor.displayTitle, t),
                  ),
                )
              else _logoBox(vendor.displayTitle, t),
              const SizedBox(width: 10),
              Text(
                vendor.displayTitle,
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: fg, letterSpacing: t.headingLetterSpacing,
                ),
              ),
            ]),
          ),
          const Spacer(),
          // Desktop links
          if (isWide) ...[
            _NLink(t.uppercaseLabels ? l10n.t('sfProducts').toUpperCase()
                : l10n.t('sfProducts'), fg, () => context.go('/store/$slug/products')),
            if (vendor.reservationsEnabled)
              _NLink(t.uppercaseLabels ? l10n.t('sfReservations').toUpperCase()
                  : l10n.t('sfReservations'), fg, () => context.go('/store/$slug/reservations')),
            if (vendor.aboutContent != null)
              _NLink(t.uppercaseLabels ? l10n.t('sfAbout').toUpperCase()
                  : l10n.t('sfAbout'), fg, () => context.go('/store/$slug/about')),
            if (vendor.contactEmail != null || vendor.contactPhone != null)
              _NLink(t.uppercaseLabels ? l10n.t('sfContact').toUpperCase()
                  : l10n.t('sfContact'), fg, () => context.go('/store/$slug/contact')),
            const SizedBox(width: 4),
          ],
          // Cart
          Stack(children: [
            IconButton(
              icon: Icon(Icons.shopping_bag_outlined, color: fg),
              onPressed: () => context.go('/store/$slug/cart'),
            ),
            if (cartCount > 0) Positioned(
              top: 6, right: 6,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
                child: Center(child: Text('$cartCount',
                  style: TextStyle(color: t.primaryFg, fontSize: 9, fontWeight: FontWeight.w700))),
              ),
            ),
          ]),
          if (!isWide)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: fg),
              onPressed: () => _mobileMenu(context, l10n, t),
            ),
        ]),
      ),
    );
  }

  Widget _logoBox(String name, SfThemeData t) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(6)),
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'S',
      style: TextStyle(color: t.primaryFg, fontWeight: FontWeight.w700, fontSize: 14),
    )),
  );

  void _mobileMenu(BuildContext context, AppLocalizations l10n, SfThemeData t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _MItem(Icons.home_outlined, l10n.t('sfHome'),
              () { Navigator.pop(context); context.go('/store/$slug'); }),
          _MItem(Icons.grid_view_rounded, l10n.t('sfProducts'),
              () { Navigator.pop(context); context.go('/store/$slug/products'); }),
          if (vendor.reservationsEnabled)
            _MItem(Icons.event_seat_rounded, l10n.t('sfReservations'),
                () { Navigator.pop(context); context.go('/store/$slug/reservations'); }),
          if (vendor.aboutContent != null)
            _MItem(Icons.info_outline_rounded, l10n.t('sfAbout'),
                () { Navigator.pop(context); context.go('/store/$slug/about'); }),
          if (vendor.contactEmail != null || vendor.contactPhone != null)
            _MItem(Icons.mail_outline_rounded, l10n.t('sfContact'),
                () { Navigator.pop(context); context.go('/store/$slug/contact'); }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _NLink extends StatelessWidget {
  final String label; final Color fg; final VoidCallback onTap;
  const _NLink(this.label, this.fg, this.onTap);
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: fg,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    child: Text(label),
  );
}

class _MItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _MItem(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    final t = StorefrontTheme.of(context);
    return ListTile(
      leading: Icon(icon, color: t.primary, size: 20),
      title: Text(label, style: TextStyle(color: t.text, fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap, dense: true,
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────────

class _SfFooter extends StatelessWidget {
  final SfVendorInfo vendor;
  final String slug;
  const _SfFooter({required this.vendor, required this.slug});

  @override
  Widget build(BuildContext context) {
    final t    = StorefrontTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Container(
      color: t.surfaceHigh,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24, vertical: 40,
      ),
      child: Column(children: [
        if (isWide)
          _DesktopFooterRow(vendor: vendor, slug: slug, l10n: l10n, t: t)
        else
          _MobileFooterColumn(vendor: vendor, slug: slug, l10n: l10n, t: t),
        const SizedBox(height: 32),
        Divider(color: t.border),
        const SizedBox(height: 16),
        Text(
          '© ${DateTime.now().year} ${vendor.displayTitle}  •  Powered by Vendora',
          style: TextStyle(fontSize: 12, color: t.textSubtle),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

class _DesktopFooterRow extends StatelessWidget {
  final SfVendorInfo vendor; final String slug;
  final AppLocalizations l10n; final SfThemeData t;
  const _DesktopFooterRow({required this.vendor, required this.slug, required this.l10n, required this.t});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: _Brand(vendor: vendor, t: t)),
      const SizedBox(width: 32),
      Expanded(child: _Links(vendor: vendor, slug: slug, l10n: l10n, t: t)),
      const SizedBox(width: 32),
      Expanded(child: _ContactInfo(vendor: vendor, t: t)),
    ],
  );
}

class _MobileFooterColumn extends StatelessWidget {
  final SfVendorInfo vendor; final String slug;
  final AppLocalizations l10n; final SfThemeData t;
  const _MobileFooterColumn({required this.vendor, required this.slug, required this.l10n, required this.t});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Brand(vendor: vendor, t: t),
      const SizedBox(height: 24),
      _Links(vendor: vendor, slug: slug, l10n: l10n, t: t),
      const SizedBox(height: 24),
      _ContactInfo(vendor: vendor, t: t),
    ],
  );
}

class _Brand extends StatelessWidget {
  final SfVendorInfo vendor; final SfThemeData t;
  const _Brand({required this.vendor, required this.t});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(vendor.displayTitle,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
            color: t.text, letterSpacing: t.headingLetterSpacing)),
      if (vendor.aboutTitle != null) ...[
        const SizedBox(height: 8),
        Text(vendor.aboutTitle!,
          style: TextStyle(fontSize: 13, color: t.textMuted, height: 1.5)),
      ],
    ],
  );
}

class _Links extends StatelessWidget {
  final SfVendorInfo vendor; final String slug;
  final AppLocalizations l10n; final SfThemeData t;
  const _Links({required this.vendor, required this.slug, required this.l10n, required this.t});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FL(l10n.t('sfProducts'), () => context.go('/store/$slug/products'), t),
      if (vendor.reservationsEnabled)
        _FL(l10n.t('sfReservations'), () => context.go('/store/$slug/reservations'), t),
      if (vendor.aboutContent != null)
        _FL(l10n.t('sfAbout'), () => context.go('/store/$slug/about'), t),
      if (vendor.contactEmail != null || vendor.contactPhone != null)
        _FL(l10n.t('sfContact'), () => context.go('/store/$slug/contact'), t),
      _FL(l10n.t('sfOrderLookup'), () => context.go('/store/$slug/lookup'), t),
    ],
  );
}

class _ContactInfo extends StatelessWidget {
  final SfVendorInfo vendor; final SfThemeData t;
  const _ContactInfo({required this.vendor, required this.t});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (vendor.contactEmail   != null) _CI(Icons.mail_outline,     vendor.contactEmail!,   t),
      if (vendor.contactPhone   != null) _CI(Icons.phone_outlined,   vendor.contactPhone!,   t),
      if (vendor.contactAddress != null) _CI(Icons.location_on_outlined, vendor.contactAddress!, t),
    ],
  );
}

class _FL extends StatelessWidget {
  final String label; final VoidCallback onTap; final SfThemeData t;
  const _FL(this.label, this.onTap, this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Text(label, style: TextStyle(fontSize: 13, color: t.textMuted)),
    ),
  );
}

class _CI extends StatelessWidget {
  final IconData icon; final String text; final SfThemeData t;
  const _CI(this.icon, this.text, this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 14, color: t.textMuted),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: t.textMuted))),
    ]),
  );
}
