import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../domain/entities/transfer_entities.dart';
import '../../../domain/usecases/transfer_usecases.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

StatusBadge _statusBadge(String status, AppLocalizations l10n) {
  final label = switch (status) {
    'draft' => l10n.t('statusDraft'),
    'approved' => l10n.t('statusApproved'),
    'in_transit' => l10n.t('statusInTransit'),
    'received' => l10n.t('statusReceived'),
    'cancelled' => l10n.t('statusCancelled'),
    _ => status,
  };
  return switch (status) {
    'approved' => StatusBadge.custom(
        label: label,
        color: AppColors.primary,
        bgColor: AppColors.primaryMuted,
      ),
    'in_transit' => StatusBadge.custom(
        label: label,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7),
      ),
    'received' => StatusBadge.custom(
        label: label,
        color: AppColors.primary,
        bgColor: AppColors.primaryMuted,
      ),
    'cancelled' => StatusBadge.custom(
        label: label,
        color: AppColors.destructive,
        bgColor: AppColors.destructive.withValues(alpha: 0.1),
      ),
    _ => StatusBadge.custom(
        label: label,
        color: AppColors.mutedForeground,
        bgColor: AppColors.muted,
      ),
  };
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopTransferDetailPage extends StatefulWidget {
  final String id;

  const DesktopTransferDetailPage({super.key, required this.id});

  @override
  State<DesktopTransferDetailPage> createState() =>
      _DesktopTransferDetailPageState();
}

