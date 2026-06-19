# AttendanceAI – Complete UI/UX & Feature Inventory Audit

> **Scope:** Every user-facing element, screen, interaction, workflow, state, and feature present in the application as of June 2026.  
> **Purpose:** Allow a designer / developer to fully understand and redesign the product without opening the app.  
> **No redesign suggestions are included — this is documentation only.**

---

## Table of Contents

1. [Navigation Architecture](#1-navigation-architecture)
2. [Design System](#2-design-system)
3. [Screen Inventory](#3-screen-inventory)
4. [Modals, Sheets & Dialogs](#4-modals-sheets--dialogs)
5. [Global / Shared Components](#5-global--shared-components)
6. [Data States Per Screen](#6-data-states-per-screen)
7. [Notification Types](#7-notification-types)
8. [Feature Status Matrix](#8-feature-status-matrix)
9. [Interaction & Animation Inventory](#9-interaction--animation-inventory)

---

## 1. Navigation Architecture

### 1.1 Bottom Navigation Bar (MainShell)

The persistent navigation shell is present on all main (top-level) screens. It sits at the bottom of the screen with a top-border divider.

| Tab Index | Label     | Inactive Icon             | Active Icon          | Route Path   |
|-----------|-----------|---------------------------|----------------------|--------------|
| 0         | Home      | `home_outlined`           | `home`               | `/dashboard` |
| 1         | Schedule  | `calendar_today_outlined` | `calendar_today`     | `/timetable` |
| 2         | Predictor | `query_stats_outlined`    | `query_stats`        | `/predictor` |
| 3         | Profile   | `person_outline`          | `person`             | `/profile`   |

> **Analytics tab is commented out** — it existed as tab 3 (leaderboard icon) pointing to `/analytics` but is currently disabled in the nav bar. The screen is still accessible via direct push.

**Behavior:**
- Active tab icon animates via `AnimatedSwitcher` (200 ms fade swap).
- Active tab label uses `FontWeight.w600`; inactive uses `w400`.
- Active tab uses `primary` color; inactive uses `onSurfaceVariant`.
- Background is semi-transparent (`alpha 230`) with a top border.
- Height: `AppSpacing.bottomNavHeight` constant.
- Uses `context.go(path)` for navigation (GoRouter shell route).

### 1.2 Full Route Map

| Route                        | Screen / Widget                   | Protected? | Notes                                        |
|------------------------------|-----------------------------------|------------|----------------------------------------------|
| `/`                          | Redirect to `/dashboard` or `/auth/login` | Auth guard | GoRouter redirect logic                |
| `/auth/login`                | LoginScreen                       | No         |                                              |
| `/auth/signup`               | SignupScreen                      | No         |                                              |
| `/auth/forgot-password`      | ForgotPasswordScreen              | No         |                                              |
| `/dashboard`                 | DashboardScreen                   | Yes        | Shell tab 0                                  |
| `/timetable`                 | TimetableScreen                   | Yes        | Shell tab 1                                  |
| `/timetable/manage`          | ManageTimetableScreen             | Yes        |                                              |
| `/timetable/builder`         | TimetableBuilderScreen            | Yes        |                                              |
| `/timetable/manual-entry`    | ManualTimetableEntryScreen        | Yes        | Accepts optional `extra: TimetableEntry`      |
| `/timetable/upload`          | OCR import — disabled/commented   | —          | Route exists but not active                  |
| `/predictor`                 | PredictorScreen                   | Yes        | Shell tab 2                                  |
| `/profile`                   | ProfileScreen                     | Yes        | Shell tab 3                                  |
| `/premium`                   | PremiumScreen                     | Yes        |                                              |
| `/subjects`                  | SubjectsScreen                    | Yes        |                                              |
| `/subjects/add`              | AddEditSubjectScreen              | Yes        | `subject` param = null                       |
| `/subjects/edit`             | AddEditSubjectScreen              | Yes        | `extra: SubjectModel`                        |
| `/subjects/detail`           | SubjectDetailScreen               | Yes        | `extra: SubjectModel`                        |
| `/attendance/history`        | AttendanceHistoryScreen           | Yes        |                                              |
| `/analytics`                 | AnalyticsScreen                   | Yes        | Not in bottom nav                            |
| `/notifications/center`      | NotificationCenterScreen          | Yes        |                                              |
| `/notifications/settings`    | NotificationSettingsScreen        | Yes        |                                              |

---

## 2. Design System

### 2.1 Color Tokens

The app uses a dual-mode color system (`AppColors`). All semantic tokens exist for both light and dark modes.

#### Light Mode Tokens
| Token                     | Usage                              |
|---------------------------|------------------------------------|
| `primary` (blue)          | Active states, CTAs, links         |
| `primaryContainer`        | Highlighted cards, plan cards      |
| `primaryFixed`            | Subtle primary backgrounds         |
| `onSurface`               | Primary text                       |
| `onSurfaceVariant`        | Secondary text / muted labels      |
| `background`              | Page background                    |
| `surface`                 | Nav bar background                 |
| `surfaceContainerLowest`  | Cards                              |
| `surfaceContainerLow`     | Hover / subtle fills               |
| `surfaceContainer`        | Section backgrounds                |
| `surfaceContainerHigh`    | Skeleton / shimmer base            |
| `surfaceContainerHighest` | Filter chip backgrounds            |
| `outlineVariant`          | Card borders, dividers             |
| `outline`                 | Muted icons                        |
| `success`                 | Present status, positive states    |
| `successContainer`        | Success backgrounds                |
| `error`                   | Absent status, delete actions      |
| `errorContainer`          | Error backgrounds                  |
| `warning`                 | Late / risky / action-required     |
| `warningContainer`        | Warning backgrounds                |
| `onWarningContainer`      | Text on warning backgrounds        |
| `tertiary`                | Premium / upgrade accents          |

#### Dark Mode Prefix: `dark*`
Each light mode token has a corresponding dark mode variant prefixed with `dark` (e.g. `darkPrimary`, `darkSurface`, `darkOnSurface`, etc.).

### 2.2 Typography (`AppTextStyles`)

| Style              | Usage                                              |
|--------------------|----------------------------------------------------|
| `displayLg`        | Large numbers (Analytics %, Premium price)         |
| `headlineLgMobile` | Page hero headings (Login "AttendanceAI")          |
| `headlineLg`       | Section titles (Dashboard "Today", Analytics)      |
| `headlineMd`       | AppBar titles, card headings, dialog titles        |
| `bodyLg`           | Body text, list tile titles, button labels         |
| `bodyMd`           | Medium body text                                   |
| `bodySm`           | Subtitles, secondary text, captions                |
| `labelMd`          | Small interactive labels, filter chip text         |
| `labelCaps`        | SECTION HEADERS (uppercased), tab labels           |

### 2.3 Spacing (`AppSpacing`)

| Token            | Value / Usage                    |
|------------------|----------------------------------|
| `xs`             | 4px — tight gaps                 |
| `sm`             | 8px — between related elements   |
| `md`             | 16px — standard padding          |
| `lg`             | 24px — section spacing           |
| `xl`             | 32px — large section gaps        |
| `xxl`            | 48px — hero padding              |
| `radiusSm`       | Small corner radius              |
| `radiusMd`       | Standard card radius             |
| `radiusLg`       | Large card / sheet radius        |
| `radiusFull`     | Pill / chip radius               |
| `bottomNavHeight`| Custom nav bar height constant   |

### 2.4 Theme Behavior

- **Theme selection:** User-controlled via Profile → Appearance (System / Light / Dark).
- **Theme persistence:** Stored in Firestore user profile.
- **Applied:** MaterialApp wraps `AppTheme.lightTheme` / `AppTheme.darkTheme`.
- **Component theming:** Inputs, buttons, chips, sliders, switch tiles all inherit from `AppTheme`.

---

## 3. Screen Inventory

---

### 3.1 Auth – Login Screen (`/auth/login`)

**Purpose:** Entry point for authentication; pre-authentication redirect target.

**Layout:** Scrollable `SafeArea` centered column with entrance animation.

**Entrance Animation:**
- `FadeTransition` + `SlideTransition` (slide up 8% of height), 800 ms, `Curves.easeOut`.

**Elements:**

| Element                 | Type                  | Behavior / Detail                                    |
|-------------------------|-----------------------|------------------------------------------------------|
| App Logo                | Container + Icon      | 64x64, `school_rounded` icon on primary bg, rounded  |
| "AttendanceAI" heading  | Text                  | `headlineLgMobile`, primary color, letter-spacing -0.5 |
| Tagline                 | Text                  | "Track smarter, attend better", `bodyLg`, `onSurfaceVariant` |
| Email field             | TextFormField         | `email_outlined` prefix, email keyboard, validates "@" |
| Password field          | TextFormField         | `lock_outline` prefix, obscure text toggle (eye icon) |
| "Forgot password?" link | TextButton            | Right-aligned, pushes `/auth/forgot-password`        |
| Sign In button          | FilledButton (52h)    | Full-width, primary color, loading spinner when busy  |
| "or continue with" row  | Divider + Text        | Decorative divider with centered label               |
| Sign in with Google btn | OutlinedButton.icon   | Full-width, `g_mobiledata` icon, 52h                 |
| "Don't have an account?" | Row + TextButton     | Inline text + "Sign Up" link → `/auth/signup`        |

**States:**
- **Loading:** Sign In & Google buttons disabled; spinner replaces button label.
- **Error:** `SnackBar` with `AppColors.error` background, message from `AuthErrorMapper`.
- **Validation errors:** Inline field error messages (Required / invalid email / min 6 chars).

---

### 3.2 Auth – Sign Up Screen (`/auth/signup`)

**Purpose:** New account registration via email/password.

**Layout:** Scrollable column with AppBar back button.

**Elements:**

| Element                  | Type              | Detail                                                  |
|--------------------------|-------------------|---------------------------------------------------------|
| Back button (AppBar)     | IconButton        | `arrow_back_ios_new`, pops route                        |
| "Create Account" heading | Text              | `headlineLgMobile`, primary color                       |
| Tagline                  | Text              | "Join thousands of students…", `bodyLg`, `onSurfaceVariant` |
| Full Name field          | TextFormField     | `person_outline` prefix, word capitalization            |
| Email field              | TextFormField     | `email_outlined` prefix, validates "@"                  |
| Password field           | TextFormField     | `lock_outline`, obscure toggle                          |
| Confirm Password field   | TextFormField     | Validates match with password field                     |
| Create Account button    | FilledButton (52h)| Full-width, loading spinner when busy                   |
| "Already have an account?" | Row + TextButton| "Sign In" link → pops back to Login                    |

**Password Validation Rules (inline):**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number

**States:** Loading (button spinner), Error (SnackBar), Validation (per-field messages).

---

### 3.3 Auth – Forgot Password Screen (`/auth/forgot-password`)

**Purpose:** Password reset via email.

**Elements:**
- AppBar with back button.
- Email `TextFormField`.
- "Send Reset Email" `FilledButton`.
- Loading / error states via SnackBar.

---

### 3.4 Dashboard (Home) Screen (`/dashboard`)

**Purpose:** Primary landing screen after authentication. Shows attendance overview and subject cards.

**Layout:** `CustomScrollView` with `SliverAppBar` + `SliverPadding`/`SliverList`. Pull-to-refresh invalidates `subjectsStreamProvider`.

#### AppBar (SliverAppBar — floating + snap)
| Element               | Detail                                                          |
|-----------------------|-----------------------------------------------------------------|
| Avatar / User chip    | CircleAvatar (r=18) showing photo or initial; shows "Welcome back, [FirstName]" |
| "Welcome back," label | `labelMd`, `onSurfaceVariant`                                   |
| First name            | `bodyLg`, primary, `FontWeight.w600`                            |
| Notification bell     | IconButton, `notifications_outlined`, primary; badge overlay    |

**Notification Badge (on bell):**
- Shown when `unreadCount > 0`.
- Counts 1–9: circular red badge.
- Counts 10+: rounded rectangle badge.
- Counts 99+: shows "99+".
- 200 ms animated container size change.
- Tapping navigates to `/notifications/center`.

#### HeroAttendanceCard Widget
| Element                    | Detail                                                   |
|----------------------------|----------------------------------------------------------|
| Overall % display          | Large percentage figure (center)                         |
| Circular progress ring     | `AttendanceProgressRing` custom widget; color by status  |
| "Safe Bunks" indicator     | Count of safe bunks across all subjects                  |
| "Classes Needed" indicator | How many classes to attend to reach target               |
| Target %                   | User's attendance goal from profile                      |

#### "Can I Bunk Tomorrow?" Button
- Full-width container (height 56), rounded, dynamic background color:
  - **Safe** → `primaryContainer` bg, white text.
  - **Risky** → `warningContainer` bg, `onWarningContainer` text.
  - **Must Attend** → `errorContainer` bg, `onErrorContainer` text.
- Icon: `event_busy_rounded`.
- Tapping opens `_BunkResultSheet` modal.
- Box shadow: primary color tinted, 12 blur.

**Bunk Result Modal (Bottom Sheet):**
| State       | Icon                    | Title           | Subtitle                                              |
|-------------|-------------------------|-----------------|-------------------------------------------------------|
| Safe        | `check_circle_rounded`  | "Safe to Bunk!" | "You have enough buffer. Enjoy your day off."         |
| Risky       | `warning_rounded`       | "Risky Bunk"    | "You're close to the limit. Think twice before skipping." |
| Must Attend | `cancel_rounded`        | "Must Attend!"  | "Missing this class will drop you below your target." |

Modal has a "Got it" `FilledButton` to dismiss.

#### Subject Overview Section
| Element            | Detail                                                       |
|--------------------|--------------------------------------------------------------|
| "Subject Overview" | `headlineMd`, `onSurface`                                    |
| "History" link     | TextButton → `/attendance/history`                          |
| "View All" link    | TextButton → `/subjects`                                    |
| Subject cards      | Max 5 subjects shown; uses `SubjectCard` shared widget      |
| Empty state        | `EmptyStateWidget` with "Add Subject" CTA → `/subjects/add` |

**SubjectCard widget:** Subject name, faculty (optional), attendance % badge, `SubjectProgressBar` (color-coded), tappable → `/subjects/detail`.

**Data States:**
- **Loading:** Full-screen `DashboardSkeleton` (shimmer placeholders).
- **Error:** Inline error text.
- **Empty subjects:** `EmptyStateWidget` inline in the list.

---

### 3.5 Schedule (Timetable) Screen (`/timetable`)

**Purpose:** Shows today's class schedule with real-time time-bucket grouping. Auto-refreshes every minute via `Timer.periodic`.

**Layout:** Scaffold with AppBar + body `ListView`.

#### AppBar
| Element           | Detail                                               |
|-------------------|------------------------------------------------------|
| Title "Schedule"  | `headlineMd`, primary color                          |
| Grid icon button  | `grid_view_rounded` → pushes `/timetable/manage`     |
| OCR import button | Disabled (commented out in code)                     |

#### Today Header (`_TodayHeader`)
- "Today" large heading (`headlineLg`).
- Date + "X classes remaining" (`bodyLg`, `onSurfaceVariant`).

#### Action Buttons Row
Two side-by-side Material + InkWell buttons with icon + label, border, rounded:

| Button       | Icon                     | Color   | Action                                        |
|--------------|--------------------------|---------|-----------------------------------------------|
| Edit Today   | `edit_calendar_outlined` | Primary | Opens `EditTodayScheduleSheet` bottom sheet   |
| Mark Absent  | `event_busy_outlined`    | Warning | Opens "Mark Classes Absent" bottom sheet      |

#### Section Headers (`_SectionHeader`)
- Shows colored dot + UPPERCASE label.
- Current Class: animated pulsing dot (900 ms fade, primary color).
- Action Required: static warning-colored dot.
- Other sections: no dot, `onSurfaceVariant` text.

#### Current Class Card (`_CurrentClassCard`)
Shown when a class is actively in progress:
- Subject name (primary color, `headlineMd`).
- Time range + optional room (location icon).
- "In Progress" pill badge with animated pulsing dot.
- Linear progress bar (% through class).
- Start / "X% through" / end time row.
- Note: "Attendance can be marked after class ends".
- Border: primary color tinted; box shadow.

#### Action Required Cards (`_ActionRequiredCard`)
For classes that ended but attendance not marked:
- Subject name, time range, optional room.
- Present / Absent / Late buttons row (3 buttons).
- Loading state while saving.
- Card border: warning-colored.

#### Upcoming Class Cards (`_UpcomingClassCard`)
- Subject name, time range, room, faculty.
- "Upcoming" badge pill.
- Minimal card styling.

#### Completed Today Tiles (`_CompletedClassTile`)
- Compact inline row.
- Subject name + time.
- Status badge (Present / Absent / Late / Cancelled).
- Color-coded by status.

#### Empty State (`_EmptySchedule`)
- Icon + "No classes today" text.
- "Manage Timetable" and "Set Up Timetable" CTAs.

#### Mark Classes Absent Modal (Bottom Sheet)
Two choice cards:

| Card                  | Icon                     | Color   | Description                                   |
|-----------------------|--------------------------|---------|-----------------------------------------------|
| Mark Remaining Absent | `arrow_forward_rounded`  | Warning | Marks upcoming + unmarked classes as absent   |
| Mark Full Day Absent  | `calendar_today_rounded` | Error   | Marks ALL unmarked classes today as absent    |

- Each card shows count of affected classes.
- "Cancel" `OutlinedButton` to dismiss.
- If no unmarked classes: "No unmarked classes remaining today."

**Data States:**
- **Loading:** `CircularProgressIndicator` full-screen.
- **Error:** Inline error text.
- **Empty today:** `_EmptySchedule` with CTAs.

---

### 3.6 Predictor Screen (`/predictor`)

**Purpose:** AI-powered attendance predictions and simulations.

**Layout:** `CustomScrollView` with pinned `SliverAppBar` + `SliverPadding`/`SliverList`.

#### App Bar
- Icon: 32x32 rounded box with primary gradient, `insights_rounded` icon.
- Title: "Predictor" bold + subtitle "N subjects · X% goal".

#### Collapsible Sections (`_CollapsibleSection`)
Each section: tappable header with icon box + title + subtitle + expand/collapse chevron. Animated height via `SizeTransition` (200 ms). All start **expanded**.

| # | Section Title        | Icon                    | Content Widget           |
|---|----------------------|-------------------------|--------------------------|
| 1 | (Always visible)     | —                       | OverallSummaryCard (hero) |
| 2 | Filter subjects      | `filter_list_rounded`   | `_SubjectFilterBar`      |
| 3 | Danger Radar         | `radar_outlined`        | `RiskRadarSection`       |
| 4 | Subject Predictions  | `auto_graph_rounded`    | `SubjectPredictionCard` per subject |
| 5 | Leave Planner        | `beach_access_rounded`  | `LeavePlannerCard`       |
| 6 | Semester Forecast    | `flag_rounded`          | `SemesterForecastCard`   |

#### Subject Filter Bar (`_SubjectFilterBar`)
- Header: "Filter subjects" label + `filter_list_rounded` icon.
- "Clear" text button (only shown when filters active).
- Wrap of animated chips: "All" chip + one per subject (truncated to 14 chars).
- Chip behavior: toggle per subject; multiple selection allowed.
- Animated selection state (150 ms AnimatedContainer).

**Data States:**
- **Loading:** Custom `_LoadingBody` — pulsing icon (0.4→1.0, 900 ms) + "Crunching your data…" + "Building predictions from your timetable".
- **Empty:** `_EmptyBody` — icon + "No data yet" + instruction.
- **Error:** `_ErrorBody` — error icon + "Something went wrong" + error message.

---

### 3.7 Profile Screen (`/profile`)

**Purpose:** User identity, attendance goal setting, theme, settings, sign out.

**Layout:** Scrollable `ListView` with AppBar.

#### AppBar
- Title: "Profile", `headlineMd`, primary.
- Action: "Go Premium" IconButton (`workspace_premium_outlined`) — only shown for free users. → `/premium`.

#### Avatar / Name / Email Section
- `CircleAvatar` (radius 40): network photo or initial letter.
- Display name (`headlineMd`).
- Email (`bodyLg`, `onSurfaceVariant`).

#### Attendance Goal Section
- Section label: "ATTENDANCE GOAL" (caps).
- Card:
  - Row: "Target Attendance" label + current `%` value (primary, `headlineMd`).
  - Slider: min 50%, max 100%, 10 divisions (5% steps). Saves on drag end.

#### Appearance Section
- Section label: "APPEARANCE" (caps).
- Card with 3 animated radio-style rows:

| Option          | Icon                       |
|-----------------|----------------------------|
| System Default  | `brightness_auto_outlined` |
| Light Mode      | `light_mode_outlined`      |
| Dark Mode       | `dark_mode_outlined`       |

Each has 200 ms animated circular check indicator.

#### More Section
- Section label: "MORE" (caps).
- Card with 4 tiles:

| Tile                  | Icon                  | Action                                       |
|-----------------------|-----------------------|----------------------------------------------|
| Premium tile          | Dynamic (3 states)    | → `/premium`                                 |
| Notification Settings | `notifications_outlined` | → `/notifications/settings`               |
| Help & Support        | `help_outline`        | No-op (not implemented)                      |
| About AttendanceAI    | `info_outline`        | No-op; shows "Version 1.0.0" subtitle        |

**Premium Tile — 3 States:**

| State              | Icon                        | Title                  | Subtitle                        | Trailing                        |
|--------------------|-----------------------------|------------------------|---------------------------------|---------------------------------|
| Free user          | `workspace_premium_outlined`| "Upgrade to Premium"   | "Unlock AI predictions & more"  | `arrow_forward_ios`             |
| Monthly subscriber | `workspace_premium_rounded` | "Upgrade to Annual"    | "Save ₹40/year vs monthly…"    | "UPGRADE" chip in tertiary      |
| Annual subscriber  | `verified_rounded`          | "Premium Active"       | "Annual Plan — Best value"     | "ACTIVE" chip in success color  |

#### Sign Out Button
- `OutlinedButton.icon`, full-width (52h), error color, border error at 40% alpha.
- Icon: `logout`. Triggers confirmation AlertDialog.

**Sign Out Dialog:**
- Title: "Sign Out?"
- Content: "Are you sure you want to sign out?"
- Actions: Cancel TextButton + Sign Out FilledButton (error background).

---

### 3.8 Notifications – Center Screen (`/notifications/center`)

**Purpose:** Inbox of all app-generated notifications, grouped by time, with pagination.

**Layout:** Scaffold with AppBar + conditional body.

#### AppBar
- Title: "Notifications", `headlineMd`, primary color.
- Action: "Mark all read (N)" TextButton — only shown when `unreadCount > 0`. Shows "99+" for ≥ 100.

#### Notification List (`_NotificationList`)
Groups: **Today / This Week / This Month / Older**. Empty groups hidden.

**Notification Tile (`_NotificationTile`):**
- Swipe-to-delete: `Dismissible`, end-to-start, red background.
- Tap: marks as read if unread.
- Unread: primary tinted bg + primary border + dot indicator.
- Read: surface container bg, no border, no dot.
- Left: 40x40 circle icon (type-colored).
- Center: Title (bold if unread) + Message (3 lines max) + Timestamp.
- Right: 8x8 primary dot for unread.
- 200 ms animated container.

**Timestamp Formats:** Just now / Nm ago / Nh ago / Yesterday / N days ago / MMM d.

**Pagination:** Initial 20. "Load more" OutlinedButton when more pages exist. Loading spinner during fetch.

**Data States:**
- **Loading:** `_NotificationLoadingSkeleton` — 6 shimmer tiles, 900 ms fade.
- **Empty:** `_EmptyNotificationsState` — icon + "No notifications yet".

---

### 3.9 Notifications – Settings Screen (`/notifications/settings`)

**Purpose:** Granular notification preferences; persisted to Firestore.

**Layout:** Scrollable `ListView` with AppBar. Loading spinner in AppBar actions.

#### Permission Banner
- Shown if permission denied. Warning container, "Enable" TextButton → system permission request.

#### Settings Sections

**GENERAL**

| Setting               | Control      | Default       | Notes                             |
|-----------------------|--------------|---------------|-----------------------------------|
| Enable Notifications  | Switch       | On            | Master toggle                     |
| Notification Sound    | Switch       | On            | Disabled when master off          |
| Vibration             | Switch       | On            | Disabled when master off          |
| Quiet Hours Start     | Time picker  | 11:00 PM      |                                   |
| Quiet Hours End       | Time picker  | 7:00 AM       |                                   |

**SMART CLASS REMINDERS**

| Setting               | Control      | Default       | Notes                             |
|-----------------------|--------------|---------------|-----------------------------------|
| Enable Smart Reminders| Switch       | On            |                                   |
| Reminder Time         | Dropdown     | 10 min before | Options: 5/10/15/30 min           |
| Only First Class      | Switch       | Off           | Skips gap reminders               |
| Gap Class Reminders   | Switch       | On            | Disabled if "Only First Class" on |
| Gap Length            | Dropdown     | 30 min        | Options: 30/45/60 min             |

**ATTENDANCE ACTIONS**

| Setting               | Control      | Default       | Notes                             |
|-----------------------|--------------|---------------|-----------------------------------|
| Attendance Reminders  | Switch       | On            |                                   |
| Reminder Delay        | Dropdown     | 5 min after   | Options: Immediately / 5 / 10 min |
| Absent Rest of Day    | Switch       | On            |                                   |

**ATTENDANCE ALERTS**

| Setting               | Control      | Default       | Notes                             |
|-----------------------|--------------|---------------|-----------------------------------|
| Low Attendance Alerts | Switch       | On            |                                   |
| Attendance Target     | Info tile    | —             | "Set in Profile" (read-only)      |
| Recovery Suggestions  | Switch       | On            | Disabled if Low Alerts off        |

**SAFE BUNK PLANNER**

| Setting               | Control      | Default       | Notes                             |
|-----------------------|--------------|---------------|-----------------------------------|
| Safe Bunk Planner     | Switch       | On            |                                   |
| Planner Time          | Time picker  | 9:00 PM       |                                   |
| Include Safe Bunks    | Switch       | On            |                                   |
| Recovery Suggestions  | Switch       | On            |                                   |
| Risk Subjects         | Switch       | On            |                                   |

**DAILY SUMMARY**

| Setting               | Control      | Default       | Notes                             |
|-----------------------|--------------|---------------|-----------------------------------|
| Daily Summary         | Switch       | On            |                                   |
| Summary Time          | Time picker  | 9:00 PM       |                                   |
| Classes Attended      | Switch       | On            |                                   |
| Classes Missed        | Switch       | On            |                                   |
| Overall Attendance %  | Switch       | On            |                                   |

#### Reset to Defaults Button
- `OutlinedButton.icon`, `restore_outlined` icon.
- Confirmation AlertDialog: "Reset Settings?" → "Reset" FilledButton.

**Disabled state:** When parent toggle is off, all children are dimmed (80% alpha) and non-interactive.

---

### 3.10 Premium Screen (`/premium`)

**Purpose:** Subscription management — upsell for free users, plan management for subscribers.

**Layout:** Scrollable `SingleChildScrollView`.

#### AppBar
- Title: Dynamic ("Go Premium" / "Monthly Plan" / "Annual Plan").
- Leading: `close` IconButton.

#### Hero Gradient Card
- Full-width, gradient (primary → primary 78% alpha), top-left to bottom-right.
- Icon: `auto_awesome_rounded` (48, white).
- Title: "AttendanceAI Premium" (`headlineLgMobile`, white).
- Free user: "Unlock the full power…" tagline.
- Premium user: "Active — [Plan] Plan" chip + "Renews on [date]" text.

#### Features List ("Everything You Get")
8 feature rows: 36x36 circle icon + text label.

| Feature                          | Icon                       |
|----------------------------------|----------------------------|
| Unlimited subjects tracking      | `book_rounded`             |
| AI-powered bunk predictions      | `auto_awesome_rounded`     |
| Advanced analytics & charts      | `bar_chart_rounded`        |
| Attendance heatmap               | `grid_view_rounded`        |
| Export attendance reports        | `download_rounded`         |
| Priority customer support        | `support_agent_rounded`    |
| Custom attendance goals          | `track_changes_rounded`    |
| Offline mode support             | `offline_bolt_rounded`     |

#### Pricing / Plan Section (conditional on user state)

**Free user — "Choose Your Plan":**
- Monthly Plan card (`_PlanCard`): ₹20/month, "Billed monthly • Cancel anytime".
- Annual Plan card (`_PlanCard`): ₹200/year, "Just ₹16.67/month • Save 17%". "BEST VALUE" chip.
- "Cancel anytime. No questions asked." caption.

**Monthly subscriber — "Upgrade & Save More":**
- `_CurrentPlanChip`: current plan + renewal date.
- Annual upgrade card.
- Credit note caption.

**Annual subscriber:**
- `_CurrentPlanChip`: Annual plan + renewal date.
- Success card: "You're on the best plan!" message.

#### Plan Card (`_PlanCard`)
- Title + subtitle + Price (36px).
- Loading: spinner. Dimmed (0.6) when other plan loading.

#### Payment Flow (Razorpay)
- `_openCheckout(planType)` triggers SDK.
- Success → premium activated → success SnackBar → auto-pop 800 ms.
- Failure → error SnackBar.
- External wallet → info SnackBar.

---

### 3.11 Subjects List Screen (`/subjects`)

**Purpose:** View, edit, delete all subjects.

**Layout:** `ListView` with AppBar + FAB.

#### AppBar
- Title: "My Subjects". Back button: `arrow_back_ios_new`.

#### FAB
- `FloatingActionButton.extended`, primary bg, "Add Subject". → `/subjects/add`.

#### Subject List Tile (`_SubjectListTile`)
Per subject card:
- Subject name (`headlineMd`) + optional faculty (`bodySm`).
- Attendance % value right-aligned.
- Popup menu: Edit / Delete.
- "X of Y classes • Z safe bunks left" caption.
- `SubjectProgressBar` widget.
- Tapping → `/subjects/detail`.

#### Delete Dialog
- "Delete Subject?" AlertDialog. Cancel + Delete (error background).

**Data States:** Loading (SubjectCardSkeleton) / Empty (EmptyStateWidget + CTA) / Error (inline text).

---

### 3.12 Subject Detail Screen (`/subjects/detail`)

**Purpose:** Deep-dive into a single subject — stats, charts, log, manual adjustments.

#### AppBar
- Subject name as title.
- Edit `IconButton` (pencil) → `/subjects/edit`.
- Popup menu: Edit / Delete.

#### Key Sections
- Quick Stats Strip: Attended / Total / Percentage (color-coded).
- Attendance Progress Ring: `AttendanceProgressRing` with % label; status-colored.
- Charts: Weekly attendance bar chart (`fl_chart`).
- Attendance Log: Chronological records; each with date, time, status badge.
- Manual Adjustment: Quick Present / Absent / Late buttons for instant logging.

---

### 3.13 Add / Edit Subject Screen (`/subjects/add`, `/subjects/edit`)

**Layout:** Form in `ListView` with AppBar.

#### AppBar
- Title: "Add Subject" or "Edit Subject". `close` icon. "Save" TextButton (right, spinner when saving).

#### Form Fields

| Field              | Validation                          |
|--------------------|-------------------------------------|
| Subject Name *     | Required, word capitalization       |
| Faculty (optional) | Optional, word capitalization       |
| Classes Attended   | >= 0, integer                       |
| Total Classes      | >= 0, >= attended, integer          |

Section labels: "SUBJECT DETAILS" and "ATTENDANCE COUNT" (caps). Error SnackBar on save failure.

---

### 3.14 Attendance History Screen (`/attendance/history`)

**Purpose:** Complete chronological log of all attendance records with filtering.

**Layout:** Column → Stats strip + Filter row + Expanded ListView.

#### AppBar
- Title: "Attendance History". Action: "Clear filters" IconButton (only when filter active).

#### Stats Strip (`_StatsStrip`)
Horizontal row: Total (onSurface) / Present (success) / Absent (error) / Late (warning) / Rate % (primary).

#### Filter Row (`_FilterRow`)
Horizontally scrollable animated chips:

| Filter Type   | Control               | Detail                                             |
|---------------|-----------------------|----------------------------------------------------|
| Subject       | Popup menu            | "All Subjects" + per-subject options               |
| Status chips  | Tap toggle            | Present / Absent / Late / Cancelled / Not Marked   |
| Date presets  | Tap toggle            | Today / This Week / This Month                     |
| Custom range  | showDateRangePicker   | Shows "d MMM – d MMM" when selected               |

#### Log Groups (`_DateGroup`)
By date (newest first): Date pill header (today vs formatted date) + class count label.

#### Log Tile (`_LogTile`)
- Status circle icon (40x40, color-coded).
- Subject name + time range.
- Status badge pill.
- Popup menu (3-dot):

| Menu Item        | Action                                          |
|------------------|-------------------------------------------------|
| Edit Status      | Opens `_EditLogSheet` bottom sheet              |
| Change Subject   | Dialog with radio list; updates both subjects   |
| Cancel Period    | Changes status to Cancelled                     |
| Restore Period   | Shown if already cancelled; restores to Present |
| Delete           | Confirmation dialog → permanent delete          |

**Data States:** Loading (`_HistorySkeleton`) / Error (`_ErrorState`) / Empty (filter-aware `_EmptyState`).

---

### 3.15 Analytics Screen (`/analytics`)

> **Note:** NOT in the bottom navigation bar. Tab was previously "Analytics" but is disabled.

**Layout:** `SingleChildScrollView` with AppBar.

#### AppBar
- Title: "AttendanceAI". Action: `history_outlined` → `/attendance/history`.

#### Content Sections

**1. Summary Cards Row (2 cards)**
- Overall Attendance: large % + linear progress bar.
- Subjects: count + "tracked this semester".

**2. Mini-Stats Row (3 cards)**
- Attended / Missed / Total — each colored mini card.

**3. Attendance Trends (`_RealTrendChart`)**
- `LineChart` (fl_chart). Y-axis 0–100%.
- Period toggle: Week / Month / Semester (`ToggleButtons`).
- X labels change per period: day names / week numbers / month abbreviations.
- Curved line, primary color, filled area (primary 10% alpha). Dots: primary fill, white stroke.
- Empty state: icon + "No data for this period".

**4. Subject Comparison**
- Per-subject `LinearProgressIndicator` with % label. Opacity scales with attendance %.

**5. Activity Heatmap (`_RealHeatmap`)**
- 15 weeks x 7 days = 105 cells in a GridView (15 columns).
- Each cell: rounded square, primary color at varying opacity.
- Zero-count: primary at 8% alpha.
- Legend: "Less ... More" color scale.
- Tooltip per cell: "No classes" or "N classes".

**6. Attendance Insights**
- `_InsightTile` per insight: 40x40 circle icon (positive/warning/critical/neutral) + title + subtitle.

**7. History CTA Card**
- Full-width tappable card → `/attendance/history`. Primary 56x56 circle icon.

**Data States:** Loading (spinner) / Error (icon + "Failed to load" + Retry button).

---

### 3.16 Manage Timetable Screen (`/timetable/manage`)

**Purpose:** View, edit, delete weekly timetable entries.

**Layout:** Scaffold with AppBar + FAB + body ListView.

#### AppBar
- Title: "Manage Timetable". Back button. Action: `grid_view_rounded` → `/timetable/builder`.

#### FAB
- `FloatingActionButton.extended`, "Add Class". → `/timetable/manual-entry`.

#### Grouped Entry List (`_GroupedEntryList`)
By day (Mon–Sun order, empty days hidden). Entries sorted by `startTime` within each day.

#### Entry Tile (`_EntryTile`)
- Swipe-to-delete: `Dismissible` (opens dialog, does NOT directly delete).
- Tap → `/timetable/manual-entry` for edit.
- Layout: time column (start + end) | vertical divider | subject name + room/faculty.
- Popup menu: Edit / Delete.

#### Delete Confirmation Dialog (`_DeleteDialog`)
- "Remove Class?" AlertDialog with rich text (subject + day + time slot).
- Optional checkbox: "Also delete N upcoming sessions" (error color, pre-checked).
- Cancel + Remove (error background).

**Empty State:** Icon + "No timetable entries yet" + "Build with Suggestions" (primary) + "Add Class Manually" (outlined).

---

### 3.17 Timetable Builder Screen (`/timetable/builder`)

- Guided flow for building timetable with subject/teacher autocomplete suggestions.
- Accessible from Manage Timetable AppBar icon.

---

### 3.18 Manual Timetable Entry Screen (`/timetable/manual-entry`)

**Purpose:** Add or edit a single timetable entry.

**Accepts:** Optional `extra: TimetableEntry` for edit mode.

**Fields:**
- Subject (linked to subjects or free text).
- Day of week selector.
- Start Time / End Time pickers.
- Room (optional).
- Faculty (optional).
- Save / Cancel actions.

---

## 4. Modals, Sheets & Dialogs

### Bottom Sheets

| Sheet                         | Trigger                              | Type                              | Key Content                                              |
|-------------------------------|--------------------------------------|-----------------------------------|----------------------------------------------------------|
| Bunk Result Sheet             | "Can I Bunk Tomorrow?" button        | Static modal sheet                | Icon + title + subtitle + "Got it" button                |
| Mark Classes Absent           | Schedule → "Mark Absent" button      | Modal sheet                       | 2 choice cards + Cancel                                  |
| Edit Today's Schedule         | Schedule → "Edit Today" button       | DraggableScrollableSheet 0.4–0.95 | Session list + "Add Extra Period" button                 |
| Edit Log Sheet                | History → log tile → Edit Status     | Modal sheet                       | Status radio selection + save                            |
| What-If Simulator             | Predictor → subject card tap         | Modal sheet                       | Bunk simulation controls                                 |

### Dialogs (AlertDialog)

| Dialog                             | Trigger                                    | Actions                         |
|------------------------------------|--------------------------------------------|---------------------------------|
| Sign Out Confirmation              | Profile → Sign Out                         | Cancel / Sign Out (error)       |
| Delete Subject                     | Subjects → popup → Delete                  | Cancel / Delete (error)         |
| Delete Timetable Entry             | Manage Timetable → delete                  | Cancel / Remove (error) + optional checkbox |
| Delete Attendance Record           | History → popup → Delete                   | Cancel / Delete (error)         |
| Change Subject (History)           | History → popup → Change Subject           | Cancel / Apply                  |
| Change Subject (Edit Today Sheet)  | Edit Today → session tile → Change Subject | Cancel / Apply                  |
| Reschedule Class (Edit Today)      | Edit Today → session tile → Reschedule     | Time pickers + Cancel / Apply   |
| Add Extra Period (Edit Today)      | Edit Today → "Add Extra Period" button      | Subject dropdown + time pickers + Cancel / Add |
| Reset Notification Settings        | Notification Settings → Reset              | Cancel / Reset                  |

---

## 5. Global / Shared Components

### `EmptyStateWidget`
- Icon (variable) + Title (`headlineMd`) + optional subtitle + optional action `FilledButton`.

### `SubjectProgressBar`
- Linear progress bar colored by % vs target: above target = primary, near = warning, below = error.

### `AttendanceProgressRing`
- Circular progress with % label center. Same color logic as `SubjectProgressBar`.

### `SubjectCard`
- Name + faculty + % badge + `SubjectProgressBar`. Tappable.

### Skeleton Shimmer Widgets
- `SubjectCardSkeleton`, `DashboardSkeleton`, `_HistorySkeleton` — animated fade 0.4–1.0 (900 ms, repeating).

### `HeroAttendanceCard`
- Overall %, safe bunks, classes needed, goal display.

---

## 6. Data States Per Screen

| Screen                  | Loading State                  | Empty State                          | Error State                    |
|-------------------------|--------------------------------|--------------------------------------|--------------------------------|
| Dashboard               | DashboardSkeleton shimmer      | EmptyStateWidget inline              | Inline text                    |
| Schedule                | CircularProgressIndicator      | `_EmptySchedule` with CTAs           | Inline error text              |
| Predictor               | Custom pulsing icon animation  | "No data yet" icon + text            | "Something went wrong" panel   |
| Profile                 | (immediate from local cache)   | —                                    | —                              |
| Notifications Center    | Skeleton shimmer (6 tiles)     | "No notifications yet" icon + text   | —                              |
| Notification Settings   | Full-screen spinner            | —                                    | —                              |
| Premium                 | (instant from Riverpod)        | —                                    | —                              |
| Subjects List           | SubjectCardSkeleton shimmer    | EmptyStateWidget + FAB hint          | Text('Error: $e')              |
| Subject Detail          | Varies                         | Varies                               | Varies                         |
| Add/Edit Subject        | Save spinner in AppBar action  | —                                    | Error SnackBar                 |
| Attendance History      | _HistorySkeleton shimmer       | Filter-aware _EmptyState             | _ErrorState widget             |
| Analytics               | CircularProgressIndicator      | Per-section "No data" states         | Error icon + Retry button      |
| Manage Timetable        | SubjectCardSkeleton shimmer    | _EmptyBody with two CTAs             | _ErrorBody panel               |

---

## 7. Notification Types

| Type                  | Icon                          | Color             | Description                              |
|-----------------------|-------------------------------|-------------------|------------------------------------------|
| `attendanceWarning`   | `warning_amber_rounded`       | `warning`         | Low attendance alert                     |
| `classReminder`       | `schedule_rounded`            | `primary`         | Pre-class reminder                       |
| `safeBunk`            | `event_available_rounded`     | `success`         | Safe bunk planner notification           |
| `delay`               | `update_rounded`              | `tertiary`        | Class delay notification                 |
| `subscription`        | `workspace_premium_rounded`   | `tertiary`        | Premium / subscription status            |
| `system`              | `info_outline_rounded`        | `onSurfaceVariant`| General system messages                  |

---

## 8. Feature Status Matrix

| Feature                        | Implemented | In Nav | Notes                                       |
|--------------------------------|-------------|--------|---------------------------------------------|
| Login (Email)                  | Yes         | N/A    |                                             |
| Login (Google)                 | Yes         | N/A    |                                             |
| Sign Up (Email)                | Yes         | N/A    |                                             |
| Forgot Password                | Yes         | N/A    |                                             |
| Dashboard / Home               | Yes         | Yes    |                                             |
| Today's Schedule               | Yes         | Yes    |                                             |
| Live Class Progress            | Yes         | Yes    | Auto-refresh every minute                   |
| Edit Today's Schedule          | Yes         | Yes    | Overrides (cancel, reschedule, change, add) |
| Mark Attendance (per class)    | Yes         | Yes    | Present / Absent / Late                     |
| Mark All Absent (bulk)         | Yes         | Yes    | Remaining or full day                       |
| Attendance Predictor           | Yes         | Yes    |                                             |
| What-If Simulator              | Yes         | Yes    | Via predictor cards                         |
| Leave Planner                  | Yes         | Yes    | Section in Predictor                        |
| Semester Forecast              | Yes         | Yes    | Section in Predictor                        |
| Danger Radar                   | Yes         | Yes    | Section in Predictor                        |
| Profile Screen                 | Yes         | Yes    |                                             |
| Attendance Goal Slider         | Yes         | Yes    |                                             |
| Theme Selection (3 modes)      | Yes         | Yes    |                                             |
| Subjects List                  | Yes         | No     | Accessible from Dashboard + Profile         |
| Subject Detail                 | Yes         | No     |                                             |
| Add / Edit Subject             | Yes         | No     |                                             |
| Attendance History             | Yes         | No     | From Dashboard + Analytics                  |
| History Filter — Subject       | Yes         | No     |                                             |
| History Filter — Status        | Yes         | No     | All 5 statuses                              |
| History Filter — Date          | Yes         | No     | Presets + custom range picker               |
| Edit Log Entry                 | Yes         | No     | Status, subject, cancel, delete             |
| Analytics Screen               | Yes         | No     | Screen exists; tab disabled in nav          |
| Analytics Trend Chart          | Yes         | No     | Week / Month / Semester                     |
| Activity Heatmap               | Yes         | No     |                                             |
| AI Insights                    | Yes         | No     |                                             |
| Manage Timetable               | Yes         | No     | Via Schedule AppBar                         |
| Timetable Builder              | Yes         | No     | Via Manage Timetable                        |
| Manual Timetable Entry         | Yes         | No     | Add / Edit slots                            |
| OCR Import (Photo/PDF)         | No          | No     | Code commented out — not enabled            |
| Notification Center            | Yes         | No     | Bell icon on Dashboard                      |
| Notification Settings          | Yes         | No     | Via Profile → More                          |
| Push Notifications             | Yes         | N/A    | Firebase Cloud Messaging                    |
| Premium Screen                 | Yes         | No     | Via Profile AppBar or More section          |
| Monthly Subscription (Rs 20)   | Yes         | No     | Razorpay integration                        |
| Annual Subscription (Rs 200)   | Yes         | No     | Razorpay integration                        |
| Premium Upgrade Monthly→Annual | Yes         | No     |                                             |
| Help & Support                 | No          | No     | Tile present; no action (no-op)             |
| About AttendanceAI             | No          | No     | Tile present; shows version; no action      |
| Offline Mode                   | No          | —      | Listed as premium feature; not built        |
| Export Attendance Reports      | No          | —      | Listed as premium feature; not built        |

---

## 9. Interaction & Animation Inventory

| Element                          | Animation Type                     | Duration | Curve      |
|----------------------------------|------------------------------------|----------|------------|
| Login screen entrance            | FadeTransition + SlideTransition   | 800 ms   | easeOut    |
| Bottom nav icon swap             | AnimatedSwitcher                   | 200 ms   | Default    |
| Nav bar active state             | AnimatedContainer (padding)        | 200 ms   | Default    |
| Notification badge               | AnimatedContainer (size/shape)     | 200 ms   | Default    |
| "Can I Bunk Tomorrow?" button    | AnimatedContainer (color)          | 200 ms   | Default    |
| Current class pulsing dot        | FadeTransition repeat              | 900 ms   | Default    |
| Predictor loading icon           | AnimatedBuilder (opacity pulse)    | 900 ms   | easeInOut  |
| Skeleton shimmer tiles           | FadeTransition 0.4–1.0 repeat      | 900 ms   | easeInOut  |
| Filter chip selection            | AnimatedContainer (bg/border)      | 200 ms   | Default    |
| Predictor filter chips           | AnimatedContainer                  | 150 ms   | Default    |
| Predictor section expand/collapse| SizeTransition + chevron rotate    | 200 ms   | easeInOut  |
| Theme radio selector             | AnimatedContainer (circle)         | 200 ms   | Default    |
| Notification tile (unread→read)  | AnimatedContainer (bg/border)      | 200 ms   | Default    |
| Premium plan card opacity        | AnimatedOpacity (when loading)     | 200 ms   | Default    |
| Swipe-to-delete (Dismissible)    | Platform swipe gesture             | System   | System     |
| DraggableScrollableSheet         | Drag gesture                       | Gesture  | System     |
| Pull-to-refresh (Dashboard)      | RefreshIndicator                   | System   | System     |

---

*End of Audit — June 2026*
