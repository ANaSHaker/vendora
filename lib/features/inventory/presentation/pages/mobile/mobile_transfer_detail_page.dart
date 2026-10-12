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
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../domain/entities/transfer_entities.dart';
import '../../../domain/usecases/transfer_usecases.dart';

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
        label: label, color: AppColors.primary, bgColor: AppColors.primaryMuted),
    'in_transit' => StatusBadge.custom(
        label: label,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFEF3C7)),
    'received' => StatusBadge.custom(
        label: label, color: AppColors.primary, bgColor: AppColors.primaryMuted),
    'cancelled' => StatusBadge.custom(
        label: label,
        color: AppColors.destructive,
        bgColor: AppColors.destructive.withValues(alpha: 0.1)),
    _ => StatusBadge.custom(
        label: label,
        color: AppColors.mutedForeground,
        bgColor: AppColors.muted),
  };
}

class MobileTransferDetailPage extends StatefulWidget {
  final String id;
  const MobileTransferDetailPage({super.key, required this.id});

  @override
  State<MobileTransferDetailPage> createState() =>
      _MobileTransferDetailPageState();
}

class _MobileTransferDetailPageState
    extends State<MobileTransferDetailPage> {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('transferDetailTitle')),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/transfers'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _errorMsg != null
              ? AppErrorWidget(message: _errorMsg!, onRetry: _load)
              : _transfer == null
                  ? const SizedBox.shrink()
                  : _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final t = _transfer!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + actions row
          Row(
            children: [
              _statusBadge(t.status, l10n),
              const Spacer(),
              if (_actionLoading)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),

          if (!_actionLoading) ...[
            const SizedBox(height: AppSpacing.sm),
            if (t.status == 'draft')
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: l10n.t('approve'),
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.thumb_up_outlined, size: 14),
                      onPressed: () => _doAction('approve'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.destructive(
                      label: l10n.delete,
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.delete_outline, size: 14),
                      onPressed: () => _doAction('delete'),
                    ),
                  ),
                ],
              ),
            if (t.status == 'approved')
              AppButton.primary(
                label: l10n.t('ship'),
                size: AppButtonSize.sm,
                leading:
                    const Icon(Icons.local_shipping_outlined, size: 14),
                onPressed: () => _doAction('ship'),
              ),
            if (t.status == 'in_transit')
              AppButton.primary(
                label: l10n.t('receive'),
                size: AppButtonSize.sm,
                leading:
                    const Icon(Icons.check_circle_outline, size: 14),
                onPressed: () => _doAction('receive'),
              ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Progress stepper
          _MobileStepper(status: t.status, isDark: isDark, l10n: l10n),
          const SizedBox(height: AppSpacing.md),

          // Info card
          _InfoCard(transfer: t, isDark: isDark, l10n: l10n),
          const SizedBox(height: AppSpacing.md),

          // Items
          if (t.items != null && t.items!.isNotEmpty)
            _ItemsCard(transfer: t, isDark: isDark, l10n: l10n),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _MobileStepper extends StatelessWidget {
  final String status;
  final bool isDark;
  final AppLocalizations l10n;

  const _MobileStepper(
      {required this.status, required this.isDark, required this.l10n});

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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: isCancelled
          ? Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    size: 14, color: AppColors.destructive),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.t('statusCancelled'),
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.destructive)),
              ],
            )
          : Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIdx = i ~/ 2;
                  final passed = _currentIndex > stepIdx;
                  return Expanded(
                    child: Container(height: 2,
                        color: passed ? AppColors.primary : border),
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
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone || isActive
                            ? AppColors.primary
                            : (isDark ? AppColors.darkMuted : AppColors.muted),
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
                              size: 12, color: Colors.white)
                          : isActive
                              ? const Icon(Icons.circle,
                                  size: 8, color: Colors.white)
                              : null,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stepLabel,
                      style: AppTextStyles.bodyXs.copyWith(
                        fontSize: 9,
                        color: isDone || isActive ? fg : muted,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final TransferEntity transfer;
  final bool isDark;
  final AppLocalizations l10n;

  const _InfoCard(
      {required this.transfer, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
          _InfoRow(
              label: l10n.t('labelReference'),
              value: transfer.reference?.isNotEmpty == true
                  ? transfer.reference!
                  : '—',
              fg: fg,
              muted: muted),
          _InfoRow(
              label: l10n.t('labelFromWarehouse'),
              value: transfer.fromWarehouseName,
              fg: fg,
              muted: muted),
          _InfoRow(
              label: l10n.t('labelToWarehouse'),
              value: transfer.toWarehouseName,
              fg: fg,
              muted: muted),
          if (transfer.fromBranchName != null)
            _InfoRow(
                label: l10n.t('labelFromBranch'),
                value: transfer.fromBranchName!,
                fg: fg,
                muted: muted),
          if (transfer.toBranchName != null)
            _InfoRow(
                label: l10n.t('labelToBranch'),
                value: transfer.toBranchName!,
                fg: fg,
                muted: muted),
          _InfoRow(
              label: l10n.t('colCreated'),
              value: _fmtDate(transfer.createdAt),
              fg: fg,
              muted: muted),
          if (transfer.approvedAt != null)
            _InfoRow(
                label: l10n.t('approvedAt'),
                value: _fmtDate(transfer.approvedAt),
                fg: fg,
                muted: muted),
          if (transfer.postedAt != null)
            _InfoRow(
                label: l10n.t('postedAt'),
                value: _fmtDate(transfer.postedAt),
                fg: fg,
                muted: muted),
          if (transfer.receivedAt != null)
            _InfoRow(
                label: l10n.t('receivedAt'),
                value: _fmtDate(transfer.receivedAt),
                fg: fg,
                muted: muted),
          if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: border),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.t('labelNotes').toUpperCase(),
                style: AppTextStyles.bodyXs.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: AppSpacing.xs),
            Text(transfer.notes!,
                style: AppTextStyles.bodySm.copyWith(color: fg)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;
  final Color muted;

  const _InfoRow(
      {required this.label,
      required this.value,
      required this.fg,
      required this.muted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTextStyles.bodyXs.copyWith(color: muted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.labelSm.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final TransferEntity transfer;
  final bool isDark;
  final AppLocalizations l10n;

  const _ItemsCard(
      {required this.transfer, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final items = transfer.items!;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Text(l10n.t('labelItems'),
                    style: AppTextStyles.labelMd.copyWith(color: fg)),
                const Spacer(),
                Text('${items.length} ${l10n.t("itemsCount")}',
                    style: AppTextStyles.bodySm.copyWith(color: muted)),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: border),
            itemBuilder: (_, i) {
              final item = items[i];
              final total = item.qty * item.unitCost;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style:
                                  AppTextStyles.labelSm.copyWith(color: fg),
                              overflow: TextOverflow.ellipsis),
                          if (item.productSku != null)
                            Text(item.productSku!,
                                style: AppTextStyles.bodyXs
                                    .copyWith(color: muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.qty.toStringAsFixed(item.qty == item.qty.truncate() ? 0 : 2)} × ${item.unitCost.toStringAsFixed(2)}',
                          style:
                              AppTextStyles.bodyXs.copyWith(color: muted),
                        ),
                        Text(
                          total.toStringAsFixed(2),
                          style:
                              AppTextStyles.labelSm.copyWith(color: fg),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
