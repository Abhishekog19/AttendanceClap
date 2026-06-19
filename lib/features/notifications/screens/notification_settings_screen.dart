import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/notification_preferences_model.dart';
import '../providers/notification_preferences_provider.dart';
import '../services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification Settings Screen
// ─────────────────────────────────────────────────────────────────────────────

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  // Local copy for instant UI feedback before Firestore round-trip
  late NotificationPreferences _local;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _local = NotificationPreferences.defaults();
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bg = isDark ? AppColors.darkSurface : AppColors.background;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onSurfaceVariant = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    prefsAsync.whenData((prefs) {
      if (_loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() { _local = prefs; _loading = false; });
        });
      }
    });

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          'Notification Settings',
          style: AppTextStyles.headlineMd.copyWith(color: primary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (prefsAsync.isLoading || _loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, 100),
              children: [
                const SizedBox(height: AppSpacing.md),
                _buildBanner(isDark, primary, onSurface, cardBg, borderColor),
                const SizedBox(height: AppSpacing.lg),

                // ─── General ─────────────────────────────────────────────────
                _sectionLabel('General', isDark),
                const SizedBox(height: AppSpacing.sm),
                _card(isDark, cardBg, borderColor, [
                  _switchTile(
                    icon: Icons.notifications_outlined,
                    title: 'Enable Notifications',
                    value: _local.notificationsEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    onChanged: (v) => _patch((p) =>
                        p.copyWith(notificationsEnabled: v)),
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.volume_up_outlined,
                    title: 'Notification Sound',
                    value: _local.soundEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.notificationsEnabled,
                    onChanged: (v) => _patch((p) => p.copyWith(soundEnabled: v)),
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.vibration_outlined,
                    title: 'Vibration',
                    value: _local.vibrationEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(vibrationEnabled: v)),
                  ),
                  _divider(borderColor),
                  _timeTile(
                    icon: Icons.bedtime_outlined,
                    title: 'Quiet Hours Start',
                    time: _local.quietHoursStart,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.notificationsEnabled,
                    onTap: () => _pickTime(
                      initial: _local.quietHoursStart ??
                          const TimeOfDay(hour: 23, minute: 0),
                      onPicked: (t) =>
                          _patch((p) => p.copyWith(quietHoursStart: t)),
                    ),
                  ),
                  _divider(borderColor),
                  _timeTile(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Quiet Hours End',
                    time: _local.quietHoursEnd,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.notificationsEnabled,
                    onTap: () => _pickTime(
                      initial: _local.quietHoursEnd ??
                          const TimeOfDay(hour: 7, minute: 0),
                      onPicked: (t) =>
                          _patch((p) => p.copyWith(quietHoursEnd: t)),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),

                // ─── Smart Class Reminders ────────────────────────────────────
                _sectionLabel('Smart Class Reminders', isDark),
                const SizedBox(height: AppSpacing.sm),
                _card(isDark, cardBg, borderColor, [
                  _switchTile(
                    icon: Icons.alarm_outlined,
                    title: 'Enable Smart Reminders',
                    subtitle: 'First class & gap reminders only',
                    value: _local.classRemindersEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(classRemindersEnabled: v)),
                  ),
                  _divider(borderColor),
                  _dropdownTile<int>(
                    icon: Icons.timer_outlined,
                    title: 'Reminder Time',
                    value: _local.reminderMinutes,
                    items: const {5: '5 min before', 10: '10 min before', 15: '15 min before', 30: '30 min before'},
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.classRemindersEnabled && _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(reminderMinutes: v!)),
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.first_page_outlined,
                    title: 'Only First Class',
                    subtitle: 'Skip gap reminders',
                    value: _local.onlyFirstClassReminder,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.classRemindersEnabled && _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(onlyFirstClassReminder: v)),
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.space_bar_outlined,
                    title: 'Gap Class Reminders',
                    subtitle: 'Notify after long breaks',
                    value: _local.gapClassRemindersEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.classRemindersEnabled &&
                        !_local.onlyFirstClassReminder &&
                        _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(gapClassRemindersEnabled: v)),
                  ),
                  _divider(borderColor),
                  _dropdownTile<int>(
                    icon: Icons.hourglass_empty_outlined,
                    title: 'Gap Length',
                    value: _local.gapMinutes,
                    items: const {30: '30 min gap', 45: '45 min gap', 60: '60 min gap'},
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.classRemindersEnabled &&
                        _local.gapClassRemindersEnabled &&
                        !_local.onlyFirstClassReminder &&
                        _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(gapMinutes: v!)),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),

                // ─── Attendance Actions ───────────────────────────────────────
                _sectionLabel('Attendance Actions', isDark),
                const SizedBox(height: AppSpacing.sm),
                _card(isDark, cardBg, borderColor, [
                  _switchTile(
                    icon: Icons.touch_app_outlined,
                    title: 'Attendance Reminders',
                    subtitle: 'Mark directly from notification',
                    value: _local.attendanceRemindersEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.notificationsEnabled,
                    onChanged: (v) => _patch(
                        (p) => p.copyWith(attendanceRemindersEnabled: v)),
                  ),
                  _divider(borderColor),
                  _dropdownTile<int>(
                    icon: Icons.schedule_outlined,
                    title: 'Reminder Delay',
                    value: _local.attendanceDelayMinutes,
                    items: const {0: 'Immediately', 5: '5 min after class', 10: '10 min after class'},
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.attendanceRemindersEnabled && _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(attendanceDelayMinutes: v!)),
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.home_outlined,
                    title: 'Absent Rest of Day',
                    subtitle: 'Show "Absent Rest of Day" action button',
                    value: _local.absentRestOfDayEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.attendanceRemindersEnabled && _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(absentRestOfDayEnabled: v)),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),

                // ─── Attendance Alerts ────────────────────────────────────────
                _sectionLabel('Attendance Alerts', isDark),
                const SizedBox(height: AppSpacing.sm),
                _card(isDark, cardBg, borderColor, [
                  _switchTile(
                    icon: Icons.warning_amber_outlined,
                    title: 'Low Attendance Alerts',
                    subtitle: 'Alert when below your profile target',
                    value: _local.lowAttendanceAlertsEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.notificationsEnabled,
                    onChanged: (v) => _patch(
                        (p) => p.copyWith(lowAttendanceAlertsEnabled: v)),
                  ),
                  _divider(borderColor),
                  _infoTile(
                    icon: Icons.percent_outlined,
                    title: 'Attendance Target',
                    subtitle: 'Set in Profile → Attendance Goal',
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.crisis_alert_outlined,
                    title: 'Critical Attendance Alert',
                    subtitle: 'Separate high-priority alert for critically low attendance',
                    value: _local.criticalAttendanceEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.notificationsEnabled,
                    onChanged: (v) => _patch(
                        (p) => p.copyWith(criticalAttendanceEnabled: v)),
                  ),
                  _divider(borderColor),
                  _sliderTile(
                    icon: Icons.thermostat_outlined,
                    title: 'Critical Threshold',
                    subtitle: 'Alert fires when attendance drops below this %',
                    value: _local.criticalThreshold,
                    min: 50,
                    max: 80,
                    divisions: 30,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    primary: primary,
                    enabled: _local.criticalAttendanceEnabled &&
                        _local.notificationsEnabled,
                    onChanged: (v) =>
                        setState(() => _local = _local.copyWith(criticalThreshold: v)),
                    onChangeEnd: (v) =>
                        _patch((p) => p.copyWith(criticalThreshold: v)),
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.trending_up_outlined,
                    title: 'Recovery Suggestions',
                    subtitle: 'How many classes to attend to recover',
                    value: _local.recoverySuggestionsEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.lowAttendanceAlertsEnabled && _local.notificationsEnabled,
                    onChanged: (v) => _patch(
                        (p) => p.copyWith(recoverySuggestionsEnabled: v)),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),

                // ─── Safe Bunk Planner ────────────────────────────────────────
                _sectionLabel('Safe Bunk Planner', isDark),
                const SizedBox(height: AppSpacing.sm),
                _card(isDark, cardBg, borderColor, [
                  _switchTile(
                    icon: Icons.event_available_outlined,
                    title: 'Safe Bunk Planner',
                    subtitle: 'Daily safe-bunk summary for tomorrow',
                    value: _local.safeBunkPlannerEnabled,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(safeBunkPlannerEnabled: v)),
                  ),
                  _divider(borderColor),
                  _timeTile(
                    icon: Icons.access_time_outlined,
                    title: 'Planner Time',
                    time: _local.plannerTime,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.safeBunkPlannerEnabled && _local.notificationsEnabled,
                    onTap: () => _pickTime(
                      initial: _local.plannerTime,
                      onPicked: (t) =>
                          _patch((p) => p.copyWith(plannerTime: t)),
                    ),
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.free_cancellation_outlined,
                    title: 'Include Safe Bunks',
                    value: _local.includeSafeBunks,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.safeBunkPlannerEnabled && _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(includeSafeBunks: v)),
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.healing_outlined,
                    title: 'Recovery Suggestions',
                    value: _local.plannerIncludeRecoverySuggestions,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.safeBunkPlannerEnabled && _local.notificationsEnabled,
                    onChanged: (v) => _patch((p) =>
                        p.copyWith(plannerIncludeRecoverySuggestions: v)),
                  ),
                  _divider(borderColor),
                  _switchTile(
                    icon: Icons.report_problem_outlined,
                    title: 'Risk Subjects',
                    subtitle: 'Highlight subjects with no safe bunks',
                    value: _local.includeRiskSubjects,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                    enabled: _local.safeBunkPlannerEnabled && _local.notificationsEnabled,
                    onChanged: (v) =>
                        _patch((p) => p.copyWith(includeRiskSubjects: v)),
                  ),
                ]),
                const SizedBox(height: AppSpacing.xl),

                // ─── Reset ────────────────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => _resetToDefaults(context, isDark),
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('Reset to Defaults'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onSurface,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Permission banner ─────────────────────────────────────────────────────

  Widget _buildBanner(bool isDark, Color primary, Color onSurface,
      Color cardBg, Color borderColor) {
    return FutureBuilder<bool>(
      future: NotificationService.instance.requestPermissions().then((_) =>
          _hasPermission()),
      builder: (ctx, snap) {
        final granted = snap.data ?? true;
        if (granted) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warningContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Notification permission required. Tap to enable.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.onWarningContainer),
                ),
              ),
              TextButton(
                onPressed: () =>
                    NotificationService.instance.requestPermissions(),
                child: Text('Enable',
                    style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _hasPermission() async {
    await NotificationService.instance.getActiveNotifications();
    return true; // If we got here, plugin is initialised
  }

  // ── Patch helper ──────────────────────────────────────────────────────────

  void _patch(NotificationPreferences Function(NotificationPreferences) fn) {
    final updated = fn(_local);
    setState(() => _local = updated);
    ref
        .read(notificationPreferencesNotifierProvider.notifier)
        .update(updated);
  }

  // ── Time picker ───────────────────────────────────────────────────────────

  Future<void> _pickTime({
    required TimeOfDay initial,
    required void Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) onPicked(picked);
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> _resetToDefaults(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
            'All notification preferences will be reset to defaults.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) {
      _patch((_) => NotificationPreferences.defaults());
    }
  }

  // ── Widget builders ───────────────────────────────────────────────────────

  Widget _sectionLabel(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.labelCaps.copyWith(
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.onSurfaceVariant,
          ),
        ),
      );

  Widget _card(bool isDark, Color cardBg, Color borderColor,
      List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: borderColor),
        ),
        child: Column(children: children),
      );

  Widget _divider(Color color) =>
      Divider(height: 1, indent: AppSpacing.md, color: color);

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Color primary,
    required Color onSurface,
    required Color onSurfaceVariant,
    bool enabled = true,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        secondary: Icon(icon,
            color: enabled ? onSurface : onSurface.withAlpha(80)),
        title: Text(
          title,
          style: AppTextStyles.bodyLg.copyWith(
            color: enabled ? onSurface : onSurface.withAlpha(80),
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: AppTextStyles.bodySm.copyWith(
                    color: enabled
                        ? onSurfaceVariant
                        : onSurfaceVariant.withAlpha(80)))
            : null,
        value: value,
        activeThumbColor: primary,
        onChanged: enabled ? onChanged : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      );

  Widget _dropdownTile<T>({
    required IconData icon,
    required String title,
    required T value,
    required Map<T, String> items,
    required Color primary,
    required Color onSurface,
    required Color onSurfaceVariant,
    bool enabled = true,
    required ValueChanged<T?> onChanged,
  }) =>
      ListTile(
        leading: Icon(icon,
            color: enabled ? onSurface : onSurface.withAlpha(80)),
        title: Text(title,
            style: AppTextStyles.bodyLg.copyWith(
                color: enabled ? onSurface : onSurface.withAlpha(80))),
        trailing: DropdownButton<T>(
          value: value,
          underline: const SizedBox.shrink(),
          style: AppTextStyles.bodySm.copyWith(color: primary),
          onChanged: enabled ? onChanged : null,
          items: items.entries
              .map((e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Text(e.value,
                      style: AppTextStyles.bodySm)))
              .toList(),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      );

  Widget _timeTile({
    required IconData icon,
    required String title,
    required TimeOfDay? time,
    required Color primary,
    required Color onSurface,
    required Color onSurfaceVariant,
    bool enabled = true,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon,
            color: enabled ? onSurface : onSurface.withAlpha(80)),
        title: Text(title,
            style: AppTextStyles.bodyLg.copyWith(
                color: enabled ? onSurface : onSurface.withAlpha(80))),
        trailing: Text(
          time != null ? _formatTime(time) : 'Not set',
          style: AppTextStyles.bodyMd.copyWith(
              color: enabled ? primary : primary.withAlpha(80),
              fontWeight: FontWeight.w600),
        ),
        onTap: enabled ? onTap : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      );

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) =>
      ListTile(
        leading: Icon(icon, color: onSurfaceVariant),
        title: Text(title,
            style: AppTextStyles.bodyLg.copyWith(color: onSurface)),
        subtitle: Text(subtitle,
            style:
                AppTextStyles.bodySm.copyWith(color: onSurfaceVariant)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      );

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  Widget _sliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color primary,
    required Color onSurface,
    required Color onSurfaceVariant,
    bool enabled = true,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) =>
      ListTile(
        leading: Icon(icon,
            color: enabled ? onSurface : onSurface.withAlpha(80)),
        title: Text(title,
            style: AppTextStyles.bodyLg.copyWith(
                color: enabled ? onSurface : onSurface.withAlpha(80))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: AppTextStyles.bodySm
                    .copyWith(color: enabled ? onSurfaceVariant : onSurfaceVariant.withAlpha(80))),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    activeColor: enabled ? primary : primary.withAlpha(80),
                    onChanged: enabled ? onChanged : null,
                    onChangeEnd: enabled ? onChangeEnd : null,
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${value.toStringAsFixed(0)}%',
                    style: AppTextStyles.bodyMd.copyWith(
                        color: enabled ? primary : primary.withAlpha(80),
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      );
}
