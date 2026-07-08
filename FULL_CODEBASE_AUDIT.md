# Attu — Complete Codebase Audit
*AttendanceAI Flutter App — Full unrestricted deep-dive*

---

## Part 0 — Full Project Structure

```
Attu/
├── android/
├── assets/
│   └── .env                          ← Firebase + Razorpay keys (dotenv)
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── pubspec.yaml
└── lib/
    ├── main.dart                      ← Entry point
    ├── firebase_options.dart
    ├── core/
    │   ├── constants/
    │   │   ├── app_colors.dart
    │   │   ├── app_spacing.dart
    │   │   └── app_text_styles.dart
    │   ├── router/
    │   │   └── app_router.dart
    │   └── utils/
    │       └── attendance_calculator.dart
    ├── data/
    │   ├── datasources/
    │   │   └── firestore_datasource.dart
    │   ├── models/
    │   │   ├── attendance_log_model.dart
    │   │   ├── class_session_model.dart
    │   │   ├── semester_model.dart
    │   │   ├── subject_model.dart
    │   │   ├── timetable_entry_model.dart
    │   │   └── user_model.dart
    │   └── repositories/
    │       ├── attendance_repository.dart
    │       ├── auth_repository.dart
    │       ├── subject_repository.dart
    │       └── timetable_repository.dart
    ├── features/
    │   ├── analytics/
    │   ├── attendance/
    │   ├── auth/
    │   ├── dashboard/
    │   ├── notifications/
    │   ├── onboarding/
    │   ├── predictor/
    │   ├── premium/
    │   ├── profile/
    │   ├── subjects/
    │   ├── timetable/
    │   └── timetable_editor/
    └── shared/
        └── widgets/
```

---

## Part 1 — Tech Stack (pubspec.yaml)

