import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';
import '../../../core/utils/enums.dart' as app_enums;

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  factory StatusBadge.fromOrderStatus(app_enums.OrderStatus status) {
    final (color, bg) = switch (status) {
      app_enums.OrderStatus.paid =>
        (AppColors.statusPaid, AppColors.statusPaidBg),
      app_enums.OrderStatus.refunded =>
        (AppColors.statusRefunded, AppColors.statusRefundedBg),
      app_enums.OrderStatus.partialRefund =>
        (AppColors.statusPartialRefund, AppColors.statusPartialRefundBg),
      app_enums.OrderStatus.cancelled =>
        (AppColors.statusCancelled, AppColors.statusCancelledBg),
    };
    final label = switch (status) {
      app_enums.OrderStatus.paid         => 'Paid',
      app_enums.OrderStatus.refunded     => 'Refunded',
      app_enums.OrderStatus.partialRefund=> 'Partial Refund',
      app_enums.OrderStatus.cancelled    => 'Cancelled',
    };
    return StatusBadge(label: label, color: color, bgColor: bg);
  }

  factory StatusBadge.fromFulfillment(app_enums.FulfillmentStatus status) {
    final (color, bg) = switch (status) {
      app_enums.FulfillmentStatus.preparing =>
        (AppColors.statusPending, AppColors.statusPendingBg),
      app_enums.FulfillmentStatus.ready =>
        (AppColors.statusApproved, AppColors.statusApprovedBg),
      app_enums.FulfillmentStatus.completed =>
        (AppColors.statusCompleted, AppColors.statusCompletedBg),
      app_enums.FulfillmentStatus.cancelled =>
        (AppColors.statusCancelled, AppColors.statusCancelledBg),
    };
    final label = switch (status) {
      app_enums.FulfillmentStatus.preparing => 'Preparing',
      app_enums.FulfillmentStatus.ready     => 'Ready',
      app_enums.FulfillmentStatus.completed => 'Completed',
      app_enums.FulfillmentStatus.cancelled => 'Cancelled',
    };
    return StatusBadge(label: label, color: color, bgColor: bg);
  }

  factory StatusBadge.fromTransfer(app_enums.TransferStatus status) {
    final (color, bg) = switch (status) {
      app_enums.TransferStatus.draft =>
        (AppColors.statusDraft, AppColors.statusDraftBg),
      app_enums.TransferStatus.approved =>
        (AppColors.statusApproved, AppColors.statusApprovedBg),
      app_enums.TransferStatus.inTransit =>
        (AppColors.statusInTransit, AppColors.statusInTransitBg),
      app_enums.TransferStatus.received =>
        (AppColors.statusCompleted, AppColors.statusCompletedBg),
      app_enums.TransferStatus.cancelled =>
        (AppColors.statusCancelled, AppColors.statusCancelledBg),
    };
    final label = switch (status) {
      app_enums.TransferStatus.draft     => 'Draft',
      app_enums.TransferStatus.approved  => 'Approved',
      app_enums.TransferStatus.inTransit => 'In Transit',
      app_enums.TransferStatus.received  => 'Received',
      app_enums.TransferStatus.cancelled => 'Cancelled',
    };
    return StatusBadge(label: label, color: color, bgColor: bg);
  }

  factory StatusBadge.fromChannel(app_enums.OrderChannel channel) {
    return switch (channel) {
      app_enums.OrderChannel.pos => const StatusBadge(
          label: 'POS',
          color: AppColors.statusApproved,
          bgColor: AppColors.statusApprovedBg,
        ),
      app_enums.OrderChannel.online => const StatusBadge(
          label: 'Online',
          color: AppColors.statusPosted,
          bgColor: AppColors.statusPostedBg,
        ),
    };
  }

  factory StatusBadge.custom({
    required String label,
    required Color color,
    required Color bgColor,
  }) =>
      StatusBadge(label: label, color: color, bgColor: bgColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.px2,
        vertical: AppSpacing.px2 + 1,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelXs.copyWith(color: color),
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const CountBadge({super.key, required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color ?? AppColors.destructive,
        borderRadius: AppRadius.brFull,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AppTextStyles.labelXs.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
