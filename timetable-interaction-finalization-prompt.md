# Timetable Interaction Finalization — Full Prompt

Paste into the agent. Scope is strictly limited to the files listed under each phase. Do not modify onboarding architecture, subject/timetable data-model consolidation, navigation, or autosave logic already completed in earlier prompts — those are done and verified. Do not add undo/redo, confirmation dialogs, or any feature not explicitly listed here. Do not touch visual styling/colors/layout of the grid screen beyond what's functionally required by the items below — a separate Stitch-fidelity pass will handle visual design later; this pass is behavior/logic only.

You already have full context on this codebase from prior sessions. Do not re-explore unrelated modules (Attendance, Planner, Subject Overview, Dashboard) — scope reads/writes strictly to: `timetable_editor_models.dart`, `timetable_editor_repository.dart`, `timetable_editor_notifier.dart`, `timetable_grid.dart`, `subject_library_strip.dart`, `cell_bottom_sheet.dart`, `ob_timetable_grid_screen.dart`, `edit_timetable_screen.dart`, `SubjectModel` and its repository, and the class-session generation function. Work phase by phase; each phase should be verifiable independently before moving to the next.

---

## Phase A — Performance foundation (do this first; everything else depends on it)

The freeform continuous-timeline rewrite introduced lag that wasn't present in the earlier row-based grid. Fix root causes before adding any new interaction:

1. Audit the Riverpod provider powering the grid — confirm it uses `.select()` or equivalent scoping so a single lecture/subject change only rebuilds the affected widget, not the entire grid tree.
2. Add `RepaintBoundary` around each individual lecture block widget, isolating its paint pass from the rest of the day column.
3. If hour gridlines are drawn via `CustomPainter`, confirm `shouldRepaint` returns `false` unless the visible range actually changed — they must not repaint on unrelated state changes.
4. Confirm `LectureBlock`/`Subject` model classes have correct `==`/`hashCode` (or use `Equatable`/manual value equality) so Firestore snapshot rebuilds don't cause Riverpod to treat every field as changed when only one did.
5. Verify: place 10+ lectures across multiple days, confirm placing/editing one does not cause visible jank or rebuild of unrelated blocks (use Flutter DevTools' rebuild/repaint overlay to confirm, don't just eyeball it).

---

## Phase B — Fix the tap-position drift bug

Root cause: the pixel↔time conversion is likely computed independently in the renderer (time→pixel for drawing blocks) and the tap handler (pixel→time for placement), using stale/cached range or scale values that can diverge whenever the visible hour range changes via Edit Timings.

1. Create a single shared conversion utility (e.g. two pure functions: `minutesToY(minutes, rangeStart, pxPerMinute)` and `yToMinutes(y, rangeStart, pxPerMinute)`) that both the renderer and every gesture handler call — no independent formulas anywhere else.
2. Ensure `rangeStart` and `pxPerMinute` are read live from current state on every call (from the provider, not cached in `initState` or a field set once).
3. Verify: change the visible hour range via Edit Timings, then tap-place a lecture — it must land at the correct rounded time relative to the new range, with zero drift, repeatedly, not just on the first attempt after the change.

---

## Phase C — Cell states: collapsed → revealed → edit sheet

Replace any existing tap-opens-popup behavior with this exact state machine per occupied cell:

1. **Default (collapsed):** subject short name only, centered.
2. **One tap → revealed:** name stays, exact time range ("9:00–9:45") appears below it in smaller/muted text, small cross (×) icon appears top-right of the block. Tapping the block body again (not the cross) opens the small bottom edit sheet (exact start/end, faculty/classroom/notes — reuse whatever fields already exist in the cell bottom sheet, just triggered from this new entry point). Tapping anywhere else on the grid collapses back to default.
3. **Cross tap:** removes the lecture immediately. No confirmation dialog, no undo/snackbar. Deletion must go through the same repository delete path already used elsewhere (single source of truth), not a new ad-hoc write.
4. **Small-block exception:** if the block's rendered height can't fit name + time + cross without clipping (roughly under ~25 minutes of duration at current scale), allow the revealed state to visually overflow slightly beyond the block's own bounds into adjacent empty space (whichever direction — up or down — has room), collapsing back to the block's true proportional height once dismissed. Normal-length blocks must stay exactly space-efficient with no overflow.
5. **Hit-testing:** the cross icon and the edit-sheet trigger must be separate tap targets with the cross consuming its own tap before it reaches the block-body handler — tapping the cross must never also open the edit sheet.
6. **Long-press, from either collapsed or revealed state, always initiates drag** (Phase D) — it must never require the block to already be in the revealed state first.

---

## Phase D — Long-press drag-to-reposition with candidate-snapping ghost preview

