import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/timetable_entry_model.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';
import '../widgets/onboarding_colors.dart';
import '../widgets/onboarding_scaffold.dart';

const _days = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

// Module-level provider — watches timetable_entries collection in real time.
final _obTimetableStreamProvider =
    StreamProvider.autoDispose<List<TimetableEntry>>((ref) {
  return ref.watch(timetableRepositoryProvider).watchTimetableEntries();
});

class ObTimetableBuilderScreen extends ConsumerStatefulWidget {
  const ObTimetableBuilderScreen({super.key});

  @override
  ConsumerState<ObTimetableBuilderScreen> createState() =>
      _ObTimetableBuilderScreenState();
}

class _ObTimetableBuilderScreenState
    extends ConsumerState<ObTimetableBuilderScreen> {
  String _selectedDay = 'Monday';

  @override
  Widget build(BuildContext context) {
    // Sync Firestore entries into notifier whenever stream updates
    ref.listen<AsyncValue<List<TimetableEntry>>>(
      _obTimetableStreamProvider,
      (_, next) {
        next.whenData((entries) {
          ref
              .read(onboardingNotifierProvider.notifier)
              .syncTimetableEntries(entries);
        });
      },
    );

    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    final dayEntries = state.timetableEntries
        .where((e) => e.day == _selectedDay)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return OnboardingScaffold(
      stepIndex: OnboardingStep.indexOf(OnboardingStep.timetable),
      totalSteps: OnboardingStep.all.length,
      showSkip: true,
      skipLabel: 'Skip',
      onSkip: () async {
        await notifier.skipTimetable();
        if (context.mounted) {
          context.go(OnboardingStep.routeFor(OnboardingStep.holidays));
        }
      },
      onBack: () => context.go(OnboardingStep.routeFor(OnboardingStep.subjects)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Build your\ntimetable',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: OnboardingColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your weekly class schedule. This powers smart attendance predictions and "safe bunk" calculations.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: OnboardingColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // ── Day selector ──────────────────────────────────────────
          _DaySelector(
            selected: _selectedDay,
            timetableEntries: state.timetableEntries,
            onSelect: (d) => setState(() => _selectedDay = d),
          ),
          const SizedBox(height: 20),
          // ── Slots for selected day ────────────────────────────────
          if (dayEntries.isEmpty)
            _EmptyDayState(
              day: _selectedDay,
              onAdd: () => _showAddSlotSheet(context, ref),
            )
          else ...[
            ...dayEntries.map((e) => _SlotCard(
                  entry: e,
                  onDelete: () {
                    if (e.id != null) notifier.removeTimetableEntry(e.id!);
                  },
                )),
            const SizedBox(height: 8),
            _AddSlotButton(onTap: () => _showAddSlotSheet(context, ref)),
          ],
          const SizedBox(height: 16),
          // ── Summary ───────────────────────────────────────────────
          if (state.timetableEntries.isNotEmpty)
            _TimetableSummary(entries: state.timetableEntries),
          const SizedBox(height: 32),
        ],
      ),
      cta: OnboardingCTAButton(
        label: 'Continue',
        onPressed: () async {
          await notifier.completeTimetable();
          if (context.mounted) {
            context.go(OnboardingStep.routeFor(OnboardingStep.holidays));
          }
        },
      ),
    );
  }

  void _showAddSlotSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotSheet(
        day: _selectedDay,
        ref: ref,
      ),
    );
  }
}

// ─── Day Selector ─────────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selected,
    required this.timetableEntries,
    required this.onSelect,
  });

  final String selected;
  final List<TimetableEntry> timetableEntries;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = _days[i];
          final isSelected = day == selected;
          final hasEntries =
              timetableEntries.any((e) => e.day == day);
          return GestureDetector(
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? OnboardingColors.primary
                    : OnboardingColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? OnboardingColors.primary
                      : OnboardingColors.border,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    day.substring(0, 3),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : OnboardingColors.textPrimary,
                    ),
                  ),
                  if (hasEntries) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : OnboardingColors.primary,
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
    );
  }
}

