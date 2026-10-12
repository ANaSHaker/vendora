import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/cubit/locale_cubit.dart';
import '../../core/cubit/theme_cubit.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/route_names.dart';
import '../../design_system/theme/app_border_radius.dart';
import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_text_styles.dart';
import '../../core/di/injection.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/notifications/domain/entities/notification_entity.dart';
import '../../features/notifications/domain/usecases/notifications_usecases.dart';
import '../../features/notifications/presentation/cubit/unread_count_cubit.dart';
import '../../features/settings/presentation/widgets/theme_picker_dialog.dart';

// ─── Language metadata ────────────────────────────────────────────────────────

class _LangOption {
  final String code;
  final String flag;
  final String Function(AppLocalizations) name;
  const _LangOption(this.code, this.flag, this.name);
}

const List<_LangOption> _kLangs = [
  _LangOption('ar', '🇸🇦', _nameAr),
  _LangOption('en', '🇺🇸', _nameEn),
  _LangOption('fr', '🇫🇷', _nameFr),
  _LangOption('it', '🇮🇹', _nameIt),
  _LangOption('de', '🇩🇪', _nameDe),
];

String _nameAr(AppLocalizations l) => l.arabic;
String _nameEn(AppLocalizations l) => l.english;
String _nameFr(AppLocalizations l) => l.french;
String _nameIt(AppLocalizations l) => l.italian;
String _nameDe(AppLocalizations l) => l.german;

_LangOption _langFor(String code) =>
    _kLangs.firstWhere((l) => l.code == code, orElse: () => _kLangs.first);

// ─── Route title map ──────────────────────────────────────────────────────────

const List<String> _kRouteOrder = [
  '/inventory/movements', '/inventory/cost-layers', '/suppliers/ledger',
  '/reports/financial', '/reports/inventory', '/inventory', '/suppliers',
  '/reports', '/settings/store', '/settings/devices', '/settings/themes',
  '/dashboard', '/pos', '/orders', '/products', '/categories', '/customers',
  '/warehouses', '/transfers', '/stock-counts', '/adjustments', '/branches',
  '/users', '/notifications', '/activity-log',
];

String _pageTitle(String path, AppLocalizations l10n) {
  String key = '';
  if (_kRouteOrder.contains(path)) {
    key = path;
  } else {
    for (final k in _kRouteOrder) {
      if (path.startsWith('$k/')) {
        key = k;
        break;
      }
    }
  }
  return switch (key) {
    '/dashboard'             => l10n.dashboard,
    '/pos'                   => l10n.pos,
    '/orders'                => l10n.orders,
    '/products'              => l10n.products,
    '/categories'            => l10n.categories,
    '/customers'             => l10n.customers,
    '/inventory'             => l10n.inventory,
    '/inventory/movements'   => l10n.inventoryMovements,
    '/inventory/cost-layers' => l10n.costLayers,
    '/warehouses'            => l10n.warehouses,
    '/transfers'             => l10n.transfers,
    '/stock-counts'          => l10n.stockCounts,
    '/adjustments'           => l10n.adjustments,
    '/suppliers'             => l10n.suppliers,
    '/suppliers/ledger'      => l10n.supplierLedger,
    '/reports'               => l10n.reports,
    '/reports/financial'     => l10n.financialReports,
    '/reports/inventory'     => l10n.inventoryReports,
    '/branches'              => l10n.branches,
    '/users'                 => l10n.users,
    '/settings/store'        => l10n.storeSettings,
    '/settings/devices'      => l10n.devices,
    '/settings/themes'       => l10n.themes,
    '/notifications'         => l10n.notifications,
    '/activity-log'          => l10n.activityLog,
    _                        => '',
  };
}

// ─── Topbar ───────────────────────────────────────────────────────────────────

class DesktopTopbar extends StatelessWidget {
  const DesktopTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = cs.onSurface;
    final muted = cs.onSurfaceVariant;
    final mutedBg = isDark ? AppColors.darkMuted : AppColors.muted;
    final currentPath = GoRouterState.of(context).uri.path;
    final l10n = AppLocalizations.of(context);
    final title = _pageTitle(currentPath, l10n);

    return Container(
      height: AppSizes.topbarHeight,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: mutedBg,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Icon(Icons.storefront_rounded, size: AppSizes.iconMd, color: muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.labelMd.copyWith(color: fg, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _ThemeToggleButton(isDark: isDark, muted: muted),
          const SizedBox(width: AppSpacing.xs),
          _PaletteButton(muted: muted),
          const SizedBox(width: AppSpacing.xs),
          _LanguageSwitcherButton(isDark: isDark, muted: muted, borderColor: borderColor),
          const SizedBox(width: AppSpacing.xs),
          _NotificationButton(muted: muted),
          const SizedBox(width: AppSpacing.sm),
          _TopbarUserMenu(isDark: isDark),
        ],
      ),
    );
  }
}

