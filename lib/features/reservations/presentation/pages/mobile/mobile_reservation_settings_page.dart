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

Color _fgOf(bool isDark) =>
    isDark ? AppColors.darkForeground : AppColors.foreground;
Color _mutedOf(bool isDark) =>
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
Color _borderOf(bool isDark) =>
    isDark ? AppColors.darkBorder : AppColors.border;
Color _surfaceOf(bool isDark) =>
    isDark ? AppColors.darkSurface : AppColors.surface;

class MobileReservationSettingsPage extends StatelessWidget {
  const MobileReservationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReservationSettingsCubit(
        getSettings: getIt(),
        saveSettings: getIt(),
        createException: getIt(),
        deleteException: getIt(),
      )..load(),
      child: const _MobileSettingsContent(),
    );
  }
}

class _MobileSettingsContent extends StatefulWidget {
  const _MobileSettingsContent();

  @override
  State<_MobileSettingsContent> createState() => _MobileSettingsContentState();
}

class _MobileSettingsContentState extends State<_MobileSettingsContent>
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
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final cs = Theme.of(context).colorScheme;
    final muted = _mutedOf(isDark);

    return BlocListener<ReservationSettingsCubit, ReservationSettingsState>(
      listener: (context, state) {
        if (state is ReservationSettingsLoaded) {
          if (state.saveSuccess) AppSnackbar.success(context, l10n.success);
          if (state.saveError != null) AppSnackbar.error(context, state.saveError!);
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(l10n.reservationSettings),
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: cs.primary,
            unselectedLabelColor: muted,
            labelStyle: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.labelSm,
            indicatorColor: cs.primary,
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: BookingLinkCard(localStorage: getIt<LocalStorage>()),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MobileGeneralTab(),
                  _MobileAvailabilityTab(),
                  _MobilePeriodsTab(),
                  _MobileComingSoonTab(),
                  _MobileComingSoonTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper: wraps loading / error / content states ──────────────────────────

Widget _tabContent({
  required BuildContext context,
  required ReservationSettingsState state,
  required ReservationSettingsCubit cubit,
  required Widget Function(ReservationSettingsLoaded loaded) builder,
}) {
  if (state is ReservationSettingsLoading || state is ReservationSettingsInitial) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: ShimmerBox(height: 64),
      ),
    );
  }

  if (state is ReservationSettingsError) {
    return AppErrorWidget(message: state.message, onRetry: cubit.load);
  }

  if (state is! ReservationSettingsLoaded) return const SizedBox.shrink();

  return builder(state);
}

// ─── General Tab ─────────────────────────────────────────────────────────────

