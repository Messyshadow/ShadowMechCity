# Stage 12.1 Dialogue and Hub NPCs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a data-driven dialogue runtime and five visually distinct, interactive NPCs in the central hub, with persistent story flags and extension points for stage 12.2 quests.

**Architecture:** Keep NPC definitions and dialogue graphs in focused data files, run conversations through a UI-independent state machine, and let `main.gd` only instantiate actors and coordinate input lock/camera state. Persist dialogue/story flags in `Game`, while quest events remain protocol-only until stage 12.2.

**Tech Stack:** Godot 4.7 custom source build, GDScript, programmatic 2D nodes/UI, SceneTree contract tests, project `godot-capture` PNG QA.

---

### Task 1: Add the failing stage 12.1 contract test

**Files:**
- Create: `tests/test_stage_12_1.gd`
- Read: `scripts/rooms.gd`
- Read: `scripts/game.gd`
- Read: `scripts/main.gd`

- [ ] **Step 1: Write the failing contract test**

Create a SceneTree test that loads source text and, when available, the dialogue resources. It must require the exact NPC IDs `smith`, `alchemist`, `cartographer`, `collector`, `bounty`; one hub placement per ID; initial/repeat/conditional dialogue routes; valid graph targets; persistence markers; input lock; and capture hooks.

```gdscript
extends SceneTree

const EXPECTED_NPCS := ["smith", "alchemist", "cartographer", "collector", "bounty"]
var failures: Array[String] = []

func _init() -> void:
	var rooms_source := FileAccess.get_file_as_string("res://scripts/rooms.gd")
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for id in EXPECTED_NPCS:
		_check(rooms_source.count('"%s"' % id) >= 1, "hub must place NPC " + id)
	_check(game_source.contains("dialogue_flags"), "dialogue flags must persist")
	_check(game_source.contains("story_flags"), "story flags must persist")
	_check(main_source.contains("SHOT_DIALOGUE"), "capture hook must open dialogue")
	if ResourceLoader.exists("res://scripts/npc_data.gd") and ResourceLoader.exists("res://scripts/dialogue_data.gd"):
		_validate_data(load("res://scripts/npc_data.gd"), load("res://scripts/dialogue_data.gd"))
	if failures.is_empty():
		print("PASS stage 12.1 dialogue and hub NPC contracts")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
```

- [ ] **Step 2: Run the test and confirm RED**

Run:

```powershell
$env:APPDATA=(Resolve-Path '.').Path
$env:LOCALAPPDATA=$env:APPDATA
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . -s res://tests/test_stage_12_1.gd
```

Expected: exit code 1 with missing NPC/data/persistence/capture contract failures.

### Task 2: Implement focused NPC and dialogue data

**Files:**
- Create: `scripts/npc_data.gd`
- Create: `scripts/dialogue_data.gd`
- Create: `scripts/dialogue_runner.gd`
- Modify: `tests/test_stage_12_1.gd`

- [ ] **Step 1: Define the five NPC records**

Use a `RefCounted` class with immutable dictionaries. Every record exposes name, role, accent, emblem, size, and dialogue route.

```gdscript
class_name NpcData
extends RefCounted

const NPCS := {
	"smith": {"name":"炉心铸造师·格里夫", "role":"炉心铸造师", "accent":Color("e77b3c"), "emblem":"hammer", "route":"smith"},
	"alchemist": {"name":"雾酿术士·塞芙拉", "role":"雾酿术士", "accent":Color("55d6b0"), "emblem":"flask", "route":"alchemist"},
	"cartographer": {"name":"轨图解析师·弥娅", "role":"轨图解析师", "accent":Color("62ccef"), "emblem":"map", "route":"cartographer"},
	"collector": {"name":"遗物收藏家·奥德里克", "role":"遗物收藏家", "accent":Color("aa78ed"), "emblem":"memory", "route":"collector"},
	"bounty": {"name":"鸦眼赏金追踪者·罗克", "role":"赏金追踪者", "accent":Color("e55353"), "emblem":"target", "route":"bounty"},
}
```

