# Interactive Shaft Transition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the forced 0.42-second down-door tween with a playable 620px shaft that preserves wall slide and wall jump.

**Architecture:** `shaft_transition.gd` owns temporary art, collision and completion. `main.gd` starts the transition and changes rooms only after completion; the existing player and camera remain active.

**Tech Stack:** Godot 4.7, GDScript, CharacterBody2D, Camera2D, godot-capture.

---

### Task 1: Failing shaft contracts

**Files:** Create `tests/test_stage_10_6_5.gd`.

- [ ] Require `shaft_transition.gd`, a 620px playable depth, solid side walls, staggered ledges, a bottom trigger and timeout.
- [ ] Require `main.gd` to stop disabling player physics and to await a completion signal.
- [ ] Run the test with the source Godot console and verify failure because the new script/API is absent.

### Task 2: Playable shaft

**Files:** Create `scripts/shaft_transition.gd`; modify `scripts/main.gd`, `scripts/player.gd`, `scripts/follow_camera.gd`.

- [ ] Implement `setup(theme, center_x, floor_y, player)` and `finished` signal in the shaft node.
- [ ] Build two StaticBody2D walls, three one-way ledges and an Area2D bottom detector; draw themed panels, braces, pipes and depth lights.
- [ ] Add `shaft_mode` to Player so attack/dash/menu inputs are ignored while movement/jump/wall mechanics remain enabled.
- [ ] Replace `_play_shaft_transition()` with creation, camera follow and awaited completion, then restore state and enter the target room.
- [ ] Run the contract and all existing tests until green.

### Task 3: Capture QA

**Files:** Modify `scripts/main.gd`; create `docs/qa/10.6.5-review.md`.

- [ ] Add `SHOT_SHAFT=1` capture automation that triggers the nearest down door and stores six changing frames.
- [ ] Run mine, depths and castle shaft captures; scan every `ERROR` and `SCRIPT ERROR` line.
- [ ] Inspect every PNG for wall alignment, player placement, camera movement and readable depth.
- [ ] Record results and update `docs/DEV_PLAN.md`.
