# Stage 12.2 Quest Log and Title Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a backward-compatible four-chapter main quest journal and replace the title screen's stretched background with an original Shadow Mech City hero image.

**Architecture:** Keep quest definitions in a data-only script and progression evaluation in a pure runtime script. `Game` owns persisted quest flags and tracked quest selection, while a focused CanvasLayer renders the journal and a small HUD tracker. The title screen consumes one generated 16:9 bitmap with a safe fallback color layer.

**Tech Stack:** Godot 4.7 GDScript, programmatic Control UI, JSON save migration, OpenAI built-in image generation, project godot-capture hooks.

---

### Task 1: Failing stage contract

**Files:**
- Create: `tests/test_stage_12_2.gd`

- [ ] Add assertions for four ordered quests, real objective references, pure runtime load, quest save fields, `quest_menu` input, journal setup, HUD tracker, title bitmap path and title capture hook.
- [ ] Run `godot.windows.editor.x86_64.console.exe --headless --path . --script res://tests/test_stage_12_2.gd` and confirm exit 1 because the 12.2 files and contracts are absent.

### Task 2: Quest data and pure progression runtime

**Files:**
- Create: `scripts/quest_data.gd`
- Create: `scripts/quest_runtime.gd`
- Modify: `tests/test_stage_12_2.gd`

- [ ] Define the four main quests and their ordered objectives using `flag`, `visited`, and `item` predicates.
- [ ] Implement safe snapshot evaluation, objective progress text, chapter unlock order and current quest selection without depending on Autoload globals.
- [ ] Extend the failing test with low-, mid- and completed-game snapshots, then run until the runtime contract passes.

### Task 3: Persistence and progression events

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/main.gd`
- Modify: `tests/test_stage_12_2.gd`

- [ ] Add `quest_changed`, `quest_flags`, `tracked_quest_id`, save/load/reset migration and `quest_snapshot()`.
- [ ] Refresh progression after dialogue flags, room visits and Boss defeat; emit notifications only on real state transitions and save them.
- [ ] Register `quest_menu` on physical `N` and verify old saves safely derive the first unfinished chapter.

### Task 4: Journal and HUD tracker

**Files:**
- Create: `scripts/quest_panel.gd`
- Create: `scripts/quest_tracker.gd`
- Modify: `scripts/main.gd`
- Modify: `tests/test_stage_12_2.gd`

- [ ] Build a 720p-safe dark-steel journal with chapter list, status color, objective checklist, location hints, mouse/keyboard selection and tracked-task switching.
- [ ] Build a compact top-right tracker showing the tracked title and up to two unfinished objectives.
- [ ] Lock/unlock player input and maintain `Game.menu_open` correctly when toggling the journal.
- [ ] Add `SHOT_QUEST_LOG` and `SHOT_QUEST_TRACKER` capture states, then make the stage test green.

### Task 5: Original title art and menu composition

**Files:**
- Create: `assets/bg/title/shadow_mech_city_title.png`
- Modify: `scripts/title_menu.gd`
- Modify: `tests/test_stage_12_2.gd`

- [ ] Generate a 16:9 no-text/no-watermark dark mechanical city image with center-left negative space and a right-side city focal point.
- [ ] Inspect the bitmap, save the selected final artifact inside the project, and record generation provenance.
- [ ] Replace the old two-texture stretch with aspect-covered hero art, safe fallback, vignette/atmosphere overlays and a readable dark-steel menu plate.
- [ ] Add a visible build marker `阶段 12.2 · 主线任务系统` and capture contract so the published build is unmistakable.

### Task 6: Verification, documentation, commit and release

**Files:**
- Modify: `docs/DEV_PLAN.md`
- Create: `docs/qa/12.2-review.md`

- [ ] Run editor parse/error scan and regression scripts for 10.6.5, 10.7, 10.8, 12.1 and 12.2; reject any non-noise `ERROR` / `SCRIPT ERROR`.
- [ ] Capture and inspect title, journal and tracker PNGs; fix visual/collision/input defects and repeat captures.
- [ ] Record implementation, generated-asset provenance, hashes, screenshots, regression results and manual-play limits in QA.
- [ ] Exact-stage only the 12.2 files, commit, export with the source-built Godot editor and custom Windows release template to `E:\Godot\release\暗影机械城`.
- [ ] Launch the published EXE for error scanning and generate/view a release-title PNG before recording final EXE/PCK timestamps and SHA-256.

