/// Period Timing Sheet
///
/// Shared widget for both onboarding Screen 2 and post-setup edits (Section 7).
/// Two-tab design: "Same every day" / "Customize per day".
/// Opened as a modal bottom sheet via showModalBottomSheet (isScrollControlled: true).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/timetable_editor_models.dart';
import '../providers/timetable_editor_notifier.dart';

class PeriodTimingSheet extends ConsumerStatefulWidget {
  const PeriodTimingSheet({super.key});

  @override
  ConsumerState<PeriodTimingSheet> createState() => _PeriodTimingSheetState();
}

class _PeriodTimingSheetState extends ConsumerState<PeriodTimingSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();

  // ── Same Every Day state ──────────────────────────────────────────────────
  TimeOfDay _firstStart = const TimeOfDay(hour: 9, minute: 0);
  int _lectureDuration = 50; // minutes
  int _breakDuration = 10;   // minutes
  int _periodCount = 6;
  bool _addLunch = false;
  int _lunchAfterPeriod = 3;
  int _lunchDuration = 40;

  // ── Customize Per Day state ───────────────────────────────────────────────
  String _selectedDay = 'MON';
  Map<String, List<PeriodSlot>> _customPeriods = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initFromExisting();
  }

  void _initFromExisting() {
    final data = ref.read(timetableEditorNotifierProvider).data;
    if (data.defaultSchedule.isNotEmpty) {
      final first = data.defaultSchedule.first;
      final parts = first.startTime.split(':');
      _firstStart = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      if (data.defaultSchedule.length > 1) {
        _lectureDuration = data.defaultSchedule.first.durationMinutes;
      }
    }
    // Load any existing custom day schedules
    for (final entry in data.daySchedules.entries) {
      if (!entry.value.usesGlobalSchedule) {
        _customPeriods[entry.key] = List.from(entry.value.periods);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Period generation ─────────────────────────────────────────────────────

  List<PeriodSlot> _generatePeriods() {
    final slots = <PeriodSlot>[];
    int current = _firstStart.hour * 60 + _firstStart.minute;
    int lectureNum = 1;

    for (int i = 0; i < _periodCount; i++) {
      if (_addLunch && i == _lunchAfterPeriod) {
        final lunchStart = _minsToTime(current);
        current += _lunchDuration;
        slots.add(PeriodSlot(
          id: 'lunch_${i}',
          label: 'Lunch',
          startTime: lunchStart,
          endTime: _minsToTime(current),
          type: PeriodType.lunch,
        ));
        current += _breakDuration;
      }

      final start = _minsToTime(current);
      current += _lectureDuration;
      slots.add(PeriodSlot(
        id: 'p${lectureNum}',
        label: 'Period $lectureNum',
        startTime: start,
        endTime: _minsToTime(current),
        type: PeriodType.lecture,
      ));
      lectureNum++;

      if (i < _periodCount - 1 && !(_addLunch && i + 1 == _lunchAfterPeriod)) {
        final breakStart = _minsToTime(current);
        current += _breakDuration;
        slots.add(PeriodSlot(
          id: 'break_$i',
          label: 'Break',
          startTime: breakStart,
          endTime: _minsToTime(current),
          type: PeriodType.breakPeriod,
        ));
      }
    }

    return slots;
  }

  static String _minsToTime(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveAndClose() async {
    final notifier = ref.read(timetableEditorNotifierProvider.notifier);

    if (_tabController.index == 0) {
      // Same every day — save generated schedule as defaultSchedule
      final slots = _generatePeriods();
      await notifier.updateDefaultSchedule(slots);
    } else {
      // Customize per day — save each modified day
      for (final entry in _customPeriods.entries) {
        final schedule = DaySchedule(
          day: entry.key,
          periods: entry.value,
          usesGlobalSchedule: false,
        );
        await notifier.updateDaySchedule(entry.key, schedule);
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2028) : Colors.white;
    final surface = isDark ? const Color(0xFF282A34) : const Color(0xFFF5F5F5);
    final onSurface = isDark ? Colors.white : const Color(0xFF111111);
    final secondary = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title + tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Period Timing',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: onSurface,
                      unselectedLabelColor: secondary,
                      indicator: BoxDecoration(
                        color: isDark ? const Color(0xFF434655) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'Same every day'),
                        Tab(text: 'Customize per day'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SameEveryDayTab(
                    scrollController: scrollController,
                    firstStart: _firstStart,
                    lectureDuration: _lectureDuration,
                    breakDuration: _breakDuration,
                    periodCount: _periodCount,
                    addLunch: _addLunch,
                    lunchAfterPeriod: _lunchAfterPeriod,
                    lunchDuration: _lunchDuration,
                    generatedPeriods: _generatePeriods(),
                    isDark: isDark,
                    onStartChanged: (t) => setState(() => _firstStart = t),
                    onLectureDurationChanged: (v) =>
                        setState(() => _lectureDuration = v),
                    onBreakDurationChanged: (v) =>
                        setState(() => _breakDuration = v),
                    onPeriodCountChanged: (v) =>
                        setState(() => _periodCount = v),
                    onAddLunchChanged: (v) => setState(() => _addLunch = v),
                    onLunchAfterChanged: (v) =>
                        setState(() => _lunchAfterPeriod = v),
                    onLunchDurationChanged: (v) =>
                        setState(() => _lunchDuration = v),
                  ),
                  _CustomizePerDayTab(
                    scrollController: scrollController,
                    selectedDay: _selectedDay,
                    customPeriods: _customPeriods,
                    isDark: isDark,
                    uuid: _uuid,
                    onDaySelected: (d) => setState(() => _selectedDay = d),
                    onPeriodsChanged: (day, periods) =>
                        setState(() => _customPeriods[day] = periods),
                  ),
                ],
              ),
            ),
            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAndClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFB4C5FF)
                        : const Color(0xFF004AC6),
                    foregroundColor: isDark
                        ? const Color(0xFF002576)
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Save Schedule',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Same Every Day Tab ───────────────────────────────────────────────────────

class _SameEveryDayTab extends StatelessWidget {
  const _SameEveryDayTab({
    required this.scrollController,
    required this.firstStart,
    required this.lectureDuration,
    required this.breakDuration,
    required this.periodCount,
    required this.addLunch,
    required this.lunchAfterPeriod,
    required this.lunchDuration,
    required this.generatedPeriods,
    required this.isDark,
    required this.onStartChanged,
    required this.onLectureDurationChanged,
    required this.onBreakDurationChanged,
    required this.onPeriodCountChanged,
    required this.onAddLunchChanged,
    required this.onLunchAfterChanged,
    required this.onLunchDurationChanged,
  });

  final ScrollController scrollController;
  final TimeOfDay firstStart;
  final int lectureDuration;
  final int breakDuration;
  final int periodCount;
  final bool addLunch;
  final int lunchAfterPeriod;
  final int lunchDuration;
  final List<PeriodSlot> generatedPeriods;
  final bool isDark;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<int> onLectureDurationChanged;
  final ValueChanged<int> onBreakDurationChanged;
  final ValueChanged<int> onPeriodCountChanged;
  final ValueChanged<bool> onAddLunchChanged;
  final ValueChanged<int> onLunchAfterChanged;
  final ValueChanged<int> onLunchDurationChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? Colors.white : const Color(0xFF111111);
    final secondary = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666);
    final surface = isDark ? const Color(0xFF282A34) : const Color(0xFFF5F5F5);
    final border = isDark ? const Color(0xFF434655) : const Color(0xFFE0E0E0);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Start time
        _SectionLabel('First class starts at', onSurface),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: firstStart,
            );
            if (t != null) onStartChanged(t);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, color: secondary, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${firstStart.hour.toString().padLeft(2, '0')}:${firstStart.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Lecture duration
        _StepperRow(
          label: 'Lecture duration',
          value: lectureDuration,
          unit: 'min',
          min: 20,
          max: 180,
          step: 5,
          isDark: isDark,
          onChanged: onLectureDurationChanged,
        ),
        const SizedBox(height: 16),
        // Break duration
        _StepperRow(
          label: 'Break between lectures',
          value: breakDuration,
          unit: 'min',
          min: 0,
          max: 60,
          step: 5,
          isDark: isDark,
          onChanged: onBreakDurationChanged,
        ),
        const SizedBox(height: 16),
        // Period count
        _StepperRow(
          label: 'Number of lecture periods',
          value: periodCount,
          unit: 'periods',
          min: 1,
          max: 12,
          step: 1,
          isDark: isDark,
          onChanged: onPeriodCountChanged,
        ),
        const SizedBox(height: 20),
        // Lunch toggle
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add lunch break',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      )),
                ],
              ),
            ),
            Switch(
              value: addLunch,
              onChanged: onAddLunchChanged,
              activeThumbColor: const Color(0xFF004AC6),
            ),
          ],
        ),
        if (addLunch) ...[
          const SizedBox(height: 12),
          _StepperRow(
            label: 'After period',
            value: lunchAfterPeriod,
            unit: '',
            min: 1,
            max: periodCount,
            step: 1,
            isDark: isDark,
            onChanged: onLunchAfterChanged,
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: 'Lunch duration',
            value: lunchDuration,
            unit: 'min',
            min: 10,
            max: 90,
            step: 5,
            isDark: isDark,
            onChanged: onLunchDurationChanged,
          ),
        ],
        const SizedBox(height: 24),
        // Preview
        Text('Preview',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: secondary,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 8),
        ...generatedPeriods.map((p) => _PeriodPreviewRow(slot: p, isDark: isDark)),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Customize Per Day Tab ────────────────────────────────────────────────────

