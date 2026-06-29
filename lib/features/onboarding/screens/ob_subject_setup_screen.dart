import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/subject_model.dart';
import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';
import '../widgets/onboarding_colors.dart';
import '../widgets/onboarding_scaffold.dart';

class ObSubjectSetupScreen extends ConsumerWidget {
  const ObSubjectSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return OnboardingScaffold(
      stepIndex: OnboardingStep.indexOf(OnboardingStep.subjects),
      totalSteps: OnboardingStep.all.length,
      onBack: () => context.go(OnboardingStep.routeFor(OnboardingStep.semester)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Add your\nsubjects',
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
            'Add all the subjects you\'re enrolled in. You can set individual attendance targets for each one.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: OnboardingColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // ── Subject list ────────────────────────────────────────────
          if (state.subjects.isEmpty)
            _EmptySubjectState(
              onAdd: () => _showAddSubjectSheet(
                  context, ref, state.attendanceGoal),
            )
          else ...[
            ...state.subjects.map((s) => _SubjectCard(
                  subject: s,
                  globalGoal: state.attendanceGoal,
                  onEdit: () => _showAddSubjectSheet(
                      context, ref, state.attendanceGoal, existing: s),
                  onDelete: () => notifier.removeSubject(s.id),
                )),
            const SizedBox(height: 12),
            _AddSubjectButton(
              onTap: () =>
                  _showAddSubjectSheet(context, ref, state.attendanceGoal),
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!,
                style: GoogleFonts.inter(
                    fontSize: 13, color: OnboardingColors.error)),
          ],
          const SizedBox(height: 32),
        ],
      ),
      cta: OnboardingCTAButton(
        label: 'Continue',
        enabled: state.subjects.isNotEmpty,
        isLoading: state.isLoading,
        onPressed: () async {
          final ok = await notifier.completeSubjectSetup();
          if (ok && context.mounted) {
            context.go(OnboardingStep.routeFor(OnboardingStep.timetable));
          }
        },
      ),
    );
  }

  void _showAddSubjectSheet(
    BuildContext context,
    WidgetRef ref,
    double globalGoal, {
    SubjectModel? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectSheet(
        existing: existing,
        globalGoal: globalGoal,
        ref: ref,
      ),
    );
  }
}

// ─── Subject card ─────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.globalGoal,
    required this.onEdit,
    required this.onDelete,
  });

  final SubjectModel subject;
  final double globalGoal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final target = subject.attendanceTarget ?? globalGoal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: OnboardingColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OnboardingColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: OnboardingColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                subject.name.substring(0, 1).toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: OnboardingColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: OnboardingColors.textPrimary,
                    )),
                if (subject.faculty != null && subject.faculty!.isNotEmpty)
                  Text(subject.faculty!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: OnboardingColors.textSecondary,
                      )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: OnboardingColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${target.round()}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: OnboardingColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                size: 18, color: OnboardingColors.textSecondary),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
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

class _EmptySubjectState extends StatelessWidget {
  const _EmptySubjectState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: OnboardingColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: OnboardingColors.border,
              style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                size: 40, color: OnboardingColors.textHint),
            const SizedBox(height: 12),
            Text('Add your first subject',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: OnboardingColors.textPrimary,
                )),
            const SizedBox(height: 4),
            Text('Tap to get started',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: OnboardingColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

class _AddSubjectButton extends StatelessWidget {
  const _AddSubjectButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: OnboardingColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OnboardingColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded,
                size: 20, color: OnboardingColors.textPrimary),
            const SizedBox(width: 8),
            Text('Add Subject',
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
}

// ─── Add/Edit Subject Bottom Sheet ───────────────────────────────────────────

class _SubjectSheet extends StatefulWidget {
  const _SubjectSheet({
    required this.globalGoal,
    required this.ref,
    this.existing,
  });

  final double globalGoal;
  final WidgetRef ref;
  final SubjectModel? existing;

  @override
  State<_SubjectSheet> createState() => _SubjectSheetState();
}

class _SubjectSheetState extends State<_SubjectSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _facultyCtrl;
  late double _target;
  late bool _useCustomTarget;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _facultyCtrl =
        TextEditingController(text: widget.existing?.faculty ?? '');
    _target = widget.existing?.attendanceTarget ?? widget.globalGoal;
    _useCustomTarget = widget.existing?.attendanceTarget != null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _facultyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.ref.read(onboardingNotifierProvider.notifier);
    final isEdit = widget.existing != null;

    return Container(
      decoration: const BoxDecoration(
        color: OnboardingColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // handle
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
          Text(
            isEdit ? 'Edit Subject' : 'Add Subject',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OnboardingColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _SheetField(
            label: 'Subject Name *',
            hint: 'e.g. Mathematics',
            controller: _nameCtrl,
          ),
          const SizedBox(height: 16),
          _SheetField(
            label: 'Faculty (optional)',
            hint: 'e.g. Prof. Sharma',
            controller: _facultyCtrl,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Custom Attendance Target',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OnboardingColors.textPrimary,
                  )),
              Switch(
                value: _useCustomTarget,
                onChanged: (v) =>
                    setState(() => _useCustomTarget = v),
                activeThumbColor: OnboardingColors.primary,
                activeTrackColor: OnboardingColors.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
          if (_useCustomTarget) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: OnboardingColors.primary,
                      inactiveTrackColor: OnboardingColors.progressBg,
                      thumbColor: OnboardingColors.primary,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _target,
                      min: 50,
                      max: 100,
                      divisions: 10,
                      onChanged: (v) => setState(() => _target = v),
                    ),
                  ),
                ),
                Container(
                  width: 48,
                  height: 32,
                  decoration: BoxDecoration(
                    color: OnboardingColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text('${_target.round()}%',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Using global target: ${widget.globalGoal.round()}%',
                style: GoogleFonts.inter(
                    fontSize: 12, color: OnboardingColors.textSecondary),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                final double? customTarget =
                    _useCustomTarget ? _target : null;
                Navigator.of(context).pop();
                if (isEdit) {
                  notifier.editSubject(
                    subjectId: widget.existing!.id,
                    name: _nameCtrl.text,
                    faculty: _facultyCtrl.text.isEmpty
                        ? null
                        : _facultyCtrl.text,
                    attendanceTarget: customTarget,
                  );
                } else {
                  notifier.addSubject(
                    name: _nameCtrl.text,
                    faculty: _facultyCtrl.text.isEmpty
                        ? null
                        : _facultyCtrl.text,
                    attendanceTarget: customTarget,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OnboardingColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEdit ? 'Save Changes' : 'Add Subject',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField(
      {required this.label, required this.hint, required this.controller});
  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: OnboardingColors.textPrimary,
            )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(
              fontSize: 15, color: OnboardingColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                fontSize: 15, color: OnboardingColors.textHint),
            filled: true,
            fillColor: OnboardingColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: OnboardingColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: OnboardingColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: OnboardingColors.borderFocus, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
