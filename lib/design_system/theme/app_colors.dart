import 'package:flutter/material.dart';

abstract final class AppColors {
  // ─── Primary (Vendora dark navy blue) ────────────────────────────────────
  static const Color primary = Color(0xFF0C2461);
  static const Color primaryHover = Color(0xFF091D4F);
  static const Color primaryLight = Color(0xFFE8EDF8);
  static const Color primaryMuted = Color(0xFFEEF1FA);
  static const Color primaryBg = Color(0xFFF5F7FF);

  // ─── Light Mode ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEFEFEF);
  static const Color muted = Color(0xFFF7F7F7);
  static const Color foreground = Color(0xFF1A1A1A);
  static const Color mutedForeground = Color(0xFF737373);
  static const Color subtleForeground = Color(0xFFA3A3A3);

  // ─── Dark Mode ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0E0F1A);
  static const Color darkSurface = Color(0xFF14162A);
  static const Color darkBorder = Color(0xFF1E2035);
  static const Color darkMuted = Color(0xFF1A1C2E);
  static const Color darkForeground = Color(0xFFECEDF5);
  static const Color darkMutedForeground = Color(0xFF9899B0);
  static const Color darkSubtleForeground = Color(0xFF6B6D85);

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveLight = Color(0xFFFEE2E2);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successForeground = Color(0xFF14532D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningForeground = Color(0xFF78350F);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDEEBFF);
  static const Color infoForeground = Color(0xFF1E3A8A);

  // ─── Order / Transfer Status ──────────────────────────────────────────────
  static const Color statusPaid = Color(0xFF22C55E);
  static const Color statusPaidBg = Color(0xFFDCFCE7);

  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusCancelledBg = Color(0xFFFEE2E2);

  static const Color statusRefunded = Color(0xFF8B5CF6);
  static const Color statusRefundedBg = Color(0xFFEDE9FE);

  static const Color statusDraft = Color(0xFF6B7280);
  static const Color statusDraftBg = Color(0xFFF3F4F6);

  static const Color statusApproved = Color(0xFF3B82F6);
  static const Color statusApprovedBg = Color(0xFFDEEBFF);

  static const Color statusCompleted = Color(0xFF22C55E);
  static const Color statusCompletedBg = Color(0xFFDCFCE7);

  static const Color statusInTransit = Color(0xFFF59E0B);
  static const Color statusInTransitBg = Color(0xFFFEF3C7);

  static const Color statusPosted = Color(0xFF0EA5E9);
  static const Color statusPostedBg = Color(0xFFE0F2FE);

  static const Color statusPartialRefund = Color(0xFF8B5CF6);
  static const Color statusPartialRefundBg = Color(0xFFEDE9FE);

  // ─── Charts ───────────────────────────────────────────────────────────────
  static const Color chart1 = Color(0xFF3B82F6);
  static const Color chart2 = Color(0xFF22C55E);
  static const Color chart3 = Color(0xFF8B5CF6);
  static const Color chart4 = Color(0xFFF59E0B);
  static const Color chart5 = Color(0xFFF472B6);

  static const Color darkChart1 = Color(0xFF60A5FA);
  static const Color darkChart2 = Color(0xFF34D399);
  static const Color darkChart3 = Color(0xFFA78BFA);
  static const Color darkChart4 = Color(0xFFFBBF24);
  static const Color darkChart5 = Color(0xFFF472B6);

  // ─── Sidebar ──────────────────────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFFFAFAFA);
  static const Color sidebarBorder = Color(0xFFEFEFEF);
  static const Color sidebarActiveItem = Color(0xFFF3F4F6);
  static const Color sidebarHoverItem = Color(0xFFF9FAFB);

  static const Color darkSidebarBg = Color(0xFF0A0B17);
  static const Color darkSidebarBorder = Color(0xFF1A1C30);
  static const Color darkSidebarActiveItem = Color(0xFF1E2035);
  static const Color darkSidebarHoverItem = Color(0xFF16182B);

  // ─── Transparent ──────────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
