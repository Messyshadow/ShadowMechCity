extends Node2D
## 主场景: 银河城房间世界 - 房间互联/四向穿门/存档点/锁门 + 暗黑机械氛围

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const ENEMY_COMBAT_DIRECTOR := preload("res://scripts/enemy_combat_director.gd")
const THEME_BACKDROP_SCRIPT := preload("res://scripts/theme_backdrop.gd")
const DOWNWARD_PORTAL_VISUAL := preload("res://scripts/downward_portal_visual.gd")
const SHAFT_TRANSITION_SCRIPT := preload("res://scripts/shaft_transition.gd")
const PORTAL_INTERACTION_SCRIPT := preload("res://scripts/portal_interaction.gd")
const PORTAL_VISUAL_SCRIPT := preload("res://scripts/portal_visual.gd")
const NPC_ACTOR_SCRIPT := preload("res://scripts/npc_actor.gd")
const DIALOGUE_PANEL_SCRIPT := preload("res://scripts/dialogue_panel.gd")
const QUEST_PANEL_SCRIPT := preload("res://scripts/quest_panel.gd")
const QUEST_TRACKER_SCRIPT := preload("res://scripts/quest_tracker.gd")
const CINEMATIC_DATA := preload("res://scripts/cinematic_data.gd")
const CINEMATIC_PANEL_SCRIPT := preload("res://scripts/cinematic_panel.gd")
const TUTORIAL_GUIDE_SCRIPT := preload("res://scripts/tutorial_guide.gd")
const DASH_GATE_SCRIPT := preload("res://scripts/dash_gate.gd")
const BOSS_RETREAT_CONSOLE := preload("res://scripts/boss_retreat_console.gd")
const SKILL_INTERACTABLE_SCRIPT := preload("res://scripts/skill_interactable.gd")

const ENEMY_DEFS := {
	"mushroom": {"frames": 8, "fps": 6.7, "scale": 0.55, "hp": 4, "speed": 58.0, "size": Vector2(54, 50), "tint": Color(1, 1, 1), "behavior": "walker", "dmg": 1, "kbr": 0.0},
	"furry": {"frames": 8, "fps": 4.2, "scale": 0.5, "hp": 6, "speed": 42.0, "size": Vector2(50, 56), "tint": Color(0.8, 0.95, 1.0), "behavior": "walker", "dmg": 1, "kbr": 0.0},
	"jelly": {"frames": 6, "fps": 6.7, "scale": 0.62, "hp": 3, "speed": 78.0, "size": Vector2(54, 42), "tint": Color(1, 1, 1), "behavior": "flyer", "dmg": 1, "kbr": 0.0},
	"beast": {"frames": 6, "fps": 5.0, "scale": 0.62, "hp": 5, "speed": 62.0, "size": Vector2(52, 62), "tint": Color(1, 1, 1), "behavior": "charger", "dmg": 2, "kbr": 0.1},
	"lion": {"frames": 4, "fps": 3.3, "scale": 0.78, "hp": 14, "speed": 34.0, "size": Vector2(96, 100), "tint": Color(1, 1, 1), "behavior": "walker", "dmg": 2, "kbr": 0.6},
	"bird": {"frames": 7, "fps": 8.3, "scale": 0.58, "hp": 5, "speed": 52.0, "size": Vector2(56, 54), "tint": Color(1, 1, 1), "behavior": "walker", "dmg": 1, "kbr": 0.1},
	"slime": {"frames": 6, "fps": 6.7, "scale": 0.6, "hp": 5, "speed": 64.0, "size": Vector2(54, 56), "tint": Color(1, 1, 1), "behavior": "charger", "dmg": 2, "kbr": 0.1},
	"bat": {"frames": 4, "fps": 7.7, "scale": 0.68, "hp": 4, "speed": 78.0, "size": Vector2(50, 52), "tint": Color(1, 1, 1), "behavior": "charger", "dmg": 1, "kbr": 0.0},
	"golem": {"frames": 6, "fps": 10.0, "scale": 1.0, "hp": 30, "speed": 40.0, "size": Vector2(96, 108), "tint": Color(1, 1, 1), "behavior": "charger", "dmg": 3, "kbr": 0.8},
	"mage": {"sprite": "bird", "frames": 7, "fps": 8.3, "scale": 0.6, "hp": 6, "speed": 36.0, "size": Vector2(56, 56), "tint": Color(0.7, 1.0, 0.7), "behavior": "shooter", "dmg": 1, "kbr": 0.1},
	# 蒸汽铸造厂专属敌种(阶段10.1)
	"mech_soldier": {"sprite": "beast", "frames": 6, "fps": 5.0, "scale": 0.66, "hp": 11, "speed": 66.0, "size": Vector2(54, 64), "tint": Color(0.62, 0.72, 0.85), "behavior": "charger", "dmg": 2, "kbr": 0.25},
	"ghost_spider": {"sprite": "bat", "frames": 4, "fps": 8.5, "scale": 0.7, "hp": 7, "speed": 74.0, "size": Vector2(52, 52), "tint": Color(0.8, 0.7, 1.0), "behavior": "flyer", "dmg": 1, "kbr": 0.0},
	"drone": {"sprite": "jelly", "frames": 6, "fps": 7.5, "scale": 0.6, "hp": 6, "speed": 92.0, "size": Vector2(54, 44), "tint": Color(0.6, 1.0, 1.0), "behavior": "flyer", "dmg": 1, "kbr": 0.1},
	"steam_brute": {"sprite": "golem", "frames": 6, "fps": 9.0, "scale": 1.05, "hp": 44, "speed": 48.0, "size": Vector2(100, 112), "tint": Color(1.0, 0.7, 0.45), "behavior": "charger", "dmg": 3, "kbr": 0.75},
	# 腐化水道专属敌种(阶段10.2)
	"fishman": {"sprite": "beast", "frames": 6, "fps": 5.5, "scale": 0.66, "hp": 10, "speed": 60.0, "size": Vector2(54, 64), "tint": Color(0.5, 0.85, 0.8), "behavior": "charger", "dmg": 2, "kbr": 0.3},
	"frog": {"sprite": "mushroom", "frames": 8, "fps": 6.5, "scale": 0.62, "hp": 7, "speed": 50.0, "size": Vector2(56, 52), "tint": Color(0.6, 0.95, 0.5), "behavior": "shooter", "dmg": 1, "kbr": 0.1},
	"snake": {"sprite": "jelly", "frames": 6, "fps": 8.0, "scale": 0.6, "hp": 6, "speed": 96.0, "size": Vector2(54, 44), "tint": Color(0.7, 0.95, 1.0), "behavior": "flyer", "dmg": 1, "kbr": 0.1},
	"deep_brute": {"sprite": "golem", "frames": 6, "fps": 9.0, "scale": 1.05, "hp": 46, "speed": 50.0, "size": Vector2(100, 112), "tint": Color(0.45, 0.8, 0.85), "behavior": "charger", "dmg": 3, "kbr": 0.7},
	# 遗迹神殿专属敌种(阶段10.3)
	"gargoyle": {"sprite": "bat", "frames": 4, "fps": 6.5, "scale": 0.78, "hp": 9, "speed": 70.0, "size": Vector2(58, 56), "tint": Color(0.72, 0.7, 0.62), "behavior": "flyer", "dmg": 2, "kbr": 0.15},
	"guard": {"sprite": "beast", "frames": 6, "fps": 5.0, "scale": 0.7, "hp": 13, "speed": 56.0, "size": Vector2(56, 66), "tint": Color(0.8, 0.78, 0.55), "behavior": "charger", "dmg": 2, "kbr": 0.35},
	"priest": {"sprite": "bird", "frames": 7, "fps": 8.3, "scale": 0.64, "hp": 8, "speed": 34.0, "size": Vector2(58, 58), "tint": Color(0.85, 0.75, 1.0), "behavior": "shooter", "dmg": 1, "kbr": 0.1},
	"guard_elite": {"sprite": "golem", "frames": 6, "fps": 9.0, "scale": 1.08, "hp": 50, "speed": 50.0, "size": Vector2(104, 114), "tint": Color(0.85, 0.78, 0.5), "behavior": "charger", "dmg": 3, "kbr": 0.8},
	# 废铁矿坑专属敌种(阶段10.4)
	"gearbat": {"sprite": "bat", "frames": 4, "fps": 9.0, "scale": 0.68, "hp": 7, "speed": 92.0, "size": Vector2(52, 50), "tint": Color(0.78, 0.76, 0.7), "behavior": "flyer", "dmg": 1, "kbr": 0.1},
	"drillworm": {"sprite": "beast", "frames": 6, "fps": 5.5, "scale": 0.66, "hp": 12, "speed": 78.0, "size": Vector2(56, 60), "tint": Color(0.7, 0.62, 0.5), "behavior": "charger", "dmg": 2, "kbr": 0.3},
	"moltenslime": {"sprite": "slime", "frames": 6, "fps": 6.7, "scale": 0.66, "hp": 9, "speed": 60.0, "size": Vector2(56, 58), "tint": Color(1.0, 0.6, 0.3), "behavior": "charger", "dmg": 2, "kbr": 0.1},
	"drill_brute": {"sprite": "golem", "frames": 6, "fps": 9.0, "scale": 1.06, "hp": 48, "speed": 52.0, "size": Vector2(102, 112), "tint": Color(0.78, 0.65, 0.45), "behavior": "charger", "dmg": 3, "kbr": 0.75},
	# 虚空要塞专属敌种(阶段10.5)
	"void_eagle": {"sprite": "bat", "frames": 4, "fps": 9.0, "scale": 0.82, "hp": 11, "speed": 150.0, "size": Vector2(62, 54), "tint": Color(0.58, 0.8, 1.0), "behavior": "diver", "role": "harrier", "dmg": 2, "kbr": 0.15},
	"void_wyvern": {"sprite": "bat", "frames": 4, "fps": 8.5, "scale": 1.0, "hp": 16, "speed": 92.0, "size": Vector2(82, 66), "tint": Color(0.72, 0.42, 1.0), "behavior": "teleflyer", "role": "ambusher", "dmg": 2, "kbr": 0.25},
	"storm_mage": {"sprite": "jelly", "frames": 6, "fps": 7.2, "scale": 0.78, "hp": 14, "speed": 38.0, "size": Vector2(62, 64), "tint": Color(0.55, 0.7, 1.0), "behavior": "storm_mage", "role": "controller", "dmg": 2, "kbr": 0.2},
	# 暗影王城精英(阶段10.6)
	"soul_shield": {"sprite": "golem", "frames": 6, "fps": 8.0, "scale": 0.98, "hp": 34, "speed": 42.0, "size": Vector2(92, 108), "tint": Color(0.5, 0.68, 0.9), "behavior": "charger", "role": "vanguard", "dmg": 3, "kbr": 0.8},
	"soul_spear": {"sprite": "beast", "frames": 6, "fps": 6.5, "scale": 0.82, "hp": 26, "speed": 92.0, "size": Vector2(66, 78), "tint": Color(0.82, 0.35, 0.65), "behavior": "charger", "role": "lancer", "dmg": 3, "kbr": 0.45},
	"soul_cannon": {"sprite": "golem", "frames": 6, "fps": 8.0, "scale": 0.72, "hp": 24, "speed": 34.0, "size": Vector2(76, 88), "tint": Color(0.55, 0.4, 1.0), "behavior": "storm_mage", "role": "artillery", "dmg": 3, "kbr": 0.35},
}

const WALL := 40
const DOWN_PORTAL_HALF_WIDTH := 90.0

var world: Node2D
var combat_director: Node
var pbg: ParallaxBackground
var camera: Camera2D
var hud: CanvasLayer
var player: CharacterBody2D
var slash_frames: SpriteFrames
var room_id := ""
var door_cd := 0.0
var _sfx := {}
var _locked_doors: Array = []   # 当前房间的锁门交互区
var _interactive_portals: Array = []
var _door_hint: Node = null
var boss_bar: CanvasLayer
var _boss: Node = null
var _boss_entry_room := ""
var skill_panel: CanvasLayer
var inv_panel: CanvasLayer
var map_panel: Control
var _bounds: Array = [0, 0, 1400, 560]   # 当前房间边界(用于攀墙越界保护)
var _rune_total := 0                      # 当前房间符文板总数
var _rune_lit := 0                        # 已点亮数(全亮→开符文封门)
var _npc_actors: Dictionary = {}
var dialogue_panel: CanvasLayer
var quest_panel: CanvasLayer
var quest_tracker: CanvasLayer
var cinematic_panel: CanvasLayer
var tutorial_guide: CanvasLayer
var _active_npc := ""
var _active_npc_actor: Node2D
var _dialogue_flags_changed := false

# 钥匙信息: 名称 + 获取地点提示
const KEY_INFO := {
	"red_key": {"name": "红钥匙", "where": "地下水道"},
}