- [ ] **Step 2: Define complete dialogue routes**

Each route contains ordered entry candidates and nodes. Candidates are highest-priority first and include a first-meet, at least one progressed state, and repeat fallback.

```gdscript
class_name DialogueData
extends RefCounted

const ROUTES := {
	"smith": {
		"entries": [
			{"node":"smith_arsenal", "conditions":{"weapon_count_gte":5}},
			{"node":"smith_first", "conditions":{"flag_missing":"met_smith"}},
			{"node":"smith_repeat", "conditions":{}},
		],
		"nodes": {
			"smith_first":{"text":"这座城的主炉熄了，但你的武器还肯呼吸。", "next":"smith_link", "events":["set:met_smith"]},
			"smith_link":{"text":"等轨道储能链恢复，我能让钢铁从天空获得新的形态。", "next":"", "events":["set:foreshadow_quantum_upgrade"]},
			"smith_arsenal":{"text":"五种兵器都认得你了。接下来该让它们形成自己的技艺枝干。", "next":"", "events":[]},
			"smith_repeat":{"text":"别让漂亮的火花骗你，真正的好武器先要可靠。", "next":"", "events":[]},
		}
	},
}
```

Implement the remaining route content exactly as follows (the runner selects the first matching entry):

| Route | Entry priority | Nodes and exact content |
|---|---|---|
| `smith` | `weapon_count_gte:5 -> smith_arsenal`; `flag_missing:met_smith -> smith_first`; fallback `smith_repeat` | Use the four nodes shown above. |
| `alchemist` | `memory_count_gte:4 -> alchemist_memory`; `flag_missing:met_alchemist -> alchemist_first`; fallback `alchemist_repeat` | `alchemist_first`: “别碰那团紫雾。虚空不是魔法，它会改写机械与血肉遵守的规则。” → `alchemist_warning`, event `set:met_alchemist`; `alchemist_warning`: “如果你带回会发光的记忆核心，先让我检查污染层。” → end; `alchemist_memory`: “这些核心没有继续扩散，说明有人在毁灭前主动封住了自己的记忆。” → end; `alchemist_repeat`: “药雾变甜时最危险，那代表过滤器已经开始撒谎。” → end. |
| `cartographer` | `hidden_count_gte:1 -> cartographer_secret`; `visited_count_gte:20 -> cartographer_network`; `flag_missing:met_cartographer -> cartographer_first`; fallback `cartographer_repeat` | `cartographer_first`: “旧轨图被切成了七块。你每走过一间房，车站就能记起一段线路。” → `cartographer_map`, event `set:met_cartographer`; `cartographer_map`: “按 M 查看世界地图，紫色菱形只会标记你亲自发现的秘室。” → end; `cartographer_secret`: “你已经找到轨图之外的空间。秘室不是漏画的，它们曾被人故意删除。” → end; `cartographer_network`: “主干线路大半恢复了。剩下的空白多半藏在能力门和回程支线后。” → end; `cartographer_repeat`: “地图不会替你探索，但会提醒你哪里仍在沉默。” → end. |
| `collector` | `memory_count_gte:3 -> collector_archive`; `flag_missing:met_collector -> collector_first`; fallback `collector_repeat` | `collector_first`: “记忆核心保存的不是影像，而是机器临终前最后一次感知。” → `collector_space`, event `set:met_collector`; `collector_space`: “旧档案还提到一层能容纳机械意识的封闭空间，可惜入口协议已经失传。” → end, event `set:foreshadow_quantum_space`; `collector_archive`: “三枚核心互相校验后，指向同一句警告：王城的影子并不属于王。” → end; `collector_repeat`: “别急着给遗物命名。名字有时比锈蚀更会掩盖真相。” → end. |
| `bounty` | `boss_count_gte:3 -> bounty_veteran`; `flag_missing:met_bounty -> bounty_first`; fallback `bounty_repeat` | `bounty_first`: “机械城的领主、巨兽和失控机甲，都在我的猎杀名单上。” → `bounty_choice`, event `set:met_bounty`; `bounty_choice`: “你想先听哪类情报？” with choices `区域领主 -> bounty_lords` and `加密悬赏 -> bounty_cipher`; `bounty_lords`: “领主会把最安全的动作重复给你看。活下来，等它第一次打破自己的节奏。” → end; `bounty_cipher`: “有个破解者把遗产藏进了铸造厂网络。等悬赏终端修好，我会把坐标交给你。” → end, event `set:foreshadow_hacker_legacy`; `bounty_veteran`: “三个领主已经沉默。现在名单开始害怕你的名字了。” → end; `bounty_repeat`: “情报只负责让你多活一秒，剩下的要靠手里的武器。” → end. |