class _DesktopTransferDetailPageState
    extends State<DesktopTransferDetailPage> {
  TransferEntity? _transfer;
  bool _loading = true;
  String? _errorMsg;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    final result = await getIt<GetTransferByIdUseCase>()(widget.id);
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _errorMsg = f.message;
        _loading = false;
      }),
      (t) => setState(() {
        _transfer = t;
        _loading = false;
      }),
    );
  }

  Future<void> _doAction(String action) async {
    final l10n = AppLocalizations.of(context);
    final t = _transfer;
    if (t == null) return;

    final (title, msg, label, isDestructive) = switch (action) {
      'approve' => (
          l10n.t('approveTransferTitle'),
          l10n.t('approveTransferMsg'),
          l10n.t('approve'),
          false
        ),
      'ship' => (
          l10n.t('shipTransferTitle'),
          l10n.t('shipTransferMsg'),
          l10n.t('ship'),
          false
        ),
      'receive' => (
          l10n.t('receiveTransferTitle'),
          l10n.t('receiveTransferMsg'),
          l10n.t('receive'),
          false
        ),
      'cancel' => (
          l10n.t('cancelTransferTitle'),
          l10n.t('cancelTransferMsg'),
          l10n.t('cancelAction'),
          true
        ),
      _ => (
          l10n.t('deleteTransferTitle'),
          l10n.t('deleteTransferMsg'),
          l10n.delete,
          true
        ),
    };

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: title,
      message: msg,
      confirmLabel: label,
      isDestructive: isDestructive,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);

    if (action == 'delete') {
      final result = await getIt<DeleteTransferUseCase>()(t.id);
      if (!mounted) return;
      result.fold(
        (f) {
          setState(() => _actionLoading = false);
          AppSnackbar.error(context, l10n.t('actionFailed'));
        },
        (_) {
          AppSnackbar.success(context, l10n.t('actionSuccess'));
          context.go('/transfers');
        },
      );
      return;
    }

    final result = await switch (action) {
      'approve' => getIt<ApproveTransferUseCase>()(t.id),
      'ship' => getIt<PostTransferUseCase>()(t.id),
      'receive' => getIt<ReceiveTransferUseCase>()(t.id),
      _ => getIt<ApproveTransferUseCase>()(t.id),
    };
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _actionLoading = false);
        AppSnackbar.error(context, l10n.t('actionFailed'));
      },
      (updated) {
        setState(() {
          _transfer = updated;
          _actionLoading = false;
        });
        AppSnackbar.success(context, l10n.t('actionSuccess'));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    return ColoredBox(
      color: bg,
      child: Column(
        children: [
          // Page header
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.desktopContentPadding),
            child: Row(
              children: [
                AppIconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  onPressed: () => context.go('/transfers'),
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.t('transferDetailTitle'),
                    style: AppTextStyles.h5.copyWith(color: fg)),
                if (_transfer != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  _statusBadge(_transfer!.status, l10n),
                ],
                const Spacer(),
                if (_actionLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_transfer != null && !_actionLoading) ...[
                  if (_transfer!.status == 'draft') ...[
                    AppButton.outline(
                      label: l10n.t('approve'),
                      size: AppButtonSize.sm,
                      leading:
                          const Icon(Icons.thumb_up_outlined, size: 14),
                      onPressed: () => _doAction('approve'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.destructive(
                      label: l10n.delete,
                      size: AppButtonSize.sm,
                      leading:
                          const Icon(Icons.delete_outline, size: 14),
                      onPressed: () => _doAction('delete'),
                    ),
                  ],
                  if (_transfer!.status == 'approved') ...[
                    AppButton.primary(
                      label: l10n.t('ship'),
                      size: AppButtonSize.sm,
                      leading: const Icon(
                          Icons.local_shipping_outlined,
                          size: 14),
                      onPressed: () => _doAction('ship'),
                    ),
                  ],
                  if (_transfer!.status == 'in_transit') ...[
                    AppButton.primary(
                      label: l10n.t('receive'),
                      size: AppButtonSize.sm,
                      leading: const Icon(
                          Icons.check_circle_outline,
                          size: 14),
                      onPressed: () => _doAction('receive'),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : _errorMsg != null
                    ? AppErrorWidget(
                        message: _errorMsg!, onRetry: _load)
                    : _transfer == null
                        ? const SizedBox.shrink()
                        : _TransferDetailBody(
                            transfer: _transfer!,
                            isDark: isDark,
                            l10n: l10n,
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────

class _TransferDetailBody extends StatelessWidget {
  final TransferEntity transfer;
  final bool isDark;
  final AppLocalizations l10n;

  const _TransferDetailBody({
    required this.transfer,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress stepper
              _TransferStepper(
                  status: transfer.status,
                  isDark: isDark,
                  l10n: l10n),
              const SizedBox(height: AppSpacing.xl),

              // Info grid
              _InfoCard(
                  transfer: transfer,
                  isDark: isDark,
                  l10n: l10n),
              const SizedBox(height: AppSpacing.lg),

              // Items
              if (transfer.items != null && transfer.items!.isNotEmpty)
                _ItemsCard(
                    transfer: transfer,
                    isDark: isDark,
                    l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stepper ───────────────────────────────────────────────────────────────────

class _TransferStepper extends StatelessWidget {
  final String status;
  final bool isDark;
  final AppLocalizations l10n;

  const _TransferStepper({
    required this.status,
    required this.isDark,
    required this.l10n,
  });

  static const _steps = ['draft', 'approved', 'in_transit', 'received'];

  int get _currentIndex => _steps.indexOf(status);

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == 'cancelled';
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: isCancelled
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color:
                        AppColors.destructive.withValues(alpha: 0.1),
                    borderRadius: AppRadius.brMd,
                    border: Border.all(
                        color: AppColors.destructive
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined,
                          size: 14, color: AppColors.destructive),
                      const SizedBox(width: AppSpacing.xs),
                      Text(l10n.t('statusCancelled'),
                          style: AppTextStyles.labelSm
                              .copyWith(color: AppColors.destructive)),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  // Connector
                  final stepIdx = i ~/ 2;
                  final passed = _currentIndex > stepIdx;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: passed ? AppColors.primary : border,
                    ),
                  );
                }
                final stepIdx = i ~/ 2;
                final isDone = _currentIndex > stepIdx;
                final isActive = _currentIndex == stepIdx;
                final stepLabel = switch (_steps[stepIdx]) {
                  'draft' => l10n.t('transferStep_draft'),
                  'approved' => l10n.t('transferStep_approved'),
                  'in_transit' => l10n.t('transferStep_in_transit'),
                  _ => l10n.t('transferStep_received'),
                };
                return Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone || isActive
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkMuted
                                : AppColors.muted),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone || isActive
                              ? AppColors.primary
                              : border,
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : isActive
                              ? const Icon(Icons.circle,
                                  size: 10, color: Colors.white)
                              : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepLabel,
                      style: AppTextStyles.bodyXs.copyWith(
                        color: isDone || isActive ? fg : muted,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final TransferEntity transfer;
  final bool isDark;
  final AppLocalizations l10n;

  const _InfoCard({
    required this.transfer,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final mutedBg =
        isDark ? AppColors.darkMuted : AppColors.muted;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('labelDetails').toUpperCase(),
            style: AppTextStyles.bodyXs.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InfoItem(
                label: l10n.t('labelReference'),
                value: transfer.reference?.isNotEmpty == true
                    ? transfer.reference!
                    : '—',
                fg: fg,
                muted: muted,
                bg: mutedBg,
              ),
              _InfoItem(
                label: l10n.t('labelFromWarehouse'),
                value: transfer.fromWarehouseName,
                fg: fg,
                muted: muted,
                bg: mutedBg,
              ),
              _InfoItem(
                label: l10n.t('labelToWarehouse'),
                value: transfer.toWarehouseName,
                fg: fg,
                muted: muted,
                bg: mutedBg,
              ),
              if (transfer.fromBranchName != null)
                _InfoItem(
                  label: l10n.t('labelFromBranch'),
                  value: transfer.fromBranchName!,
                  fg: fg,
                  muted: muted,
                  bg: mutedBg,
                ),
              if (transfer.toBranchName != null)
                _InfoItem(
                  label: l10n.t('labelToBranch'),
                  value: transfer.toBranchName!,
                  fg: fg,
                  muted: muted,
                  bg: mutedBg,
                ),
              _InfoItem(
                label: l10n.t('colCreated'),
                value: _fmtDate(transfer.createdAt),
                fg: fg,
                muted: muted,
                bg: mutedBg,
              ),
              if (transfer.approvedAt != null)
                _InfoItem(
                  label: l10n.t('approvedAt'),
                  value: _fmtDate(transfer.approvedAt),
                  fg: fg,
                  muted: muted,
                  bg: mutedBg,
                ),
              if (transfer.postedAt != null)
                _InfoItem(
                  label: l10n.t('postedAt'),
                  value: _fmtDate(transfer.postedAt),
                  fg: fg,
                  muted: muted,
                  bg: mutedBg,
                ),
              if (transfer.receivedAt != null)
                _InfoItem(
                  label: l10n.t('receivedAt'),
                  value: _fmtDate(transfer.receivedAt),
                  fg: fg,
                  muted: muted,
                  bg: mutedBg,
                ),
            ],
          ),
          if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: border),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.t('labelNotes').toUpperCase(),
              style: AppTextStyles.bodyXs.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(transfer.notes!,
                style: AppTextStyles.bodySm.copyWith(color: fg)),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;
  final Color muted;
  final Color bg;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.fg,
    required this.muted,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodyXs.copyWith(color: muted)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.labelSm.copyWith(color: fg)),
        ],
      ),
    );
  }
}

// ── Items card ────────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final TransferEntity transfer;
  final bool isDark;
  final AppLocalizations l10n;

  const _ItemsCard({
    required this.transfer,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg =
        isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final items = transfer.items!;

    // Summary totals
    final totalQty =
        items.fold<double>(0, (s, i) => s + i.qty);
    final totalCost =
        items.fold<double>(0, (s, i) => s + (i.qty * i.unitCost));

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md),
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: border))),
              child: Row(
                children: [
                  Text(l10n.t('labelItems'),
                      style: AppTextStyles.labelMd.copyWith(color: fg)),
                  const Spacer(),
                  Text(
                    '${items.length} ${l10n.t("itemsCount")}',
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
                ],
              ),
            ),

            // Table header
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(l10n.t('colProduct'),
                          style: AppTextStyles.tableHeader)),
                  SizedBox(
                    width: 80,
                    child: Text(l10n.t('colQty'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(l10n.t('colUnitCost'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(l10n.t('colTotal'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: border),
              itemBuilder: (_, i) {
                final item = items[i];
                final total = item.qty * item.unitCost;
                return Container(
                  height: AppSizes.tableRowHeight,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(item.productName,
                                style: AppTextStyles.tableCell
                                    .copyWith(color: fg),
                                overflow: TextOverflow.ellipsis),
                            if (item.productSku != null)
                              Text(item.productSku!,
                                  style: AppTextStyles.bodyXs
                                      .copyWith(color: muted),
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          item.qty.toStringAsFixed(
                              item.qty == item.qty.truncate()
                                  ? 0
                                  : 2),
                          style: AppTextStyles.numeric
                              .copyWith(color: fg),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          item.unitCost.toStringAsFixed(2),
                          style: AppTextStyles.numeric
                              .copyWith(color: muted),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          total.toStringAsFixed(2),
                          style: AppTextStyles.numeric
                              .copyWith(color: fg),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Footer totals
            Divider(height: 1, color: border),
            Container(
              height: AppSizes.tableRowHeight,
              color:
                  isDark ? AppColors.darkMuted : AppColors.primaryMuted,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(l10n.t('totalLabel'),
                          style: AppTextStyles.labelSm
                              .copyWith(color: fg))),
                  SizedBox(
                    width: 80,
                    child: Text(
                      totalQty.toStringAsFixed(
                          totalQty == totalQty.truncate() ? 0 : 2),
                      style:
                          AppTextStyles.numeric.copyWith(color: fg),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 110),
                  SizedBox(
                    width: 110,
                    child: Text(
                      totalCost.toStringAsFixed(2),
                      style: AppTextStyles.numeric
                          .copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
