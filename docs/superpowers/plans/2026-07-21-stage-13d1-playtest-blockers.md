# Stage 13D.1 Playtest Blockers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make dash gates self-explanatory and let players safely retreat from an undefeated Boss room without changing the current demo death-respawn rule.

**Architecture:** Move dash-gate presentation and proximity feedback into a focused `DashGate` component while retaining collision bit 6. Add a focused `BossRetreatConsole` component and expose retreat state through `Main`, with the pause menu consuming the same API. Persist only the completed dash-gate tutorial flag; Boss retreat state remains session-only.

**Tech Stack:** Godot 4 GDScript, programmatic UI/2D nodes, SceneTree contract tests, project godot-capture workflow.

---

## File map

- Create `scripts/dash_gate.gd`: collision-compatible gate visuals, proximity prompt, rejection feedback, success detection.
- Create `scripts/boss_retreat_console.gd`: in-world hold-to-retreat interaction and progress display.
- Modify `scripts/main.gd`: instantiate both components, track Boss entry room, expose retreat API and capture hooks.
- Modify `scripts/pause_menu.gd`: conditionally display the test-build Boss retreat button.
- Modify `scripts/game.gd`: register retreat input and persist dash-gate tutorial completion.
- Create `tests/test_stage_13_d_1.gd`: contracts and runtime state checks.
- Create `docs/qa/13D.1-review.md`: verification evidence after implementation.
- Modify `docs/DEV_PLAN.md`: mark only 13D.1 complete after all gates pass.

### Task 1: Define the failing 13D.1 contract

**Files:**
- Create: `tests/test_stage_13_d_1.gd`

- [ ] **Step 1: Write the failing test**

```gdscript
extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	var game_src := FileAccess.get_file_as_string("res://scripts/game.gd")
	var pause_src := FileAccess.get_file_as_string("res://scripts/pause_menu.gd")
	_expect(FileAccess.file_exists("res://scripts/dash_gate.gd"), "dash gate component exists")
	_expect(FileAccess.file_exists("res://scripts/boss_retreat_console.gd"), "boss retreat console exists")
	for marker in ["boss_entry_room", "can_retreat_boss", "retreat_from_boss", "BOSS_RETREAT_CONSOLE"]:
		_expect(main_src.contains(marker), "main exposes " + marker)
	for marker in ["撤离 Boss 战（测试版）", "can_retreat_boss", "retreat_from_boss"]:
		_expect(pause_src.contains(marker), "pause menu exposes " + marker)
	_expect(game_src.contains('"retreat"'), "retreat input is registered")
	_expect(game_src.contains('"dash_gate_taught"'), "dash gate tutorial flag is persisted")
	if failures.is_empty():
		print("STAGE_13_D_1_PASS")
		quit(0)
	for failure in failures:
		push_error("STAGE_13_D_1: " + failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
```

- [ ] **Step 2: Run the contract and verify RED**

Run:

```powershell
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . -s tests/test_stage_13_d_1.gd
```

Expected: exit code `1` with failures for missing `dash_gate.gd`, `boss_retreat_console.gd`, retreat API, and tutorial flag.

- [ ] **Step 3: Commit the failing contract**

```powershell
git add -- tests/test_stage_13_d_1.gd
git commit -m "test(13d1): define playtest blocker contracts"
```

### Task 2: Replace the static dash gate with a readable component

**Files:**
- Create: `scripts/dash_gate.gd`
- Modify: `scripts/main.gd:631`
- Modify: `scripts/game.gd:260-285,408-418`
- Test: `tests/test_stage_13_d_1.gd`

- [ ] **Step 1: Extend the failing contract with visual and behavior markers**

Add these expectations before the test result branch:

```gdscript
	var gate_src := FileAccess.get_file_as_string("res://scripts/dash_gate.gd")
	for marker in ["冲刺穿越相位屏障", "普通移动无法穿越", "direction_arrow", "dash_gate_taught", "collision_layer = 0b100000"]:
		_expect(gate_src.contains(marker), "dash gate behavior exists: " + marker)
	_expect(main_src.contains("DASH_GATE_SCRIPT"), "main preloads the dash gate component")
```

- [ ] **Step 2: Run and verify RED**

Run the Task 1 test command.

Expected: failures name the missing dash-gate behavior markers.

- [ ] **Step 3: Implement `DashGate`**

Create a `StaticBody2D` component with this public API and state:

```gdscript
extends StaticBody2D
class_name DashGate

var gate_size := Vector2(44, 600)
var direction := 1
var player: CharacterBody2D
var prompt: Label
var reject_cd := 0.0
var was_near := false
var start_side := 0

func setup(size: Vector2, travel_direction: int, target: CharacterBody2D) -> void:
	gate_size = size
	direction = 1 if travel_direction >= 0 else -1
	player = target
	collision_layer = 0b100000
	collision_mask = 0
	_build_gate()

func direction_arrow() -> String:
	return "→" if direction > 0 else "←"
```

Build a pulsing cyan core, three moving arrow chevrons and a prompt label whose full novice text is:

```gdscript
prompt.text = "%s  [Shift] 冲刺穿越相位屏障" % direction_arrow()
```

In `_process(delta)`, show the full prompt within 260 px until `Game.story_flags["dash_gate_taught"]` is true; otherwise show only `[Shift]` within 150 px. When a non-dashing player is within 54 px on the blocked side, flash the gate red and call:

```gdscript
Fx.popup(get_parent(), player.global_position + Vector2(0, -90), "普通移动无法穿越 · 按 Shift 冲刺", Color(1.0, 0.42, 0.32))
```

Detect a side change while near and while collision bit 6 is absent from the player's mask, then call `Game.set_story_flag("dash_gate_taught")`.

- [ ] **Step 4: Replace `_make_dash_gate` construction**

Preload the component:

```gdscript
const DASH_GATE_SCRIPT := preload("res://scripts/dash_gate.gd")
```

Replace the inline visual body with:

```gdscript
func _make_dash_gate(x: float, top: float, w: float, h: float) -> void:
	var gate := StaticBody2D.new()
	gate.set_script(DASH_GATE_SCRIPT)
	gate.position = Vector2(x + w * 0.5, top + h * 0.5)
	world.add_child(gate)
	gate.setup(Vector2(w, h), 1, player)
```

- [ ] **Step 5: Run and verify GREEN**

Run the Task 1 test command.

Expected: dash-gate assertions pass; Boss retreat assertions may remain red until Task 3.

- [ ] **Step 6: Commit the dash-gate slice**

```powershell
git add -- scripts/dash_gate.gd scripts/main.gd scripts/game.gd tests/test_stage_13_d_1.gd
git commit -m "feat(13d1): clarify dash gate traversal"
```

### Task 3: Add safe Boss retreat in-world and in the pause menu

**Files:**
- Create: `scripts/boss_retreat_console.gd`
- Modify: `scripts/main.gd:130-180,205-260,301-420`
- Modify: `scripts/pause_menu.gd`
- Modify: `scripts/game.gd:408-418`
- Test: `tests/test_stage_13_d_1.gd`

- [ ] **Step 1: Extend the failing contract with retreat semantics**

Add:

```gdscript
	var console_src := FileAccess.get_file_as_string("res://scripts/boss_retreat_console.gd")
	for marker in ["长按 B 撤离 Boss 战", "hold_time", "retreat_from_boss", "progress"]:
		_expect(console_src.contains(marker), "retreat console behavior exists: " + marker)
	for marker in ["not Game.has_item(\"boss_\" + room_id)", "_boss_entry_room = from_room", "_enter_room.call_deferred(target_room, room_id)"]:
		_expect(main_src.contains(marker), "retreat safety rule exists: " + marker)
```

- [ ] **Step 2: Run and verify RED**

Run the Task 1 command.

Expected: failures identify the missing console and safe-retreat rules.

- [ ] **Step 3: Add Boss entry state and retreat API to `Main`**

Add:

```gdscript
const BOSS_RETREAT_CONSOLE := preload("res://scripts/boss_retreat_console.gd")
var _boss_entry_room := ""

func can_retreat_boss() -> bool:
	return _boss_entry_room != "" and is_instance_valid(_boss) and not Game.has_item("boss_" + room_id)

func retreat_from_boss() -> void:
	if not can_retreat_boss():
		return
	var target_room := _boss_entry_room
	_boss_entry_room = ""
	boss_bar.hide_boss()
	Game.reset_session_encounters()
	_enter_room.call_deferred(target_room, room_id)
```

In `_enter_room`, before assigning `room_id`, set `_boss_entry_room = from_room` only when the destination contains an undefeated Boss and `from_room` is non-empty. Clear it when entering a non-Boss room.

After spawning an undefeated Boss, create the retreat console 130 px inside the entry-side door and pass `player` plus `self` to its `setup()` method.

