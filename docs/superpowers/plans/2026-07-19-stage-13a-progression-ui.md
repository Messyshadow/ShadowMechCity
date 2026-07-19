# Stage 13A Progression UI and Unified Stats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy list-based skill and inventory panels with a navigable circular skill tree and category-based three-column inventory while preserving old saves and making UI and combat consume one unified attribute snapshot.

**Architecture:** Pure helpers own attribute resolution, skill-graph validation/navigation, save migration, and equipment comparison. `Game` remains the persistence authority, `player.gd` consumes the resolved snapshot, and focused Control scripts render skill nodes, previews, character equipment, and item grids without owning gameplay truth.

**Tech Stack:** Godot 4.7 GDScript, Control/Container/SubViewport/AnimatedSprite2D, JSON save migration, headless SceneTree contracts, project `godot-capture` workflow, source-built Windows export template.

---

### Task 1: Establish the 13A contract and unified attribute resolver

**Files:**
- Create: `tests/test_stage_13_a.gd`
- Create: `scripts/stat_resolver.gd`

- [ ] **Step 1: Write the failing resolver contract**

Create `tests/test_stage_13_a.gd` with a pure test that also becomes the shared runner for later tasks:

```gdscript
extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var path := "res://scripts/stat_resolver.gd"
	_check(FileAccess.file_exists(path), "stat resolver must exist")
	if FileAccess.file_exists(path):
		var resolver = load(path)
		var snapshot: Dictionary = resolver.resolve(
			{"attack":10.0, "max_health":5.0, "move_speed":250.0},
			{"attack_flat":2.0, "attack_percent":0.10, "max_health":1.0},
			{"attack_flat":3.0, "move_speed_percent":0.08},
			{"attack_percent":0.20})
		_check(is_equal_approx(snapshot["attack"], 19.5), "flat attack must apply before total percent")
		_check(is_equal_approx(snapshot["max_health"], 6.0), "health modifiers must aggregate")
		_check(is_equal_approx(snapshot["move_speed"], 270.0), "speed percent must resolve from base")
		_check(resolver.resolve({}, {"unknown":3}, {}, {}).get("unknown", 0) == 0, "unknown stats must not leak")
	_finish()

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("PASS stage 13A progression contracts")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)
```

- [ ] **Step 2: Run the contract and verify RED**

Run:

```powershell
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --script tests/test_stage_13_a.gd
```

Expected: exit code `1` with `stat resolver must exist`.

- [ ] **Step 3: Implement the pure resolver**

Create `scripts/stat_resolver.gd`:

```gdscript
class_name StatResolver
extends RefCounted

const DEFAULTS := {
	"attack": 0.0, "max_health": 0.0, "armor": 0.0,
	"crit_chance": 0.0, "crit_damage": 1.5,
	"move_speed": 0.0, "stagger_power": 1.0,
	"skill_damage": 1.0, "cooldown_rate": 1.0,
	"max_mp": 0.0, "mp_regen": 0.0,
}
const FLAT_TO_FINAL := {
	"attack_flat":"attack", "max_health":"max_health", "armor":"armor",
	"crit_chance":"crit_chance", "crit_damage":"crit_damage",
	"stagger_power":"stagger_power", "max_mp":"max_mp", "mp_regen":"mp_regen",
}
const PERCENT_TO_FINAL := {
	"attack_percent":"attack", "move_speed_percent":"move_speed",
	"skill_damage_percent":"skill_damage", "cooldown_reduction":"cooldown_rate",
}

static func resolve(base: Dictionary, skill: Dictionary, gear: Dictionary, temporary: Dictionary) -> Dictionary:
	var out := DEFAULTS.duplicate(true)
	for key in out:
		out[key] = float(base.get(key, out[key]))
	var flats := {}
	var percents := {}
	for source in [skill, gear, temporary]:
		for key in source:
			if FLAT_TO_FINAL.has(key): flats[key] = float(flats.get(key, 0.0)) + float(source[key])
			elif PERCENT_TO_FINAL.has(key): percents[key] = float(percents.get(key, 0.0)) + float(source[key])
	for key in flats:
		var final_key: String = FLAT_TO_FINAL[key]
		out[final_key] = float(out[final_key]) + float(flats[key])
	for key in percents:
		var final_key: String = PERCENT_TO_FINAL[key]
		if key == "cooldown_reduction":
			out[final_key] = maxf(0.25, float(out[final_key]) - float(percents[key]))
		else:
			out[final_key] = float(out[final_key]) * (1.0 + float(percents[key]))
	return out
```

