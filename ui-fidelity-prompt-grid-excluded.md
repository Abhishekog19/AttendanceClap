# UI Fidelity Implementation Prompt (Grid Screen Excluded)

Paste into Antigravity. This is a UI-only pass: it does NOT touch data models, providers, Firestore logic, navigation, or the interaction behavior finalized in the separate Timetable Interaction Finalization / regression-fix prompts.

**Budget constraint: this is a single-session task. Work efficiently — do not re-explore files or re-fetch Stitch data unnecessarily, don't re-read files you've already read in this session, and don't produce speculative alternative versions of anything. Do exactly what's specified, once, correctly.**

**Non-regression rule, strict: do not modify any file outside the 8 files listed in the mapping table below. Do not change any provider, notifier, repository, Firestore call, navigation call, or business logic in any file you do touch — visual/layout changes only. If achieving a visual match seems to require a logic change, STOP and ask before proceeding rather than making the change. Every one of these screens currently works correctly end to end (verified across multiple prior sessions) — nothing about their behavior may change, only their appearance.**

**The Timetable Builder / grid screen (`ob_timetable_grid_screen.dart`, `timetable_grid.dart`, `edit_timetable_screen.dart`, `cell_bottom_sheet.dart`) is explicitly EXCLUDED from this pass. Do not restyle, re-theme, or visually modify these files at all right now — that grid's final design hasn't been decided yet and will be done separately once a Stitch design for it exists. Leave its current visuals exactly as they are.**

---

## Step 1 — Fetch everything, images AND code, before writing any Flutter code

## Stitch Instructions
Get the images and code for the following Stitch project's screens:
## Project
Title: Attendance AI Onboarding Flow
ID: 13912202415305631836
## Screens:
1. Semester Setup
    ID: 7404b73d3db64f85b0dbb287bf258e86
2. College Details
    ID: 18696df92ec647b0b73a42d5f2dd5095
3. Welcome to Attendance AI
    ID: ac242fe672ba483eb4b3b774e589ac07
4. Subject Setup
    ID: 9cbdb010c96a4bc988ff01aa935a17ee
5. Holiday Calendar
    ID: 80f8b16804a542f0921a8fda3090a932
6. Review Your Plan
    ID: a915d0de7a3840bfab03724f536bd550
7. Attendance Import
    ID: 4a714b3113e845cab8d2eaffb9c3ff86
8. Success!
    ID: 71c63ddc48e54b7c99d53d1d96a5b671

Note: the "Timetable Builder" screen (ID c5c090248f5b40558fd272275ac26571) exists in this Stitch project but must NOT be fetched or implemented in this pass — it is explicitly excluded per the instructions above.

Use a utility like `curl -L` to download the hosted URLs. Save every screenshot and code export locally in a `stitch-reference/` folder in the project root, one subfolder per screen, before doing anything else. Do not proceed to Step 2 until all 8 screens (excluding Timetable Builder) have both an image and a code export saved locally.

---

## Step 2 — Extract a single shared DESIGN.md before touching any screen file

After fetching all 8 screens, analyze them together (not one at a time in isolation) and produce one `DESIGN.md` in the project root containing the literal, extracted values — not descriptions, not approximations:

- Exact hex codes for every color used (background, text, borders, card fills, button states, subject-color palette if visible)
- Font family, and exact weight/size for each text style tier (headline, body, label, button text, muted/secondary text)
- Exact corner radius values used on cards, buttons, chips
- Exact spacing/padding values (between sections, inside cards, around the screen edge)
- Button styles: fill color, text color, height, corner radius, for both primary (black pill) and secondary/outlined variants
- The progress-dot indicator: size, spacing, active vs inactive dot style
- Any icon style conventions (stroke width, size) visible across screens

If you find inconsistencies between screens for what should be the same value, flag it to me explicitly in the DESIGN.md rather than picking one arbitrarily. Do not write any Flutter code until I've confirmed this DESIGN.md.

---

## Step 3 — Map each screen to its real file, then implement literally

Once confirmed, implement each screen strictly against its saved reference image + code export, using only DESIGN.md token values:

| Stitch screen | Implement into |
|---|---|
| Welcome to Attendance AI | `ob_welcome_screen.dart` |
| College Details | `ob_college_details_screen.dart` |
| Semester Setup | `ob_semester_setup_screen.dart` |
| Subject Setup | `ob_subject_setup_screen.dart` |
| Holiday Calendar | `ob_holiday_calendar_screen.dart` |
| Attendance Import | `ob_attendance_import_screen.dart` |
| Review Your Plan | `ob_review_screen.dart` |
| Success! | `ob_success_screen.dart` |

**Do not create or modify an entry for the Timetable Builder / grid screen in this table or anywhere in this pass.**

**Rules for this pass:**
- Styling and layout only. Do not change what any screen reads, writes, or how it navigates — that logic is already correct and must be preserved exactly, including every provider call, Firestore read/write, and navigation call.
- Use only colors, type styles, spacing, and radii present in DESIGN.md. Do not introduce any value not in that file.
- Match each reference image's layout structure element-for-element — same order, same relative spacing, same alignment — not a "similar-looking" reinterpretation.
- If anything is ambiguous or a value wasn't cleanly extractable, stop and ask rather than guessing.
- All 8 screens must share the same `OnboardingScaffold`/theme tokens so they're visually identical in system even though content differs.
- Confirm the Review screen's timetable summary card (if it references the grid) reads live data correctly but does not need its own visual redesign — only the surrounding Review screen chrome gets the Stitch treatment.

---

## Step 4 — Vibe check

After implementing all 8 screens, open each one side by side with its corresponding saved Stitch screenshot from `stitch-reference/`. Report specific visual deltas (color mismatch, spacing off, wrong font weight, misaligned element) screen by screen — specific, not a general "looks close" assessment. Fix only genuine, clear deltas — do not iterate speculatively on things that are already a close match. I will review this list before approving.

**Final confirmation before you finish: re-check that `ob_timetable_grid_screen.dart`, `timetable_grid.dart`, `edit_timetable_screen.dart`, and `cell_bottom_sheet.dart` were not modified at all during this pass, and that no provider/logic/navigation code changed in any of the 8 screens you did touch.**