// ─── Theme toggle ─────────────────────────────────────────────────────────────

class _ThemeToggleButton extends StatelessWidget {
  final bool isDark;
  final Color muted;
  const _ThemeToggleButton({required this.isDark, required this.muted});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<ThemeCubit>().toggle(),
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: AppSizes.iconMd,
          color: muted,
        ),
      ),
    );
  }
}

// ─── Palette button ───────────────────────────────────────────────────────────

class _PaletteButton extends StatelessWidget {
  final Color muted;
  const _PaletteButton({required this.muted});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ThemePickerDialog.show(context),
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(Icons.palette_outlined, size: AppSizes.iconMd, color: muted),
      ),
    );
  }
}

// ─── Language switcher ────────────────────────────────────────────────────────

class _LanguageSwitcherButton extends StatelessWidget {
  final bool isDark;
  final Color muted;
  final Color borderColor;

  const _LanguageSwitcherButton({
    required this.isDark,
    required this.muted,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final current = _langFor(locale.languageCode);

        return PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXl,
            side: BorderSide(color: borderColor),
          ),
          elevation: 8,
          offset: const Offset(0, 4),
          constraints: const BoxConstraints(minWidth: 200),
          onSelected: (code) =>
              context.read<LocaleCubit>().setLocale(Locale(code)),
          itemBuilder: (ctx) {
            final primary = Theme.of(ctx).colorScheme.primary;
            final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
            return _kLangs.map((lang) {
              final isSelected = locale.languageCode == lang.code;
              return PopupMenuItem<String>(
                value: lang.code,
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        lang.name(l10n),
                        style: AppTextStyles.labelSm.copyWith(
                          color: fg,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded, size: 16, color: primary),
                  ],
                ),
              );
            }).toList();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(current.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  current.code.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: muted),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Notification bell ────────────────────────────────────────────────────────

class _NotificationButton extends StatefulWidget {
  final Color muted;
  const _NotificationButton({required this.muted});

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  final _key = GlobalKey();
  OverlayEntry? _overlay;

  // Notifiers so the overlay can react to data changes without rebuild
  final _loadingNotifier = ValueNotifier<bool>(false);
  final _itemsNotifier = ValueNotifier<List<NotificationEntity>>([]);

  Future<void> _load() async {
    _loadingNotifier.value = true;
    try {
      final result =
          await getIt<GetNotificationsUseCase>()(unreadOnly: true);
      result.fold((_) {}, (list) {
        _itemsNotifier.value = list.take(8).toList();
      });
      await getIt<MarkAllNotificationsReadUseCase>()();
      if (mounted) context.read<UnreadCountCubit>().reset();
    } finally {
      _loadingNotifier.value = false;
    }
  }

