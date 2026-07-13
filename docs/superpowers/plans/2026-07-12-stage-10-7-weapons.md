# Stage 10.7 Weapons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three collectible regional weapons with rune-wave, void-critical lifesteal and corrosion traits.

**Architecture:** Weapon data declares traits; Game owns unlock/save migration; Player applies hit traits; Enemy owns corrosion state; room data places one-time rewards. Original SVG assets keep art self-contained.

**Tech Stack:** Godot 4.7, GDScript, SVG, godot-capture.

---

### Task 1: Failing weapon contracts

**Files:** Create `tests/test_stage_10_7.gd`.

- [ ] Require six weapon records and exact IDs `relic_blade`, `void_blade`, `corrupt_scythe`.
- [ ] Require unlock/save migration and cycling only unlocked IDs.
- [ ] Require rune-wave third-hit, +0.20 critical chance, kill heal and four-second corrosion APIs.
- [ ] Require three room rewards and three SVG files.
- [ ] Run and verify expected failures before production edits.

### Task 2: Data, assets and unlocks

**Files:** Modify `scripts/weapons.gd`, `scripts/game.gd`, `scripts/rooms.gd`, `scripts/main.gd`; create three `assets/weapons/*.svg`; update `assets/ATTRIBUTION.md`.

- [ ] Add complete weapon dictionaries with damage, timing, range, colors, trait and asset path.
- [ ] Implement `unlocked_weapons`, migration defaults, `unlock_weapon()`, `is_weapon_unlocked()` and legal index selection.
- [ ] Place one-time rewards in temple sanctum, void core and water boss; render pickup pedestal and unlock popup.
- [ ] Draw distinct mechanical SVG silhouettes and record them as project-original assets.

### Task 3: Combat traits

**Files:** Modify `scripts/player.gd`, `scripts/enemy.gd`, `scripts/projectile.gd`, `scripts/fx.gd`.

- [ ] Cycle only unlocked weapons and keep HUD/save index valid.
- [ ] Count successful relic-blade hits and spawn a piercing rune projectile on hit three.
- [ ] Add void-blade critical chance and heal after confirming the target changed from alive to dead.
- [ ] Implement corrosion duration/ticks/refresh on Enemy with bubbles and damage popups.
- [ ] Add weapon-specific swing, switch, hit and trait feedback; run contracts and regression tests.

### Task 4: QA and release

**Files:** Create `docs/qa/10.7-review.md`; modify `docs/DEV_PLAN.md`.

- [ ] Use `SHOT_WEAPON` motion captures for all three weapons and `SHOT_SWITCH=1` stills.
- [ ] Inspect all frames; fix clipping, scale, missing motion and weak trait readability.
- [ ] Run all tests and scan all runtime `ERROR` / `SCRIPT ERROR` lines.
- [ ] Export with the source-built template, launch the release EXE, capture the published build, update QA/DEV_PLAN, commit exact files.
