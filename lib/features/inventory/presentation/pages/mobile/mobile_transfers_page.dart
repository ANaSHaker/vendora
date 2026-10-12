import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../domain/entities/transfer_entities.dart';
import '../../cubit/transfer_cubit.dart';
import '../../cubit/transfer_state.dart';

class MobileTransfersPage extends StatelessWidget {
  const MobileTransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransferCubit(
        getTransfers: getIt(),
        createTransfer: getIt(),
        approveTransfer: getIt(),
        postTransfer: getIt(),
        receiveTransfer: getIt(),
        deleteTransfer: getIt(),
      )..load(),
      child: const _MobileTransfersContent(),
    );
  }
}

class _MobileTransfersContent extends StatelessWidget {
  const _MobileTransfersContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('transfers')),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _FilterBar(l10n: l10n),
          Expanded(
            child: BlocBuilder<TransferCubit, TransferState>(
              builder: (context, state) {
                if (state is TransferLoading) {
                  return const ShimmerBox(height: 300);
                }
                if (state is TransferError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<TransferCubit>().refresh(),
                  );
                }
                if (state is TransferLoaded) {
                  if (state.transfers.isEmpty) {
                    return Center(
                      child: AppEmptyState(
                        message: l10n.t('noData'),
                        subtitle: l10n.t('transfers'),
                        icon: const Icon(Icons.swap_horiz_outlined, size: 32),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<TransferCubit>().refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: state.transfers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final t = state.transfers[i];
                        return _TransferCard(transfer: t, l10n: l10n);
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final AppLocalizations l10n;
  const _FilterBar({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransferCubit>().state;
    final statusFilter =
        state is TransferLoaded ? state.statusFilter : null;

    final statuses = <(String?, String)>[
      (null, l10n.t('all')),
      ('draft', l10n.t('statusDraft')),
      ('approved', l10n.t('statusApproved')),
      ('in_transit', l10n.t('statusInTransit')),
      ('received', l10n.t('statusReceived')),
      ('statusCancelled', l10n.t('statusCancelled')),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Column(
        children: [
          AppSearchField(
            hint: l10n.t('search'),
            onChanged: (q) => context.read<TransferCubit>().search(q),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: statuses.map((pair) {
                final isSelected = statusFilter == pair.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: FilterChip(
                    label: Text(pair.$2),
                    selected: isSelected,
                    onSelected: (_) => context
                        .read<TransferCubit>()
                        .filterByStatus(pair.$1),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final TransferEntity transfer;
  final AppLocalizations l10n;
  const _TransferCard({required this.transfer, required this.l10n});

  Color _statusColor(String status) => switch (status) {
        'draft' => AppColors.statusDraft,
        'approved' => AppColors.primary,
        'in_transit' => AppColors.warning,
        'received' => AppColors.success,
        'cancelled' => AppColors.destructive,
        _ => AppColors.statusDraft,
      };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransferCubit>();
    final statusColor = _statusColor(transfer.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transfer.reference ?? '#${transfer.id.substring(0, 8)}',
                    style: AppTextStyles.labelLg
                        .copyWith(fontWeight: FontWeight.w600, color: fg),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transfer.status,
                    style: AppTextStyles.labelSm
                        .copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.arrow_forward, size: 14, color: muted),
                const SizedBox(width: 4),
                Text(
                  '${transfer.fromWarehouseCode} → ${transfer.toWarehouseCode}',
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  '${transfer.itemsCount} ${l10n.t('itemsCount')}',
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
                const Spacer(),
                Text(
                  AppFormatters.dateShort(
                      DateTime.tryParse(transfer.createdAt) ?? DateTime.now()),
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
              ],
            ),
            if (transfer.status == 'draft' ||
                transfer.status == 'approved') ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (transfer.status == 'draft')
                    TextButton(
                      onPressed: () async {
                        final ok = await cubit.approveTransfer(transfer.id);
                        if (context.mounted) {
                          if (ok) {
                            AppSnackbar.success(
                                context, l10n.t('transferApproved'));
                          } else {
                            AppSnackbar.error(
                                context, l10n.t('transferActionFailed'));
                          }
                        }
                      },
                      child: Text(l10n.t('approve')),
                    ),
                  if (transfer.status == 'approved')
                    TextButton(
                      onPressed: () async {
                        final ok = await cubit.shipTransfer(transfer.id);
                        if (context.mounted) {
                          if (ok) {
                            AppSnackbar.success(context, l10n.t('shipped'));
                          } else {
                            AppSnackbar.error(
                                context, l10n.t('transferActionFailed'));
                          }
                        }
                      },
                      child: Text(l10n.t('ship')),
                    ),
                  if (transfer.status == 'draft')
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppColors.destructive,
                      onPressed: () async {
                        final confirmed = await ConfirmDialog.show(
                          context: context,
                          title: l10n.t('deleteTransfer'),
                          message: l10n.t('deleteTransferMsg'),
                          confirmLabel: l10n.delete,
                          isDestructive: true,
                          onConfirm: () {},
                        );
                        if (confirmed != true || !context.mounted) return;
                        final ok =
                            await cubit.deleteTransfer(transfer.id);
                        if (context.mounted) {
                          if (ok) {
                            AppSnackbar.success(
                                context, l10n.t('transferDeleted'));
                          } else {
                            AppSnackbar.error(
                                context, l10n.t('transferDeleteFailed'));
                          }
                        }
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
