# Attendance AI — Complete Architecture Audit

> **Codebase:** `c:\Users\Abhishek\OneDrive\Desktop\Projects\Attu\lib`  
> **Stack:** Flutter + Riverpod (code-gen) + Firestore + go_router  
> **Audit Date:** 2026-06-16

---

## SECTION 1 — STATE MANAGEMENT

### 1. What state management solution is used?

**Primary: Riverpod with code generation (`riverpod_annotation` + `riverpod_generator`).**

Every provider file uses `@riverpod` annotations and has a companion `.g.dart` file.  
No Provider, Bloc, GetX, or plain `ChangeNotifier` is used anywhere in the provider layer.

| Pattern | Where Used |
|---|---|
| `@riverpod` auto-dispose providers | All feature providers |
| `StreamProvider` (via `@riverpod` returning `Stream<T>`) | Subjects, Sessions, Logs, Overrides |
| `AsyncNotifier` / `Notifier` (via code-gen) | Dashboard, Schedule, SubjectsNotifier, LogEditNotifier |
| `setState()` | Timetable screens (form state only), Auth screens |

**`setState()` is used in screen-local widget state, not for shared data** — this is the correct pattern for UI-only state like loading spinners and form toggles. It is *not* used as a substitute for global state.

---

### 2. Screens still relying on local widget state (`setState`)

