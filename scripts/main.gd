extends Node2D
## 主场景: 银河城房间世界 - 房间互联/四向穿门/存档点/锁门 + 暗黑机械氛围

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")

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
}

const WALL := 40

var world: Node2D
var pbg: ParallaxBackground
var camera: Camera2D
var hud: CanvasLayer
var player: CharacterBody2D
var slash_frames: SpriteFrames
var room_id := ""
var door_cd := 0.0
var _sfx := {}
var _locked_doors: Array = []   # 当前房间的锁门交互区
var _door_hint: Node = null
var boss_bar: CanvasLayer
var _boss: Node = null
var inv_panel: CanvasLayer
var _bounds: Array = [0, 0, 1400, 560]   # 当前房间边界(用于攀墙越界保护)
var _rune_total := 0                      # 当前房间符文板总数
var _rune_lit := 0                        # 已点亮数(全亮→开符文封门)

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
	_setup_menus()
	_setup_boss_bar()
	_setup_audio()
	# 读档则从存档房间/血量开始, 否则起始房间
	var start_room := Rooms.START
	var loaded: bool = Game.current_room != "" and Rooms.ROOMS.has(Game.current_room)
	if loaded:
		start_room = Game.current_room
	_enter_room(start_room, "")
	if loaded:
		player.health = clampi(Game.player_hp, 1, player.max_hp())
		player.health_changed.emit(player.health, player.max_hp())
	if "--shot" in OS.get_cmdline_args() or "--shot" in OS.get_cmdline_user_args():
		_auto_screenshot()

func _setup_menus() -> void:
	var settings := CanvasLayer.new()
	settings.set_script(load("res://scripts/settings_panel.gd"))
	add_child(settings)
	var pause := CanvasLayer.new()
	pause.set_script(load("res://scripts/pause_menu.gd"))
	add_child(pause)
	pause.settings = settings
	pause.main_ref = self

func save_now() -> void:
	Game.player_hp = player.health
	Game.save_game()

func _setup_boss_bar() -> void:
	boss_bar = CanvasLayer.new()
	boss_bar.set_script(load("res://scripts/boss_bar.gd"))
	add_child(boss_bar)

func _spawn_boss(room: Dictionary, id: String) -> void:
	var bd: Dictionary = room["boss"]
	var b := CharacterBody2D.new()
	b.set_script(load("res://scripts/boss.gd"))
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
		var blk := StaticBody2D.new()
		blk.collision_layer = 0b00001
		var bx: float = bnds[0] + 20 if d["side"] == "left" else bnds[2] - 20
		blk.position = Vector2(bx, (d["p"] + bnds[3]) * 0.5)
		var bc := CollisionShape2D.new()
		var bsh := RectangleShape2D.new()
		bsh.size = Vector2(40, bnds[3] - d["p"])
		bc.shape = bsh
		blk.add_child(bc)
		blk.set_meta("arena_block", true)
		world.add_child(blk)

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
	save_now()

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
	room_id = id
	var room: Dictionary = Rooms.ROOMS[id]
	door_cd = 0.45
	# 清空旧房间
	_locked_doors = []
	_rune_total = 0
	_rune_lit = 0
	for c in world.get_children():
		c.queue_free()
	_build_parallax(room["theme"])
	var tint: Color = Rooms.THEME_TINT.get(room["theme"], Color.WHITE)
	_build_geometry(room, tint)
	# 装饰物(非碰撞中景, decor): [x, y, "theme/sprite", scale]
	for dc in room.get("decor", []):
		_make_decor(dc[0], dc[1], dc[2], dc[3] if dc.size() > 3 else 1.0)
	for p in room.get("platforms", []):
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
	for e in room.get("enemies", []):
		_spawn_enemy(e[0], e[1], e[2])
	for it in room.get("items", []):
		var iid: String = it[3] if it.size() > 3 else ""
		var val := 3 if it[2] == "coin" else 1
		Pickup.spawn(world, Vector2(it[0], it[1]), it[2], val, false, iid)
	# 能力拾取物 [x, y, ability_id]
	for ab in room.get("abilities", []):
		Pickup.spawn_ability(world, Vector2(ab[0], ab[1]), ab[2])
	# 隐藏收集物(生命碎片等) [x, y, kind, secret_id]: 已收集则不再刷出
	for sc in room.get("secrets", []):
		if not Game.is_collected(sc[3]):
			Pickup.spawn(world, Vector2(sc[0], sc[1]), sc[2], 1, false, sc[3])
	# 冲刺门 [x, top, w, h]  (冲刺相位穿越)
	for g in room.get("gates", []):
		_make_dash_gate(g[0], g[1], g[2], g[3])
	# 可破坏墙 [x, top, w, h]  (炸弹炸开)
	for bw in room.get("breakables", []):
		_make_breakable(bw[0], bw[1], bw[2], bw[3])
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
				"down":  return Vector2(d["p"] + 110, b[3] - 30)   # 从下方上来, 站到洞口旁
				"up":    return Vector2(d["p"], b[1] + 90)          # 从上方落下
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
			"up": up_xs.append(d["p"])
			"left": left_door = d
			"right": right_door = d
	# 地面(底), 留下行门缺口 + 坑(pit/熔铁河)缺口
	var ground_ranges: Array = []
	for gx in down_xs:
		ground_ranges.append([gx - 60.0, gx + 60.0])
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