| Category | Package |
|----------|---------|
| State Management | `flutter_riverpod` + `riverpod_annotation` |
| Navigation | `go_router` |
| Backend | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` |
| Payments | `razorpay_flutter` |
| Local Notifications | `flutter_local_notifications` |
| Charts | `fl_chart` |
| ML / OCR | `google_mlkit_text_recognition` |
| Image picking | `image_picker` |
| Fonts | `google_fonts` |
| Timezone | `flutter_timezone`, `timezone` |
| Permissions | `permission_handler` |
| Env | `flutter_dotenv` |
| Utilities | `equatable`, `intl`, `uuid` |

---

## Part 2 — Data Architecture

### Firestore Collections (per user, under `users/{uid}/`)

| Collection | Purpose |
|-----------|---------|
| `users/{uid}` | UserModel document — profile, onboarding state, premium |
| `users/{uid}/semesters/{id}` | Semester records — date range, holidays, goal |
| `users/{uid}/subjects/{id}` | SubjectModel — attended/total counters, color, faculty |
| `users/{uid}/attendance_logs/{id}` | AttendanceLogModel — per-event historical log |
| `users/{uid}/timetable_entries/{id}` | TimetableEntry — day/time/subject weekly template |
| `users/{uid}/class_sessions/{id}` | ClassSession — generated daily schedule items with status |
| `users/{uid}/notifications/{id}` | AppNotificationModel — persistent notification center |
| `users/{uid}/notification_settings/prefs` | NotificationPreferences document |
| `users/{uid}/timetable/config` | Grid config: default duration, gridStartHour, gridEndHour |
| `users/{uid}/timetable/config/lectures/{id}` | LectureBlock docs (new timetable editor format) |

### Key Models

**UserModel** — `name`, `email`, `photoUrl`, `collegeName`, `courseName`, `semesterName`, `onboardingComplete` (bool), `onboardingStep` (string key), `attendanceGoal` (double, default 75.0), `themeMode` (system/light/dark), `isPremium` (bool), `premiumPlanType` (monthly/annual), `premiumExpiresAt`, `createdAt`, `updatedAt`

**SubjectModel** — `id`, `name`, `attendedClasses` (int), `totalClasses` (int), `faculty` (nullable), `colorHex` (nullable), `attendanceTarget` (nullable, per-subject override), `createdAt`, `updatedAt`. Computed: `attendancePercentage`, `shortName` (2 chars), `colorFromHex`

**AttendanceLogModel** — `id`, `subjectId`, `subjectName`, `status` (present/absent/cancelled), `date` (Timestamp), `classSessionId` (nullable), `source` (manual/notification), `note` (nullable)

**ClassSession** — `id`, `timetableEntryId`, `subjectId`, `subjectName`, `date` (Timestamp), `startTime` (HH:mm), `endTime` (HH:mm), `status` (notMarked/present/absent/cancelled), `isCancelled`, `displaySubjectName`, `displayStartTime`, `displayEndTime`

**Semester** — `id`, `uid`, `name`, `startDate`, `endDate`, `attendanceGoal` (double), `holidays` (List<DateTime>). Computed: `getDatesForWeekday(int)`, `isHoliday(DateTime)`, `totalWorkingDays`

**LectureBlock** (timetable editor) — `id`, `day` ("MON"–"SUN"), `subjectId`, `startTime` (HH:mm), `durationMinutes`, `facultyName`, `classroom`, `notes`. Computed: `endTime`, `startHour`, `startMinute`

**TimetableEntry** (predictor/old system) — `id`, `day` (full "Monday" etc.), `subject` (name string), `startTime`, `endTime`

---

## Part 3 — Feature-by-Feature Audit

---

### FEATURE: Authentication (`features/auth/`)

**Status: FULLY IMPLEMENTED**

- Screen: `auth_screen.dart` — Google Sign-In via `firebase_auth`
- `auth_repository.dart` — `currentUserProvider` (Firebase `User`), `currentUserProfileProvider` (future → `UserModel`), `authStateChangesProvider` (stream)
- The router's `redirect` logic gates everything behind `isLoggedIn`. If not signed in → `/auth`. If signed in but `!onboardingComplete` → redirect to appropriate onboarding step key

**What's shown in UI:**
- Google Sign-In button on launch screen

---

### FEATURE: Onboarding (`features/onboarding/`)

**Status: FULLY IMPLEMENTED — most complex feature**

8-step linear flow, gated by `UserModel.onboardingStep` + `onboardingComplete`. **Each step persists to Firestore immediately.** Flow can be resumed mid-step on re-launch.

**Steps and screens:**

| Step Key | Route | What It Does |
|----------|-------|-------------|
| `welcome` | `/onboarding/welcome` | Splash/intro screen |
| `college` | `/onboarding/college` | `collegeName`, `courseName`, `year`, `section` (year/section optional) |
| `semester` | `/onboarding/semester` | semester name, start date, end date, `attendanceGoal` (slider, default 75%) |
| `subjects` | `/onboarding/subjects` | Add subjects (name, faculty, per-subject attendance target, color picker) |
| `timetable` | `/onboarding/timetable` | Embeds the full `TimetableGrid` widget (Google Calendar-style). Skippable |
| `holidays` | `/onboarding/holidays` | Calendar date-picker to mark holidays. Skippable |
| `import` | `/onboarding/import` | Import prior attendance — 2 methods (below). Skippable |
| `review` | `/onboarding/review` | Shows summary of all data, "Confirm & Start" button |

**Attendance Import methods (onboarding/import step):**
- **Method A — Manual Count:** User enters "attended X out of Y" per subject
- **Method B — Mark Absent Dates:** User marks specific calendar dates they were absent; app counts from timetable

**Mandatory vs optional:** Steps `welcome`, `college`, `semester`, `subjects` are mandatory. Steps `timetable`, `holidays`, `import` have a "Skip" button and are optional.

**`OnboardingState` fields:** `currentStep`, `isLoading`, `error`, `collegeName`, `courseName`, `year`, `section`, `semesterName`, `semesterStart`, `semesterEnd`, `attendanceGoal`, `semesterId`, `subjects` (List<SubjectModel>), `timetableSkipped`, `holidays`, `holidaysSkipped`, `importData` (Map<subjectId, SubjectImportData>), `importSkipped`

**On Review/Confirm:**
- Calls `_repo.generateClassSessions()` (if timetable not skipped) — generates `class_sessions` from timetable/config/lectures
- Calls `_repo.markComplete()` — sets `UserModel.onboardingComplete = true`
- Router then redirects to main shell (`/dashboard`)

---

### FEATURE: Shell Navigation (Bottom Nav)

**Status: FULLY IMPLEMENTED**

`app_router.dart` defines a `ShellRoute` with a persistent bottom navigation bar. 5 tabs:

| Tab | Route | Screen |
|-----|-------|--------|
| Dashboard | `/dashboard` | `DashboardScreen` |
| Schedule | `/timetable` | `TimetableScreen` |
| Predictor | `/predictor` | `PredictorScreen` |
| Analytics | `/analytics` | `AnalyticsScreen` |
| Profile | `/profile` | `ProfileScreen` |

---

### FEATURE: Dashboard (`features/dashboard/`)

**Status: FULLY IMPLEMENTED**

**What the screen shows:**
1. **Sticky App Bar** — CircleAvatar (Google photo or initials), "Welcome back, [first name]", notification bell icon with unread badge count (real-time, animates shape for 99+)
2. **Hero Attendance Card** (`hero_attendance_card.dart`) — circular progress ring showing overall %, safe bunks count, classes needed to recover. Color-coded by threshold. Tappable.
3. **"Can I Bunk Tomorrow?" CTA button** — color changes by `BunkStatus` (safe=primary/green, risky=warning yellow, mustAttend=error red). Tap opens bottom sheet with verdict + message.
4. **Subject Overview section header** — "History" button → `/attendance/history`, "View All" → `/subjects`
5. **Subject cards** — shows up to 5 subjects, each a `SubjectCard` with progress bar. Empty state if no subjects. Tap → `/subjects/detail`
6. **Recent Notifications Card** (`recent_notifications_card.dart`) — inline preview of recent notifications

**DashboardData computed fields:** `overallPercentage`, `safeBunks` (int), `classesNeeded` (int), `bunkStatus` (enum: safe/risky/mustAttend), `attendanceGoal`, `subjects` (List<SubjectModel>)

**Pull-to-refresh:** invalidates `subjectsStreamProvider`

---

### FEATURE: Schedule / Timetable View (`features/timetable/`)

**Status: FULLY IMPLEMENTED — most complex screen (1331 lines)**

**What `TimetableScreen` shows:**
1. **Date header** — current day + date ("Monday, Jan 5")
2. **Clock-driven invalidation** — a `Timer.periodic(1 minute)` invalidates `schedulePageDataProvider` so class blocks move between time buckets automatically
3. **Session sections** (3 categories):
   - **Action Required** — classes in progress right now → large prominent cards with quick "Present/Absent" mark buttons
   - **Upcoming** — future classes today → shows countdown in minutes/hours
   - **Completed** — past classes → shows marked status or "not marked" indicator
4. **No-timetable empty state** — shows "Set up your timetable" CTA → `/timetable/edit`
5. **No-semester empty state** — shows "Complete setup" CTA
6. **Edit button** → `/timetable/edit` (opens TimetableEditorScreen)
7. **Commented-out OCR button** — `Icons.document_scanner_outlined`, route `/timetable/upload` — disabled, pending OCR feature completion

**`edit_today_schedule_sheet.dart`** — bottom sheet to manually add/cancel classes for today, manage today's one-off session changes

**Key providers used:**
- `todaySessionsStreamProvider` — real-time stream of today's ClassSessions
- `schedulePageDataProvider` — derives buckets (upcoming/action/completed) + counts
- `scheduleNotifierProvider` — handles mark-present, mark-absent, cancel-class, absent-rest-of-day actions

---

### FEATURE: Timetable Editor (`features/timetable_editor/`)

**Status: FULLY IMPLEMENTED — premium-quality custom widget (1356 lines grid file)**

**What it is:** A Google Calendar-style weekly grid editor. Saves LectureBlocks to Firestore at `users/{uid}/timetable/config/lectures/{id}`.

**TimetableGrid widget features:**
- **Continuous timeline grid** — Y axis is real wall-clock time at `1.2px/minute`. No slot-anchoring. Each day is an absolutely-positioned Stack.
- **Subject Library Strip** — horizontal scroll strip pinned below header. Tap to select subject, then tap on grid to place.
- **Placement:** Tap empty space → snaps to nearest 15-min boundary → places selected subject block
- **Quick remove:** Tap an occupied block → confirmation popup
- **Long-press edit:** Opens `cell_bottom_sheet.dart` — time picker, duration picker, notes, faculty, classroom fields
- **Drag to move (Phase D):** Long-press drag implemented with snapping algorithm. Candidates from: flush-after, flush-before, 15-min grid. Conflict-aware (won't land on another block).
- **Conflict detection:** Overlapping blocks highlighted, `ConflictInfo` surfaced to notifier state
- **Grid range config:** `gridStartHour` (default 8), `gridEndHour` (default 22), stored in Firestore `timetable/config`
- **Default duration:** `defaultLectureDurationMinutes` (default 60), configurable in Firestore `timetable/config`
- **"Same-subject contiguous" detection:** Adjacent blocks of same subject suppress the shared border for a merged appearance
- **Sticky time labels** column + sticky day headers row — custom scroll sync

**LectureBlock model fields:** `id`, `day` (MON/TUE/WED/THU/FRI/SAT/SUN), `subjectId`, `startTime` (HH:mm), `durationMinutes`, `facultyName`?, `classroom`?, `notes`?

**Day order:** MON→SAT (6 days shown, SUN defined but not in `kDayOrder`)

**TimetableEditorState computed:** `filledWeekdayCount`, `totalWeeklyLectures`, `hourRows` (list of int hours), `lecturesForDay(day)`, `subjectById(id)`, `lectureAtHour(day, hour)`

---

### FEATURE: Predictor (`features/predictor/`)

**Status: FULLY IMPLEMENTED — V2 active, V1 commented-out but retained**

**Predictor V2 — 4 sections currently live:**

#### Section 1: Bunk Bank Card (`bunk_bank_card.dart`)
- Hero gradient card (blue→dark-blue or red→dark-red based on healthy/critical)
- Total safe bunks counter (large prominent number)
- Per-subject breakdown list, sorted ascending by safe bunks (riskiest first)
- Each row shows: subject name, subject color chip, current %, safe bunk count
- Empty state when no data

#### Section 2: Tomorrow Opportunities Card (`tomorrow_opportunities_card.dart`)
- Only shown when there are classes scheduled tomorrow
- Lists each tomorrow lecture with: subject name, time range, `TomorrowSafety` badge
- **`TomorrowSafety.safeToSkip`** — student has >1 bunk remaining (keeps 1 buffer)
- **`TomorrowSafety.attendRecommended`** — at or near limit
- Multiple lectures of same subject each consume from a per-session decrementing counter (not static `safeBunks` from prediction)
- Hidden automatically when no classes tomorrow

#### Section 3: Leave Planner Card (`leave_planner_card.dart`)
- Date range picker (start–end of planned leave)
- Computes per-subject `pctBefore` → `pctAfter` impact
- Shows `recoveryNeeded` (classes to attend after leave to return to goal)
- Overall before/after delta

#### Section 4: Subjects Requiring Attention Card (`subjects_requiring_attention_card.dart`)
- Only shown when a leave range is selected AND some subjects drop below target
- Shows recovery path per affected subject

**Predictor V1 widgets — commented-out, retained in codebase:**
- `OverallSummaryCard` — hero summary of all subjects
- `SubjectPredictionCard` — per-subject card with prediction details
- `WhatIfSimulator` — bottom sheet: slider for "miss X classes", shows predictedPct + minPresentNeeded + isAchievable
- `RiskRadarSection` — risk levels at a glance (visual radar)
- `SemesterForecastCard` — projected % by semester end
- `_SubjectFilterBar` — filter by subject

**PredictorService (pure Dart, fully implemented):**
- `computePredictions()` — builds `SubjectPrediction` for each subject (currentPct, safeBunks, riskLevel, classesNeeded, projectedPct, remainingClasses)
- `simulateMiss()` — what-if single-subject bunk simulation
- `whatIfBreakdown()` — full breakdown: predictedPct, totalLectures, remainingAfterBunk, minPresentNeeded, isAchievable
- `simulateLeave()` — date-range leave simulation across all subjects
- `safeUntilDate()` — computes last date student can safely skip a subject
- `tomorrowOpportunities()` — per-lecture safety analysis for tomorrow
- `recoveryDate()` — earliest date student recovers to goal% after leave
- `overallCurrentPct()`, `overallProjectedPct()`, `totalSafeBunks()`, `criticalCount()`
- `_buildRemainingMap()` — generates remaining class counts from timetable entries + semester (no Firestore)

**Risk Levels:** `critical` (below goal), `warning` (above goal but ≤2 safe bunks), `safe` (>2 safe bunks)

**PredictorData container:** `predictions`, `entries`, `semester`, `overallCurrentPct`, `overallProjectedPct`, `totalSafeBunks`, `criticalCount`, `goal`

---

### FEATURE: Analytics (`features/analytics/`)

**Status: FULLY IMPLEMENTED**

**What the screen shows (770 lines):**

1. **Summary cards row:**
   - Overall Attendance % (large number + linear progress bar)
   - Subjects tracked count

2. **Stats mini-cards row:**
   - Total Attended (green)
   - Total Missed (red)
   - Total Classes (primary)

3. **Attendance Trends section:**
   - Line chart (fl_chart `LineChart`) — Y axis = attendance %, X axis = date
   - **Period toggle:** Week / Month / Semester
   - `trendDataProvider` derives chart spots from `attendanceLogsStreamProvider`
   - `analyticsPeriodNotifierProvider` manages selected period

4. **Subject Comparison section:**
   - Horizontal bar-style comparison — each subject: name, %, LinearProgressIndicator colored by percentage

5. **Heatmap section:**
   - `heatmapDataProvider` — calendar-style attendance heatmap
   - Color intensity by daily attendance rate

6. **AI Insights section:**
   - `analyticsInsightsProvider` — derives text insights from logs (best day, worst day, streak)

**Key providers:**
- `attendanceLogsStreamProvider` — single canonical Firestore stream of all logs
- `analyticsSummaryProvider` — derived: totalAttended, totalMissed, totalClasses, overallPercentage, totalSubjects
- `analyticsInsightsProvider` — derived text insights
- `analyticsPeriodNotifierProvider` — week/month/semester selection
- `trendDataProvider` — List<FlSpot> for chart
- `heatmapDataProvider` — calendar grid data

---

### FEATURE: Subjects (`features/subjects/`)

**Status: FULLY IMPLEMENTED**

**Screens:**

**`SubjectsScreen`** (list view):
- All subjects in a ListView
- Each row: `_SubjectListTile` with attendance %, progress bar, edit/delete actions
- FAB "Add Subject" → `/subjects/add`
- Tap subject → `/subjects/detail` (passes SubjectModel as extra)

**`AddEditSubjectScreen`** (`/subjects/add`, `/subjects/edit`):
- Fields: name (required), faculty (optional), per-subject attendance target (optional slider), color picker
- Color picker: 12-color palette (stored as `colorHex` string e.g. `#E57373`)

