# AttendanceAI 🎓

> Smart attendance tracking for college students. Know exactly how many classes you can miss — before you miss them.

Built with Flutter + Firebase + Riverpod, AttendanceAI takes the mental overhead out of attendance management. It tracks your attendance per subject, predicts whether you can safely bunk, and tells you exactly how many classes you need to attend to hit your target — in real time.

---

## The Problem

Every college student has been there: you want to skip a class but you're not sure if you're safe. You do the mental math, second-guess yourself, and either go unnecessarily or skip and regret it later. Most students track attendance in their notes app or a spreadsheet, recalculate manually after every class, and never have a clear picture of where they actually stand.

AttendanceAI solves this completely.

---

## Features

### 🏠 Dashboard
- Overall attendance percentage with an animated circular ring
- Per-subject attendance at a glance
- **Safe bunks counter** — how many classes you can still skip and stay above your target
- **"Can I Bunk Tomorrow?" predictor** — instant yes/no based on your current standing
- Pull-to-refresh for live updates

### 📚 Subjects
- Add, edit, and delete subjects
- Real-time attendance percentage per subject
- Track attended vs. total classes with auto-updating counters
- Set per-subject attendance targets

### 📅 Timetable
- Weekly schedule management
- **Today's schedule view** with current class detection — knows which class is happening right now
- One-tap mark present / absent directly from the timetable
- Daily overrides — cancel, reschedule, or add extra classes for specific days
- Re-mark attendance (changing present → absent or vice versa updates counters atomically)

### 🔮 Predictor
- Simulate future scenarios: "What if I attend the next 3 and miss 2?"
- Instant attendance percentage recalculation on every input
- See exactly how many consecutive classes you need to attend to recover a low attendance

### 📊 Analytics
- Attendance trend charts over time (via `fl_chart`)
- Per-subject comparison bar charts
- Activity heatmap showing your attendance patterns
- Streak tracking

### 🔔 Smart Notifications
- Class reminders before each session based on your actual timetable
- Low attendance alerts when a subject drops below your target
- Reschedules automatically when attendance is marked or sessions change

### 💎 Premium
- ₹20/month or ₹200/year
- Integrated Razorpay payment flow

### 👤 Profile
- Light/dark theme toggle (persisted)
- Attendance goal slider (75%, 80%, 85% — updates calculations app-wide instantly)
- Account management

---

## Business Logic

All attendance calculations are mathematically precise and recalculate in real time:

| Formula | Description |
|---|---|
| `(attended / total) × 100` | Current attendance percentage |
| `floor((attended - target × total) / target)` | Safe bunks remaining |
| `ceil((target × total - attended) / (1 - target))` | Classes needed to reach target |
| `(attended / (total + 1)) × 100 >= target` | Can I bunk next class? |

Attendance marking uses **atomic batch writes** — when you mark a class, both the log entry and the subject counters update in a single Firestore transaction. No inconsistency, no race conditions.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Material 3) |
| Language | Dart |
| State Management | Riverpod 2 (code-gen with `@riverpod` annotations) |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, FCM) |
| Charts | fl_chart |
| Local Cache | SharedPreferences |
| Fonts | Google Fonts (Inter) |
| Payments | Razorpay |

---

## Architecture

AttendanceAI uses a clean, feature-based architecture with strict layer separation:

```
lib/
├── core/           # Colors, typography, spacing, theme, router, utils
├── data/           # Models, repositories, datasources (Firestore + cache)
├── domain/         # Business logic, pure calculations
├── features/       # Feature modules
│   ├── auth/
│   ├── dashboard/
│   ├── subjects/
│   ├── timetable/
│   ├── analytics/
│   ├── predictor/
│   ├── notifications/
│   └── premium/
└── shared/         # Reusable widgets
```

### State Management

Every shared piece of state is managed by **Riverpod with code generation** — no Bloc, GetX, or plain ChangeNotifier anywhere in the data layer. Providers use `@riverpod` annotations and companion `.g.dart` files.