func _ready() -> void:
	randomize()
	slash_frames = AnimLoader.build_slash()
	_build_vignette()
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	_spawn_player()
	_setup_camera()
	_setup_hud()
	_setup_skill_panel()
	_setup_map_panel()
	_setup_quest_ui()
	_setup_menus()
	_setup_dialogue_panel()
	_setup_boss_bar()
	_setup_audio()
	_setup_story_ui()
	# 读档则从存档房间/血量开始, 否则起始房间
	var start_room := Rooms.START
	var loaded: bool = Game.current_room != "" and Rooms.ROOMS.has(Game.current_room)
	if loaded:
		start_room = Game.current_room
	_enter_room(start_room, "")
	if loaded:
		player.health = clampi(Game.player_hp, 1, player.max_hp())
		player.health_changed.emit(player.health, player.max_hp())
	var qa_running := "--shot" in OS.get_cmdline_args() or "--shot" in OS.get_cmdline_user_args()
	if qa_running:
		_auto_screenshot()
	else:
		_start_story_flow.call_deferred(loaded)

func _setup_story_ui() -> void:
	cinematic_panel = CanvasLayer.new()
	cinematic_panel.set_script(CINEMATIC_PANEL_SCRIPT)
	add_child(cinematic_panel)
	cinematic_panel.opened.connect(func(_mode: String):
		Game.menu_open += 1
		if is_instance_valid(player): player.set_input_locked(true))
	cinematic_panel.closed.connect(func(_mode: String):
		Game.menu_open = maxi(0, Game.menu_open - 1)
		if is_instance_valid(player): player.set_input_locked(false))
	cinematic_panel.sequence_finished.connect(_on_cinematic_finished)
	cinematic_panel.return_title_requested.connect(_return_to_title_from_ending)
	tutorial_guide = CanvasLayer.new()
	tutorial_guide.set_script(TUTORIAL_GUIDE_SCRIPT)
	add_child(tutorial_guide)

func _start_story_flow(loaded: bool) -> void:
	if loaded and not bool(Game.story_flags.get("intro_seen", false)):
		Game.set_story_flag("intro_seen")
	if not bool(Game.story_flags.get("intro_seen", false)):
		cinematic_panel.play(CINEMATIC_DATA.INTRO, "intro")
	else:
		tutorial_guide.begin_if_needed(Game.visited.size())

func _on_cinematic_finished(sequence_mode: String) -> void:
	if sequence_mode == "intro":
		Game.set_story_flag("intro_seen")
		Game.save_game()
		tutorial_guide.begin_if_needed(Game.visited.size())
	elif sequence_mode == "ending":
		Game.set_story_flag("ending_seen")
		Game.save_game()

func _return_to_title_from_ending() -> void:
	Game.set_story_flag("ending_seen")
	save_now()
	Game.menu_open = 0
	get_tree().change_scene_to_file("res://title.tscn")

func _setup_menus() -> void:
	var settings := CanvasLayer.new()
	settings.set_script(load("res://scripts/settings_panel.gd"))
	add_child(settings)
	var pause := CanvasLayer.new()
	pause.set_script(load("res://scripts/pause_menu.gd"))
	add_child(pause)
	pause.settings = settings
	pause.main_ref = self

func _setup_dialogue_panel() -> void:
	dialogue_panel = CanvasLayer.new()
	dialogue_panel.set_script(DIALOGUE_PANEL_SCRIPT)
	add_child(dialogue_panel)
	dialogue_panel.conversation_closed.connect(_finish_dialogue)
	dialogue_panel.flags_emitted.connect(_on_dialogue_flags)

func _setup_quest_ui() -> void:
	quest_tracker = CanvasLayer.new()
	quest_tracker.set_script(QUEST_TRACKER_SCRIPT)
	add_child(quest_tracker)
	quest_panel = CanvasLayer.new()
	quest_panel.set_script(QUEST_PANEL_SCRIPT)
	add_child(quest_panel)
	quest_panel.open_changed.connect(func(is_open: bool):
		if is_instance_valid(player):
			player.set_input_locked(is_open))
	Game.refresh_quests(false)

func save_now() -> void:
	Game.player_hp = player.health
	Game.save_game()

func reload_current_room_after_death() -> void:
	var id := room_id
	_enter_room.call_deferred(id, "")

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

func _setup_boss_bar() -> void:
	boss_bar = CanvasLayer.new()
	boss_bar.set_script(load("res://scripts/boss_bar.gd"))
	add_child(boss_bar)

func _spawn_boss(room: Dictionary, id: String) -> void:
	var bd: Dictionary = room["boss"]
	var b := CharacterBody2D.new()
	var mode: String = bd.get("mode", "")
	var boss_script := load("res://scripts/boss.gd")
	if mode == "void_dragon": boss_script = load("res://scripts/void_dragon_boss.gd")
	elif mode == "soul_knights": boss_script = load("res://scripts/soul_knights_boss.gd")
	elif mode == "void_king": boss_script = load("res://scripts/void_king_boss.gd")
	b.set_script(boss_script)
	b.boss_name = bd["name"]
	b.sprite_name = bd["sprite"]
	b.frame_count = bd.get("frames", 6)
	b.anim_fps = bd.get("fps", 8.0)
	b.max_hp = bd["hp"]
	b.sprite_scale = bd["scale"]
	b.body_size = bd["size"]
	b.can_summon = bd.get("summon", false)
	b.summon_type = bd.get("summon_type", "bat")
	if bd.has("tint"):
		b.tint = bd["tint"]
	b.position = Vector2(bd["x"], bd["y"] - 6)
	world.add_child(b)
	_boss = b
	boss_bar.show_boss(bd["name"])
	b.hp_changed.connect(boss_bar.set_hp)
	b.defeated.connect(func(): _on_boss_defeated(id))
	# 封闭竞技场: 在出口门放挡板, 击败后移除
	var bnds = room["bounds"]
	for d in room["doors"]:
		_arena_block_for_door(bnds, d)

func _arena_block_for_door(bnds: Array, d: Dictionary) -> void:
	var blk := StaticBody2D.new(); blk.collision_layer = 0b00001
	var size := Vector2(40, 120)
	match d["side"]:
		"left":
			size = Vector2(40, maxf(40, bnds[3] - d["p"])); blk.position = Vector2(bnds[0] + 20, (d["p"] + bnds[3]) * 0.5)
		"right":
			size = Vector2(40, maxf(40, bnds[3] - d["p"])); blk.position = Vector2(bnds[2] - 20, (d["p"] + bnds[3]) * 0.5)
		"up":
			size = Vector2(120, 40); blk.position = Vector2(d["p"], bnds[1] + 20)
		"down":
			size = Vector2(120, 40); blk.position = Vector2(d["p"], bnds[3] + 20)
	var bc := CollisionShape2D.new(); var bsh := RectangleShape2D.new(); bsh.size = size; bc.shape = bsh; blk.add_child(bc)
	blk.set_meta("arena_block", true); world.add_child(blk)

func _on_boss_defeated(id: String) -> void:
	Game.give_item("boss_" + id)
	boss_bar.hide_boss()
	for c in world.get_children():
		if c.has_meta("arena_block"):
			c.queue_free()
	# 奖励
	Game.add_coins(200)
	Game.add_xp(40)
	if is_instance_valid(player) and player.has_method("heal"):
		player.heal(99)
	Fx.popup(world, player.global_position + Vector2(0, -100), "区域已肃清!  +200金币 +40经验", Color(1, 0.85, 0.4))
	# 掉落宝箱 + 传奇装备
	Pickup.spawn(world, Vector2(player.global_position.x + 80, player.global_position.y - 20), "chest", 1)
	Pickup.spawn_gear(world, Vector2(player.global_position.x - 80, player.global_position.y - 20), ItemsData.generate(3))
	_spawn_room_weapon_rewards(Rooms.ROOMS[id], id, true)
	save_now()
	if id == "castle_throne":
		_show_ending()

func _spawn_room_weapon_rewards(room: Dictionary, id: String, boss_just_defeated: bool) -> void:
	if room.has("boss") and not boss_just_defeated and not Game.has_item("boss_" + id): return
	for reward in room.get("weapons", []):
		if not Game.is_weapon_unlocked(reward[2]):
			Pickup.spawn_weapon(world, Vector2(reward[0], reward[1]), reward[2])

func _show_ending() -> void:
	if is_instance_valid(cinematic_panel):
		cinematic_panel.play(CINEMATIC_DATA.ENDING, "ending")

func _process(delta: float) -> void:
	if door_cd > 0.0:
		door_cd -= delta
	# 攀墙越界保护: 禁止玩家爬出房间顶部边界(上行门在 T+16, 仍可触发)
	if is_instance_valid(player) and player.global_position.y < _bounds[1] - 50:
		player.global_position.y = _bounds[1] - 50
		player.velocity.y = maxf(player.velocity.y, 0.0)
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

# ============================================================ 房间加载
func _enter_room(id: String, from_room: String) -> void:
	if _active_npc != "" and is_instance_valid(dialogue_panel) and dialogue_panel.is_open():
		dialogue_panel.close_conversation()
	_record_room_clear()
	var room: Dictionary = Rooms.ROOMS[id]
	var undefeated_boss := room.has("boss") and not Game.has_item("boss_" + id)
	if undefeated_boss and from_room != "":
		_boss_entry_room = from_room
	elif undefeated_boss and _boss_entry_room == "":
		_boss_entry_room = _fallback_boss_entry(room)
	elif not room.has("boss"):
		_boss_entry_room = ""
	room_id = id
	door_cd = 0.45
	# 清空旧房间
	_locked_doors = []
	_interactive_portals = []
	_npc_actors = {}
	_rune_total = 0
	_rune_lit = 0
	for c in world.get_children():
		c.queue_free()
	combat_director = ENEMY_COMBAT_DIRECTOR.new()
	combat_director.name = "EnemyCombatDirector"
	world.add_child(combat_director)
	_build_parallax(room["theme"])
	_make_theme_backdrop(room)
	var tint: Color = Rooms.THEME_TINT.get(room["theme"], Color.WHITE)
	_build_geometry(room, tint)
	_make_room_atmosphere(room)
	# 装饰物(非碰撞中景, decor): [x, y, "theme/sprite", scale]
	for dc in room.get("decor", []):
		_make_decor(dc[0], dc[1], dc[2], dc[3] if dc.size() > 3 else 1.0)
	for p in room.get("platforms", []):
		if p.size() > 4 and p[4]:
			_make_oneway(p[0], p[1], p[2], tint)
		else:
			_make_solid(p[0], p[1], p[2], p[3], true, tint)
	# 内部迷宫墙 [x, top, w, h] (竖墙/隔墙, 非地面)
	for wseg in room.get("walls", []):
		_make_solid(wseg[0], wseg[1], wseg[2], wseg[3], false, tint)
	for o in room.get("oneways", []):
		_make_oneway(o[0], o[1], o[2], tint)
	# 环境陷阱 [x, top, w, h, dmg, kind]
	for hz in room.get("hazards", []):
		_make_hazard(hz[0], hz[1], hz[2], hz[3], hz[4], hz[5])
	# 移动平台/升降机 [cx, cy, w, axis, dist, period, phase]
	for mv in room.get("movers", []):
		_make_mover(mv, tint)
	# 传送带 [cx, cy, w, h, push]
	for be in room.get("belts", []):
		_make_belt(be[0], be[1], be[2], be[3], be[4], tint)
	# 热气流 [cx, cy, w, h, force]
	for ud in room.get("updrafts", []):
		_make_updraft(ud[0], ud[1], ud[2], ud[3], ud[4])
	# 方向性虚空气流 [cx, cy, w, h, flow_x, flow_y]
	for wd in room.get("winds", []):
		_make_wind(wd[0], wd[1], wd[2], wd[3], Vector2(wd[4], wd[5]))
	for shaft in room.get("shafts", []):
		if shaft[3] >= 500:
			_make_shaft(shaft[0], shaft[1], shaft[2], shaft[3])
	# 水域 [cx, cy, w, h, (flowx=0), (flowy=0)]
	for wt in room.get("water", []):
		_make_water(wt)
	# 符文封门 [x, top, w, h] (踩亮全部符文板后解除)
	for rg in room.get("rune_gates", []):
		_make_rune_barrier(rg[0], rg[1], rg[2], rg[3])
	# 符文板 [x, y] (踩上点亮)
	for rn in room.get("runes", []):
		_make_rune(rn[0], rn[1])
		_rune_total += 1
	if not Game.is_room_cleared(id):
		for e in room.get("enemies", []):
			_spawn_enemy(e[0], e[1], e[2])
	for it in room.get("items", []):
		var iid: String = it[3] if it.size() > 3 else ""
		if it[2] == "chest" and iid == "":
			iid = "%s:chest:%d:%d" % [id, int(it[0]), int(it[1])]
		if it[2] == "chest" and (Game.is_session_chest_open(iid) or Game.is_chest_collected(iid)):
			continue
		var val := 3 if it[2] == "coin" else 1
		Pickup.spawn(world, Vector2(it[0], it[1]), it[2], val, false, iid)
	# 能力拾取物 [x, y, ability_id]
	for ab in room.get("abilities", []):
		Pickup.spawn_ability(world, Vector2(ab[0], ab[1]), ab[2])
	_spawn_room_weapon_rewards(room, id, false)
	# 隐藏收集物(生命碎片等) [x, y, kind, secret_id]: 已收集则不再刷出
	for sc in room.get("secrets", []):
		if not Game.is_collected(sc[3]):
			Pickup.spawn(world, Vector2(sc[0], sc[1]), sc[2], 1, false, sc[3])
	for npc in room.get("npcs", []):
		_spawn_npc(npc)

	# 冲刺门 [x, top, w, h]  (冲刺相位穿越)
	for g in room.get("gates", []):
		_make_dash_gate(g[0], g[1], g[2], g[3])
	# 可破坏墙 [x, top, w, h]  (炸弹炸开)
	for bw in room.get("breakables", []):
		_make_breakable(bw[0], bw[1], bw[2], bw[3])
	# 功能型武器目标 [x, y, kind, width?, height?]，只放在可选路线。
	for target in room.get("skill_targets", []):
		var target_size := Vector2(float(target[3]), float(target[4])) if target.size() >= 5 else Vector2(54, 74)
		_make_skill_interactable(float(target[0]), float(target[1]), str(target[2]), target_size)
	for d in room["doors"]:
		_make_door(room, d)
	if room.has("save"):
		_make_save_point(room["save"])
	# Boss
	_boss = null
	if room.has("boss") and not Game.has_item("boss_" + id):
		_spawn_boss(room, id)
	# 玩家落位
	var sp: Vector2 = _spawn_for(room, from_room)
	player.global_position = sp
	player.velocity = Vector2.ZERO
	player.spawn_point = sp
	player.state = 0
	player.iframes = 0.5
	if is_instance_valid(_boss) and _boss_entry_room != "":
		_spawn_boss_retreat_console(room)
	# 相机
	var b = room["bounds"]
	_bounds = b
	camera.limit_left = int(b[0] - 80); camera.limit_top = int(b[1] - 120)
	camera.limit_right = int(b[2] + 80); camera.limit_bottom = int(b[3] + 120)
	camera.reset_smoothing()
	camera.global_position = sp
	Game.visit_room(id)
	if hud.has_method("set_area"):
		hud.set_area(room["name"])
	_show_banner(room["name"])