**Subject Detail Screen** (`/subjects/detail`):
- Shows full subject stats: attended, total, %, progress
- History of attendance logs for this subject
- Quick mark buttons (Present/Absent)

**Providers:**
- `subjectsStreamProvider` — real-time stream via `firestoreDatasource.watchSubjects(uid)`
- `subjectRepositoryProvider` — add, edit, delete subjects

---

### FEATURE: Attendance History (`features/attendance/`)

**Status: FULLY IMPLEMENTED (983 lines)**

**AttendanceHistoryScreen shows:**
1. **Stats Strip** — summary totals (attended/missed/total) + overall %
2. **Filter Row** — filter by: subject (dropdown), status (present/absent/cancelled), date range
   - When active filter: `Filter active` indicator + clear-filter icon in AppBar
3. **Grouped log list** — logs grouped by date (most recent first)
   - Each group: date header + list of `AttendanceLogItem` rows
   - Each row: subject name (colored chip), status chip (✅/❌/🚫), timestamp, source (manual/notification), optional note
   - **Swipe-to-delete** on each log row

**AttendanceFilter fields:** `subjectId` (nullable), `status` (nullable AttendanceStatus), `startDate` (nullable), `endDate` (nullable). Computed: `isActive`

**AttendanceStats fields:** `totalAttended`, `totalMissed`, `totalCancelled`, `totalClasses`, `overallPercentage`

