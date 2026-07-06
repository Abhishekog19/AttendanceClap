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
          const SizedBox(height: 28),
          Text(
            'Your Subjects',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: OnboardingColors.onBackground,
              height: 1.28,
              letterSpacing: -0.28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s set up your classes and attendance goals.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: OnboardingColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
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
            final nextStep = ref.read(onboardingNotifierProvider).currentStep;
            context.go(OnboardingStep.routeFor(nextStep));
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
    final color = Color(int.parse(
        'FF${subject.effectiveColorHex.replaceAll('#', '')}',
        radix: 16));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: OnboardingColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OnboardingColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left color accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      subject.effectiveShortName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + faculty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: OnboardingColors.onSurface,
                        ),
                      ),
                      if (subject.faculty != null && subject.faculty!.isNotEmpty)
                        Text(
                          subject.faculty!,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            color: OnboardingColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Target badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: OnboardingColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${target.round()}%',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: OnboardingColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  color: OnboardingColors.onSurfaceVariant,
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: OnboardingColors.error,
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: OnboardingColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: OnboardingColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: OnboardingColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: OnboardingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Add your first subject',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: OnboardingColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to get started',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: OnboardingColors.onSurfaceVariant,
              ),
            ),
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
          color: OnboardingColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: OnboardingColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 20,
              color: OnboardingColors.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'Add Another Subject',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: OnboardingColors.onSurface,
              ),
            ),
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
  String? _selectedColor; // null = auto-assigned by repo

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _facultyCtrl = TextEditingController(text: widget.existing?.faculty ?? '');
    _target = widget.existing?.attendanceTarget ?? widget.globalGoal;
    _useCustomTarget = widget.existing?.attendanceTarget != null;
    _selectedColor = widget.existing?.colorHex; // null for new subjects
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
      decoration: BoxDecoration(
        color: OnboardingColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
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
                color: OnboardingColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEdit ? 'Edit Subject' : 'Add Subject',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: OnboardingColors.onSurface,
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
          // ── Color picker ──────────────────────────────────────────
          Text(
            'Color',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: OnboardingColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kSubjectColorPalette.map((hex) {
              final color = Color(
                  int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
              final isSelected = _selectedColor == hex ||
                  (_selectedColor == null &&
                      hex == widget.existing?.effectiveColorHex);
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Custom Attendance Target',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: OnboardingColors.onSurface,
                ),
              ),
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
                    data: const SliderThemeData(
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
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  color: OnboardingColors.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_nameCtrl.text.trim().isEmpty) return;
                final double? customTarget =
                    _useCustomTarget ? _target : null;
                try {
                  if (isEdit) {
                    await notifier.editSubject(
                      subjectId: widget.existing!.id,
                      name: _nameCtrl.text,
                      faculty: _facultyCtrl.text.isEmpty
                          ? null
                          : _facultyCtrl.text,
                      attendanceTarget: customTarget,
                      colorHex: _selectedColor,
                    );
                  } else {
                    await notifier.addSubject(
                      name: _nameCtrl.text,
                      faculty: _facultyCtrl.text.isEmpty
                          ? null
                          : _facultyCtrl.text,
                      attendanceTarget: customTarget,
                      colorHex: _selectedColor,
                    );
                  }
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save: $e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OnboardingColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              child: Text(
                isEdit ? 'Save Changes' : 'Add Subject',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: OnboardingColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            color: OnboardingColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              color: OnboardingColors.outline,
            ),
            filled: true,
            fillColor: OnboardingColors.surfaceContainerLowest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: OnboardingColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: OnboardingColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: OnboardingColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
