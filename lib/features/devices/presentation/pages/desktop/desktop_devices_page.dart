import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../domain/entities/device_session_entity.dart';
import '../../../domain/usecases/devices_usecases.dart';
import '../../cubit/devices_cubit.dart';
import '../../cubit/devices_state.dart';

class DesktopDevicesPage extends StatelessWidget {
  const DesktopDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DevicesCubit(
        getSessions: getIt<GetDeviceSessionsUseCase>(),
        logoutDevice: getIt<LogoutDeviceUseCase>(),
        logoutAll: getIt<LogoutAllDevicesUseCase>(),
        blockDevice: getIt<BlockDeviceUseCase>(),
      )..load(),
      child: const _DevicesContent(),
    );
  }
}

class _DevicesContent extends StatelessWidget {
  const _DevicesContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesCubit, DevicesState>(
      builder: (context, state) {
        final cubit = context.read<DevicesCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('deviceSessionsTitle'),
                            style: AppTextStyles.h4.copyWith(color: fg),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.t('deviceSessionsSubtitle'),
                            style: AppTextStyles.bodySm.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    AppButton.outline(
                      label: l10n.t('logoutAllDevices'),
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.logout_rounded, size: 16),
                      onPressed: () =>
                          _confirmLogoutAll(context, cubit, l10n),
                    ),
                  ],
                ),
              ),

              // ── Table ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding,
                  ),
                  child: switch (state) {
                    DevicesInitial() || DevicesLoading() =>
                      const ShimmerTableRows(),
                    DevicesError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.load,
                      ),
                    DevicesLoaded(:final sessions) when sessions.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.devices_outlined, size: 40),
                        message: l10n.t('noDeviceSessions'),
                      ),
                    DevicesLoaded(:final sessions) => _SessionsTable(
                        sessions: sessions,
                        isDark: isDark,
                        l10n: l10n,
                        onLogout: (s) =>
                            _confirmLogout(context, s, cubit, l10n),
                        onBlock: (s) =>
                            _confirmBlock(context, s, cubit, l10n),
                      ),
                  },
                ),
              ),
              const SizedBox(height: AppSizes.desktopContentPadding),
            ],
          ),
        );
      },
    );
  }
}

// ── Sessions Table ─────────────────────────────────────────────────────────────

class _SessionsTable extends StatelessWidget {
  final List<DeviceSessionEntity> sessions;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(DeviceSessionEntity) onLogout;
  final void Function(DeviceSessionEntity) onBlock;

