import 'package:flutter/material.dart';
import 'enums.dart' as app_enums;
import '../error/failures.dart';
import '../../design_system/theme/app_colors.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  MediaQueryData get media => MediaQuery.of(this);
  double get screenWidth => media.size.width;
  double get screenHeight => media.size.height;
  bool get isDesktop => screenWidth >= 1024;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isMobile => screenWidth < 600;
}

extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get titleCase {
    return split(' ').map((w) => w.capitalize).join(' ');
  }

  String get snakeToTitle {
    return replaceAll('_', ' ').titleCase;
  }
}

extension FailureExtensions on Failure {
  bool get isUnauthorized => this is UnauthorizedFailure;
  bool get isForbidden    => this is ForbiddenFailure;
  bool get isNetwork      => this is NetworkFailure;
  bool get isValidation   => this is ValidationFailure;
}

extension OrderStatusExtensions on app_enums.OrderStatus {
  Color get color => switch (this) {
        app_enums.OrderStatus.paid          => AppColors.statusPaid,
        app_enums.OrderStatus.refunded      => AppColors.statusRefunded,
        app_enums.OrderStatus.partialRefund => AppColors.statusPartialRefund,
        app_enums.OrderStatus.cancelled     => AppColors.statusCancelled,
      };

  Color get bgColor => switch (this) {
        app_enums.OrderStatus.paid          => AppColors.statusPaidBg,
        app_enums.OrderStatus.refunded      => AppColors.statusRefundedBg,
        app_enums.OrderStatus.partialRefund => AppColors.statusPartialRefundBg,
        app_enums.OrderStatus.cancelled     => AppColors.statusCancelledBg,
      };

  String get label => switch (this) {
        app_enums.OrderStatus.paid          => 'Paid',
        app_enums.OrderStatus.refunded      => 'Refunded',
        app_enums.OrderStatus.partialRefund => 'Partial Refund',
        app_enums.OrderStatus.cancelled     => 'Cancelled',
      };
}

extension TransferStatusExtensions on app_enums.TransferStatus {
  Color get color => switch (this) {
        app_enums.TransferStatus.draft      => AppColors.statusDraft,
        app_enums.TransferStatus.approved   => AppColors.statusApproved,
        app_enums.TransferStatus.inTransit  => AppColors.statusInTransit,
        app_enums.TransferStatus.received   => AppColors.statusCompleted,
        app_enums.TransferStatus.cancelled  => AppColors.statusCancelled,
      };

  Color get bgColor => switch (this) {
        app_enums.TransferStatus.draft      => AppColors.statusDraftBg,
        app_enums.TransferStatus.approved   => AppColors.statusApprovedBg,
        app_enums.TransferStatus.inTransit  => AppColors.statusInTransitBg,
        app_enums.TransferStatus.received   => AppColors.statusCompletedBg,
        app_enums.TransferStatus.cancelled  => AppColors.statusCancelledBg,
      };

  String get label => switch (this) {
        app_enums.TransferStatus.draft      => 'Draft',
        app_enums.TransferStatus.approved   => 'Approved',
        app_enums.TransferStatus.inTransit  => 'In Transit',
        app_enums.TransferStatus.received   => 'Received',
        app_enums.TransferStatus.cancelled  => 'Cancelled',
      };
}