| File | `setState` usage |
|---|---|
| [`timetable_screen.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/timetable/screens/timetable_screen.dart#L32) | `_completedExpanded` toggle + per-card `_isLoading` flag |
| [`timetable_review_screen.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/timetable/screens/timetable_review_screen.dart#L473) | `_selectedDay` dropdown |
| [`manual_entry_screen.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/timetable/screens/manual_entry_screen.dart#L184) | `_isNewSubject`, `_selectedDay`, `_startTime`, `_endTime` form fields |
| [`manage_timetable_screen.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/timetable/screens/manage_timetable_screen.dart#L446) | `_deleteSessions` checkbox toggle |
| [`add_edit_subject_screen.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/subjects/screens/add_edit_subject_screen.dart#L53) | `_saving` flag |
| [`profile_screen.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/profile/screens/profile_screen.dart#L129) | `_goalDirty` slider state |
| [`premium_screen.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/premium/screens/premium_screen.dart#L51) | `_purchasingPlan` flag |
| [`notification_settings_screen.dart`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/notifications/screens/notification_settings_screen.dart#L55) | `_local` prefs copy + `_loading` |
| Auth screens | `_obscure`, `_loading`, `_sent` flags |

**Assessment:** These are all valid local UI states. The concern is `notification_settings_screen.dart` which keeps a *full local copy* of notification preferences (`_local`) and only pushes to Firestore on save — this creates a window where local state diverges from server state.

---

### 3. Same piece of data in multiple providers?

**YES — attendance logs are duplicated across three separate stream providers:**

| Provider | File | Stream source |
|---|---|---|
| `attendanceLogsStreamProvider` | [`attendance_history_provider.dart:110`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/attendance/providers/attendance_history_provider.dart#L110) | `attendanceRepository.watchAllLogs()` |
| `analyticsLogsStreamProvider` | [`analytics_provider.dart:89`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/analytics/providers/analytics_provider.dart#L89) | `attendanceRepository.watchAllLogs()` |
| `subjectLogsStreamProvider(id)` | [`subject_detail_provider.dart:31`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/subjects/providers/subject_detail_provider.dart#L31) | `attendanceRepository.watchLogsForSubject(id)` |

Both `attendanceLogsStreamProvider` and `analyticsLogsStreamProvider` call `watchAllLogs()` independently — this opens **two separate Firestore listeners** returning the same 500-doc stream.

---

### 4. Single Source of Truth

| Data Domain | Source of Truth | Provider | Notes |
|---|---|---|---|
| **Subjects** | `users/{uid}/subjects` | `subjectsStreamProvider` (dashboard_provider.dart) | ✅ Single stream. Counter fields (`attendedClasses`, `totalClasses`) are denormalized here. |
| **Attendance** | `users/{uid}/attendance_logs` | `attendanceLogsStreamProvider` + `analyticsLogsStreamProvider` | ❌ **Two separate streams for the same collection** |
| **Timetable** | `users/{uid}/timetable_entries` + `users/{uid}/class_sessions` | `todaySessionsStreamProvider` | ⚠️ Split across two collections with no enforced link |
| **Notifications** | `users/{uid}/notification_preferences` | `notificationPreferencesProvider` | ✅ Single source |
| **User Profile** | `users/{uid}` | `userProfileProvider` | ⚠️ Fetched with `Future` (one-shot), not a stream — no realtime updates |

---

## SECTION 2 — DATA FLOW

### Flow: Mark Attendance

```
UI (timetable_screen.dart)
  └─ _ActionRequiredCard.onMark(status)
       └─ scheduleNotifierProvider.notifier.markAttendance(session, status)
            └─ timetable_repository.markSessionAttendance(session, status)
                 ├─ [1] firestore_datasource.getLogForSession(uid, session.id)
                 │       → query: attendance_logs WHERE sessionId == session.id LIMIT 1
                 │       → returns null (first mark) or existing log
                 │
                 ├─ [2a] First mark → firestore_datasource.logAttendance(uid, newLog)
                 │       → WriteBatch:
                 │          • SET attendance_logs/{logId}
                 │          • UPDATE subjects/{subjectId} (attendedClasses++, totalClasses++)
                 │
                 ├─ [2b] Re-mark → firestore_datasource.updateAttendanceLog(uid, log, oldStatus)
                 │       → WriteBatch:
                 │          • SET attendance_logs/{logId}
                 │          • UPDATE subjects/{subjectId} (delta correction)
                 │
                 └─ [3] UPDATE class_sessions/{sessionId} {status: status.name}

State Update (automatic via streams):
  • subjectsStreamProvider emits new list (subject counters updated)
  • todaySessionsStreamProvider emits new sessions (session status updated)
  • attendanceLogsStreamProvider emits new logs
  • analyticsLogsStreamProvider emits new logs (SEPARATE LISTENER, SAME DATA)
  • dashboardNotifierProvider recomputes from subjectsStreamProvider
  • schedulePageDataProvider recomputes from todaySessionsStreamProvider
  • notificationSchedulerWatcherProvider fires → rescheduleAll()

UI Refresh: Automatic — Riverpod invalidates all watchers of changed streams.
```

**Files involved:** `timetable_screen.dart`, `timetable_provider.dart`, `timetable_repository.dart`, `firestore_datasource.dart`, `attendance_log_model.dart`, `class_session_model.dart`, `subject_model.dart`

---

### Flow: Edit Subject (Rename)

```
UI (add_edit_subject_screen.dart)
  └─ _save() → setState(_saving = true)
       └─ subjectRepositoryProvider.updateSubject(subject.copyWith(name: newName))
            └─ firestore_datasource.updateSubject(uid, subject)
                 → UPDATE users/{uid}/subjects/{id}
                    { name: newName, updatedAt: serverTimestamp() }

State Update:
  • subjectsStreamProvider emits (subject name updated)
  • dashboardNotifierProvider recomputes
  • subjectDetailProvider recomputes (uses subjectsStreamProvider)

❌ NOT UPDATED:
  • attendance_logs.subjectName (denormalized — stale!)
  • class_sessions.subjectName (denormalized — stale!)
  • timetable_entries.subject (raw name — stale!)
  • notification payloads (still reference old name)
```

**Files involved:** `add_edit_subject_screen.dart`, `subject_repository.dart`, `firestore_datasource.dart`

---

### Flow: Delete Subject

```
UI (subject_detail_screen.dart or subjects_screen.dart)
  └─ subjectRepositoryProvider.deleteSubject(subjectId)
       └─ firestore_datasource.deleteSubject(uid, subjectId)
            → DELETE users/{uid}/subjects/{id}

State Update:
  • subjectsStreamProvider emits (subject removed)
  • dashboardNotifierProvider recomputes

❌ NOT CLEANED UP:
  • attendance_logs WHERE subjectId == deletedId → ORPHANED
  • class_sessions WHERE subjectId == deletedId → ORPHANED
  • timetable_entries WHERE subject == deletedName → ORPHANED
  • notification_preferences alerts for this subject → ORPHANED
  • daily_overrides referencing this subjectId → ORPHANED
```

**Files involved:** `subject_detail_screen.dart`, `subjects_screen.dart`, `subject_repository.dart`, `firestore_datasource.dart`

---

### Flow: Edit Schedule (Timetable Entry)

```
UI (manage_timetable_screen.dart)
  └─ timetableRepositoryProvider.updateTimetableEntry(id, entry)
       └─ _entriesCol.doc(id).set(entry.toMap())
            → SET users/{uid}/timetable_entries/{id}

State Update:
  • timetableEntriesStreamProvider emits

❌ NOT UPDATED:
  • class_sessions already generated from old entry (future sessions use OLD times)
  • attendance_logs referencing old times (startTime/endTime denormalized)
  • notification schedules (still use old session times)
```

---

### Flow: Daily Override

```
UI (edit_today_schedule_sheet.dart)
  └─ scheduleNotifierProvider.notifier.saveOverride(override)
       └─ timetableRepositoryProvider.saveDailyOverride(override)
            └─ firestore_datasource.saveDailyOverride(uid, override)
                 → SET users/{uid}/daily_overrides/{dateKey}/sessions/{overrideId}

State Update:
  • todayOverridesStreamProvider emits
  • schedulePageDataProvider recomputes (_applyOverrides merges overrides into sessions)

✅ This flow is largely correct — overrides are streamed and applied in-memory.
⚠️ Gap: notification reschedule does NOT re-run after an override is saved.
    (notificationSchedulerWatcherProvider watches todaySessionsStreamProvider, 
     NOT todayOverridesStreamProvider — so notifications keep the pre-override schedule)
```

---

## SECTION 3 — SUBJECT DATA CONSISTENCY

### Every location where subject information is stored:

#### 1. `users/{uid}/subjects/{subjectId}` — The Master Record
| Field | Present? |
|---|---|
| `name` (subjectName) | ✅ Yes |
| `id` (subjectId) | ✅ Yes (doc ID) |
| Primary reference | ✅ YES — this is the source of truth |
| Rename causes stale data? | ❌ No — this IS the source |
| Delete leaves orphans? | ❌ No — this is the origin |

---

#### 2. `users/{uid}/class_sessions/{sessionId}` — Denormalized
| Field | Present? |
|---|---|
| `subjectName` | ✅ Yes — stored at creation time |
| `subjectId` | ✅ Yes |
| Primary reference | Both stored; `subjectId` is foreign key |
| Rename causes stale data? | ✅ **YES — subjectName is never updated after session creation** |
| Delete leaves orphans? | ✅ **YES — sessions remain with dangling subjectId** |

Code reference: [`timetable_repository.dart:248`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/repositories/timetable_repository.dart#L248) — `subjectName: entry.subject` baked in at write time.

---

#### 3. `users/{uid}/attendance_logs/{logId}` — Denormalized
| Field | Present? |
|---|---|
| `subjectName` | ✅ Yes (nullable — old logs may lack it) |
| `subjectId` | ✅ Yes |
| Primary reference | `subjectId` is foreign key; `subjectName` is display-only cache |
| Rename causes stale data? | ✅ **YES — subjectName in old logs shows the OLD name** |
| Delete leaves orphans? | ✅ **YES — logs remain referencing deleted subjectId** |

Code reference: [`attendance_log_model.dart:19`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/models/attendance_log_model.dart#L19) — `final String? subjectName` is nullable.

---

#### 4. `users/{uid}/timetable_entries/{id}` — Blueprint layer
| Field | Present? |
|---|---|
| `subject` (raw name string, no ID) | ✅ Yes |
| `subjectId` | ❌ **NO — not stored here** |
| Primary reference | Subject name only (string match) |
| Rename causes stale data? | ✅ **YES — timetable_entries use the old name** |
| Delete leaves orphans? | ✅ **YES — entry still references deleted subject name** |

Code reference: [`timetable_entry_model.dart:4`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/models/timetable_entry_model.dart#L4) — `final String subject` — no ID field.

---

#### 5. `users/{uid}/daily_overrides/{dateKey}/sessions/{id}` — Override layer
| Field | Present? |
|---|---|
| `newSubjectName` | ✅ Yes (nullable) |
| `newSubjectId` | ✅ Yes (nullable) |
| Primary reference | `newSubjectId` |
| Rename causes stale data? | ✅ **YES — `newSubjectName` shows old name** |
| Delete leaves orphans? | ✅ **YES — override references deleted subjectId** |

---

#### 6. `users/{uid}/notification_preferences/alert_log` — Alert tracking
| Field | Present? |
|---|---|
| `subjectName` | ❌ No |
| `subjectId` | ✅ Yes (key in alert map) |
| Rename causes stale data? | ✅ No display issue but phantom alerts persist |
| Delete leaves orphans? | ✅ **YES — alert entries remain for deleted subjectId** |

---

**Summary table:**

| Location | subjectName stored? | subjectId stored? | Primary ref | Rename stale? | Delete orphans? |
|---|---|---|---|---|---|
| `subjects` | ✅ | ✅ (doc ID) | Both | ❌ Source | ❌ Source |
| `class_sessions` | ✅ | ✅ | subjectId | ✅ YES | ✅ YES |
| `attendance_logs` | ✅ (nullable) | ✅ | subjectId | ✅ YES | ✅ YES |
| `timetable_entries` | ✅ (as `subject`) | ❌ MISSING | Name only | ✅ YES | ✅ YES |
| `daily_overrides` | ✅ (nullable) | ✅ (nullable) | subjectId | ✅ YES | ✅ YES |
| `notification alerts` | ❌ | ✅ | subjectId | N/A | ✅ YES |

---

## SECTION 4 — FIRESTORE SCHEMA

### Collections & Schema

```
users/                                    ← users collection (root)
  {uid}/                                  ← user document
    ├── uid, displayName, email, photoURL
    ├── attendanceGoal (double)
    ├── themeMode (string)
    ├── isPremium (bool)
    ├── planType, premiumExpiresAt
    ├── lastPaymentId
    ├── createdAt, updatedAt
    │
    ├── subjects/                         ← MASTER subject data
    │   {subjectId}/
    │     ├── name (string)               ← SOURCE OF TRUTH for name
    │     ├── faculty (string?)
    │     ├── attendedClasses (int)       ← DENORMALIZED counter
    │     ├── totalClasses (int)          ← DENORMALIZED counter
    │     ├── targetAttendance (double)
    │     ├── createdAt, updatedAt
    │     └── (NO uid field stored per doc)
    │
    ├── timetable_entries/               ← Weekly template (blueprint)
    │   {entryId}/
    │     ├── subject (string — NAME ONLY, no subjectId!)
    │     ├── day (string: "Monday"…)
    │     ├── startTime, endTime
    │     ├── faculty, room
    │     └── confidence (double)
    │
    ├── class_sessions/                  ← Generated instances (one per day×entry)
    │   {sessionId}/
    │     ├── id, uid
    │     ├── subjectId (string)          ← FK to subjects
    │     ├── subjectName (string)        ← DENORMALIZED (stale on rename!)
    │     ├── date (Timestamp)
    │     ├── startTime, endTime
    │     ├── faculty, room
    │     ├── status (string: notMarked/present/absent/late/cancelled)
    │     ├── overrideSubjectId, overrideSubjectName
    │     ├── overrideStartTime, overrideEndTime
    │     ├── isCancelled, isExtraPeriod
    │
    ├── attendance_logs/                 ← Audit log of attendance decisions
    │   {logId}/
    │     ├── id
    │     ├── subjectId (string)          ← FK to subjects
    │     ├── subjectName (string?)       ← DENORMALIZED (nullable, stale on rename!)
    │     ├── status (string)
    │     ├── date (Timestamp)
    │     ├── startTime, endTime
    │     ├── sessionId (string?)         ← FK to class_sessions (nullable!)
    │     └── (no createdAt on main path — only in notification handler)
    │
    ├── timetable/                       ← LEGACY (different from timetable_entries!)
    │   {id}/
    │     ├── subjectId, subjectName
    │     ├── day, startTime, endTime
    │
    ├── semesters/
    │   {semesterId}/
    │     ├── id, uid
    │     ├── startDate, endDate (Timestamp)
    │     ├── holidays (List<Timestamp>)
    │     └── createdAt
    │
    ├── daily_overrides/
    │   {dateKey}/                        ← "YYYY-MM-DD"
    │     sessions/
    │       {overrideId}/
    │         ├── id, uid, date
    │         ├── sessionId (FK to class_sessions)
    │         ├── type (string: cancel/reschedule/addExtra)
    │         ├── newSubjectId, newSubjectName
    │         ├── newStartTime, newEndTime
    │
    └── notification_preferences/        ← (separate subcollection implied by repo)
```

### Per-collection classification:

| Collection | Source of Truth | Derived? | Cached? | Redundant? |
|---|---|---|---|---|
| `subjects` | ✅ YES | Counter fields derived from logs | ✅ Local SharedPrefs cache | Counter denormalization |
| `timetable_entries` | ✅ YES (schedule template) | No | No | `timetable/` legacy collection duplicates structure |
| `class_sessions` | Derived from timetable_entries + semesters | ✅ YES | No | `subjectName` redundant |
| `attendance_logs` | ✅ YES (audit trail) | No | No | `subjectName`, `startTime`, `endTime` redundant |
| `semesters` | ✅ YES | No | No | No |
| `daily_overrides` | ✅ YES | No | No | `newSubjectName` redundant |
| `timetable/` | ⚠️ LEGACY — overlaps with `timetable_entries` | — | — | **Duplicate of timetable_entries** |

> [!WARNING]
> There are **two timetable collections**: `timetable/` (old, used by `firestore_datasource.dart` watchTimetable/addTimetableEntry) and `timetable_entries/` (new, used by `timetable_repository.dart`). These are separate, unlinked collections for the same conceptual data.

---

## SECTION 5 — REALTIME UPDATES PER SCREEN

| Screen | Uses Stream? | Uses Future? | Manual Refresh? | Cache? | Rebuild Trigger |
|---|---|---|---|---|---|
| **Dashboard** | ✅ `subjectsStreamProvider` (Firestore snapshot) | ✅ `userProfileProvider` (one-shot) | ✅ Pull-to-refresh invalidates `subjectsStreamProvider` | ✅ SharedPrefs for `attendanceGoal` | Firestore snapshot push |
| **Schedule (Timetable)** | ✅ `todaySessionsStreamProvider` + `todayOverridesStreamProvider` | ❌ | ❌ | ❌ | Firestore snapshots + local `Timer.periodic(1 min)` |
| **Analytics** | ✅ `analyticsLogsStreamProvider` + `subjectsStreamProvider` via dashboard | ❌ | ❌ | ❌ | Firestore snapshot push |
| **Attendance History** | ✅ `attendanceLogsStreamProvider` | ❌ | ❌ | ❌ | Firestore snapshot push + filter state change |
| **Subject Detail** | ✅ `subjectsStreamProvider` + `subjectLogsStreamProvider` + `upcomingSessionsProvider` | ❌ | ❌ | ❌ | Firestore snapshot push (3 streams) |

---

## SECTION 6 — STREAM AUDIT

### Total active streams per screen:

| Screen | Stream Count | Providers |
|---|---|---|
| **Dashboard** | 2 | `subjectsStreamProvider`, `userProfileProvider` (Future, not stream) |
| **Schedule** | 3 | `todaySessionsStreamProvider`, `todayOverridesStreamProvider`, `clockTickProvider` (local timer) |
| **Analytics** | 3 | `analyticsLogsStreamProvider`, `dashboardNotifierProvider` (which watches `subjectsStreamProvider`) = effectively 2 Firestore streams |
| **Attendance History** | 2 | `attendanceLogsStreamProvider`, `subjectsStreamProvider` |
| **Subject Detail** | 3 | `subjectsStreamProvider`, `subjectLogsStreamProvider(id)`, `upcomingSessionsProvider(id)` |

### Global always-on streams (from `main.dart`):
- `notificationSchedulerWatcherProvider` watches: `todaySessionsStreamProvider` + `subjectsNotifierProvider` + `attendanceGoalProvider` = **3 additional streams running app-wide at all times**

---

### Nested StreamBuilders?
**No `StreamBuilder` widgets exist** — the app uses Riverpod's `ref.watch` on stream providers throughout. This is the correct pattern.

---

### Duplicate listeners for the same data?

**YES — critical duplication:**

```dart
// attendance_history_provider.dart:110
Stream<List<AttendanceLogModel>> attendanceLogsStream(Ref ref) {
  return ref.watch(attendanceRepositoryProvider).watchAllLogs();
}

// analytics_provider.dart:89
Stream<List<AttendanceLogModel>> analyticsLogsStream(Ref ref) =>
    ref.watch(attendanceRepositoryProvider).watchAllLogs();
```

Both call `watchAllLogs()` which hits `_logsRef(uid).orderBy('date', descending: true).limit(500).snapshots()`.  
**This opens two independent Firestore listeners on the same 500-document query.**

---

### Streams recreated unnecessarily during rebuilds?

**YES:**

1. **`SubjectsNotifier.build()`** ([`subjects_provider.dart:12`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/subjects/providers/subjects_provider.dart#L12)):
```dart
final stream = ref.watch(subjectRepositoryProvider).watchSubjects();
return ref.watch(
  StreamProvider((ref) => stream).select((v) => v),
);
```
This creates an **anonymous inline `StreamProvider`** inside `build()`. Every time `SubjectsNotifier` rebuilds, a new `StreamProvider` is instantiated. This is an anti-pattern.

2. **`clockTickProvider`** creates a `Stream.periodic` via `asBroadcastStream()` that could recreate if the provider is disposed and re-watched.

3. **`upcomingSessionsForSubject(subjectId)`** ([`timetable_repository.dart:354`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/repositories/timetable_repository.dart#L354)) opens a stream on `class_sessions WHERE subjectId == x` with **NO date filter** — this streams the entire subject's session history across the full semester to then filter client-side.

---

## SECTION 7 — PERFORMANCE AUDIT

### 1. Largest Firestore reads

| Query | Documents read | Frequency |
|---|---|---|
| `attendance_logs ORDER BY date DESC LIMIT 500` | Up to 500 docs | On every open of History, Analytics, Subject Detail |
| `class_sessions WHERE subjectId == x` (no date filter) | All sessions for subject (could be 100s) | Subject Detail open |
| `class_sessions WHERE date in [today]` | Today's sessions | Dashboard + Schedule + Notification scheduler |
| `subjects ORDER BY createdAt` | All subjects | Dashboard, Analytics, Notifications |

---

### 2. Screens with highest read count

**Subject Detail Screen** opens **3 simultaneous streams:**
- `subjectsStreamProvider` → subjects collection
- `subjectLogsStreamProvider(id)` → `attendance_logs WHERE subjectId == id` (no limit!)
- `upcomingSessionsProvider(id)` → `class_sessions WHERE subjectId == id` (no date limit!)

---

### 3. Expensive queries

**`upcomingSessionsForSubject`** ([`timetable_repository.dart:354`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/repositories/timetable_repository.dart#L354)):
```dart
return _sessionsCol
    .where('subjectId', isEqualTo: subjectId)
    .snapshots()   // NO date filter
    .map((snap) {
  final all = snap.docs.map(...)
  final upcoming = all
      .where((s) => !s.date.isBefore(startOfToday)) // client-side filter!
      .toList()
    ..sort(...)
  return upcoming.take(10).toList();
});
```
This reads **the full history of a subject's sessions** (could be 200+ docs for a semester) just to show 10 upcoming ones.

**`watchLogsForSubject`** ([`firestore_datasource.dart:138`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/datasources/firestore_datasource.dart#L138)):
```dart
return _logsRef(uid)
    .where('subjectId', isEqualTo: subjectId)
    .snapshots()   // NO limit!
    // sorts client-side
```
No pagination limit — reads every log for a subject ever.

---

### 4. Full collection scans

| Query | Why it's a scan |
|---|---|
| `attendance_logs WHERE subjectId == x` | No composite index (subjectId + date); comment in code confirms client-side sort |
| `class_sessions WHERE subjectId == x` (upcoming) | No `date` filter in Firestore query |
| `class_sessions WHERE subjectName == x AND startTime == x AND status == notMarked AND date >= now` | Four filter fields — requires composite index; done only on deletion |

---

### 5. N+1 query patterns

**`markMultipleSessionsAbsent`** ([`timetable_repository.dart:415`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/data/repositories/timetable_repository.dart#L415)):
```dart
for (final session in sessions) {
  await markSessionAttendance(session: session, status: status);
}
```
Each call to `markSessionAttendance` does:
1. A `getLogForSession` query (Firestore read)
2. A batch write (Firestore write)

For "Mark Full Day Absent" with 8 sessions: **8 reads + 8 batch writes = 16 Firestore operations sequentially.**

---

### 6. Screens rebuilding excessively

**`schedulePageData`** provider ([`timetable_provider.dart:66`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/timetable/providers/timetable_provider.dart#L66)) recomputes on:
- Every Firestore update to today's sessions
- Every Firestore update to today's overrides  
- **Every clock tick (every 1 minute via `_clockTimer`)** — BUT the clock timer uses `setState` in the screen, not `clockTickProvider`, so the entire `build()` of `TimetableScreen` runs every minute.

**`DashboardNotifier`** rebuilds whenever `subjectsStreamProvider` emits, which happens on **any** subject update (including `updatedAt` timestamp changes triggered by attendance marking).

---

### 7. Widgets rebuilding unnecessarily

- `DashboardScreen.build()` calls `ref.watch(currentUserProvider)` — user profile rebuild triggers dashboard rebuild
- `subjectDetailProvider` watches 3 streams; ANY change to subjects triggers full recompute including chart data

---

### 8. Synchronous work on UI thread

- `_buildTrendSpots()` in analytics — O(n) loop over all logs: acceptable for <500 logs
- `_applyFilter()` in history provider — O(n) filter over 500 logs: acceptable
- `_computeStreak()` — O(n × days) nested loop: acceptable for small datasets
- `_applyOverrides()` in timetable provider — O(n×m) merge: fine for small n,m

No heavy synchronous work detected that would cause jank at current scale.

---

## SECTION 8 — NOTIFICATION SYSTEM

### How notifications update after each action:

| Action | Auto re-scheduled? | Implementation |
|---|---|---|
| **Attendance Marked** | ✅ YES (automatic) | `notificationSchedulerWatcherProvider` watches `todaySessionsStreamProvider`. When a session's status changes, the stream emits → watcher fires → `rescheduleAll()` called |
| **Subject Renamed** | ⚠️ PARTIAL | Subject stream emits → scheduler runs with new subject data for low-attendance alerts. But **class reminders already scheduled with old name in payload** — the notification text will show the old name until tomorrow |
| **Subject Deleted** | ⚠️ PARTIAL | Subject stream emits → scheduler runs without deleted subject. Pending notifications for deleted subject are NOT cancelled (no explicit cancel by subjectId) |
| **Schedule Edited (timetable entry)** | ❌ NO | `timetableEntriesStreamProvider` is NOT watched by scheduler. Editing an entry doesn't regenerate class_sessions, so no stream emits. Notifications are NOT updated. |
| **Day Override Applied** | ❌ NO | `todayOverridesStreamProvider` is NOT watched by the scheduler. Only `todaySessionsStreamProvider` is watched. Overrides are applied in-memory by `schedulePageData` but the **notification scheduler never sees the override-merged schedule**. |

Code reference — what the scheduler watches ([`notification_scheduler_provider.dart:21`](file:///c:/Users/Abhishek/OneDrive/Desktop/Projects/Attu/lib/features/notifications/providers/notification_scheduler_provider.dart#L21)):
```dart
final sessionsAsync = ref.watch(todaySessionsStreamProvider);  // raw sessions only
// todayOverridesStreamProvider is NOT watched here!
```

---

## SECTION 9 — CACHE STRATEGY

### What caching currently exists:

| Data | Cache mechanism | Location | Invalidation |
|---|---|---|---|
| **Subjects list** | `SharedPreferences` JSON blob | `local_cache_datasource.dart` (key: `cached_subjects`) | Manual: `clearSubjectsCache()` — but this is **never called anywhere in the app** |
| **Attendance goal** | `SharedPreferences` double | `local_cache_datasource.dart` (key: `attendance_goal`) | Overwritten on `ProfileNotifier.updateGoal()` |
| **Theme mode** | `SharedPreferences` string | `local_cache_datasource.dart` (key: `theme_mode`) | Overwritten on `ProfileNotifier.updateTheme()` |
| **Firestore offline** | Firestore SDK default offline persistence | Firestore SDK | LRU, SDK-managed |
| **Provider state** | Riverpod in-memory (auto-dispose) | RAM | Disposed when screen leaves scope |

### Issues:

1. **`cacheSubjects()` is never called.** The method exists but no code calls it — the subjects cache is always empty.
2. **`getCachedSubjects()` is never called.** Cache reads are never used either.
3. **Firestore SDK offline cache** is enabled by default — this provides some offline resilience but has no custom invalidation strategy.
4. **Stale cache can explain outdated UI?** Yes — if Firestore offline cache returns stale documents before a sync, providers will briefly show old data. This resolves automatically when the stream catches up, but can cause flicker.

---

## SECTION 10 — SCALABILITY

### Assumed load: 1,000 → 5,000 → 10,000 concurrent users

| Concern | 1,000 users | 5,000 users | 10,000 users |
|---|---|---|---|
| **Firestore reads** | Manageable | Expensive | Very expensive |
| **Active listeners** | ~5–8 per active user = 5,000–8,000 concurrent listeners | 25,000–40,000 listeners | 50,000–80,000 listeners |
| **Duplicate log streams** | 2× reads on Analytics + History | 2× more waste | Cost doubles |
| **Session generation** | OK | Students with 5 subjects × 150 days = 750 sessions each; bulk write OK | Batch write latency increases |
| **`upcomingSessionsForSubject`** | ~100 docs per subject read for each Subject Detail open | Scales linearly | Expensive at scale |

### 1. Biggest bottleneck
The **duplicate `watchAllLogs()` streams** (History + Analytics) each reading 500 documents. With 10,000 users, that's potentially **10 million document reads per sync cycle**.

### 2. Most expensive query
`class_sessions WHERE subjectId == x .snapshots()` with NO date limit — reads the full semester history for every Subject Detail open.

### 3. Most likely source of lag
**Sequential N+1 in `markMultipleSessionsAbsent`** — 8 sessions = 16 serial Firestore operations. User sees a spinner for 2–5 seconds.

### 4. Firestore cost risks
- Two independent listeners on `attendance_logs` (up to 500 docs each) both firing on every attendance mark
- `class_sessions` growing to 750+ docs per user (5 subjects × 150 days) — full-collection reads on every Subject Detail open
- `timetable/` legacy collection being maintained in parallel with `timetable_entries/` = redundant writes

### 5. Architecture risks
- **No cascade delete** — subject deletion leaves orphaned sessions and logs
- **No cascade rename** — subject rename leaves stale names in 4 collections  
- **`timetable/` vs `timetable_entries/`** — two parallel schemas with different code paths
- **Notification scheduler doesn't observe daily overrides** — override-aware schedule exists only in-memory

---

## FINAL DELIVERABLE — TOP 10 ARCHITECTURE PROBLEMS

| # | Problem | Severity | Impact | Recommended Fix |
|---|---|---|---|---|
| **1** | **Duplicate `watchAllLogs()` streams** — `attendanceLogsStreamProvider` and `analyticsLogsStreamProvider` both open independent Firestore listeners on the same 500-doc query | 🔴 **Critical** | Performance, Scalability, Cost | Merge into a single `allLogsStreamProvider` that both screens share via `ref.watch` |
| **2** | **`upcomingSessionsForSubject` reads entire session history with no date filter** — full collection scan per subject per Subject Detail open | 🔴 **Critical** | Performance, Scalability | Add `where('date', isGreaterThanOrEqualTo: startOfToday)` to the Firestore query; remove client-side date filter |
| **3** | **Subject rename doesn't update denormalized `subjectName` in `class_sessions`, `attendance_logs`, `timetable_entries`, `daily_overrides`** — stale names persist everywhere | 🔴 **Critical** | Data inconsistency | On rename: run a batch update propagating the new name to all child collections; or switch to ID-only references and join names at query time |
| **4** | **Subject delete doesn't cascade** — orphaned sessions, logs, overrides, and notifications remain after deletion | 🔴 **Critical** | Data inconsistency | Implement a cascade delete (Firestore function or client batch): delete all `class_sessions`, `attendance_logs`, `daily_overrides` WHERE subjectId == deletedId |
| **5** | **`timetable_entries/` lacks `subjectId`** — only stores name string; subject linking is done by case-insensitive name match | 🔴 **Critical** | Data inconsistency | Add `subjectId` field to `TimetableEntry` model and persist it to Firestore; update `createSubjectsFromTimetable` |
| **6** | **Notification scheduler doesn't watch `todayOverridesStreamProvider`** — scheduled notifications don't reflect daily overrides (cancelled/rescheduled classes) | 🟠 **High** | User experience | Add `ref.watch(todayOverridesStreamProvider)` to `notificationSchedulerWatcherProvider`; pass merged schedule to `rescheduleAll()` |
| **7** | **`markMultipleSessionsAbsent` is N+1 sequential** — each session triggers a separate read + write; "Mark Full Day Absent" on 8 classes = 16 serial Firestore ops | 🟠 **High** | Performance, UX (spinner) | Batch the lookups: fetch all existing logs for today's sessions in one query, then batch all writes in one or two batches |
| **8** | **`SubjectsNotifier.build()` creates an anonymous inline `StreamProvider`** — anti-pattern that can recreate the stream on rebuild | 🟠 **High** | Performance, rebuild cascades | Replace with a top-level `@riverpod Stream<List<SubjectModel>> subjectsStream(Ref ref)` and watch it inside `SubjectsNotifier` |
| **9** | **`timetable/` legacy collection exists alongside `timetable_entries/`** — two different code paths manage timetable data; `FirestoreDatasource` still has `watchTimetable()`, `addTimetableEntry()`, `updateTimetableEntry()`, `deleteTimetableEntry()` methods referencing the old `timetable/` path while `TimetableRepository` uses `timetable_entries/` | 🟡 **Medium** | Data inconsistency, Maintenance | Audit which collection is actually used at runtime; migrate fully to `timetable_entries/`; delete `timetable/` methods and data |
| **10** | **`userProfileProvider` is a one-shot Future, not a Stream** — profile changes (goal, theme) require `ref.invalidate(userProfileProvider)` to propagate; no realtime sync | 🟡 **Medium** | Data inconsistency, UX | Replace with `Stream<UserModel?>` using `_userDoc(uid).snapshots()` so profile updates propagate immediately without manual invalidation |

---

> **Note:** This is a pure audit — no code has been changed. All file references are clickable.  
> Proceed with fixes only after this plan is approved.