class _MobileGeneralTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationSettingsCubit, ReservationSettingsState>(
      builder: (context, state) {
        final cubit = context.read<ReservationSettingsCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return _tabContent(
          context: context,
          state: state,
          cubit: cubit,
          builder: (loaded) {
            final s = loaded.settings;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _MobileCard(
                    isDark: isDark,
                    children: [
                      _MobileToggleRow(
                        title: l10n.enableReservations,
                        subtitle: l10n.enableReservationsDesc,
                        value: s.isEnabled,
                        onChanged: (_) => cubit.toggleEnabled(),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _MobileToggleRow(
                        title: l10n.autoConfirmRes,
                        subtitle: l10n.autoConfirmResDesc,
                        value: s.autoConfirm,
                        onChanged: (_) => cubit.toggleAutoConfirm(),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _MobileToggleRow(
                        title: l10n.allowCancellationRes,
                        subtitle: l10n.allowCancellationResDesc,
                        value: s.allowCancellation,
                        onChanged: (_) => cubit.toggleAllowCancellation(),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _MobileToggleRow(
                        title: l10n.requirePhoneRes,
                        subtitle: l10n.requirePhoneResDesc,
                        value: s.requirePhone,
                        onChanged: (_) => cubit.toggleRequirePhone(),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _MobileToggleRow(
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
                    fullWidth: true,
                    onPressed: loaded.isSaving ? null : cubit.save,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Availability Tab ─────────────────────────────────────────────────────────

class _MobileAvailabilityTab extends StatelessWidget {
  static const List<String> _dayKeys = [
    'sunday', 'monday', 'tuesday', 'wednesday',
    'thursday', 'friday', 'saturday',
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

        return _tabContent(
          context: context,
          state: state,
          cubit: cubit,
          builder: (loaded) {
            final schedule = loaded.settings.weeklySchedule;
            final ordered = _dayKeys.map((key) {
              final idx = schedule.indexWhere((d) => d.day == key);
              return idx >= 0
                  ? schedule[idx]
                  : DayScheduleEntity(
                      day: key,
                      isOpen: key != 'friday',
                      openTime: '09:00',
                      closeTime: '22:00',
                      maxGuests: 20,
                    );
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.availabilityHint,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...List.generate(ordered.length, (i) {
                    final day = ordered[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _MobileDayCard(
                        day: day,
                        label: _dayLabel(l10n, day.day),
                        isDark: isDark,
                        l10n: l10n,
                        onToggle: (v) =>
                            cubit.updateDaySchedule(day.copyWith(isOpen: v)),
                        onOpenTimeChanged: (t) =>
                            cubit.updateDaySchedule(day.copyWith(openTime: t)),
                        onCloseTimeChanged: (t) =>
                            cubit.updateDaySchedule(day.copyWith(closeTime: t)),
                        onMaxGuestsChanged: (g) =>
                            cubit.updateDaySchedule(day.copyWith(maxGuests: g)),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.primary(
                    label: l10n.saveChanges,
                    isLoading: loaded.isSaving,
                    fullWidth: true,
                    onPressed: loaded.isSaving ? null : cubit.save,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _MobileExceptionsSection(
                    exceptions: loaded.settings.exceptions,
                    isDark: isDark,
                    l10n: l10n,
                    cubit: cubit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Mobile Exceptions Section ────────────────────────────────────────────────

class _MobileExceptionsSection extends StatelessWidget {
  final List<ReservationExceptionEntity> exceptions;
  final bool isDark;
  final AppLocalizations l10n;
  final ReservationSettingsCubit cubit;

  const _MobileExceptionsSection({
    required this.exceptions,
    required this.isDark,
    required this.l10n,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy', 'en_US');

    return Column(
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
        const SizedBox(height: AppSpacing.md),
        AppButton.outline(
          label: l10n.addException,
          fullWidth: true,
          onPressed: () => _showAddExceptionDialog(context),
        ),
        const SizedBox(height: AppSpacing.md),
        if (exceptions.isEmpty)
          _MobileCard(
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
          _MobileCard(
            isDark: isDark,
            children: List.generate(exceptions.length, (i) {
              final ex = exceptions[i];
              final isLast = i == exceptions.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      ex.isClosed
                          ? Icons.block_rounded
                          : Icons.schedule_rounded,
                      color: ex.isClosed ? cs.error : cs.primary,
                      size: 20,
                    ),
                    title: Text(
                      dateFmt.format(ex.date),
                      style: AppTextStyles.labelSm.copyWith(
                          color: fg, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      ex.isClosed
                          ? l10n.closedAllDay
                          : '${ex.openTime ?? ''} - ${ex.closeTime ?? ''}',
                      style: AppTextStyles.bodySm.copyWith(color: muted),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 18, color: cs.error),
                      onPressed: () async {
                        final err = await cubit.deleteException(ex.id);
                        if (err != null && context.mounted) {
                          AppSnackbar.error(context, err);
                        }
                      },
                    ),
                    dense: true,
                  ),
                  if (!isLast) _Divider(isDark: isDark),
                ],
              );
            }),
          ),
      ],
    );
  }

  Future<void> _showAddExceptionDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MobileAddExceptionDialog(l10n: l10n, isDark: isDark),
    );
    if (result != null && context.mounted) {
      final err = await cubit.createException(result);
      if (err != null && context.mounted) {
        AppSnackbar.error(context, err);
      }
    }
  }
}

class _MobileAddExceptionDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _MobileAddExceptionDialog({required this.l10n, required this.isDark});

  @override
  State<_MobileAddExceptionDialog> createState() =>
      _MobileAddExceptionDialogState();
}

class _MobileAddExceptionDialogState extends State<_MobileAddExceptionDialog> {
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
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final border = _borderOf(isDark);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy', 'en_US');

    return AlertDialog(
      backgroundColor: _surfaceOf(isDark),
      title: Text(l10n.addException,
          style: AppTextStyles.labelLg.copyWith(
              color: fg, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: muted),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _selectedDate != null
                          ? dateFmt.format(_selectedDate!)
                          : l10n.exceptionDate,
                      style: AppTextStyles.bodyMd.copyWith(
                          color: _selectedDate != null ? fg : muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.closedAllDay,
                      style: AppTextStyles.labelSm
                          .copyWith(color: fg, fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _isClosed,
                  onChanged: (v) => setState(() => _isClosed = v),
                  activeTrackColor: cs.primary,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
            if (!_isClosed) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(true),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          border: Border.all(color: border),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Text(_openTime,
                            style: AppTextStyles.bodyMd.copyWith(color: fg)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: Text('—', style: TextStyle(color: muted)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(false),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          border: Border.all(color: border),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Text(_closeTime,
                            style: AppTextStyles.bodyMd.copyWith(color: fg)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reasonCtrl,
              style: AppTextStyles.bodyMd.copyWith(color: fg),
              decoration: InputDecoration(
                labelText: l10n.exceptionReason,
                labelStyle: AppTextStyles.bodySm.copyWith(color: muted),
                isDense: true,
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
          child: Text(l10n.cancel, style: TextStyle(color: muted)),
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
                    if (_reasonCtrl.text.isNotEmpty)
                      'reason': _reasonCtrl.text,
                  });
                },
        ),
      ],
    );
  }
}

class _MobileDayCard extends StatelessWidget {
  final DayScheduleEntity day;
  final String label;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onOpenTimeChanged;
  final ValueChanged<String> onCloseTimeChanged;
  final ValueChanged<int> onMaxGuestsChanged;

  const _MobileDayCard({
    required this.day,
    required this.label,
    required this.isDark,
    required this.l10n,
    required this.onToggle,
    required this.onOpenTimeChanged,
    required this.onCloseTimeChanged,
    required this.onMaxGuestsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surfaceOf(isDark),
        border: Border.all(color: _borderOf(isDark)),
        borderRadius: AppRadius.brLg,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day name + toggle in same row
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.labelMd.copyWith(
                        color: fg, fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: day.isOpen,
                  onChanged: onToggle,
                  activeTrackColor: cs.primary,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
            if (day.isOpen) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  // Open time
                  Expanded(
                    child: _MobileTimeInput(
                      label: l10n.openTime,
                      value: day.openTime,
                      isDark: isDark,
                      onChanged: onOpenTimeChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: Text('—', style: TextStyle(color: muted)),
                  ),
                  // Close time
                  Expanded(
                    child: _MobileTimeInput(
                      label: l10n.closeTime,
                      value: day.closeTime,
                      isDark: isDark,
                      onChanged: onCloseTimeChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Max guests
                  SizedBox(
                    width: 72,
                    child: _MobileSmallNumberInput(
                      label: l10n.maxGuestsPerSlot,
                      value: day.maxGuests,
                      isDark: isDark,
                      onChanged: onMaxGuestsChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n.dayClosed,
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Periods Tab ──────────────────────────────────────────────────────────────

class _MobilePeriodsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationSettingsCubit, ReservationSettingsState>(
      builder: (context, state) {
        final cubit = context.read<ReservationSettingsCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final fg = _fgOf(isDark);
        final muted = _mutedOf(isDark);
        final cs = Theme.of(context).colorScheme;

        return _tabContent(
          context: context,
          state: state,
          cubit: cubit,
          builder: (loaded) {
            final s = loaded.settings;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _MobileCard(
                    isDark: isDark,
                    children: [
                      // Slot duration
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.slotDuration,
                              style: AppTextStyles.labelMd.copyWith(
                                  color: fg, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [15, 30, 60].map((min) {
                                final isSelected = s.slotDuration == min;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: AppSpacing.xs),
                                    child: GestureDetector(
                                      onTap: () => cubit.setSlotDuration(min),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(
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
                                        alignment: Alignment.center,
                                        child: Text(
                                          min == 15
                                              ? l10n.slotDuration15
                                              : min == 30
                                                  ? l10n.slotDuration30
                                                  : l10n.slotDuration60,
                                          style:
                                              AppTextStyles.labelSm.copyWith(
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
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      _Divider(isDark: isDark),
                      // Buffer time
                      _MobileNumberInputRow(
                        title: l10n.bufferTime,
                        hint: l10n.bufferTimeHint,
                        value: s.bufferTime,
                        onChanged: cubit.setBufferTime,
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      // Min advance hours
                      _MobileNumberInputRow(
                        title: l10n.minAdvanceHours,
                        hint: l10n.minAdvanceHoursHint,
                        value: s.minAdvanceHours,
                        onChanged: cubit.setMinAdvanceHours,
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      // Max advance days
                      _MobileNumberInputRow(
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
                    fullWidth: true,
                    onPressed: loaded.isSaving ? null : cubit.save,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Coming Soon Tab ──────────────────────────────────────────────────────────

class _MobileComingSoonTab extends StatelessWidget {
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

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _MobileCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _MobileCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surfaceOf(isDark),
        border: Border.all(color: _borderOf(isDark)),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: _borderOf(isDark));
  }
}

class _MobileToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _MobileToggleRow({
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

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: cs.primary,
      activeThumbColor: Colors.white,
      title: Text(
        title,
        style: AppTextStyles.labelMd.copyWith(
            color: fg, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySm.copyWith(color: muted),
      ),
    );
  }
}

class _MobileNumberInputRow extends StatefulWidget {
  final String title;
  final String hint;
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _MobileNumberInputRow({
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  State<_MobileNumberInputRow> createState() => _MobileNumberInputRowState();
}

class _MobileNumberInputRowState extends State<_MobileNumberInputRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_MobileNumberInputRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value.toString()) {
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
            width: 88,
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

class _MobileTimeInput extends StatefulWidget {
  final String label;
  final String value;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _MobileTimeInput({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_MobileTimeInput> createState() => _MobileTimeInputState();
}

class _MobileTimeInputState extends State<_MobileTimeInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_MobileTimeInput old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _controller.text != widget.value) {
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
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _controller.text = formatted;
      widget.onChanged(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = _mutedOf(widget.isDark);

    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: _surfaceOf(widget.isDark),
          border: Border.all(color: _borderOf(widget.isDark)),
          borderRadius: AppRadius.brSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: AppTextStyles.bodyXs.copyWith(color: muted),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded, size: 13, color: muted),
                const SizedBox(width: 4),
                Text(
                  _controller.text,
                  style: AppTextStyles.bodySm
                      .copyWith(color: _fgOf(widget.isDark)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSmallNumberInput extends StatefulWidget {
  final String label;
  final int value;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _MobileSmallNumberInput({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_MobileSmallNumberInput> createState() =>
      _MobileSmallNumberInputState();
}

class _MobileSmallNumberInputState extends State<_MobileSmallNumberInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_MobileSmallNumberInput old) {
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
        labelStyle:
            AppTextStyles.bodyXs.copyWith(color: _mutedOf(widget.isDark)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary),
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