**Key providers:**
- `attendanceLogsStreamProvider` — canonical single Firestore listener
- `groupedLogsProvider` — derives Map<dateString, List<AttendanceLog>> with filter applied
- `filteredStatsProvider` — derives stats from filtered logs
- `attendanceFilterNotifierProvider` — manages filter state

---

### FEATURE: Notifications (`features/notifications/`)

**Status: FULLY IMPLEMENTED — most sophisticated system**

#### Notification Types

| Type | Where stored | Description |
|------|-------------|-------------|
| Class Reminder | Device-only | N minutes before class starts |
| Attendance Marking | Device-only | N minutes after class ends: "Did you attend?" with action buttons |
| Attendance Danger Alert | Device + Firestore | Daily: subjects below goal% |
| Critical Attendance Alert | Device + Firestore | Daily: subjects below critical threshold (configurable, default 65%) |
| Nightly Bunk Planner | Device + Firestore | Evening: which tomorrow classes are safe to skip |

#### NotificationService (singleton)
- `initialize()` — sets up flutter_local_notifications, creates Android channels, configures timezone
- `showClassReminder()` — immediate show (title + action button "❌ Absent Today")
- `showAttendanceMarking()` — immediate show with actions: "✅ Present", "❌ Absent", "🏠 Absent Rest of Day" (if enabled)
- `showLowAttendanceAlert()` — immediate show
- `showSafeBunkPlanner()` — immediate show (big-text style)
- `showDailySummary()` — immediate show (daily summary — currently disabled in scheduler)
- `scheduleOnce()` — scheduleZoned with exact alarm
- `scheduleDaily()` — repeating daily at a configured time
- `cancelNotification()`, `cancelAll()`, `cancelClassReminder()`, `cancelAttendanceReminder()`
- `isPending(id)` — checks if a notification is in the pending queue