- [ ] **Step 4: Run the contract and verify GREEN**

Expected: `PASS stage 13A progression contracts`, exit code `0`.

- [ ] **Step 5: Commit the resolver**

```powershell
git add -- tests/test_stage_13_a.gd scripts/stat_resolver.gd
git commit -m "feat(13a): add unified attribute resolver"
```

### Task 2: Define and validate the spatial skill graph

**Files:**
- Modify: `scripts/skills_data.gd`
- Create: `scripts/skill_graph.gd`
- Modify: `tests/test_stage_13_a.gd`

- [ ] **Step 1: Add failing graph and navigation assertions**

Append before `_finish()`:

```gdscript
	var data = load("res://scripts/skills_data.gd")
	var graph = load("res://scripts/skill_graph.gd") if FileAccess.file_exists("res://scripts/skill_graph.gd") else null
	_check(graph != null, "skill graph helper must exist")
	if graph:
		var report: Dictionary = graph.validate(data.TREE)
		_check(report.get("errors", []).is_empty(), "skill graph must be structurally valid")
		_check(data.PAGES == ["基础", "身法", "战斗", "探索"], "four progression pages must stay ordered")
		var combat: Array = data.nodes_for("战斗", "刀剑")
		_check(combat.size() >= 5, "sword family needs a usable first tree")
		var root: Dictionary = combat[0]
		var right_id: String = graph.nearest_in_direction(root["id"], Vector2.RIGHT, combat)
		_check(right_id != "", "spatial navigation must find a right-hand node")
		for node in data.TREE:
			for field in ["id", "name", "page", "pos", "type", "usage", "desc", "max", "cost", "req"]:
				_check(node.has(field), "skill node missing field %s: %s" % [field, node.get("id", "?")])
```

- [ ] **Step 2: Run and verify RED**

Expected: missing `skill_graph.gd`, `PAGES`, `nodes_for`, or new node fields.

- [ ] **Step 3: Expand skill data without changing legacy IDs**

Modify `skills_data.gd` so every existing ID (`hp`, `power`, `speed`, `dashcd`, `triple`, `atk`, `crit`, `lifesteal`, `wave`, `spin`, `mp_max`, `mp_regen`, `skill_dmg`, `skill_cd`, `magnet`, `ultimate`) remains present. Add:

