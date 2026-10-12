import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../../design_system/widgets/tables/app_pagination.dart';
import '../../domain/entities/admin_plan_entity.dart';
import '../../domain/entities/admin_vendor_entity.dart';
import '../../domain/entities/vendor_create_meta_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import '../cubit/admin_vendors_cubit.dart';
import '../cubit/admin_vendors_state.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

String _sliceDate(String? s) => (s != null && s.length >= 10) ? s.substring(0, 10) : (s ?? '');

String _fmtDate(String iso) {
  if (iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

String _fmtCurrency(double? n) {
  if (n == null || n == 0) return '—';
  return AppFormatters.compact(n);
}

String _fmtMoney(double n) => n == 0 ? r'$0' : '\$${AppFormatters.compact(n)}';

String _localizeSubStatus(String? s, AppLocalizations l10n) {
  if (s == null || s.isEmpty) return '—';
  final t = l10n.t('status_$s');
  return t == 'status_$s' ? s.replaceAll('_', ' ') : t;
}

// ── page ──────────────────────────────────────────────────────────────────────

class AdminVendorsPage extends StatelessWidget {
  const AdminVendorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminVendorsCubit(
        getVendors: getIt<GetAdminVendorsUseCase>(),
        getPlans: getIt<GetAdminPlansUseCase>(),
        getCreateMeta: getIt<GetVendorCreateMetaUseCase>(),
        toggleStatus: getIt<ToggleAdminVendorStatusUseCase>(),
        createVendor: getIt<CreateAdminVendorUseCase>(),
        updateVendor: getIt<UpdateAdminVendorUseCase>(),
        getVendorDetails: getIt<GetAdminVendorDetailsUseCase>(),
        assignSubscription: getIt<AssignVendorSubscriptionUseCase>(),
      )..load(),
      child: const _VendorsContent(),
    );
  }
}

class _VendorsContent extends StatefulWidget {
  const _VendorsContent();
  @override
  State<_VendorsContent> createState() => _VendorsContentState();
}

class _VendorsContentState extends State<_VendorsContent> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(l10n: l10n, fg: fg, muted: muted),
                const SizedBox(height: AppSpacing.lg),
                BlocBuilder<AdminVendorsCubit, AdminVendorsState>(
                  buildWhen: (_, s) => s is AdminVendorsLoaded,
                  builder: (context, state) {
                    if (state is! AdminVendorsLoaded) return const SizedBox.shrink();
                    return Column(
                      children: [
                        _SummaryCards(summary: state.summary, vendors: state.vendors, isDark: isDark, borderColor: borderColor),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    );
                  },
                ),
                _FilterBar(controller: _searchCtrl, l10n: l10n, isDark: isDark, borderColor: borderColor, bg: bg, muted: muted),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: BlocBuilder<AdminVendorsCubit, AdminVendorsState>(
                    builder: (context, state) {
                      if (state is AdminVendorsLoading) {
                        return Container(
                          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brLg, border: Border.all(color: borderColor)),
                          child: const ShimmerTableRows(rows: 10),
                        );
                      }
                      if (state is AdminVendorsError) {
                        return AppErrorWidget(message: state.message, onRetry: () => context.read<AdminVendorsCubit>().load());
                      }
                      if (state is AdminVendorsLoaded) {
                        return _VendorsTable(state: state, l10n: l10n, isDark: isDark, bg: bg, borderColor: borderColor, fg: fg, muted: muted);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Slide-over
          BlocBuilder<AdminVendorsCubit, AdminVendorsState>(
            builder: (context, state) {
              if (state is! AdminVendorsLoaded) {
                return _SlideOver(open: false, isDark: isDark, borderColor: borderColor, child: const SizedBox.shrink());
              }
              final open = state.selectedVendorId != null;
              return _SlideOver(
                open: open,
                isDark: isDark,
                borderColor: borderColor,
                child: open
                    ? _VendorSlideOverContent(
                        state: state,
                        l10n: l10n,
                        isDark: isDark,
                        borderColor: borderColor,
                        fg: fg,
                        muted: muted,
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── page header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;
  const _PageHeader({required this.l10n, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.t('adminVendors'), style: AppTextStyles.h4.copyWith(color: fg)),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.t('adminVendorsSubtitle'), style: AppTextStyles.bodySm.copyWith(color: muted)),
            ],
          ),
        ),
        AppButton(
          label: l10n.t('addVendor'),
          leading: const Icon(Icons.add_rounded),
          onPressed: () => _showCreateDialog(context),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    final cubit = context.read<AdminVendorsCubit>();
    final state = cubit.state is AdminVendorsLoaded ? cubit.state as AdminVendorsLoaded : null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _CreateVendorDialog(
          l10n: l10n,
          plans: state?.plans ?? const [],
          createMeta: state?.createMeta,
        ),
      ),
    );
  }
}

// ── summary cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final Map<String, dynamic> summary;
  final List<AdminVendorEntity> vendors;
  final bool isDark;
  final Color borderColor;

  const _SummaryCards({required this.summary, required this.vendors, required this.isDark, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeCount = (summary['account_active'] ?? summary['active'] ?? 0) as num;
    final salesNet = vendors.fold<double>(0.0, (s, v) => s + (v.totalRevenue ?? 0));
    final collected = vendors.fold<double>(0.0, (s, v) => s + (v.billingCollected ?? 0));
    final cards = [
      _CardData(l10n.t('totalVendors'),       (summary['total'] ?? 0).toString(),   Colors.transparent),
      _CardData(l10n.t('activeAccounts'),      activeCount.toString(),               AppColors.primary),
      _CardData(l10n.t('billingCollected'),    _fmtMoney(collected),                 Colors.transparent),
      _CardData(l10n.t('billingPending'),      _fmtMoney(0),                         AppColors.warning),
      _CardData(l10n.t('salesNet'),            _fmtMoney(salesNet),                  AppColors.primary),
      _CardData(l10n.t('trialLabel'),          (summary['trial'] ?? 0).toString(),   AppColors.primary),
      _CardData(l10n.t('pastDue'),             (summary['past_due'] ?? 0).toString(), AppColors.destructive),
      _CardData(l10n.t('invoicesOutstanding'), _fmtMoney(0),                         AppColors.destructive),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => _SummaryCard(data: cards[i], isDark: isDark, borderColor: borderColor),
      ),
    );
  }
}

class _CardData {
  final String label;
  final String value;
  final Color valueColor;
  const _CardData(this.label, this.value, this.valueColor);
}

