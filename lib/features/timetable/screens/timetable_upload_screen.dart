import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/timetable_ocr_provider.dart';

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
        ref.read(editedTimetableProvider.notifier).setAll(next.schedule);
        context.push('/timetable/review');
      }
    });

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Import Timetable',
          style: AppTextStyles.headlineMd.copyWith(color: onSurface),
        ),
      ),
      body: ocrState.status == OcrStatus.extracting ||
              ocrState.status == OcrStatus.parsing
          ? _ProcessingView(
              status: ocrState.status,
              primaryColor: primary,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero illustration ────────────────────────────────────
                  Center(
                    child: ScaleTransition(
                      scale: _pulse,
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
                    'Upload a photo, screenshot, or PDF of your class timetable. '
                    'Our AI will extract all subjects, timings, and faculty automatically.',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Upload options ──────────────────────────────────────
                  Text(
                    'Choose Source',
                    style: AppTextStyles.labelMd.copyWith(
                      color: onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _UploadOptionCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'Take a Photo',
                    subtitle: 'Capture your printed timetable',
                    color: Colors.blue,
                    onTap: () => _pickFromCamera(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _UploadOptionCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Choose from Gallery',
                    subtitle: 'Select an existing screenshot',
                    color: Colors.purple,
                    onTap: () => _pickFromGallery(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _UploadOptionCard(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Upload PDF',
                    subtitle: 'Import from university portal PDF',
                    color: Colors.red,
                    onTap: () => _pickPdf(),
                  ),

                  if (ocrState.status == OcrStatus.error) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              ocrState.errorMessage ?? 'Unknown error',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Tips ────────────────────────────────────────────────
                  _TipsSection(surface: surface, onSurfaceVariant: onSurfaceVariant),
                ],
              ),
            ),
    );
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (xFile != null) _processFile(File(xFile.path));
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xFile != null) _processFile(File(xFile.path));
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      _processFile(File(result.files.single.path!));
    }
  }

  void _processFile(File file) {
    ref.read(timetableOcrProvider.notifier).processImage(file);
  }
}

// ── Processing View ────────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  final OcrStatus status;
  final Color primaryColor;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _ProcessingView({
    required this.status,
    required this.primaryColor,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    final isExtracting = status == OcrStatus.extracting;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isExtracting ? 'Reading text from image…' : 'AI is parsing your timetable…',
            style: AppTextStyles.headlineMd.copyWith(color: onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isExtracting
                ? 'Google ML Kit scanning text on-device'
                : 'Gemini Flash structuring your schedule',
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
  final Color color;
  final VoidCallback onTap;

  const _UploadOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

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
                        style: AppTextStyles.bodySm.copyWith(
                            color: onSurfaceVariant)),
                  ],
                ),
              ),
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
      '📄  For PDFs, use the downloaded version from your portal',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips for Best Results',
          style: AppTextStyles.labelMd.copyWith(color: onSurfaceVariant),
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