  void _showDropdown() {
    _removeOverlay();
    _load();

    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final primary = Theme.of(context).colorScheme.primary;
    // Capture l10n from THIS context — not the overlay's context
    final l10n = AppLocalizations.of(context);

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          Positioned(
            top: pos.dy + box.size.height + 6,
            right: isRtl ? null : 12,
            left: isRtl ? 12 : null,
            child: Material(
              elevation: 12,
              color: Colors.transparent,
              borderRadius: AppRadius.brXl,
              child: Container(
                width: 380,
                constraints: const BoxConstraints(maxHeight: 480),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: AppRadius.brXl,
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                // Use ValueListenableBuilder so overlay rebuilds on data change
                child: ValueListenableBuilder2(
                  first: _loadingNotifier,
                  second: _itemsNotifier,
                  builder: (_, loading, items, __) => _NotificationDropdown(
                    items: items,
                    loading: loading,
                    isDark: isDark,
                    primary: primary,
                    l10n: l10n,
                    onViewAll: () {
                      _removeOverlay();
                      if (mounted) context.goNamed(RouteNames.notifications);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    _loadingNotifier.dispose();
    _itemsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnreadCountCubit, int>(
      builder: (context, count) {
        final primary = Theme.of(context).colorScheme.primary;
        return InkWell(
          key: _key,
          onTap: _showDropdown,
          borderRadius: AppRadius.brMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  count > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_outlined,
                  size: AppSizes.iconMd,
                  color: count > 0 ? primary : widget.muted,
                ),
                if (count > 0)
                  PositionedDirectional(
                    top: -4,
                    end: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.destructive,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? AppColors.darkBackground
                              : AppColors.background,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

// ── Dropdown panel ─────────────────────────────────────────────────────────────

class _NotificationDropdown extends StatelessWidget {
  final List<NotificationEntity> items;
  final bool loading;
  final bool isDark;
  final Color primary;
  final AppLocalizations l10n;
  final VoidCallback onViewAll;

  const _NotificationDropdown({
    required this.items,
    required this.loading,
    required this.isDark,
    required this.primary,
    required this.l10n,
    required this.onViewAll,
  });

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return '${diff.inMinutes} د';
      if (diff.inHours < 24) return '${diff.inHours} س';
      return '${diff.inDays} ي';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
          child: Row(
            children: [
              Text(
                l10n.notifications,
                style: AppTextStyles.labelMd.copyWith(
                    color: fg, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.t('viewAll'),
                  style: AppTextStyles.bodyXs
                      .copyWith(color: primary),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: border),

        // Body
        if (loading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 32, color: muted),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.t('notificationsAllRead'),
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                ),
              ],
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: border),
              itemBuilder: (_, i) {
                final n = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(n.type),
                          size: 15,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localizedTitle(n.type, n.title, n.data, l10n),
                              style: AppTextStyles.labelSm
                                  .copyWith(color: fg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (n.body.isNotEmpty)
                              Text(
                                _localizedBody(n.type, n.data, n.body, l10n),
                                style: AppTextStyles.bodyXs
                                    .copyWith(color: muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _fmtDate(n.createdAt),
                        style: AppTextStyles.bodyXs
                            .copyWith(color: muted, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'order_created' || 'order_status_updated' || 'order_ready' =>
          Icons.receipt_long_outlined,
        'payment' => Icons.payments_outlined,
        'low_stock' => Icons.inventory_2_outlined,
        'refund_completed' => Icons.keyboard_return_rounded,
        _ => Icons.notifications_none_rounded,
      };

  String _localizedTitle(String type, String fallback,
      Map<String, dynamic> data, AppLocalizations l10n) {
    final key = switch (type) {
      'order_created'                          => 'notifNewOrder',
      'order_status_updated' || 'order_ready'  => 'notifOrderStatus',
      'payment'                                => 'notifPayment',
      'low_stock'                              => 'notifLowStock',
      'refund_completed'                       => 'notifRefund',
      'subscription_expiring' ||
      'subscription_expired'  ||
      'employee_created'      ||
      'system'                                 => 'notifSystem',
      _                                        => null,
    };
    if (key == null) return fallback;
    final translated = l10n.t(key);
    return translated == key ? fallback : translated;
  }

  String _localizedBody(String type, Map<String, dynamic> data,
      String fallback, AppLocalizations l10n) {
    final ref = data['reference'] as String? ??
        data['order_reference'] as String? ?? '';
    final name = data['name'] as String? ??
        data['product_name'] as String? ?? '';
    if (ref.isEmpty && name.isEmpty) return fallback;

    final tmpl = switch (type) {
      'order_created'                         => l10n.t('notifNewOrderBody'),
      'order_status_updated' || 'order_ready' => l10n.t('notifOrderStatusBody'),
      'payment'                               => l10n.t('notifPaymentBody'),
      'low_stock'                             => l10n.t('notifLowStockBody'),
      'refund_completed'                      => l10n.t('notifRefundBody'),
      _                                       => fallback,
    };
    return tmpl.replaceAll('{ref}', ref).replaceAll('{name}', name);
  }
}

// ─── ValueListenableBuilder2 helper ──────────────────────────────────────────

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (ctx, a, _) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (ctx2, b, child) => builder(ctx2, a, b, child),
      ),
    );
  }
}

// ─── User menu ────────────────────────────────────────────────────────────────

class _TopbarUserMenu extends StatelessWidget {
  final bool isDark;
  const _TopbarUserMenu({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final name = user?.name ?? '';
        final email = user?.email ?? '';
        final initial = user?.initials ?? 'U';

        return PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXl,
            side: BorderSide(color: borderColor),
          ),
          elevation: 8,
          offset: const Offset(0, 4),
          constraints: const BoxConstraints(minWidth: 224),
          onSelected: (value) {
            if (value == 'signout') context.read<AuthCubit>().logout();
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.labelSm.copyWith(
                        color: fg, fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.px2),
                    Text(
                      email,
                      style: AppTextStyles.caption.copyWith(color: muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuDivider(height: 1, color: borderColor),
            PopupMenuItem<String>(
              value: 'signout',
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: AppSizes.iconSm, color: AppColors.destructive),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.signOut,
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.destructive),
                  ),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _UserAvatar(initial: initial, primary: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  name,
                  style: AppTextStyles.labelSm.copyWith(color: fg, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.keyboard_arrow_down_rounded, size: AppSizes.iconMd, color: muted),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String initial;
  final Color primary;
  const _UserAvatar({required this.initial, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