func _fallback_boss_entry(room: Dictionary) -> String:
	for door in room.get("doors", []):
		var target := str(door.get("to", ""))
		if target != "":
			return target
	return ""

func _spawn_boss_retreat_console(room: Dictionary) -> void:
	var entry_spawn := _spawn_for(room, _boss_entry_room)
	var bounds: Array = room["bounds"]
	var center := Vector2(
		(float(bounds[0]) + float(bounds[2])) * 0.5,
		(float(bounds[1]) + float(bounds[3])) * 0.5
	)
	var inward := (center - entry_spawn).normalized()
	var console := BOSS_RETREAT_CONSOLE.new()
	console.name = "BossRetreatConsole"
	console.position = entry_spawn + inward * 95.0 + Vector2(0, 12)
	world.add_child(console)
	console.setup(player, self)

func _spawn_npc(entry: Array) -> void:
	if entry.size() < 3:
		push_error("Invalid NPC placement in room " + room_id)
		return
	var id := str(entry[2])
	var actor := Node2D.new()
	actor.set_script(NPC_ACTOR_SCRIPT)
	actor.position = Vector2(float(entry[0]), float(entry[1]))
	world.add_child(actor)
	actor.setup(id)
	actor.interaction_requested.connect(_start_dialogue)
	_npc_actors[id] = actor

func _start_dialogue(npc_id: String, actor: Node2D, forced_node := "") -> void:
	if _active_npc != "" or Game.menu_open > 0 or not is_instance_valid(actor):
		return
	_active_npc = npc_id
	_active_npc_actor = actor
	_dialogue_flags_changed = false
	player.set_input_locked(true)
	Game.menu_open += 1
	Game.dialogue_started.emit(npc_id)
	var flags := Game.dialogue_flags.duplicate(true)
	flags.merge(Game.story_flags, true)
	if forced_node == "":
		dialogue_panel.open_conversation(npc_id, Game.narrative_snapshot(), flags)
	else:
		dialogue_panel.open_specific(npc_id, forced_node)
	var focus_x := clampf((actor.global_position.x - player.global_position.x) * 0.22, -90.0, 90.0)
	camera.create_tween().tween_property(camera, "dialogue_focus", Vector2(focus_x, -20), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_dialogue_flags(flags: Array[String]) -> void:
	for flag in flags:
		var changed := Game.set_story_flag(flag) if flag.begins_with("foreshadow_") else Game.set_dialogue_flag(flag)
		_dialogue_flags_changed = _dialogue_flags_changed or changed

func _finish_dialogue() -> void:
	if _active_npc == "":
		return
	var closed_id := _active_npc
	_active_npc = ""
	_active_npc_actor = null
	player.set_input_locked(false)
	Game.menu_open = maxi(0, Game.menu_open - 1)
	Game.dialogue_ended.emit(closed_id)
	camera.create_tween().tween_property(camera, "dialogue_focus", Vector2.ZERO, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _dialogue_flags_changed:
		save_now()
	_dialogue_flags_changed = false

func _record_room_clear() -> void:
	if room_id == "" or not is_instance_valid(world):
		return
	var living := 0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and not enemy.is_in_group("boss") and not enemy.get("dead"):
			living += 1
	if living == 0 and not Rooms.ROOMS.get(room_id, {}).get("enemies", []).is_empty():
		Game.mark_room_cleared(room_id)

func _spawn_for(room: Dictionary, from_room: String) -> Vector2:
	var b = room["bounds"]
	if from_room == "":
		return room.get("start_spawn", Vector2((b[0] + b[2]) * 0.5, b[3] - 40))
	# 找到通向 from_room 的门, 据其方位落位
	for d in room["doors"]:
		if d["to"] == from_room:
			match d["side"]:
				"left":  return Vector2(b[0] + 90, b[3] - 30)
				"right": return Vector2(b[2] - 90, b[3] - 30)
				"down":  return Vector2(d["p"] + DOWN_PORTAL_HALF_WIDTH + 55.0, b[3] - 30)   # 从下方上来, 站到井口旁
				"up":
					if d.get("hidden", false):
						return Vector2(d["p"], b[1] + 90)
					var landing_x: float = float(d["p"]) + 145.0
					if landing_x > float(b[2]) - 80.0:
						landing_x = float(d["p"]) - 145.0
					return Vector2(landing_x, b[3] - 30)
	return room.get("start_spawn", Vector2((b[0] + b[2]) * 0.5, b[3] - 40))

# ============================================================ 几何
func _build_geometry(room: Dictionary, tint: Color) -> void:
	var b = room["bounds"]
	var L: float = b[0]; var T: float = b[1]; var R: float = b[2]; var B: float = b[3]
	var down_xs: Array = []
	var up_xs: Array = []
	var left_door = null
	var right_door = null
	for d in room["doors"]:
		match d["side"]:
			"down": down_xs.append(d["p"])
			"up":
				if d.get("hidden", false):
					up_xs.append(d["p"])
			"left": left_door = d
			"right": right_door = d
	# 地面(底), 留下行门缺口 + 坑(pit/熔铁河)缺口
	var ground_ranges: Array = []
	for gx in down_xs:
		ground_ranges.append([gx - DOWN_PORTAL_HALF_WIDTH, gx + DOWN_PORTAL_HALF_WIDTH])
	for p in room.get("pits", []):
		ground_ranges.append([p[0] - p[1] * 0.5, p[0] + p[1] * 0.5])
	_build_ground_gaps(L - WALL, R + WALL, B, 200, ground_ranges, tint)
	# 坑底: 接住玩家的实体 + 熔铁危害(掉坑=危害但可跳出, 跨坑走平台=必经动线)
	for p in room.get("pits", []):
		var px: float = p[0]; var pw: float = p[1]
		var depth: float = p[2] if p.size() > 2 else 140.0
		var pdmg: int = p[3] if p.size() > 3 else 2
		_make_solid(px - pw * 0.5, B + depth, pw, 90, true, tint)
		_make_hazard(px - pw * 0.5 + 12, B + depth - 22, pw - 24, 22, pdmg, "lava")
	# 天花板(顶), 留上行门缺口
	_build_run(L - WALL, R + WALL, T - 40, 40, up_xs, false, tint)
	# 左右墙(门处留缺口)
	_build_wall(L - WALL, T, B, left_door, tint)
	_build_wall(R, T, B, right_door, tint)

func _build_ground_gaps(x0: float, x1: float, y: float, h: float, ranges: Array, tint: Color) -> void:
	# 按显式缺口区间铺地面
	var gs := ranges.duplicate()
	gs.sort_custom(func(a, b): return a[0] < b[0])
	var start := x0
	for g in gs:
		if g[0] > start:
			_make_solid(start, y, g[0] - start, h, true, tint)
		start = maxf(start, g[1])
	if x1 > start:
		_make_solid(start, y, x1 - start, h, true, tint)

func _build_run(x0: float, x1: float, y: float, h: float, gaps: Array, is_ground: bool, tint: Color) -> void:
	# 横向铺设, 在 gaps(中心x) 处留 120 宽缺口
	var gs := []
	for gx in gaps:
		gs.append([gx - 60.0, gx + 60.0])
	gs.sort_custom(func(a, b): return a[0] < b[0])
	var start := x0
	for g in gs:
		if g[0] > start:
			_make_solid(start, y, g[0] - start, h, is_ground, tint)
		start = max(start, g[1])
	if x1 > start:
		_make_solid(start, y, x1 - start, h, is_ground, tint)

func _build_wall(x: float, T: float, B: float, door, tint: Color) -> void:
	if door == null:
		_make_solid(x, T - 40, WALL, (B - T) + 240, false, tint)
	else:
		# 门洞: door.p .. B 开口; 墙体只到 door.p
		var top := T - 40
		_make_solid(x, top, WALL, door["p"] - top, false, tint)

# ============================================================ 砖块
func _make_solid(x: float, y: float, w: float, h: float, is_ground: bool, tint: Color = Color.WHITE) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 0b00001
	body.position = Vector2(x + w * 0.5, y + h * 0.5)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	col.shape = shape
	body.add_child(col)
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/tiles/metal.png" if is_ground else "res://assets/tiles/metal_wall.png")
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, w, h)
	spr.modulate = tint
	body.add_child(spr)
	if is_ground:
		var top := Sprite2D.new()
		top.texture = load("res://assets/tiles/metal_top.png")
		top.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		top.region_enabled = true
		top.region_rect = Rect2(0, 0, w, 16)
		top.position = Vector2(0, -h * 0.5 + 5)
		body.add_child(top)
	world.add_child(body)

func _make_breakable(x: float, top: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 0b00001   # 阻挡(world)
	body.add_to_group("breakable")
	body.position = Vector2(x + w * 0.5, top + h * 0.5)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	col.shape = shape
	body.add_child(col)
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/tiles/metal_wall.png")
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, w, h)
	spr.modulate = Color(1.0, 0.75, 0.5)   # 偏橙: 提示可破坏
	body.add_child(spr)
	# 裂纹
	var crack := Line2D.new()
	crack.width = 2.0
	crack.default_color = Color(0.1, 0.08, 0.06, 0.8)
	crack.points = PackedVector2Array([
		Vector2(0, -h * 0.5), Vector2(-6, -h * 0.2), Vector2(5, h * 0.1), Vector2(-4, h * 0.5)])
	body.add_child(crack)
	var lab := Label.new()
	lab.text = "可破坏"
	lab.position = Vector2(-26, -h * 0.5 - 26)
	lab.add_theme_font_size_override("font_size", 14)
	lab.add_theme_color_override("font_color", Color(1, 0.7, 0.4))
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lab.add_theme_constant_override("outline_size", 4)
	body.add_child(lab)
	world.add_child(body)

func _make_skill_interactable(x: float, y: float, kind: String, size: Vector2) -> Node:
	var target := SKILL_INTERACTABLE_SCRIPT.new()
	target.position = Vector2(x, y)
	world.add_child(target)
	target.setup(kind, size)
	return target

func _make_dash_gate(x: float, top: float, w: float, h: float) -> void:
	var gate := DASH_GATE_SCRIPT.new()
	gate.position = Vector2(x + w * 0.5, top + h * 0.5)
	world.add_child(gate)
	gate.setup(Vector2(w, h), 1, player)

func _make_mover(mv: Array, tint: Color) -> void:
	# [cx, cy, w, axis, dist, period, phase]
	var m := AnimatableBody2D.new()
	m.set_script(load("res://scripts/mover.gd"))
	m.position = Vector2(mv[0], mv[1])
	if m.has_method("setup"):
		var ax: String = mv[3] if mv.size() > 3 else "h"
		var dist: float = mv[4] if mv.size() > 4 else 200.0
		var per: float = mv[5] if mv.size() > 5 else 3.0
		var ph: float = mv[6] if mv.size() > 6 else 0.0
		m.setup(mv[2], ax, dist, per, ph, tint)
	world.add_child(m)

func _make_belt(cx: float, cy: float, w: float, h: float, push: float, tint: Color) -> void:
	var be := Area2D.new()
	be.set_script(load("res://scripts/belt.gd"))
	be.position = Vector2(cx, cy)
	if be.has_method("setup"):
		be.setup(w, h, push, tint)
	world.add_child(be)

func _make_rune(x: float, y: float) -> void:
	var r := Area2D.new()
	r.set_script(load("res://scripts/rune.gd"))
	r.position = Vector2(x, y)
	world.add_child(r)

func _make_rune_barrier(x: float, top: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 0b00001
	body.add_to_group("rune_barrier")
	body.position = Vector2(x + w * 0.5, top + h * 0.5)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	col.shape = shape
	body.add_child(col)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var seal := Polygon2D.new()
	seal.polygon = PackedVector2Array([Vector2(-w * 0.5, -h * 0.5), Vector2(w * 0.5, -h * 0.5), Vector2(w * 0.5, h * 0.5), Vector2(-w * 0.5, h * 0.5)])
	seal.color = Color(0.55, 0.4, 0.85, 0.55)
	seal.material = add
	body.add_child(seal)
	# 符文纹路
	var ln := Line2D.new()
	ln.width = 3.0
	ln.closed = true
	ln.default_color = Color(0.8, 0.7, 1.0, 0.8)
	var pts := PackedVector2Array()
	for i in range(6):
		var a := TAU * i / 6.0 - PI / 2.0
		pts.append(Vector2(cos(a) * w * 0.3, sin(a) * h * 0.32))
	ln.points = pts
	ln.material = add
	body.add_child(ln)
	world.add_child(body)

func rune_lit_inc() -> void:
	_rune_lit += 1
	if _rune_total > 0 and _rune_lit >= _rune_total:
		for c in world.get_children():
			if c.is_in_group("rune_barrier"):
				Fx.death_burst(world, c.global_position, Color(0.85, 0.7, 1.0))
				c.queue_free()
		Fx.popup(world, player.global_position + Vector2(0, -96), "符文共鸣!  封门开启", Color(1.0, 0.9, 0.5))
		Fx.screen_flash(get_tree(), Color(0.8, 0.7, 1.0, 0.3))
		play_sfx("ui", -2.0)
		Game.shake(6.0)

func _make_water(wt: Array) -> void:
	# [cx, cy, w, h, (flowx), (flowy)]
	var wa := Area2D.new()
	wa.set_script(load("res://scripts/water.gd"))
	wa.position = Vector2(wt[0], wt[1])
	if wa.has_method("setup"):
		var fx: float = wt[4] if wt.size() > 4 else 0.0
		var fy: float = wt[5] if wt.size() > 5 else 0.0
		wa.setup(wt[2], wt[3], fx, fy)
	world.add_child(wa)

func _make_updraft(cx: float, cy: float, w: float, h: float, force: float) -> void:
	var ud := Area2D.new()
	ud.set_script(load("res://scripts/updraft.gd"))
	ud.position = Vector2(cx, cy)
	if ud.has_method("setup"):
		ud.setup(w, h, force)
	world.add_child(ud)

func _make_wind(cx: float, cy: float, w: float, h: float, flow: Vector2) -> void:
	var wd := Area2D.new()
	wd.set_script(load("res://scripts/updraft.gd"))
	wd.position = Vector2(cx, cy)
	wd.setup_flow(w, h, flow, "wind")
	world.add_child(wd)

func _make_shaft(cx: float, top: float, width: float, depth: float) -> void:
	var root := Node2D.new(); root.position = Vector2(cx, top); root.z_index = 4
	var well := Polygon2D.new(); well.polygon = PackedVector2Array([Vector2(-width * 0.5, 0), Vector2(width * 0.5, 0), Vector2(width * 0.38, depth), Vector2(-width * 0.38, depth)])
	well.color = Color(0.015, 0.01, 0.035, 0.96); root.add_child(well)
	for side in [-1, 1]:
		var rim := Line2D.new(); rim.width = 12.0; rim.default_color = Color(0.3, 0.36, 0.48)
		rim.points = PackedVector2Array([Vector2(side * width * 0.5, -8), Vector2(side * width * 0.42, depth)]); root.add_child(rim)
		var chain := Line2D.new(); chain.width = 3.0; chain.default_color = Color(0.28, 0.22, 0.34)
		chain.points = PackedVector2Array([Vector2(side * width * 0.3, 8), Vector2(side * width * 0.28, depth * 0.78)]); root.add_child(chain)
	var arrow := Label.new(); arrow.text = "▼"; arrow.position = Vector2(-18, 18); arrow.add_theme_font_size_override("font_size", 34); arrow.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0)); root.add_child(arrow)
	var particles := CPUParticles2D.new(); particles.position = Vector2(0, 12); particles.amount = 24; particles.lifetime = 1.4; particles.direction = Vector2(0, 1); particles.spread = 18.0; particles.initial_velocity_min = 40; particles.initial_velocity_max = 90; particles.color = Color(0.5, 0.35, 1.0, 0.55); root.add_child(particles)
	world.add_child(root)

