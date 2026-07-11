# Stage 10.5 Void Fortress Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete Void Fortress vertical slice while preserving the existing glide ability.

**Architecture:** Extend the existing data-driven room/enemy pipeline, generalize the current updraft into directional wind, and isolate the aerial-to-ground dragon behavior in a dedicated boss script. Keep old room and boss behavior unchanged.

**Tech Stack:** Godot 4.7, GDScript, programmatic Node2D scenes, headless GDScript smoke tests, godot-capture PNG QA.

---

### Task 1: Contract tests

**Files:** Create `tests/test_stage_10_5.gd`.

- [ ] Write assertions for five linked rooms, three enemy definitions, `shadow_glider`, directional wind data, and the dedicated boss mode.
- [ ] Run `godot --headless --path . --script res://tests/test_stage_10_5.gd` and confirm failure because 10.5 data is absent.

### Task 2: Ability and airflow compatibility

**Files:** Modify `scripts/game.gd`, `scripts/player.gd`, `scripts/pickup.gd`, `scripts/updraft.gd`, `scripts/main.gd`.

- [ ] Register `shadow_glider`; granting it also grants `glide`.
- [ ] Add directional wind setup and player velocity application, with reduced horizontal push and stronger lift while enhanced gliding.
- [ ] Add `winds` room-data generation and rerun the focused test.

### Task 3: Fortress rooms and enemies

**Files:** Modify `scripts/rooms.gd`, `scripts/main.gd`, `scripts/enemy.gd`.

- [ ] Add the Hub connection and five-room chain with safe spawn points, platforms, wind fields, enemies, save point, rewards, and Boss metadata.
- [ ] Add `void_eagle`, `void_wyvern`, and `storm_mage` definitions and behavior state transitions.
- [ ] Run the focused test and a headless startup scan.

### Task 4: Void Dragon boss

**Files:** Create `scripts/void_dragon_boss.gd`; modify `scripts/main.gd`.

- [ ] Dispatch Boss metadata with `mode: "void_dragon"` to the dedicated script.
- [ ] Implement phase-one flight/cross/barrage and phase-two fall/charge/slam/lightning with the existing boss signals.
- [ ] Run the focused test and start the Boss room headlessly.

### Task 5: Visual and release QA

**Files:** Modify `docs/qa/10.5-review.md`, `docs/DEV_PLAN.md`.

- [ ] Capture each fortress room and inspect every PNG for reachability, overlap, clipping, scale, and readability.
- [ ] Capture the Boss at both phases and verify visibly distinct forms.
- [ ] Run full ERROR/SCRIPT ERROR scans, update the QA report and plan, then export with the existing Windows Desktop preset to `E:\Godot\release\暗影机械城`.
