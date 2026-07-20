# Stage 13C Enemy Coordination Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give six late-game enemies distinct readable attacks and coordinate their actions through a room-scoped combat director.

**Architecture:** Add one `EnemyCombatDirector` node per room to own short-lived melee, ranged, and mobility permissions plus formation slots. Keep shared collision, damage, drops, and legacy behaviors in `enemy.gd`; role-bearing enemies opt into dedicated strategies while every existing role-less enemy follows the previous code path.

**Tech Stack:** Godot 4.7 custom source build, GDScript, programmatic Node2D scenes, existing `Fx` and enemy projectile helpers, headless contract tests, godot-capture PNG review.

---

### Task 1: Define the 13C contracts

**Files:**
- Create: `tests/test_stage_13_c.gd`
- Read: `scripts/main.gd`
- Read: `scripts/enemy.gd`
- Read: `scripts/rooms.gd`

- [ ] **Step 1: Write the failing contract test**

Create a `SceneTree` test that loads source text and asserts:

```gdscript
const ROLE_BY_ID := {
    "void_eagle": "harrier", "void_wyvern": "ambusher",
    "storm_mage": "controller", "soul_shield": "vanguard",
    "soul_spear": "lancer", "soul_cannon": "artillery",
}

func _init() -> void:
    _expect(FileAccess.file_exists("res://scripts/enemy_combat_director.gd"), "director exists")
    var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
    var enemy_src := FileAccess.get_file_as_string("res://scripts/enemy.gd")
    for id in ROLE_BY_ID:
        _expect(main_src.contains('"%s"' % ROLE_BY_ID[id]), "%s has role" % id)
    for marker in ["request_action", "formation_offset", "_b_harrier", "_b_ambusher", "_b_controller", "_b_vanguard", "_b_lancer", "_b_artillery"]:
        _expect(enemy_src.contains(marker) or FileAccess.get_file_as_string("res://scripts/enemy_combat_director.gd").contains(marker), marker)
    _expect(main_src.contains("SHOT_ENEMY_SQUAD"), "squad capture hook")
    quit(1 if not failures.is_empty() else 0)
```

Also inspect `Rooms.ROOMS` and require at least one void room containing all three void roles and one castle room containing the three ground roles.

- [ ] **Step 2: Run the test and observe RED**

Run:

```powershell
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --script res://tests/test_stage_13_c.gd
```

Expected: non-zero exit with missing director, role fields, strategy markers, mixed formations, and capture hook.

- [ ] **Step 3: Commit the failing contract**

```powershell
git add tests/test_stage_13_c.gd
git commit -m "test(13c): define enemy coordination contracts"
```

### Task 2: Build the room combat director

**Files:**
- Create: `scripts/enemy_combat_director.gd`
- Modify: `tests/test_stage_13_c.gd`

- [ ] **Step 1: Extend the test with deterministic runtime assertions**

Instantiate the director and three `Node2D` enemies. Assert the first melee request succeeds, a second different melee request fails until release/timeout, ranged requests respect `RANGED_GAP`, the same enemy cannot own overlapping channels, one registered enemy receives immediate permission, and `formation_offset` returns stable distinct slots.

- [ ] **Step 2: Run and observe RED from the missing API**

Use the Task 1 command. Expected: the director file may load but runtime assertions fail because the methods/constants do not exist.

- [ ] **Step 3: Implement minimal token and formation behavior**

Implement:

```gdscript
extends Node
class_name EnemyCombatDirector

const RANGED_GAP := 0.42
var _members: Array[Dictionary] = []
var _leases := {}
var _clock := 0.0
var _last_ranged := -99.0

func register_enemy(enemy: Node, role: String) -> void:
    if not is_instance_valid(enemy): return
    for entry in _members:
        if entry.enemy == enemy: return
    _members.append({"enemy": enemy, "role": role})

func unregister_enemy(enemy: Node) -> void:
    _members = _members.filter(func(entry): return entry.enemy != enemy)
    notify_action_finished(enemy)

func request_action(enemy: Node, channel: String, duration: float) -> bool:
    _expire_leases()
    for owned_channel in _leases:
        if _leases[owned_channel].enemy == enemy: return false
    if _leases.has(channel): return false
    if channel == "ranged" and _clock - _last_ranged < RANGED_GAP: return false
    _leases[channel] = {"enemy": enemy, "expires": _clock + maxf(duration, 0.1)}
    if channel == "ranged": _last_ranged = _clock
    return true

func notify_action_finished(enemy: Node, channel: String = "") -> void:
    for owned_channel in _leases.keys():
        if _leases[owned_channel].enemy == enemy and (channel == "" or channel == owned_channel):
            _leases.erase(owned_channel)

func formation_offset(enemy: Node, role: String) -> Vector2:
    var index := 0
    for i in _members.size():
        if _members[i].enemy == enemy: index = i
    var side := -1.0 if index % 2 == 0 else 1.0
    var base := {"vanguard": Vector2(120, 0), "lancer": Vector2(220, -10),
        "artillery": Vector2(430, -20), "harrier": Vector2(180, -190),
        "ambusher": Vector2(280, -150), "controller": Vector2(390, -170)}.get(role, Vector2(180, 0))
    return Vector2(base.x * side, base.y)
```

Use weak validity checks on every request, expire leases from `_process(delta)`, and return fixed role-aware offsets with a registration-index side sign.

- [ ] **Step 4: Run 13C and full regression GREEN**

Expected: 13C director runtime assertions pass and the existing 15 tests remain exit 0.

- [ ] **Step 5: Commit**

```powershell
git add scripts/enemy_combat_director.gd tests/test_stage_13_c.gd
git commit -m "feat(13c): add room combat director"
```

