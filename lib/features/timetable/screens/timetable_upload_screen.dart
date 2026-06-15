import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../providers/timetable_ocr_provider.dart';

part 'timetable_upload_screen.g.dart';

// ── Provider: check if active timetable exists ────────────────────────────────

@riverpod
Future<bool> activeTimetableExists(Ref ref) {
  return ref.watch(timetableRepositoryProvider).hasActiveTimetable();
}

// ── Provider: replace timetable notifier ──────────────────────────────────────

enum ReplaceStatus { idle, deleting, done, error }

@riverpod
class ReplaceTimetableNotifier extends _$ReplaceTimetableNotifier {
  @override
  ReplaceStatus build() => ReplaceStatus.idle;

  Future<void> replaceAll() async {
    state = ReplaceStatus.deleting;
    try {
      await ref.read(timetableRepositoryProvider).deleteAllUserData();
      // Invalidate the active timetable check so the upload UI appears
      ref.invalidate(activeTimetableExistsProvider);
      state = ReplaceStatus.done;
    } catch (_) {
      state = ReplaceStatus.error;
    }
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class TimetableUploadScreen extends ConsumerStatefulWidget {
  const TimetableUploadScreen({super.key});

  @override
  ConsumerState<TimetableUploadScreen> createState() =>
      _TimetableUploadScreenState();
}

class _TimetableUploadScreenState
    extends ConsumerState<TimetableUploadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(timetableOcrProvider);
    final activeTimetableAsync = ref.watch(activeTimetableExistsProvider);
    final replaceStatus = ref.watch(replaceTimetableNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    // Navigate to review when OCR succeeds
    ref.listen(timetableOcrProvider, (prev, next) {
      if (next.status == OcrStatus.success) {
        context.push('/timetable/review');
      }
    });

    final isProcessing = ocrState.status == OcrStatus.validating ||
        ocrState.status == OcrStatus.convertingPdf ||
        ocrState.status == OcrStatus.extracting ||
        ocrState.status == OcrStatus.parsing;

    final isReplacing = replaceStatus == ReplaceStatus.deleting;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: (isProcessing || isReplacing) ? null : () => context.pop(),
        ),
        title: Text(
          'Import Timetable',
          style: AppTextStyles.headlineMd.copyWith(color: onSurface),
        ),
      ),
      body: activeTimetableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _UploadBody(
          pulse: _pulse,
          primary: primary,
          surface: surface,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          ocrState: ocrState,
          isProcessing: isProcessing,
          onCamera: _pickFromCamera,
          onGallery: _pickFromGallery,
          onPdf: _pickPdf,
          onRetry: () => ref.read(timetableOcrProvider.notifier).retry(),
        ),
        data: (hasActive) {
          if (hasActive && replaceStatus != ReplaceStatus.done) {
            // Show locked state — timetable exists
            return _ActiveTimetableLockedView(
              isDark: isDark,
              primary: primary,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
              isReplacing: isReplacing,
              onReplace: () => _showReplaceConfirmation(context, ref),
            );
          }

          if (isProcessing) {
            return _ProcessingView(
              state: ocrState,
              primaryColor: primary,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            );
          }

          return _UploadBody(
            pulse: _pulse,
            primary: primary,
            surface: surface,
            onSurface: onSurface,
            onSurfaceVariant: onSurfaceVariant,
            ocrState: ocrState,
            isProcessing: isProcessing,
            onCamera: _pickFromCamera,
            onGallery: _pickFromGallery,
            onPdf: _pickPdf,
            onRetry: () => ref.read(timetableOcrProvider.notifier).retry(),
          );
        },
      ),
    );
  }

  Future<void> _showReplaceConfirmation(
      BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded,
                  color: AppColors.error, size: 30),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Replace Active Timetable?',
                style: AppTextStyles.headlineMd,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This will permanently delete your current timetable, all subjects, attendance logs, and analytics data. This action cannot be undone.',
              style: AppTextStyles.bodyLg.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text('Yes, Replace Everything'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(replaceTimetableNotifierProvider.notifier).replaceAll();
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (xFile != null && mounted) {
      ref.read(timetableOcrProvider.notifier).processFile(File(xFile.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xFile != null && mounted) {
      ref.read(timetableOcrProvider.notifier).processFile(File(xFile.path));
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null &&
        result.files.single.path != null &&
        mounted) {
      ref
          .read(timetableOcrProvider.notifier)
          .processFile(File(result.files.single.path!));
    }
  }
}

// ── Locked State View ─────────────────────────────────────────────────────────

class _ActiveTimetableLockedView extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final bool isReplacing;
  final VoidCallback onReplace;

  const _ActiveTimetableLockedView({
    required this.isDark,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.isReplacing,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outlined,
                  size: 48, color: AppColors.warning),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Active Timetable Exists',
              style: AppTextStyles.headlineLg.copyWith(color: onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'An active timetable already exists. Replace it to continue.',
              style: AppTextStyles.bodyLg.copyWith(
                color: onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Replacing will delete all subjects, attendance logs, and analytics.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.error.withValues(alpha: 0.8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (isReplacing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Deleting existing data…',
                style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onReplace,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Replace Timetable'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
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

// ── Upload Body ───────────────────────────────────────────────────────────────

class _UploadBody extends StatelessWidget {
  final Animation<double> pulse;
  final Color primary;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final OcrState ocrState;
  final bool isProcessing;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onPdf;
  final VoidCallback onRetry;

  const _UploadBody({
    required this.pulse,
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.ocrState,
    required this.isProcessing,
    required this.onCamera,
    required this.onGallery,
    required this.onPdf,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return _ProcessingView(
        state: ocrState,
        primaryColor: primary,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero illustration ──────────────────────────────────────
          Center(
            child: ScaleTransition(
              scale: pulse,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.15),
                      primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.document_scanner_outlined,
                  size: 64,
                  color: primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Scan Your Timetable',
            style: AppTextStyles.headlineLg.copyWith(color: onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Upload a photo, screenshot, or PDF of your class '
            'timetable. Our AI will extract all subjects, timings, '
            'and faculty automatically.',
            style: AppTextStyles.bodyLg.copyWith(
              color: onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Upload options ─────────────────────────────────────────
          Text(
            'CHOOSE SOURCE',
            style: AppTextStyles.labelCaps.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _UploadOptionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Take a Photo',
            subtitle: 'Capture your printed timetable',
            badge: 'PNG · JPG',
            color: Colors.blue,
            onTap: onCamera,
          ),
          const SizedBox(height: AppSpacing.md),
          _UploadOptionCard(
            icon: Icons.photo_library_outlined,
            title: 'Choose from Gallery',
            subtitle: 'Select an existing screenshot',
            badge: 'PNG · JPG',
            color: Colors.purple,
            onTap: onGallery,
          ),
          const SizedBox(height: AppSpacing.md),
          _UploadOptionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Upload PDF',
            subtitle: 'Import from university portal — up to 10 pages',
            badge: 'PDF',
            color: Colors.red,
            onTap: onPdf,
          ),

          // ── Error banner ───────────────────────────────────────────
          if (ocrState.status == OcrStatus.error) ...[
            const SizedBox(height: AppSpacing.lg),
            _ErrorBanner(
              message: ocrState.errorMessage ?? 'Unknown error',
              retryable: ocrState.retryable,
              onRetry: ocrState.retryable ? onRetry : null,
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // ── Tips ──────────────────────────────────────────────────
          _TipsSection(
              surface: surface, onSurfaceVariant: onSurfaceVariant),
        ],
      ),
    );
  }
}

// ── Processing View ────────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  final OcrState state;
  final Color primaryColor;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _ProcessingView({
    required this.state,
    required this.primaryColor,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  String get _headline {
    switch (state.status) {
      case OcrStatus.validating:
        return 'Validating file…';
      case OcrStatus.convertingPdf:
        if (state.totalPages > 0) {
          return 'Processing PDF page ${state.currentPage} of ${state.totalPages}…';
        }
        return 'Converting PDF to images…';
      case OcrStatus.extracting:
        return 'Reading text from image…';
      case OcrStatus.parsing:
        return 'AI is parsing your timetable…';
      default:
        return 'Processing…';
    }
  }

  String get _subtitle {
    switch (state.status) {
      case OcrStatus.validating:
        return 'Checking file integrity';
      case OcrStatus.convertingPdf:
        return 'Rendering pages for OCR analysis';
      case OcrStatus.extracting:
        return 'Google ML Kit scanning text on-device';
      case OcrStatus.parsing:
        return 'LLaMA 3.3 structuring your schedule';
      default:
        return 'Please wait…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: primaryColor,
                    value: state.isProcessingPdf && state.totalPages > 0
                        ? state.currentPage / state.totalPages
                        : null,
                  ),
                ),
                if (state.isProcessingPdf && state.totalPages > 0)
                  Text(
                    '${state.currentPage}/${state.totalPages}',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _headline,
              style: AppTextStyles.headlineMd.copyWith(color: onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _subtitle,
              style: AppTextStyles.bodyLg.copyWith(color: onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This may take 30–60 seconds',
              style: AppTextStyles.bodySm.copyWith(
                color: onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _PipelineSteps(currentStatus: state.status),
          ],
        ),
      ),
    );
  }
}

// ── Pipeline Step Indicators ──────────────────────────────────────────────────

class _PipelineSteps extends StatelessWidget {
  final OcrStatus currentStatus;

  const _PipelineSteps({required this.currentStatus});

  static const _steps = [
    (OcrStatus.validating, Icons.verified_outlined, 'Validate'),
    (OcrStatus.convertingPdf, Icons.picture_as_pdf_outlined, 'Convert'),
    (OcrStatus.extracting, Icons.text_snippet_outlined, 'Extract'),
    (OcrStatus.parsing, Icons.auto_awesome_outlined, 'Parse'),
  ];

  int get _currentIndex {
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == currentStatus) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final current = _currentIndex;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          return Container(
            width: 24,
            height: 1,
            color: stepIdx < current
                ? primary
                : onSurfaceVariant.withValues(alpha: 0.3),
          );
        }
        final stepIdx = i ~/ 2;
        final isDone = stepIdx < current;
        final isActive = stepIdx == current;
        final step = _steps[stepIdx];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? primary
                    : isActive
                        ? primary.withValues(alpha: 0.15)
                        : onSurfaceVariant.withValues(alpha: 0.1),
                border: isActive
                    ? Border.all(color: primary, width: 2)
                    : null,
              ),
              child: Icon(
                isDone ? Icons.check : step.$2,
                size: 16,
                color: isDone
                    ? Colors.white
                    : isActive
                        ? primary
                        : onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.$3,
              style: TextStyle(
                fontSize: 9,
                color: isActive || isDone ? primary : onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool retryable;
  final VoidCallback? onRetry;

  const _ErrorBanner({
    required this.message,
    required this.retryable,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.error,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (retryable && onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Upload Option Card ────────────────────────────────────────────────────────

class _UploadOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  const _UploadOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyLg.copyWith(
                            color: onSurface, fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: AppTextStyles.bodySm
                            .copyWith(color: onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right, color: onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tips Section ──────────────────────────────────────────────────────────────

class _TipsSection extends StatelessWidget {
  final Color surface;
  final Color onSurfaceVariant;

  const _TipsSection({required this.surface, required this.onSurfaceVariant});

  @override
  Widget build(BuildContext context) {
    const tips = [
      '📸  Ensure good lighting — avoid shadows on the timetable',
      '📐  Hold camera parallel to the table, not at an angle',
      '🔍  Text should be clearly readable before uploading',
      '📄  PDFs must be ≤10 pages and not password-protected',
      '↔️   Landscape timetables work best when captured full-width',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIPS FOR BEST RESULTS',
          style: AppTextStyles.labelCaps.copyWith(color: onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                tip,
                style: AppTextStyles.bodySm.copyWith(
                  color: onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            )),
      ],
    );
  }
}