```gdscript
const PAGES := ["基础", "身法", "战斗", "探索"]
const FAMILIES := ["刀剑", "铁锤", "蒸汽枪炮", "双刀", "长枪", "弓弩"]

const TREE := [
	{"id":"hp", "name":"生命强化", "page":"基础", "family":"", "pos":Vector2(120,220),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"最大生命 +1",
	 "usage":"自动生效；适合需要更多容错的近战构筑。", "input":"自动生效", "preview":"idle_guard"},
	{"id":"power", "name":"能量强化", "page":"基础", "family":"", "pos":Vector2(300,120),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"技能基础伤害 +1",
	 "usage":"释放任意主动技能时自动计入伤害。", "input":"自动生效", "preview":"skill_cast"},
	{"id":"mp_max", "name":"技力强化", "page":"基础", "family":"", "pos":Vector2(300,300),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"技力上限 +20",
	 "usage":"自动提高蓝色技力槽上限，适合连续释放招式。", "input":"自动生效", "preview":"skill_cast"},
	{"id":"mp_regen", "name":"技力回流", "page":"基础", "family":"", "pos":Vector2(500,320),
	 "type":"被动", "max":3, "cost":1, "req":["mp_max"], "desc":"技力回复 +3/秒",
	 "usage":"战斗与探索中持续生效；技力未满时可见回复。", "input":"自动生效", "preview":"idle_guard"},
	{"id":"skill_dmg", "name":"过载输出", "page":"基础", "family":"", "pos":Vector2(500,100),
	 "type":"被动", "max":3, "cost":1, "req":["power"], "desc":"主动技能伤害 +15%",
	 "usage":"使用 K 方向技或 V 终结技时自动生效。", "input":"K / 方向+K / V", "preview":"skill_cast"},
	{"id":"skill_cd", "name":"招式精通", "page":"基础", "family":"", "pos":Vector2(660,180),
	 "type":"被动", "max":2, "cost":2, "req":["skill_dmg"], "desc":"主动技能冷却 -15%",
	 "usage":"主动技能进入冷却时自动缩短等待时间。", "input":"自动生效", "preview":"skill_cast"},
	{"id":"speed", "name":"疾行", "page":"身法", "family":"", "pos":Vector2(120,220),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"移动速度 +8%",
	 "usage":"地面移动时持续生效，不改变空中惯性。", "input":"A / D", "preview":"run"},
	{"id":"dashcd", "name":"迅捷冲刺", "page":"身法", "family":"", "pos":Vector2(340,120),
	 "type":"被动", "max":3, "cost":1, "req":["speed"], "desc":"冲刺冷却 -0.1秒",
	 "usage":"每次冲刺结束后自动缩短再次冲刺的等待。", "input":"Shift / L", "preview":"dash"},
	{"id":"triple", "name":"三段跳", "page":"身法", "family":"", "pos":Vector2(340,320),
	 "type":"主动能力", "max":1, "cost":2, "req":["speed"], "desc":"额外获得一段空中跳",
	 "usage":"离地后再次按跳跃；新增一段空中跳次数。", "input":"空中 Space", "preview":"jump"},
	{"id":"atk", "name":"近战强化", "page":"战斗", "family":"刀剑", "pos":Vector2(100,220),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"近战伤害 +1",
	 "usage":"装备刀剑并命中时自动生效。", "input":"自动生效", "preview":"attack_1"},
	{"id":"crit", "name":"暴击强化", "page":"战斗", "family":"刀剑", "pos":Vector2(300,80),
	 "type":"被动", "max":3, "cost":1, "req":["atk"], "desc":"暴击率 +12%",
	 "usage":"刀剑攻击命中时自动掷出暴击判定；暴击显示强化闪光。", "input":"自动生效", "preview":"attack_2"},
	{"id":"lifesteal", "name":"吸血攻击", "page":"战斗", "family":"刀剑", "pos":Vector2(300,220),
	 "type":"被动", "max":2, "cost":2, "req":["atk"], "desc":"命中有几率回复生命",
	 "usage":"近战命中敌人时自动判定；满生命时不会浪费视觉提示。", "input":"J / K 命中", "preview":"attack_2"},
	{"id":"wave", "name":"剑气波强化", "page":"战斗", "family":"刀剑", "pos":Vector2(300,360),
	 "type":"被动", "max":3, "cost":1, "req":["atk"], "desc":"斩击波穿透 +1",
	 "usage":"释放地面波时自动增加可穿透目标数量。", "input":"↓ + K", "preview":"skill_wave"},
	{"id":"spin", "name":"旋风斩", "page":"战斗", "family":"刀剑", "pos":Vector2(460,220),
	 "type":"组合", "max":1, "cost":2, "req":["atk"], "desc":"连段终结化为范围旋风斩",
	 "usage":"第三次轻攻击命中前继续按 J；适合被包围时收尾。", "input":"J → J → J", "preview":"spin"},
	{"id":"ultimate", "name":"终极剑技", "page":"战斗", "family":"刀剑", "pos":Vector2(660,220),
	 "type":"终结", "max":1, "cost":3, "req":["spin","crit"], "desc":"满怒气释放刀剑终结技",
	 "usage":"怒气达到 100 后按 V；适合精英破防或 Boss 输出窗口。", "input":"怒气满 → V", "preview":"ultimate"},
	{"id":"magnet", "name":"拾取吸附", "page":"探索", "family":"", "pos":Vector2(100,220),
	 "type":"被动", "max":1, "cost":1, "req":[], "desc":"金币与经验自动吸附",
	 "usage":"靠近掉落物时自动生效，不影响能力门。", "input":"自动生效", "preview":"pickup"},
	{"id":"ability_bomb_root", "name":"爆破共鸣", "page":"探索", "family":"", "pos":Vector2(300,80),
	 "type":"能力根", "max":0, "cost":0, "req":[], "ability_required":"bomb", "desc":"炸弹能力强化入口",
	 "usage":"在熔岩腔穴取得炸弹后开放；13A 仅展示获取状态。", "input":"F", "preview":"bomb"},
	{"id":"ability_wall_root", "name":"壁行共鸣", "page":"探索", "family":"", "pos":Vector2(300,180),
	 "type":"能力根", "max":0, "cost":0, "req":[], "ability_required":"wall_climb", "desc":"攀墙能力强化入口",
	 "usage":"取得攀墙后开放；13A 仅展示获取状态。", "input":"贴墙 W / S", "preview":"climb"},
	{"id":"ability_aqua_root", "name":"深潜共鸣", "page":"探索", "family":"", "pos":Vector2(300,280),
	 "type":"能力根", "max":0, "cost":0, "req":[], "ability_required":"aqua", "desc":"水下推进强化入口",
	 "usage":"取得水下推进器后开放；13A 仅展示获取状态。", "input":"水中 Shift / L", "preview":"swim"},
	{"id":"ability_glider_root", "name":"暗翼共鸣", "page":"探索", "family":"", "pos":Vector2(300,380),
	 "type":"能力根", "max":0, "cost":0, "req":[], "ability_required":"glide", "desc":"滑翔与暗影滑翔强化入口",
	 "usage":"取得滑翔翼后开放；暗影滑翔翼继续兼容旧 glide。", "input":"下落时按住 Space", "preview":"glide"},
	{"id":"family_hammer_root", "name":"铁锤战技", "page":"战斗", "family":"铁锤", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"hammer", "desc":"铁锤专属技能树入口",
	 "usage":"现有铁锤招式保持可用；专属可加点节点在 13B 交付。", "input":"J / 方向+K", "preview":"hammer_attack"},
	{"id":"family_cannon_root", "name":"蒸汽枪炮战技", "page":"战斗", "family":"蒸汽枪炮", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"cannon", "desc":"蒸汽枪炮技能树入口",
	 "usage":"现有蒸汽炮招式保持可用；专属可加点节点在 13B 交付。", "input":"J / 方向+K", "preview":"cannon_attack"},
	{"id":"family_dual_root", "name":"双刀战技", "page":"战斗", "family":"双刀", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"dual_blades", "desc":"双刀装备与技能树入口",
	 "usage":"取得双刀后开放；装备和技能在 13B 同批交付。", "input":"取得武器后显示", "preview":"locked_weapon"},
	{"id":"family_spear_root", "name":"长枪战技", "page":"战斗", "family":"长枪", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"spear", "desc":"长枪装备与技能树入口",
	 "usage":"取得长枪后开放；装备和技能在 13B 同批交付。", "input":"取得武器后显示", "preview":"locked_weapon"},
	{"id":"family_crossbow_root", "name":"弓弩战技", "page":"战斗", "family":"弓弩", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"crossbow", "desc":"弓弩装备与技能树入口",
	 "usage":"取得弓弩后开放；装备和技能在 13B 同批交付。", "input":"取得武器后显示", "preview":"locked_weapon"},
]

static func nodes_for(page: String, family: String = "") -> Array:
	var result: Array = []
	for node in TREE:
		if node["page"] == page and (page != "战斗" or node.get("family", "") == family):
			result.append(node)
	return result

static func modifiers(levels: Dictionary) -> Dictionary:
	return {
		"max_health": float(levels.get("hp", 0)),
		"attack_flat": float(levels.get("atk", 0) + levels.get("power", 0)),
		"crit_chance": 0.12 * float(levels.get("crit", 0)),
		"move_speed_percent": 0.08 * float(levels.get("speed", 0)),
		"max_mp": 20.0 * float(levels.get("mp_max", 0)),
		"mp_regen": 3.0 * float(levels.get("mp_regen", 0)),
		"skill_damage_percent": 0.15 * float(levels.get("skill_dmg", 0)),
		"cooldown_reduction": 0.15 * float(levels.get("skill_cd", 0)),
	}
```