func _make_hazard(x: float, top: float, w: float, h: float, dmg: int, kind: String) -> void:
	var hz := Area2D.new()
	hz.set_script(load("res://scripts/hazard.gd"))
	hz.position = Vector2(x + w * 0.5, top + h * 0.5)
	if hz.has_method("setup"):
		hz.setup(w, h, dmg, kind)
	world.add_child(hz)

func _make_decor(x: float, y: float, path: String, scale: float) -> void:
	# 非碰撞中景装饰: 中心定位, z_index 低(平台/玩家之后, 视差背景之前)
	var tex := load("res://assets/decor/%s.png" % path)
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.position = Vector2(x, y)
	s.scale = Vector2(scale, scale)
	s.z_index = -2
	s.modulate = Color(1.0, 0.98, 1.0)   # 中景, 保持可辨识
	world.add_child(s)

func _make_room_atmosphere(room: Dictionary) -> void:
	var theme: String = room.get("theme", "")
	if theme != "water" and theme != "mine": return
	var b = room["bounds"]
	var root := Node2D.new()
	root.z_index = -3
	# 用低对比的空气层拉开远近关系；刻意避免把同一个支撑物平铺成图案墙。
	var haze := Polygon2D.new()
	haze.polygon = PackedVector2Array([Vector2(b[0],155),Vector2(b[2],155),Vector2(b[2],b[3]-70),Vector2(b[0],b[3]-70)])
	if theme == "water":
		haze.color = Color(0.01,0.20,0.23,0.16)
		var service_pipe := Line2D.new(); service_pipe.width = 16.0; service_pipe.default_color = Color(0.025,0.12,0.14,0.58)
		service_pipe.points = PackedVector2Array([Vector2(b[0]+150,120),Vector2(b[0]+270,120),Vector2(b[0]+292,150),Vector2(b[0]+292,300)]); root.add_child(service_pipe)
		var lamp := Polygon2D.new(); lamp.polygon = PackedVector2Array([Vector2(b[0]+278,210),Vector2(b[0]+306,210),Vector2(b[0]+312,236),Vector2(b[0]+272,236)]); lamp.color = Color(0.25,0.82,0.82,0.42); root.add_child(lamp)
	else:
		haze.color = Color(0.27,0.07,0.015,0.12)
		var distant_rig := Line2D.new(); distant_rig.width = 13.0; distant_rig.default_color = Color(0.16,0.065,0.025,0.52)
		distant_rig.points = PackedVector2Array([Vector2(b[2]-260,140),Vector2(b[2]-190,275),Vector2(b[2]-120,140)]); root.add_child(distant_rig)
		var ember := Polygon2D.new(); ember.polygon = PackedVector2Array([Vector2(b[2]-201,285),Vector2(b[2]-179,285),Vector2(b[2]-174,308),Vector2(b[2]-206,308)]); ember.color = Color(0.9,0.25,0.04,0.36); root.add_child(ember)
	root.add_child(haze)
	world.add_child(root)

func _make_oneway(x: float, y: float, w: float, tint: Color = Color.WHITE) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 0b00001
	body.position = Vector2(x + w * 0.5, y + 9)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, 18)
	col.shape = shape
	col.one_way_collision = true
	body.add_child(col)
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/tiles/platform.png")
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, w, 18)
	spr.modulate = tint
	body.add_child(spr)
	world.add_child(body)

# ============================================================ 门
func _make_door(room: Dictionary, d: Dictionary) -> void:
	var b = room["bounds"]
	var pos: Vector2 = PORTAL_INTERACTION_SCRIPT.anchor_position(d, b)
	var size: Vector2
	var requires_interact := bool(PORTAL_INTERACTION_SCRIPT.requires_interaction(d))
	match d["side"]:
		"left":  size = Vector2(46, b[3] - d["p"])
		"right": size = Vector2(46, b[3] - d["p"])
		"down":  size = Vector2(DOWN_PORTAL_HALF_WIDTH * 2.0, 176)
		"up":    size = Vector2(170, 132) if d.get("hidden", false) else Vector2(240, 150)
	if d["side"] == "down":
		_make_downward_portal(room, d)
		if requires_interact:
			_make_shaft_safety_floor(float(d["p"]), float(b[3]), DOWN_PORTAL_HALF_WIDTH * 2.0)
	var locked: String = d.get("locked", "")
	var is_hidden: bool = d.get("hidden", false)
	var tag := "%s>%s" % [room_id, d["to"]]
	var is_locked := locked != "" and not Game.is_door_unlocked(tag)

	var area: Area2D = PORTAL_INTERACTION_SCRIPT.new() if requires_interact else Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 0b00010
	area.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	area.add_child(cs)
	# 门视觉：特殊入口使用分层机械阵，普通横向门保留轻量轮廓。
	var visual: Node2D = null
	if requires_interact:
		visual = PORTAL_VISUAL_SCRIPT.new()
		visual.setup(is_hidden, is_locked or not _missing_required_abilities(d.get("requires", [])).is_empty(), str(d["side"]))
		area.add_child(visual)
	else:
		var glow := Line2D.new()
		glow.width = 5.0
		glow.closed = true
		glow.default_color = Color(1.0, 0.5, 0.3) if is_locked else Color(0.5, 0.95, 1.0)
		var pts := PackedVector2Array()
		var rw: float = size.x * 0.5 + 6
		var rh: float = min(size.y * 0.5, 70.0)
		for i in range(18):
			var a := TAU * i / 18.0
			pts.append(Vector2(cos(a) * rw, sin(a) * rh))
		glow.points = pts
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = mat
		area.add_child(glow)
		var tw := glow.create_tween().set_loops()
		tw.tween_property(glow, "modulate:a", 0.4, 0.7)
		tw.tween_property(glow, "modulate:a", 1.0, 0.7)
	if requires_interact:
		var portal = area
		var target_name := str(Rooms.ROOMS.get(d["to"], {}).get("name", d["to"]))
		var missing := _missing_required_abilities(d.get("requires", []))
		portal.configure(d, target_name, Game.visited.has(d["to"]), missing)
		portal.travel_requested.connect(func(_door): _request_portal_travel(portal, d, tag, locked))
		portal.travel_blocked.connect(func(names): _on_portal_blocked(pos, names))
		portal.focus_changed.connect(visual.set_focused)
		_interactive_portals.append(portal)
	else:
		area.body_entered.connect(func(body): _on_door(body, d, tag, locked))
	world.add_child(area)

	# 锁门: 在门洞放一块挡板
	if is_locked:
		var block := StaticBody2D.new()
		block.collision_layer = 0b00001
		block.position = pos
		var bc := CollisionShape2D.new()
		var bsh := RectangleShape2D.new()
		bsh.size = size
		bc.shape = bsh
		block.add_child(bc)
		var br := ColorRect.new()
		br.color = Color(0.5, 0.2, 0.15, 0.85)
		br.size = size
		br.position = -size * 0.5
		block.add_child(br)
		var lock := Label.new()
		lock.text = "🔒"
		lock.position = Vector2(-12, -20)
		lock.add_theme_font_size_override("font_size", 28)
		block.add_child(lock)
		block.set_meta("door_tag", tag)
		world.add_child(block)
		# 交互检测区(攻击靠近时提示/解锁)
		var iz := Area2D.new()
		iz.collision_layer = 0
		iz.collision_mask = 0b00010
		iz.position = pos
		var ic := CollisionShape2D.new()
		var ish := RectangleShape2D.new()
		ish.size = Vector2(240, maxf(size.y, 170))
		ic.shape = ish
		iz.add_child(ic)
		world.add_child(iz)
		_locked_doors.append({"tag": tag, "key": locked, "area": iz, "pos": pos})

func _on_player_attacked() -> void:
	for ld in _locked_doors:
		if not is_instance_valid(ld["area"]) or Game.is_door_unlocked(ld["tag"]):
			continue
		if not player in ld["area"].get_overlapping_bodies():
			continue
		var key: String = ld["key"]
		var info: Dictionary = KEY_INFO.get(key, {"name": "钥匙", "where": "某处"})
		if Game.has_item(key):
			Game.unlock_door(ld["tag"])
			for c in world.get_children():
				if c.has_meta("door_tag") and c.get_meta("door_tag") == ld["tag"]:
					c.queue_free()
			_show_door_hint(ld["pos"], "🔓 已用%s解锁!" % info["name"], Color(0.5, 1, 0.7))
			Fx.screen_flash(get_tree(), Color(1, 0.85, 0.4, 0.3))
			Game.shake(5.0)
			play_sfx("ui", -2.0)
		else:
			_show_door_hint(ld["pos"], "🔒 门已锁 · 需要「%s」\n(在%s寻找)" % [info["name"], info["where"]], Color(1, 0.7, 0.4))