Every node explicitly stores `events: []` when it has no event, `next: ""` when it ends, and `choices: []` unless it is `bounty_choice`. This makes graph validation deterministic and leaves no implicit fields.

- [ ] **Step 3: Implement the pure dialogue runner**

```gdscript
class_name DialogueRunner
extends RefCounted

var route: Dictionary = {}
var node_id := ""

func begin(route_id: String, snapshot: Dictionary, flags: Dictionary) -> Dictionary:
	route = DialogueData.ROUTES.get(route_id, {})
	for candidate in route.get("entries", []):
		if _conditions_match(candidate.get("conditions", {}), snapshot, flags):
			node_id = candidate["node"]
			return current()
	return _missing_node(route_id)

func current() -> Dictionary:
	return route.get("nodes", {}).get(node_id, _missing_node(node_id))

func advance(choice_index := -1) -> Dictionary:
	var node := current()
	var target: String = node.get("next", "")
	if choice_index >= 0 and choice_index < node.get("choices", []).size():
		target = node["choices"][choice_index].get("to", "")
	node_id = target
	return {} if target == "" else current()
```

Conditions explicitly support counts and flag presence/missing. Events only accept `set:<flag>` in 12.1; unknown/quest events are returned to the caller without executing rewards.

- [ ] **Step 4: Expand and run the data tests**

The test iterates every entry, `next`, and choice target and asserts they exist. It builds low/high snapshots and confirms route selection. Run the stage 12.1 test; expected: data/runner assertions pass while integration contracts remain RED.

### Task 3: Persist dialogue/story flags and expose a narrative snapshot

**Files:**
- Modify: `scripts/game.gd`
- Modify: `tests/test_stage_12_1.gd`

- [ ] **Step 1: Add persistence state and signals**

```gdscript
signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
var dialogue_flags: Dictionary = {}
var story_flags: Dictionary = {}

func set_story_flag(id: String) -> void:
	if id != "": story_flags[id] = true

func narrative_snapshot() -> Dictionary:
	var completion := completion_snapshot()
	return {
		"visited_count": visited.size(),
		"hidden_count": int(completion.get("hidden", {}).get("done", 0)),
		"boss_count": _boss_defeat_count(),
		"memory_count": _memory_count(),
		"weapon_count": unlocked_weapons.size(),
	}
```

Count bosses from `items` keys beginning `boss_` and memories from collected IDs beginning `memory_`.

- [ ] **Step 2: Add save/load/reset migration**

Write both dictionaries in `save_game`. On load, accept only dictionaries and otherwise migrate to `{}`. Clear them in `reset`.

```gdscript
dialogue_flags = data.get("dialogue_flags", {}) if data.get("dialogue_flags", {}) is Dictionary else {}
story_flags = data.get("story_flags", {}) if data.get("story_flags", {}) is Dictionary else {}
```

- [ ] **Step 3: Run stage 12.1 and existing 10.8 tests**

Expected: persistence contracts pass; no regression in completion tracking.

### Task 4: Add hub placement and interactive NPC actors