  const _SessionsTable({
    required this.sessions,
    required this.isDark,
    required this.l10n,
    required this.onLogout,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Header
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(l10n.t('colDevice'),
                        style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('colUser'),
                        style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('colLocation'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(l10n.t('colIpAddress'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 150,
                    child: Text(l10n.t('colLastLogin'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(l10n.colStatus,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 260,
                    child: Text(l10n.t('colActions'),
                        style: AppTextStyles.tableHeader),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) => _SessionRow(
                  session: sessions[i],
                  isDark: isDark,
                  l10n: l10n,
                  onLogout: () => onLogout(sessions[i]),
                  onBlock: () => onBlock(sessions[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final DeviceSessionEntity session;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onLogout;
  final VoidCallback onBlock;

  const _SessionRow({
    required this.session,
    required this.isDark,
    required this.l10n,
    required this.onLogout,
    required this.onBlock,
  });

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final y = dt.year;
      final mo = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      final amPm = dt.hour < 12 ? 'ص' : 'م';
      final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      return '$y/$mo/$d $h12:$mi:$s $amPm';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final currentBg =
        isDark ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFF0F7FF);
    final rowBg = session.isCurrent ? currentBg : Colors.transparent;

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Device
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.device.isNotEmpty
                            ? session.device
                            : l10n.t('unknownDevice'),
                        style:
                            AppTextStyles.labelSm.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (session.isCurrent) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Text(
                          l10n.t('thisDevice'),
                          style: AppTextStyles.bodyXs.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                if (session.userAgent.isNotEmpty)
                  Text(
                    session.userAgent,
                    style:
                        AppTextStyles.bodyXs.copyWith(color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // User
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.userName.isNotEmpty ? session.userName : '—',
                  style: AppTextStyles.tableCell.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
                if (session.userName.isNotEmpty && session.userEmail.isNotEmpty)
                  Text(
                    session.userEmail,
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Location
          Expanded(
            flex: 2,
            child: Text(
              session.location.isNotEmpty
                  ? session.location
                  : l10n.t('unknownLocation'),
              style: AppTextStyles.tableCell.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // IP
          SizedBox(
            width: 130,
            child: Text(
              session.ipAddress.isNotEmpty ? session.ipAddress : '—',
              style: AppTextStyles.numeric.copyWith(
                color: fg,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Last login
          SizedBox(
            width: 150,
            child: Text(
              session.lastLoginAt.isNotEmpty
                  ? _fmtDate(session.lastLoginAt)
                  : '—',
              style: AppTextStyles.bodyXs.copyWith(color: muted),
            ),
          ),
          // Status
          SizedBox(
            width: 80,
            child: Center(
              child: session.isBlocked
                  ? StatusBadge.custom(
                      label: l10n.t('statusBlocked'),
                      color: AppColors.destructive,
                      bgColor: AppColors.destructive.withValues(alpha: 0.1),
                    )
                  : session.isExpired
                      ? StatusBadge.custom(
                          label: l10n.t('statusExpired'),
                          color: AppColors.warningForeground,
                          bgColor: AppColors.warningLight,
                        )
                      : session.isActive
                          ? StatusBadge.custom(
                              label: l10n.t('statusActive'),
                              color: AppColors.successForeground,
                              bgColor: AppColors.successLight,
                            )
                          : StatusBadge.custom(
                              label: l10n.t('statusInactive'),
                              color: AppColors.mutedForeground,
                              bgColor: AppColors.muted,
                            ),
            ),
          ),
          // Actions
          SizedBox(
            width: 260,
            child: Row(
              children: [
                Flexible(
                  child: AppButton.outline(
                    label: l10n.t('logoutThisDevice'),
                    size: AppButtonSize.sm,
                    onPressed: session.isCurrent ? null : onLogout,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppButton.outline(
                  label: session.isBlocked
                      ? l10n.t('unblock')
                      : l10n.t('blockDevice'),
                  size: AppButtonSize.sm,
                  onPressed: onBlock,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confirm Dialogs ────────────────────────────────────────────────────────────

Future<void> _confirmLogout(
  BuildContext context,
  DeviceSessionEntity session,
  DevicesCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('logoutDeviceTitle'),
    message: l10n.t('logoutDeviceMsg'),
    confirmLabel: l10n.t('logoutThisDevice'),
    isDestructive: false,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.logoutDevice(session.id);
  if (context.mounted) {
    ok
        ? AppSnackbar.success(context, l10n.t('deviceLoggedOut'))
        : AppSnackbar.error(context, l10n.t('actionFailed'));
  }
}

Future<void> _confirmBlock(
  BuildContext context,
  DeviceSessionEntity session,
  DevicesCubit cubit,
  AppLocalizations l10n,
) async {
  final isBlocking = !session.isBlocked;
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: isBlocking ? l10n.t('blockDeviceTitle') : l10n.t('unblockDeviceTitle'),
    message: isBlocking ? l10n.t('blockDeviceMsg') : l10n.t('unblockDeviceMsg'),
    confirmLabel: isBlocking ? l10n.t('blockDevice') : l10n.t('unblock'),
    isDestructive: isBlocking,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.blockDevice(session.id);
  if (context.mounted) {
    ok
        ? AppSnackbar.success(
            context,
            isBlocking
                ? l10n.t('deviceBlocked')
                : l10n.t('deviceUnblocked'),
          )
        : AppSnackbar.error(context, l10n.t('actionFailed'));
  }
}

Future<void> _confirmLogoutAll(
  BuildContext context,
  DevicesCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('logoutAllDevicesTitle'),
    message: l10n.t('logoutAllDevicesMsg'),
    confirmLabel: l10n.t('logoutAllDevices'),
    isDestructive: true,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.logoutAll();
  if (context.mounted) {
    ok
        ? AppSnackbar.success(context, l10n.t('allDevicesLoggedOut'))
        : AppSnackbar.error(context, l10n.t('actionFailed'));
  }
}
