# Stage 10.6 Shadow Castle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the six-room Shadow Castle finale with improved vertical shafts, elite encounters, sequential knight bosses, a three-phase final boss, and upgraded combat presentation.

**Architecture:** Extend room data with `shafts` and castle decoration fields, keep transitions in `main.gd`, and isolate both finale bosses in dedicated scripts. Reuse existing projectile and FX primitives while adding focused castle/weapon effects instead of restructuring the whole game.

**Tech Stack:** Godot 4.7 custom build, GDScript, procedural Node2D scenes, headless contract tests, godot-capture PNG QA.

---

### Task 1: Finale contracts

**Files:** Create `tests/test_stage_10_6.gd`.

- [ ] Assert the six room IDs, ordered connections, castle theme, shaft metadata, knight enemy definitions, `soul_knights` mode, and `void_king` mode.
- [ ] Run `godot --headless --path . --script res://tests/test_stage_10_6.gd`; expect failure listing missing castle rooms.

### Task 2: Vertical shaft presentation and transition

**Files:** Create `scripts/shaft.gd`; modify `scripts/main.gd`, `scripts/rooms.gd`.

- [ ] Add room data `shafts: [[x, top, width, depth]]` and generate a solid rim, dark well, chains, arrow and descending particles.
- [ ] Route down-door activation through `_play_shaft_transition(to_room)` so the camera follows a short fall before deferred room loading.
- [ ] Run the contract and capture `mine` plus `depths` to prove old down/up connections still load without errors.

### Task 3: Castle rooms and background

**Files:** Modify `scripts/rooms.gd`, `scripts/main.gd`.

- [ ] Add the six room dictionaries and a `castle` theme backed by existing background textures plus procedural gothic arches, columns, chains and rifts.
- [ ] Require `shadow_glider`, `aqua`, `bomb`, `wall_climb`, `glide`, and dash availability at the castle entrance; show missing ability names without consuming items.
- [ ] Capture each room at wide zoom and correct unreachable platforms, door overlap and empty focal areas.

### Task 4: Knight enemy behaviors and sequential boss

**Files:** Create `scripts/soul_knights_boss.gd`; modify `scripts/enemy.gd`, `scripts/main.gd`.

- [ ] Register shield, spear and cannon knight definitions.
- [ ] Implement telegraphed guard/counter, leap/thrust and fan-shot/mine behaviors.
- [ ] Spawn the trio in sequence, emit the standard boss signals, and unlock the arena only after all three are defeated.

### Task 5: Three-phase Void Mechanical King

**Files:** Create `scripts/void_king_boss.gd`; modify `scripts/main.gd`, `scripts/rooms.gd`.

- [ ] Implement phase thresholds at 66% and 33%, with distinct color, silhouette, collision and move tables.
- [ ] Ensure charge, teleport barrage and light-core pulse each use visible telegraphs before damage.
- [ ] Add an ending overlay and save `boss_castle_throne` after defeat.

### Task 6: Combat presentation baseline

**Files:** Modify `scripts/fx.gd`, `scripts/player.gd`, `scripts/main.gd`.

- [ ] Add `Fx.weapon_switch(parent, pos, color, weapon_kind)` with two contracting rings, a vertical flare and particles.
- [ ] Invoke it from `_switch_weapon()` while preserving the existing HUD signal.
- [ ] Capture sword/hammer/cannon switching and representative ground/upper/ultimate skills; reject identical frames or effects obscuring the player.

### Task 7: QA, commit and release

**Files:** Create `docs/qa/10.6-review.md`; modify `docs/DEV_PLAN.md`.

- [ ] Run contract tests and every castle room, scanning all `ERROR` and `SCRIPT ERROR` lines.
- [ ] Inspect room, shaft, weapon and Boss PNGs and iterate until geometry and phases are visually distinct.
- [ ] Update QA and plan, stage only 10.6 files, commit `feat(10.6): 完成暗影王城终章`, then export `ShadowMechCity.pck` with the custom Godot build.
