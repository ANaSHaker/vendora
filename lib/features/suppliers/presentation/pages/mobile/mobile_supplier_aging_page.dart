import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/file_saver.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../domain/entities/aging_entities.dart';
import '../../../domain/usecases/aging_usecases.dart';
import '../../../domain/usecases/suppliers_usecases.dart';
import '../../cubit/aging_cubit.dart';

class MobileSupplierAgingPage extends StatefulWidget {
  const MobileSupplierAgingPage({super.key});

  @override
  State<MobileSupplierAgingPage> createState() => _MobileSupplierAgingPageState();
}

class _MobileSupplierAgingPageState extends State<MobileSupplierAgingPage> {
  late final AgingCubit _cubit;
  final _asOfCtrl = TextEditingController();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _cubit = AgingCubit(
      getAging: getIt<GetSupplierAgingUseCase>(),
      exportAging: getIt<ExportSupplierAgingUseCase>(),
      getSuppliers: getIt<GetSuppliersUseCase>(),
    )..init();
  }

  @override
  void dispose() {
    _cubit.close();
    _asOfCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAsOf() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null && mounted) {
      _asOfCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _cubit.setAsOf(_asOfCtrl.text.trim());
    }
  }

  Future<void> _doExport() async {
    setState(() => _exporting = true);
    try {
      final bytes = await _cubit.exportAging();
      if (!mounted) return;
      setState(() => _exporting = false);
      if (bytes != null && bytes.isNotEmpty) {
        final ts = DateTime.now();
        final name =
            'suppliers_aging_${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}.xlsx';
        final path = await saveExportFile(bytes, name);
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        if (path != null) {
          AppSnackbar.success(context, path);
        } else {
          AppSnackbar.error(context, l10n.error);
        }
      } else {
        AppSnackbar.error(context, AppLocalizations.of(context).error);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      AppSnackbar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<AgingCubit, AgingState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg      = isDark ? AppColors.darkBackground : AppColors.background;
          final surface = isDark ? AppColors.darkSurface    : AppColors.surface;
          final border  = isDark ? AppColors.darkBorder     : AppColors.border;
          final fg      = isDark ? AppColors.darkForeground  : AppColors.foreground;
          final muted   = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

          final supplierList = switch (state) {
            AgingInitial(:final supplierList) => supplierList,
            AgingLoading(:final supplierList) => supplierList,
            AgingLoaded(:final supplierList)  => supplierList,
            AgingError(:final supplierList)   => supplierList,
          };

          final currentSupplierId =
              state is AgingLoaded ? state.supplierId : null;

          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              title: Text(l10n.supplierAgingTitle,
                  style: AppTextStyles.h6.copyWith(color: fg)),
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: l10n.supplierAgingExport,
                  icon: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  onPressed: _exporting ? null : _doExport,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: border),
              ),
            ),
            body: Column(
              children: [
                // Filters
                Container(
                  color: surface,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      // As Of date
                      InkWell(
                        onTap: _pickAsOf,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _asOfCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: l10n.supplierAgingAsOf,
                              hintStyle:
                                  TextStyle(color: muted, fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(color: border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(color: border),
                              ),
                              filled: true,
                              fillColor: bg,
                              suffixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: muted),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Supplier filter
                      AppSelectField<String>(
                        value: currentSupplierId ?? '',
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('all_suppliers')),
                          ...supplierList.map(
                            (s) => AppSelectOption(
                                value: s.id, label: s.name),
                          ),
                        ],
                        onChanged: (v) => _cubit.setSupplier(
                            (v == null || v.isEmpty) ? null : v),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.supplierAgingNote,
                        style: AppTextStyles.bodyXs.copyWith(
                          color: muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: border),

                // Body
                Expanded(
                  child: switch (state) {
                    AgingInitial() || AgingLoading() => ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: 6,
                        itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ShimmerBox(height: 80),
                        ),
                      ),
                    AgingError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: _cubit.init,
                      ),
                    AgingLoaded(:final rows) when rows.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.access_time_outlined, size: 40),
                        message: l10n.supplierAgingNoData,
                      ),
                    AgingLoaded(:final rows, :final totals) =>
                      RefreshIndicator(
                        onRefresh: () async => _cubit.init(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: rows.length + 1, // +1 for totals card
                          itemBuilder: (context, i) {
                            if (i == rows.length) {
                              // Totals card
                              return _AgingTotalsCard(
                                totals: totals,
                                l10n: l10n,
                                isDark: isDark,
                                fg: fg,
                                muted: muted,
                                border: border,
                                surface: surface,
                              );
                            }
                            final r = rows[i];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _AgingRowCard(
                                row: r,
                                l10n: l10n,
                                isDark: isDark,
                                fg: fg,
                                muted: muted,
                                border: border,
                                surface: surface,
                              ),
                            );
                          },
                        ),
                      ),
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Mobile Cards ──────────────────────────────────────────────────────────────

class _AgingRowCard extends StatelessWidget {
  final AgingRowEntity row;
  final AppLocalizations l10n;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color border;
  final Color surface;

  const _AgingRowCard({
    required this.row,
    required this.l10n,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.border,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.supplierName,
                style: AppTextStyles.labelSm.copyWith(color: fg)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _bucket(l10n.supplierAgingColCurrent, row.current, fg),
                _bucket(l10n.supplierAgingCol1_30, row.bucket1to30, fg),
                _bucket(l10n.supplierAgingCol31_60, row.bucket31to60, fg),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _bucket(l10n.supplierAgingCol61_90, row.bucket61to90,
                    AppColors.primary),
                _bucket(l10n.supplierAgingColOver90, row.over90,
                    AppColors.destructive),
                _bucket(l10n.supplierAgingColTotal, row.totalBalance,
                    AppColors.primary,
                    bold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bucket(String label, double val, Color color,
      {bool bold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodyXs.copyWith(color: muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            val > 0 ? AppFormatters.currency(val) : '—',
            style: AppTextStyles.numeric.copyWith(
              color: val > 0 ? color : muted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgingTotalsCard extends StatelessWidget {
  final AgingTotals totals;
  final AppLocalizations l10n;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color border;
  final Color surface;

  const _AgingTotalsCard({
    required this.totals,
    required this.l10n,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.border,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: headerBg,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('total'),
                style: AppTextStyles.labelSm
                    .copyWith(color: fg, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _bucket(l10n.supplierAgingColCurrent, totals.current, fg),
                _bucket(l10n.supplierAgingCol1_30, totals.bucket1to30, fg),
                _bucket(l10n.supplierAgingCol31_60, totals.bucket31to60, fg),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _bucket(l10n.supplierAgingCol61_90, totals.bucket61to90,
                    AppColors.primary),
                _bucket(l10n.supplierAgingColOver90, totals.over90,
                    AppColors.destructive),
                _bucket(l10n.supplierAgingColTotal, totals.totalBalance,
                    AppColors.primary,
                    bold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bucket(String label, double val, Color color,
      {bool bold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodyXs.copyWith(color: muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            AppFormatters.currency(val),
            style: AppTextStyles.numeric.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