// ─── Slot card ────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.entry, required this.onDelete});
  final TimetableEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: OnboardingColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OnboardingColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: OnboardingColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(entry.startTime,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: OnboardingColors.textPrimary,
                    )),
                const Text('—',
                    style: TextStyle(
                        fontSize: 10,
                        color: OnboardingColors.textHint)),
                Text(entry.endTime,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: OnboardingColors.textPrimary,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subject,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OnboardingColors.textPrimary,
                    )),
                if (entry.faculty != null && entry.faculty!.isNotEmpty)
                  Text(entry.faculty!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: OnboardingColors.textSecondary,
                      )),
                if (entry.room != null && entry.room!.isNotEmpty)
                  Text('Room ${entry.room}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: OnboardingColors.textSecondary,
                      )),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: OnboardingColors.error),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({required this.day, required this.onAdd});
  final String day;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: OnboardingColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OnboardingColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                size: 32, color: OnboardingColors.textHint),
            const SizedBox(height: 8),
            Text('No classes on $day',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: OnboardingColors.textSecondary,
                )),
            Text('Tap to add',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: OnboardingColors.textHint,
                )),
          ],
        ),
      ),
    );
  }
}

class _AddSlotButton extends StatelessWidget {
  const _AddSlotButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: OnboardingColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OnboardingColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded,
                  size: 18, color: OnboardingColors.textPrimary),
              const SizedBox(width: 6),
              Text('Add Class',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: OnboardingColors.textPrimary,
                  )),
            ],
          ),
        ),
      );
}

class _TimetableSummary extends StatelessWidget {
  const _TimetableSummary({required this.entries});
  final List<TimetableEntry> entries;
  @override
  Widget build(BuildContext context) {
    final subjects = entries.map((e) => e.subject).toSet().length;
    final slots = entries.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: OnboardingColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Stat(value: '$slots', label: 'Slots/week'),
          const SizedBox(width: 24),
          _Stat(value: '$subjects', label: 'Subjects'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: OnboardingColors.textPrimary,
              )),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: OnboardingColors.textSecondary,
              )),
        ],
      );
}

// ─── Add Slot Bottom Sheet ────────────────────────────────────────────────────

class _SlotSheet extends StatefulWidget {
  const _SlotSheet({required this.day, required this.ref});
  final String day;
  final WidgetRef ref;

  @override
  State<_SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends State<_SlotSheet> {
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final _facultyCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _facultyCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.ref.watch(onboardingNotifierProvider);
    final notifier = widget.ref.read(onboardingNotifierProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: OnboardingColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: OnboardingColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add Class — ${widget.day}',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: OnboardingColors.textPrimary)),
            const SizedBox(height: 20),
            // Subject picker
            Text('Subject',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: OnboardingColors.textPrimary,
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: OnboardingColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OnboardingColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubjectId,
                  hint: Text('Select subject',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: OnboardingColors.textHint)),
                  isExpanded: true,
                  items: state.subjects.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: OnboardingColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedSubjectId = v;
                      _selectedSubjectName = state.subjects
                          .firstWhere((s) => s.id == v)
                          .name;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Time pickers
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Start',
                    time: _startTime,
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _startTime);
                      if (t != null) setState(() => _startTime = t);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: 'End',
                    time: _endTime,
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _endTime);
                      if (t != null) setState(() => _endTime = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedSubjectId == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        notifier.addTimetableEntry(
                          subjectId: _selectedSubjectId!,
                          subjectName: _selectedSubjectName!,
                          day: widget.day,
                          startTime: _fmt(_startTime),
                          endTime: _fmt(_endTime),
                          faculty: _facultyCtrl.text.isEmpty
                              ? null
                              : _facultyCtrl.text,
                          room: _roomCtrl.text.isEmpty
                              ? null
                              : _roomCtrl.text,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: OnboardingColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Add Class',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker(
      {required this.label, required this.time, required this.onTap});
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OnboardingColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OnboardingColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: OnboardingColors.textHint,
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: OnboardingColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