#### NotificationScheduler (singleton)
- `rescheduleAll()` — master entry point (called on login, timetable changes, app start)
- `scheduleClassReminders()` — respects `onlyFirstClassReminder` and `gapClassRemindersEnabled` (only reminds for classes with gap ≥ N minutes from previous)
- `scheduleAttendanceReminders()` — per class, fires `attendanceDelayMinutes` after end
- `checkDailyAttendanceAlerts()` — deduped per day via `repo.hasWarningFiredToday()`; computes fire time as 2h after last session
- `scheduleSafeBunkPlanner()` — daily repeating at `plannerTime`; writes to Firestore notification center too

#### Notification Action Handler (`handlers/attendance_notification_action_handler.dart`)
- Handles action button taps from notification tray (even when app is terminated — uses `@pragma('vm:entry-point')`)
- Actions: `action_present` → marks ClassSession present, `action_absent` → absent, `action_absent_rest_of_day` → absent all remaining today, `action_absent_today` → absent current session
- Re-initializes Firebase if fresh isolate

#### NotificationPreferences model (full list of settings):
- `notificationsEnabled`, `soundEnabled`, `vibrationEnabled`, `badgeCount`
- `quietHoursStart`, `quietHoursEnd` (TimeOfDay, supports overnight ranges)
- `classRemindersEnabled`, `reminderMinutes` (5/10/15/30), `onlyFirstClassReminder`, `gapClassRemindersEnabled`, `gapMinutes` (30/45/60)
- `attendanceRemindersEnabled`, `attendanceDelayMinutes` (0/5/10), `absentRestOfDayEnabled`, `autoDismissMinutes`
- `lowAttendanceAlertsEnabled`, `recoverySuggestionsEnabled`
- `criticalAttendanceEnabled`, `criticalThreshold` (double, 0–100, default 65.0)
- `safeBunkPlannerEnabled`, `plannerTime` (TimeOfDay, default 22:00), `includeSafeBunks`, `plannerIncludeRecoverySuggestions`, `includeRiskSubjects`
- `dailySummaryEnabled` (default false), `summaryTime`, `includeClassesAttended`, `includeClassesMissed`, `includeSubjectBreakdown`, `includeOverallAttendance`

#### Notification Center Screen (`notification_center_screen.dart`)
- Groups notifications: **Today**, **This Week**, **This Month**, **Older**
- Pagination: initial 20, "Load more" button (Firestore cursor)
- First page is real-time (stream)
- "Mark all read" action button
- `unreadNotificationCountProvider` — stream of unread count (drives AppBar badge)
- Empty state, loading skeleton

#### Notification Settings Screen (`notification_settings_screen.dart`, 750 lines)
- Full settings UI for every preference in `NotificationPreferences`
- Local copy pattern: changes apply instantly to UI, then save to Firestore
- Permission request button for Android 13+
- Quiet hours time pickers

---

### FEATURE: Premium (`features/premium/`)

**Status: FULLY IMPLEMENTED — Razorpay payment wired**

**Plans:**
- Monthly: ₹20/month (2000 paise)
- Annual: ₹200/year (20000 paise), "Best Value" badge