func _show_door_hint(pos: Vector2, text: String, color: Color) -> void:
	if _door_hint and is_instance_valid(_door_hint):
		_door_hint.queue_free()
	var l := Label.new()
	l.text = text
	l.position = pos + Vector2(-130, -150)
	l.size = Vector2(260, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 100
	l.add_theme_font_size_override("font_size", 21)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	world.add_child(l)
	_door_hint = l
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

func _on_door(body: Node, d: Dictionary, tag: String, locked: String) -> void:
	if door_cd > 0.0 or not body.is_in_group("player"):
		return
	var required: Array = d.get("requires", [])
	if not _has_required_abilities(required):
		var missing := _missing_required_abilities(required)
		var gate_name := "隐藏回响需要: " if d.get("hidden", false) else "终章封印缺少: "
		Fx.popup(world, player.global_position + Vector2(0,-95), gate_name + " / ".join(missing), Color(0.75,0.55,1))
		door_cd=0.8; return
	if locked != "" and not Game.is_door_unlocked(tag):
		if Game.has_item(locked):
			Game.unlock_door(tag)
			Fx.popup(world, player.global_position + Vector2(0, -90), "门已解锁!", Color(1, 0.85, 0.3))
			Fx.screen_flash(get_tree(), Color(1, 0.8, 0.4, 0.3))
			# 移除挡板
			for c in world.get_children():
				if c.has_meta("door_tag") and c.get_meta("door_tag") == tag:
					c.queue_free()
			door_cd = 0.4
		else:
			Fx.popup(world, player.global_position + Vector2(0, -90), "需要钥匙", Color(1, 0.5, 0.5))
			door_cd = 0.6
		return
	play_sfx("ui", -3.0)
	Fx.screen_flash(get_tree(), Color(0.6, 0.85, 1.0, 0.4))
	# 门触发在碰撞信号期: 换房(重建几何/oneway)必须延迟到 flush 之后,
	# 否则 "Can't change this state while flushing queries"。先锁 door_cd 防重入。
	door_cd = 0.6
	if d["side"] == "down":
		_play_shaft_transition.call_deferred(d["to"])
	else:
		_enter_room.call_deferred(d["to"], room_id)

func _has_required_abilities(required: Array) -> bool:
	return _missing_required_abilities(required).is_empty()

func _missing_required_abilities(required: Array) -> Array[String]:
	var missing: Array[String] = []
	for ability in required:
		if ability != "dash" and not Game.has_ability(ability):
			missing.append(str(Game.ABILITY_NAME.get(ability, ability)))
	return missing

func _request_portal_travel(portal: Node, d: Dictionary, tag: String, locked: String) -> void:
	if door_cd > 0.0:
		portal.reset_request()
		return
	_on_door(player, d, tag, locked)

func _on_portal_blocked(pos: Vector2, missing: Array[String]) -> void:
	_show_door_hint(pos, "封印尚未共鸣\n需要：" + " / ".join(missing), Color(0.78, 0.58, 1.0))
	play_sfx("ui", -7.0)

func _make_shaft_safety_floor(center_x: float, floor_y: float, width: float) -> void:
	var cover := StaticBody2D.new()
	cover.name = "ShaftSafetyFloor"
	cover.collision_layer = 0b00001
	cover.position = Vector2(center_x, floor_y + 3.0)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 12.0)
	collision.shape = shape
	cover.add_child(collision)
	world.add_child(cover)

func _play_shaft_transition(to_room: String) -> void:
	door_cd = 99.0
	var from_room := room_id
	var room: Dictionary = Rooms.ROOMS[room_id]
	var floor_y: float = float(room["bounds"][3])
	var shaft := Node2D.new()
	shaft.set_script(SHAFT_TRANSITION_SCRIPT)
	shaft.global_position = Vector2(player.global_position.x, floor_y)
	world.add_child(shaft)
	shaft.setup(room.get("theme", "city"), player)
	player.shaft_mode = true
	player.z_index = 10
	player.state = 0
	player.velocity = Vector2(0.0, 90.0)
	player.global_position = Vector2(shaft.global_position.x, floor_y + 52.0)
	camera.target = player
	if camera.has_method("begin_shaft"):
		camera.begin_shaft(floor_y + shaft.SHAFT_DEPTH)
	await shaft.finished
	player.shaft_mode = false
	player.z_index = 0
	if camera.has_method("end_shaft"):
		camera.end_shaft()
	Fx.screen_flash(get_tree(), Color(0.08, 0.02, 0.16, 0.72))
	_enter_room(to_room, from_room)

func _make_downward_portal(room: Dictionary, d: Dictionary) -> void:
	var portal_bounds = room["bounds"]
	var portal_theme: String = room.get("theme", "city")
	var portal_visual := Node2D.new()
	portal_visual.set_script(DOWNWARD_PORTAL_VISUAL)
	portal_visual.position = Vector2(d["p"], portal_bounds[3] - 4)
	portal_visual.setup(portal_theme, DOWN_PORTAL_HALF_WIDTH * 2.0, 250.0)
	var portal_mist := CPUParticles2D.new()
	portal_mist.position = Vector2(0, 22)
	portal_mist.amount = 22
	portal_mist.lifetime = 1.7
	portal_mist.direction = Vector2(0, -1)
	portal_mist.spread = 22.0
	portal_mist.initial_velocity_min = 12.0
	portal_mist.initial_velocity_max = 34.0
	portal_mist.color = Color(0.42,0.50,0.82,0.28)
	portal_visual.add_child(portal_mist)
	world.add_child(portal_visual)
func _make_save_point(pos: Vector2) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 0b00010
	area.position = pos                      # 原点在地面
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(80, 110)
	cs.shape = sh
	cs.position = Vector2(0, -55)
	area.add_child(cs)
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var col := Color(0.45, 1.0, 0.7)
	# 金属底座
	var base := ColorRect.new()
	base.color = Color(0.16, 0.2, 0.26)
	base.size = Vector2(56, 18); base.position = Vector2(-28, -18)
	area.add_child(base)
	var base2 := ColorRect.new()
	base2.color = col; base2.size = Vector2(56, 4); base2.position = Vector2(-28, -20)
	base2.material = add_mat
	area.add_child(base2)
	# 两侧立柱
	for sx in [-22, 18]:
		var pillar := ColorRect.new()
		pillar.color = Color(0.22, 0.28, 0.36)
		pillar.size = Vector2(6, 84); pillar.position = Vector2(sx, -102)
		area.add_child(pillar)
	# 中央能量核(脉动光球)
	var core := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 14.0)
	core.polygon = pts
	core.color = col
	core.position = Vector2(0, -64)
	core.material = add_mat
	area.add_child(core)
	var halo := Polygon2D.new()
	halo.polygon = pts; halo.scale = Vector2(2.2, 2.2)
	halo.color = Color(col.r, col.g, col.b, 0.25); halo.position = Vector2(0, -64)
	halo.material = add_mat
	area.add_child(halo)
	var tw := core.create_tween().set_loops()
	tw.tween_property(core, "scale", Vector2(1.25, 1.25), 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(core, "scale", Vector2(0.85, 0.85), 0.8).set_trans(Tween.TRANS_SINE)
	# 上升粒子
	var ps := CPUParticles2D.new()
	ps.position = Vector2(0, -20)
	ps.amount = 14; ps.lifetime = 1.4
	ps.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ps.emission_rect_extents = Vector2(22, 4)
	ps.direction = Vector2(0, -1); ps.spread = 8.0
	ps.gravity = Vector2(0, -30); ps.initial_velocity_min = 18.0; ps.initial_velocity_max = 36.0
	ps.scale_amount_min = 1.5; ps.scale_amount_max = 3.0
	ps.color = Color(col.r, col.g, col.b, 0.7)
	ps.material = add_mat
	area.add_child(ps)
	# 提示
	var lab := Label.new()
	lab.text = "✦ 存档点"
	lab.position = Vector2(-44, -132); lab.size = Vector2(88, 20)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 15)
	lab.add_theme_color_override("font_color", col)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lab.add_theme_constant_override("outline_size", 4)
	area.add_child(lab)
	area.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("heal"):
			body.heal(99)
			save_now()
			Fx.shockwave(world, area.global_position + Vector2(0, -55), col)
			Fx.popup(world, body.global_position + Vector2(0, -95), "已存档 · 回满血", col))
	world.add_child(area)

# ============================================================ 敌人
func _spawn_enemy(x: float, y: float, type: String) -> void:
	var def: Dictionary = ENEMY_DEFS[type]
	var en := CharacterBody2D.new()
	en.set_script(ENEMY_SCRIPT)
	en.enemy_name = def.get("sprite", type)
	en.frame_count = def["frames"]; en.anim_fps = def["fps"]; en.sprite_scale = def["scale"]
	en.max_hp = def["hp"]; en.move_speed = def["speed"]; en.body_size = def["size"]
	en.tint = def["tint"]; en.behavior = def["behavior"]
	en.contact_damage = def["dmg"]; en.knockback_resist = def["kbr"]
	en.enemy_type = type
	en.combat_role = str(def.get("role", ""))
	en.combat_director = combat_director
	var bounds: Array = Rooms.ROOMS[room_id]["bounds"]
	en.room_bounds = Rect2(Vector2(bounds[0], bounds[1]), Vector2(bounds[2] - bounds[0], bounds[3] - bounds[1]))
	en.position = Vector2(x, y - 6)
	world.add_child(en)

# ============================================================ 相机/视差/暗角
func _spawn_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(PLAYER_SCRIPT)
	player.slash_frames = slash_frames
	player.position = Rooms.ROOMS[Rooms.START].get("start_spawn", Vector2(160, 500))
	add_child(player)
	player.attacked.connect(_on_player_attacked)

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.set_script(load("res://scripts/follow_camera.gd"))
	camera.target = player
	add_child(camera)
	var em := CPUParticles2D.new()
	em.amount = 30; em.lifetime = 5.0
	em.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	em.emission_rect_extents = Vector2(720, 420)
	em.direction = Vector2(0, -1); em.spread = 30.0; em.gravity = Vector2(0, -8)
	em.initial_velocity_min = 4.0; em.initial_velocity_max = 16.0
	em.scale_amount_min = 1.0; em.scale_amount_max = 2.5
	em.color = Color(1.0, 0.6, 0.3, 0.25)
	camera.add_child(em)

func _make_theme_backdrop(room: Dictionary) -> void:
	var theme: String = room.get("theme", "")
	if theme != "castle" and theme != "void": return
	var backdrop := Node2D.new()
	backdrop.set_script(THEME_BACKDROP_SCRIPT)
	backdrop.setup(theme, room["bounds"])
	world.add_child(backdrop)

func _build_parallax(theme: String) -> void:
	if pbg and is_instance_valid(pbg):
		pbg.queue_free()
	pbg = ParallaxBackground.new()
	pbg.layer = -20
	add_child(pbg)
	move_child(pbg, 0)
	_bg_fill_layer(theme)
	# 虚空区复用已有工厂层，再由紫青色瓦片/气流统一主题，避免引入未授权素材。
	var bg_theme := "temple" if theme == "castle" else ("factory" if theme == "void" else theme)
	var base := "res://assets/bg/%s/" % bg_theme
	_bg_layer(base + "sky.png", 0.08, 3.2, Vector2(-300, -340))
	_bg_layer(base + "far.png", 0.28, 2.6, Vector2(0, -160))
	_bg_layer(base + "near.png", 0.55, 2.6, Vector2(0, -10))
	_add_theme_atmosphere(theme)

func _bg_fill_layer(theme: String) -> void:
	var colors := {
		"city": Color("09121b"), "factory": Color("190b08"), "mine": Color("130b08"),
		"water": Color("061a1d"), "temple": Color("0d0918"), "void": Color("05091c"),
		"castle": Color("0b0719")
	}
	var fill_color: Color = colors.get(theme, Color("090d16"))
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2.ZERO
	var fill := Polygon2D.new()
	fill.polygon = PackedVector2Array([Vector2(-2200,-1400),Vector2(5200,-1400),Vector2(5200,2600),Vector2(-2200,2600)])
	fill.color = fill_color
	layer.add_child(fill)
	pbg.add_child(layer)

