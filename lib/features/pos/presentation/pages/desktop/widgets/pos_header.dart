import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../cubit/pos_cubit.dart';
import '../../../cubit/pos_state.dart';

class PosHeader extends StatelessWidget implements PreferredSizeWidget {
  const PosHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            AppIconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/dashboard'),
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              tooltip: l10n.back,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.pointOfSale, style: AppTextStyles.h6),
            const SizedBox(width: AppSpacing.md),
            BlocBuilder<PosCubit, PosState>(
              buildWhen: (p, c) =>
                  p.selectedBranch != c.selectedBranch ||
                  p.selectedWarehouse != c.selectedWarehouse,
              builder: (_, state) {
                if (state.selectedBranch == null) return const SizedBox.shrink();
                return _BranchWarehouseChip(state: state);
              },
            ),
            const Spacer(),
            // Online/Offline indicator
            const _ConnectivityIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ConnectivityIndicator extends StatelessWidget {
  const _ConnectivityIndicator();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data;
        final isOnline = results == null ||
            results.any((r) => r != ConnectivityResult.none);
        final l10n = AppLocalizations.of(context);
        final color = isOnline ? AppColors.success : AppColors.destructive;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppRadius.brFull,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isOnline ? l10n.online : l10n.offline,
                style: AppTextStyles.labelXs.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BranchWarehouseChip extends StatelessWidget {
  final PosState state;
  const _BranchWarehouseChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final branchName = state.selectedBranch!.name;
    final warehouseName = state.selectedWarehouse?.displayName;

    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brXl,
        side: BorderSide(color: cs.outline),
      ),
      elevation: 8,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 200),
      onSelected: (value) {
        if (value == 'branch') context.read<PosCubit>().switchBranch();
        if (value == 'warehouse') context.read<PosCubit>().switchWarehouse();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'branch',
          child: Row(
            children: [
              Icon(Icons.store_rounded, size: 16, color: cs.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.switchBranch,
                style: AppTextStyles.labelSm.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
        if (state.warehouses.isNotEmpty)
          PopupMenuItem<String>(
            value: 'warehouse',
            child: Row(
              children: [
                Icon(Icons.inventory_2_rounded, size: 16, color: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.switchWarehouse,
                  style: AppTextStyles.labelSm.copyWith(color: cs.onSurface),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: AppRadius.brFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined, size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              warehouseName != null
                  ? '$branchName · $warehouseName'
                  : branchName,
              style: AppTextStyles.bodyXs.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