- [ ] **Step 4: Implement the in-world hold interaction**

Create a component that exposes:

```gdscript
extends Area2D
class_name BossRetreatConsole

var player: CharacterBody2D
var main_ref: Node
var hold_time := 1.0
var held := 0.0
var progress: Label

func setup(target: CharacterBody2D, owner_main: Node) -> void:
	player = target
	main_ref = owner_main
	_build_visual()
```

Within 150 px, show `长按 B 撤离 Boss 战`; while `Input.is_action_pressed("retreat")`, fill ten progress pips. On reaching `hold_time`, call `main_ref.retreat_from_boss()` exactly once.

- [ ] **Step 5: Add the conditional pause-menu button**

Store the button returned by `_btn` as `retreat_btn`. On `_open()`:

```gdscript
retreat_btn.visible = main_ref != null and main_ref.has_method("can_retreat_boss") and main_ref.can_retreat_boss()
```

The handler must resume before calling Main:

```gdscript
func _on_retreat() -> void:
	_resume()
	if main_ref and main_ref.has_method("retreat_from_boss"):
		main_ref.retreat_from_boss()
```

Register `"retreat": [KEY_B]` in `Game.ACTIONS`.

- [ ] **Step 6: Run and verify GREEN**

Run the Task 1 command.

Expected: `STAGE_13_D_1_PASS`, exit code `0`.

- [ ] **Step 7: Run existing death and Boss regressions**

Run:

```powershell
$godot = 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe'
& $godot --headless --path . -s tests/test_stage_10_5.gd
& $godot --headless --path . -s tests/test_stage_10_7.gd
```

Expected: both scripts exit `0`; current-room death rebuild remains unchanged.

- [ ] **Step 8: Commit the Boss-retreat slice**

```powershell
git add -- scripts/boss_retreat_console.gd scripts/main.gd scripts/pause_menu.gd scripts/game.gd tests/test_stage_13_d_1.gd
git commit -m "feat(13d1): add safe boss retreat"
```

### Task 4: Capture, inspect and document the slice

**Files:**
- Modify: `scripts/main.gd` only if deterministic capture setup needs a 13D.1 branch.
- Create: `docs/qa/13D.1-review.md`
- Modify: `docs/DEV_PLAN.md`

- [ ] **Step 1: Add deterministic QA capture selectors**

Extend `_auto_screenshot()` with `SHOT_13D1=dash_gate` and `SHOT_13D1=boss_retreat`. The dash selector enters `tunnel`, places the player 120 px left of the gate and waits for the proximity prompt. The Boss selector enters `mine_boss`, positions the player beside the retreat console and leaves the Boss visible but outside immediate attack range.

- [ ] **Step 2: Run the source-engine captures and scan all errors**

Run the project godot-capture workflow with the source-built console executable and save output logs. Preserve `_shot.png` as:

```text
screenshots/13d1/dash_gate_prompt.png
screenshots/13d1/boss_retreat_prompt.png
```

Scan every line matching `ERROR` or `SCRIPT ERROR`, excluding only the documented shutdown-only resource-count noise.

- [ ] **Step 3: Visually inspect both PNGs**

Open both PNGs at original detail. Reject and fix the build if the prompt overlaps HUD, the arrow points the wrong way, the key is illegible, the retreat console is hidden behind the Boss, or collision geometry does not align with the gate visual.

- [ ] **Step 4: Run the full contract suite and main-scene smoke scan**

Run every `tests/test_*.gd`, then run `main.tscn` headlessly for at least 240 frames. Expected: all test exit codes `0` and zero actionable `ERROR` / `SCRIPT ERROR` lines.

- [ ] **Step 5: Write QA and update DEV_PLAN**

Document commands, captured files, visual findings, retreat semantics and remaining 13D.2/13D.3 work in `docs/qa/13D.1-review.md`. Add a checked `13D.1` line under stage 13; leave the parent `13D` unchecked until all sub-batches are finished.

- [ ] **Step 6: Export and verify the release package**

Export `ShadowMechCity.pck` to `E:\Godot\release\暗影机械城` with the source-built Godot executable. Launch the release executable with the new PCK and verify its log contains no actionable error.

- [ ] **Step 7: Commit the verified delivery**

```powershell
git add -- scripts/main.gd docs/qa/13D.1-review.md docs/DEV_PLAN.md screenshots/13d1
git commit -m "feat(13d1): deliver playtest blocker fixes"
```