func _add_theme_atmosphere(theme: String) -> void:
	if theme != "water" and theme != "mine": return
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(0.76, 0.76)
	layer.motion_mirroring = Vector2(1680, 0)
	var art := Node2D.new()
	art.z_index = -4
	if theme == "water":
		# 水道的管线、检修灯和滴水，让重复拱顶后面仍有可辨认的工业层次。
		for x in range(-160, 1800, 330):
			var pipe := Line2D.new()
			pipe.width = 15.0
			pipe.default_color = Color(0.06, 0.19, 0.22, 0.92)
			pipe.points = PackedVector2Array([Vector2(x, 120), Vector2(x + 130, 120), Vector2(x + 152, 156), Vector2(x + 152, 300)])
			art.add_child(pipe)
			var lamp := Polygon2D.new()
			lamp.polygon = PackedVector2Array([Vector2(x + 143, 165), Vector2(x + 161, 165), Vector2(x + 166, 183), Vector2(x + 138, 183)])
			lamp.color = Color(0.20, 0.88, 0.93, 0.72)
			art.add_child(lamp)
			var drip := Line2D.new()
			drip.width = 2.0
			drip.default_color = Color(0.30, 0.90, 1.0, 0.38)
			drip.points = PackedVector2Array([Vector2(x + 153, 188), Vector2(x + 149, 238)])
			art.add_child(drip)
	else:
		# 矿坑增加支撑梁、绞盘索和暖色矿灯，打破平铺山体的单调感。
		for x in range(-120, 1800, 300):
			var beam := Line2D.new()
			beam.width = 18.0
			beam.default_color = Color(0.20, 0.105, 0.055, 0.92)
			beam.points = PackedVector2Array([Vector2(x, 80), Vector2(x + 60, 210), Vector2(x + 122, 80)])
			art.add_child(beam)
			var rope := Line2D.new()
			rope.width = 3.0
			rope.default_color = Color(0.18, 0.13, 0.10, 0.82)
			rope.points = PackedVector2Array([Vector2(x + 60, 210), Vector2(x + 60, 370)])
			art.add_child(rope)
			var lantern := Polygon2D.new()
			lantern.polygon = PackedVector2Array([Vector2(x + 50, 226), Vector2(x + 70, 226), Vector2(x + 76, 252), Vector2(x + 44, 252)])
			lantern.color = Color(1.0, 0.38, 0.08, 0.62)
			art.add_child(lantern)
	layer.add_child(art)
	pbg.add_child(layer)

func _bg_layer(path: String, motion: float, sc: float, off: Vector2) -> void:
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(motion, motion)
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.scale = Vector2(sc, sc)
	s.position = off
	layer.motion_mirroring = Vector2(480 * sc, 0)
	layer.add_child(s)
	pbg.add_child(layer)

func _build_vignette() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment(){float d=distance(UV,vec2(0.5));float v=smoothstep(0.30,0.85,d);COLOR=vec4(0.0,0.0,0.03,v*0.7);}"
	mat.shader = sh
	rect.material = mat
	cl.add_child(rect)
	add_child(cl)

# ============================================================ UI
func _setup_hud() -> void:
	hud = CanvasLayer.new()
	hud.set_script(load("res://scripts/hud.gd"))
	add_child(hud)
	player.health_changed.connect(hud.set_health)
	player.resource_changed.connect(hud.set_resources)
	player.weapon_changed.connect(hud.set_weapon)
	Game.enemy_killed.connect(hud.set_kills)
	Game.progression_changed.connect(hud.set_progress)
	hud.set_weapon(player.weapon["name"], player.weapon["color"])
	hud.set_progress()

func _setup_skill_panel() -> void:
	skill_panel = CanvasLayer.new()
	skill_panel.set_script(load("res://scripts/skill_panel.gd"))
	add_child(skill_panel)

func _setup_map_panel() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 21
	var mp := Control.new()
	mp.set_anchors_preset(Control.PRESET_FULL_RECT)
	mp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp.set_script(load("res://scripts/map_panel.gd"))
	map_panel = mp
	cl.add_child(mp)
	add_child(cl)
	# 背包面板
	inv_panel = CanvasLayer.new()
	inv_panel.set_script(load("res://scripts/inventory_panel.gd"))
	add_child(inv_panel)

func _show_banner(text: String) -> void:
	var cl := CanvasLayer.new()
	cl.name = "RoomBanner"
	cl.add_to_group("room_banner")
	cl.layer = 11
	var l := Label.new()
	l.text = text
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(-220, -170)
	l.size = Vector2(440, 60)
	l.add_theme_font_size_override("font_size", 38)
	l.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 8)
	cl.add_child(l)
	add_child(cl)
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(cl.queue_free)

# ============================================================ 音频
func _setup_audio() -> void:
	for k in ["jump", "dash", "land", "atk_hammer", "atk_cannon", "slam"]:
		_sfx[k] = load("res://assets/audio/%s.wav" % k)
	for k in ["attack", "hit", "ui"]:
		_sfx[k] = load("res://assets/audio/%s.mp3" % k)
	var bgm := AudioStreamPlayer.new()
	bgm.name = "BGM"
	bgm.stream = load("res://assets/audio/bgm.mp3")
	if bgm.stream is AudioStreamMP3:
		bgm.stream.loop = true
	bgm.volume_db = -15.0
	add_child(bgm)
	bgm.play()

func play_sfx(key: String, db: float = 0.0, pitch: float = 1.0) -> void:
	if not _sfx.has(key) or _sfx[key] == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = _sfx[key]
	p.volume_db = db
	p.pitch_scale = clampf(pitch, 0.45, 1.6)
	add_child(p)
	p.play()
	p.finished.connect(func():
		if is_instance_valid(p):
			p.queue_free())

func _auto_screenshot() -> void:
	if _qa_option("SHOT_UNLOCK_ABILITIES") == "1":
		for ability_id in Game.ABILITY_NAME:
			Game.grant_ability(str(ability_id))
	var rid := _qa_option("SHOT_ROOM")
	if rid != "" and Rooms.ROOMS.has(rid):
		_enter_room(rid, "")
	var shot_13_1 := _qa_option("SHOT_13_1")
	if shot_13_1 != "":
		await _prepare_13_1_capture(shot_13_1)
		return
	var shot_13_4 := _qa_option("SHOT_13_4")
	if shot_13_4 != "":
		await _prepare_13_4_capture(shot_13_4)
		return
	var shot_13d1 := _qa_option("SHOT_13D1")
	if shot_13d1 != "":
		await _prepare_13d1_capture(shot_13d1)
	var shot_13d2 := _qa_option("SHOT_13D2")
	if shot_13d2 != "":
		await _prepare_13d2_capture(shot_13d2)
		return
	var shot_13d3 := _qa_option("SHOT_13D3")
	if shot_13d3 != "":
		await _prepare_13d3_capture(shot_13d3)
		return
	var portal_kind := _qa_option("SHOT_PORTAL_PROMPT")
	if portal_kind != "":
		await _prepare_portal_capture(portal_kind, _qa_option("SHOT_PORTAL_TRAVEL") == "1")
	if _qa_option("SHOT_INTRO") == "1" and is_instance_valid(cinematic_panel):
		cinematic_panel.play(CINEMATIC_DATA.INTRO, "intro", 1, true)
	if _qa_option("SHOT_TUTORIAL") == "1" and is_instance_valid(tutorial_guide):
		tutorial_guide.force_show_for_qa(2)
	if _qa_option("SHOT_ENDING_12_4") == "1" and is_instance_valid(cinematic_panel):
		cinematic_panel.play(CINEMATIC_DATA.ENDING, "ending", CINEMATIC_DATA.ENDING.size() - 1, true)
	if _qa_option("SHOT_DIALOGUE_PROGRESS") == "1":
		_seed_dialogue_progress_for_qa()
	var shot_dialogue := _qa_option("SHOT_DIALOGUE")
	if shot_dialogue != "":
		await get_tree().process_frame
		var actor: Node2D = _npc_actors.get(shot_dialogue)
		if not is_instance_valid(actor):
			push_error("SHOT_DIALOGUE NPC not found in room: " + shot_dialogue)
		else:
			var forced_node := "bounty_choice" if _qa_option("SHOT_DIALOGUE_CHOICE") == "1" and shot_dialogue == "bounty" else ""
			_start_dialogue(shot_dialogue, actor, forced_node)
	var shot_prompt := _qa_option("SHOT_NPC_PROMPT")
	if shot_prompt != "":
		await get_tree().process_frame
		var prompt_actor: Node2D = _npc_actors.get(shot_prompt)
		if not is_instance_valid(prompt_actor):
			push_error("SHOT_NPC_PROMPT NPC not found in room: " + shot_prompt)
		else:
			player.global_position = prompt_actor.global_position + Vector2(-70, 0)
			prompt_actor.force_prompt_visible(true)
	if _qa_option("SHOT_COMPLETION") == "1":
		for id in ["hub","mine","factory_entry","void_core","secret_void_observatory"]: Game.visited[id] = true
		Game.items["boss_mine_boss"] = true
		Game.permanent_chests["secret_chest_hub"] = true; Game.permanent_chests["secret_chest_void"] = true
		Game.unlock_weapon("relic_blade")
		for sid in ["heart_hub","memory_hub_archive","memory_void_observatory"]: Game.collected[sid] = true
		Game.current_room = room_id
		map_panel.open = true; map_panel.queue_redraw()
	if _qa_option("SHOT_QUEST_LOG") == "1" or _qa_option("SHOT_QUEST_TRACKER") == "1" or _qa_option("SHOT_SIDE_QUESTS") == "1" or _qa_option("SHOT_COLLECTIBLES") == "1":
		_seed_quest_progress_for_qa()
		Game.refresh_quests()
	if _qa_option("SHOT_QUEST_LOG") == "1" and is_instance_valid(quest_panel):
		quest_panel.force_open_for_qa()
	if _qa_option("SHOT_SIDE_QUESTS") == "1" and is_instance_valid(quest_panel):
		quest_panel.force_page_for_qa("side")
	if _qa_option("SHOT_COLLECTIBLES") == "1" and is_instance_valid(quest_panel):
		quest_panel.force_page_for_qa("collectibles")
	var enemy_squad := _qa_option("SHOT_ENEMY_SQUAD")
	if enemy_squad != "":
		await _enemy_squad_capture(enemy_squad)
		return
	if _qa_option("SHOT_SHAFT") == "1":
		await _shaft_capture_burst()
		return
	var shot_phase := OS.get_environment("SHOT_BOSS_PHASE").to_int()
	if shot_phase >= 2 and is_instance_valid(_boss):
		await get_tree().process_frame
		player.iframes = 99.0
		var damage_ratio := 0.7 if shot_phase >= 3 else 0.5
		_boss.take_damage(int(_boss.max_hp * damage_ratio) + 1, Vector2.ZERO)
	# 动作连拍(打击感验收): 在角色面前放假人, 自动打一套, 连存若干帧
	if OS.get_environment("SHOT_MOTION") == "1":
		await _motion_burst()
		return
	# 镜头取景: SHOT_AT="x,y" 把镜头钉在指定点(脱离跟随), 用于看房间任意区域
	var cam_at := _qa_option("SHOT_AT")
	if cam_at != "" and is_instance_valid(camera):
		var parts := cam_at.split(",")
		if parts.size() == 2:
			camera.target = null
			camera.global_position = Vector2(parts[0].to_float(), parts[1].to_float())
	# SHOT_ZOOM<1 看更广, >1 拉近(默认1)
	var cam_zoom := _qa_option("SHOT_ZOOM")
	if cam_zoom != "" and is_instance_valid(camera):
		var z := cam_zoom.to_float()
		if z > 0.0:
			camera.zoom = Vector2(z, z)
	var progression_ui_opened := false
	if _qa_option("SHOT_SKILL_TREE") == "1" and is_instance_valid(skill_panel):
		_seed_progression_ui_for_qa()
		var skill_page := _qa_option("SHOT_SKILL_PAGE")
		if skill_page == "": skill_page = "基础"
		var skill_family := _qa_option("SHOT_SKILL_FAMILY")
		if skill_family == "": skill_family = "刀剑"
		var skill_node := _qa_option("SHOT_SKILL_NODE")
		if skill_node == "": skill_node = "hp"
		skill_panel.call("open_for_qa", skill_page, skill_family, skill_node)
		progression_ui_opened = true
	var inventory_category := _qa_option("SHOT_INVENTORY_CATEGORY")
	if OS.get_environment("SHOT_INV") == "1" and inventory_category == "":
		inventory_category = "防具"
	if inventory_category != "" and is_instance_valid(inv_panel):
		_seed_inventory_for_qa()
		var inventory_index := maxi(0, _qa_option("SHOT_INVENTORY_INDEX").to_int())
		inv_panel.call("open_for_qa", inventory_category, inventory_index)
		progression_ui_opened = true
	if progression_ui_opened:
		await get_tree().process_frame
		await get_tree().process_frame
	if OS.get_environment("SHOT_SWITCH") == "1":
		player._switch_weapon()
	if OS.get_environment("SHOT_END") == "1" and is_instance_valid(_boss):
		await get_tree().process_frame
		_boss.take_damage(_boss.max_hp + 1, Vector2.ZERO)
	var shot_wait := _qa_option("SHOT_WAIT").to_float()
	await get_tree().create_timer(shot_wait if shot_wait > 0.0 else 1.6).timeout
	await RenderingServer.frame_post_draw
	var shot_output := _qa_option("SHOT_OUTPUT")
	if shot_output == "":
		shot_output = ProjectSettings.globalize_path("res://_shot.png")
	var save_error := get_viewport().get_texture().get_image().save_png(shot_output)
	if save_error != OK:
		push_error("Failed to save QA screenshot to %s: %s" % [shot_output, error_string(save_error)])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _prepare_13d1_capture(kind: String) -> void:
	if kind == "dash_gate":
		Game.story_flags.erase(Game.DASH_GATE_TUTORIAL_FLAG)
		_enter_room("tunnel", "depths")
		await get_tree().process_frame
		_clear_13d1_capture_enemies()
		player.global_position = Vector2(205, 520)
		_freeze_13d1_capture_player()
		camera.target = null
		camera.global_position = Vector2(640, 340)
		camera.zoom = Vector2(0.88, 0.88)
	elif kind == "boss_retreat":
		Game.items.erase("boss_mine_boss")
		_enter_room("mine_boss", "cavern")
		await get_tree().process_frame
		_clear_13d1_capture_enemies(true)
		var console := world.get_node_or_null("BossRetreatConsole")
		if not is_instance_valid(console):
			push_error("SHOT_13D1 boss retreat console not found")
			return
		player.global_position = console.global_position + Vector2(130, 0)
		_freeze_13d1_capture_player()
		if is_instance_valid(_boss):
			_boss.set_physics_process(false)
		camera.target = null
		camera.global_position = Vector2(650, 340)
		camera.zoom = Vector2(0.78, 0.78)
	else:
		push_error("SHOT_13D1 must be dash_gate or boss_retreat: " + kind)
		return
	for banner in get_tree().get_nodes_in_group("room_banner"):
		banner.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _clear_13d1_capture_enemies(keep_boss: bool = false) -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			if keep_boss and enemy == _boss:
				continue
			enemy.queue_free()