**Files:**
- Modify: `scripts/rooms.gd`
- Create: `scripts/npc_actor.gd`
- Modify: `scripts/main.gd`
- Modify: `scripts/player.gd`
- Modify: `tests/test_stage_12_1.gd`

- [ ] **Step 1: Place all five NPCs in the hub**

Add a single `npcs` array to `hub`, keeping doors and save point unobstructed:

```gdscript
"npcs": [
	[330, 510, "cartographer"],
	[610, 510, "smith"],
	[790, 510, "alchemist"],
	[1030, 510, "collector"],
	[1190, 510, "bounty"],
],
```

Final coordinates may move after PNG review, but IDs remain unique.

- [ ] **Step 2: Build the NPC actor**

`npc_actor.gd` extends `Node2D`, has `signal interaction_requested(npc_id)`, a 74×110 interaction Area2D, a body silhouette assembled from Polygon2D/Line2D/Sprite2D, and a world-space prompt. Use emblem-specific geometry and props so silhouettes differ.

```gdscript
func setup(id: String) -> void:
	npc_id = id
	data = NpcData.NPCS[id]
	_build_workstation()
	_build_character()
	_build_interaction_area()

func _unhandled_input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("interact") and Game.menu_open == 0:
		interaction_requested.emit(npc_id)
		get_viewport().set_input_as_handled()
```

- [ ] **Step 3: Instantiate actors from room data**

Add `_spawn_npc` to `main.gd` and call it for `room.get("npcs", [])` before doors. Connect `interaction_requested` to `_start_dialogue`.

- [ ] **Step 4: Add a player input lock**

Add `var input_locked := false` to `player.gd`. At the top of `_physics_process`, when locked, decelerate horizontal movement, apply normal floor gravity, call `move_and_slide`, and return before reading combat/movement input. Death handling remains active.

- [ ] **Step 5: Run the contract and editor parse**

Expected: NPC placement/actor/input-lock contracts pass and `--headless --editor --quit` reports no SCRIPT ERROR.

### Task 5: Build the dialogue panel and main-scene coordination

**Files:**
- Create: `scripts/dialogue_panel.gd`
- Modify: `scripts/main.gd`
- Modify: `scripts/game.gd`
- Modify: `project.godot`
- Modify: `tests/test_stage_12_1.gd`

- [ ] **Step 1: Register the interact input**

Add `"interact": [KEY_E, KEY_ENTER]` to `Game.ACTIONS`. The panel uses built-in `ui_accept`, `ui_cancel`, `ui_up`, and `ui_down` after the opening input is released.

- [ ] **Step 2: Build the commercial-style panel**

The `CanvasLayer` constructs a bottom anchored panel with dark steel StyleBoxFlat, rivet corners, emblem portrait, name/role labels, RichTextLabel body, page indicator, next glyph, and optional choice VBox. Expose:

```gdscript
signal conversation_closed
func open_conversation(npc_id: String, snapshot: Dictionary, flags: Dictionary) -> void
func close_conversation() -> void
func show_node(node: Dictionary) -> void
```

The typewriter can be completed instantly with one accept; the next accept advances. Choices wrap vertically and use a circular accent outline for the selected row.

- [ ] **Step 3: Coordinate dialogue in `main.gd`**

Create one panel during `_ready`. `_start_dialogue` locks player input, increments `Game.menu_open`, emits the start signal, opens the route, and tweens the camera offset toward the player/NPC midpoint. Closing always decrements the menu count safely, releases input, clears active NPC, emits end, and restores camera offset.

```gdscript
func _start_dialogue(npc_id: String, actor: Node2D) -> void:
	if _active_npc != "" or Game.menu_open > 0: return
	_active_npc = npc_id
	player.input_locked = true
	Game.menu_open += 1
	dialogue_panel.open_conversation(npc_id, Game.narrative_snapshot(), Game.dialogue_flags)
```

- [ ] **Step 4: Apply allowed runner events**