class _SummaryCard extends StatelessWidget {
  final _CardData data;
  final bool isDark;
  final Color borderColor;
  const _SummaryCard({required this.data, required this.isDark, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final valueColor = data.valueColor == Colors.transparent ? fg : data.valueColor;

    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brLg, border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data.label, style: AppTextStyles.caption.copyWith(color: muted), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(data.value, style: AppTextStyles.h5.copyWith(color: valueColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations l10n;
  final bool isDark;
  final Color borderColor;
  final Color bg;
  final Color muted;

  const _FilterBar({
    required this.controller,
    required this.l10n,
    required this.isDark,
    required this.borderColor,
    required this.bg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminVendorsCubit, AdminVendorsState>(
      builder: (context, state) {
        final loaded = state is AdminVendorsLoaded ? state : null;
        final cubit = context.read<AdminVendorsCubit>();
        final hasFilters = (loaded?.planFilter?.isNotEmpty ?? false) ||
            (loaded?.subscriptionStatusFilter?.isNotEmpty ?? false) ||
            (loaded?.accountStatusFilter?.isNotEmpty ?? false);

        final planOptions = <AppSelectOption<String>>[
          AppSelectOption(value: '', label: l10n.t('allPlans')),
          ...(loaded?.plans ?? []).map((p) => AppSelectOption(value: p.id, label: p.name)),
        ];

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: _SearchBox(
                controller: controller,
                hint: l10n.t('searchVendors'),
                isDark: isDark,
                borderColor: borderColor,
                bg: bg,
                muted: muted,
                onChanged: (q) => cubit.search(q),
              ),
            ),
            SizedBox(
              width: 170,
              child: _LabeledSelect(
                label: l10n.t('filterByPlan'),
                value: loaded?.planFilter ?? '',
                options: planOptions,
                onChanged: (v) => cubit.filterByPlan(v == null || v.isEmpty ? null : v),
                isDark: isDark,
                borderColor: borderColor,
                bg: bg,
              ),
            ),
            SizedBox(
              width: 190,
              child: _LabeledSelect(
                label: l10n.t('subscriptionStatus'),
                value: loaded?.subscriptionStatusFilter ?? '',
                options: [
                  AppSelectOption(value: '', label: l10n.t('allSubscriptions')),
                  AppSelectOption(value: 'active', label: l10n.t('status_active')),
                  AppSelectOption(value: 'trial', label: l10n.t('status_trial')),
                  AppSelectOption(value: 'past_due', label: l10n.t('status_past_due')),
                  AppSelectOption(value: 'cancelled', label: l10n.t('status_canceled')),
                  AppSelectOption(value: 'suspended', label: l10n.t('status_suspended')),
                ],
                onChanged: (v) => cubit.filterBySubscriptionStatus(v == null || v.isEmpty ? null : v),
                isDark: isDark,
                borderColor: borderColor,
                bg: bg,
              ),
            ),
            SizedBox(
              width: 210,
              child: _LabeledSelect(
                label: l10n.t('accountStatus'),
                value: loaded?.accountStatusFilter ?? '',
                options: [
                  AppSelectOption(value: '', label: l10n.t('activeAccountsDefault')),
                  AppSelectOption(value: 'all', label: l10n.t('allAccounts')),
                  AppSelectOption(value: 'active', label: l10n.t('activeOnly')),
                  AppSelectOption(value: 'suspended', label: l10n.t('status_suspended')),
                  AppSelectOption(value: 'inactive', label: l10n.t('status_inactive')),
                ],
                onChanged: (v) => cubit.filterByAccountStatus(v == null || v.isEmpty ? null : v),
                isDark: isDark,
                borderColor: borderColor,
                bg: bg,
              ),
            ),
            if (hasFilters)
              TextButton.icon(
                onPressed: () {
                  controller.clear();
                  cubit.filterByPlan(null);
                  cubit.filterBySubscriptionStatus(null);
                  cubit.filterByAccountStatus(null);
                },
                icon: const Icon(Icons.close_rounded, size: 14),
                label: Text(l10n.t('clearFilters')),
                style: TextButton.styleFrom(foregroundColor: muted),
              ),
          ],
        );
      },
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final Color borderColor, bg, muted;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.isDark,
    required this.borderColor,
    required this.bg,
    required this.muted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brMd, border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Icon(Icons.search_rounded, size: 16, color: muted),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.darkForeground : AppColors.foreground),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodySm.copyWith(color: muted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 14, color: muted),
              onPressed: () { controller.clear(); onChanged(''); },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

class _LabeledSelect extends StatelessWidget {
  final String label;
  final String value;
  final List<AppSelectOption<String>> options;
  final ValueChanged<String?> onChanged;
  final bool isDark;
  final Color borderColor, bg;

  const _LabeledSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDark,
    required this.borderColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final validValue = options.any((o) => o.value == value) ? value : '';

    return Container(
      height: 36,
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brMd, border: Border.all(color: borderColor)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          hint: Text(label, style: AppTextStyles.bodySm.copyWith(color: muted), overflow: TextOverflow.ellipsis),
          style: AppTextStyles.bodySm.copyWith(color: fg),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: muted),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppRadius.brLg,
          onChanged: onChanged,
          items: options.map((o) => DropdownMenuItem(
            value: o.value,
            child: Text(o.label, style: AppTextStyles.bodySm.copyWith(color: fg), overflow: TextOverflow.ellipsis),
          )).toList(),
        ),
      ),
    );
  }
}

// ── table ─────────────────────────────────────────────────────────────────────

class _VendorsTable extends StatelessWidget {
  final AdminVendorsLoaded state;
  final AppLocalizations l10n;
  final bool isDark;
  final Color bg, borderColor, fg, muted;

