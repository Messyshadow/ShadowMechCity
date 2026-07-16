# Stage 12.4 Cinematics and Tutorial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver skippable opening/ending cinematics and contextual onboarding with persistent old-save-safe state.

**Architecture:** Static cinematic data feeds a reusable overlay; a separate tutorial guide observes existing input actions. Main only wires lifecycle, input lock and QA capture hooks.

**Tech Stack:** Godot 4.7 GDScript, programmatic Control UI, existing Game autoload, headless contract tests, godot-capture.

---

### Task 1: Contract and pure data

**Files:** Create `tests/test_stage_12_4.gd`, `scripts/cinematic_data.gd`.

- [ ] Write assertions for four intro beats, three ending beats, persistent flags and capture hooks.
- [ ] Run the test and confirm it fails because 12.4 resources are absent.
- [ ] Add authored cinematic data and rerun until the data contract passes.

### Task 2: Cinematic overlay

**Files:** Create `scripts/cinematic_panel.gd`; modify `scripts/main.gd`.

- [ ] Build the reusable opening/ending overlay with keyboard, mouse, skip and two ending actions.
- [ ] Connect input locking and `intro_seen` / `ending_seen` state in main.
- [ ] Add deterministic QA entry points for intro and ending screenshots.

### Task 3: Contextual tutorial

**Files:** Create `scripts/tutorial_guide.gd`; modify `scripts/main.gd`, `scripts/game.gd` if migration helpers are required.

- [ ] Define six input-driven tutorial steps and a non-blocking HUD card.
- [ ] Skip onboarding for old saves with established exploration progress.
- [ ] Add a deterministic tutorial screenshot hook and verify the 12.4 contract turns green.

### Task 4: Visual QA, regression and release

**Files:** Modify `docs/DEV_PLAN.md`, `scripts/title_menu.gd`; create `docs/qa/12.4-review.md`.

- [ ] Run editor parsing, every contract and main-scene ERROR/SCRIPT ERROR scan.
- [ ] Capture and inspect intro, tutorial and ending PNGs; fix any clipping or unsafe layout.
- [ ] Update visible build marker and acceptance documents.
- [ ] Commit only 12.4 files, export with source-built Godot, launch the release EXE from its directory and verify timestamps/hashes.
