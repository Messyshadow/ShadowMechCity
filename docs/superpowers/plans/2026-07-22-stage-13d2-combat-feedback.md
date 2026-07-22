# Stage 13D.2 Combat Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify hit stop, knockback, material impact effects, camera shake, and layered combat effects without allowing repeated attacks to stun-lock bosses.

**Architecture:** Add a focused `CombatFeedback` data helper that resolves impact profiles by power tier and target material. Existing player, enemy, boss, FX, and camera scripts consume those profiles while keeping their current damage APIs compatible. Automated contract tests cover profile bounds and integration markers; Godot Capture motion frames verify the actual rendered result.

**Tech Stack:** Godot 4 GDScript, procedural CanvasItem/particle FX, source-built Godot Windows editor, project-local Godot Capture workflow.

---

### Task 1: Feedback profiles and contract

**Files:**
- Create: `scripts/combat_feedback.gd`
- Create: `tests/test_stage_13_d_2.gd`

- [x] **Step 1: Write the failing contract test**

Assert that the helper exposes five material palettes, four bounded impact tiers, a boss scale, and a camera merge window; assert that enemies, bosses, players, FX, and the camera reference the helper APIs.

- [x] **Step 2: Run the contract and verify RED**

Run the source Godot with `--headless --path . -s res://tests/test_stage_13_d_2.gd --log-file .godot/13d2-red.log` and expect `STAGE_13_D_2_FAIL` because `combat_feedback.gd` and integration markers do not exist.

- [x] **Step 3: Implement the minimal profile helper**

Define `LIGHT`, `HEAVY`, `ARMOR_BREAK`, and `FINISHER` profiles with hit-stop duration/scale, camera trauma, knockback scale, ring width, and particle amount. Define `flesh`, `metal`, `stone`, `shield`, and `void` material colors plus deterministic enemy-type material resolution.

- [x] **Step 4: Run the contract and keep remaining integration failures visible**

Expect the data-helper assertions to pass and consumer assertions to remain red.

### Task 2: Material-aware layered hit FX

**Files:**
- Modify: `scripts/fx.gd`
- Modify: `scripts/enemy.gd`
- Modify: `scripts/boss.gd`
- Modify: `scripts/player.gd`

- [x] **Step 1: Add `Fx.combat_impact`**

Render an additive directional spark burst, core flash, expanding ring, and short residue streak. Accept the resolved profile and material palette so warnings remain visually above decorative particles.

- [x] **Step 2: Integrate ordinary enemies and bosses**

Resolve enemy materials from `enemy_type`/behavior. Apply bounded knockback and hit flash to enemies; give bosses reduced hit-stop/knockback response with no state interruption. Route player damage through the same profile system using a flesh palette and red direction cue.

- [x] **Step 3: Run contract GREEN**

Run the 13D.2 test and expect `STAGE_13_D_2_PASS` with exit code 0.

### Task 3: Camera shake merging and motion capture

**Files:**
- Modify: `scripts/follow_camera.gd`
- Modify: `scripts/main.gd`
- Modify: `tests/test_stage_13_d_2.gd`

- [x] **Step 1: Add a failing camera/capture assertion**

Require a merge window that keeps the strongest recent trauma rather than summing every multi-hit impulse, and require a deterministic `SHOT_13D2=material_hits` selector.

- [x] **Step 2: Implement merged trauma and capture staging**

Clamp camera amplitude by tier, merge repeated shakes within 90 ms, and stage metal, flesh, shield, stone, and void targets for automatic motion capture.

- [x] **Step 3: Run the contract GREEN and regression suite**

Run `test_stage_13_d_2.gd`, then all `tests/test_*.gd`; expect zero failures and zero actionable `ERROR`/`SCRIPT ERROR` lines.

- [x] **Step 4: Capture and inspect real PNGs**

Run source Godot with `--shot`, preserve frames under `screenshots/13d2/`, inspect every representative frame, and iterate on overlap, scale, readability, and impact direction.

### Task 4: QA, release, and commit

**Files:**
- Create: `docs/qa/13D.2-review.md`
- Modify: `docs/DEV_PLAN.md`

- [x] **Step 1: Write the QA evidence**

Record RED/GREEN evidence, full-suite results, actionable error scans, inspected PNG paths, visual fixes, and known 13D.3 scope.

- [x] **Step 2: Export with the source engine**

Export preset `Windows Desktop` to `E:\Godot\release\暗影机械城`, then start the published executable hidden with a project-local log and verify exit code 0 with no actionable errors.

- [x] **Step 3: Update roadmap and commit only scoped files**

Mark 13D.2 complete while keeping parent 13D unchecked. Preserve every unrelated tracked/untracked user file, then commit the scoped implementation, tests, QA report, and plan.
