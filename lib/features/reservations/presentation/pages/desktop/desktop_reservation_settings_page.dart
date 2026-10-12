import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../domain/entities/reservation_entity.dart';
import '../../cubit/reservations_cubit.dart';
import '../../cubit/reservations_state.dart';
import '../../widgets/booking_link_card.dart';

Color _surfaceOf(bool isDark) =>
    isDark ? AppColors.darkSurface : AppColors.surface;
Color _borderOf(bool isDark) =>
    isDark ? AppColors.darkBorder : AppColors.border;
Color _fgOf(bool isDark) =>
    isDark ? AppColors.darkForeground : AppColors.foreground;
Color _mutedOf(bool isDark) =>
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

class DesktopReservationSettingsPage extends StatelessWidget {
  const DesktopReservationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReservationSettingsCubit(
        getSettings: getIt(),
        saveSettings: getIt(),
        createException: getIt(),
        deleteException: getIt(),
      )..load(),
      child: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent();

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final border = _borderOf(isDark);
    final cs = Theme.of(context).colorScheme;

    return BlocListener<ReservationSettingsCubit, ReservationSettingsState>(
      listener: (ctx, state) {
        if (state is ReservationSettingsLoaded) {
          if (state.saveSuccess) AppSnackbar.success(ctx, l10n.success);
          if (state.saveError != null) AppSnackbar.error(ctx, state.saveError!);
        }
      },
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.desktopContentPadding,
                AppSizes.desktopContentPadding,
                AppSizes.desktopContentPadding,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.reservationSettings,
                      style: AppTextStyles.h4.copyWith(color: fg)),
                  Text(l10n.reservationSettingsSubtitle,
                      style: AppTextStyles.bodySm.copyWith(color: muted)),
                ],
              ),
            ),
            // Booking link card
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.desktopContentPadding,
                0,
                AppSizes.desktopContentPadding,
                0,
              ),
              child: BookingLinkCard(localStorage: getIt<LocalStorage>()),
            ),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.desktopContentPadding),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: cs.primary,
                unselectedLabelColor: muted,
                labelStyle:
                    AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.labelSm,
                indicatorColor: cs.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: l10n.tabGeneral),
                  Tab(text: l10n.tabAvailability),
                  Tab(text: l10n.tabPeriods),
                  Tab(text: l10n.tabAppearance),
                  Tab(text: l10n.tabAdvanced),
                ],
              ),
            ),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _GeneralTab(),
                  _AvailabilityTab(),
                  _PeriodsTab(),
                  _ComingSoonTab(),
                  _ComingSoonTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared loading / error / shimmer wrapper ─────────────────────────────────

Widget _settingsTabWrapper({
  required BuildContext context,
  required ReservationSettingsState state,
  required ReservationSettingsCubit cubit,
  required Widget Function(ReservationSettingsLoaded loaded) builder,
}) {
  if (state is ReservationSettingsLoading || state is ReservationSettingsInitial) {
    return const Padding(
      padding: EdgeInsets.all(AppSizes.desktopContentPadding),
      child: Column(children: [
        ShimmerBox(height: 72),
        SizedBox(height: AppSpacing.sm),
        ShimmerBox(height: 72),
        SizedBox(height: AppSpacing.sm),
        ShimmerBox(height: 72),
      ]),
    );
  }
  if (state is ReservationSettingsError) {
    return AppErrorWidget(message: state.message, onRetry: cubit.load);
  }
  if (state is! ReservationSettingsLoaded) return const SizedBox.shrink();
  return builder(state);
}

// ─── General Tab ──────────────────────────────────────────────────────────────

