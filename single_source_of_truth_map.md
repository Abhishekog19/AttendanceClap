# Single Source of Truth Map — AttendanceAI

**Last Updated:** June 17, 2026 (Architecture Stabilization Sprint)

This document defines the authoritative owner of each data entity in AttendanceAI.
When two sources disagree, this map tells you which one wins.

---

## Core Entities

### Subject Identity

| Field | Source of Truth | Notes |
|-------|----------------|-------|
| `subjectId` | `subjects/{subjectId}` | Immutable primary key. NEVER changes. Created by UUID at subject creation. |
| `subjectName` | `subjects/{subjectId}.name` | Mutable. Renames propagate via `SubjectCascadeService.propagateRename()`. |
| Displayed name everywhere | Always read from the subject document by ID | Never join on name. |

**Rule:** `subjectId` is the ONLY join key across collections. `subjectName` in dependent collections is a **read-optimized denormalization** — it must always be synchronized via the cascade service.

---

### Attendance Status

| Field | Source of Truth | Notes |
|-------|----------------|-------|
| Current session status | `class_sessions/{sessionId}.status` | Used by Schedule screen for real-time bucketing. |
| Historical attendance record | `attendance_logs/{logId}.status` | Source of truth for counters, analytics, and history. |
| Subject counters | `subjects/{subjectId}.attendedClasses` + `.totalClasses` | Derived from attendance_logs. Updated atomically via batch writes in `FirestoreDatasource`. |

**Rule:** `class_sessions.status` and `attendance_logs.status` MUST always be in sync.
- `markSessionAttendance()` in `TimetableRepository` updates both in one batch.
- `updateAttendanceLog()` in `FirestoreDatasource` updates both in one batch.
- `deleteAttendanceLog()` in `FirestoreDatasource` resets `class_sessions.status` to `notMarked`.

**Divergence = Bug.** If they differ, the attendance_logs entry is the ground truth.

---

### User Profile / Goal / Theme

| Field | Source of Truth | Notes |
|-------|----------------|-------|
| `attendanceGoal` | `users/{uid}.attendanceGoal` | Realtime via `userProfileProvider` stream. |
| `themeMode` | `users/{uid}.themeMode` | Realtime via `userProfileProvider` stream. |
| Premium status | `users/{uid}.isPremium` + `.planType` | Verified via Razorpay webhook. |

**Rule:** `userProfileProvider` is a **real-time Firestore stream**. All derived providers (`attendanceGoalProvider`, `themeModeProviderProvider`) react immediately. No `ref.invalidate()` needed.

---

### Today's Schedule

| Field | Source of Truth | Notes |
|-------|----------------|-------|
| Today's raw sessions | `todaySessionsStreamProvider` | Reads `class_sessions` where date = today. |
| Daily overrides | `todayOverridesStreamProvider` | Reads `daily_overrides/{today}/sessions`. |
| **Merged schedule** | **`schedulePageDataProvider`** | **The single merged + bucketed truth. All features that need "today's schedule" must watch this.** |

**Rule:** The Schedule screen, notification scheduler, and any feature rendering today's schedule must watch `schedulePageDataProvider`. This ensures overrides are always applied.

---

### Timetable (Master Blueprint)

| Collection | Status | Notes |
|-----------|--------|-------|
| `timetable_entries/` | **ACTIVE** | The current timetable store. Managed by `TimetableRepository`. Each entry has `subjectId` (post-sprint). |
| `timetable/` (legacy) | **DEPRECATED** | Old collection. Not written to by any active code. `FirestoreDatasource` methods for this collection are annotated `@Deprecated`. |

**Rule:** Only `timetable_entries/` is authoritative. Do not read from or write to `timetable/`.

---

### Attendance Logs

| Field | Source of Truth | Notes |
|-------|----------------|-------|
| Active logs | `attendance_logs` where `isArchived != true` | Used by History, Analytics, Subject Detail. |
| Archived logs | `attendance_logs` where `isArchived == true` | Created when a subject is deleted. Not visible in UI. Preserved for audit. |

**Rule:** Soft archive (`isArchived: true`) is used instead of hard deletion when a subject is removed. This preserves historical integrity. All Firestore stream queries filter `isArchived != true`.

---

## Provider Hierarchy (Riverpod)

```
Firestore
  |
  +-- userProfileProvider (Stream) --> attendanceGoalProvider
  |                                --> themeModeProviderProvider
  |                                --> ProfileNotifier
  |
  +-- subjectsStreamProvider (Stream) --> SubjectsNotifier
  |                                   --> dashboardNotifierProvider
  |
  +-- todaySessionsStreamProvider (Stream) -+
  |                                         +--> schedulePageDataProvider --> notificationSchedulerWatcherProvider
  +-- todayOverridesStreamProvider (Stream) -+
  |
  +-- attendanceLogsStreamProvider (Stream) --> filteredLogsProvider
  |   [SINGLE - analytics and history share]    --> analyticsInsightsProvider
  |                                             --> analyticsSummaryProvider
  |                                             --> trendDataProvider
  |                                             --> heatmapDataProvider
  |
  +-- subjectLogsStreamProvider(subjectId) --> subjectDetailProvider(subjectId)
      [Per-subject - separate listener, intentional]
```

**Rules:**
1. `attendanceLogsStreamProvider` is the **single** all-logs stream. Analytics must NOT create a second listener.
2. `schedulePageDataProvider` is the **single** override-aware schedule. Notification scheduler must watch this, not raw sessions.
3. `SubjectsNotifier.build()` must watch `subjectsStreamProvider` (top-level) — never create an inline StreamProvider inside `build()`.

---

## Cascade Rules

### Subject Rename
```
SubjectRepository.updateSubject()
  -> FirestoreDatasource.updateSubject()      [updates subjects/{id}.name]
  -> SubjectCascadeService.propagateRename()  [updates 4 collections]
      -> class_sessions.subjectName           [batch update by subjectId]
      -> attendance_logs.subjectName          [batch update by subjectId]
      -> timetable_entries.subject            [batch update by subjectId]
      -> daily_overrides.newSubjectName       [collection group query]
```

### Subject Delete
```
SubjectRepository.deleteSubject()
  -> SubjectCascadeService.cascadeDelete()    [runs BEFORE deleting subject doc]
      -> class_sessions                       [hard delete by subjectId]
      -> attendance_logs                      [soft archive: isArchived=true]
      -> timetable_entries                    [hard delete by subjectId]
      -> daily_overrides                      [hard delete, collection group]
      -> notification_alert_state/{subjectId} [hard delete]
  -> FirestoreDatasource.deleteSubject()      [deletes subjects/{id}]
```

---

## Firestore Composite Indexes (Required Post-Sprint)

| Collection | Fields | Purpose |
|-----------|--------|---------|
| `class_sessions` | `subjectId ASC, date ASC` | `upcomingSessionsForSubject()` date filter |
| `sessions` (collection group) | `uid ASC, newSubjectId ASC` | Daily override cascade operations |

> **Note:** `attendance_logs` isArchived filtering is done client-side (not Firestore-side),
> so no composite indexes are needed for log queries.
> The isArchived field is only present on archived logs — absent on all normal logs.

---

## What Is Not Changed (Protected)

- **Predictor module** (`lib/features/predictor/`) — zero modifications.
- Predictor reads: `dashboardNotifierProvider` + `attendanceGoalProvider` only.
- Both provider APIs are unchanged. Predictor is not impacted by this sprint.
