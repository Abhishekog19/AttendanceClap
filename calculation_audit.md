# Attu — Full Calculation Audit Report

**Scope:** Every formula, scenario, projection, safe-bunk calc, target-achievement calc,
semester projection, edge case, and mathematical assumption across the entire codebase.
UI code is ignored; only computation correctness is evaluated.

---

## Files Audited

| File | Role |
|---|---|
| [`attendance_calculator.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/core/utils/attendance_calculator.dart) | Core static formula library |
| [`predictor_service.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/predictor/services/predictor_service.dart) | Predictor engine (all scenarios + projections) |
| [`dashboard_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/dashboard/providers/dashboard_provider.dart) | Dashboard aggregation |
| [`subject_detail_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/subjects/providers/subject_detail_provider.dart) | Per-subject detail + chart data |
| [`analytics_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/analytics/providers/analytics_provider.dart) | Analytics trend/summary/insights engine |
| [`attendance_history_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/attendance/providers/attendance_history_provider.dart) | `AttendanceStats` from logs |
| [`firestore_datasource.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/datasources/firestore_datasource.dart) | Counter delta helper (write-path math) |
| [`subject_model.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/models/subject_model.dart) | `attendancePercentage` computed property |
| [`semester_model.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/models/semester_model.dart) | `getDatesForWeekday` (session generation) |

---

## Section 1 — Core `AttendanceCalculator` Formulas

### 1.1 `calculatePercentage`
```
(attended / total) * 100   [returns 0.0 when total == 0]
```
✅ **Correct.** Zero-division guarded. Identity: 0 attended / 0 total → 0% (neutral, not NaN).

---

### 1.2 `getSafeBunks`
**Derivation needed:**
Want max `x` such that `attended / (total + x) ≥ target`.

```
attended / (total + x) ≥ target
attended ≥ target * (total + x)
attended / target ≥ total + x
x ≤ attended / target - total
x_max = floor(attended / target - total)
```

**Code:** `floor((attended / required) - total)` — **✅ Correct.**

**Edge cases:**
| Case | Expected | Code output |
|---|---|---|
| `attended=0, total=0` | 0 (no data) | 0 (guarded by `total == 0`) |
| `attended=75, total=100, target=75%` | `floor(75/0.75 - 100) = floor(100 - 100) = 0` | 0 ✅ |
| `attended=80, total=100, target=75%` | `floor(80/0.75 - 100) = floor(106.67 - 100) = floor(6.67) = 6` | 6 ✅ |
| `attended=74, total=100, target=75%` | `floor(74/0.75 - 100) = floor(98.67 - 100) = floor(-1.33) → 0 (clamped)` | 0 ✅ |
| `goal=0%` | PredictorService guards `required <= 0`, returns 0 | 0 ✅ |
| `goal=100%` | `attended / 1.0 - total = attended - total` (correct if attended ≥ total) | ✅ |

> [!NOTE]
> `AttendanceCalculator.getSafeBunks` does NOT guard `goal=0%` (no `required <= 0` check).
> Division by zero occurs when `targetPercent = 0.0`: `attended / 0.0` returns `Infinity` in Dart (IEEE 754 double), then `Infinity - total = Infinity`, and `Infinity.floor()` throws a **RangeError** at runtime.
>
> `PredictorService._safeBunks` DOES guard this case. The two implementations diverge.
> **Severity: Low-Medium** — goal=0% is not user-selectable through normal UI, but a defensive guard is still needed.

---

### 1.3 `getClassesNeeded`
**Derivation:** Find `x` such that `(attended + x) / (total + x) = target`.

```
attended + x = target * (total + x)
attended + x = target*total + target*x
x - target*x = target*total - attended
x(1 - target) = target*total - attended
x = (target*total - attended) / (1 - target)
```

**Code:** `ceil((target * total - attended) / (1 - target))` — **✅ Correct.**

**Edge cases:**
| Case | Expected | Code output |
|---|---|---|
| `attended=75, total=100, target=75%` | 0 (already at goal) | 0 ✅ (early return, current ≥ target) |
| `attended=0, total=0, target=75%` | 0 (0 ≥ 0 when total=0) | 0 ✅ (current=0.0, which IS NOT ≥ target=0.75, BUT `total=0` sets current=0.0; 0.0 < 0.75 → enters formula; then `(0.75*0 - 0)/(0.25) = 0`, ceil=0) |
| `attended=0, total=1, target=75%` | `ceil((0.75 - 0) / 0.25) = ceil(3) = 3` | 3 ✅ |
| `attended=60, total=100, target=75%` | `ceil((75 - 60) / 0.25) = ceil(60) = 60` | 60 ✅ |
| `goal=100%` | Denominator = 0 → undefined → capped at 999 | 999 ✅ (PredictorService guards this; `AttendanceCalculator` has `(1 - 1.0) = 0.0` denominator → `Infinity` → `Infinity.ceil()` → **RangeError** in Dart) |

> [!CAUTION]
> **Bug:** `AttendanceCalculator.getClassesNeeded` with `targetPercent = 100.0`:
> - `target = 1.0`
> - `1 - target = 0.0`
> - `needed = anything / 0.0` → Dart double: positive Infinity
> - `Infinity.ceil()` → throws `UnsupportedError` or `RangeError`
>
> `PredictorService._classesNeeded` correctly guards this with `if (required >= 1) return 999`.
> `AttendanceCalculator.getClassesNeeded` has **no such guard**.
>
> Since UI currently caps the goal slider below 100%, this doesn't surface in practice.
> But if a user manipulates data or a future feature allows 100% goal, this crashes.
> **Severity: Medium** — add `if (target >= 1.0) return 999;` before the division.

---

### 1.4 `canIBunk`
**Logic:**
1. Simulate one more absent: `afterBunk = pct(attended, total+1)`
2. `safeBunks = getSafeBunks(attended, total, target)`
3. `afterBunk >= target && safeBunks > 2` → **Safe**
4. `afterBunk >= target` → **Risky**
5. else → **MustAttend**

✅ **Correct.** The simulation is sound. `safeBunks > 2` as the "safe" threshold is a design choice (buffer of 3+), not a formula error.

**Edge cases:**
| Case | Expected | Code output |
|---|---|---|
| `total=0` | Safe (no data = no risk) | `BunkStatus.safe` ✅ |
| `attended=75, total=100, target=75%` | `afterBunk = 75/101*100 = 74.26%` < 75% → MustAttend | MustAttend ✅ |
| `attended=80, total=100, target=75%` | `afterBunk = 80/101*100 = 79.2%` ≥ 75%; safeBunks=6 > 2 → Safe | Safe ✅ |

---

### 1.5 `simulateFutureAttendance`
```
newTotal = currentTotal + futureAttended + futureMissed
newAttended = currentAttended + futureAttended
pct = newAttended / newTotal * 100
```
✅ **Correct.** Unused in current UI beyond being referenced in the core lib.

---

### 1.6 `getStatus` (threshold bands)
```
≥ target + 10  → Excellent
≥ target + 5   → Good
≥ target       → Safe
≥ target - 5   → Risky (Watch)
< target - 5   → Critical
```
✅ **Correct.** Bands are relative to the user's goal, not hardcoded values.

---

## Section 2 — `PredictorService` Formulas

### 2.1 `_pct` (private)
```dart
total == 0 ? 0 : (attended / total) * 100
```
✅ **Correct.** Identical to `AttendanceCalculator.calculatePercentage`.

---

### 2.2 `_safeBunks` (private)
Identical algebra to §1.2 but **adds** the `goal=0%` guard:
```dart
if (required <= 0) return 0;
```
✅ **Correct + defensive.**

---

### 2.3 `_classesNeeded` (private)
Identical algebra to §1.3 but **adds** the `goal=100%` guard:
```dart
if (required >= 1) return 999;
```
✅ **Correct + defensive.**

---

### 2.4 `_projectedPct` — Semester Projection (Best Case)
```
projectedPct = (attended + remaining) / (total + remaining) * 100
```
**Assumption:** Student attends ALL remaining future classes.

✅ **Correct for stated assumption.** This is the *optimistic ceiling* — explicitly labeled as such in UI ("If you attend all remaining classes"). Not misleading.

**Edge case:** `remaining=0` → `projectedPct = attended/total * 100 = currentPct`. ✅ Stable.

---

### 2.5 `overallProjectedPct` — Aggregate Semester Projection

> [!CAUTION]
> **Subtle Bug Found — Asymmetric Projection Formula**
>
> ```dart
> static double overallProjectedPct(List<SubjectPrediction> predictions) {
>   int totalAttended = 0;
>   int totalClasses = 0;
>   for (final p in predictions) {
>     totalAttended += p.attended + p.remainingClasses;  // ← attended + remaining
>     totalClasses  += p.total   + p.remainingClasses;  // ← total + remaining
>   }
>   return _pct(totalAttended, totalClasses);
> }
> ```
>
> The formula treats "projected overall" as the percentage you'd have if you attended all remaining classes. This is arithmetically sound **only if** `remainingClasses` is counted uniformly for both numerator and denominator.
>
> Let's verify: If current is `attended/total` and you attend all `r` remaining:
> - New attended = `attended + r`
> - New total = `total + r`
> - `pct = (attended + r) / (total + r)`
>
> This is what the code computes. ✅ **The formula is correct.**

---

### 2.6 `simulateMiss` — What-If (Simple)
```
newTotal = prediction.total + missedClasses
pct = attended / newTotal * 100
```
**Assumption:** Missing future classes only adds to total (denominator), attended stays the same.

✅ **Correct.** Mathematically, bunking means the class happened but you weren't there → attended stays same, total increases.

---

### 2.7 `whatIfBreakdown` — What-If (Full Breakdown)

```dart
totalAfterBunk = total + missedClasses
predictedPct = attended / totalAfterBunk * 100

remainingAfterBunk = (remaining - missedClasses).clamp(0, 999)

semesterTotal = total + remaining      // ← total end-of-semester classes

rawNeeded = (goal/100 * semesterTotal) - attended
minPresentNeeded = max(0, ceil(rawNeeded))

isAchievable = minPresentNeeded <= remainingAfterBunk
```

**Verify `minPresentNeeded` algebra:**
You need `(attended + x) / semesterTotal >= goal/100`
```
attended + x >= goal/100 * semesterTotal
x >= goal/100 * semesterTotal - attended
x_min = ceil(goal/100 * semesterTotal - attended)
```
✅ **Correct.**

**Edge cases:**

| Case | Expected | Code output |
|---|---|---|
| `missed=0` | `predictedPct = currentPct`, `remainingAfterBunk = remaining` | ✅ |
| `missed > remaining` | `remainingAfterBunk = 0` (clamped) | 0 ✅ |
| Already above goal after bunk | `rawNeeded <= 0` → `minPresentNeeded = 0` | 0 ✅ |
| Can't recover even attending all remaining | `minPresentNeeded > remainingAfterBunk` → `isAchievable = false` | ✅ |

> [!WARNING]
> **Bug in `WhatIfBreakdown.diff` getter (line 428–429):**
> ```dart
> double get diff => predictedPct - (attendedSoFar /
>     (totalLectures - missedClasses == 0 ? 1 : totalLectures - missedClasses) * 100);
> ```
>
> This is supposed to compute the change in percentage. But `totalLectures - missedClasses`
> is just `total` (the original total before bunking). So `diff` computes:
> `predictedPct - (attended / total * 100)` = `predictedPct - currentPct`.
>
> That is mathematically equivalent to `bd.predictedPct - widget.prediction.currentPct`
> which the UI already computes directly as `delta`. The `diff` getter is **redundant and confusing**
> — it appears to be a vestigial property. Worse: when `missedClasses = 0`,
> `totalLectures - missedClasses = totalLectures`, so the zero-division guard is checking
> `totalLectures == 0`, not the intended case.
>
> **However:** This getter is **never used in any widget or provider** — it was introduced
> with the model but left unreferenced. No display bug results. Still, it should be removed
> or corrected to avoid future misuse.
> **Severity: Low (dead code with wrong math).**

---

### 2.8 `simulateLeave` — Leave Planner

**Per-subject impact:**
```
pctBefore = attended / total * 100
pctAfter  = attended / (total + missedCount) * 100
```
✅ Correct. Missing `missedCount` future classes increases total, not attended.

**Recovery formula:**
```
rawRecovery = (goal * (total + missedCount) - attended) / (1 - goal)
recoveryNeeded = ceil(max(0, rawRecovery))
```
**Verify:** After taking leave, you have `total + missedCount` classes on record.
You need `attended + x` classes attended such that:
```
(attended + x) / (total + missedCount) >= goal
x >= goal * (total + missedCount) - attended
x_min = ceil(goal * (total + missedCount) - attended)
```
Wait — this is NOT the same as `getClassesNeeded` because the denominator is fixed here
(we're computing from the post-leave `newTotal`, not solving for more classes to add).
The formula above is wrong if interpreted as "future classes to attend after leave."

Let's re-derive. After the leave, remaining lectures are `r' = remaining - missedCount`.
You'll attend `x` of those remaining lectures. Final state at semester end:
```
attended_final = attended + x
total_final    = total + missedCount + x          (leave missed + x attended future)
                                                  WAIT — remaining already counted in total?
```

> [!CAUTION]
> **Semantic inconsistency in `simulateLeave` recovery formula:**
>
> The code computes `newTotal = total + missedCount` (only the leave classes added).
> It then asks: "how many MORE classes x to attend so that `(attended + x) / (total + missedCount + x) >= goal`?"
>
> But that's NOT what `rawRecovery` computes. `rawRecovery` solves:
> ```
> goal * (total + missedCount) - attended
> ```
> This is `ceil(goal * newTotal - attended)` — this is the total number of future classes
> you must attend OUT OF the semester total `newTotal`. But `newTotal = total + missedCount`
> does NOT include the classes you'll attend going forward — it only includes current + leave gap.
>
> Let me check what `newTotal` represents in context:
> - `total` = classes on record right now (attended + absent so far)
> - `missedCount` = additional classes you're skipping on leave (future → now missed)
> - The real semester-end total would be `total + remaining` (all classes ever scheduled)
>
> **The recovery formula uses `(total + missedCount)` as the final semester total, but the
> correct final total is `(total + remaining)`.** The code is using a smaller denominator than
> reality, making recovery appear more achievable than it actually is.
>
> **Concrete Example:**
> - `attended=60, total=80, remaining=40, goal=75%, missed on leave=10`
> - Semester-end total = `80 + 40 = 120`
> - Needed at semester end for 75%: `0.75 * 120 = 90` attended
> - Already attended: 60 → need 30 more out of remaining `40 - 10 = 30` left → all remaining
> - **Code computes:** `rawRecovery = 0.75 * (80 + 10) - 60 = 67.5 - 60 = 7.5 → ceil = 8`
>   - Says: "attend 8 more classes" (wrong — wildly underestimates)
>
> Compare to `whatIfBreakdown` which correctly uses `semesterTotal = total + remaining`.
>
> **Severity: HIGH.** The leave recovery number shown to the user is mathematically wrong.
> It will always understate the true recovery effort.
>
> **Fix:** Change:
> ```dart
> // WRONG:
> final rawRecovery = (goalPct * (total + missedCount) - attended) / (1 - goalPct);
> ```
> to:
> ```dart
> // CORRECT: use the real semester-end total
> final semesterTotal = total + pred.remainingClasses; // all classes in semester
> final rawRecovery = (goalPct * semesterTotal - attended) / (1 - goalPct);
> ```
> Note: `pred` here is the `SubjectPrediction` for the subject, which has `remainingClasses`.
> The `simulateLeave` function already has access to `pred.subject` via `predMap`.

---

### 2.9 `_buildRemainingMap` — Remaining Classes Count

```dart
final limitedSemester = Semester(
  startDate: from.isAfter(semester.startDate) ? from : semester.startDate,
  endDate: semester.endDate,
  ...
);
// Then: getDatesForWeekday(weekday).where((d) => d.isAfter(from))
```

> [!WARNING]
> **Double boundary issue — `today` classes potentially counted twice:**
>
> `limitedSemester.startDate` is set to `from` (today) when today is after semester start.
> `getDatesForWeekday` starts iterating from `startDate` and includes it if
> `current.weekday == weekday`. Then the outer `.where((d) => d.isAfter(from))` is applied.
>
> `d.isAfter(from)` is STRICT — it excludes dates that are equal to `from` (i.e., today).
> So today's class is NOT counted. This is the intended behavior (today is "now" — you may
> or may not attend, so it shouldn't be in "future remaining"). ✅ Correct semantics.
>
> The `limitedSemester` trick is actually redundant: even if `startDate` is set to `from`,
> the `.where(d.isAfter(from))` filter already excludes today. The `limitedSemester`
> only optimizes iteration speed (fewer days to loop). The result is correct either way.

**Holiday filtering:** `getDatesForWeekday` calls `isHoliday()` before adding a date. Holidays are excluded from remaining classes. ✅ Correct.

---

### 2.10 `_countMissedInRange` — Leave Planner Session Count

```dart
return d.isAfter(now) &&
       !d.isBefore(rangeStart) &&
       !d.isAfter(rangeEnd);
```

- `d.isAfter(now)` — only future classes count. ✅
- `!d.isBefore(rangeStart)` ≡ `d >= rangeStart` — inclusive start. ✅
- `!d.isAfter(rangeEnd)` ≡ `d <= rangeEnd` — inclusive end. ✅

Note: `rangeEnd` is set to `23:59:59` which makes date-only comparison ≤ end.day. ✅

---

### 2.11 `_riskLevel`
```
currentPct < goal  → Critical
safeBunks <= 2     → Warning
else               → Safe
```
✅ **Correct.** The priority order matters: if below goal, you're critical regardless of safe bunks (which would be 0 anyway).

---

### 2.12 `overallCurrentPct`
```
sum(attended) / sum(total) * 100
```
✅ **Correct.** This is properly a weighted average (by class count), not an unweighted average of subject percentages.

**Why it matters:** If subject A has 40/50 (80%) and subject B has 10/50 (20%):
- Weighted: 50/100 = 50% ← correct
- Unweighted avg: (80+20)/2 = 50% ← coincidence here but differs in general

The code sums raw counts, not percentages → correct weighted approach. ✅

---

## Section 3 — Analytics Provider

### 3.1 Trend data `_buildTrendSpots`

**Week period:**
```dart
final weekStart = now.subtract(Duration(days: now.weekday - 1));
// iterates i=0..6: day = weekStart + i days
```

> [!WARNING]
> **Off-by-one: Week starts at Monday of current week, but includes future days.**
> If today is Wednesday, the loop generates spots for Monday (i=0), Tuesday (i=1),
> Wednesday (i=2), **Thursday (i=3), Friday (i=4), Saturday (i=5), Sunday (i=6)**.
> Thursday–Sunday are in the FUTURE — logs for those days will be empty, producing 0%.
>
> This causes the trend chart to show 0% for future days of the week, making the
> rightmost part of the chart always look like a crash.
>
> **Expected behavior:** Only show past and today's data (7 trailing days), not future days.
> **Severity: Medium** — visually incorrect chart.
>
> **Fix option:** Use 7 trailing days instead:
> ```dart
> // Replace week case with:
> for (int i = 6; i >= 0; i--) {
>   final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
>   // x = 6 - i (0 = oldest, 6 = today)
>   ...
> }
> ```

**Month period:**
```dart
final monthStart = DateTime(now.year, now.month, 1);
for (int w = 0; w < 4; w++) {
  final weekS = monthStart.add(Duration(days: w * 7));
  final weekE = weekS.add(const Duration(days: 7));
  final weekLogs = logs.where((l) => l.date.isAfter(weekS) && l.date.isBefore(weekE));
```

`isAfter(weekS)` is strict — excludes `weekS` itself. So the first log of week 1 (monthStart day 1 at midnight) might be excluded if the log timestamp is exactly midnight. In practice, Firestore timestamps will have non-midnight times, so this is very unlikely to matter. Acceptable. ✅

**Semester period:**
```dart
for (int m = 5; m >= 0; m--) {
  final month = DateTime(now.year, now.month - m, 1);
  final nextMonth = DateTime(now.year, now.month - m + 1, 1);
```

> [!CAUTION]
> **Month arithmetic bug — negative month overflow:**
> If `now.month = 1` (January) and `m = 5`, then `now.month - m = -4`.
> `DateTime(year, -4, 1)` in Dart overflows: Dart's `DateTime` constructor does NOT
> clamp negative months. `DateTime(2026, -4, 1)` → this will likely compute as
> month 0 or negative, potentially producing `1970-01-01` or similar unexpected date.
>
> Dart actually handles negative month/day arguments by rolling back: month=-4 of 2026
> maps to August 2025. So it doesn't crash — Dart does the arithmetic — but the user
> gets "last 6 months ending at this month" spanning across years correctly.
>
> Wait — let's test: `DateTime(2026, -4, 1)`:
> Dart DateTime wraps months: month -4 from 2026 → 2025 + (12 - 5) = 2025 Aug?
> Actually: `month = -4` means 4 months before month 0 of year 2026.
> Month 0 = December of previous year (2025). Month -1 = November 2025, -2 = Oct, -3 = Sep, -4 = Aug 2025.
> So `DateTime(2026, -4, 1) = 2025-08-01`. This is correct for "6 months ago from Jan 2026."
>
> The behavior is correct but relies on Dart's undocumented overflow behavior.
> **Verdict: ✅ Accidentally correct** but fragile. Using explicit year-rollback math would be more reliable.

**Trend pct formula:**
```
total = dayLogs.length   (all statuses including cancelled)
present = logs where status == present OR late
pct = present / total * 100
```

> [!WARNING]
> **Cancelled classes inflate the denominator in trend charts.**
> `total = dayLogs.length` includes cancelled-status logs. If a class is cancelled,
> it's still in `dayLogs` but not counted as present, lowering the trend % artificially.
>
> Whether cancelled classes should count toward the trend total is a design question,
> but it's inconsistent with:
> - `SubjectModel.attendancePercentage` which counts cancelled in `totalClasses` (they DO affect the real %)
> - `AttendanceStats.fromLogs` which counts cancelled in `total` (consistent with subject model)
> - `logAttendance()` in Firestore which does NOT increment counters for cancelled classes
>
> The Firestore write path is the truth source: **cancelled classes do NOT count toward real attendance**.
> The trend chart should exclude them from `total` to show accurate trend %.
>
> **Fix:** `total = dayLogs.where((l) => l.status != AttendanceStatus.cancelled && l.status != AttendanceStatus.notMarked).length`
>
> **Severity: Medium** — trend data understates real attendance on days with many cancelled classes.

---

### 3.2 `analyticsSummary`

```dart
final present = logs.where((l) => l.status == present || l.status == late).length;
final missed  = logs.where((l) => l.status == absent).length;
// ...
totalClasses: logs.length,
```

> [!WARNING]
> **Same cancelled-class denominator problem as §3.1.**
> `totalClasses = logs.length` includes cancelled and notMarked logs.
> `totalAttended + totalMissed` will not equal `totalClasses` when any cancelled/notMarked
> logs exist. The summary card showing "X attended out of Y total" is potentially misleading.
>
> **Fix:** `totalClasses: present + missed` (to match what's actually tracked).
> **Severity: Medium.**

---

### 3.3 `_classesNeeded` (analytics-local function, line 336)
```dart
int _classesNeeded(SubjectModel s, double goal) {
  final target = goal / 100;
  if (s.totalClasses == 0) return 0;
  final needed = (target * s.totalClasses - s.attendedClasses) / (1 - target);
  return needed.ceil().clamp(0, 999);
}
```

> [!CAUTION]
> **Missing `goal=100%` guard.**
> Same as §1.3: if `goal=100.0`, `target=1.0`, denominator `1-target=0.0`.
> `needed = X / 0.0 = Infinity` → `Infinity.ceil()` throws.
> This function is a private duplicate of the core formula without the safety guard.
>
> Also: **This function doesn't check if already at/above goal.** If `s.attendedClasses/s.totalClasses >= goal`, the numerator `target*total - attended` is negative → `needed < 0` → `ceil` gives a negative int → `.clamp(0, 999)` returns 0. ✅ Safe via clamp. But the explicit guard improves clarity and avoids Infinity.

---

### 3.4 `_computeStreak`
```dart
var checkDate = DateTime(now.year, now.month, now.day); // start from today
while (true) {
  final hasPresent = logs.any((l) => _isSameDay(l.date, checkDate) && (present || late));
  if (!hasPresent) break;
  streak++;
  checkDate = checkDate.subtract(const Duration(days: 1));
}
```

✅ **Correct.** Counts consecutive days going back from today. Breaks at first day with no present/late log.

**Edge case:** If today has no logs (e.g., weekend), streak = 0. This is correct — streak resets on any no-attendance day (including holidays/weekends where classes don't happen).

This is a potential UX concern (weekends always break streak), but the formula itself is correct as written.

---

## Section 4 — Subject Detail Provider

### 4.1 `weeklyTrend`
```dart
for (int i = 6; i >= 0; i--) {
  final day = now.subtract(Duration(days: i));
  // x = 6 - i (x=0 is 6 days ago, x=6 is today)
```
✅ **Correct.** Goes back 7 days from today (inclusive). No future days.

**Same cancelled denominator issue as §3.1** — `total = dayLogs.length` includes cancelled.
**Severity: Medium** — same fix applies.

### 4.2 `monthlyTrend`
```dart
for (int w = 3; w >= 0; w--) {
  final weekEnd = now.subtract(Duration(days: w * 7));
  final weekStart = weekEnd.subtract(const Duration(days: 7));
  logs.where((l) => l.date.isAfter(weekStart) && l.date.isBefore(weekEnd))
```
`isAfter(weekStart)` and `isBefore(weekEnd)` → exclusive on both ends. This means a log timestamped exactly at `weekStart` or exactly at `weekEnd` midnight would be excluded. In practice, timestamps are not exactly midnight, so this is fine. ✅

---

## Section 5 — Firestore Counter Delta (Write-Path)

### 5.1 `_counterDelta`
```
present/late → attended +1, total +1
absent       → attended +0, total +1
cancelled    → attended +0, total +0
notMarked    → attended +0, total +0 (not handled explicitly, treated as cancelled)
```

**All transitions verified:**

| Old → New | Δattended | Δtotal | Expected | Code |
|---|---|---|---|---|
| present → absent | -1 | 0 | Correct (lose attend, keep total) | ✅ |
| present → cancelled | -1 | -1 | Correct (remove from both) | ✅ |
| absent → present | +1 | 0 | Correct (gain attend, keep total) | ✅ |
| absent → cancelled | 0 | -1 | Correct (remove from total) | ✅ |
| cancelled → present | +1 | +1 | Correct (add to both) | ✅ |
| cancelled → absent | 0 | +1 | Correct (add to total only) | ✅ |
| late → absent | -1 | 0 | Correct | ✅ |
| present → late | 0 | 0 | Correct (both count as attended) | ✅ |

**Delete path** (`deleteAttendanceLog`):
```dart
_counterDelta(oldStatus: log.status, newStatus: AttendanceStatus.cancelled)
```
This reverses the original log's effect by transitioning to "cancelled" (which has no counter impact). ✅ Correct.

---

## Section 6 — `AttendanceStats` (History Screen)

### 6.1 `AttendanceStats.fromLogs`
**Status in previous audit:** Was broken (total = logs.length). 
**Current code:**
```dart
total: p + a + l + c,   // excludes notMarked
```
✅ **Already fixed.** Correct.

### 6.2 `AttendanceStats.percentage`
```
(present + late) / total * 100   [returns 0 when total=0]
```
✅ **Correct.** Late counts as present. Cancelled counts toward total (consistent with how logAttendance does NOT increment counters for cancelled — but cancelled IS stored as a log, so it lands in `c`). Wait:

> [!WARNING]
> **Cancelled classes should NOT count toward `AttendanceStats.total`.**
>
> The Firestore write path: `logAttendance()` does NOT call `totalClasses += 1` for cancelled.
> So cancelled classes don't inflate `totalClasses` in the subject model.
>
> But `AttendanceStats.total = p + a + l + c` includes `c` (cancelled logs).
> This means the History screen's percentage stat (`(p+l)/total`) uses a denominator that
> includes cancelled — which is inconsistent with the real `attendancePercentage` on the subject.
>
> **Example:** Subject has 70 present + 10 absent + 5 cancelled = 85 total classes.
> - Real `attendedClasses = 70`, `totalClasses = 80` (no cancelled) → real % = 87.5%
> - `AttendanceStats`: total = 70+10+5 = 85, pct = 70/85 = 82.4% ← **wrong**
>
> The History screen percentage is understated whenever cancelled logs exist.
>
> **Fix:** `total: p + a + l` (exclude cancelled from denominator).
> **Severity: Medium.**

---

## Summary Table

| # | Location | Formula | Verdict | Severity |
|---|---|---|---|---|
| 1.2a | `AttendanceCalculator.getSafeBunks` | No guard for goal=0% | ⚠️ Bug | Low-Medium |
| 1.3a | `AttendanceCalculator.getClassesNeeded` | No guard for goal=100% → crash | 🔴 Bug | Medium |
| 2.7a | `WhatIfBreakdown.diff` getter | Wrong math, dead code | ⚠️ Bug | Low |
| 2.8a | `simulateLeave` recovery formula | Wrong denominator → understates recovery | 🔴 Bug | **HIGH** |
| 3.1a | `_buildTrendSpots` (week) | Future days shown as 0% | ⚠️ Bug | Medium |
| 3.1b | `_buildTrendSpots` (all periods) | Cancelled classes inflate denominator | ⚠️ Bug | Medium |
| 3.2 | `analyticsSummary.totalClasses` | `logs.length` includes cancelled/notMarked | ⚠️ Bug | Medium |
| 3.3 | `_classesNeeded` (analytics local) | No goal=100% guard | ⚠️ Bug | Low-Medium |
| 6.2 | `AttendanceStats.total` includes cancelled | Inconsistent with write-path | ⚠️ Bug | Medium |

### ✅ Verified Correct

| Area | Formula | Verdict |
|---|---|---|
| `calculatePercentage` | `attended/total*100` | ✅ |
| `getSafeBunks` (PredictorService) | With 0% guard | ✅ |
| `getClassesNeeded` (PredictorService) | With 100% guard | ✅ |
| `canIBunk` (all cases) | Simulate +1 absent | ✅ |
| `simulateMiss` (What-If simple) | `attended / (total+missed)` | ✅ |
| `whatIfBreakdown` main numbers | Uses `semesterTotal = total+remaining` | ✅ |
| `_projectedPct` | `(attended+r)/(total+r)` | ✅ |
| `overallCurrentPct` | Weighted sum (not avg of %) | ✅ |
| `overallProjectedPct` | Consistent formula | ✅ |
| `_riskLevel` | Critical priority correct | ✅ |
| `_buildRemainingMap` date boundaries | `isAfter(from)` excludes today | ✅ |
| `_countMissedInRange` | Inclusive range, future only | ✅ |
| Counter delta all transitions | All 12 transitions verified | ✅ |
| `AttendanceStats.fromLogs` total | `p+a+l+c` (fixed from prev audit) | ✅ |
| `getStatus` threshold bands | Relative to goal | ✅ |
| `getDatesForWeekday` holiday filter | Correct | ✅ |
| `Semester.totalWeeks` | `inDays ~/ 7` | ✅ |

---

## Required Fixes (Priority Order)

### Fix 1 🔴 HIGH — `simulateLeave` Recovery Formula
**File:** [`predictor_service.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/predictor/services/predictor_service.dart#L175-L181)

```dart
// BEFORE (wrong denominator):
final rawRecovery =
    (goalPct * (total + missedCount) - attended) / (1 - goalPct);

// AFTER (correct — use real semester-end total):
final semesterTotal = total + pred.remainingClasses;
final rawRecovery =
    (goalPct * semesterTotal - attended) / (1 - goalPct);
```
Note: `pred` is already in scope inside `simulateLeave`'s loop.

---

### Fix 2 🔴 MEDIUM — `AttendanceCalculator.getClassesNeeded` Missing 100% Guard
**File:** [`attendance_calculator.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/core/utils/attendance_calculator.dart#L33-L43)

```dart
// Add after: final target = targetPercent / 100;
if (target >= 1.0) return 999;
```

---

### Fix 3 ⚠️ MEDIUM — `AttendanceStats.total` Includes Cancelled
**File:** [`attendance_history_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/attendance/providers/attendance_history_provider.dart#L97-L106)

```dart
// BEFORE:
total: p + a + l + c,

// AFTER (exclude cancelled — consistent with Firestore write path):
total: p + a + l,
```

---

### Fix 4 ⚠️ MEDIUM — Weekly Trend Chart Shows Future Days as 0%
**File:** [`analytics_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/analytics/providers/analytics_provider.dart#L116-L128)

```dart
// BEFORE: starts from Monday of current week (includes future weekdays)
// AFTER: use 7 trailing days from today
case AnalyticsPeriod.week:
  final spots = <FlSpot>[];
  for (int i = 6; i >= 0; i--) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
    final dayLogs = logs.where((l) => _isSameDay(l.date, day)).toList();
    final total = dayLogs.where((l) =>
        l.status != AttendanceStatus.cancelled &&
        l.status != AttendanceStatus.notMarked).length;
    final present = dayLogs.where((l) =>
        l.status == AttendanceStatus.present || l.status == AttendanceStatus.late).length;
    final pct = total == 0 ? 0.0 : (present / total) * 100;
    spots.add(FlSpot((6 - i).toDouble(), pct));
  }
  return spots;
```

---

### Fix 5 ⚠️ MEDIUM — Trend Charts Include Cancelled in Denominator
Apply same cancelled-exclusion fix from Fix 4 to:
- `AnalyticsPeriod.month` case in `_buildTrendSpots`
- `AnalyticsPeriod.semester` case in `_buildTrendSpots`
- `SubjectDetailData.weeklyTrend` and `monthlyTrend` in [`subject_detail_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/subjects/providers/subject_detail_provider.dart#L75-L119)

---

### Fix 6 ⚠️ LOW-MEDIUM — `AttendanceCalculator.getSafeBunks` Missing 0% Guard
**File:** [`attendance_calculator.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/core/utils/attendance_calculator.dart#L16-L25)

```dart
// Add after: if (total == 0) return 0;
if (targetPercent <= 0) return 0;
```

---

### Fix 7 ⚠️ LOW-MEDIUM — Analytics `_classesNeeded` Missing 100% Guard
**File:** [`analytics_provider.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/analytics/providers/analytics_provider.dart#L336-L342)

```dart
int _classesNeeded(SubjectModel s, double goal) {
  final target = goal / 100;
  if (s.totalClasses == 0) return 0;
  if (target >= 1.0) return 999;     // ← add this guard
  final current = s.attendedClasses / s.totalClasses;
  if (current >= target) return 0;   // ← add already-at-goal short-circuit
  final needed = (target * s.totalClasses - s.attendedClasses) / (1 - target);
  return needed.ceil().clamp(0, 999);
}
```

---

### Fix 8 ⚠️ LOW — Remove/Correct `WhatIfBreakdown.diff` Dead Getter
**File:** [`predictor_service.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/predictor/services/predictor_service.dart#L428-L429)

Simply remove the `diff` getter (it is unused). Or if it was intended as `predictedPct - currentPct`:
```dart
// Replace complex wrong formula with:
double get diff => predictedPct - (attendedSoFar / (totalLectures - missedClasses == 0 ? 1 : totalLectures - missedClasses) * 100);
// Becomes:
double get diff => predictedPct - (attendedSoFar / (attendedSoFar + (totalLectures - missedClasses - attendedSoFar) == 0 ? 1 : (totalLectures - missedClasses)) * 100);
// Actually, just use:
double get diff => predictedPct - (attendedSoFar / (totalLectures - missedClasses).clamp(1, 999999) * 100);
```
Or simply delete it since `predictedPct - currentPct` is already computed at call sites.
