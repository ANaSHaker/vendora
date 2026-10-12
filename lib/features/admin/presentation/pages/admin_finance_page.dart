import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../domain/entities/admin_finance_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import '../cubit/admin_finance_cubit.dart';
import '../cubit/admin_finance_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso.length > 10 ? iso.substring(0, 10) : iso;
  }
}

String _fmtMoney(double n) => AppFormatters.currency(n);

String _fmtMonth(String key) {
  try {
    final parts = key.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[dt.month - 1]} '${dt.year.toString().substring(2)}";
  } catch (_) {
    return key;
  }
}

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.transparent;
  try {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {
    return Colors.transparent;
  }
}

// ── Page Entry ────────────────────────────────────────────────────────────────

class AdminFinancePage extends StatelessWidget {
  const AdminFinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFinanceCubit(
        getSummary: getIt<GetAdminFinanceSummaryUseCase>(),
        getEntries: getIt<GetAdminFinanceEntriesUseCase>(),
        createEntry: getIt<CreateAdminFinanceEntryUseCase>(),
        updateEntry: getIt<UpdateAdminFinanceEntryUseCase>(),
        voidEntry: getIt<VoidAdminFinanceEntryUseCase>(),
        getCategories: getIt<GetAdminFinanceCategoriesUseCase>(),
        createCategory: getIt<CreateAdminFinanceCategoryUseCase>(),
        updateCategory: getIt<UpdateAdminFinanceCategoryUseCase>(),
      )..load(),
      child: const _FinanceContent(),
    );
  }
}

// ── Main Content ──────────────────────────────────────────────────────────────

class _FinanceContent extends StatefulWidget {
  const _FinanceContent();

  @override
  State<_FinanceContent> createState() => _FinanceContentState();
}

