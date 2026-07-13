# Stage 10.8 Hidden Exploration and Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add seven discoverable themed secret rooms, permanent collectible/chest tracking, and an accurate six-category completion dashboard.

**Architecture:** `rooms.gd` remains the content source; a new stateless `completion.gd` derives totals and progress from room data and saved state. `game.gd` owns persistence, `main.gd` owns hidden-door discovery and procedural presentation, and `map_panel.gd` only renders results.

**Tech Stack:** Godot 4.7 custom source build, GDScript, programmatic 2D rooms, SceneTree contract tests, godot-capture PNG QA.

---

### Task 1: Contract test for room topology and completion API

**Files:**
- Create: `tests/test_stage_10_8.gd`
- Read: `scripts/rooms.gd`
- Read: `scripts/game.gd`

- [ ] **Step 1: Write the failing contract test**

Create a SceneTree test that loads `Rooms.ROOMS`, requires exactly the IDs `secret_hub_archive`, `secret_mine_cache`, `secret_factory_heat`, `secret_water_cistern`, `secret_temple_orbit`, `secret_void_observatory`, `secret_castle_ossuary`, verifies each has `hidden_room: true`, a valid return door, a unique `memory` secret and a uniquely identified chest. Also require `completion.gd`, `permanent_chests`, `completion_snapshot`, and hidden-room map markers.

- [ ] **Step 2: Run the test and verify RED**

Run:
```powershell
$env:APPDATA=(Resolve-Path '.').Path
$env:LOCALAPPDATA=(Resolve-Path '.').Path
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . -s res://tests/test_stage_10_8.gd
```
Expected: exit 1 with missing secret room and completion module assertions.

- [ ] **Step 3: Preserve the red-test evidence**

Do not modify the assertions after they fail for missing features; use the same test for the green pass.

### Task 2: Seven secret rooms and discoverable entrances

**Files:**
- Modify: `scripts/rooms.gd`
- Modify: `scripts/main.gd`
- Test: `tests/test_stage_10_8.gd`

- [ ] **Step 1: Add seven room dictionaries**

Each room must include `hidden_room: true`, `region`, `map`, `bounds`, multi-level `platforms`, a theme-specific mechanic (`water`, `winds`, `hazards`, `runes`, or `breakables`), one `items` chest with explicit ID, one `[x,y,"memory",id]` secret, and one return door.

- [ ] **Step 2: Add hidden entrance doors to seven parent rooms**

Add `hidden: true` and `requires` arrays using only existing abilities: hub/wall_climb, mine/bomb, factory/dash+bomb, water/aqua, temple/double_jump+wall_climb, void/shadow_glider, castle/all six abilities. Ensure the return door is not ability-gated so the player cannot be trapped.

- [ ] **Step 3: Render hidden entrances without map spoilers**

In `_make_door`, apply a subdued theme-colored frame and `隐藏回响` prompt for hidden doors. Existing ability checks remain authoritative. Entering a hidden room uses normal deferred room switching; `Game.visit_room()` is the discovery event.

- [ ] **Step 4: Run the contract test**

Expected: room topology assertions pass; completion assertions still fail because Task 3 is not implemented.

### Task 3: Permanent collection state and completion calculator

**Files:**
- Create: `scripts/completion.gd`
- Modify: `scripts/game.gd`
- Modify: `scripts/pickup.gd`
- Modify: `scripts/main.gd`
- Test: `tests/test_stage_10_8.gd`

- [ ] **Step 1: Add permanent chest migration**

Add `var permanent_chests: Dictionary = {}`. Save/load it under `permanent_chests`; missing old-save data becomes `{}`. `open_session_chest(id)` records both session and permanent dictionaries. Reset clears both. Room spawning skips a chest when either permanent or session-opened.

- [ ] **Step 2: Add memory-core pickup behavior**

Support `kind == "memory"` with the existing orb texture tinted violet/cyan. Collection calls `Game.collect_secret(item_id, "memory")`, shows `记忆核心已同步`, flashes the screen, and never respawns after collection.

- [ ] **Step 3: Implement stateless completion calculations**

