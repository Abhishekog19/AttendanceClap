import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/predictor_provider.dart';
import '../services/predictor_service.dart';

/// Predictor V2 — Section 1: Bunk Bank hero card.
///
/// Displays total safe bunks and per-subject breakdown sorted by ascending
/// safe bunk count (riskiest subjects first). Uses [bunkBankProvider] which
/// derives all values from the already-fetched [predictorDataProvider] —
/// zero additional Firebase reads.
class BunkBankCard extends ConsumerWidget {
  final PredictorData data;
  const BunkBankCard({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bankEntries = ref.watch(bunkBankProvider);

    final totalBunks = data.totalSafeBunks;
    final isHealthy = data.overallCurrentPct >= data.goal;

    // Gradient matches OverallSummaryCard aesthetic
    final List<Color> gradColors = isDark
        ? [const Color(0xFF1A1F35), const Color(0xFF0D1220)]
        : totalBunks > 0
            ? [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)]
            : [const Color(0xFF991B1B), const Color(0xFFDC2626)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: (isHealthy ? AppColors.primary : AppColors.error)
                .withValues(alpha: isDark ? 0.2 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background blob
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.savings_outlined,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 4),
                          Text(
                            'BUNK BANK',
                            style: AppTextStyles.labelCaps.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Goal badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'Goal ${data.goal.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Hero number ───────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalBunks',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safe Bunks',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            'Remaining',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (bankEntries.isEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    totalBunks == 0
                        ? 'No safe bunks — attend all classes to stay on track.'
                        : 'All subjects are safely above your goal.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),

                  // Divider
                  Divider(color: Colors.white.withValues(alpha: 0.12)),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Subject list ──────────────────────────────────────
                  ...bankEntries.map((entry) => _BunkSubjectRow(
                        entry: entry,
                        onTap: () => _showDetailSheet(context, entry, data),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(
      BuildContext context, BunkBankEntry entry, PredictorData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final bg = isDark ? AppColors.darkSurfaceContainer : Colors.white;

    // Find the prediction for this subject
    final pred = data.predictions
        .where((p) => p.subject.id == entry.subjectId)
        .firstOrNull;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              entry.subjectName,
              style: AppTextStyles.headlineMd
                  .copyWith(color: onSurface, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),

            if (pred != null) ...[
              _SheetRow(
                label: 'Current Attendance',
                value: '${pred.currentPct.toStringAsFixed(1)}%',
                onSurface: onSurface,
                onSurfaceVariant: onSurfaceVariant,
              ),
              _SheetRow(
                label: 'Attended / Total',
                value: '${pred.attended} / ${pred.total}',
                onSurface: onSurface,
                onSurfaceVariant: onSurfaceVariant,
              ),
              _SheetRow(
                label: 'Safe Bunks Remaining',
                value: '${entry.safeBunks}',
                valueColor: AppColors.success,
                onSurface: onSurface,
                onSurfaceVariant: onSurfaceVariant,
              ),
            ],
            if (entry.safeUntil != null)
              _SheetRow(
                label: 'Last Safe Skip Date',
                value: _fmtDate(entry.safeUntil!),
                onSurface: onSurface,
                onSurfaceVariant: onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

// ─── Per-subject row ──────────────────────────────────────────────────────────

class _BunkSubjectRow extends StatelessWidget {
  final BunkBankEntry entry;
  final VoidCallback onTap;
  const _BunkSubjectRow({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Colour-code the bunk count: ≤2 amber, >2 green
    final bunkColor = entry.safeBunks <= 2
        ? const Color(0xFFFBBF24)   // amber-400
        : const Color(0xFF34D399);   // emerald-400

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            // Subject name
            Expanded(
              child: Text(
                entry.subjectName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Bunk count pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bunkColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: bunkColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${entry.safeBunks} bunk${entry.safeBunks == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: bunkColor,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Safe Until date chip
            if (entry.safeUntil != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'Until ${_fmtShort(entry.safeUntil!)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'No upcoming classes',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtShort(DateTime d) =>
      '${d.day} ${_months[d.month - 1]}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

// ─── Bottom sheet row ─────────────────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _SheetRow({
    required this.label,
    required this.value,
    required this.onSurface,
    required this.onSurfaceVariant,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: onSurfaceVariant)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