Use the complete `TREE` above. It preserves every legacy ID, provides six authored刀剑 nodes, and represents later weapon families as non-purchasable roots. Do not add another temporary node list.

- [ ] **Step 4: Implement graph validation and four-way navigation**

Create `scripts/skill_graph.gd`:

```gdscript
class_name SkillGraph
extends RefCounted

static func validate(nodes: Array) -> Dictionary:
	var errors: Array[String] = []
	var ids := {}
	for node in nodes:
		var id := str(node.get("id", ""))
		if id == "" or ids.has(id): errors.append("duplicate/empty id: " + id)
		ids[id] = node
	for node in nodes:
		for req in node.get("req", []):
			if not ids.has(str(req)): errors.append("missing prerequisite %s for %s" % [req, node["id"]])
		if int(node.get("max", -1)) < 0: errors.append("negative max: " + str(node["id"]))
	for node in nodes:
		var seen := {str(node["id"]):true}
		var queue: Array = node.get("req", []).duplicate()
		while not queue.is_empty():
			var req := str(queue.pop_front())
			if seen.has(req): errors.append("cycle at " + str(node["id"])); break
			seen[req] = true
			if ids.has(req): queue.append_array(ids[req].get("req", []))
	return {"errors":errors}

static func nearest_in_direction(current_id: String, direction: Vector2, nodes: Array) -> String:
	var current := {}
	for node in nodes:
		if node["id"] == current_id: current = node; break
	if current.is_empty(): return ""
	var best := ""
	var best_score := INF
	for node in nodes:
		if node["id"] == current_id: continue
		var delta: Vector2 = Vector2(node["pos"]) - Vector2(current["pos"])
		if delta.dot(direction) <= 0.0: continue
		var angle_penalty := 1.0 - delta.normalized().dot(direction.normalized())
		var score := angle_penalty * 1000.0 + delta.length()
		if score < best_score: best_score = score; best = str(node["id"])
	return best
```

