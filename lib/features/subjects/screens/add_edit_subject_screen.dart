import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/repositories/subject_repository.dart';

class AddEditSubjectScreen extends ConsumerStatefulWidget {
  final SubjectModel? subject;
  const AddEditSubjectScreen({super.key, this.subject});

  @override
  ConsumerState<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends ConsumerState<AddEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _facultyCtrl;
  late final TextEditingController _attendedCtrl;
  late final TextEditingController _totalCtrl;
  bool _saving = false;

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.subject?.name ?? '');
    _facultyCtrl = TextEditingController(text: widget.subject?.faculty ?? '');
    _attendedCtrl = TextEditingController(
      text: widget.subject?.attendedClasses.toString() ?? '0',
    );
    _totalCtrl = TextEditingController(
      text: widget.subject?.totalClasses.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _facultyCtrl.dispose();
    _attendedCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(subjectRepositoryProvider);
      final attended = int.tryParse(_attendedCtrl.text) ?? 0;
      final total = int.tryParse(_totalCtrl.text) ?? 0;

      if (_isEditing) {
        await repo.updateSubject(widget.subject!.copyWith(
          name: _nameCtrl.text.trim(),
          faculty: _facultyCtrl.text.trim().isEmpty ? null : _facultyCtrl.text.trim(),
          attendedClasses: attended,
          totalClasses: total,
          updatedAt: DateTime.now(),
        ));
      } else {
        await repo.addSubject(
          name: _nameCtrl.text.trim(),
          attendedClasses: attended,
          totalClasses: total,
          faculty: _facultyCtrl.text.trim().isEmpty ? null : _facultyCtrl.text.trim(),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Subject' : 'Add Subject',
          style: AppTextStyles.headlineMd.copyWith(color: primary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _SectionLabel('Subject Details', isDark),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Subject Name *',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _facultyCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Faculty (optional)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Attendance Count', isDark),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _attendedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Classes Attended',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _totalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Classes',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Invalid';
                      final attended = int.tryParse(_attendedCtrl.text) ?? 0;
                      if (n < attended) return 'Must be ≥ attended';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelCaps.copyWith(
        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
      ),
    );
  }
}