### Task 3: Wire roles and mixed formations

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/rooms.gd`
- Modify: `scripts/enemy.gd`
- Modify: `tests/test_stage_13_c.gd`

- [ ] **Step 1: Add failing data/wiring assertions**

Require exact role mapping, `enemy_type`, `combat_role`, `combat_director` assignment in `_spawn_enemy`, one void all-role encounter, and one castle all-role encounter with horizontal spawn separation of at least 180 px.

- [ ] **Step 2: Run and observe RED**

Expected: missing fields/wiring and incomplete room formations.

- [ ] **Step 3: Add minimal wiring**

Add `role` to the six enemy definitions. Create the director when creating `world`, pass the original type/role to each enemy before `add_child`, assign the director, and register in `_ready`. Unregister in `_exit_tree` and death. Update `void_hangar` and `castle_gallery` to contain their complete themed trio without putting an enemy on a reward or door.

- [ ] **Step 4: Run 13C and full regression GREEN**

- [ ] **Step 5: Commit**

```powershell
git add scripts/main.gd scripts/rooms.gd scripts/enemy.gd tests/test_stage_13_c.gd
git commit -m "feat(13c): wire coordinated enemy roles"
```

### Task 4: Implement the void air-combat trio

**Files:**
- Modify: `scripts/enemy.gd`
- Modify: `tests/test_stage_13_c.gd`

- [ ] **Step 1: Add failing behavior assertions**

Require explicit `warn/strike/recover` state markers for harrier; teleport clamp, cross-shot helper, and mobility/ranged permissions for ambusher; three spell patterns selected at hit counts 0/3/6 with ranged permission for controller.

- [ ] **Step 2: Run and observe RED**

- [ ] **Step 3: Implement the harrier**

Hold a formation high slot, request `melee`, draw a cyan Line2D warning, dive after at least 0.28 s, pass through the player once, then recover to the formation slot and release the token.

- [ ] **Step 4: Implement the ambusher**

Request mobility, show three ghosts, clamp the behind-player target against the active room bounds passed by main, teleport, then request ranged and fire two crossing violet projectiles before recovering.

- [ ] **Step 5: Implement the controller**

Maintain distance, request ranged after the common gap, show a spell-color warning ring for at least 0.3 s, then fire one, three, or five projectiles based on `_hit_count / 3` capped at tier 2.

- [ ] **Step 6: Run 13C and full regression GREEN**

- [ ] **Step 7: Commit**

```powershell
git add scripts/enemy.gd tests/test_stage_13_c.gd
git commit -m "feat(13c): diversify void enemy attacks"
```

### Task 5: Implement the castle ground trio

**Files:**
- Modify: `scripts/enemy.gd`
- Modify: `tests/test_stage_13_c.gd`

- [ ] **Step 1: Add failing behavior assertions**

Require frontal shield reduction and shield spark markers, vanguard bash permission, lancer range-line warning and long thrust, artillery retreat band plus alternating single/fan volleys, and melee mutual exclusion through the director.

- [ ] **Step 2: Run and observe RED**

- [ ] **Step 3: Implement vanguard defense/bash**

While facing the player and not attacking, reduce positive incoming damage from the front by 45% (minimum 1), show blue shield sparks, hold a near formation slot, and use a short bash only after obtaining `melee`.

- [ ] **Step 4: Implement lancer telegraph/thrust**

Hold 170–240 px, request `melee`, draw a magenta 260 px warning line for 0.32 s, thrust through that line, then recover and release.

- [ ] **Step 5: Implement artillery spacing/volleys**

Retreat inside 260 px, approach beyond 520 px, otherwise stop. After ranged permission, charge the muzzle for 0.35 s and alternate one direct shell with a three-angle volley.

- [ ] **Step 6: Run 13C and full regression GREEN**

- [ ] **Step 7: Commit**

```powershell
git add scripts/enemy.gd tests/test_stage_13_c.gd
git commit -m "feat(13c): coordinate castle combat roles"
```

### Task 6: Add deterministic squad capture and inspect visuals

**Files:**
- Modify: `scripts/main.gd`
- Modify: `tests/test_stage_13_c.gd`
- Output ignored PNGs: `screenshots/13C/`

- [ ] **Step 1: Add failing capture-hook assertions**

Require `SHOT_ENEMY_SQUAD=void|castle`, a deterministic seed, invulnerable QA player, fixed camera, `SHOT_OUTPUT` directory, and at least six sequential frames.

- [ ] **Step 2: Run and observe RED**

- [ ] **Step 3: Implement the capture burst**

For void, load `void_hangar`, place the player centrally and preserve the three-role formation. For castle, load `castle_gallery` and do the same. Capture eight frames over at least 2.4 seconds so warning and release phases both appear; quit without saving.

- [ ] **Step 4: Generate and actually open PNGs**

Run the graphical source Godot twice with `--shot`; scan every output line for effective `ERROR`/`SCRIPT ERROR`. Open each sequence with `view_image`, not just the final frame.

- [ ] **Step 5: Fix visual defects through RED/GREEN tests**

If an enemy overlaps geometry, attacks have no escape lane, warnings are hidden, or roles collapse into one point, first add a failing geometric/presentation assertion to `test_stage_13_c.gd`, then fix and recapture.

- [ ] **Step 6: Commit**

```powershell
git add scripts/main.gd tests/test_stage_13_c.gd scripts/enemy.gd scripts/rooms.gd
git commit -m "test(13c): add coordinated combat capture coverage"
```

### Task 7: Final verification, QA, release, and Git handoff

**Files:**
- Create: `docs/qa/13C-review.md`
- Modify: `docs/DEV_PLAN.md`

- [ ] **Step 1: Run all tests fresh**

Run all `tests/test_*.gd`; require 16 total, every exit 0, no effective errors.

- [ ] **Step 2: Parse and run the project**

Run headless editor parse and a graphical main-scene session for at least 240 frames. Require exit 0 and zero effective `ERROR` / `SCRIPT ERROR`.

- [ ] **Step 3: Write QA and update DEV_PLAN**

Record scope, RED/GREEN evidence, screenshots inspected, defects fixed, runtime output, asset/license status, and the honest 13D boundary. Mark only 13C complete.

- [ ] **Step 4: Export with source Godot**

Use `--headless --path . --export-release "Windows Desktop"`; verify EXE/PCK timestamps, sizes, and SHA-256 under `E:\Godot\release\暗影机械城`.

- [ ] **Step 5: Direct-launch the release and recapture**

Use the existing `SHOT_ROOM` direct hook plus `SHOT_ENEMY_SQUAD` to create one release PNG. Open it and confirm the coordinated roles shipped in the PCK.

- [ ] **Step 6: Commit only tracked 13C files**

Preserve `assets/decor/mine/`, `docs/godot.code-workspace`, `策划的提议.docx`, and unrelated logs. Commit QA/plan state without `git add .`.