Pattern breakdown:
- `StreamProvider` — Subjects, Sessions, Attendance Logs, Daily Overrides (all real-time Firestore streams)
- `AsyncNotifier` — Dashboard, Schedule, SubjectsNotifier, LogEditNotifier (stateful, async-aware)
- `setState()` — Used only for local UI state (loading spinners, form toggles) — never as a substitute for global state

### Attendance Marking Flow

```
UI (timetable_screen)
  └─ markAttendance(session, status)
       └─ timetableRepository.markSessionAttendance()
            ├─ getLogForSession() → check if first mark or re-mark
            │
            ├─ First mark → WriteBatch:
            │    • SET attendance_logs/{logId}
            │    • UPDATE subjects/{subjectId} (attended++, total++)
            │
            └─ Re-mark → WriteBatch:
                 • SET attendance_logs/{logId}
                 • UPDATE subjects/{subjectId} (delta correction)

Automatic state updates (via Riverpod stream invalidation):
  • subjectsStreamProvider → dashboard recalculates
  • todaySessionsStreamProvider → timetable updates
  • attendanceLogsStreamProvider → history + analytics update
  • notificationSchedulerWatcherProvider → notifications reschedule
```

### Firestore Schema

```
users/{uid}/
  ├── profile fields (name, email, goal, theme, isPremium)
  │
  ├── subjects/{subjectId}         ← Source of truth for subject data
  │   └── name, attendedClasses, totalClasses, targetAttendance
  │
  ├── timetable_entries/{id}       ← Weekly schedule blueprint
  │   └── subject, day, startTime, endTime, faculty, room
  │
  ├── class_sessions/{sessionId}   ← Generated daily instances
  │   └── subjectId, date, startTime, endTime, status
  │
  ├── attendance_logs/{logId}      ← Audit trail for every mark
  │   └── subjectId, status, date, sessionId
  │
  ├── daily_overrides/{dateKey}/   ← Per-day schedule changes
  │   sessions/{id}
  │   └── type (cancel/reschedule/addExtra), newSubjectId, newTimes
  │
  ├── semesters/{id}               ← Semester date ranges + holidays
  │
  └── notification_preferences/    ← Per-subject alert config
```

### Real-Time Updates

Every screen in the app is driven by Firestore streams — no manual refresh needed (except pull-to-refresh on dashboard):

| Screen | Live Streams |
|---|---|
| Dashboard | `subjectsStreamProvider` |
| Schedule | `todaySessionsStreamProvider` + `todayOverridesStreamProvider` + clock tick |
| Analytics | `analyticsLogsStreamProvider` + `subjectsStreamProvider` |
| History | `attendanceLogsStreamProvider` |
| Subject Detail | `subjectsStreamProvider` + `subjectLogsStreamProvider` + `upcomingSessionsProvider` |

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.3.0
- Dart SDK ≥ 3.3.0
- A Firebase project

### Setup

**1. Clone the repo**
```bash
git clone https://github.com/Abhishekog19/AttendanceClap.git
cd AttendanceClap
```

**2. Configure Firebase**
- Go to [Firebase Console](https://console.firebase.google.com/) and create a project
- Enable **Authentication** (Email/Password + Google)
- Enable **Cloud Firestore**
- Enable **Firebase Cloud Messaging**
- Download `google-services.json` → place in `android/app/`
- Update `lib/firebase_options.dart` with your project keys

**3. Set up Firestore security rules**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**4. Install dependencies**
```bash
flutter pub get
```

**5. Generate Riverpod code**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**6. Run**
```bash
flutter run
```

---

## Design System

AttendanceAI uses a clean Material 3 design language with a focus on readability and clarity:

| Token | Value |
|---|---|
| Primary | `#004AC6` (Precision Blue) |
| Surface | `#FAF8FF` (Warm White) |
| Error | `#BA1A1A` |
| Font | Inter (Regular 400 · Medium 500 · SemiBold 600 · Bold 700) |

Dark mode is fully supported and persisted to both Firestore and local cache.

---

## Screenshots

*Coming soon.*

---

## Author

**Abhishek** — [@Abhishekog19](https://github.com/Abhishekog19)
