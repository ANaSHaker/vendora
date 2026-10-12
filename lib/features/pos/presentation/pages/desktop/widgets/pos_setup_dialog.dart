import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../cubit/pos_cubit.dart';
import '../../../cubit/pos_state.dart';
import '../../../../domain/entities/pos_entities.dart';

class PosSetupOverlay extends StatelessWidget {
  const PosSetupOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosCubit, PosState>(
      builder: (context, state) {
        if (state.isReady) return const SizedBox.shrink();

        return _Overlay(state: state);
      },
    );
  }
}

class _Overlay extends StatelessWidget {
  final PosState state;
  const _Overlay({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = Colors.black.withValues(alpha: isDark ? 0.65 : 0.45);

    return ColoredBox(
      color: overlayColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: switch (state.setupStep) {
            PosSetupStep.idle => const _ErrorCard(),
            PosSetupStep.loadingBranches ||
            PosSetupStep.loadingWarehouses => const _LoadingCard(),
            PosSetupStep.selectBranch => _BranchCard(branches: state.branches),
            PosSetupStep.selectWarehouse => _WarehouseCard(
                branch: state.selectedBranch,
                warehouses: state.warehouses,
              ),
            PosSetupStep.ready => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

// ─── Shared card shell ────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: cs.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onBack;

  const _CardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Vendora',
                style: AppTextStyles.labelMd.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (onBack != null)
                InkWell(
                  onTap: onBack,
                  borderRadius: AppRadius.brMd,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // Step icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: AppRadius.brLg,
            ),
            child: Icon(icon, size: 24, color: cs.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.h5.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodySm.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: cs.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.loading,
              style: AppTextStyles.bodySm.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error / Retry ────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: AppRadius.brLg,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 24,
                color: cs.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.failedToLoadBranches,
              style: AppTextStyles.h5.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.checkConnectionRetry,
              style: AppTextStyles.bodySm.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.read<PosCubit>().initialize(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.retry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Branch selection ─────────────────────────────────────────────────────────

class _BranchCard extends StatelessWidget {
  final List<BranchEntity> branches;
  const _BranchCard({required this.branches});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.selectBranch,
            subtitle: l10n.selectBranchSubtitle,
            icon: Icons.account_balance_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              children: branches
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _BranchTile(branch: b),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final BranchEntity branch;
  const _BranchTile({required this.branch});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => context.read<PosCubit>().selectBranch(branch),
      borderRadius: AppRadius.brLg,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: AppRadius.brLg,
          color: cs.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(
                Icons.store_rounded,
                size: 20,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                branch.name,
                style: AppTextStyles.labelMd.copyWith(color: cs.onSurface),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Warehouse selection ──────────────────────────────────────────────────────

class _WarehouseCard extends StatelessWidget {
  final BranchEntity? branch;
  final List<WarehouseEntity> warehouses;

  const _WarehouseCard({required this.branch, required this.warehouses});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEmpty = warehouses.isEmpty;

    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: isEmpty ? l10n.noWarehouses : l10n.selectWarehouse,
            subtitle: isEmpty
                ? l10n.noWarehousesSubtitle
                : branch != null
                    ? '${l10n.branches}: ${branch!.name}'
                    : l10n.selectWarehouseSubtitle,
            icon: isEmpty
                ? Icons.warehouse_outlined
                : Icons.warehouse_rounded,
            onBack: () => context.read<PosCubit>().switchBranch(),
          ),
          if (!isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Column(
                children: warehouses
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _WarehouseTile(warehouse: w),
                      ),
                    )
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: SizedBox(
              width: double.infinity,
              child: isEmpty
                  ? FilledButton.icon(
                      onPressed: () => context.read<PosCubit>().skipWarehouse(),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(l10n.continueWithoutWarehouse),
                    )
                  : OutlinedButton(
                      onPressed: () => context.read<PosCubit>().skipWarehouse(),
                      child: Text(l10n.continueWithoutWarehouse),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseTile extends StatelessWidget {
  final WarehouseEntity warehouse;
  const _WarehouseTile({required this.warehouse});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => context.read<PosCubit>().selectWarehouse(warehouse),
      borderRadius: AppRadius.brLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: AppRadius.brLg,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 20,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse.name,
                    style: AppTextStyles.labelMd.copyWith(color: cs.onSurface),
                  ),
                  if (warehouse.code != null)
                    Text(
                      warehouse.code!,
                      style: AppTextStyles.caption.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