class _GeneralTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationSettingsCubit, ReservationSettingsState>(
      builder: (context, state) {
        final cubit = context.read<ReservationSettingsCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return _settingsTabWrapper(
          context: context,
          state: state,
          cubit: cubit,
          builder: (loaded) {
            final s = loaded.settings;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsCard(
                      isDark: isDark,
                      children: [
                        _ToggleRow(
                          title: l10n.enableReservations,
                          subtitle: l10n.enableReservationsDesc,
                          value: s.isEnabled,
                          onChanged: (_) => cubit.toggleEnabled(),
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _ToggleRow(
                          title: l10n.autoConfirmRes,
                          subtitle: l10n.autoConfirmResDesc,
                          value: s.autoConfirm,
                          onChanged: (_) => cubit.toggleAutoConfirm(),
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _ToggleRow(
                          title: l10n.allowCancellationRes,
                          subtitle: l10n.allowCancellationResDesc,
                          value: s.allowCancellation,
                          onChanged: (_) => cubit.toggleAllowCancellation(),
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _ToggleRow(
                          title: l10n.requirePhoneRes,
                          subtitle: l10n.requirePhoneResDesc,
                          value: s.requirePhone,
                          onChanged: (_) => cubit.toggleRequirePhone(),
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _ToggleRow(
                          title: l10n.requireEmailRes,
                          subtitle: l10n.requireEmailResDesc,
                          value: s.requireEmail,
                          onChanged: (_) => cubit.toggleRequireEmail(),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: l10n.saveChanges,
                      isLoading: loaded.isSaving,
                      onPressed: loaded.isSaving ? null : cubit.save,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Periods Tab ──────────────────────────────────────────────────────────────

class _PeriodsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationSettingsCubit, ReservationSettingsState>(
      builder: (context, state) {
        final cubit = context.read<ReservationSettingsCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final muted = _mutedOf(isDark);
        final fg = _fgOf(isDark);

        return _settingsTabWrapper(
          context: context,
          state: state,
          cubit: cubit,
          builder: (loaded) {
            final s = loaded.settings;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsCard(
                      isDark: isDark,
                      children: [
                        // Slot duration
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.slotDuration,
                                  style: AppTextStyles.labelMd.copyWith(
                                      color: fg, fontWeight: FontWeight.w600)),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [15, 30, 60].map((min) {
                                  final isSelected = s.slotDuration == min;
                                  final cs = Theme.of(context).colorScheme;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        right: AppSpacing.sm),
                                    child: GestureDetector(
                                      onTap: () =>
                                          cubit.setSlotDuration(min),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? cs.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? cs.primary
                                                : _borderOf(isDark),
                                          ),
                                          borderRadius: AppRadius.brMd,
                                        ),
                                        child: Text(
                                          min == 15
                                              ? l10n.slotDuration15
                                              : min == 30
                                                  ? l10n.slotDuration30
                                                  : l10n.slotDuration60,
                                          style: AppTextStyles.labelSm.copyWith(
                                            color: isSelected
                                                ? Colors.white
                                                : muted,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        _Divider(isDark: isDark),
                        // Buffer time
                        _NumberInputRow(
                          title: l10n.bufferTime,
                          hint: l10n.bufferTimeHint,
                          value: s.bufferTime,
                          onChanged: cubit.setBufferTime,
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        // Min advance hours
                        _NumberInputRow(
                          title: l10n.minAdvanceHours,
                          hint: l10n.minAdvanceHoursHint,
                          value: s.minAdvanceHours,
                          onChanged: cubit.setMinAdvanceHours,
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        // Max advance days
                        _NumberInputRow(
                          title: l10n.maxAdvanceDays,
                          hint: l10n.maxAdvanceDaysHint,
                          value: s.maxAdvanceDays,
                          onChanged: cubit.setMaxAdvanceDays,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: l10n.saveChanges,
                      isLoading: loaded.isSaving,
                      onPressed: loaded.isSaving ? null : cubit.save,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Availability Tab ─────────────────────────────────────────────────────────

class _AvailabilityTab extends StatelessWidget {
  static const List<String> _dayKeys = [
    'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
  ];

  String _dayLabel(AppLocalizations l10n, String day) => switch (day) {
        'sunday'    => l10n.daySunday,
        'monday'    => l10n.dayMonday,
        'tuesday'   => l10n.dayTuesday,
        'wednesday' => l10n.dayWednesday,
        'thursday'  => l10n.dayThursday,
        'friday'    => l10n.dayFriday,
        'saturday'  => l10n.daySaturday,
        _           => day,
      };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationSettingsCubit, ReservationSettingsState>(
      builder: (context, state) {
        final cubit = context.read<ReservationSettingsCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final muted = _mutedOf(isDark);
        final fg = _fgOf(isDark);

        return _settingsTabWrapper(
          context: context,
          state: state,
          cubit: cubit,
          builder: (loaded) {
            final schedule = loaded.settings.weeklySchedule;
            // Ensure we have 7 days in order
            final ordered = _dayKeys.map((key) {
              final idx = schedule.indexWhere((d) => d.day == key);
              return idx >= 0 ? schedule[idx] : DayScheduleEntity(
                day: key, isOpen: key != 'friday',
                openTime: '09:00', closeTime: '22:00', maxGuests: 20,
              );
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.availabilityHint,
                        style: AppTextStyles.bodySm.copyWith(color: muted)),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsCard(
                      isDark: isDark,
                      children: List.generate(ordered.length, (i) {
                        final day = ordered[i];
                        final isLast = i == ordered.length - 1;
                        return Column(
                          children: [
                            _DayRow(
                              day: day,
                              label: _dayLabel(l10n, day.day),
                              isDark: isDark,
                              l10n: l10n,
                              fg: fg,
                              muted: muted,
                              onToggle: (v) =>
                                  cubit.updateDaySchedule(day.copyWith(isOpen: v)),
                              onOpenTimeChanged: (t) =>
                                  cubit.updateDaySchedule(day.copyWith(openTime: t)),
                              onCloseTimeChanged: (t) =>
                                  cubit.updateDaySchedule(day.copyWith(closeTime: t)),
                              onMaxGuestsChanged: (g) =>
                                  cubit.updateDaySchedule(day.copyWith(maxGuests: g)),
                            ),
                            if (!isLast) _Divider(isDark: isDark),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: l10n.saveChanges,
                      isLoading: loaded.isSaving,
                      onPressed: loaded.isSaving ? null : cubit.save,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ExceptionsSection(
                      exceptions: loaded.settings.exceptions,
                      isDark: isDark,
                      l10n: l10n,
                      fg: fg,
                      muted: muted,
                      cubit: cubit,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Exceptions Section ───────────────────────────────────────────────────────

class _ExceptionsSection extends StatelessWidget {
  final List<ReservationExceptionEntity> exceptions;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;
  final ReservationSettingsCubit cubit;

  const _ExceptionsSection({
    required this.exceptions,
    required this.isDark,
    required this.l10n,
    required this.fg,
    required this.muted,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy', 'en_US');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.closureDaysExceptions,
                    style: AppTextStyles.labelLg.copyWith(
                        color: fg, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.closureDaysExceptionsHint,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _showAddExceptionDialog(context, cubit, l10n, isDark),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(l10n.addException),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                textStyle: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // List or empty state
        if (exceptions.isEmpty)
          _SettingsCard(
            isDark: isDark,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text(
                    l10n.noExceptions,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
                ),
              ),
            ],
          )
        else
          _SettingsCard(
            isDark: isDark,
            children: List.generate(exceptions.length, (i) {
              final ex = exceptions[i];
              final isLast = i == exceptions.length - 1;
              return Column(
                children: [
                  _ExceptionRow(
                    exception: ex,
                    dateFmt: dateFmt,
                    isDark: isDark,
                    fg: fg,
                    muted: muted,
                    l10n: l10n,
                    onDelete: () async {
                      final err = await cubit.deleteException(ex.id);
                      if (err != null && context.mounted) {
                        AppSnackbar.error(context, err);
                      }
                    },
                  ),
                  if (!isLast) _Divider(isDark: isDark),
                ],
              );
            }),
          ),
      ],
    );
  }

  Future<void> _showAddExceptionDialog(
    BuildContext context,
    ReservationSettingsCubit cubit,
    AppLocalizations l10n,
    bool isDark,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AddExceptionDialog(l10n: l10n, isDark: isDark),
    );
    if (result != null && context.mounted) {
      final err = await cubit.createException(result);
      if (err != null && context.mounted) {
        AppSnackbar.error(context, err);
      }
    }
  }
}

class _ExceptionRow extends StatelessWidget {
  final ReservationExceptionEntity exception;
  final DateFormat dateFmt;
  final bool isDark;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final VoidCallback onDelete;

  const _ExceptionRow({
    required this.exception,
    required this.dateFmt,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            exception.isClosed
                ? Icons.block_rounded
                : Icons.schedule_rounded,
            size: 18,
            color: exception.isClosed ? cs.error : cs.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFmt.format(exception.date),
                  style: AppTextStyles.labelSm.copyWith(
                      color: fg, fontWeight: FontWeight.w600),
                ),
                if (exception.reason != null && exception.reason!.isNotEmpty)
                  Text(
                    exception.reason!,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (exception.isClosed ? cs.error : cs.primary).withValues(alpha: 0.1),
              borderRadius: AppRadius.brSm,
            ),
            child: Text(
              exception.isClosed
                  ? l10n.closedAllDay
                  : '${exception.openTime ?? ''} - ${exception.closeTime ?? ''}',
              style: AppTextStyles.bodyXs.copyWith(
                color: exception.isClosed ? cs.error : cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: cs.error),
            tooltip: l10n.delete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AddExceptionDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _AddExceptionDialog({required this.l10n, required this.isDark});

  @override
  State<_AddExceptionDialog> createState() => _AddExceptionDialogState();
}

class _AddExceptionDialogState extends State<_AddExceptionDialog> {
  DateTime? _selectedDate;
  bool _isClosed = true;
  String _openTime = '09:00';
  String _closeTime = '22:00';
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isOpen) async {
    final parts = (isOpen ? _openTime : _closeTime).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 9,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpen) { _openTime = formatted; }
        else { _closeTime = formatted; }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = widget.isDark;
    final cs = Theme.of(context).colorScheme;
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final border = _borderOf(isDark);
    final dateFmt = DateFormat('dd MMM yyyy', 'en_US');

    return AlertDialog(
      backgroundColor: _surfaceOf(isDark),
      title: Text(l10n.addException,
          style: AppTextStyles.labelLg.copyWith(
              color: fg, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            Text(l10n.exceptionDate,
                style: AppTextStyles.labelSm.copyWith(
                    color: fg, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                  borderRadius: AppRadius.brMd,
                  color: _surfaceOf(isDark),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16, color: muted),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _selectedDate != null
                          ? dateFmt.format(_selectedDate!)
                          : l10n.exceptionDate,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: _selectedDate != null ? fg : muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Closed all day toggle
            Row(
              children: [
                Expanded(
                  child: Text(l10n.closedAllDay,
                      style: AppTextStyles.labelSm.copyWith(
                          color: fg, fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _isClosed,
                  onChanged: (v) => setState(() => _isClosed = v),
                  activeTrackColor: cs.primary,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
            // Custom hours (only when not closed)
            if (!_isClosed) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.customHours,
                  style: AppTextStyles.labelSm.copyWith(
                      color: fg, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          border: Border.all(color: border),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14, color: muted),
                            const SizedBox(width: 4),
                            Text(_openTime,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: fg)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: Text('—',
                        style: TextStyle(color: muted)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          border: Border.all(color: border),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14, color: muted),
                            const SizedBox(width: 4),
                            Text(_closeTime,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: fg)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // Reason
            Text(l10n.exceptionReason,
                style: AppTextStyles.labelSm.copyWith(
                    color: fg, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _reasonCtrl,
              style: AppTextStyles.bodyMd.copyWith(color: fg),
              decoration: InputDecoration(
                hintText: l10n.exceptionReason,
                hintStyle: AppTextStyles.bodyMd.copyWith(color: muted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                border: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide(color: cs.primary)),
                filled: true,
                fillColor: _surfaceOf(isDark),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel,
              style: TextStyle(color: muted)),
        ),
        AppButton.primary(
          label: l10n.addException,
          onPressed: _selectedDate == null
              ? null
              : () {
                  Navigator.pop(context, {
                    'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                    'is_closed': _isClosed,
                    if (!_isClosed) 'open_time': _openTime,
                    if (!_isClosed) 'close_time': _closeTime,
                    if (_reasonCtrl.text.isNotEmpty) 'reason': _reasonCtrl.text,
                  });
                },
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final DayScheduleEntity day;
  final String label;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onOpenTimeChanged;
  final ValueChanged<String> onCloseTimeChanged;
  final ValueChanged<int> onMaxGuestsChanged;

  const _DayRow({
    required this.day,
    required this.label,
    required this.isDark,
    required this.l10n,
    required this.fg,
    required this.muted,
    required this.onToggle,
    required this.onOpenTimeChanged,
    required this.onCloseTimeChanged,
    required this.onMaxGuestsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 96,
            child: Text(label,
                style: AppTextStyles.labelSm.copyWith(
                    color: fg, fontWeight: FontWeight.w600)),
          ),
          // Toggle
          Switch(
            value: day.isOpen,
            onChanged: onToggle,
            activeTrackColor: cs.primary,
            activeThumbColor: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          if (day.isOpen) ...[
            // Open time
            _TimeInput(
              label: l10n.openTime,
              value: day.openTime,
              isDark: isDark,
              onChanged: onOpenTimeChanged,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('—', style: TextStyle(color: muted)),
            const SizedBox(width: AppSpacing.sm),
            // Close time
            _TimeInput(
              label: l10n.closeTime,
              value: day.closeTime,
              isDark: isDark,
              onChanged: onCloseTimeChanged,
            ),
            const SizedBox(width: AppSpacing.md),
            // Max guests
            SizedBox(
              width: 80,
              child: _SmallNumberInput(
                label: l10n.maxGuestsPerSlot,
                value: day.maxGuests,
                isDark: isDark,
                onChanged: onMaxGuestsChanged,
              ),
            ),
          ] else
            Text(l10n.dayClosed,
                style: AppTextStyles.bodySm.copyWith(color: muted)),
        ],
      ),
    );
  }
}

class _TimeInput extends StatefulWidget {
  final String label;
  final String value;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _TimeInput({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_TimeInput> createState() => _TimeInputState();
}

class _TimeInputState extends State<_TimeInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TimeInput old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value &&
        _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = widget.value.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 9,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _controller.text = formatted;
      widget.onChanged(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: GestureDetector(
        onTap: _pickTime,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 6),
          decoration: BoxDecoration(
            color: _surfaceOf(widget.isDark),
            border: Border.all(color: _borderOf(widget.isDark)),
            borderRadius: AppRadius.brSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14,
                  color: _mutedOf(widget.isDark)),
              const SizedBox(width: 4),
              Text(
                _controller.text,
                style: AppTextStyles.bodySm
                    .copyWith(color: _fgOf(widget.isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallNumberInput extends StatefulWidget {
  final String label;
  final int value;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _SmallNumberInput({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_SmallNumberInput> createState() => _SmallNumberInputState();
}

class _SmallNumberInputState extends State<_SmallNumberInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_SmallNumberInput old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value &&
        _ctrl.text != widget.value.toString()) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySm.copyWith(color: _fgOf(widget.isDark)),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: AppTextStyles.bodyXs.copyWith(color: _mutedOf(widget.isDark)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: _borderOf(widget.isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: _borderOf(widget.isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary),
        ),
        filled: true,
        fillColor: _surfaceOf(widget.isDark),
      ),
      onChanged: (v) {
        final n = int.tryParse(v);
        if (n != null) widget.onChanged(n);
      },
    );
  }
}

// ─── Number Input Row (for periods) ──────────────────────────────────────────

class _NumberInputRow extends StatefulWidget {
  final String title;
  final String hint;
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _NumberInputRow({
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  State<_NumberInputRow> createState() => _NumberInputRowState();
}

class _NumberInputRowState extends State<_NumberInputRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_NumberInputRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value &&
        _ctrl.text != widget.value.toString()) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fgOf(widget.isDark);
    final muted = _mutedOf(widget.isDark);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: AppTextStyles.labelMd.copyWith(
                        color: fg, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(widget.hint,
                    style: AppTextStyles.bodySm.copyWith(color: muted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: fg),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide(color: _borderOf(widget.isDark)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide(color: _borderOf(widget.isDark)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide(color: cs.primary),
                ),
                filled: true,
                fillColor: _surfaceOf(widget.isDark),
              ),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null) widget.onChanged(n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surfaceOf(isDark),
        border: Border.all(color: _borderOf(isDark)),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.labelMd.copyWith(
                        color: fg, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.bodySm.copyWith(color: muted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: cs.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: _borderOf(isDark));
}

// ─── Coming Soon Tab ──────────────────────────────────────────────────────────

class _ComingSoonTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = _mutedOf(isDark);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded, size: 48, color: muted),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.comingSoon,
              style: AppTextStyles.h5.copyWith(color: muted)),
        ],
      ),
    );
  }
}