class _CustomizePerDayTab extends StatelessWidget {
  const _CustomizePerDayTab({
    required this.scrollController,
    required this.selectedDay,
    required this.customPeriods,
    required this.isDark,
    required this.uuid,
    required this.onDaySelected,
    required this.onPeriodsChanged,
  });

  final ScrollController scrollController;
  final String selectedDay;
  final Map<String, List<PeriodSlot>> customPeriods;
  final bool isDark;
  final Uuid uuid;
  final ValueChanged<String> onDaySelected;
  final void Function(String day, List<PeriodSlot> periods) onPeriodsChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? Colors.white : const Color(0xFF111111);
    final secondary = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666);
    final surface = isDark ? const Color(0xFF282A34) : const Color(0xFFF5F5F5);
    final primaryColor =
        isDark ? const Color(0xFFB4C5FF) : const Color(0xFF004AC6);
    final periods = customPeriods[selectedDay] ?? [];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Day chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kDayOrder.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final day = kDayOrder[i];
              final isSelected = day == selectedDay;
              final hasCustom = customPeriods.containsKey(day);
              return GestureDetector(
                onTap: () => onDaySelected(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isDark
                              ? const Color(0xFF434655)
                              : const Color(0xFFDDDDDD)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        day,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? (isDark
                                  ? const Color(0xFF002576)
                                  : Colors.white)
                              : onSurface,
                        ),
                      ),
                      if (hasCustom) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withAlpha(180)
                                : primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text('Periods for ${kDayFullNames[selectedDay] ?? selectedDay}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondary,
            )),
        const SizedBox(height: 8),
        if (periods.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Using global schedule — tap + to customize',
                style: GoogleFonts.inter(fontSize: 13, color: secondary),
              ),
            ),
          )
        else
          ...periods.asMap().entries.map((entry) {
            final i = entry.key;
            final slot = entry.value;
            return _EditablePeriodRow(
              slot: slot,
              isDark: isDark,
              onTimeChanged: (start, end) {
                final updated = List<PeriodSlot>.from(periods);
                updated[i] = slot.copyWith(startTime: start, endTime: end);
                onPeriodsChanged(selectedDay, updated);
              },
              onDelete: () {
                final updated = List<PeriodSlot>.from(periods)..removeAt(i);
                onPeriodsChanged(selectedDay, updated);
              },
            );
          }),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final id = 'p${periods.length + 1}_${uuid.v4().substring(0, 4)}';
                  final lastEnd = periods.isNotEmpty
                      ? periods.last.endTime
                      : '09:00';
                  final start = lastEnd;
                  final startMins = _minsFromTime(start);
                  final end = _minsToTimeStr(startMins + 50);
                  final updated = [
                    ...periods,
                    PeriodSlot(
                      id: id,
                      label: 'Period ${periods.where((p) => p.type == PeriodType.lecture).length + 1}',
                      startTime: start,
                      endTime: end,
                      type: PeriodType.lecture,
                    ),
                  ];
                  onPeriodsChanged(selectedDay, updated);
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add Period',
                    style: GoogleFonts.inter(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final id = 'break_${uuid.v4().substring(0, 4)}';
                  final lastEnd =
                      periods.isNotEmpty ? periods.last.endTime : '09:50';
                  final start = lastEnd;
                  final startMins = _minsFromTime(start);
                  final end = _minsToTimeStr(startMins + 10);
                  final updated = [
                    ...periods,
                    PeriodSlot(
                      id: id,
                      label: 'Break',
                      startTime: start,
                      endTime: end,
                      type: PeriodType.breakPeriod,
                    ),
                  ];
                  onPeriodsChanged(selectedDay, updated);
                },
                icon: const Icon(Icons.coffee_outlined, size: 16),
                label:
                    Text('Add Break', style: GoogleFonts.inter(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondary,
                  side: BorderSide(color: isDark ? const Color(0xFF434655) : const Color(0xFFDDDDDD)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  static int _minsFromTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _minsToTimeStr(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.isDark,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final bool isDark;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? Colors.white : const Color(0xFF111111);
    final secondary = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666);
    final surface = isDark ? const Color(0xFF282A34) : const Color(0xFFF5F5F5);
    final primaryColor =
        isDark ? const Color(0xFFB4C5FF) : const Color(0xFF004AC6);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
              if (unit.isNotEmpty)
                Text('$value $unit',
                    style: GoogleFonts.inter(fontSize: 12, color: secondary)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.remove_rounded, size: 18, color: value <= min ? secondary.withAlpha(100) : primaryColor),
                onPressed: value <= min ? null : () => onChanged(value - step),
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: onSurface),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_rounded, size: 18, color: value >= max ? secondary.withAlpha(100) : primaryColor),
                onPressed: value >= max ? null : () => onChanged(value + step),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodPreviewRow extends StatelessWidget {
  const _PeriodPreviewRow({required this.slot, required this.isDark});
  final PeriodSlot slot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isBreak = slot.type != PeriodType.lecture;
    final color = isBreak
        ? (isDark ? const Color(0xFF434655) : const Color(0xFFEEEEEE))
        : (isDark ? const Color(0xFF1A2752) : const Color(0xFFEEF2FF));
    final textColor = isBreak
        ? (isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666))
        : (isDark ? const Color(0xFFB4C5FF) : const Color(0xFF004AC6));

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(slot.label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          ),
          Text('${slot.startTime} – ${slot.endTime}',
              style: GoogleFonts.inter(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }
}

class _EditablePeriodRow extends StatelessWidget {
  const _EditablePeriodRow({
    required this.slot,
    required this.isDark,
    required this.onTimeChanged,
    required this.onDelete,
  });

  final PeriodSlot slot;
  final bool isDark;
  final void Function(String start, String end) onTimeChanged;
  final VoidCallback onDelete;

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final current = isStart ? slot.startTime : slot.endTime;
    final parts = current.split(':');
    final initial = TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) {
      final formatted =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        onTimeChanged(formatted, slot.endTime);
      } else {
        onTimeChanged(slot.startTime, formatted);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? Colors.white : const Color(0xFF111111);
    final secondary = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF666666);
    final surface = isDark ? const Color(0xFF282A34) : const Color(0xFFF5F5F5);
    final border = isDark ? const Color(0xFF434655) : const Color(0xFFE0E0E0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(slot.label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: onSurface)),
          ),
          GestureDetector(
            onTap: () => _pickTime(context, true),
            child: Text(slot.startTime,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF004AC6))),
          ),
          Text(' – ', style: GoogleFonts.inter(fontSize: 13, color: secondary)),
          GestureDetector(
            onTap: () => _pickTime(context, false),
            child: Text(slot.endTime,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF004AC6))),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: const Color(0xFFBA1A1A),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
