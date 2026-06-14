# AttendanceAI 🎓

A production-ready Flutter application for smart student attendance tracking with AI-powered predictions.

## ✨ Features

- **Dashboard** — Overall attendance % with animated circular ring, safe bunks counter, "Can I Bunk Tomorrow?" predictor
- **Subjects** — CRUD for subjects with real-time attendance % tracking
- **Timetable** — Today's schedule with current class detection, mark present/absent buttons
- **Predictor** — Simulate future attended/missed classes with instant % recalculation
- **Analytics** — Attendance trends chart, subject comparison bars, activity heatmap
- **Premium** — ₹20/month or ₹200/year pricing UI
- **Profile** — Theme toggle, attendance goal slider, logout

## 🏗️ Architecture

```
lib/
├── core/           # Colors, typography, spacing, theme, router, utils
├── data/           # Models, repositories, datasources (Firestore + cache)
├── domain/         # Business logic
├── features/       # Feature-based modules (auth, dashboard, subjects, etc.)
└── shared/         # Reusable widgets
```

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter + Material 3 |
| State | Riverpod 2 |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, FCM) |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter) |
| Local Cache | SharedPreferences |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (≥ 3.3.0)
- Dart SDK (≥ 3.3.0)
- Firebase project

### Setup

1. **Clone the repo**
   ```bash
   cd "c:\Users\Abhishek\OneDrive\Desktop\Projects\Attu"
   ```

2. **Configure Firebase**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create project `attendance-ai-app`
   - Enable **Authentication** (Email/Password + Google)
   - Enable **Cloud Firestore**
   - Enable **Firebase Messaging**
   - Download `google-services.json` → `android/app/`
   - Download `GoogleService-Info.plist` → `ios/Runner/`
   - Update `lib/firebase_options.dart` with your actual keys

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Generate Riverpod code**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🎨 Design System

Based on the Stitch AttendanceAI design (Project ID: `12650928810199388745`).

**Colors:**
- Primary: `#004AC6` (Precision Blue)
- Surface: `#FAF8FF` (Warm White)
- Error: `#BA1A1A`

**Font:** Inter (Regular 400, Medium 500, SemiBold 600, Bold 700)

## 📐 Business Logic

| Formula | Code |
|---|---|
| Attendance % | `(attended / total) * 100` |
| Safe Bunks | `floor((attended / targetPercent) - total)` |
| Classes Needed | `ceil((target*total - attended) / (1 - target))` |
| Can I Bunk? | `(attended / (total + 1)) * 100 >= target` |

## 🔐 Firebase Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 📁 Firestore Structure

```
users/{userId}/
  ├── profile: { name, email, photoUrl, attendanceGoal, themeMode }
  ├── subjects/{id}: { name, attendedClasses, totalClasses, faculty }
  ├── timetable/{id}: { subjectId, day, startTime, endTime, faculty, room }
  └── attendance_logs/{id}: { subjectId, status, date }
```

## 🗒️ TODO

- [ ] Add Firebase `google-services.json` and `GoogleService-Info.plist`
- [ ] Run `dart run build_runner build` to generate `.g.dart` files
- [ ] Configure Firestore Security Rules
- [ ] Set up FCM for push notifications
- [ ] Add app icon (replace default)
- [ ] Configure signing for release builds

---

Built with ❤️ using Flutter + Firebase + Riverpod
