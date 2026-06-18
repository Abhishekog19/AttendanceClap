# Homepage Data & Formula Audit

Audit covers every value displayed on the Dashboard (homepage) — how it's sourced, computed, and refreshed.

---

## ✅ What's Correct

### Data Pipeline — Single Source of Truth
The data flow is clean and reactive:

```
Firestore (subjects/) → watchSubjects() stream
  → subjectsStreamProvider [dashboard_provider.dart]
  → DashboardNotifier.build() [dashboard_provider.dart]
  → DashboardData → DashboardScreen
```

Firestore's real-time stream means **every attendance mark, edit, or delete automatically pushes updates to the dashboard** without any manual refresh needed.

### Overall Attendance Percentage
**Formula:** `(totalAttended / totalClasses) * 100`  
**Location:** [`AttendanceCalculator.calculatePercentage()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/core/utils/attendance_calculator.dart#L6-L12)  
**Verdict: ✅ Correct.** Handles `total == 0` case (returns 0.0).

### Subject-wise Attendance Percentages
**Formula:** `attendedClasses / totalClasses * 100` (in `SubjectModel`)  
**Location:** [`SubjectModel.attendancePercentage`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/models/subject_model.dart#L23-L24)  
**Verdict: ✅ Correct.** Handles zero-division.

### Classes Attended / Total Classes
**Source:** `subject.attendedClasses` / `subject.totalClasses` — Firestore denormalized counters, atomically updated via `FieldValue.increment()` in `logAttendance()`, `updateAttendanceLog()`, `deleteAttendanceLog()`.  
**Verdict: ✅ Correct.** All write paths use Firestore atomic batches to maintain counter integrity.

### Safe Bunks (Buffer)
**Formula:** `floor((attended / target) - total)`, clamped to ≥ 0  
**Location:** [`AttendanceCalculator.getSafeBunks()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/core/utils/attendance_calculator.dart#L16-L25)  
**Verdict: ✅ Correct.** The formula derivation: if you can miss `x` classes, you need `attended / (attended + total + x) ≥ target`, solving gives `x ≤ attended/target − total`.

### Classes Needed to Reach Target
**Formula:** `ceil((target*total − attended) / (1 − target))`, with guard when already above target  
**Location:** [`AttendanceCalculator.getClassesNeeded()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/core/utils/attendance_calculator.dart#L29-L43)  
**Verdict: ✅ Correct.** The algebra is right (solves `(a+x)/(t+x) = target`). Clamped to [0, 999].

### "Can I Bunk Tomorrow?" (Bunk Status)
**Logic:**  
1. Simulate missing one class: `afterBunk = calculatePercentage(attended, total+1)`  
2. If `afterBunk ≥ target && safeBunks > 2` → `safe`  
3. If `afterBunk ≥ target` (but tight) → `risky`  
4. Otherwise → `mustAttend`  
**Location:** [`AttendanceCalculator.canIBunk()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/core/utils/attendance_calculator.dart#L46-L69)  
**Verdict: ✅ Correct.** Uses overall counters (cross-subject aggregate) for a holistic bunk decision.

### Attendance Status Chip (Excellent / Good / Safe / Watch / Critical)
**Formula:**
- `≥ target + 10` → Excellent  
- `≥ target + 5`  → Good  
- `≥ target`      → Safe  
- `≥ target − 5`  → Watch (Risky)  
- `< target − 5`  → Critical  
**Location:** [`AttendanceCalculator.getStatus()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/core/utils/attendance_calculator.dart#L84-L90)  
**Verdict: ✅ Correct.** Consistent across dashboard hero card, subject cards, and subject detail screen.

### Attendance Goal (Target %)
**Source:** `userProfileProvider` stream → `attendanceGoalProvider` (defaults to 75.0)  
**Propagation:** Firestore real-time stream — changing the goal in profile instantly updates dashboard, analytics, and notifications.  
**Verdict: ✅ Correct and reactive.**

### Subject Card Display (Dashboard)
Shows `attendedClasses of totalClasses classes attended` and `attendancePercentage` (rounded to 0dp).  
**Verdict: ✅ Correct.**

### Rounding
- Hero card percentage text: `toStringAsFixed(1)` → 1 decimal place  
- Subject card percentage: `toStringAsFixed(0)` → integer  
- Progress ring internal: uses raw `double`, animated cleanly  
**Verdict: ✅ No rounding inconsistencies found.**

### Animation Refresh (didUpdateWidget)
Both [`AttendanceProgressRing`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/shared/widgets/attendance_progress_ring.dart#L48-L58) and [`_AnimatedPercentageText`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/dashboard/widgets/hero_attendance_card.dart#L159-L167) implement `didUpdateWidget` and re-animate when the value changes.  
**Verdict: ✅ Values update visually without restart.**

### SubjectProgressBar animation
**Issue found but low severity:** [`SubjectProgressBar`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/shared/widgets/subject_progress_bar.dart) does NOT implement `didUpdateWidget`. If the percentage changes while the widget stays mounted, the bar will **not** re-animate to the new value.  
**Impact:** In practice, the dashboard rebuilds subject cards from scratch via the stream (new `SubjectModel` → new widget keys), so this may not manifest in normal use. But it could affect the subject detail screen if visible.

### Atomic Counter Integrity
All writes to `attendedClasses`/`totalClasses` use Firestore `FieldValue.increment()` inside Firestore batches/transactions:
- [`logAttendance()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/datasources/firestore_datasource.dart#L231-L251) — create log path
- [`updateAttendanceLog()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/datasources/firestore_datasource.dart#L255-L288) — edit log path
- [`deleteAttendanceLog()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/datasources/firestore_datasource.dart#L292-L323) — delete log path
- [`markMultipleSessionsAbsent()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/repositories/timetable_repository.dart#L459-L557) — bulk mark absent
- [`AttendanceNotificationActionHandler._markSession()`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/notifications/handlers/attendance_notification_action_handler.dart#L209-L323) — notification quick-action path

**Verdict: ✅ No double-counting or missed increments found.**

---

## ⚠️ Issues Found

### Issue 1: `SubjectProgressBar` Missing `didUpdateWidget` — Bar Stale on Live Update
**Severity:** Low-Medium  
**File:** [`subject_progress_bar.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/shared/widgets/subject_progress_bar.dart#L24-L98)  
**Problem:** The `_SubjectProgressBarState` initializes the animation in `initState()` but has no `didUpdateWidget`. If `percentage` changes (e.g., user marks attendance while on the subject detail screen), the bar stays frozen at the old value until the widget is disposed and remounted.

```dart
// MISSING in _SubjectProgressBarState:
@override
void didUpdateWidget(SubjectProgressBar old) {
  super.didUpdateWidget(old);
  if (old.percentage != widget.percentage) {
    _widthAnim = Tween<double>(begin: _widthAnim.value, end: widget.percentage / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }
}
```

**Impact:** Dashboard subject cards likely rebuild with new widget instances (stream-driven), so the dashboard is unaffected. The **Subject Detail screen's** progress bar inside the ring (hero area uses `AttendanceProgressRing` which is correct) would be affected if someone marks attendance while viewing it.

---

### Issue 2: `AttendanceStats.total` Counts `notMarked` Logs (Incorrect Total)
**Severity:** Medium  
**File:** [`attendance_history_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/attendance/providers/attendance_history_provider.dart#L81-L104)  
**Problem:** `AttendanceStats.fromLogs()` sets `total = logs.length`, but the loop skips `notMarked` status for individual counters. This means `total` can be > `present + absent + late + cancelled` if any `notMarked` logs exist in the stream. The `percentage` computed from these stats will be **understated** (lower than actual) because the denominator is inflated.

```dart
factory AttendanceStats.fromLogs(List<AttendanceLogModel> logs) {
  // ...
  return AttendanceStats(
    total: logs.length,  // ⚠️ counts notMarked logs too
    ...
  );
}

double get percentage =>
    total == 0 ? 0 : ((present + late) / total) * 100;  // ⚠️ inflated denominator
```

The `notMarked` status comment says *"notMarked logs are not counted in stats"* — but `total` still counts them via `logs.length`.

**Fix:**
```dart
// Change total to only count "meaningful" entries:
total: p + a + l + c,  // excludes notMarked
```

> [!NOTE]
> `notMarked` logs should rarely appear in `attendance_logs` (the model docs say `notMarked` is only used on `class_sessions` documents, never stored in logs). However, if any stale/test data has `notMarked` in logs, this would corrupt the stats.

---

### Issue 3: Dashboard `RefreshIndicator` Only Invalidates `subjectsStreamProvider`
**Severity:** Low  
**File:** [`dashboard_screen.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/dashboard/screens/dashboard_screen.dart#L33)  
**Problem:** Pull-to-refresh only invalidates `subjectsStreamProvider`, not the `attendanceGoalProvider` or `userProfileProvider`. Since `userProfileProvider` is already a Firestore real-time stream, this is functionally fine in normal operation. However, the pull-to-refresh gesture **kills and restarts** the subjects stream unnecessarily (streams are already live). This provides no benefit and slightly penalizes UX by briefly showing loading state.

**Verdict:** Not a bug per se, but the `ref.invalidate(subjectsStreamProvider)` on pull-to-refresh is redundant — the stream already updates reactively. The `RefreshIndicator` could be removed or no-oped since there's nothing stale to refresh.

---

### Issue 4: `SubjectCard` Percentage Display — Inconsistent Decimal Precision with Hero Card
**Severity:** Cosmetic  
**Location:** [`subject_card.dart#L78`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/dashboard/widgets/subject_card.dart#L77-L79) vs [`hero_attendance_card.dart#L180`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/dashboard/widgets/hero_attendance_card.dart#L180)  
**Problem:** Subject cards display `toStringAsFixed(0)` (e.g., "75%") while the hero card shows `toStringAsFixed(1)` (e.g., "75.0%"). This is a display inconsistency — the subject detail screen also uses `toStringAsFixed(0)` for the ring. Not a calculation error, just a visual inconsistency.

---

### Issue 5: `canIBunk` Uses Aggregate (Cross-Subject) — Not Per-Subject Tomorrow Bunk Check
**Severity:** By-design, but potentially misleading  
**Location:** [`dashboard_provider.dart#L67-L71`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/dashboard/providers/dashboard_provider.dart#L67-L71)  
**Observation:** "Can I Bunk Tomorrow?" is evaluated on the **aggregate** of all subjects. A user might be safe overall (aggregate 80%) but have one subject at 72% where they truly cannot bunk. The banner says "Safe to Bunk!" which could be misleading.  
**This is a design limitation, not a bug.** The subject detail screen provides per-subject bunk analysis.

---

## ✅ No Issues Found In

| Area | Verdict |
|---|---|
| Overall % formula | ✅ Correct |
| Per-subject % formula | ✅ Correct |
| Safe bunks formula | ✅ Correct |
| Classes needed formula | ✅ Correct |
| Bunk status logic | ✅ Correct |
| Status threshold logic | ✅ Correct |
| Atomic counter updates | ✅ No races |
| Rename propagation | ✅ Handled |
| Delete cascade | ✅ Handled |
| Real-time stream reactivity | ✅ No polling needed |
| Attendance goal propagation | ✅ Stream-based, instant |
| Notification quick-action counters | ✅ Transaction-safe |
| Log archive filtering | ✅ Client-side, correct |
| Stale cache between users | ✅ Cleared on sign-out |
| Hero card animation on update | ✅ `didUpdateWidget` present |
| Progress ring animation on update | ✅ `didUpdateWidget` present |

---

## Fixes Required

### Fix 1 (Medium): `AttendanceStats.total` excludes `notMarked`
**File:** [`attendance_history_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/attendance/providers/attendance_history_provider.dart)

Change `total: logs.length` → `total: p + a + l + c` in `AttendanceStats.fromLogs()`.

### Fix 2 (Low): `SubjectProgressBar` add `didUpdateWidget`
**File:** [`subject_progress_bar.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/shared/widgets/subject_progress_bar.dart)

Add `didUpdateWidget` to `_SubjectProgressBarState` to re-animate when percentage changes in place.

### Fix 3 (Cosmetic, optional): Unify percentage precision
Decide whether subject cards show 0dp or 1dp and make it consistent with the hero card.
