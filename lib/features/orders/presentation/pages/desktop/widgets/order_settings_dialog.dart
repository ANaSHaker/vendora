import 'package:flutter/material.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/api/api_endpoints.dart';
import '../../../../../../core/di/injection.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../core/storage/local_storage.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../../design_system/widgets/inputs/app_select_field.dart';

class OrderSettingsDialog extends StatefulWidget {
  const OrderSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const OrderSettingsDialog(),
    );
  }

  @override
  State<OrderSettingsDialog> createState() => _OrderSettingsDialogState();
}

class _OrderSettingsDialogState extends State<OrderSettingsDialog> {
  String? _selected;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentSetting();
  }

  static const _validStatuses = {'preparing', 'ready', 'completed', 'cancelled'};

  static String? _sanitize(String? v) =>
      (v != null && _validStatuses.contains(v)) ? v : 'preparing';

  Future<void> _fetchCurrentSetting() async {
    final cached = getIt<LocalStorage>().posDefaultStatus;
    setState(() => _selected = _sanitize(cached));

    try {
      final response = await getIt<ApiClient>().get<Map<String, dynamic>>(
        ApiEndpoints.vendorSettings,
      );
      final body = response.data!;
      final data = body.containsKey('data')
          ? body['data'] as Map<String, dynamic>
          : body;
      final remote =
          data['default_order_status'] as String? ??
          data['pos_default_status'] as String?;
      if (remote != null && remote.isNotEmpty && mounted) {
        setState(() {
          _selected = _sanitize(remote);
          _loading = false;
        });
        // Sync to local cache
        await getIt<LocalStorage>().savePosDefaultStatus(remote);
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      await getIt<ApiClient>().put<Map<String, dynamic>>(
        ApiEndpoints.vendorSettings,
        data: {'default_order_status': _selected},
      );
      await getIt<LocalStorage>().savePosDefaultStatus(_selected!);
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(context, AppLocalizations.of(context).success);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.error(context, AppLocalizations.of(context).error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final statusOptions = [
      AppSelectOption(value: 'preparing', label: l10n.fulfillPreparing),
      AppSelectOption(value: 'ready',     label: l10n.fulfillReady),
      AppSelectOption(value: 'completed', label: l10n.fulfillCompleted),
      AppSelectOption(value: 'cancelled', label: l10n.fulfillCancelled),
    ];

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.orderSettings,
                          style: AppTextStyles.h6.copyWith(color: fg),
                        ),
                        Text(
                          l10n.defaultOrderStatusHint,
                          style: AppTextStyles.bodyXs.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: muted),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Divider(height: AppSpacing.xl, color: border),

              // Status dropdown
              Text(
                l10n.defaultOrderStatus,
                style: AppTextStyles.labelSm.copyWith(color: fg),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.defaultOrderStatusHint,
                style: AppTextStyles.bodyXs.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (_loading)
                const ShimmerBox(height: 44)
              else
                AppSelectField<String>(
                  value: _selected,
                  options: statusOptions,
                  onChanged: (v) {
                    if (v != null) setState(() => _selected = v);
                  },
                ),

              // Status preview badges
              if (!_loading && _selected != null) ...[
                const SizedBox(height: AppSpacing.md),
                _StatusPreview(status: _selected!, l10n: l10n, border: border),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    label: l10n.cancel,
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.primary(
                    label: l10n.save,
                    isLoading: _saving,
                    onPressed: (_saving || _loading) ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPreview extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  final Color border;

  const _StatusPreview({
    required this.status,
    required this.l10n,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final (color, bg, label) = switch (status) {
      'preparing' => (AppColors.statusPending,   AppColors.statusPendingBg,   l10n.fulfillPreparing),
      'ready'     => (AppColors.statusApproved,  AppColors.statusApprovedBg,  l10n.fulfillReady),
      'completed' => (AppColors.statusCompleted, AppColors.statusCompletedBg, l10n.fulfillCompleted),
      'cancelled' => (AppColors.statusCancelled, AppColors.statusCancelledBg, l10n.fulfillCancelled),
      _ => (AppColors.statusDraft, AppColors.statusDraftBg, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: muted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.defaultOrderStatusHint,
              style: AppTextStyles.bodyXs.copyWith(color: muted),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.brFull,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
