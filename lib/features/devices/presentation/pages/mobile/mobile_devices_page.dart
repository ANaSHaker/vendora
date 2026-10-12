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

class MobileDevicesPage extends StatelessWidget {
  const MobileDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DevicesCubit(
        getSessions: getIt<GetDeviceSessionsUseCase>(),
        logoutDevice: getIt<LogoutDeviceUseCase>(),
        logoutAll: getIt<LogoutAllDevicesUseCase>(),
        blockDevice: getIt<BlockDeviceUseCase>(),
      )..load(),
      child: const _MobileContent(),
    );
  }
}

class _MobileContent extends StatelessWidget {
  const _MobileContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesCubit, DevicesState>(
      builder: (context, state) {
        final cubit = context.read<DevicesCubit>();
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(l10n.t('deviceSessionsTitle'),
                style: AppTextStyles.h6),
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20),
                tooltip: l10n.t('logoutAllDevices'),
                onPressed: () => _confirmLogoutAll(context, cubit, l10n),
              ),
            ],
          ),
          body: switch (state) {
            DevicesInitial() || DevicesLoading() => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ShimmerBox(height: 120),
                ),
              ),
            DevicesError(:final message) => AppErrorWidget(
                message: message,
                onRetry: cubit.load,
              ),
            DevicesLoaded(:final sessions) when sessions.isEmpty =>
              AppEmptyState(
                icon: const Icon(Icons.devices_outlined, size: 40),
                message: l10n.t('noDeviceSessions'),
              ),
            DevicesLoaded(:final sessions) => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _DeviceCard(
                  session: sessions[i],
                  l10n: l10n,
                  onLogout: () =>
                      _confirmLogout(context, sessions[i], cubit, l10n),
                  onBlock: () =>
                      _confirmBlock(context, sessions[i], cubit, l10n),
                ),
              ),
          },
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceSessionEntity session;
  final AppLocalizations l10n;
  final VoidCallback onLogout;
  final VoidCallback onBlock;

  const _DeviceCard({
    required this.session,
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
      final amPm = dt.hour < 12 ? 'ص' : 'م';
      final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$y/$mo/$d $h12:$mi $amPm';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = session.isCurrent;
    final currentBg = AppColors.primary.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrent ? currentBg : AppColors.surface,
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: device + status
          Row(
            children: [
              const Icon(Icons.computer_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  session.device.isNotEmpty
                      ? session.device
                      : l10n.t('unknownDevice'),
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrent)
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                session.isBlocked
                    ? StatusBadge.custom(
                        label: l10n.t('statusBlocked'),
                        color: AppColors.destructive,
                        bgColor:
                            AppColors.destructive.withValues(alpha: 0.1),
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
            ],
          ),

          if (session.userAgent.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              session.userAgent,
              style: AppTextStyles.bodyXs
                  .copyWith(color: AppColors.mutedForeground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),

          // Meta info grid
          _MetaRow(
            icon: Icons.person_outline,
            label:
                '${session.userName} · ${session.userEmail}',
          ),
          const SizedBox(height: AppSpacing.xs),
          _MetaRow(
            icon: Icons.location_on_outlined,
            label: session.location.isNotEmpty
                ? session.location
                : '—',
          ),
          const SizedBox(height: AppSpacing.xs),
          _MetaRow(
            icon: Icons.wifi_outlined,
            label: session.ipAddress.isNotEmpty
                ? session.ipAddress
                : '—',
            isMonospace: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          _MetaRow(
            icon: Icons.access_time_outlined,
            label: session.lastLoginAt.isNotEmpty
                ? _fmtDate(session.lastLoginAt)
                : '—',
          ),

          if (!isCurrent) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    label: l10n.t('logoutThisDevice'),
                    size: AppButtonSize.sm,
                    leading:
                        const Icon(Icons.logout_rounded, size: 14),
                    onPressed: onLogout,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton.outline(
                  label: session.isBlocked
                      ? l10n.t('unblock')
                      : l10n.t('blockDevice'),
                  size: AppButtonSize.sm,
                  leading: Icon(
                    session.isBlocked
                        ? Icons.lock_open_outlined
                        : Icons.block_outlined,
                    size: 14,
                  ),
                  onPressed: onBlock,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isMonospace;

  const _MetaRow({
    required this.icon,
    required this.label,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.mutedForeground),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: (isMonospace
                    ? AppTextStyles.numeric
                    : AppTextStyles.bodyXs)
                .copyWith(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    title: isBlocking
        ? l10n.t('blockDeviceTitle')
        : l10n.t('unblockDeviceTitle'),
    message: isBlocking
        ? l10n.t('blockDeviceMsg')
        : l10n.t('unblockDeviceMsg'),
    confirmLabel:
        isBlocking ? l10n.t('blockDevice') : l10n.t('unblock'),
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
