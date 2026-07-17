# Interactive Teleport and Hidden Entry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade up/down portals and all hidden entrances to show an `E / Enter` prompt and require deliberate interaction, while preserving automatic horizontal doors and the existing shaft transition.

**Architecture:** A focused `portal_interaction.gd` owns proximity, prompt text, input consumption, and ability-gate feedback. `main.gd` remains the sole room-transition authority and reuses `_on_door()`, `_enter_room()`, and `_play_shaft_transition()`; a focused `portal_visual.gd` supplies layered procedural portal art without coupling visuals to room loading.

**Tech Stack:** Godot 4.7 GDScript, Area2D/StaticBody2D/Line2D/CPUParticles2D, existing `Game` autoload and room dictionary, headless GDScript contract tests, project godot-capture workflow.

---

### Task 1: Specify portal classification and prompt behavior

**Files:**
- Create: `tests/test_stage_10_9.gd`
- Create: `scripts/portal_interaction.gd`

- [ ] **Step 1: Write the failing classification contract**

Create `tests/test_stage_10_9.gd` with assertions for the public static API:

```gdscript
extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var path := "res://scripts/portal_interaction.gd"
	_check(FileAccess.file_exists(path), "portal interaction script must exist")
	if FileAccess.file_exists(path):
		var portal = load(path)
		_check(not portal.requires_interaction({"side":"left"}), "ordinary left door remains automatic")
		_check(not portal.requires_interaction({"side":"right"}), "ordinary right door remains automatic")
		_check(portal.requires_interaction({"side":"up"}), "up portal requires interact")
		_check(portal.requires_interaction({"side":"down"}), "down shaft requires interact")
		_check(portal.requires_interaction({"side":"left", "hidden":true}), "hidden side door requires interact")
		_check(portal.requires_interaction({"side":"left", "trigger_mode":"interact"}), "explicit interact override works")
		_check(not portal.requires_interaction({"side":"up", "trigger_mode":"auto"}), "explicit auto override works")
		_check(portal.prompt_text({"side":"up"}, "破碎甲板", false, []).contains("启动传送阵"), "up prompt names teleport action")
		_check(portal.prompt_text({"side":"down"}, "地下水道", false, []).contains("向下进入"), "down prompt names descent")
		_check(portal.prompt_text({"side":"left", "hidden":true}, "遗失档案库", false, []).contains("隐藏回响"), "unvisited secret stays unnamed")
		_check(portal.prompt_text({"side":"left", "hidden":true}, "遗失档案库", true, []).contains("遗失档案库"), "visited secret shows target name")
		_check(portal.prompt_text({"side":"up"}, "破碎甲板", false, ["暗影滑翔翼"]).contains("需要：暗影滑翔翼"), "locked prompt lists missing abilities")
	_finish()

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("PASS stage 10.9 portal contracts")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)
```

- [ ] **Step 2: Run the contract and verify RED**

Run:

```powershell
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . -s res://tests/test_stage_10_9.gd
```

Expected: exit code `1`, with `portal interaction script must exist`.

- [ ] **Step 3: Add the minimal pure helpers**

Create `scripts/portal_interaction.gd` beginning with:

```gdscript
class_name PortalInteraction
extends Area2D

signal travel_requested(door_data: Dictionary)
signal travel_blocked(missing: Array[String])

static func requires_interaction(door: Dictionary) -> bool:
	var override := str(door.get("trigger_mode", ""))
	if override == "interact": return true
	if override == "auto": return false
	return bool(door.get("hidden", false)) or str(door.get("side", "")) in ["up", "down"]

static func prompt_text(door: Dictionary, target_name: String, visited: bool, missing: Array[String]) -> String:
	if not missing.is_empty(): return "需要：" + " / ".join(missing)
	if bool(door.get("hidden", false)):
		return "[E / Enter] 前往 " + target_name if visited else "[E / Enter] 进入隐藏回响"
	if str(door.get("side", "")) == "down": return "[E / Enter] 向下进入"
	return "[E / Enter] 启动传送阵"
```

- [ ] **Step 4: Run the contract and verify the pure helpers pass**

Run the Task 1 command again. Expected: `PASS stage 10.9 portal contracts`, exit code `0`.

- [ ] **Step 5: Commit the behavior contract and helpers**

```powershell
git add -- tests/test_stage_10_9.gd scripts/portal_interaction.gd
git commit -m "test(10.9): specify interactive portal behavior"
```

### Task 2: Implement proximity, prompt, and guarded input

**Files:**
- Modify: `scripts/portal_interaction.gd`
- Modify: `tests/test_stage_10_9.gd`

- [ ] **Step 1: Extend the test with runtime signal behavior**

Add after the pure helper assertions:

```gdscript
		var node := Area2D.new()
		node.set_script(portal)
		get_root().add_child(node)
		node.configure({"side":"up", "to":"void_deck"}, "破碎甲板", false, [])
		var counts := {"requested":0, "blocked":0}
		node.travel_requested.connect(func(_door): counts["requested"] += 1)
		node.force_player_near_for_test(true)
		node.accept_interaction_for_test()
		node.accept_interaction_for_test()
		_check(counts["requested"] == 1, "interaction emits travel only once until reset")
		node.reset_request()
		node.configure({"side":"up", "to":"void_deck"}, "破碎甲板", false, ["暗影滑翔翼"])
		node.travel_blocked.connect(func(_missing): counts["blocked"] += 1)
		node.force_player_near_for_test(true)
		node.accept_interaction_for_test()
		_check(counts["blocked"] == 1, "missing ability blocks travel")
```

- [ ] **Step 2: Run and verify RED**

Expected failure: missing methods `configure`, `force_player_near_for_test`, or `accept_interaction_for_test`.

- [ ] **Step 3: Implement the runtime API**

Complete `PortalInteraction` with stored `door_data`, `target_name`, `visited`, `missing`, `player_near`, `_request_sent`, a world-space `Label`, body-enter/body-exit callbacks, `_unhandled_input(event)`, and a `focus_changed(focused: bool)` signal used by portal art. Implement these methods:

```gdscript
func configure(data: Dictionary, destination: String, was_visited: bool, missing_names: Array[String]) -> void
func set_missing(missing_names: Array[String]) -> void
func reset_request() -> void
func force_player_near_for_test(value: bool) -> void
func accept_interaction_for_test() -> void
```

`accept_interaction_for_test()` must return when the player is absent or `_request_sent` is true. When `missing` is non-empty it emits `travel_blocked`; otherwise it sets `_request_sent = true`, hides the prompt, and emits `travel_requested(door_data)`. Enter/exit callbacks update the prompt and emit `focus_changed`. `_unhandled_input` must require `Game.menu_open == 0`, call the same method for `interact`, and mark the viewport input handled.

- [ ] **Step 4: Run and verify GREEN**

Expected: `PASS stage 10.9 portal contracts`, exit code `0`.

- [ ] **Step 5: Commit interaction behavior**

```powershell
git add -- tests/test_stage_10_9.gd scripts/portal_interaction.gd
git commit -m "feat(10.9): add guarded portal interaction"
```

### Task 3: Integrate interactive entrances without breaking automatic doors

**Files:**
- Modify: `scripts/main.gd:821-1038`
- Modify: `tests/test_stage_10_9.gd`

- [ ] **Step 1: Add failing integration markers to the contract**

Read `scripts/main.gd` and assert it contains:

```gdscript
const PORTAL_INTERACTION_SCRIPT
PortalInteraction.requires_interaction
travel_requested.connect
travel_blocked.connect
_make_shaft_safety_floor
```

Also load all rooms and assert every hidden door remains pointed at one of the seven existing secret room IDs.

- [ ] **Step 2: Run and verify RED**

Expected: integration markers are missing.

- [ ] **Step 3: Wire interactive areas in `_make_door()`**

Preload `portal_interaction.gd`. After constructing the collision area and visual, branch on `PortalInteraction.requires_interaction(d)`:

```gdscript
if PortalInteraction.requires_interaction(d):
	area.set_script(PORTAL_INTERACTION_SCRIPT)
	var target_name := str(Rooms.ROOMS.get(d["to"], {}).get("name", d["to"]))
	var missing := _missing_required_abilities(d.get("requires", []))
	area.configure(d, target_name, Game.visited.has(d["to"]), missing)
	area.travel_requested.connect(func(_door): _on_door(player, d, tag, locked))
	area.travel_blocked.connect(func(names): _on_portal_blocked(pos, names))
else:
	area.body_entered.connect(func(body): _on_door(body, d, tag, locked))
```

Extract `_missing_required_abilities(required)` and make `_has_required_abilities()` return whether that array is empty, so prompt and transition use one source of truth.

- [ ] **Step 4: Prevent falling through an untriggered down shaft**

Add `_make_shaft_safety_floor(center_x, floor_y, width)` to create a static collision strip across each interactive down opening. Keep the existing visible shaft mouth; `_play_shaft_transition()` already places the player below the floor after interaction, so the cover does not block the cinematic descent.

- [ ] **Step 5: Run contract and room smoke tests**

Run the 10.9 contract, then headless-load `hub`, `depths`, `void_hangar`, and `castle_gallery`. Expected: all exit `0`, no effective `ERROR` / `SCRIPT ERROR`.

- [ ] **Step 6: Commit integration**

```powershell
git add -- tests/test_stage_10_9.gd scripts/main.gd
git commit -m "feat(10.9): require interaction at special entrances"
```

### Task 4: Add layered teleport and hidden-rift visuals

**Files:**
- Create: `scripts/portal_visual.gd`
- Modify: `scripts/main.gd:847-874`
- Modify: `tests/test_stage_10_9.gd`

- [ ] **Step 1: Add failing visual contract markers**

Assert `portal_visual.gd` exists and includes public `setup(hidden: bool, locked: bool, side: String)` and `set_focused(value: bool)` methods. Assert `main.gd` preloads and instantiates it for interactive doors.