**PremiumScreen states (3 distinct views):**
1. **Free user** — hero card + features list + both plan cards with purchase CTAs
2. **Monthly subscriber** — active plan chip + annual upgrade prompt
3. **Annual subscriber** — success state "You're on the best plan!" card

**RazorpayService:**
- `openCheckout()` — reads `RAZORPAY_KEY_ID` from dotenv
- Emits `PaymentSuccess`, `PaymentFailure`, `PaymentExternalWallet` via StreamController
- On success → calls `premiumNotifierProvider.activatePremium(planType, paymentId)` → writes to Firestore → shows success snackbar → `context.pop()` after 800ms delay

**PremiumState fields:** `isPremium`, `planType` (monthly/annual/null), `expiresAt` (DateTime?)

**Premium features list shown in UI** (all currently aspirational/marketing copy, not all gated in code):
- Unlimited subjects tracking
- AI-powered bunk predictions
- Advanced analytics & charts
- Attendance heatmap
- Export attendance reports
- Priority customer support
- Custom attendance goals
- Offline mode support

---

### FEATURE: Profile (`features/profile/`)

**Status: FULLY IMPLEMENTED**

**ProfileScreen sections:**
1. **Avatar / Name / Email** — Google profile photo or initials avatar
2. **Attendance Goal** — slider (50–100%, step 10) with live % display; saves on drag-end
3. **Appearance** — System/Light/Dark theme selection (radio-style tiles with animation)
4. **More section:**
   - Premium tile (3 states: free→upgrade CTA, monthly→annual upgrade, annual→active status)
   - Notification Settings → `/notifications/settings`
   - Edit Timetable → `/timetable/edit`
   - Help & Support (onTap is empty `{}` — placeholder only)
   - About AttendanceAI — "Version 1.0.0" (static text)
5. **Sign Out** button — confirm dialog, then `profileNotifierProvider.signOut()`

**profileNotifierProvider** methods: `updateGoal(double)`, `updateTheme(String)`, `signOut()`

---

## Part 4 — Core Calculation Engine

### AttendanceCalculator (utility class — pure Dart)

| Method | Formula |
|--------|---------|
| `calculatePercentage(attended, total)` | `(attended / total) * 100` |
| `getSafeBunks(attended, total, target)` | `floor(attended / (target/100) - total)` |
| `getClassesNeeded(attended, total, target)` | `ceil((target*total - attended) / (1 - target))` |
| `canIBunk(attended, total, target)` | Returns BunkStatus: safe if afterBunk ≥ target AND safeBunks > 2; risky if afterBunk ≥ target; mustAttend otherwise |
| `simulateFutureAttendance(...)` | Projects % given future attended + missed |
| `getStatus(percentage, target)` | Returns AttendanceStatus enum: excellent (target+10), good (target+5), safe (target), risky (target-5), critical |

**BunkStatus enum:** `safe`, `risky`, `mustAttend`
**AttendanceStatus enum:** `excellent`, `good`, `safe`, `risky`, `critical`

### PredictorService (pure Dart, static methods)

All calculations described above in the Predictor feature section. Key distinction: operates entirely on locally-fetched data — **zero additional Firestore reads after initial load.**

---

## Part 5 — Design System

### AppColors

**Light mode:**
- `primary`: #004AC6 (deep blue)
- `primaryContainer`: #2563EB
- `primaryFixed`: #DBE1FF (light lavender)
- `secondary`: #505F76
- `tertiary`: #943700 (rust/orange)
- `error`: #BA1A1A
- `success`: #16A34A (green)
- `successContainer`: #DCFCE7
- `warning`: #CA8A04 (amber)
- `background`/`surface`: #FAF8FF (near-white lavender)

**Dark mode:**
- `darkPrimary`: #B4C5FF (light lavender)
- `darkOnPrimary`: #002576
- `darkPrimaryContainer`: #003EA8
- `darkSurface`: #111318 (near-black)
- `darkSurfaceContainer`: #1E2028

### AppSpacing
- `xs`, `sm`, `md`, `lg`, `xl`, `xxl` — standard spacing values
- `radiusSm`, `radiusMd`, `radiusLg`, `radiusFull` — border radius tokens

### AppTextStyles
- `displayLg` — large display text
- `headlineLgMobile`, `headlineLg`, `headlineMd` — section headings
- `bodyLg`, `bodySm` — body text
- `labelMd`, `labelCaps` — label/caps text

---

## Part 6 — Running Lists

---

### LIST 1: IMPLEMENTED BUT NOT SURFACED IN UI