- [ ] **Step 5: Run the contract and verify GREEN**

Expected: graph errors empty, four pages ordered, spatial navigation returns a node.

- [ ] **Step 6: Commit skill data and graph helpers**

```powershell
git add -- scripts/skills_data.gd scripts/skill_graph.gd tests/test_stage_13_a.gd
git commit -m "feat(13a): define spatial progression graph"
```

### Task 3: Add idempotent save migration and unified Game snapshots

**Files:**
- Create: `scripts/progression_migration.gd`
- Modify: `scripts/game.gd:103-166,187-249`
- Modify: `tests/test_stage_13_a.gd`

- [ ] **Step 1: Add failing migration/snapshot tests**

Add:

```gdscript
	var migration = load("res://scripts/progression_migration.gd") if FileAccess.file_exists("res://scripts/progression_migration.gd") else null
	_check(migration != null, "progression migration must exist")
	if migration:
		var old := {"skills":{"hp":2,"spin":1}, "inventory":[{"slot":"helmet","rarity":1,"lv":2}],
			"equipped":{}, "abilities":{"wall_climb":true}, "unlocked_weapons":["sword","hammer","cannon"]}
		var once: Dictionary = migration.migrate(old)
		var twice: Dictionary = migration.migrate(once)
		_check(once == twice, "save migration must be idempotent")
		_check(once["skills"] == old["skills"], "legacy skill levels must survive")
		_check(once["inventory"].size() == 1 and once["abilities"].has("wall_climb"), "inventory and abilities must survive")
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	for marker in ["save_version", "ProgressionMigration.migrate", "attribute_snapshot", "StatResolver.resolve"]:
		_check(game_source.contains(marker), "Game integration missing: " + marker)
```

- [ ] **Step 2: Run and verify RED**

Expected: migration file and Game markers missing.

- [ ] **Step 3: Implement idempotent migration**

Create `scripts/progression_migration.gd`:

```gdscript
class_name ProgressionMigration
extends RefCounted

const CURRENT_VERSION := 13
const LEGACY_SKILL_IDS := ["hp","power","speed","dashcd","triple","atk","crit","lifesteal",
	"wave","spin","mp_max","mp_regen","skill_dmg","skill_cd","magnet","ultimate"]

static func migrate(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	if int(data.get("save_version", 0)) >= CURRENT_VERSION: return data
	var old_skills = data.get("skills", {})
	var safe_skills := {}
	if old_skills is Dictionary:
		for id in LEGACY_SKILL_IDS:
			if old_skills.has(id): safe_skills[id] = maxi(0, int(old_skills[id]))
		for id in old_skills:
			if not safe_skills.has(id): safe_skills[id] = old_skills[id]
	data["skills"] = safe_skills
	if not (data.get("inventory", []) is Array): data["inventory"] = []
	if not (data.get("equipped", {}) is Dictionary): data["equipped"] = {}
	if not (data.get("abilities", {}) is Dictionary): data["abilities"] = {}
	data["compat_progression"] = data.get("compat_progression", {})
	data["save_version"] = CURRENT_VERSION
	return data
```

- [ ] **Step 4: Integrate migration and snapshots in Game**

Preload both helpers, add `save_version` to `save_game()`, run migration immediately after JSON type validation, and expose:

```gdscript
const StatResolver = preload("res://scripts/stat_resolver.gd")
const ProgressionMigration = preload("res://scripts/progression_migration.gd")

func attribute_snapshot(base: Dictionary, temporary: Dictionary = {}) -> Dictionary:
	return StatResolver.resolve(base, SkillsData.modifiers(skills), ItemsData.equipment_modifiers(equipped), temporary)
```

Change `can_upgrade()` so nodes with `max <= 0`, unmet `weapon_required`, or unmet `ability_required` return false. Do not change the existing point cost and prerequisite behavior.

- [ ] **Step 5: Run 13A and save-related regression tests**

Run 13A, 10.7, 10.8, 12.2 and 12.3. Expected: all exit `0`.

- [ ] **Step 6: Commit migration and snapshots**