func _freeze_13d1_capture_player() -> void:
	player.velocity = Vector2.ZERO
	player.iframes = 0.0
	player.anim.visible = true
	player.set_input_locked(true)
	player.set_physics_process(false)

func _prepare_13d2_capture(kind: String) -> void:
	if kind != "material_hits":
		push_error("SHOT_13D2 must be material_hits: " + kind)
		get_tree().quit(1)
		return
	_enter_room("castle_gallery", "")
	await get_tree().process_frame
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for portal in _interactive_portals:
		if is_instance_valid(portal):
			portal.queue_free()
	_interactive_portals.clear()
	await get_tree().process_frame
	var target_specs := [
		[600.0, "beast", "血肉"],
		[800.0, "mech_soldier", "金属"],
		[1000.0, "golem", "岩石"],
		[1200.0, "soul_shield", "护盾"],
		[1400.0, "void_wyvern", "虚空"],
	]
	for spec in target_specs:
		_spawn_enemy(float(spec[0]), 720.0, str(spec[1]))
	await get_tree().process_frame
	var targets: Array[Node] = []
	for spec in target_specs:
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy) and str(enemy.enemy_type) == str(spec[1]):
				enemy.max_hp = 99
				enemy.hp = 99
				enemy.velocity = Vector2.ZERO
				enemy.set_physics_process(false)
				targets.append(enemy)
				var label := Label.new()
				label.text = str(spec[2])
				label.position = Vector2(float(spec[0]) - 34.0, 565.0)
				label.z_index = 80
				label.add_theme_font_size_override("font_size", 24)
				label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
				label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04))
				label.add_theme_constant_override("outline_size", 6)
				world.add_child(label)
				break
	player.global_position = Vector2(280, 720)
	player.velocity = Vector2.ZERO
	player.iframes = 99.0
	player.anim.visible = true
	player.set_input_locked(true)
	player.set_physics_process(false)
	camera.target = null
	camera.global_position = Vector2(1000, 430)
	camera.zoom = Vector2(0.82, 0.82)
	for banner in get_tree().get_nodes_in_group("room_banner"):
		banner.queue_free()
	var out_dir := _qa_option("SHOT_OUTPUT")
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://screenshots/13d2/material-hits")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var tiers := [2, 3, 4, 2, 5]
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/frame_0.png" % out_dir)
	for i in range(targets.size()):
		var enemy := targets[i]
		if is_instance_valid(enemy):
			enemy.take_damage(int(tiers[i]), Vector2(260.0, -95.0))
		await get_tree().create_timer(0.06, true, false, true).timeout
		await RenderingServer.frame_post_draw
		print("13D2_IMPACT_FRAME %d material=%s" % [i + 1, target_specs[i][2]])
		var save_error := get_viewport().get_texture().get_image().save_png("%s/frame_%d.png" % [out_dir, i + 1])
		if save_error != OK:
			push_error("Failed 13D.2 impact frame %d: %s" % [i + 1, error_string(save_error)])
	await get_tree().create_timer(0.1, true, false, true).timeout
	get_tree().quit()

func _prepare_13d3_capture(kind: String) -> void:
	var setups := {
		"sword_relay": ["secret_factory_heat", "sword", "sword_resonance", Vector2(1080, 440), Vector2(1050, 410)],
		"hammer_wall": ["secret_mine_cache", "hammer", "hammer_demolition", Vector2(205, 680), Vector2(420, 510)],
		"cannon_steam": ["secret_factory_heat", "cannon", "cannon_steam_jet", Vector2(600, 450), Vector2(760, 400)],
		"dual_grapple": ["secret_void_observatory", "dual_blades", "dual_grapple", Vector2(560, 470), Vector2(760, 380)],
		"spear_drill": ["secret_mine_cache", "spear", "spear_drill", Vector2(1040, 440), Vector2(1260, 390)],
		"crossbow_switch": ["secret_void_observatory", "crossbow", "crossbow_remote", Vector2(1110, 570), Vector2(1390, 500)],
	}
	if not setups.has(kind):
		push_error("SHOT_13D3 unknown capture: " + kind)
		get_tree().quit(1)
		return
	var setup: Array = setups[kind]
	_enter_room(str(setup[0]), "")
	await get_tree().process_frame
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for banner in get_tree().get_nodes_in_group("room_banner"):
		banner.queue_free()
	Game.skills[str(setup[2])] = 1
	for i in range(Weapons.LIST.size()):
		if str(Weapons.LIST[i]["id"]) == str(setup[1]):
			player._on_weapon_equipped(i)
			break
	player.global_position = setup[3]
	player.velocity = Vector2.ZERO
	player.facing = 1
	player.iframes = 99.0
	player.set_input_locked(true)
	camera.target = null
	camera.global_position = setup[4]
	camera.zoom = Vector2(0.92, 0.92)
	var out_dir := _qa_option("SHOT_OUTPUT")
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://screenshots/13d3/%s" % kind)
	DirAccess.make_dir_recursive_absolute(out_dir)
	await get_tree().create_timer(0.28, true, false, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/frame_0.png" % out_dir)
	print("13D3_TRIGGER kind=%s skill=%s level=%d targets=%d" % [kind, setup[2], Game.skill_lv(str(setup[2])), get_tree().get_nodes_in_group("skill_interactable").size()])
	match kind:
		"sword_relay": player._heavy_sword()
		"hammer_wall": player._heavy_hammer()
		"cannon_steam": player._skill_upper()
		"dual_grapple", "spear_drill": player._skill_dash_atk()
		"crossbow_switch": player._crossbow_heavy()
	for frame_index in range(1, 4):
		await get_tree().create_timer(0.11 + frame_index * 0.05, true, false, true).timeout
		await RenderingServer.frame_post_draw
		var save_error := get_viewport().get_texture().get_image().save_png("%s/frame_%d.png" % [out_dir, frame_index])
		if save_error != OK:
			push_error("Failed 13D.3 frame %d: %s" % [frame_index, error_string(save_error)])
	print("13D3_CAPTURE_COMPLETE " + kind)
	await get_tree().create_timer(0.1, true, false, true).timeout
	get_tree().quit()

func _seed_progression_ui_for_qa() -> void:
	# 仅 --shot 进程内使用，不调用 save_game，不污染玩家存档。
	Game.level = maxi(Game.level, 8)
	Game.skill_points = maxi(Game.skill_points, 9)
	Game.coins = maxi(Game.coins, 860)
	Game.skills = {
		"hp": 1, "power": 1, "speed": 1, "atk": 1, "crit": 1, "spin": 1,
		"dual_edge": 1, "dual_cross": 1, "dual_execution": 1,
		"spear_mastery": 1, "spear_charge": 1, "spear_dragon": 1,
		"crossbow_focus": 1, "crossbow_burst": 1, "crossbow_barrage": 1,
		"sword_resonance": 1, "hammer_demolition": 1, "cannon_steam_jet": 1,
		"dual_grapple": 1, "spear_drill": 1, "crossbow_remote": 1,
	}
	for weapon_id in ["sword", "hammer", "cannon", "dual_blades", "spear", "crossbow"]:
		if not Game.unlocked_weapons.has(weapon_id):
			Game.unlocked_weapons.append(weapon_id)
	Game.skills_changed.emit()
	Game.progression_changed.emit()

func _seed_inventory_for_qa() -> void:
	# 固定物品避免随机词条导致截图对比不稳定；字典仍沿用旧存档格式。
	Game.coins = maxi(Game.coins, 860)
	Game.equipped = {
		"armor": {"name":"稀有·铆钉胸甲", "slot":"armor", "rarity":1, "lv":1, "atk":0.0, "def":2.0, "hp":1.0, "crit":0.0, "ls":0.0, "spd":0.0, "source":"中央车站工坊"},
		"ring": {"name":"普通·余烬戒指", "slot":"ring", "rarity":0, "lv":0, "atk":1.0, "def":0.0, "hp":0.0, "crit":0.02, "ls":0.0, "spd":0.0, "source":"废弃矿坑"},
		"boots": {"name":"稀有·涡轮战靴", "slot":"boots", "rarity":1, "lv":1, "atk":0.0, "def":1.0, "hp":0.0, "crit":0.0, "ls":0.0, "spd":0.05, "source":"机械工坊"},
	}
	Game.inventory = [
		{"name":"传奇·虚空壁垒", "slot":"armor", "rarity":3, "lv":2, "atk":0.0, "def":5.0, "hp":3.0, "crit":0.0, "ls":0.0, "spd":0.0, "source":"虚空要塞宝库", "description":"以虚空合金重铸的胸甲，显著提高防御与生命。"},
		{"name":"史诗·雷鸣护手", "slot":"gloves", "rarity":2, "lv":1, "atk":3.0, "def":1.0, "hp":0.0, "crit":0.08, "ls":0.0, "spd":0.0, "source":"风暴法师掉落"},
		{"name":"稀有·巡夜头盔", "slot":"helmet", "rarity":1, "lv":0, "atk":0.0, "def":2.0, "hp":2.0, "crit":0.0, "ls":0.0, "spd":0.0, "source":"城防仓库"},
		{"name":"史诗·天龙指环", "slot":"ring", "rarity":2, "lv":2, "atk":2.0, "def":0.0, "hp":0.0, "crit":0.12, "ls":1.0, "spd":0.0, "source":"虚空天龙机甲"},
		{"name":"稀有·暗翼护符", "slot":"amulet", "rarity":1, "lv":1, "atk":0.0, "def":0.0, "hp":1.0, "crit":0.06, "ls":1.0, "spd":0.03, "source":"上升气流密室"},
	]
	for weapon_id in ["sword", "hammer", "cannon", "dual_blades", "spear", "crossbow"]:
		if not Game.unlocked_weapons.has(weapon_id):
			Game.unlocked_weapons.append(weapon_id)
	Game.gear_changed.emit()
	Game.progression_changed.emit()

func _prepare_portal_capture(kind: String, trigger_travel: bool) -> void:
	await get_tree().process_frame
	var selected = null
	for portal in _interactive_portals:
		if not is_instance_valid(portal):
			continue
		var data: Dictionary = portal.get("door_data")
		var matches := bool(data.get("hidden", false)) if kind == "hidden" else str(data.get("side", "")) == kind and not bool(data.get("hidden", false))
		if matches:
			selected = portal
			break
	if not is_instance_valid(selected):
		push_error("SHOT_PORTAL_PROMPT found no %s portal in room %s" % [kind, room_id])
		return
	var selected_data: Dictionary = selected.get("door_data")
	selected.set_missing(_missing_required_abilities(selected_data.get("requires", [])))
	selected.force_prompt_visible(true)
	var player_offset := Vector2.ZERO
	match str(selected_data.get("side", "")):
		"left": player_offset = Vector2(75, 0)
		"right": player_offset = Vector2(-75, 0)
		"up": player_offset = Vector2(0, 58) if selected_data.get("hidden", false) else Vector2(-95, 0)
		"down": player_offset = Vector2(0, 34)
	player.global_position = selected.global_position + player_offset
	player.velocity = Vector2.ZERO
	player.process_mode = Node.PROCESS_MODE_DISABLED
	camera.target = null
	camera.global_position = selected.global_position
	if trigger_travel:
		await get_tree().create_timer(0.55).timeout
		selected.attempt_interaction()
		await get_tree().create_timer(0.3).timeout

func _seed_dialogue_progress_for_qa() -> void:
	for id in ["hub", "mine", "factory_entry", "depths", "temple", "void_core", "castle_gate",
		"secret_hub_archive", "secret_mine_cache", "secret_void_observatory"]:
		Game.visited[id] = true
	for boss_id in ["boss_mine_boss", "boss_factory_core", "boss_temple_sanctum", "boss_void_throne"]:
		Game.items[boss_id] = true
	for memory_id in ["memory_hub_archive", "memory_mine_cache", "memory_factory_heat", "memory_void_observatory", "memory_castle_ossuary"]:
		Game.collected[memory_id] = true
	for weapon in Weapons.LIST:
		Game.unlock_weapon(str(weapon["id"]))

func _seed_quest_progress_for_qa() -> void:
	for flag in ["met_smith", "met_alchemist", "met_cartographer", "met_collector", "met_bounty"]: Game.dialogue_flags[flag] = true
	for id in ["hub", "mine", "factory_entry", "water_tunnel", "temple"]:
		Game.visited[id] = true
	Game.items["boss_mine_boss"] = true
	for memory_id in ["memory_hub_archive", "memory_mine_cache", "memory_factory_heat", "memory_water_cistern"]: Game.collected[memory_id] = true
	for weapon in Weapons.LIST: Game.unlock_weapon(str(weapon["id"]))

func _shaft_capture_burst() -> void:
	await get_tree().process_frame
	var down_door: Dictionary = {}
	for door in Rooms.ROOMS[room_id].get("doors", []):
		if door.get("side", "") == "down":
			down_door = door
			break
	if down_door.is_empty():
		push_error("SHOT_SHAFT requested in room without a down door: " + room_id)
		get_tree().quit(1)
		return
	player.global_position = Vector2(float(down_door["p"]), float(_bounds[3]) + 24.0)
	_play_shaft_transition.call_deferred(down_door["to"])
	await get_tree().process_frame
	var out_dir := _qa_option("SHOT_OUTPUT")
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://screenshots/shaft")
	DirAccess.make_dir_recursive_absolute(out_dir)
	for i in range(6):
		await get_tree().create_timer(0.38).timeout
		await RenderingServer.frame_post_draw
		print("SHAFT_FRAME %d player=%s camera=%s" % [i, player.global_position, camera.global_position])
		var save_error := get_viewport().get_texture().get_image().save_png("%s/frame_%d.png" % [out_dir, i])
		if save_error != OK:
			push_error("Failed shaft frame %d: %s" % [i, error_string(save_error)])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _enemy_squad_capture(kind: String) -> void:
	seed(1303)
	var target_room := "void_bridge" if kind == "void" else "castle_gate"
	if kind not in ["void", "castle"]:
		push_error("SHOT_ENEMY_SQUAD must be void or castle: " + kind)
		get_tree().quit(1)
		return
	Game.cleared_rooms.erase(target_room)
	_enter_room(target_room, "")
	await get_tree().process_frame
	await get_tree().physics_frame
	for banner in get_tree().get_nodes_in_group("room_banner"):
		banner.queue_free()
	player.iframes = 99
	player.health = player.max_hp()
	player.velocity = Vector2.ZERO
	if kind == "void":
		player.global_position = Vector2(1100, 700)
		camera.global_position = Vector2(1100, 360)
	else:
		player.global_position = Vector2(1300, 720)
		camera.global_position = Vector2(1280, 430)
	player.set_physics_process(false)
	# Freezing physics must not freeze iframe blinking on an invisible frame.
	player.anim.visible = true
	player.set_input_locked(true)
	_prepare_squad_roles(kind)
	camera.target = null
	camera.zoom = Vector2(0.72, 0.72)
	var out_dir := _qa_option("SHOT_OUTPUT")
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://screenshots/13C/%s-squad" % kind)
	DirAccess.make_dir_recursive_absolute(out_dir)
	for i in range(8):
		await get_tree().create_timer(0.32).timeout
		await RenderingServer.frame_post_draw
		var states: Array[String] = []
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy) and not str(enemy.combat_role).is_empty():
				states.append("%s:%s@%s" % [enemy.combat_role, enemy._role_state, enemy.global_position.round()])
		print("SQUAD_FRAME %s %d %s" % [kind, i, " | ".join(states)])
		var save_error := get_viewport().get_texture().get_image().save_png("%s/frame_%d.png" % [out_dir, i])
		if save_error != OK:
			push_error("Failed squad frame %d: %s" % [i, error_string(save_error)])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _prepare_squad_roles(kind: String) -> void:
	var slots := {
		"void": {
			"harrier": Vector2(850, 230),
			"ambusher": Vector2(1320, 235),
			"controller": Vector2(1550, 320),
		},
		"castle": {
			"lancer": Vector2(850, 720),
			"vanguard": Vector2(1480, 720),
			"artillery": Vector2(1770, 720),
		},
	}
	var order := 0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or str(enemy.combat_role).is_empty():
			continue
		combat_director.notify_action_finished(enemy)
		enemy._clear_role_warning()
		enemy._role_state = ""
		enemy._role_channel = ""
		enemy._role_timer = 0.0
		enemy._special_cd = 0.42 + order * 0.18
		enemy._shoot_cd = 0.42 + order * 0.18
		enemy.velocity = Vector2.ZERO
		if slots[kind].has(enemy.combat_role):
			enemy.global_position = slots[kind][enemy.combat_role]
			enemy._base_y = enemy.global_position.y
		order += 1