1. Use `LongPressDraggable` (or equivalent) on each block. On long-press start: lift animation (subtle scale ~1.03x + shadow increase via cheap composited transform, e.g. `AnimatedScale`), light haptic. This happens in local widget state only — no Firestore write, no provider update yet.
2. **While dragging:** the block follows the raw finger position with no snapping. Simultaneously render a separate ghost/outline widget showing where it would land if released now, using the candidate algorithm below. A subtle background tint highlights the hovered time band.
3. **Candidate algorithm** (recompute continuously as the drag position updates, scoped to the day column currently under the finger):
   - For every existing block on that day, generate two candidates: "start exactly when this block ends" (flush-after) and "end exactly when this block starts" (flush-before, i.e. `candidateStart = thatBlock.start - draggedBlock.duration`).
   - Generate standard 15-minute-rounded candidates across the visible range.
   - **Discard any candidate that would cause the dragged block to overlap an existing block** (other than the block being dragged itself, if repositioning one that already exists). This guarantees the ghost can never preview an invalid position.
   - From the surviving candidates, snap the ghost to whichever is numerically closest to the raw (unsnapped) pointer time.
   - If the raw pointer is directly over an occupied block with no valid nearby candidate on either side within a reasonable range, show no ghost at all rather than forcing an invalid or distant snap.
4. **On release:** commit exactly one write to the `LectureBlock`'s start time, using wherever the ghost was last shown. Animate with `AnimatedPositioned` (spring/ease curve) into the final resting position, haptic confirms. If the committed position is flush against a same-subject neighbor (exact end==start match), suppress the shared border immediately per existing contiguous-block rendering logic.
5. **No overlap warning during drag** — per the candidate filtering above, an invalid position is never shown, so there is nothing to warn about. The existing overlap-warning UI stays, but scope it exclusively to the long-press edit sheet's manual exact-time-entry fields (Phase C step 2), since that's the only remaining path where a real conflict could be typed in directly.
6. **Tap-to-place (existing, unaffected by this phase):** stays as-is — tap a selected subject chip, tap an empty cell, places at nearest clean 15-min rounded time using the shared conversion utility from Phase B, at the default lecture duration.

---

## Phase E — Subject color fix

1. Audit subject-creation color assignment — it currently always returns the same palette value instead of cycling. Fix: assign the next unused palette color based on existing subject count (or least-used color if subjects have been deleted).
2. Add a simple color-swatch picker (row of tappable palette dots, selected one shows a ring/check) to both Subject Setup and the grid's subject edit surface, writing to `SubjectModel.colorHex` with the same debounced-write pattern used elsewhere.
3. **One-time backfill:** for any existing subject in Firestore with a null/missing `colorHex` or `shortName`, generate and write both now, following the same generation logic as new subjects. Run this once, not on every app load.
4. Make card rendering defensive regardless: if `shortName` is somehow still null at render time, fall back to the first few characters of `name` rather than rendering blank text.

---

## Phase F — Edit Timetable screen button consolidation

1. Remove the duplicate bottom "Done" button.
2. Bottom button becomes a Settings/Customize action (gear icon or similar) opening a bottom sheet with: default lecture duration, visible hour range start/end. No other new settings unless they already exist elsewhere in this screen.
3. Top-right becomes the single primary action, labeled "Done" (not "Save" — every edit already autosaves instantly; this button only closes the screen).

---

## Phase G — Safe class_sessions regeneration

Root cause: Home/Schedule reads from `class_sessions`, which is only generated once at onboarding completion and never regenerated when the timetable is edited afterward.

1. Implement `regenerateFutureClassSessions()`:
   - **Protected, never touched:** any session where `date < today` OR `status != notMarked`.
   - **Eligible:** everything else (`date >= today AND status == notMarked`) — delete these in a batch, then regenerate fresh `notMarked` sessions for `today → semester end` by walking each date, matching weekday against current `lectures`, creating one session per matching instance.
2. Trigger this **debounced** (~1.5s after the last grid edit, or on grid-screen exit/"Done" tap) — not on every single placement.
3. Verify explicitly: mark attendance for a past/today session, then edit tomorrow's timetable — confirm that marked session and its linked `attendance_logs` entry (referenced via `sessionId`) are completely untouched. Then edit a future lecture and confirm Home reflects the change within ~2 seconds without manual refresh.

---

## Full verification checklist

- [ ] Grid remains smooth (no dropped frames, verified via DevTools) with 10+ lectures placed across multiple days, both idle and while placing/editing
- [ ] Changing the visible hour range via Edit Timings, then tap-placing, lands at the correct time with zero drift, repeatably
- [ ] Tap an occupied cell → reveals time + cross, tap again → opens edit sheet, tap cross → removes instantly with no confirmation
- [ ] Tap elsewhere → collapses back to name-only
- [ ] A very short block's revealed state doesn't clip — overflows into adjacent space instead
- [ ] Long-press from collapsed state → drag works immediately (no requirement to reveal first)
- [ ] Dragging a block near another block's edge shows a ghost distinctly snapping between "flush against it" and "15-min-gap clean time," flipping at the correct midpoint, exactly matching the 9:00–9:45 + drag-near-10:00 example
- [ ] Dragging over an occupied block never shows an invalid ghost position and never produces a warning — it silently offers the nearest valid spot
- [ ] Manually typing an exact conflicting time in the edit sheet still shows the overlap warning
- [ ] Two contiguous same-subject blocks (exact end==start) render with no divider between them, including after a drag that produces this result
- [ ] New subjects get visibly different colors automatically; existing subjects can have their color changed
- [ ] Previously-created test subjects with blank/red-only appearance are backfilled correctly after this pass
- [ ] Edit Timetable screen has exactly one "Done" (top right) and one "Customize" (bottom) action
- [ ] Editing the timetable updates Home/Schedule within ~2 seconds; past/marked sessions remain completely untouched
- [ ] `flutter analyze` clean across all files touched in this pass