| Item | Where it lives | Notes |
|------|---------------|-------|
| `simulateFutureAttendance()` in AttendanceCalculator | `core/utils/attendance_calculator.dart` | Fully implemented, not called from any UI |
| `safeUntilDate()` in PredictorService | `predictor_service.dart:342` | Computes last safe skip date — no widget displays this |
| `recoveryDate()` in PredictorService | `predictor_service.dart:465` | Computes recovery date after leave — computed but not displayed |
| `getStatus()` / `AttendanceStatus` enum | `attendance_calculator.dart:84` | Returns excellent/good/safe/risky/critical — not surfaced in Dashboard or subject cards |
| `simulateFutureAttendance()` | `attendance_calculator.dart:72` | Exists, no callers found in UI |
| `subjectById(id)` on TimetableEditorState | `timetable_editor_models.dart:207` | Utility method, presumably used internally |
| `lectureAtHour(day, hour)` on TimetableEditorState | `timetable_editor_models.dart:217` | Legacy hour-based lookup — grid now uses continuous pixels |
| `filledWeekdayCount`, `totalWeeklyLectures` on TimetableEditorState | `timetable_editor_models.dart:234-240` | Stats never displayed in UI |
| `_hasTimetableEntriesProvider` | `timetable_screen.dart:20` | Used internally to control empty state — not shown as a displayed stat |
| `UserModel.section` | `user_model.dart` | Collected in onboarding → never displayed anywhere post-onboarding |
| `UserModel.year` | `user_model.dart` | Same — collected but not displayed |
| `LectureBlock.classroom` | `timetable_editor_models.dart:42` | Stored in Firestore, editable in cell_bottom_sheet — never displayed on the grid block or schedule view |
| `LectureBlock.notes` | `timetable_editor_models.dart:43` | Same as classroom |
| `AppNotificationModel.payload` | `app_notification_model.dart:56` | Stored to Firestore, never used for deep-link navigation from notification center |
| `NotificationPreferences.dailySummaryEnabled` | `notification_preferences_model.dart:47` | Full model field, Firestore-synced, settings toggle exists — but `NotificationScheduler` has `cancelNotification(summaryNotificationId)` comment "Daily Summary was removed" |
| `NotificationPreferences.autoDismissMinutes` | preferences model | Model field + settings toggle exists — no code in scheduler acts on it |
| `NotificationPreferences.includeSubjectBreakdown` | preferences model | Flag exists but daily summary is disabled |

---

### LIST 2: UI SHELL ONLY (UI exists, backing logic missing or placeholder)

| Item | Screen | Status |
|------|--------|--------|
| **Help & Support** | Profile screen → "Help & Support" tile | `onTap: () {}` — empty callback, no screen exists |
| **About AttendanceAI** | Profile screen → "About" tile | Static "Version 1.0.0" text, `onTap: () {}` — no about screen |
| **OCR / Import Timetable button** | TimetableScreen AppBar | Commented out: `Icons.document_scanner_outlined`, route `/timetable/upload` — screen not implemented |
| **Export attendance reports** | Listed as a premium feature in PremiumScreen | No export screen, no export logic anywhere |
| **Offline mode support** | Listed as a premium feature in PremiumScreen | No offline/caching layer implemented |
| **"Unlimited subjects tracking"** | Premium feature bullet | No subject count limit enforcement in free-tier code |
| **`RecentNotificationsCard`** | Dashboard | Widget imported and placed — needs verification of content (likely a minimal preview strip) |

---

### LIST 3: PARTIALLY IMPLEMENTED

| Item | What exists | What's missing |
|------|------------|---------------|
| **OCR Timetable Import** | `google_mlkit_text_recognition` is in pubspec.yaml; `image_picker` is in pubspec; button was commented out in timetable screen | No screen, no parsing logic, no route `/timetable/upload` |
| **Attendance Import — Method B (absent dates)** | Full state model (`SubjectImportData.absentDates`), `toggleAbsentDate()`, calendar UI in onboarding | `_repo.saveAbsentDates()` needs timetable entries to count classes — the comment says it reads from `timetable/config/lectures` but correctness depends on timetable being set up first; calendar may show wrong range if timetable skipped |
| **Per-subject attendance targets** | `SubjectModel.attendanceTarget` (nullable), onboarding add-subject form has the slider | `PredictorService.computePredictions()` uses a global `goal` — per-subject `attendanceTarget` is never passed to the predictor engine |
| **Daily Summary notification** | Full model, preferences toggle, `showDailySummary()` method | `NotificationScheduler.rescheduleAll()` explicitly calls `_svc.cancelNotification(summaryNotificationId)` — feature was built then commented out |
| **What-If Simulator** | `WhatIfBreakdown`, `PredictorService.whatIfBreakdown()`, `WhatIfSimulator` widget (commented out) | V1 widget commented out; V2 does not include it |
| **Risk Radar** | `RiskRadarSection` widget (commented out) | Commented out in V1, not ported to V2 |
| **Semester Forecast card** | `SemesterForecastCard` widget (commented out) | Commented out in V1, not ported to V2 |
| **Notification badge count on app icon** | `NotificationPreferences.badgeCount` bool, field synced to Firestore | No `flutter_app_badge` or equivalent package in pubspec — field has no effect |
| **`autoDismissMinutes` for attendance notifications** | Preference model field (0=never, 60, -1=end-of-day) | No timer code in scheduler to auto-cancel after X minutes |
| **`recoverySuggestionsEnabled` preference** | Bool in preferences | Only used in `showLowAttendanceAlert` body text — not wired to suppress/show recovery suggestions elsewhere |

---

### LIST 4: DEAD CODE / UNUSED