func _qa_option(env_name: String) -> String:
	var value := OS.get_environment(env_name)
	if value != "":
		return value
	var prefix := "--%s=" % env_name.to_lower().replace("_", "-")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	for arg in OS.get_cmdline_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""

# 动作连拍: 角色面前放站桩假人, 触发一次攻击, 连存若干帧供打击感验收
# 用法: SHOT_MOTION=1 (可选 SHOT_ROOM / SHOT_ENEMY / SHOT_WEAPON / SHOT_SKILL / SHOT_OUTPUT) ... --shot
## 13.1 主角视觉统一确定性抓图。
## SHOT_13_1=locomotion：待机/奔跑/跳跃/下落/冲刺/受击。
## SHOT_13_1=weapons + SHOT_WEAPON=<id>：六武器待机与攻击姿态。
func _prepare_13_1_capture(capture_kind: String) -> void:
	if capture_kind != "locomotion" and capture_kind != "weapons":
		push_error("SHOT_13_1 unknown capture kind: " + capture_kind)
		get_tree().quit(2)
		return
	for capture_enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(capture_enemy):
			capture_enemy.queue_free()
	var bounds: Array = Rooms.ROOMS[room_id]["bounds"]
	player.global_position = Vector2(
		lerpf(float(bounds[0]), float(bounds[2]), 0.14),
		float(bounds[3]) - 60.0
	)
	player.velocity = Vector2.ZERO
	player.iframes = 0.0
	if is_instance_valid(camera):
		camera.zoom = Vector2(1.35, 1.35)
	await get_tree().process_frame
	await get_tree().create_timer(0.55).timeout
	var out_dir := _qa_option("SHOT_OUTPUT")
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://screenshots/13_1/%s" % capture_kind)
	DirAccess.make_dir_recursive_absolute(out_dir)
	if capture_kind == "weapons":
		await _capture_13_1_weapon(out_dir)
	else:
		await _capture_13_1_locomotion(out_dir)
	get_tree().quit()

func _capture_13_1_locomotion(out_dir: String) -> void:
	player.velocity = Vector2.ZERO
	player._set_anim("idle")
	await _save_13_1_frame(out_dir, "idle")

	Input.action_press("move_right")
	for _step in range(14):
		await get_tree().physics_frame
	Input.action_release("move_right")
	player._set_anim("run")
	await _save_13_1_frame(out_dir, "run")

	player.velocity = Vector2(180.0, -520.0)
	player._set_anim("jump")
	for _step in range(4):
		await get_tree().physics_frame
	await _save_13_1_frame(out_dir, "jump")

	player.velocity = Vector2(120.0, 390.0)
	player._set_anim("fall")
	for _step in range(4):
		await get_tree().physics_frame
	await _save_13_1_frame(out_dir, "fall")

	player._start_dash()
	await get_tree().physics_frame
	await _save_13_1_frame(out_dir, "dash")

	player.state = 3 # Player.S.HURT；QA 只固定动画，不改生命/存档。
	player.velocity = Vector2(-190.0, -160.0)
	player._squash(Vector2(0.86, 1.14))
	player._set_anim("hurt")
	await _save_13_1_frame(out_dir, "hurt")

func _capture_13_1_weapon(out_dir: String) -> void:
	var weapon_id := _qa_option("SHOT_WEAPON")
	var found := false
	for i in range(Weapons.LIST.size()):
		if String(Weapons.LIST[i].get("id", "")) == weapon_id:
			player.weapon_index = i
			player.weapon = Weapons.get_weapon(i)
			player._apply_weapon()
			player.weapon_changed.emit(player.weapon["name"], player.weapon["color"])
			found = true
			break
	if not found:
		push_error("SHOT_13_1 unknown weapon: " + weapon_id)
		get_tree().quit(2)
		return
	player.velocity = Vector2.ZERO
	player._set_anim("idle")
	await _save_13_1_frame(out_dir, "idle")
	Input.action_press("attack")
	await get_tree().process_frame
	await get_tree().physics_frame
	Input.action_release("attack")
	for frame_index in range(5):
		await get_tree().create_timer(0.065).timeout
		await _save_13_1_frame(out_dir, "attack_%d" % frame_index)

func _save_13_1_frame(out_dir: String, file_stem: String) -> void:
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(
		"%s/%s.png" % [out_dir, file_stem]
	)
	if error != OK:
		push_error("SHOT_13_1 failed to save frame: %s (%s)" % [file_stem, error])

func _prepare_13_4_capture(weapon_id: String) -> void:
	var valid_weapon := false
	for weapon_data in Weapons.LIST:
		if String(weapon_data.get("id", "")) == weapon_id:
			valid_weapon = true
			break
	if not valid_weapon:
		push_error("SHOT_13_4 unknown weapon: " + weapon_id)
		get_tree().quit(2)
		return
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	var bounds: Array = Rooms.ROOMS[room_id]["bounds"]
	player.global_position = Vector2(
		lerpf(float(bounds[0]), float(bounds[2]), 0.34),
		float(bounds[3]) - 60.0
	)
	player.velocity = Vector2.ZERO
	player.iframes = 99.0
	await get_tree().process_frame
	await get_tree().create_timer(0.9).timeout
	OS.set_environment("SHOT_WEAPON", weapon_id)
	OS.set_environment("SHOT_SKILL", "burst")
	await _motion_burst()

func _motion_burst() -> void:
	var dummy_type := OS.get_environment("SHOT_ENEMY")
	if dummy_type == "" or not ENEMY_DEFS.has(dummy_type):
		dummy_type = "slime"
	# 一排假人, 让位移/弹道技能也有命中目标
	var dummy_offsets := [125.0, 285.0] if _qa_option("SHOT_13_4") != "" else [70.0, 150.0, 230.0]
	for dx in dummy_offsets:
		_spawn_enemy(player.position.x + dx, player.position.y, dummy_type)
	if _qa_option("SHOT_13_4") != "":
		for capture_dummy in get_tree().get_nodes_in_group("enemy"):
			if not is_instance_valid(capture_dummy):
				continue
			capture_dummy.set_physics_process(false)
			capture_dummy.contact_damage = 0
			capture_dummy.max_hp = 999
			capture_dummy.hp = 999
	# SHOT_WEAPON 接受 Weapons.LIST 任意 id，包括 dual_blades/spear/crossbow。
	var wid := OS.get_environment("SHOT_WEAPON")
	if wid != "":
		for i in range(Weapons.LIST.size()):
			if Weapons.LIST[i]["id"] == wid:
				player.weapon_index = i
				player.weapon = Weapons.get_weapon(i)
				player._apply_weapon()
				player.weapon_changed.emit(player.weapon["name"], player.weapon["color"])  # 刷新HUD武器名
				break
	await get_tree().create_timer(0.5).timeout   # 等镜头/场景稳定
	var out_dir := _qa_option("SHOT_OUTPUT")
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://screenshots/motion")
	DirAccess.make_dir_recursive_absolute(out_dir)
	# SHOT_SKILL: ""=普攻J / ground / upper / dash / burst / ult
	var skill := OS.get_environment("SHOT_SKILL")
	var frames := 5
	# 预置状态(专为拍效果: 搓招直接 arm 窗口, 大招直接给满怒气)
	match skill:
		"upper":
			Input.action_press("move_up")
		"dash":
			player._dash_ready = 0.4
			player._dash_dir = 1
			Input.action_press("move_right")
		"burst":
			player._down_ready = 0.4
			Input.action_press("move_down")
		"ult":
			player.rage = player.MAX_RAGE
	await get_tree().process_frame
	var trigger := "attack"
	if skill == "ground" or skill == "upper" or skill == "dash" or skill == "burst":
		trigger = "skill"
		frames = 8
	elif skill == "ult":
		trigger = "ult"
		frames = 9
	# 触发(跨一个物理帧, 让 just_pressed 生效)
	Input.action_press(trigger)
	await get_tree().process_frame
	await get_tree().physics_frame
	Input.action_release(trigger)
	if skill == "upper":
		Input.action_release("move_up")
	if skill == "dash":
		Input.action_release("move_right")
	if skill == "burst":
		Input.action_release("move_down")
	# 连拍, 每帧约 0.1s, 覆盖整段技能
	for i in range(frames):
		await get_tree().create_timer(0.1).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/frame_%d.png" % [out_dir, i])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