When a node is shown or completed, parse only `set:` events into `Game.dialogue_flags`/`story_flags`. Save after conversation close if flags changed. Keep quest events as inert returned strings for 12.2.

- [ ] **Step 5: Verify GREEN and regressions**

Run editor parse plus tests 10.6.5, 10.7, 10.8, and 12.1. Expected: all PASS, no ERROR/SCRIPT ERROR.

### Task 6: Add deterministic capture hooks and perform visual QA

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/npc_actor.gd`
- Modify: `scripts/dialogue_panel.gd`
- Create: `screenshots/12.1/*.png` (ignored QA output)

- [ ] **Step 1: Add shot options**

Extend `_auto_screenshot` with:

```gdscript
var shot_dialogue := _qa_option("SHOT_DIALOGUE")
if shot_dialogue != "":
	var actor := _npc_actors.get(shot_dialogue)
	if is_instance_valid(actor): _start_dialogue(shot_dialogue, actor)
if _qa_option("SHOT_DIALOGUE_PROGRESS") == "1":
	_seed_dialogue_progress_for_qa()
```

Support `SHOT_DIALOGUE_CHOICE=1` to open a deterministic two-choice node. QA seeding is only reachable in `--shot` flow and does not save.

- [ ] **Step 2: Read and follow godot-capture skill**

Read `.claude/skills/godot-capture/SKILL.md` completely, run the custom source-built Godot with isolated APPDATA/LOCALAPPDATA, and capture hub lineup, first meet, choice, and progressed dialogue.

- [ ] **Step 3: View every PNG and fix issues**

Use actual image viewing. Check NPC differentiation, player/NPC overlap, door and save access, prompt readability, panel safe area, Chinese font clipping, choice highlight, and background contrast. Apply focused corrections, recapture, and re-view until acceptable.

- [ ] **Step 4: Scan runtime output**

Run each shot with output captured and search case-insensitively for `ERROR`, `SCRIPT ERROR`, invalid resource, and missing node. Record any permitted screenshot-exit ObjectDB/resource noise separately.

### Task 7: Document, commit, export, and verify the published build

**Files:**
- Create: `docs/qa/12.1-review.md`
- Modify: `docs/DEV_PLAN.md`
- Modify: `ATTRIBUTION.md` only if new third-party assets are added

- [ ] **Step 1: Write the QA report**

Record delivered scope, exact test commands/results, every viewed PNG and resulting fixes, collision/access findings, asset provenance, remaining manual-play boundary, and release verification.

- [ ] **Step 2: Update DEV_PLAN**

Mark only 12.1 complete. Add a note that stage 11 is deliberately deferred and preserved in `future_systems.md`. Keep 12.2–12.4 unchecked. Record the deferred skill-tree redesign without marking it implemented.

- [ ] **Step 3: Run final verification**

Freshly run full editor parse and 10.6.5/10.7/10.8/12.1 tests. Require exit code 0 and scan all output for errors.

- [ ] **Step 4: Commit only scoped files**

Explicitly stage the 12.1 code, tests, DEV_PLAN, QA report, and any documented assets. Exclude `.superpowers/`, `Godot/`, logs, `assets/decor/mine/`, `docs/godot.code-workspace`, and `策划的提议.docx`.

```powershell
git commit -m "feat(12.1): add hub NPCs and dialogue system"
```

- [ ] **Step 5: Export with source-built Godot**

Use `E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe` and the configured source-built release template to export `E:\Godot\release\暗影机械城\ShadowMechCity.exe` plus PCK.

- [ ] **Step 6: Verify the release itself**

Launch the published EXE headlessly for an error scan, then launch it with `SHOT_ROOM=hub`, `SHOT_DIALOGUE=cartographer`, and a workspace `SHOT_OUTPUT`. View the published PNG, verify timestamps/sizes/hashes, and append this evidence to `docs/qa/12.1-review.md` in a small follow-up QA commit if necessary.