`completion.gd` exposes `static func snapshot(rooms, visited, items, permanent_chests, unlocked_weapons, collected) -> Dictionary`. It returns `{rooms, hidden, bosses, chests, weapons, collectibles, done, total, percent}` where every category has `done` and `total`; percentage is `roundi(done * 100.0 / total)` and clamps to 0 when total is zero.

- [ ] **Step 4: Expose Game completion snapshot**

Add `func completion_snapshot() -> Dictionary` that delegates to Completion using live Game state and `Rooms.ROOMS`/`Weapons.LIST`.

- [ ] **Step 5: Run test and verify GREEN**

Expected: `PASS stage 10.8 hidden/completion contracts` and exit 0.

### Task 4: Map completion dashboard and hidden-room reveal

**Files:**
- Modify: `scripts/map_panel.gd`
- Modify: `scripts/main.gd`
- Test: `tests/test_stage_10_8.gd`

- [ ] **Step 1: Draw the six-category dashboard**

On the full M map, call `Game.completion_snapshot()` once per draw. Render total percentage, one overall bar, then room/secret/chest/Boss/weapon/collectible rows with `done / total` and compact bars on the left. Shift the map center right so labels do not overlap rooms.

- [ ] **Step 2: Hide undiscovered secret rooms and links**

The existing `visited` condition remains the reveal gate. For visited `hidden_room` rooms draw a purple fill, dashed-style double outline and diamond marker; normal rooms retain blue styling. Never draw a connection when either endpoint is unvisited.

- [ ] **Step 3: Add capture-only completion setup**

Support `SHOT_COMPLETION=1` in `_auto_screenshot`: visit `hub`, `mine`, `factory_entry`, `void_core` and `secret_void_observatory`; mark `boss_mine_boss`, two explicit chest IDs, `relic_blade`, and three secret IDs; open the map, then capture `_shot.png`. The branch only runs with `--shot` and cannot affect normal saves.

- [ ] **Step 4: Run full script parse and contract tests**

Run editor `--headless --editor --quit`, then stages 10.6.5, 10.7 and 10.8 tests. Expected: zero SCRIPT ERROR and all PASS.

### Task 5: godot-capture QA, documentation, commit and release

**Files:**
- Create: `docs/qa/10.8-review.md`
- Modify: `docs/DEV_PLAN.md`
- QA output: `screenshots/10.8/`

- [ ] **Step 1: Capture all seven secret rooms**

For each secret room run the source-built editor with `SHOT_ROOM=<id>`, a suitable `SHOT_AT`, `SHOT_ZOOM=0.75`, and `--shot`; copy `_shot.png` to `screenshots/10.8/<id>.png`. Scan full output for `ERROR:` and `SCRIPT ERROR` except documented exit-only resource-cache noise.

- [ ] **Step 2: Capture the completion dashboard**

Run with `SHOT_COMPLETION=1`, save `screenshots/10.8/completion-dashboard.png`, and visually inspect text hierarchy, bars, map overlap, hidden-room marker and 1280×720 safety.

- [ ] **Step 3: Inspect every PNG and fix defects**

Open all seven room PNGs and dashboard PNG. Check spawn/return-door reachability, central paths, platform gaps, collectible/chest placement, HUD overlap, missing art and hidden-marker legibility. Any fix requires rerunning the relevant test and recapturing the affected PNG.

- [ ] **Step 4: Write QA and update plan**

Document commands, screenshots, errors found/fixed, licensing and honest manual-play boundaries in `docs/qa/10.8-review.md`. Mark 10.8 complete in `docs/DEV_PLAN.md` only after fresh verification.

- [ ] **Step 5: Commit scoped files**

Stage only 10.6.5/10.7 pending delivery files and 10.8 files; explicitly exclude `assets/decor/mine/`, `docs/godot.code-workspace`, `策划的提议.docx`, logs and `.superpowers/`. Commit with `feat(10.8): add hidden rooms and completion tracking`.

- [ ] **Step 6: Export and launch-scan release**

Export with the source-built editor and configured `template_release` to `E:\Godot\release\暗影机械城\ShadowMechCity.exe`; verify EXE/PCK timestamps and sizes, then launch the release EXE with shot mode and scan output for all errors.