```powershell
git add -- scripts/progression_migration.gd scripts/game.gd tests/test_stage_13_a.gd
git commit -m "feat(13a): migrate progression saves safely"
```

### Task 4: Build circular skill nodes, preview, and detail teaching

**Files:**
- Create: `scripts/skill_node_control.gd`
- Create: `scripts/skill_preview.gd`
- Rewrite: `scripts/skill_panel.gd`
- Modify: `tests/test_stage_13_a.gd`

- [ ] **Step 1: Add failing UI surface markers**

Assert that all three scripts compile and that `skill_panel.gd` contains `SubViewportContainer`, `SkillGraph.nearest_in_direction`, `usage`, `input`, four page labels, family switching, and deterministic QA methods `open_for_qa(page, family, node_id)`.

- [ ] **Step 2: Run and verify RED**

Expected: missing node/preview scripts and panel markers.

- [ ] **Step 3: Implement the circular node control**

Create a custom `Control` with `node_data`, `level`, `available`, `selected`, signals `chosen(id)` and `hovered(id)`. Its `_draw()` must draw the dark core, rarity/state ring, selected double ring, level pips, icon glyph, and locked overlay. `_gui_input()` accepts left click/Enter; mouse enter emits `hovered`. Public API:

```gdscript
func setup(data: Dictionary, current_level: int, can_learn: bool) -> void
func set_selected(value: bool) -> void
func refresh(current_level: int, can_learn: bool) -> void
```

Set `custom_minimum_size = Vector2(74,74)`, `mouse_filter = MOUSE_FILTER_STOP`, and an accessible tooltip containing name plus usage.

- [ ] **Step 4: Implement the isolated preview**

Create `skill_preview.gd` as `SubViewportContainer`. It owns a 420×190 transparent SubViewport, a dark mechanical backdrop, an `AnimatedSprite2D` built through `AnimLoader.build_player()`, and a weapon Sprite2D. Public `play_node(node, weapon)` maps `preview` to an existing animation or a short scripted transform; it loops locally, creates no Area2D, consumes no Game resources, and stops processing while hidden.

- [ ] **Step 5: Rewrite the skill panel**

Build a 1180×650 panel for 1280×720 safe area:

- top header with level/SP/coins and four page buttons;
- optional weapon-family row on 战斗;
- left 700×500 graph canvas with Line2D prerequisites and positioned circular nodes;
- right 410×500 preview and detail column;
- bottom controls for `T/Esc`, arrows/WASD, Enter, click.

Handle `ui_left/right/up/down` through `SkillGraph.nearest_in_direction`; mouse hover calls the same `_select_node(id)`. Detail text must render input, usage, prerequisites, resource/cooldown fields when present, and exact before/after level effect. Upgrade uses `Game.upgrade_skill()` and never mutates `Game.skills` directly.

- [ ] **Step 6: Add deterministic UI contract methods**

Implement:

```gdscript
func open_for_qa(page: String, family: String, node_id: String) -> void:
	if not open: _toggle()
	_select_page(page)
	if page == "战斗": _select_family(family)
	_select_node(node_id)
```

- [ ] **Step 7: Run the contract and editor parse**

Expected: 13A passes; `--headless --editor --quit` has no `SCRIPT ERROR`.

- [ ] **Step 8: Commit the skill UI**

```powershell
git add -- scripts/skill_node_control.gd scripts/skill_preview.gd scripts/skill_panel.gd tests/test_stage_13_a.gd
git commit -m "feat(13a): replace list skills with spatial tree"
```

### Task 5: Build item categories, comparison, and three-column inventory

**Files:**
- Modify: `scripts/items_data.gd`
- Create: `scripts/item_compare.gd`
- Create: `scripts/character_equipment_preview.gd`
- Rewrite: `scripts/inventory_panel.gd`
- Modify: `tests/test_stage_13_a.gd`

- [ ] **Step 1: Add failing inventory data/UI assertions**

Assert `ItemsData.CATEGORIES` equals `武器/防具/饰品/消耗品/材料/任务`, `equipment_modifiers()` maps legacy `atk/def/hp/crit/ls/spd`, `ItemCompare.compare()` returns signed deltas, and the panel exposes `open_for_qa(category, index)` plus category sorting and grid navigation markers.

- [ ] **Step 2: Run and verify RED**

Expected: missing category, comparison, preview, and panel APIs.

- [ ] **Step 3: Extend ItemsData compatibly**

Add:

```gdscript
const CATEGORIES := ["武器", "防具", "饰品", "消耗品", "材料", "任务"]

static func category(item: Dictionary) -> String:
	if item.get("kind", "") == "weapon": return "武器"
	if item.get("kind", "") == "consumable": return "消耗品"
	if item.get("kind", "") == "material": return "材料"
	if item.get("kind", "") == "quest": return "任务"
	return "饰品" if str(item.get("slot", "")) in ["amulet", "ring"] else "防具"

static func equipment_modifiers(equipped: Dictionary) -> Dictionary:
	var out := {"attack_flat":0.0,"armor":0.0,"max_health":0.0,"crit_chance":0.0,"move_speed_percent":0.0}
	for slot in equipped:
		var item: Dictionary = equipped[slot]
		out["attack_flat"] += value(item, "atk")
		out["armor"] += value(item, "def")
		out["max_health"] += value(item, "hp")
		out["crit_chance"] += value(item, "crit")
		out["move_speed_percent"] += value(item, "spd")
	return out
```

Keep all legacy keys and generation behavior.

- [ ] **Step 4: Implement pure item comparison**

`item_compare.gd` exposes `compare(candidate, current)` and returns rows `{key,label,current,candidate,delta,tone}` for `atk/def/hp/crit/ls/spd`. Missing values resolve to zero; `tone` is `gain`, `loss`, or `neutral`.

- [ ] **Step 5: Implement live character/equipment preview**

Create a SubViewport-based preview using `AnimLoader.build_player()` and the actual current weapon sprite from `Weapons.LIST[Game.weapon_index]`. Draw equipment slots around it as focused buttons. Armor without a dedicated sprite changes a restrained tint accent and slot icon only; it must not claim a false full costume swap.

- [ ] **Step 6: Rewrite the inventory panel**

Build a 1200×650 panel:

- header with categories, sort selector, coins and capacity;
- left 330px character preview and six existing equipment slots plus current weapon display;
- middle 480px scrollable 5-column square item grid with icon/glyph, rarity frame, `+level`, count and new badge;
- right 340px details, source, affixes, comparison rows, equip/unequip/enhance actions;
- bottom input hints and reserved four-slot consumable bar.

Use a stable filtered array of `{source_index,item}` so sorting never equips the wrong original index. Preserve `Game.equip_item(source_index)`. Empty categories render an authored empty-state message. `open_for_qa(category,index)` selects deterministically.

- [ ] **Step 7: Run 13A and editor parse**

Expected: pure comparisons pass, all new scripts instantiate, no script errors.

- [ ] **Step 8: Commit the inventory UI**

```powershell
git add -- scripts/items_data.gd scripts/item_compare.gd scripts/character_equipment_preview.gd scripts/inventory_panel.gd tests/test_stage_13_a.gd
git commit -m "feat(13a): rebuild inventory and equipment interface"
```

### Task 6: Make player combat consume the unified snapshot

**Files:**
- Modify: `scripts/player.gd:153-181,480-520`
- Modify: `tests/test_stage_13_a.gd`

- [ ] **Step 1: Add failing compatibility assertions**

Assert `player.gd` defines `_base_attributes()` and `_attributes()`, calls `Game.attribute_snapshot`, and no longer calls `Game.equip_bonus()` inside `max_hp`, `_run_speed`, `max_mp`, or `_skill_dmg`. Add pure expectations reproducing legacy values for hp, attack, speed, crit, max MP and cooldown.

- [ ] **Step 2: Run and verify RED**

Expected: snapshot helpers missing and direct bonus calls remain.

- [ ] **Step 3: Route player calculations through the snapshot**

Add:

```gdscript
func _base_attributes() -> Dictionary:
	return {"attack":float(weapon["damage"]), "max_health":float(MAX_HEALTH + Game.heart_pieces),
		"armor":0.0, "crit_chance":0.0, "crit_damage":1.5, "move_speed":RUN_SPEED,
		"stagger_power":1.0, "skill_damage":1.0, "cooldown_rate":1.0,
		"max_mp":MAX_MP, "mp_regen":MP_REGEN}

func _attributes() -> Dictionary:
	return Game.attribute_snapshot(_base_attributes())
```

Then derive health, movement, MP, active-skill damage and cooldown from this snapshot. Preserve heart pieces, weapon base damage, legacy skill levels and equipment stats. Clamp health/MP when equipment or skills change and emit both health/resource signals.

- [ ] **Step 4: Run 13A plus gameplay regressions**

Run all tests in `tests/`. Expected: every test exits `0`; no legacy combat contract changes.

- [ ] **Step 5: Commit player integration**