  const _VendorsTable({
    required this.state, required this.l10n, required this.isDark,
    required this.bg, required this.borderColor, required this.fg, required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    if (state.vendors.isEmpty) return AppEmptyState(message: l10n.t('noVendors'));

    final headerBg = isDark ? AppColors.darkMuted : AppColors.muted;
    // Total width = sum of all column SizedBox widths + left/right row padding (AppSpacing.md × 2)
    const double totalW = 220 + 110 + 120 + 130 + 70 + 80 + 110 + 110 + 110 + 140 + AppSpacing.md * 2;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brLg, border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final tableWidth = constraints.maxWidth > totalW ? constraints.maxWidth : totalW;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          decoration: BoxDecoration(
                            color: headerBg,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            border: Border(bottom: BorderSide(color: borderColor)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          child: _HeaderCells(l10n: l10n, muted: muted),
                        ),
                        // Rows
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.vendors.length,
                            itemBuilder: (ctx2, i) {
                              final v = state.vendors[i];
                              return Container(
                                decoration: i < state.vendors.length - 1
                                    ? BoxDecoration(border: Border(bottom: BorderSide(color: borderColor)))
                                    : null,
                                child: _VendorRowCells(
                                  vendor: v,
                                  l10n: l10n,
                                  isDark: isDark,
                                  fg: fg,
                                  muted: muted,
                                  isToggling: state.togglingIds.contains(v.id),
                                  isSelected: state.selectedVendorId == v.id,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Pagination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: AppPagination(
              meta: state.meta,
              onPageChanged: (p) => context.read<AdminVendorsCubit>().changePage(p),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCells extends StatelessWidget {
  final AppLocalizations l10n;
  final Color muted;
  const _HeaderCells({required this.l10n, required this.muted});

  @override
  Widget build(BuildContext context) {
    final s = AppTextStyles.tableHeader.copyWith(color: muted);
    return Row(
      children: [
        SizedBox(width: 220, child: Text(l10n.t('colVendor'), style: s)),
        SizedBox(width: 110, child: Text(l10n.t('colPlan'), style: s)),
        SizedBox(width: 120, child: Text(l10n.t('colAccount'), style: s)),
        SizedBox(width: 130, child: Text(l10n.t('colSubscription'), style: s)),
        SizedBox(width: 70, child: Text(l10n.t('colUsers'), style: s, textAlign: TextAlign.end)),
        SizedBox(width: 80, child: Text(l10n.t('colOrders'), style: s, textAlign: TextAlign.end)),
        SizedBox(width: 110, child: Text(l10n.t('colRevenue'), style: s, textAlign: TextAlign.end)),
        SizedBox(width: 110, child: Text(l10n.t('colBillingCollected'), style: s, textAlign: TextAlign.end)),
        SizedBox(width: 110, child: Text(l10n.t('colJoined'), style: s, textAlign: TextAlign.end)),
        SizedBox(width: 140, child: Text(l10n.t('colActions'), style: s, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _VendorRowCells extends StatelessWidget {
  final AdminVendorEntity vendor;
  final AppLocalizations l10n;
  final bool isDark, isToggling, isSelected;
  final Color fg, muted;

  const _VendorRowCells({
    required this.vendor, required this.l10n, required this.isDark,
    required this.fg, required this.muted,
    required this.isToggling, required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rowBg = isSelected ? cs.primary.withValues(alpha: 0.06) : Colors.transparent;

    return Material(
      color: rowBg,
      child: InkWell(
        onTap: () => context.read<AdminVendorsCubit>().selectVendor(vendor.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
          children: [
            // Vendor: avatar + name + slug
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: AppRadius.brMd),
                    child: Center(
                      child: Text(
                        vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : '?',
                        style: AppTextStyles.labelSm.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor.name, style: AppTextStyles.tableCell.copyWith(color: fg, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                        if (vendor.slug?.isNotEmpty == true)
                          Text(vendor.slug!, style: AppTextStyles.caption.copyWith(color: muted, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Plan badge
            SizedBox(
              width: 110,
              child: _PlanBadge(planName: vendor.planName),
            ),
            // Account status badge
            SizedBox(
              width: 120,
              child: _AccountBadge(status: vendor.status, l10n: l10n),
            ),
            // Subscription display badge
            SizedBox(
              width: 130,
              child: _SubscriptionBadge(
                status: vendor.subscriptionDisplayStatus,
                expiringSoon: vendor.subscriptionDisplayExpiringSoon,
                l10n: l10n,
              ),
            ),
            // Users
            SizedBox(
              width: 70,
              child: Text(
                (vendor.usersCount ?? 0) > 0 ? '${vendor.usersCount}' : '—',
                style: AppTextStyles.tableCell.copyWith(
                  color: (vendor.usersCount ?? 0) > 0 ? fg : muted,
                  fontWeight: (vendor.usersCount ?? 0) > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            // Orders
            SizedBox(
              width: 80,
              child: Text(
                (vendor.ordersCount ?? 0) > 0 ? '${vendor.ordersCount}' : '—',
                style: AppTextStyles.tableCell.copyWith(
                  color: (vendor.ordersCount ?? 0) > 0 ? fg : muted,
                  fontWeight: (vendor.ordersCount ?? 0) > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            // Revenue (orders_total)
            SizedBox(
              width: 110,
              child: Text(
                _fmtCurrency(vendor.totalRevenue),
                style: AppTextStyles.tableCell.copyWith(
                  color: (vendor.totalRevenue ?? 0) > 0 ? cs.primary : muted,
                  fontWeight: (vendor.totalRevenue ?? 0) > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            // Billing collected
            SizedBox(
              width: 110,
              child: Text(
                _fmtCurrency(vendor.billingCollected),
                style: AppTextStyles.tableCell.copyWith(color: muted),
                textAlign: TextAlign.end,
              ),
            ),
            // Joined date
            SizedBox(
              width: 110,
              child: Text(_fmtDate(vendor.createdAt), style: AppTextStyles.tableCell.copyWith(color: muted), textAlign: TextAlign.end),
            ),
            // Actions
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isToggling)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  else ...[
                    Flexible(
                      child: _ActionButton(
                        label: l10n.t('editLabel'),
                        onTap: () => _showEdit(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: _ActionButton(
                        label: vendor.status == 'active' ? l10n.t('suspendVendor') : l10n.t('activateVendor'),
                        isDestructive: vendor.status == 'active',
                        onTap: () => _toggle(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    final cubit = context.read<AdminVendorsCubit>();
    final state = cubit.state is AdminVendorsLoaded ? cubit.state as AdminVendorsLoaded : null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _EditVendorDialog(
          vendor: vendor,
          l10n: l10n,
          createMeta: state?.createMeta,
          plans: state?.plans ?? const [],
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final ok = await context.read<AdminVendorsCubit>().toggleStatus(vendor.id);
    if (!ok && context.mounted) AppSnackbar.error(context, l10n.t('errorToggleVendor'));
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _ActionButton({required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final color = isDestructive ? AppColors.destructive : Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brMd,
          border: Border.all(color: isDestructive ? AppColors.destructive.withValues(alpha: 0.4) : borderColor),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    );
  }
}

// ── badges ────────────────────────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  final String? planName;
  const _PlanBadge({this.planName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    if (planName == null || planName!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkMuted : AppColors.muted),
          borderRadius: AppRadius.brFull,
        ),
        child: Text('—', style: AppTextStyles.caption.copyWith(color: muted)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.brFull,
      ),
      child: Text(planName!, style: AppTextStyles.caption.copyWith(color: cs.primary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  const _AccountBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (dot, text, bg) = switch (status) {
      'active'    => (AppColors.statusPaid, AppColors.statusPaid, AppColors.statusPaidBg),
      'suspended' => (AppColors.destructive, AppColors.destructive, AppColors.destructive.withValues(alpha: 0.08)),
      _           => (AppColors.statusPending, AppColors.statusPending, AppColors.statusPendingBg),
    };
    final label = switch (status) {
      'active'    => l10n.t('accountActive'),
      'suspended' => l10n.t('accountSuspended'),
      _           => l10n.t('accountInactive'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brFull, border: Border.all(color: dot.withValues(alpha: 0.3))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.caption.copyWith(color: text, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubscriptionBadge extends StatelessWidget {
  final String? status;
  final bool expiringSoon;
  final AppLocalizations l10n;
  const _SubscriptionBadge({this.status, required this.expiringSoon, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (status == null || status!.isEmpty) {
      return const SizedBox.shrink();
    }
    final (dot, text, bg) = switch (status) {
      'active'    => (AppColors.statusPaid, AppColors.statusPaid, AppColors.statusPaidBg),
      'trial'     => (AppColors.primary, AppColors.primary, AppColors.primary.withValues(alpha: 0.08)),
      'past_due'  => (AppColors.destructive, AppColors.destructive, AppColors.destructive.withValues(alpha: 0.08)),
      'cancelled' || 'canceled' => (AppColors.statusPending, AppColors.statusPending, AppColors.statusPendingBg),
      'expired'   => (AppColors.statusPending, AppColors.statusPending, AppColors.statusPendingBg),
      _           => (AppColors.statusPending, AppColors.statusPending, AppColors.statusPendingBg),
    };
    final label = l10n.t('subStatus_$status') != 'subStatus_$status'
        ? l10n.t('subStatus_$status')
        : status!.replaceAll('_', ' ');

    return Wrap(
      spacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brFull, border: Border.all(color: dot.withValues(alpha: 0.3))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.caption.copyWith(color: text, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (expiringSoon && status != 'expired')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.brSm,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(l10n.t('endsSoon'), style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ── slide-over ────────────────────────────────────────────────────────────────

class _SlideOver extends StatelessWidget {
  final bool open;
  final bool isDark;
  final Color borderColor;
  final Widget child;

  const _SlideOver({required this.open, required this.isDark, required this.borderColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !open,
        child: Stack(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: open ? 1 : 0,
              child: GestureDetector(
                onTap: () => context.read<AdminVendorsCubit>().clearSelectedVendor(),
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              top: 0, bottom: 0,
              right: open ? 0 : -520,
              width: 500,
              child: Material(
                elevation: 8,
                color: isDark ? AppColors.darkSurface : AppColors.white,
                child: Container(
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: borderColor))),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorSlideOverContent extends StatefulWidget {
  final AdminVendorsLoaded state;
  final AppLocalizations l10n;
  final bool isDark;
  final Color borderColor, fg, muted;

  const _VendorSlideOverContent({
    required this.state, required this.l10n, required this.isDark,
    required this.borderColor, required this.fg, required this.muted,
  });

  @override
  State<_VendorSlideOverContent> createState() => _VendorSlideOverContentState();
}

class _VendorSlideOverContentState extends State<_VendorSlideOverContent> {
  bool _assigning = false;

  @override
  Widget build(BuildContext context) {
    final vendor = widget.state.detailVendor;
    final cs = Theme.of(context).colorScheme;
    final l10n = widget.l10n;

    // Header
    Widget header = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: widget.borderColor.withValues(alpha: 0.4)))),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _assigning ? l10n.t('assignSubscription') : l10n.t('vendorDetail'),
              style: AppTextStyles.labelLg.copyWith(color: widget.fg, fontWeight: FontWeight.w600),
            ),
          ),
          if (!_assigning && vendor != null) ...[
            _ActionButton(
              label: '+ ${l10n.t('subscriptions')}',
              onTap: () => setState(() => _assigning = true),
            ),
            const SizedBox(width: AppSpacing.xs),
            _ActionButton(
              label: l10n.t('editLabel'),
              onTap: () => _showEdit(context, vendor),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: widget.muted),
            onPressed: () { setState(() => _assigning = false); context.read<AdminVendorsCubit>().clearSelectedVendor(); },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );

    if (vendor == null) {
      return Column(
        children: [
          header,
          if (widget.state.isLoadingDetail)
            const LinearProgressIndicator(minHeight: 2),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (_assigning) {
      return Column(
        children: [
          header,
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _AssignSubscriptionForm(
                vendorId: vendor.id,
                plans: widget.state.plans,
                l10n: l10n,
                onCancel: () => setState(() => _assigning = false),
                onSaved: () {
                  setState(() => _assigning = false);
                  context.read<AdminVendorsCubit>().selectVendor(vendor.id);
                },
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        header,
        if (widget.state.isLoadingDetail) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identity
                _IdentitySection(vendor: vendor, l10n: l10n, cs: cs, fg: widget.fg, muted: widget.muted),
                _Divider(color: widget.borderColor),
                // Stats 2x2
                _StatsGrid(vendor: vendor, l10n: l10n, isDark: widget.isDark, fg: widget.fg, muted: widget.muted),
                _Divider(color: widget.borderColor),
                // Financials
                _FinancialsSection(vendor: vendor, l10n: l10n, isDark: widget.isDark, fg: widget.fg, muted: widget.muted),
                _Divider(color: widget.borderColor),
                // Subscription
                _SubscriptionSection(vendor: vendor, l10n: l10n, fg: widget.fg, muted: widget.muted, borderColor: widget.borderColor, onAssign: () => setState(() => _assigning = true)),
                _Divider(color: widget.borderColor),
                // Feature limits
                _FeatureLimitsSection(vendor: vendor, l10n: l10n, fg: widget.fg, muted: widget.muted),
                // Notes
                if (vendor.notes?.isNotEmpty == true) ...[
                  _Divider(color: widget.borderColor),
                  _NotesSection(vendor: vendor, l10n: l10n, fg: widget.fg, muted: widget.muted),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEdit(BuildContext context, AdminVendorEntity vendor) {
    final cubit = context.read<AdminVendorsCubit>();
    final state = cubit.state is AdminVendorsLoaded ? cubit.state as AdminVendorsLoaded : null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _EditVendorDialog(
          vendor: vendor,
          l10n: widget.l10n,
          createMeta: state?.createMeta,
          plans: state?.plans ?? const [],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});
  @override
  Widget build(BuildContext context) => Divider(height: 32, color: color.withValues(alpha: 0.5));
}

// ── slide-over sections ───────────────────────────────────────────────────────

class _IdentitySection extends StatelessWidget {
  final AdminVendorEntity vendor;
  final AppLocalizations l10n;
  final ColorScheme cs;
  final Color fg, muted;

  const _IdentitySection({required this.vendor, required this.l10n, required this.cs, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: AppRadius.brMd),
          child: Center(
            child: Text(
              vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : '?',
              style: AppTextStyles.labelLg.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(vendor.name, style: AppTextStyles.labelLg.copyWith(color: fg, fontWeight: FontWeight.w600)),
                  _AccountBadge(status: vendor.status, l10n: l10n),
                  _PlanBadge(planName: vendor.planName),
                  _SubscriptionBadge(status: vendor.subscriptionDisplayStatus, expiringSoon: vendor.subscriptionDisplayExpiringSoon, l10n: l10n),
                ],
              ),
              if (vendor.slug?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(vendor.slug!, style: AppTextStyles.caption.copyWith(color: muted, fontFamily: 'monospace')),
              ],
              const SizedBox(height: 2),
              Text(
                [if (vendor.timezone != null) vendor.timezone!, if (vendor.currencyCode != null) vendor.currencyCode!, l10n.t('joined') + ' ' + _fmtDate(vendor.createdAt)].join(' · '),
                style: AppTextStyles.caption.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AdminVendorEntity vendor;
  final AppLocalizations l10n;
  final bool isDark;
  final Color fg, muted;

  const _StatsGrid({required this.vendor, required this.l10n, required this.isDark, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    final bgStat = isDark ? AppColors.darkMuted : AppColors.muted;
    final stats = [
      (Icons.manage_accounts_rounded, l10n.t('colUsers'), '${vendor.usersCount ?? 0}', null as String?),
      (Icons.account_tree_rounded, l10n.t('branches'), '${vendor.branchesCount ?? 0}', null),
      (Icons.inventory_2_rounded, l10n.t('products'), '${vendor.productsCount ?? 0}', null),
      (Icons.shopping_bag_rounded, l10n.t('colOrders'), '${vendor.ordersCount ?? 0}', l10n.t('statsPaidOrders')),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.4,
      children: stats.map((s) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: bgStat, borderRadius: AppRadius.brMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(s.$1, size: 13, color: muted),
              const SizedBox(width: 4),
              Text(s.$2, style: AppTextStyles.caption.copyWith(color: muted)),
            ]),
            const SizedBox(height: 4),
            Text(s.$3, style: AppTextStyles.h5.copyWith(color: fg, fontWeight: FontWeight.w600)),
            if (s.$4 != null) Text(s.$4!, style: AppTextStyles.caption.copyWith(color: muted)),
          ],
        ),
      )).toList(),
    );
  }
}

class _FinancialsSection extends StatelessWidget {
  final AdminVendorEntity vendor;
  final AppLocalizations l10n;
  final bool isDark;
  final Color fg, muted;

  const _FinancialsSection({required this.vendor, required this.l10n, required this.isDark, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    final bgStat = isDark ? AppColors.darkMuted : AppColors.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('financialsTitle'), style: AppTextStyles.caption.copyWith(color: muted, letterSpacing: 0.8), ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.4,
          children: [
            _StatCell(icon: Icons.attach_money_rounded, label: l10n.t('billingCollected'), value: _fmtCurrency(vendor.billingCollected), bg: bgStat, fg: fg, muted: muted),
            _StatCell(icon: Icons.receipt_rounded, label: l10n.t('billingPending'), value: '—', bg: bgStat, fg: fg, muted: muted),
            _StatCell(icon: Icons.trending_up_rounded, label: l10n.t('salesNet'), value: _fmtCurrency(vendor.totalRevenue), bg: bgStat, fg: fg, muted: muted),
            _StatCell(icon: Icons.receipt_long_rounded, label: l10n.t('invoicesOutstanding'), value: '—', bg: bgStat, fg: fg, muted: muted),
          ],
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color bg, fg, muted;
  const _StatCell({required this.icon, required this.label, required this.value, required this.bg, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 13, color: muted), const SizedBox(width: 4), Expanded(child: Text(label, style: AppTextStyles.caption.copyWith(color: muted), overflow: TextOverflow.ellipsis))]),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.labelMd.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  final AdminVendorEntity vendor;
  final AppLocalizations l10n;
  final Color fg, muted, borderColor;
  final VoidCallback onAssign;

  const _SubscriptionSection({required this.vendor, required this.l10n, required this.fg, required this.muted, required this.borderColor, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    final sub = vendor.currentSubscription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('subscriptionTitle').toUpperCase(), style: AppTextStyles.caption.copyWith(color: muted, letterSpacing: 0.8)),
        const SizedBox(height: AppSpacing.sm),
        if (sub != null) ...[
          if (sub.planName.isNotEmpty) _DetailRow(label: l10n.t('plan'), value: sub.planName, fg: fg, muted: muted),
          _DetailRow(label: l10n.t('statusLabel'), value: _localizeSubStatus(sub.status, l10n), fg: fg, muted: muted),
          if (sub.startedAt.isNotEmpty) _DetailRow(label: l10n.t('startedAt'), value: _fmtDate(sub.startedAt), fg: fg, muted: muted),
          if (sub.endsAt != null) _DetailRow(label: l10n.t('endsAt'), value: _fmtDate(sub.endsAt!), fg: fg, muted: muted),
          if (vendor.billingEmail != null) _DetailRow(label: l10n.t('billingEmail'), value: vendor.billingEmail!, fg: fg, muted: muted),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(borderRadius: AppRadius.brMd, border: Border.all(color: borderColor, style: BorderStyle.solid)),
            child: Row(
              children: [
                Expanded(child: Text(l10n.t('noSubscriptions'), style: AppTextStyles.bodySm.copyWith(color: muted))),
                _ActionButton(label: '+ ${l10n.t("assign")}', onTap: onAssign),
              ],
            ),
          ),
      ],
    );
  }
}

class _FeatureLimitsSection extends StatelessWidget {
  final AdminVendorEntity vendor;
  final AppLocalizations l10n;
  final Color fg, muted;

  const _FeatureLimitsSection({required this.vendor, required this.l10n, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('featureUsageLimitsTitle').toUpperCase(), style: AppTextStyles.caption.copyWith(color: muted, letterSpacing: 0.8)),
        const SizedBox(height: AppSpacing.sm),
        _LimitBar(label: l10n.t('branches'), used: vendor.branchesCount ?? 0, max: vendor.maxBranches, fg: fg, muted: muted),
        const SizedBox(height: AppSpacing.sm),
        _LimitBar(label: l10n.t('users'), used: vendor.usersCount ?? 0, max: vendor.maxUsers, fg: fg, muted: muted),
        const SizedBox(height: AppSpacing.sm),
        _LimitBar(label: l10n.t('products'), used: vendor.productsCount ?? 0, max: vendor.maxProducts, fg: fg, muted: muted),
      ],
    );
  }
}

class _LimitBar extends StatelessWidget {
  final String label;
  final int used;
  final int? max;
  final Color fg, muted;

  const _LimitBar({required this.label, required this.used, this.max, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    final pct = max != null && max! > 0 ? (used / max!).clamp(0.0, 1.0) : 0.0;
    final barColor = pct >= 0.9 ? AppColors.destructive : pct >= 0.7 ? AppColors.warning : AppColors.primary;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: muted)),
            Text(max != null ? '$used / $max' : '$used', style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w500)),
          ],
        ),
        if (max != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: AppRadius.brFull,
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppColors.muted,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  final AdminVendorEntity vendor;
  final AppLocalizations l10n;
  final Color fg, muted;

  const _NotesSection({required this.vendor, required this.l10n, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('adminNotesTitle').toUpperCase(), style: AppTextStyles.caption.copyWith(color: muted, letterSpacing: 0.8)),
        const SizedBox(height: AppSpacing.sm),
        Text(vendor.notes!, style: AppTextStyles.bodySm.copyWith(color: fg)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color fg, muted;
  const _DetailRow({required this.label, required this.value, required this.fg, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.bodySm.copyWith(color: muted))),
          Expanded(child: Text(value, style: AppTextStyles.bodySm.copyWith(color: fg, fontWeight: FontWeight.w500), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

// ── assign subscription form ──────────────────────────────────────────────────

class _AssignSubscriptionForm extends StatefulWidget {
  final String vendorId;
  final List<AdminPlanEntity> plans;
  final AppLocalizations l10n;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  const _AssignSubscriptionForm({
    required this.vendorId, required this.plans, required this.l10n,
    required this.onCancel, required this.onSaved,
  });

  @override
  State<_AssignSubscriptionForm> createState() => _AssignSubscriptionFormState();
}

class _AssignSubscriptionFormState extends State<_AssignSubscriptionForm> {
  final _startsAt = TextEditingController();
  final _expiresAt = TextEditingController();
  final _notes = TextEditingController();
  String? _planId;
  String _status = 'active';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startsAt.text = DateTime.now().toIso8601String().substring(0, 10);
    if (widget.plans.isNotEmpty) _planId = widget.plans.first.id;
  }

  @override
  void dispose() {
    _startsAt.dispose(); _expiresAt.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_planId == null) { setState(() => _error = widget.l10n.t('fieldRequired')); return; }
    setState(() { _saving = true; _error = null; });
    final data = {
      'plan_id': _planId,
      'status': _status,
      'starts_at': _startsAt.text.trim(),
      if (_expiresAt.text.trim().isNotEmpty) 'expires_at': _expiresAt.text.trim(),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
    };
    final ok = await context.read<AdminVendorsCubit>().assignSubscription(widget.vendorId, data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) { widget.onSaved(); } else { setState(() => _error = widget.l10n.t('errorSaving')); }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final selected = widget.plans.where((p) => p.id == _planId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.destructive.withValues(alpha: 0.08), borderRadius: AppRadius.brMd),
            child: Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.destructive)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppSelectField<String>(
          label: l10n.t('plan'),
          value: _planId,
          options: widget.plans.map((p) => AppSelectOption(value: p.id, label: '${p.name} — \$${p.price}/mo')).toList(),
          onChanged: (v) => setState(() => _planId = v),
        ),
        if (selected != null) ...[
          const SizedBox(height: 4),
          Text(
            '${l10n.t("products")}: ${selected.maxProducts ?? '∞'}  ·  ${l10n.t("users")}: ${selected.maxUsers ?? '∞'}  ·  ${l10n.t("branches")}: ${selected.maxBranches ?? '∞'}',
            style: AppTextStyles.caption,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppSelectField<String>(
          label: l10n.t('subscriptionStatus'),
          value: _status,
          options: [
            AppSelectOption(value: 'active', label: l10n.t('status_active')),
            AppSelectOption(value: 'trial', label: l10n.t('status_trial')),
            AppSelectOption(value: 'past_due', label: l10n.t('status_past_due')),
          ],
          onChanged: (v) => setState(() => _status = v ?? 'active'),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: AppTextField(controller: _startsAt, label: l10n.t('startDate'), hint: 'YYYY-MM-DD')),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: AppTextField(controller: _expiresAt, label: l10n.t('expiresAt'), hint: 'YYYY-MM-DD')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _notes, label: l10n.t('notesLabel'), maxLines: 2),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: l10n.cancel,
                onPressed: widget.onCancel,
                variant: AppButtonVariant.ghost,
                fullWidth: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: l10n.t('assignSubscription'),
                onPressed: _saving ? null : _save,
                isLoading: _saving,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── shared helpers ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color borderColor;
  const _SectionTitle({required this.title, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).brightness == Brightness.dark ? AppColors.darkForeground : AppColors.foreground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700, color: fg)),
        const SizedBox(height: AppSpacing.xs),
        Divider(color: borderColor, height: 1),
      ],
    );
  }
}

// Common static data
const _kCurrencies = [
  'USD', 'EGP', 'SAR', 'AED', 'KWD', 'QAR', 'BHD', 'OMR',
  'JOD', 'IQD', 'LBP', 'MAD', 'TND', 'DZD', 'LYD',
];

const _kFeatures = [
  ('reports',    Icons.bar_chart_rounded),
  ('catalog',    Icons.category_rounded),
  ('customers',  Icons.people_rounded),
  ('purchasing', Icons.shopping_cart_rounded),
  ('inventory',  Icons.inventory_2_rounded),
  ('operations', Icons.settings_rounded),
  ('devices',    Icons.devices_rounded),
];

// ── create vendor dialog ──────────────────────────────────────────────────────

class _CreateVendorDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final List<AdminPlanEntity> plans;
  final VendorCreateMetaEntity? createMeta;

  const _CreateVendorDialog({
    required this.l10n,
    required this.plans,
    this.createMeta,
  });

  @override
  State<_CreateVendorDialog> createState() => _CreateVendorDialogState();
}

class _CreateVendorDialogState extends State<_CreateVendorDialog> {
  // Section 1 – Basic Info
  final _name    = TextEditingController();
  final _email   = TextEditingController(); // vendor store email
  final _phone   = TextEditingController();
  final _country = TextEditingController();
  String _currency = 'USD';
  String _status   = 'active';

  // Section 2 – Owner Account
  final _ownerName     = TextEditingController();
  final _ownerEmail    = TextEditingController();
  final _ownerPassword = TextEditingController();
  bool _showPassword   = false;

  // Section 3 – Plan & Limits
  String? _planId;
  final _maxUsers    = TextEditingController();
  final _maxBranches = TextEditingController();
  final _maxProducts = TextEditingController();

  // Section 4 – Features
  final Set<String> _createFeatures = {for (final f in _kFeatures) f.$1};

  // Section 5 – Modules & Permissions
  List<String>? _allowedPermissions; // null = unrestricted
  final Set<String> _expandedModules = {};

  bool _saving = false;

  List<AdminPlanEntity> get _plans =>
      widget.createMeta?.plans.isNotEmpty == true
          ? widget.createMeta!.plans
          : widget.plans;

  List<String> get _allPermKeys =>
      (widget.createMeta?.modules ?? [])
          .expand((m) => m.permissions.map((p) => p.key))
          .toList();

  bool get _isUnrestricted => _allowedPermissions == null;

  int _modulePermSelected(VendorModuleEntity mod) {
    if (_isUnrestricted) return mod.permissions.length;
    return mod.permissions.where((p) => (_allowedPermissions!).contains(p.key)).length;
  }

  bool _isModulePartial(VendorModuleEntity mod) {
    if (_isUnrestricted) return false;
    final n = _modulePermSelected(mod);
    return n > 0 && n < mod.permissions.length;
  }

  bool _isModuleChecked(VendorModuleEntity mod) {
    if (_isUnrestricted) return true;
    return mod.permissions.every((p) => (_allowedPermissions!).contains(p.key));
  }

  void _toggleModule(VendorModuleEntity mod) {
    if (_isUnrestricted) return;
    final keys = mod.permissions.map((p) => p.key).toList();
    final allOn = _isModuleChecked(mod);
    setState(() {
      final cur = List<String>.from(_allowedPermissions!);
      if (allOn) {
        _allowedPermissions = cur.where((k) => !keys.contains(k)).toList();
      } else {
        _allowedPermissions = {...cur, ...keys}.toList();
      }
    });
  }

  void _togglePerm(String key) {
    if (_isUnrestricted) return;
    setState(() {
      final cur = List<String>.from(_allowedPermissions!);
      if (cur.contains(key)) {
        _allowedPermissions = cur.where((k) => k != key).toList();
      } else {
        _allowedPermissions = [...cur, key];
      }
    });
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _phone.dispose(); _country.dispose();
    _ownerName.dispose(); _ownerEmail.dispose(); _ownerPassword.dispose();
    _maxUsers.dispose(); _maxBranches.dispose(); _maxProducts.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = widget.l10n;
    if (_name.text.trim().isEmpty) {
      AppSnackbar.error(context, '${l10n.t("vendorName")}: ${l10n.t("fieldRequired")}');
      return;
    }
    if (_ownerEmail.text.trim().isEmpty) {
      AppSnackbar.error(context, '${l10n.t("ownerEmail")}: ${l10n.t("fieldRequired")}');
      return;
    }
    if (_ownerPassword.text.isEmpty) {
      AppSnackbar.error(context, '${l10n.t("labelPassword")}: ${l10n.t("fieldRequired")}');
      return;
    }

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'basic': {
        'name':     _name.text.trim(),
        'email':    _email.text.trim(),
        'phone':    _phone.text.trim(),
        'country':  _country.text.trim(),
        'currency': _currency,
        'status':   _status,
      },
      'owner': {
        'name':     _ownerName.text.trim(),
        'email':    _ownerEmail.text.trim(),
        'password': _ownerPassword.text,
      },
      'plan': {
        'max_users':    _maxUsers.text.trim().isNotEmpty ? int.tryParse(_maxUsers.text.trim()) : null,
        'max_branches': _maxBranches.text.trim().isNotEmpty ? int.tryParse(_maxBranches.text.trim()) : null,
        'max_products': _maxProducts.text.trim().isNotEmpty ? int.tryParse(_maxProducts.text.trim()) : null,
      },
      'allowed_permissions': _allowedPermissions,
      'features': _createFeatures.toList(),
    };

    final ok = await context.read<AdminVendorsCubit>().createVendor(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
      AppSnackbar.success(context, l10n.t('vendorCreated'));
    } else {
      AppSnackbar.error(context, l10n.t('errorSaving'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cs = Theme.of(context).colorScheme;

    final meta = widget.createMeta;
    final statuses = meta?.statuses.isNotEmpty == true
        ? meta!.statuses
        : ['active', 'inactive', 'suspended'];
    final currencies = meta?.currencies.isNotEmpty == true
        ? meta!.currencies
        : _kCurrencies;
    final modules = meta?.modules ?? [];

    final selPlan = _plans.where((p) => p.id == _planId).firstOrNull;
    final totalSelected = _isUnrestricted ? _allPermKeys.length : (_allowedPermissions?.length ?? 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t('addVendor'), style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(l10n.t('addVendorSubtitle'), style: AppTextStyles.bodySm.copyWith(color: muted)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── 1. Basic Info ────────────────────────────────────
                    _SectionTitle(title: '1. ${l10n.t("storeInfo")}', borderColor: borderColor),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(child: AppTextField(controller: _name,  label: '${l10n.t("vendorName")} *')),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(controller: _email, label: l10n.t('vendorEmail'), keyboardType: TextInputType.emailAddress)),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(child: AppTextField(controller: _phone,   label: l10n.t('phone'), keyboardType: TextInputType.phone)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(controller: _country, label: l10n.t('country'), hint: 'EG')),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(
                        child: AppSelectField<String>(
                          label: l10n.t('currency'),
                          value: currencies.contains(_currency) ? _currency : currencies.first,
                          options: currencies.map((c) => AppSelectOption(value: c, label: c)).toList(),
                          onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppSelectField<String>(
                          label: l10n.t('statusLabel'),
                          value: statuses.contains(_status) ? _status : statuses.first,
                          options: statuses.map((s) => AppSelectOption(value: s, label: s)).toList(),
                          onChanged: (v) => setState(() => _status = v ?? 'active'),
                        ),
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),
                    // ── 2. Owner Account ─────────────────────────────────
                    _SectionTitle(title: '2. ${l10n.t("ownerAccount")}', borderColor: borderColor),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(child: AppTextField(controller: _ownerName,  label: l10n.t('ownerName'))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(controller: _ownerEmail, label: '${l10n.t("ownerEmail")} *', keyboardType: TextInputType.emailAddress)),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _ownerPassword,
                      label: '${l10n.t("labelPassword")} *',
                      obscureText: !_showPassword,
                      suffix: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    // ── 3. Plan & Limits ─────────────────────────────────
                    _SectionTitle(title: '3. ${l10n.t("planAndBilling")}', borderColor: borderColor),
                    const SizedBox(height: AppSpacing.md),
                    AppSelectField<String>(
                      label: l10n.t('plan'),
                      value: _planId,
                      options: [
                        AppSelectOption(value: '', label: l10n.t('noPlan')),
                        ..._plans.map((p) => AppSelectOption(value: p.id, label: p.name)),
                      ],
                      onChanged: (v) => setState(() {
                        _planId = (v == null || v.isEmpty) ? null : v;
                        if (_planId != null) {
                          final p = _plans.where((pl) => pl.id == _planId).firstOrNull;
                          if (p != null) {
                            _maxUsers.text    = p.maxUsers?.toString() ?? '';
                            _maxBranches.text = p.maxBranches?.toString() ?? '';
                            _maxProducts.text = p.maxProducts?.toString() ?? '';
                          }
                        }
                      }),
                    ),
                    if (selPlan != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${selPlan.name} (${selPlan.slug})',
                        style: AppTextStyles.caption.copyWith(color: muted),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(child: AppTextField(controller: _maxUsers,    label: l10n.t('maxUsers'),    keyboardType: TextInputType.number)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(controller: _maxBranches, label: l10n.t('maxBranches'), keyboardType: TextInputType.number)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(controller: _maxProducts, label: l10n.t('maxProducts'), keyboardType: TextInputType.number)),
                    ]),

                    const SizedBox(height: AppSpacing.xl),
                    // ── 4. Features ──────────────────────────────────────
                    _SectionTitle(title: '4. ${l10n.t("featuresAndNotes")}', borderColor: borderColor),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: _kFeatures.map((f) {
                        final key = f.$1;
                        final icon = f.$2;
                        final checked = _createFeatures.contains(key);
                        return _FeatureChip(
                          featureKey: key, icon: icon, checked: checked,
                          label: l10n.t('feature_$key'),
                          onToggle: () => setState(() {
                            if (checked) { _createFeatures.remove(key); } else { _createFeatures.add(key); }
                          }),
                        );
                      }).toList(),
                    ),

                    if (modules.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      // ── 5. Modules & Permissions ─────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.brLg,
                          border: Border.all(color: borderColor),
                          color: bg,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.4))),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('5. ${l10n.t("modulesTitle")}', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700, color: fg)),
                                        Text(l10n.t('modulesSubtitle'), style: AppTextStyles.caption.copyWith(color: muted)),
                                      ],
                                    ),
                                  ),
                                  // Controls
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    children: [
                                      if (!_isUnrestricted) ...[
                                        _ModuleButton(
                                          label: l10n.t('modulesEnableAll'),
                                          onTap: () => setState(() => _allowedPermissions = List.from(_allPermKeys)),
                                        ),
                                        _ModuleButton(
                                          label: l10n.t('modulesDisableAll'),
                                          onTap: () => setState(() => _allowedPermissions = []),
                                        ),
                                      ],
                                      _ModuleToggleButton(
                                        label: l10n.t('modulesUnrestricted'),
                                        checked: _isUnrestricted,
                                        onTap: () => setState(() {
                                          _allowedPermissions = _isUnrestricted ? List.from(_allPermKeys) : null;
                                        }),
                                        cs: cs,
                                        borderColor: borderColor,
                                        muted: muted,
                                        fg: fg,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Summary bar
                            if (!_isUnrestricted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                                  border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.4))),
                                ),
                                child: Text(
                                  '$totalSelected / ${_allPermKeys.length} ${l10n.t("modulesCount")}',
                                  style: AppTextStyles.caption.copyWith(color: muted),
                                ),
                              ),
                            // Module rows
                            Opacity(
                              opacity: _isUnrestricted ? 0.5 : 1.0,
                              child: IgnorePointer(
                                ignoring: _isUnrestricted,
                                child: Column(
                                  children: modules.map((mod) {
                                    final checked = _isModuleChecked(mod);
                                    final partial = _isModulePartial(mod);
                                    final expanded = _expandedModules.contains(mod.key);
                                    final selected = _modulePermSelected(mod);

                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () => setState(() {
                                            if (_expandedModules.contains(mod.key)) {
                                              _expandedModules.remove(mod.key);
                                            } else {
                                              _expandedModules.add(mod.key);
                                            }
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                                            decoration: BoxDecoration(
                                              color: (checked || partial) ? cs.primary.withValues(alpha: 0.04) : Colors.transparent,
                                              border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.3))),
                                            ),
                                            child: Row(
                                              children: [
                                                // Indeterminate-style checkbox
                                                GestureDetector(
                                                  onTap: () => _toggleModule(mod),
                                                  child: Container(
                                                    width: 16, height: 16,
                                                    decoration: BoxDecoration(
                                                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                                                      border: Border.all(color: checked ? cs.primary : (partial ? cs.primary : borderColor), width: checked || partial ? 0 : 1.5),
                                                      color: checked ? cs.primary : (partial ? cs.primary.withValues(alpha: 0.5) : Colors.transparent),
                                                    ),
                                                    child: checked
                                                        ? const Icon(Icons.check, size: 11, color: Colors.white)
                                                        : partial
                                                            ? Center(child: Container(width: 8, height: 2, color: Colors.white))
                                                            : null,
                                                  ),
                                                ),
                                                const SizedBox(width: AppSpacing.sm),
                                                Expanded(
                                                  child: Text(
                                                    mod.label,
                                                    style: AppTextStyles.bodySm.copyWith(
                                                      color: (checked || partial) ? fg : muted,
                                                      fontWeight: (checked || partial) ? FontWeight.w500 : FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                                if (checked || partial)
                                                  Text(
                                                    '$selected/${mod.permissions.length}',
                                                    style: AppTextStyles.caption.copyWith(color: muted),
                                                  ),
                                                const SizedBox(width: AppSpacing.xs),
                                                Icon(
                                                  expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                                  size: 16, color: muted,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (expanded)
                                          Container(
                                            color: isDark ? AppColors.darkMuted.withValues(alpha: 0.5) : AppColors.muted.withValues(alpha: 0.5),
                                            padding: const EdgeInsets.fromLTRB(AppSpacing.xl + AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                                            child: Column(
                                              children: mod.permissions.map((perm) {
                                                final on = (_allowedPermissions ?? []).contains(perm.key);
                                                return InkWell(
                                                  onTap: () => _togglePerm(perm.key),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          width: 16, height: 16,
                                                          margin: const EdgeInsets.only(top: 1),
                                                          decoration: BoxDecoration(
                                                            borderRadius: const BorderRadius.all(Radius.circular(3)),
                                                            border: Border.all(color: on ? cs.primary : borderColor, width: on ? 0 : 1.5),
                                                            color: on ? cs.primary : Colors.transparent,
                                                          ),
                                                          child: on
                                                              ? const Icon(Icons.check, size: 11, color: Colors.white)
                                                              : null,
                                                        ),
                                                        const SizedBox(width: AppSpacing.sm),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(perm.label, style: AppTextStyles.bodySm.copyWith(color: on ? fg : muted, fontWeight: on ? FontWeight.w500 : FontWeight.normal)),
                                                              if (perm.description.isNotEmpty)
                                                                Text(perm.description, style: AppTextStyles.caption.copyWith(color: muted)),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(label: l10n.cancel, onPressed: () => Navigator.of(context).pop(), variant: AppButtonVariant.ghost),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton(label: l10n.t('addVendor'), onPressed: _saving ? null : _save, isLoading: _saving),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ModuleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(borderRadius: AppRadius.brMd, border: Border.all(color: borderColor)),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.caption.copyWith(color: fg)),
      ),
    );
  }
}

class _ModuleToggleButton extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;
  final ColorScheme cs;
  final Color borderColor, muted, fg;
  const _ModuleToggleButton({
    required this.label, required this.checked, required this.onTap,
    required this.cs, required this.borderColor, required this.muted, required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brMd,
          border: Border.all(color: checked ? cs.primary : borderColor),
          color: checked ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(3)),
                border: Border.all(color: checked ? cs.primary : borderColor, width: checked ? 0 : 1.5),
                color: checked ? cs.primary : Colors.transparent,
              ),
              child: checked ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
            ),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.caption.copyWith(color: checked ? cs.primary : fg)),
          ],
        ),
      ),
    );
  }
}

// ── edit vendor dialog ────────────────────────────────────────────────────────

class _EditVendorDialog extends StatefulWidget {
  final AdminVendorEntity vendor;
  final AppLocalizations l10n;
  final VendorCreateMetaEntity? createMeta;
  final List<AdminPlanEntity> plans;

  const _EditVendorDialog({
    required this.vendor,
    required this.l10n,
    this.createMeta,
    required this.plans,
  });

  @override
  State<_EditVendorDialog> createState() => _EditVendorDialogState();
}

class _EditVendorDialogState extends State<_EditVendorDialog> {
  // Section 1 – Basic Info
  late final TextEditingController _name;
  late final TextEditingController _email; // billing_email
  late final TextEditingController _phone;
  late final TextEditingController _country;
  late String _currency;
  late String _status;

  // Section 2 – Plan & Subscription
  late String? _planId;
  late String  _subscriptionStatus;
  late final TextEditingController _planExpiresAt;
  late final TextEditingController _trialEndsAt;
  late final TextEditingController _maxUsers;
  late final TextEditingController _maxBranches;
  late final TextEditingController _maxProducts;

  // Section 3 – Features
  late Set<String> _features;

  // Section 4 – Notes
  late final TextEditingController _notes;

  bool _saving = false;
  bool _loadingDetail = true; // true until full detail is fetched (mirrors React hydration)

  List<AdminPlanEntity> get _plans =>
      widget.createMeta?.plans.isNotEmpty == true
          ? widget.createMeta!.plans
          : widget.plans;

  @override
  void initState() {
    super.initState();
    // Pre-fill with whatever is available (may be partial list entity)
    _initControllers(widget.vendor);
    // Always fetch full detail — matches React GET /admin/vendors/:id flow
    _fetchDetail();
  }

  void _initControllers(AdminVendorEntity v) {
    _name               = TextEditingController(text: v.name);
    _email              = TextEditingController(text: v.billingEmail ?? '');
    _phone              = TextEditingController(text: v.phone ?? '');
    _country            = TextEditingController(text: v.country ?? '');
    _currency           = (v.currencyCode ?? 'USD').toUpperCase();
    _status             = v.status;
    _planId             = v.planId;
    _subscriptionStatus = v.subscriptionStatus ?? 'active';
    _planExpiresAt      = TextEditingController(text: _sliceDate(v.planExpiresAt));
    _trialEndsAt        = TextEditingController(text: _sliceDate(v.trialEndsAt ?? v.currentSubscription?.trialEndsAt));
    _maxUsers           = TextEditingController(text: v.maxUsers?.toString() ?? '');
    _maxBranches        = TextEditingController(text: v.maxBranches?.toString() ?? '');
    _maxProducts        = TextEditingController(text: v.maxProducts?.toString() ?? '');
    _features           = Set.from(v.assignedFeatureKeys);
    _notes              = TextEditingController(text: v.notes ?? '');
  }

  Future<void> _fetchDetail() async {
    final result = await getIt<GetAdminVendorDetailsUseCase>()(widget.vendor.id);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loadingDetail = false),
      (detail) {
        // Update all form fields from the authoritative detail entity
        _name.text          = detail.name;
        _email.text         = detail.billingEmail ?? '';
        _phone.text         = detail.phone ?? '';
        _country.text       = detail.country ?? '';
        _planExpiresAt.text = _sliceDate(detail.planExpiresAt);
        _trialEndsAt.text   = _sliceDate(detail.trialEndsAt ?? detail.currentSubscription?.trialEndsAt);
        _maxUsers.text      = detail.maxUsers?.toString() ?? '';
        _maxBranches.text   = detail.maxBranches?.toString() ?? '';
        _maxProducts.text   = detail.maxProducts?.toString() ?? '';
        _notes.text         = detail.notes ?? '';
        setState(() {
          _currency           = (detail.currencyCode ?? 'USD').toUpperCase();
          _status             = detail.status;
          _planId             = detail.planId;
          _subscriptionStatus = detail.subscriptionStatus ?? 'active';
          _features           = Set.from(detail.assignedFeatureKeys);
          _loadingDetail      = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _phone.dispose(); _country.dispose();
    _planExpiresAt.dispose(); _trialEndsAt.dispose();
    _maxUsers.dispose(); _maxBranches.dispose(); _maxProducts.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = widget.l10n;
    if (_name.text.trim().isEmpty) {
      AppSnackbar.error(context, l10n.t('fieldRequired'));
      return;
    }
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name':                _name.text.trim(),
      'phone':               _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'country':             _country.text.trim().isEmpty ? null : _country.text.trim(),
      'currency':            _currency.trim().toUpperCase(),
      'status':              _status,
      'billing_email':       _email.text.trim().isEmpty ? null : _email.text.trim(),
      'plan_id':             (_planId?.isEmpty ?? true) ? null : _planId,
      'subscription_status': _subscriptionStatus,
      'plan_expires_at':     _planExpiresAt.text.trim().isEmpty ? null : _planExpiresAt.text.trim(),
      'trial_ends_at':       _trialEndsAt.text.trim().isEmpty ? null : _trialEndsAt.text.trim(),
      'max_users':           _maxUsers.text.trim().isEmpty ? null : int.tryParse(_maxUsers.text.trim()),
      'max_branches':        _maxBranches.text.trim().isEmpty ? null : int.tryParse(_maxBranches.text.trim()),
      'max_products':        _maxProducts.text.trim().isEmpty ? null : int.tryParse(_maxProducts.text.trim()),
      'notes':               _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'features':            _features.toList(),
    };

    final ok = await context.read<AdminVendorsCubit>().updateVendor(widget.vendor.id, data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
      AppSnackbar.success(context, l10n.t('vendorUpdated'));
    } else {
      AppSnackbar.error(context, l10n.t('errorSaving'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    final meta = widget.createMeta;
    final statuses = meta?.statuses.isNotEmpty == true ? meta!.statuses : ['active', 'inactive', 'suspended'];
    final currencies = meta?.currencies.isNotEmpty == true ? meta!.currencies : _kCurrencies;
    final apiFeatures = meta?.features ?? [];

    final selPlan = _plans.where((p) => p.id == _planId).firstOrNull;
    final validCurrency = currencies.contains(_currency) ? _currency : currencies.first;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.t('editVendor'), style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(widget.vendor.name, style: AppTextStyles.bodySm.copyWith(color: muted)),
                    ],
                  )),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            // Loading indicator while fetching full vendor detail
            if (_loadingDetail) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── 1. Basic Info ────────────────────────────────────
                    _SectionTitle(title: '1. ${l10n.t("storeInfo")}', borderColor: borderColor),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(child: AppTextField(controller: _name,  label: '${l10n.t("vendorName")} *')),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(controller: _email, label: l10n.t('billingEmail'), hint: l10n.t('billingEmailHint'), keyboardType: TextInputType.emailAddress)),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(child: AppTextField(controller: _phone,   label: l10n.t('phone'), keyboardType: TextInputType.phone)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(controller: _country, label: l10n.t('country'), hint: 'EG')),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(
                        child: AppSelectField<String>(
                          label: l10n.t('currency'),
                          value: validCurrency,
                          options: currencies.map((c) => AppSelectOption(value: c, label: c)).toList(),
                          onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppSelectField<String>(
                          label: l10n.t('statusLabel'),
                          value: statuses.contains(_status) ? _status : statuses.first,
                          options: statuses.map((s) => AppSelectOption(value: s, label: s)).toList(),
                          onChanged: (v) => setState(() => _status = v ?? _status),
                        ),
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),
                    // ── 2. Owner (display-only — API does not return owner user data) ──
                    _SectionTitle(title: '2. ${l10n.t("ownerAccount")}', borderColor: borderColor),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.t('ownerHint'), style: AppTextStyles.bodySm.copyWith(color: muted)),

                    const SizedBox(height: AppSpacing.xl),
                    // ── 3. Plan & Subscription ───────────────────────────
                    _SectionTitle(title: '3. ${l10n.t("planAndBilling")}', borderColor: borderColor),
                    const SizedBox(height: AppSpacing.md),
                    AppSelectField<String>(
                      label: l10n.t('plan'),
                      value: _planId,
                      options: [
                        AppSelectOption(value: '', label: l10n.t('noPlan')),
                        ..._plans.map((p) => AppSelectOption(value: p.id, label: p.name)),
                      ],
                      onChanged: (v) => setState(() {
                        _planId = (v == null || v.isEmpty) ? null : v;
                        if (_planId != null) {
                          final p = _plans.where((pl) => pl.id == _planId).firstOrNull;
                          if (p != null) {
                            _maxUsers.text    = p.maxUsers?.toString() ?? '';
                            _maxBranches.text = p.maxBranches?.toString() ?? '';
                            _maxProducts.text = p.maxProducts?.toString() ?? '';
                          }
                        }
                      }),
                    ),
                    if (selPlan != null) ...[
                      const SizedBox(height: 4),
                      Text('${selPlan.name} (${selPlan.slug})', style: AppTextStyles.caption.copyWith(color: muted)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.t('subscriptionStatus'), style: AppTextStyles.caption.copyWith(color: muted, fontWeight: FontWeight.w500)),
                            const SizedBox(height: AppSpacing.xs),
                            AppSelectField<String>(
                              value: _subscriptionStatus,
                              options: [
                                AppSelectOption(value: 'active',    label: l10n.t('status_active')),
                                AppSelectOption(value: 'trial',     label: l10n.t('status_trial')),
                                AppSelectOption(value: 'past_due',  label: l10n.t('status_past_due')),
                                AppSelectOption(value: 'cancelled', label: l10n.t('status_canceled')),
                                AppSelectOption(value: 'suspended', label: l10n.t('status_suspended')),
                              ],
                              onChanged: (v) => setState(() => _subscriptionStatus = v ?? _subscriptionStatus),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(child: SizedBox()),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.t('planExpires'), style: AppTextStyles.caption.copyWith(color: muted, fontWeight: FontWeight.w500)),
                            const SizedBox(height: AppSpacing.xs),
                            AppTextField(controller: _planExpiresAt, hint: 'YYYY-MM-DD'),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.t('trialEnds'), style: AppTextStyles.caption.copyWith(color: muted, fontWeight: FontWeight.w500)),
                            const SizedBox(height: AppSpacing.xs),
                            AppTextField(controller: _trialEndsAt, hint: 'YYYY-MM-DD'),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(child: AppTextField(controller: _maxUsers,    label: l10n.t('maxUsers'),    keyboardType: TextInputType.number)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(controller: _maxBranches, label: l10n.t('maxBranches'), keyboardType: TextInputType.number)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(controller: _maxProducts, label: l10n.t('maxProducts'), keyboardType: TextInputType.number)),
                    ]),

                    const SizedBox(height: AppSpacing.xl),
                    // ── 4. Features ──────────────────────────────────────
                    _SectionTitle(title: '4. ${l10n.t("featuresAndNotes")}', borderColor: borderColor),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: (apiFeatures.isNotEmpty
                          ? apiFeatures.map((f) => (f.key, Icons.extension_rounded, f.name)).toList()
                          : _kFeatures.map((f) => (f.$1, f.$2, l10n.t('feature_${f.$1}'))).toList()
                      ).map((rec) {
                        final key = rec.$1;
                        final icon = rec.$2;
                        final label = rec.$3;
                        final checked = _features.contains(key);
                        return _FeatureChip(
                          featureKey: key, icon: icon, checked: checked, label: label,
                          onToggle: () => setState(() {
                            if (checked) { _features.remove(key); } else { _features.add(key); }
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.md),
                    // ── 5. Notes ─────────────────────────────────────────
                    Text(l10n.t('adminNotes'), style: AppTextStyles.labelMd.copyWith(color: fg)),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(controller: _notes, hint: l10n.t('adminNotesHint'), maxLines: 3),

                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(label: l10n.cancel, onPressed: () => Navigator.of(context).pop(), variant: AppButtonVariant.ghost),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton(label: l10n.save, onPressed: _saving ? null : _save, isLoading: _saving),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── feature chip ──────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final String featureKey;
  final IconData icon;
  final bool checked;
  final String label;
  final VoidCallback onToggle;

  const _FeatureChip({
    required this.featureKey,
    required this.icon,
    required this.checked,
    required this.label,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final border = checked ? cs.primary : (isDark ? AppColors.darkBorder : AppColors.border);
    final bg = checked ? cs.primary.withValues(alpha: 0.06) : Colors.transparent;
    final textColor = isDark ? AppColors.darkForeground : AppColors.foreground;

    return InkWell(
      onTap: onToggle,
      borderRadius: AppRadius.brMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brMd, border: Border.all(color: border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16, height: 16,
              child: Checkbox(
                value: checked,
                onChanged: (_) => onToggle(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                activeColor: cs.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.labelSm.copyWith(color: checked ? cs.primary : textColor, fontWeight: checked ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