class _FinanceContentState extends State<_FinanceContent> {
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
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return BlocConsumer<AdminFinanceCubit, AdminFinanceState>(
      listener: (context, state) {
        if (state is AdminFinanceLoaded) {
          if (state.saveSuccess) {
            AppSnackbar.show(context, message: l10n.adminFinanceSaveSuccess, type: SnackbarType.success);
            context.read<AdminFinanceCubit>().clearSaveStatus();
          }
          if (state.saveError != null) {
            AppSnackbar.show(context, message: state.saveError!, type: SnackbarType.error);
            context.read<AdminFinanceCubit>().clearSaveStatus();
          }
        }
      },
      builder: (context, state) {
        if (state is AdminFinanceLoading || state is AdminFinanceInitial) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is AdminFinanceError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: AppErrorWidget(
                message: state.message,
                onRetry: () => context.read<AdminFinanceCubit>().load(),
              ),
            ),
          );
        }

        final s = state as AdminFinanceLoaded;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.adminFinanceTitle,
                              style: AppTextStyles.h2),
                          const SizedBox(height: 4),
                          Text(l10n.adminFinanceSubtitle,
                              style: AppTextStyles.bodySm.copyWith(color: muted)),
                        ],
                      ),
                    ),
                    if (s.tab != 'categories') ...[
                      _PrimaryButton(
                        label: l10n.adminFinanceAddRevenue,
                        onTap: () => _openEntryModal(context, null, defaultType: 'revenue'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _GhostButton(
                        label: l10n.adminFinanceAddExpense,
                        borderColor: borderColor,
                        onTap: () => _openEntryModal(context, null, defaultType: 'expense'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Summary cards
                _SummaryCards(summary: s.summary, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // Monthly trend
                if (s.summary.monthly.isNotEmpty) ...[
                  _MonthlyTrendChart(monthly: s.summary.monthly, isDark: isDark, l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Filters row
                _FiltersRow(
                  s: s,
                  isDark: isDark,
                  searchCtrl: _searchCtrl,
                  l10n: l10n,
                  onChanged: (from, to, cat, status, search) {
                    context.read<AdminFinanceCubit>().applyFilters(
                      dateFrom: from,
                      dateTo: to,
                      categoryFilter: cat,
                      statusFilter: status,
                      search: search,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Tabs
                _TabsBar(
                  tab: s.tab,
                  isDark: isDark,
                  l10n: l10n,
                  onTabChanged: (t) => context.read<AdminFinanceCubit>().setTab(t),
                ),
                const SizedBox(height: AppSpacing.md),

                // Content
                Expanded(
                  child: s.tab == 'categories'
                      ? _CategoriesTabContent(
                          categories: s.categories,
                          isDark: isDark,
                          l10n: l10n,
                          onEdit: (cat) => _openCategoryModal(context, cat),
                          onAdd: () => _openCategoryModal(context, null),
                        )
                      : _EntriesTabContent(
                          entries: s.entries.data,
                          tab: s.tab,
                          isDark: isDark,
                          l10n: l10n,
                          onEdit: (e) => _openEntryModal(context, e),
                          onVoid: (id) async {
                            final ok = await context.read<AdminFinanceCubit>().voidEntry(id);
                            if (!ok && context.mounted) {
                              AppSnackbar.show(context, message: l10n.adminFinanceVoidFailed, type: SnackbarType.error);
                            } else if (ok && context.mounted) {
                              AppSnackbar.show(context, message: l10n.adminFinanceVoidSuccess, type: SnackbarType.success);
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEntryModal(BuildContext context, AdminFinanceEntryEntity? entry, {String defaultType = 'revenue'}) {
    final state = context.read<AdminFinanceCubit>().state;
    if (state is! AdminFinanceLoaded) return;
    showDialog(
      context: context,
      builder: (_) => _EntryModal(
        entry: entry,
        defaultType: defaultType,
        categories: state.categories,
        vendors: state.entries.data.map((e) => e.vendor).whereType<AdminFinanceVendorRefEntity>().toSet().toList(),
        onSave: (data) async {
          final ok = await context.read<AdminFinanceCubit>().saveEntry(
            id: entry?.id,
            data: data,
          );
          return ok;
        },
      ),
    );
  }

  void _openCategoryModal(BuildContext context, AdminFinanceCategoryEntity? cat) {
    showDialog(
      context: context,
      builder: (_) => _CategoryModal(
        category: cat,
        onSave: (data) async {
          final ok = await context.read<AdminFinanceCubit>().saveCategory(
            id: cat?.id,
            data: data,
          );
          return ok;
        },
      ),
    );
  }
}

// ── Summary Cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final AdminFinanceSummaryEntity summary;
  final bool isDark;
  const _SummaryCards({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = isDark ? AppColors.primary : AppColors.primary;

    final netColor = summary.netProfit >= 0 ? primary : AppColors.destructive;

    final cards = [
      (l10n.adminFinanceSummaryRevenue, _fmtMoney(summary.revenueTotal), Icons.trending_up_rounded, primary),
      (l10n.adminFinanceSummaryExpense, _fmtMoney(summary.expenseTotal), Icons.trending_down_rounded, AppColors.destructive),
      (l10n.adminFinanceSummaryNet, _fmtMoney(summary.netProfit), Icons.attach_money_rounded, netColor),
      (l10n.adminFinanceSummaryPending, _fmtMoney(summary.pendingRevenue), Icons.hourglass_empty_rounded, muted),
    ];

    return Row(
      children: cards.map((c) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(c.$3, size: 18, color: c.$4),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.$1, style: AppTextStyles.bodyXs.copyWith(color: muted)),
                      const SizedBox(height: 2),
                      Text(c.$2,
                          style: AppTextStyles.h3.copyWith(color: c.$4),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Monthly Trend ─────────────────────────────────────────────────────────────

class _MonthlyTrendChart extends StatelessWidget {
  final List<AdminFinanceMonthlyStat> monthly;
  final bool isDark;
  final AppLocalizations l10n;
  const _MonthlyTrendChart({required this.monthly, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final maxVal = monthly.fold(0.0, (m, s) => [m, s.revenue, s.expense].reduce((a, b) => a > b ? a : b));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.adminFinanceMonthlyTrend,
                    style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
              ),
              _Legend(color: primary, label: l10n.adminFinanceTabRevenue, isDark: isDark),
              const SizedBox(width: AppSpacing.md),
              _Legend(color: AppColors.destructive, label: l10n.adminFinanceTabExpense, isDark: isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthly.map((m) {
                final revH = maxVal > 0 ? (m.revenue / maxVal) * 100 : 0.0;
                final expH = maxVal > 0 ? (m.expense / maxVal) * 100 : 0.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 8,
                            height: revH.clamp(2.0, 100.0),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 8,
                            height: expH.clamp(2.0, 100.0),
                            decoration: BoxDecoration(
                              color: AppColors.destructive,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtMonth(m.month),
                        style: TextStyle(fontSize: 9, color: muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  const _Legend({required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodyXs),
      ],
    );
  }
}

// ── Filters Row ───────────────────────────────────────────────────────────────

class _FiltersRow extends StatefulWidget {
  final AdminFinanceLoaded s;
  final bool isDark;
  final TextEditingController searchCtrl;
  final AppLocalizations l10n;
  final void Function(String, String, String, String, String) onChanged;

  const _FiltersRow({
    required this.s,
    required this.isDark,
    required this.searchCtrl,
    required this.l10n,
    required this.onChanged,
  });

  @override
  State<_FiltersRow> createState() => _FiltersRowState();
}

class _FiltersRowState extends State<_FiltersRow> {
  late String _from;
  late String _to;
  late String _cat;
  late String _status;

  @override
  void initState() {
    super.initState();
    _from = widget.s.dateFrom;
    _to = widget.s.dateTo;
    _cat = widget.s.categoryFilter;
    _status = widget.s.statusFilter;
    widget.searchCtrl.text = widget.s.search;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = widget.isDark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cats = widget.s.categories
        .where((c) => widget.s.tab == 'all' || c.type == widget.s.tab)
        .toList();

    InputDecoration _dec(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: muted, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: borderColor),
          ),
          filled: true,
          fillColor: bg,
        );

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: TextFormField(
            style: const TextStyle(fontSize: 13),
            decoration: _dec(l10n.adminFinanceDateLabel).copyWith(hintText: 'From date'),
            initialValue: _from,
            onChanged: (v) {
              _from = v;
              widget.onChanged(_from, _to, _cat, _status, widget.searchCtrl.text);
            },
          ),
        ),
        SizedBox(
          width: 150,
          child: TextFormField(
            style: const TextStyle(fontSize: 13),
            decoration: _dec('To date'),
            initialValue: _to,
            onChanged: (v) {
              _to = v;
              widget.onChanged(_from, _to, _cat, _status, widget.searchCtrl.text);
            },
          ),
        ),
        if (widget.s.tab != 'categories') ...[
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              value: _cat.isNotEmpty ? _cat : null,
              isExpanded: true,
              decoration: _dec(l10n.adminFinanceAllCategories),
              style: const TextStyle(fontSize: 13),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.adminFinanceAllCategories, overflow: TextOverflow.ellipsis)),
                ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) {
                _cat = v ?? '';
                setState(() {});
                widget.onChanged(_from, _to, _cat, _status, widget.searchCtrl.text);
              },
            ),
          ),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: _status.isNotEmpty ? _status : null,
              isExpanded: true,
              decoration: _dec(l10n.adminFinanceAllStatuses),
              style: const TextStyle(fontSize: 13),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.adminFinanceAllStatuses, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'confirmed', child: Text(l10n.adminFinanceStatusConfirmed, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'pending', child: Text(l10n.adminFinanceStatusPending, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'void', child: Text(l10n.adminFinanceStatusVoid, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) {
                _status = v ?? '';
                setState(() {});
                widget.onChanged(_from, _to, _cat, _status, widget.searchCtrl.text);
              },
            ),
          ),
          SizedBox(
            width: 220,
            child: TextFormField(
              controller: widget.searchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: _dec(l10n.adminFinanceSearchPlaceholder),
              onChanged: (v) => widget.onChanged(_from, _to, _cat, _status, v),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Tabs Bar ──────────────────────────────────────────────────────────────────

class _TabsBar extends StatelessWidget {
  final String tab;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(String) onTabChanged;

  const _TabsBar({
    required this.tab,
    required this.isDark,
    required this.l10n,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final tabs = [
      ('all', l10n.adminFinanceTabAll, Icons.format_list_bulleted_rounded),
      ('revenue', l10n.adminFinanceTabRevenue, Icons.trending_up_rounded),
      ('expense', l10n.adminFinanceTabExpense, Icons.trending_down_rounded),
      ('categories', l10n.adminFinanceTabCategories, Icons.category_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.4))),
      ),
      child: Row(
        children: tabs.map((t) {
          final active = tab == t.$1;
          return InkWell(
            onTap: () => onTabChanged(t.$1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(t.$3, size: 14, color: active ? primary : muted),
                  const SizedBox(width: 6),
                  Text(
                    t.$2,
                    style: AppTextStyles.bodySm.copyWith(
                      color: active ? (isDark ? AppColors.darkForeground : AppColors.foreground) : muted,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Entries Tab ───────────────────────────────────────────────────────────────

class _EntriesTabContent extends StatelessWidget {
  final List<AdminFinanceEntryEntity> entries;
  final String tab;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(AdminFinanceEntryEntity) onEdit;
  final void Function(String) onVoid;

  const _EntriesTabContent({
    required this.entries,
    required this.tab,
    required this.isDark,
    required this.l10n,
    required this.onEdit,
    required this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.muted;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final showType = tab == 'all';

    if (entries.isEmpty) {
      return AppEmptyState(message: l10n.adminFinanceNoEntries, icon: const Icon(Icons.attach_money_rounded));
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: SingleChildScrollView(
        child: Table(
          columnWidths: {
            0: const FlexColumnWidth(3),
            1: const FlexColumnWidth(2),
            if (showType) 2: const FlexColumnWidth(1.5),
            showType ? 3 : 2: const FlexColumnWidth(1.5),
            showType ? 4 : 3: const FlexColumnWidth(1.5),
            showType ? 5 : 4: const FlexColumnWidth(1.5),
            showType ? 6 : 5: const FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              ),
              children: [
                _TH(l10n.adminFinanceTitleLabel, muted: muted),
                _TH(l10n.adminFinanceCategoryLabel, muted: muted),
                if (showType) _TH(l10n.adminFinanceTypeLabel, muted: muted),
                _TH(l10n.adminFinanceAmountLabel, muted: muted),
                _TH(l10n.adminFinanceDateLabel, muted: muted),
                _TH(l10n.adminFinanceStatusLabel, muted: muted),
                _TH(l10n.actions, muted: muted, align: TextAlign.end),
              ],
            ),
            ...entries.map((e) => _entryRow(e, showType, isDark, muted, borderColor)),
          ],
        ),
      ),
    );
  }

  TableRow _entryRow(
    AdminFinanceEntryEntity e,
    bool showType,
    bool isDark,
    Color muted,
    Color borderColor,
  ) {
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final amtColor = e.type == 'expense' ? AppColors.destructive : primary;
    final amtPrefix = e.type == 'expense' ? '−' : '+';
    final isVoided = e.status == 'void';
    final voidDisabled = e.isLocked || isVoided;

    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.4))),
      ),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500)),
                if (e.vendor != null)
                  Text(e.vendor!.name,
                      style: AppTextStyles.bodyXs.copyWith(color: muted)),
              ],
            ),
          ),
        ),
        _TC(e.category?.name ?? '—', muted: muted, isDark: isDark),
        if (showType) TableCell(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _TypeBadge(type: e.type, isDark: isDark, l10n: l10n),
        )),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '$amtPrefix${_fmtMoney(e.amount)}',
              style: AppTextStyles.bodySm.copyWith(
                color: amtColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _TC(_fmtDate(e.entryDate), muted: muted, isDark: isDark),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _StatusBadge(status: e.status, isDark: isDark, l10n: l10n),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionBtn(
                  label: l10n.edit,
                  icon: Icons.edit_rounded,
                  onTap: () => onEdit(e),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                if (!isVoided)
                  _ActionBtn(
                    label: l10n.adminFinanceVoid,
                    icon: Icons.block_rounded,
                    onTap: voidDisabled ? null : () => onVoid(e.id),
                    isDark: isDark,
                    destructive: true,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Categories Tab ────────────────────────────────────────────────────────────

class _CategoriesTabContent extends StatelessWidget {
  final List<AdminFinanceCategoryEntity> categories;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(AdminFinanceCategoryEntity) onEdit;
  final VoidCallback onAdd;

  const _CategoriesTabContent({
    required this.categories,
    required this.isDark,
    required this.l10n,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.muted;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = isDark ? AppColors.primary : AppColors.primary;

    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(l10n.adminFinanceAddCategory),
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (categories.isEmpty)
          Expanded(child: AppEmptyState(message: l10n.adminFinanceNoCategories, icon: const Icon(Icons.category_rounded)))
        else
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(3),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: headerBg),
                      children: [
                        _TH(l10n.adminFinanceCategoryName, muted: muted),
                        _TH(l10n.adminFinanceTypeLabel, muted: muted),
                        _TH(l10n.adminFinanceDescriptionLabel, muted: muted),
                        _TH(l10n.adminFinanceStatusLabel, muted: muted),
                        _TH(l10n.actions, muted: muted, align: TextAlign.end),
                      ],
                    ),
                    ...categories.map((c) {
                      final catColor = _parseColor(c.color);
                      return TableRow(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.4))),
                        ),
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  if (c.color != null && c.color!.isNotEmpty) ...[
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: catColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(c.name,
                                        style: AppTextStyles.bodySm
                                            .copyWith(fontWeight: FontWeight.w500)),
                                  ),
                                  if (c.isSystem)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: borderColor),
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Text(l10n.adminFinanceSystemBadge,
                                          style: TextStyle(fontSize: 9, color: muted)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: _TypeBadge(type: c.type, isDark: isDark, l10n: l10n),
                            ),
                          ),
                          _TC(c.description ?? '—', muted: muted, isDark: isDark),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: _ActiveBadge(isActive: c.isActive, isDark: isDark, l10n: l10n),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: _ActionBtn(
                                  label: l10n.edit,
                                  icon: Icons.edit_rounded,
                                  onTap: () => onEdit(c),
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Entry Modal ───────────────────────────────────────────────────────────────

class _EntryModal extends StatefulWidget {
  final AdminFinanceEntryEntity? entry;
  final String defaultType;
  final List<AdminFinanceCategoryEntity> categories;
  final List<AdminFinanceVendorRefEntity> vendors;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  const _EntryModal({
    required this.entry,
    required this.defaultType,
    required this.categories,
    required this.vendors,
    required this.onSave,
  });

  @override
  State<_EntryModal> createState() => _EntryModalState();
}

class _EntryModalState extends State<_EntryModal> {
  late String _type;
  late String _categoryId;
  late String _amount;
  late String _title;
  late String _description;
  late String _entryDate;
  late String _status;
  late String _vendorId;
  late String _reference;
  late String _paymentMethod;
  late String _recurring;
  late String _notes;
  bool _saving = false;
  String? _error;

  bool get _locked => widget.entry?.isLocked ?? false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _type = e?.type ?? widget.defaultType;
    _categoryId = e?.category?.id ?? '';
    _amount = e != null ? e.amount.toStringAsFixed(2) : '';
    _title = e?.title ?? '';
    _description = e?.description ?? '';
    _entryDate = e?.entryDate ?? DateTime.now().toIso8601String().substring(0, 10);
    _status = (e?.status == 'void') ? 'confirmed' : (e?.status ?? 'confirmed');
    _vendorId = e?.vendor?.id ?? '';
    _reference = e?.reference ?? '';
    _paymentMethod = e?.paymentMethod ?? '';
    _recurring = e?.recurring ?? 'none';
    _notes = e?.notes ?? '';
  }

  List<AdminFinanceCategoryEntity> get _filteredCats =>
      widget.categories.where((c) => c.isActive && c.type == _type).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final isEditing = widget.entry != null;

    final paymentMethods = [
      ('', '—'),
      ('cash', l10n.adminFinancePaymentCash),
      ('card', l10n.adminFinancePaymentCard),
      ('bank_transfer', l10n.adminFinancePaymentBankTransfer),
      ('online', l10n.adminFinancePaymentOnline),
      ('stripe', l10n.adminFinancePaymentStripe),
      ('other', l10n.adminFinancePaymentOther),
    ];
    final recurringOpts = [
      ('none', l10n.adminFinanceRecurringNone),
      ('monthly', l10n.adminFinanceRecurringMonthly),
      ('yearly', l10n.adminFinanceRecurringYearly),
    ];

    final canSave = !_locked &&
        _categoryId.isNotEmpty &&
        _title.trim().isNotEmpty &&
        _amount.isNotEmpty &&
        (double.tryParse(_amount) ?? 0) > 0;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? l10n.adminFinanceEditEntry : l10n.adminFinanceCreateEntry,
                      style: AppTextStyles.h3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: borderColor, height: 1),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(_error!, style: TextStyle(color: AppColors.destructive, fontSize: 13)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_locked) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkMuted : AppColors.muted,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 14, color: muted),
                            const SizedBox(width: 8),
                            Expanded(child: Text(l10n.adminFinanceBillingLocked,
                                style: TextStyle(fontSize: 13, color: muted))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!isEditing) ...[
                      _FieldLabel(l10n.adminFinanceTypeLabel, isDark: isDark),
                      _Dropdown(
                        value: _type,
                        enabled: !_locked,
                        items: [
                          ('revenue', l10n.adminFinanceTabRevenue),
                          ('expense', l10n.adminFinanceTabExpense),
                        ],
                        isDark: isDark,
                        onChanged: (v) => setState(() { _type = v; _categoryId = ''; }),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _FieldLabel(l10n.adminFinanceCategoryLabel, isDark: isDark),
                    _Dropdown(
                      value: _categoryId.isNotEmpty ? _categoryId : null,
                      enabled: !_locked,
                      hint: l10n.adminFinanceSelectCategory,
                      items: _filteredCats.map((c) => (c.id, c.name)).toList(),
                      isDark: isDark,
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.adminFinanceAmountLabel, isDark: isDark),
                              _TextField(
                                value: _amount,
                                enabled: !_locked,
                                keyboardType: TextInputType.number,
                                hint: '0.00',
                                isDark: isDark,
                                onChanged: (v) => _amount = v,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.adminFinanceDateLabel, isDark: isDark),
                              _TextField(
                                value: _entryDate,
                                enabled: !_locked,
                                hint: 'YYYY-MM-DD',
                                isDark: isDark,
                                onChanged: (v) => _entryDate = v,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _FieldLabel(l10n.adminFinanceTitleLabel, isDark: isDark),
                    _TextField(
                      value: _title,
                      enabled: !_locked,
                      isDark: isDark,
                      onChanged: (v) => _title = v,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.adminFinanceStatusLabel, isDark: isDark),
                              _Dropdown(
                                value: _status,
                                enabled: !_locked && widget.entry?.status != 'void',
                                items: [
                                  ('confirmed', l10n.adminFinanceStatusConfirmed),
                                  ('pending', l10n.adminFinanceStatusPending),
                                ],
                                isDark: isDark,
                                onChanged: (v) => setState(() => _status = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.adminFinancePaymentMethodLabel, isDark: isDark),
                              _Dropdown(
                                value: _paymentMethod.isNotEmpty ? _paymentMethod : null,
                                enabled: !_locked,
                                hint: '—',
                                items: paymentMethods,
                                isDark: isDark,
                                onChanged: (v) => setState(() => _paymentMethod = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _FieldLabel('${l10n.adminFinanceVendorLabel} (${l10n.optional})', isDark: isDark),
                    _Dropdown(
                      value: _vendorId.isNotEmpty ? _vendorId : null,
                      enabled: !_locked,
                      hint: l10n.adminFinanceSelectVendor,
                      items: widget.vendors.map((v) => (v.id, v.name)).toList(),
                      isDark: isDark,
                      onChanged: (v) => setState(() => _vendorId = v),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.adminFinanceReferenceLabel, isDark: isDark),
                              _TextField(
                                value: _reference,
                                enabled: !_locked,
                                isDark: isDark,
                                onChanged: (v) => _reference = v,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.adminFinanceRecurringLabel, isDark: isDark),
                              _Dropdown(
                                value: _recurring,
                                enabled: !_locked,
                                items: recurringOpts,
                                isDark: isDark,
                                onChanged: (v) => setState(() => _recurring = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _FieldLabel(l10n.adminFinanceDescriptionLabel, isDark: isDark),
                    _TextField(
                      value: _description,
                      enabled: !_locked,
                      maxLines: 2,
                      isDark: isDark,
                      onChanged: (v) => _description = v,
                    ),
                    const SizedBox(height: 12),

                    _FieldLabel(l10n.adminFinanceNotesLabel, isDark: isDark),
                    _TextField(
                      value: _notes,
                      enabled: !_locked,
                      maxLines: 2,
                      isDark: isDark,
                      onChanged: (v) => _notes = v,
                    ),
                  ],
                ),
              ),
            ),

            Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel, style: TextStyle(color: muted)),
                  ),
                  const SizedBox(width: 8),
                  if (!_locked)
                    ElevatedButton(
                      onPressed: (!canSave || _saving) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l10n.save),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() { _saving = true; _error = null; });
    final data = {
      'type': _type,
      'category_id': _categoryId,
      'amount': double.tryParse(_amount) ?? 0,
      'title': _title.trim(),
      if (_description.trim().isNotEmpty) 'description': _description.trim(),
      'entry_date': _entryDate,
      'status': _status,
      if (_vendorId.isNotEmpty) 'vendor_id': _vendorId,
      if (_reference.trim().isNotEmpty) 'reference': _reference.trim(),
      if (_paymentMethod.isNotEmpty) 'payment_method': _paymentMethod,
      'recurring': _recurring,
      if (_notes.trim().isNotEmpty) 'notes': _notes.trim(),
    };
    final ok = await widget.onSave(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }
}

// ── Category Modal ────────────────────────────────────────────────────────────

class _CategoryModal extends StatefulWidget {
  final AdminFinanceCategoryEntity? category;
  final Future<bool> Function(Map<String, dynamic>) onSave;
  const _CategoryModal({required this.category, required this.onSave});

  @override
  State<_CategoryModal> createState() => _CategoryModalState();
}

class _CategoryModalState extends State<_CategoryModal> {
  late String _type;
  late String _name;
  late String _description;
  late String _color;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _type = c?.type ?? 'revenue';
    _name = c?.name ?? '';
    _description = c?.description ?? '';
    _color = c?.color ?? '';
    _isActive = c?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final isEditing = widget.category != null;
    final isSystem = widget.category?.isSystem ?? false;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? l10n.adminFinanceEditCategory : l10n.adminFinanceCreateCategory,
                      style: AppTextStyles.h3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: borderColor, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(_error!, style: TextStyle(color: AppColors.destructive, fontSize: 13)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!isEditing) ...[
                      _FieldLabel(l10n.adminFinanceTypeLabel, isDark: isDark),
                      _Dropdown(
                        value: _type,
                        items: [
                          ('revenue', l10n.adminFinanceTabRevenue),
                          ('expense', l10n.adminFinanceTabExpense),
                        ],
                        isDark: isDark,
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _FieldLabel(l10n.adminFinanceCategoryName, isDark: isDark),
                    _TextField(
                      value: _name,
                      enabled: !isSystem,
                      isDark: isDark,
                      onChanged: (v) => _name = v,
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel(l10n.adminFinanceDescriptionLabel, isDark: isDark),
                    _TextField(
                      value: _description,
                      maxLines: 2,
                      isDark: isDark,
                      onChanged: (v) => _description = v,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.adminFinanceColorLabel, isDark: isDark),
                              _TextField(
                                value: _color,
                                hint: '#3b82f6',
                                isDark: isDark,
                                onChanged: (v) => _color = v,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _isActive,
                                onChanged: (v) => setState(() => _isActive = v ?? true),
                                activeColor: primary,
                              ),
                              Text(l10n.active, style: AppTextStyles.bodySm),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel, style: TextStyle(color: muted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_name.trim().isEmpty || _saving) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l10n.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() { _saving = true; _error = null; });
    final payload = widget.category != null
        ? {
            'name': _name.trim(),
            if (_description.trim().isNotEmpty) 'description': _description.trim(),
            if (_color.trim().isNotEmpty) 'color': _color.trim(),
            'is_active': _isActive,
          }
        : {
            'type': _type,
            'name': _name.trim(),
            if (_description.trim().isNotEmpty) 'description': _description.trim(),
            if (_color.trim().isNotEmpty) 'color': _color.trim(),
            'is_active': _isActive,
          };
    final ok = await widget.onSave(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }
}

// ── Shared UI Helpers ─────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final Color muted;
  final TextAlign align;
  const _TH(this.text, {required this.muted, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted, letterSpacing: 0.5),
            textAlign: align,
          ),
        ),
      );
}

class _TC extends StatelessWidget {
  final String text;
  final Color muted;
  final bool isDark;
  const _TC(this.text, {required this.muted, required this.isDark});

  @override
  Widget build(BuildContext context) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(text,
              style: AppTextStyles.bodySm.copyWith(color: muted),
              overflow: TextOverflow.ellipsis),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;
  final AppLocalizations l10n;
  const _StatusBadge({required this.status, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    Color bg; Color fg; String label;
    switch (status) {
      case 'confirmed':
        bg = primary.withOpacity(0.1); fg = primary;
        label = l10n.adminFinanceStatusConfirmed;
      case 'pending':
        bg = (isDark ? AppColors.darkMuted : AppColors.muted); fg = primary;
        label = l10n.adminFinanceStatusPending;
      default:
        bg = (isDark ? AppColors.darkMuted : AppColors.muted); fg = muted;
        label = l10n.adminFinanceStatusVoid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final bool isDark;
  final AppLocalizations l10n;
  const _TypeBadge({required this.type, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final isRevenue = type == 'revenue';
    final color = isRevenue ? primary : AppColors.destructive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isRevenue ? l10n.adminFinanceTabRevenue : l10n.adminFinanceTabExpense,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final bool isActive;
  final bool isDark;
  final AppLocalizations l10n;
  const _ActiveBadge({required this.isActive, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? primary.withOpacity(0.1) : (isDark ? AppColors.darkMuted : AppColors.muted),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? l10n.active : l10n.inactive,
        style: TextStyle(fontSize: 11, color: isActive ? primary : muted, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final bool destructive;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final color = destructive ? AppColors.destructive : (isDark ? AppColors.darkForeground : AppColors.foreground);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: destructive ? AppColors.destructive.withOpacity(0.4) : borderColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    return ElevatedButton.icon(
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(label),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final Color borderColor;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.borderColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    return OutlinedButton.icon(
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(label),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500)),
      );
}

class _TextField extends StatelessWidget {
  final String value;
  final bool enabled;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool isDark;
  final void Function(String) onChanged;

  const _TextField({
    required this.value,
    this.enabled = true,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return TextFormField(
      initialValue: value,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: muted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        filled: true,
        fillColor: bg,
      ),
      onChanged: onChanged,
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String? value;
  final bool enabled;
  final String? hint;
  final List<(String, String)> items;
  final bool isDark;
  final void Function(String) onChanged;

  const _Dropdown({
    required this.value,
    this.enabled = true,
    this.hint,
    required this.items,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: muted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        filled: true,
        fillColor: bg,
      ),
      items: items.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
      onChanged: enabled ? (v) => onChanged(v ?? '') : null,
    );
  }
}