func _make_dash_gate(x: float, top: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 0b100000   # bit6: 冲刺门(玩家平时碰撞, 冲刺时相位穿越)
	body.collision_mask = 0
	body.position = Vector2(x + w * 0.5, top + h * 0.5)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	col.shape = shape
	body.add_child(col)
	# 视觉: 青色能量屏障
	var rect := ColorRect.new()
	rect.color = Color(0.4, 0.85, 1.0, 0.35)
	rect.size = Vector2(w, h)
	rect.position = Vector2(-w * 0.5, -h * 0.5)
	body.add_child(rect)
	var edge := Line2D.new()
	edge.width = 3.0
	edge.default_color = Color(0.6, 0.95, 1.0)
	edge.points = PackedVector2Array([Vector2(0, -h * 0.5), Vector2(0, h * 0.5)])
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	edge.material = mat
	body.add_child(edge)
	var lab := Label.new()
	lab.text = "⟫冲刺⟫"
	lab.position = Vector2(-28, -h * 0.5 - 30)
	lab.add_theme_font_size_override("font_size", 18)
	lab.add_theme_color_override("font_color", Color(0.6, 0.95, 1.0))
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lab.add_theme_constant_override("outline_size", 5)
	body.add_child(lab)
	var tw := rect.create_tween().set_loops()
	tw.tween_property(rect, "color:a", 0.18, 0.8)
	tw.tween_property(rect, "color:a", 0.4, 0.8)
	world.add_child(body)

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
	var pos: Vector2
	var size: Vector2
	match d["side"]:
		"left":  pos = Vector2(b[0] + 12, (d["p"] + b[3]) * 0.5); size = Vector2(46, b[3] - d["p"])
		"right": pos = Vector2(b[2] - 12, (d["p"] + b[3]) * 0.5); size = Vector2(46, b[3] - d["p"])
		"down":  pos = Vector2(d["p"], b[3] + 36); size = Vector2(110, 60)
		"up":    pos = Vector2(d["p"], b[1] + 16); size = Vector2(110, 60)
	var locked: String = d.get("locked", "")
	var tag := "%s>%s" % [room_id, d["to"]]
	var is_locked := locked != "" and not Game.is_door_unlocked(tag)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 0b00010
	area.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	area.add_child(cs)
	# 门视觉
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
	_enter_room.call_deferred(d["to"], room_id)

# ============================================================ 存档点
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

func _build_parallax(theme: String) -> void:
	if pbg and is_instance_valid(pbg):
		pbg.queue_free()
	pbg = ParallaxBackground.new()
	add_child(pbg)
	move_child(pbg, 0)
	var base := "res://assets/bg/%s/" % theme
	_bg_layer(base + "sky.png", 0.08, 3.2, Vector2(-300, -340))
	_bg_layer(base + "far.png", 0.28, 2.6, Vector2(0, -160))
	_bg_layer(base + "near.png", 0.55, 2.6, Vector2(0, -10))

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
	var sp := CanvasLayer.new()
	sp.set_script(load("res://scripts/skill_panel.gd"))
	add_child(sp)

func _setup_map_panel() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 21
	var mp := Control.new()
	mp.set_anchors_preset(Control.PRESET_FULL_RECT)
	mp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp.set_script(load("res://scripts/map_panel.gd"))
	cl.add_child(mp)
	add_child(cl)
	# 背包面板
	inv_panel = CanvasLayer.new()
	inv_panel.set_script(load("res://scripts/inventory_panel.gd"))
	add_child(inv_panel)

func _show_banner(text: String) -> void:
	var cl := CanvasLayer.new()
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

func play_sfx(key: String, db: float = 0.0) -> void:
	if not _sfx.has(key) or _sfx[key] == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = _sfx[key]
	p.volume_db = db
	add_child(p)
	p.play()
	p.finished.connect(func():
		if is_instance_valid(p):
			p.queue_free())

func _auto_screenshot() -> void:
	var rid := OS.get_environment("SHOT_ROOM")
	if rid != "" and Rooms.ROOMS.has(rid):
		_enter_room(rid, "")
	# 动作连拍(打击感验收): 在角色面前放假人, 自动打一套, 连存若干帧
	if OS.get_environment("SHOT_MOTION") == "1":
		await _motion_burst()
		return
	# 镜头取景: SHOT_AT="x,y" 把镜头钉在指定点(脱离跟随), 用于看房间任意区域
	var cam_at := OS.get_environment("SHOT_AT")
	if cam_at != "" and is_instance_valid(camera):
		var parts := cam_at.split(",")
		if parts.size() == 2:
			camera.target = null
			camera.global_position = Vector2(parts[0].to_float(), parts[1].to_float())
	# SHOT_ZOOM<1 看更广, >1 拉近(默认1)
	var cam_zoom := OS.get_environment("SHOT_ZOOM")
	if cam_zoom != "" and is_instance_valid(camera):
		var z := cam_zoom.to_float()
		if z > 0.0:
			camera.zoom = Vector2(z, z)
	if OS.get_environment("SHOT_INV") == "1":
		Game.add_item(ItemsData.generate(3))
		Game.add_item(ItemsData.generate(2))
		Game.add_item(ItemsData.generate(1))
		Game.add_item(ItemsData.generate(0))
		Game.equip_item(0)
		Game.coins = 500
		if inv_panel and inv_panel.has_method("_toggle"):
			inv_panel._toggle()
	await get_tree().create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://_shot.png"))
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

# 动作连拍: 角色面前放站桩假人, 触发一次攻击, 连存若干帧供打击感验收
# 用法: SHOT_MOTION=1 (可选 SHOT_ROOM=<房间> / SHOT_ENEMY=<敌人type>) ... --shot
func _motion_burst() -> void:
	var dummy_type := OS.get_environment("SHOT_ENEMY")
	if dummy_type == "" or not ENEMY_DEFS.has(dummy_type):
		dummy_type = "slime"
	# 一排假人, 让位移/弹道技能也有命中目标
	for dx in [70.0, 150.0, 230.0]:
		_spawn_enemy(player.position.x + dx, player.position.y, dummy_type)
	# SHOT_WEAPON: sword/hammer/cannon — 切到指定武器再放技能(验证武器联动变形)
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
	var out_dir := ProjectSettings.globalize_path("res://screenshots/motion")
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