```powershell
git add -- scripts/player.gd tests/test_stage_13_a.gd
git commit -m "refactor(13a): resolve player stats from one snapshot"
```

### Task 7: Add deterministic capture hooks and perform visual QA

**Files:**
- Modify: `scripts/main.gd:1390-1496`
- Create: `docs/qa/13A-review.md`
- Generate locally: `screenshots/13A/*.png`

- [ ] **Step 1: Add failing capture-hook markers**

The 13A test must require `SHOT_SKILL_TREE`, `SHOT_SKILL_PAGE`, `SHOT_SKILL_FAMILY`, `SHOT_SKILL_NODE`, `SHOT_INVENTORY_CATEGORY`, and `SHOT_INVENTORY_INDEX` in `main.gd`.

- [ ] **Step 2: Run and verify RED**

Expected: deterministic 13A hooks absent.

- [ ] **Step 3: Implement QA seeding and panel selection**

During `--shot` only, seed skill points and representative equipment without saving, call `skill_panel.open_for_qa(...)` or `inv_panel.open_for_qa(...)`, and wait two rendered frames before capture. Normal startup and saves must not read these environment variables.

- [ ] **Step 4: Capture actual PNGs with the source-built Godot**

Capture at 1280×720:

```text
screenshots/13A/skill-basic-passive.png
screenshots/13A/skill-mobility.png
screenshots/13A/skill-sword-combo.png
screenshots/13A/skill-exploration-locked.png
screenshots/13A/inventory-armor-compare.png
screenshots/13A/inventory-accessory.png
screenshots/13A/inventory-empty-category.png
```

Use unique `SHOT_OUTPUT` values and `--shot`; scan every run for all `ERROR` and `SCRIPT ERROR` lines.

- [ ] **Step 5: Open and inspect every PNG**

Reject and fix: clipped 720p controls, unreadable text, graph lines crossing labels, selected node not obvious, preview covering details, keyboard focus differing from mouse selection, inventory item/equipment mismatch, comparison colors without signed values, empty-state layout collapse, or HUD bleeding over modal UI.

- [ ] **Step 6: Write QA evidence**

Create `docs/qa/13A-review.md` with exact commands/results, every screenshot name and visual finding, migration evidence, asset/license statement, and the honest boundary that static captures cannot prove input feel or long-term balance.

- [ ] **Step 7: Commit QA-ready integration**

```powershell
git add -- scripts/main.gd tests/test_stage_13_a.gd docs/qa/13A-review.md docs/DEV_PLAN.md
git commit -m "feat(13a): add progression UI capture coverage"
```

### Task 8: Final regression, documentation, release, and published-build proof

**Files:**
- Modify: `docs/DEV_PLAN.md`
- Modify: `docs/qa/13A-review.md`
- Export: `E:\Godot\release\暗影机械城\ShadowMechCity.exe`
- Export: `E:\Godot\release\暗影机械城\ShadowMechCity.pck`

- [ ] **Step 1: Run the complete contract suite fresh**

Run every `tests/*.gd` with the source console executable. Expected: all exit `0`, including 13A.

- [ ] **Step 2: Run the full project parser**

```powershell
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --editor --path . --quit
```

Expected: exit code `0`, no effective `ERROR` / `SCRIPT ERROR`.

- [ ] **Step 3: Update DEV_PLAN**

Insert checked `13A` before existing 13.1 and state exactly what shipped. Keep 13B–13D unchecked; do not mark new weapons, enemies or hit-feel work complete during 13A.

- [ ] **Step 4: Export with the source-built release template**

```powershell
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --export-release 'Windows Desktop' 'E:\Godot\release\暗影机械城\ShadowMechCity.exe'
```

Expected: exit code `0`, both EXE and PCK timestamps refreshed.

- [ ] **Step 5: Prove the published PCK contains 13A**

Run `ShadowMechCity.exe --shot` with `SHOT_SKILL_TREE=1` and a release-only `SHOT_OUTPUT`, then with inventory selection. Open both PNGs, scan output for all errors, and record EXE/PCK size, timestamp and SHA-256 in the QA report.

- [ ] **Step 6: Commit release evidence**

```powershell
git add -- docs/DEV_PLAN.md docs/qa/13A-review.md
git commit -m "docs(qa): record stage 13A release verification"
```

- [ ] **Step 7: Audit protected files and final status**

Verify `assets/decor/mine/`, `docs/godot.code-workspace`, and `策划的提议.docx` remain present and unmodified/untracked. Do not add unrelated historical logs or `.superpowers/` session output.