- [ ] **Step 2: Run and verify RED**

Expected: missing `portal_visual.gd`.

- [ ] **Step 3: Implement procedural portal art**

Create a Node2D that draws a base, inner energy membrane, two mechanical rings, broken purple runes for hidden entries, and a low-count particle field. `set_focused(true)` raises ring alpha and rotation speed; locked hidden entries retain a visible gap. Use cyan for ordinary teleport arrays and violet for hidden rifts.

- [ ] **Step 4: Replace the single ellipse for interactive entrances**

Keep the existing simple line for automatic side doors. For interactive entrances, add `portal_visual.gd`, call `setup(is_hidden, not missing.is_empty(), d["side"])`, and connect `area.focus_changed` to `visual.set_focused`.

- [ ] **Step 5: Run contract and verify GREEN**

Expected: `PASS stage 10.9 portal contracts`, exit code `0`.

- [ ] **Step 6: Commit visuals**

```powershell
git add -- tests/test_stage_10_9.gd scripts/portal_visual.gd scripts/main.gd
git commit -m "feat(10.9): enhance teleport and hidden-rift visuals"
```

### Task 5: Add deterministic capture hooks and perform visual QA

**Files:**
- Modify: `scripts/main.gd:1345-1442`
- Create: `docs/qa/10.9-review.md`
- Create: `screenshots/10.9/*.png`

- [ ] **Step 1: Add a failing capture-hook contract**

Assert `main.gd` recognizes `SHOT_PORTAL_PROMPT` and can choose `up`, `down`, or `hidden` interactive portals for QA.

- [ ] **Step 2: Run and verify RED**

Expected: `SHOT_PORTAL_PROMPT` marker missing.

- [ ] **Step 3: Implement deterministic prompt capture**

Track interactive portals created for the current room. During `_auto_screenshot()`, select a portal by requested kind, place the player inside its interaction range, and force the prompt visible. Add `SHOT_UNLOCK_ABILITIES=1` support only through existing QA seeding so normal saves are untouched.

- [ ] **Step 4: Capture and inspect actual PNGs**

Use the source-built Godot and unique `SHOT_OUTPUT` paths to capture:

```text
hub/up
hub/hidden locked
hub/hidden unlocked
castle_gallery/down
secret_hub_archive/room result
```

Open every PNG. Correct overlap, unreadable prompt placement, portal/player collision, shaft cover alignment, hidden/normal color confusion, and target-room spawning before continuing.

- [ ] **Step 5: Scan all runtime errors**

For every capture and smoke run, scan all `ERROR` / `SCRIPT ERROR` lines, excluding only the two known exit-noise patterns documented by godot-capture. Expected effective count: `0`.

- [ ] **Step 6: Write QA evidence**

Record exact screenshots, errors, fixes, manual-testing boundary, and asset licensing in `docs/qa/10.9-review.md`. This stage uses only programmatic visuals and existing repository assets, so no new third-party license entry is expected.

### Task 6: Update plan, export, verify release, and commit

**Files:**
- Modify: `docs/DEV_PLAN.md`
- Modify/Create: `docs/qa/10.9-review.md`
- Export: `E:\Godot\release\暗影机械城\ShadowMechCity.exe`
- Export: `E:\Godot\release\暗影机械城\ShadowMechCity.pck`

- [ ] **Step 1: Run full relevant regression**

Run 10.6.5 shaft, 10.8 hidden/completion, 10.9 portal, 12.1 dialogue, and 12.4 cinematic/tutorial contracts. Expected: every test prints `PASS` and exits `0`.

- [ ] **Step 2: Run full project parse and gameplay error scan**

Use the source-built editor in headless editor mode and run the main scene. Expected: no effective `ERROR` / `SCRIPT ERROR`.

- [ ] **Step 3: Update DEV_PLAN**

Add a checked 10.9 entry describing active portal prompts, hidden entrances, shaft safety floor, preserved automatic side doors, QA evidence, and the continued separation of the future equipment UI batch.

- [ ] **Step 4: Export with the source-built Godot**

Export the configured Windows preset into `E:\Godot\release\暗影机械城`, preserving the EXE+PCK format.

- [ ] **Step 5: Verify the published build**

Launch the release EXE for a no-window smoke scan, then use the release EXE itself to capture one portal prompt and one hidden entrance. Inspect both PNGs and confirm their timestamps and PCK SHA-256.

- [ ] **Step 6: Commit only tracked implementation and QA files**

```powershell
git add -- scripts/portal_interaction.gd scripts/portal_visual.gd scripts/main.gd tests/test_stage_10_9.gd docs/qa/10.9-review.md docs/DEV_PLAN.md screenshots/10.9
git commit -m "feat(10.9): add interactive teleport entrances"
```

Do not add or alter the protected untracked paths `assets/decor/mine/`, `docs/godot.code-workspace`, or `策划的提议.docx`.