| Item | File | Notes |
|------|------|-------|
| Legacy Firestore datasource methods | `firestore_datasource.dart` | Multiple deprecated `timetable` collection methods still present — marked deprecated in code comments. New system uses `timetable_entries` and `timetable/config/lectures`. |
| `UserModel.onboardingStep` old step names | `user_model.dart` | If legacy step strings exist in Firestore from old users, the router fallback handles them — but the old step enum values may exist as strings |
| Predictor V1 widget files in `features/predictor/widgets/` | `overall_summary_card.dart`, `risk_radar_section.dart`, `semester_forecast_card.dart`, `subject_prediction_card.dart`, `what_if_simulator.dart` | All import lines are commented out in `predictor_screen.dart`; the files themselves still exist on disk |
| `_SubjectFilterBar` in predictor | `predictor_screen.dart:150` | Commented out |
| `TimetableEditorState.lectureAtHour()` | `timetable_editor_models.dart:217` | Grid migrated to continuous pixel layout; this hour-based lookup is superseded |
| `NotificationService.showClassReminder()`, `showAttendanceMarking()`, `showLowAttendanceAlert()`, `showSafeBunkPlanner()`, `showDailySummary()` | `notification_service.dart` | These immediate-show methods are bypassed by `NotificationScheduler.scheduleOnce()`; the scheduler calls `_svc.scheduleOnce()` directly. The immediate-show versions are only called in some old test paths. |
| `stableNotificationId()` function | `notification_service.dart` (imported by scheduler) | Used correctly — not dead, just worth noting it's a shared hash function |
| `AttendanceStatus.excellent`, `.good` in AttendanceCalculator | `attendance_calculator.dart` | `getStatus()` returns these but no UI reads them |
| Empty onTap handlers in Profile | `profile_screen.dart:234, 244` | Help & About tiles have `onTap: () {}` |

---

## Part 7 — Navigation Map

```
/auth                           AuthScreen
/onboarding/welcome             WelcomeScreen
/onboarding/college             CollegeScreen
/onboarding/semester            SemesterScreen
/onboarding/subjects            SubjectsSetupScreen
/onboarding/timetable           TimetableSetupScreen (embeds TimetableGrid)
/onboarding/holidays            HolidaysScreen (calendar date-picker)
/onboarding/import              AttendanceImportScreen
/onboarding/review              ReviewScreen

Shell (persistent bottom nav):
  /dashboard                    DashboardScreen
  /timetable                    TimetableScreen
  /predictor                    PredictorScreen
  /analytics                    AnalyticsScreen
  /profile                      ProfileScreen

Full-screen routes:
  /subjects                     SubjectsScreen
  /subjects/add                 AddEditSubjectScreen (add mode)
  /subjects/edit                AddEditSubjectScreen (edit mode, extra=SubjectModel)
  /subjects/detail              SubjectDetailScreen (extra=SubjectModel)
  /attendance/history           AttendanceHistoryScreen
  /timetable/edit               TimetableEditorScreen
  /notifications/center         NotificationCenterScreen
  /notifications/settings       NotificationSettingsScreen
  /premium                      PremiumScreen

Commented-out / unimplemented:
  /timetable/upload             (OCR import — no screen yet)
```

---

## Part 8 — Firestore Security Summary

Security rules file exists (`firestore.rules`). Pattern: all writes require `request.auth.uid == userId` path match. Read/write scoped to `users/{userId}/**`.

---

## Part 9 — Key Gotchas for UI Redesign

1. **Two timetable systems coexist.** `TimetableEntry` (day/subject-name based, used by PredictorService) and `LectureBlock` (subjectId-based, day-abbrev, used by TimetableGrid). The `TimetableRepository.generateClassSessions()` bridges them. When redesigning, do not conflate these — they serve different roles.

2. **`ClassSession` is the live daily schedule unit.** The Schedule tab works entirely from `ClassSession` documents. Timetable entries are templates. Sessions are generated once (at onboarding complete or manual regeneration).

3. **`AttendanceGoal` lives in 3 places.** `UserModel.attendanceGoal`, `SubjectModel.attendanceTarget` (per-subject override, nullable), and `Semester.attendanceGoal`. Dashboard and Predictor both read from `attendanceGoalProvider` which derives from `UserModel`. Per-subject target is stored but not wired to the predictor engine.

4. **Predictor is entirely local computation.** Once `predictorDataProvider` loads subjects + timetable entries + semester from Firestore, all predictor math happens in pure Dart. Zero additional reads for any calculation.

5. **Notification scheduler must be called after timetable changes.** The scheduler is not reactive — it's imperative (`rescheduleAll`). If timetable is edited, the caller must explicitly invoke the scheduler.

6. **OCR is a ghost feature.** `google_mlkit_text_recognition` and `image_picker` are both in pubspec and can be enabled anytime, but the screen and parsing logic do not exist yet.

7. **Premium enforcement is not implemented.** The "Unlimited subjects", "AI predictions" etc. listed as premium features are marketing copy only. No code gates any feature behind `isPremium`.

8. **Attendance import Method B has a dependency.** It requires a timetable to be set up (to count schedule-based absences). If the user skipped timetable setup and also chose Method B import, the absence counting may be zero or broken.

9. **`section` and `year` fields are collected but go nowhere.** The UI never reads them after onboarding. Available in `UserModel` / `OnboardingState` for future use.

10. **`LectureBlock.classroom` and `.notes` are edited in the cell bottom sheet but never displayed** on the grid blocks or in the Schedule screen's session cards.
