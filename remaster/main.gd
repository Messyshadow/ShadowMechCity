extends Node3D
const World = preload("res://remaster/world_data.gd")
const ActorScript = preload("res://remaster/actor.gd")
const EnemyScript = preload("res://remaster/enemy.gd")
const ProjectileScript = preload("res://remaster/projectile.gd")
const AudioScript = preload("res://remaster/audio.gd")
const UIScript = preload("res://remaster/ui.gd")
const CompanionsScript = preload("res://remaster/companions.gd")
const ControlsScript = preload("res://remaster/controls.gd")
const LevelDesign = preload("res://remaster/level_design.gd")
const REGION_COLORS := {"city":Color(.16,.73,.85),"mine":Color(1,.49,.17),"water":Color(.13,.86,.61),"factory":Color(1,.37,.10),"temple":Color(.83,.66,.32),"void":Color(.53,.36,1),"castle":Color(.46,.63,.88),"dawn":Color(.65,.91,.48)}
const BOSS_MODELS := {"temple_sanctum":"guardian","mine_boss":"behemoth","water_boss":"crocodile","boss":"titan","void_throne":"dragon","castle_knights":"knight","castle_throne":"king"}
var world: Node3D
var player: CharacterBody3D
var camera: Camera3D
var ui: CanvasLayer
var companions:Node
var controls:Node
var audio: Node
var room_id := "hub"
var room: Dictionary = {}
var room_width := 24.0
var enemies: Array = []
var doors: Array = []
var ladders: Array = []
var pickups: Array = []
var gears: Array = []
var hazards: Array = []
var movers: Array = []
var boss: Node3D
var save_position := Vector3.ZERO
var merchant_position := Vector3(8,0,0)
var transitioning := false
var transition_cooldown := 0.0
var shake := 0.0
var time := 0.0
var meshes: Dictionary = {}
var materials: Dictionary = {}
var capture_path := ""
var capture_timer := 0.0
var room_override := ""
var panel_override := ""
var platforms: Array = []
var strikes: Array = []
var environment: Environment
var npc_position := Vector3(14.4,0,0)
var beacon_position := Vector3.ZERO
var beacon_lamp: OmniLight3D
var beacon_glow: MeshInstance3D
var beacon_label: Label3D

func _ready() -> void:
	register_input()
	controls=Node.new();controls.set_script(ControlsScript);controls.game=self
	audio=Node.new(); audio.set_script(AudioScript); add_child(audio)
	setup_environment()
	ui=CanvasLayer.new(); ui.set_script(UIScript); ui.game=self; add_child(ui)
	companions=Node.new();companions.set_script(CompanionsScript);companions.game=self;add_child(companions)
	add_child(controls)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--remaster-room="): room_override=arg.get_slice("=",1)
		if arg.begins_with("--remaster-capture="): capture_path=arg.get_slice("=",1)
		if arg.begins_with("--remaster-panel="): panel_override=arg.get_slice("=",1)
		if arg=="--remaster-test": Reforged.persistence_enabled=false
	load_room(room_override if World.ROOMS.has(room_override) else Reforged.checkpoint_room, "", true)
	if room_override.is_empty(): ui.open_title()
	if Reforged.save_blocked:ui.open_save_recovery()
	if not Reforged.save_notice.is_empty():ui.toast(Reforged.save_notice,8)
	if panel_override in ["open_title","open_inventory","open_skills","open_map","open_shop","open_settings","open_journal","open_npc","open_story","open_companions"]:ui.call(panel_override)
	if not capture_path.is_empty():capture_timer=4.0;player.invulnerable=10

func register_input() -> void:
	ControlsScript.register_actions()

func setup_environment() -> void:
	get_viewport().msaa_3d=Viewport.MSAA_4X
	var env := WorldEnvironment.new(); add_child(env)
	var e := Environment.new();env.environment=e;environment=e
	e.background_mode=Environment.BG_COLOR; e.background_color=Color(.022,.039,.065)
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color=Color(.49,.58,.68);e.ambient_light_energy=.66
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	e.fog_enabled=true; e.fog_light_color=Color(.035,.069,.09);e.fog_density=.013
	e.ssao_enabled=true;e.ssao_radius=.85;e.ssao_intensity=1.15
	e.glow_enabled=true; e.glow_intensity=.35
	var sun:=DirectionalLight3D.new();add_child(sun);sun.rotation_degrees=Vector3(-42,-28,0)
	sun.light_color=Color(.68,.79,.9);sun.light_energy=1.05;sun.shadow_enabled=true
	var fill:=DirectionalLight3D.new();add_child(fill);fill.rotation_degrees=Vector3(-20,140,0)
	fill.light_color=Color(.67,.79,1);fill.light_energy=.85
	camera=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	camera.fov=37;camera.far=160;camera.current=true
	camera.position=Vector3(8,5,21);camera.rotation_degrees=Vector3(-7,0,0)
	apply_visibility()

func apply_visibility() -> void:
	if environment:
		environment.adjustment_enabled=true;environment.adjustment_brightness=float(Reforged.settings.brightness)
		environment.adjustment_contrast=1.04;environment.adjustment_saturation=.98

func quit_game() -> void:
	Reforged.save_game();Reforged.save_settings()
	get_tree().create_timer(.25).timeout.connect(get_tree().quit)
	queue_free()

func model(id: String) -> Node3D:
	if not meshes.has(id): meshes[id]=load("res://remaster/assets/models/"+id+".glb")
	if meshes[id] is PackedScene: return meshes[id].instantiate()
	push_error("Missing Blender asset: "+id)
	return Node3D.new()

func mat(color: Color, emissive := false) -> StandardMaterial3D:
	var key:=str(color)+str(emissive)
	if materials.has(key): return materials[key]
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.5;m.metallic=.65
	if emissive: m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=2
	materials[key]=m;return m

func cube(parent: Node3D, pos: Vector3, size: Vector3, color: Color, emissive := false) -> MeshInstance3D:
	var m:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size
	m.mesh=mesh;m.material_override=mat(color,emissive);parent.add_child(m);m.position=pos
	return m

func solid(pos: Vector3, size: Vector3, parent: Node3D = null) -> StaticBody3D:
	var body:=StaticBody3D.new();(world if parent==null else parent).add_child(body)
	body.position=pos;body.collision_layer=1;body.collision_mask=0
	var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)
	return body

func deck(x: float, y: float, width: float, depth := 2.8) -> void:
	if width<.1:return
	solid(Vector3(x,y-.22,0),Vector3(width,.44,depth))
	var node:=model("platform");world.add_child(node);node.position=Vector3(x,y,0)
	node.scale=Vector3(width/4,1,depth/2.8)
	var edge:=cube(world,Vector3(x,y+.012,depth*.5),Vector3(width,.038,.045),Color(.29,.53,.58),true);edge.transparency=.40

func label3(text: String, pos: Vector3, color := Color(.7,.9,1), size := 32) -> Label3D:
	var l:=Label3D.new();world.add_child(l);l.text=text;l.position=pos;l.font_size=size;l.pixel_size=.008
	l.modulate=color;l.outline_size=5;l.no_depth_test=false;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	if not text.is_empty():l.set_meta("prompt_source",text);l.text=controls.prompt(text)
	return l

func load_room(id: String, from := "", initial := false) -> void:
	if not World.ROOMS.has(id): return
	if is_instance_valid(world):
		remove_child(world);world.queue_free()
	if is_instance_valid(player): remove_child(player);player.queue_free()
	room_id=id;room=World.ROOMS[id];room_width=maxf(24,float(room.bounds[2])/64.0)
	world=Node3D.new();world.name="RebuiltWorld";add_child(world)
	enemies.clear();doors.clear();ladders.clear();pickups.clear();gears.clear();hazards.clear();movers.clear();platforms.clear();strikes.clear();boss=null
	build_background(str(room.theme))
	build_floor()
	build_platforms()
	build_doors()
	build_machines()
	var spawn:=Vector3(3,.15,0)
	if initial and room_id==Reforged.checkpoint_room: spawn=Reforged.checkpoint
	for door in doors:
		if str(door.to)==from:
			spawn=Vector3(float(door.x),.15,0)
			if door.side=="left": spawn.x+=1.8
			elif door.side=="right":spawn.x-=1.8
			else:spawn=safe_ground_spawn(float(door.x)+1.8)
	player=CharacterBody3D.new();player.set_script(ActorScript);player.game=self;player.position=spawn;add_child(player)
	player.name="Hunter";player.invulnerable=1.0
	if not room.has("boss") and room_id!="hub" and not room.get("hidden_room",false):
		for i in range(3 if room.theme in ["void","castle","factory"] else 2):
			var x:=room_width*(.40+i*.19)
			# Keep enemies away from the arrival and checkpoint corridor.
			for l in ladders:
				if absf(x-float(l.x))<2.0:x+=2.5
			spawn_enemy(LevelDesign.enemy_kind(str(room.theme),i),safe_ground_spawn(x))
	if room.has("boss") and not Reforged.bosses.has(id):
		var kind: String=BOSS_MODELS.get(id,"guardian")
		boss=spawn_enemy(kind,Vector3(room_width*.7,.1,0),true)
		boss.boss_name=str(room.boss.name)
		boss.max_hp=340.0+float(room.boss.get("hp",120))*.8
		boss.hp=boss.max_hp
	build_interactables()
	if companions:companions.refresh()
	Reforged.visited[id]=true;Reforged.save_game()
	transition_cooldown=1; transitioning=false
	camera.position=Vector3(clampf(spawn.x,8,room_width-8),5,22)
	ui.region_banner(str(room.name),str(room.theme))
	if audio.has_method("set_region"):audio.set_region(str(room.theme),is_instance_valid(boss))

func build_floor() -> void:
	var cuts: Array[Vector2]=[]
	for d in room.get("doors",[]):
		if d.side=="down":
			var x:=door_x(d)
			if str(LevelDesign.profile(room_id)[3])=="stairs" and not bool(d.get("hidden",false)):
				var exit_x:=x+3.2*(-1 if x>room_width*.55 else 1)
				cuts.append(Vector2(minf(x,exit_x)-1,maxf(x,exit_x)+1))
			else:cuts.append(Vector2(x-1,x+1))
	for pit in room.get("pits",[]):
		var x:=float(pit[0])/64.0;var width:=float(pit[1])/64.0
		var crosses_passage:=false
		for cut in cuts:
			if x<cut.y+.5 and x+width>cut.x-.5:crosses_passage=true
		if crosses_passage:continue
		cuts.append(Vector2(x,x+width))
		for px in range(int(ceil(width/2.8))): deck(x+.7+px*2.8,.5+(.6 if px%2 else 0),1.6)
		cube(world,Vector3(x+width*.5,-3.8,0),Vector3(width,.08,2.7),REGION_COLORS[room.theme].darkened(.4),room.theme in ["mine","factory","void"])
	cuts.sort_custom(func(a,b):return a.x<b.x)
	var left:=0.0
	for cut in cuts:
		var end:=clampf(cut.x,0,room_width)
		floor_strip(left,end);left=maxf(left,cut.y)
	floor_strip(left,room_width)
	# Perimeter columns provide readable, physical surfaces for wall jumping.
	for x in [-.35,room_width+.35]:
		solid(Vector3(x,5,0),Vector3(.6,12,3))
		cube(world,Vector3(x,5,-.4),Vector3(.6,12,2.2),Color(.07,.10,.13))

func floor_strip(a: float, b: float) -> void:
	var x:=a
	while x<b-.05:
		var width:=minf(4,b-x);deck(x+width*.5,0,width);x+=width

func build_platforms() -> void:
	var shafts:Array=[]
	for d in room.get("doors",[]):
		if d.side in ["up","down"]:shafts.append(door_x(d))
	platforms=LevelDesign.platforms(room_id,room_width,shafts)
	for p in platforms:deck(p.x,p.y,p.z)

func surface_y(x: float, upper := false) -> float:
	if upper:
		var highest:=0.0
		for p in platforms:
			if absf(p.x-x)<p.z*.5-.25:highest=maxf(highest,p.y)
		return highest
	for pit in room.get("pits",[]):
		var start:=float(pit[0])/64.0;var width:=float(pit[1])/64.0
		if x>start and x<start+width:return 1.9
	return 0.0

func safe_ground_spawn(x: float) -> Vector3:
	for attempt in range(8):
		var moved:=false
		for pit in room.get("pits",[]):
			var a:=float(pit[0])/64.0;var b:=a+float(pit[1])/64.0
			if x>a-.6 and x<b+.6:x=b+.9;moved=true
		for l in ladders:
			if l.door.side=="down":
				var start:=minf(l.x,l.exit_x) if l.kind=="stairs" else float(l.x)
				var end:=maxf(l.x,l.exit_x) if l.kind=="stairs" else float(l.x)
				if x>start-1.7 and x<end+1.7:x=end+1.9;moved=true
		if not moved:break
	return Vector3(clampf(x,2,room_width-2),.1,0)

func door_x(d: Dictionary) -> float:
	if d.side=="left":return 1.0
	if d.side=="right":return room_width-1.0
	var x:=float(d.p)/64.0
	for other in room.get("doors",[]):
		if other.side in ["up","down"] and other.side!=d.side and absf(float(other.p)/64.0-x)<2.8:
			x+=-1.8 if d.side=="up" else 1.8;break
	return clampf(x,3.0,room_width-3.0)

func build_doors() -> void:
	for src in room.get("doors",[]):
		if not World.ROOMS.has(str(src.to)):continue
		var d:Dictionary=src.duplicate(true);d.x=door_x(d);doors.append(d)
		var x:float=d.x
		var target:=str(World.ROOMS[str(d.to)].name)
		if d.side in ["left","right"]:
			var arch:=model("arch");world.add_child(arch);arch.position=Vector3(x,0,-.65);arch.scale=Vector3(.63,.78,.7)
			label3(("←  " if d.side=="left" else "→  ")+target,Vector3(x,3.85,.4),Color(.68,.86,.91),22)
		else:
			var up:bool=d.side=="up"
			var passage:=str(LevelDesign.profile(room_id)[3])
			if bool(d.get("hidden",false)) and passage!="pipe":passage="ladder"
			var is_lift:bool=passage=="lift"
			var low:=0.0 if up else -3.0
			var high:=5.8 if up else 0.0
			var run:=4.4 if up else 3.2
			var exit_x:=x+run*(-1 if x>room_width*.55 else 1)
			ladders.append({"x":x,"low":low,"high":high,"door":d,"lift":is_lift,"kind":passage,"exit_x":exit_x})
			if is_lift:
				for rail_x in [x-.85,x+.85]:
					cube(world,Vector3(rail_x,(low+high)*.5,-.8),Vector3(.12,high-low+1,.14),Color(.15,.7,.88),true)
					cube(world,Vector3(rail_x-.13,(low+high)*.5,-.95),Vector3(.2,high-low+1,.3),Color(.13,.17,.2))
				var lift:=model("lift");world.add_child(lift);lift.position=Vector3(x,0,0);lift.scale=Vector3(.66,1,.8)
				d["lift_node"]=lift
				audio.machine(lift,"lift",-27)
			elif passage=="stairs":
				var steps:=20 if up else 12
				for i in range(steps):
					var u:=float(i+1)/steps
					var sx:=lerpf(x,exit_x,u);var sy:=lerpf(0,high if up else low,u)
					var tread:=model("platform");world.add_child(tread);tread.position=Vector3(sx,sy,-1.4);tread.scale=Vector3(.16,.42,.5)
					if i%4==0:
						cube(world,Vector3(sx,sy+.6,-2.1),Vector3(.045,1.2,.045),Color(.38,.28,.15))
				var railing:=cube(world,Vector3((x+exit_x)*.5,(high if up else low)*.5+1.15,-2.1),Vector3(sqrt(run*run+pow(high-low,2)),.055,.055),Color(.54,.38,.18))
				railing.rotation.z=atan2(high if up else low,exit_x-x)
			elif passage=="pipe":
				var shaft:=model("pipe");world.add_child(shaft);shaft.position=Vector3(x,low,-1.35);shaft.scale=Vector3(4,(high-low)/4,4)
				for y in [low,high]:
					var rim:=MeshInstance3D.new();var ring:=TorusMesh.new();ring.inner_radius=.78;ring.outer_radius=1.02;rim.mesh=ring;rim.material_override=mat(Color(.12,.37,.28));world.add_child(rim);rim.position=Vector3(x,y,.0)
				var rail:=model("ladder");world.add_child(rail);rail.position=Vector3(x,low,-.2);rail.scale.y=(high-low)/4
			else:
				var ladder:=model("ladder");world.add_child(ladder);ladder.position=Vector3(x,low,-.30);ladder.scale.y=(high-low)/4
			cube(world,Vector3(x,(low+high)*.5,-1.25),Vector3(2,high-low+1,.35),Color(.038,.055,.07))
			if up:
				deck(exit_x if passage=="stairs" else x+1.5,5.8,1.6)
				# The rail itself is a guaranteed bidirectional route; ledges are optional.
				if passage!="stairs":deck(x+1.9,2.8,1.55)
			else:
				deck(exit_x if passage=="stairs" else x,-3.15,2.0)
				for lip in [-1.05,1.05]:cube(world,Vector3(x+lip,.06,0),Vector3(.13,.15,2.9),Color(.95,.52,.08))
			label3(("↑ W" if up else "↓ S")+" · "+{"lift":"升降机","stairs":"楼梯","pipe":"排水管","ladder":"检修梯"}[passage],Vector3(x,2.6,1),Color(.96,.7,.25),29)
			label3(target,Vector3(x,2.15,1),Color(.71,.82,.85),22)

func build_background(theme: String) -> void:
	preload("res://remaster/scenery.gd").build(self,theme)

func build_machines() -> void:
	if room.theme=="water":
		var water_mesh:=cube(world,Vector3(room_width*.5,.36,.1),Vector3(room_width-4,.035,2.4),Color(.04,.4,.36))
		var shader:=Shader.new();shader.code="shader_type spatial; render_mode blend_mix, cull_disabled; uniform float time_scale = 1.0; void vertex(){VERTEX.y += sin(VERTEX.x*3.0+TIME*2.0)*0.045;} void fragment(){ALBEDO=vec3(0.03,0.38,0.36);METALLIC=0.55;ROUGHNESS=0.15;ALPHA=0.42;EMISSION=vec3(0.0,0.07,0.055);}"
		var sm:=ShaderMaterial.new();sm.shader=shader;water_mesh.material_override=sm
	if room_id in ["factory_conveyor","factory_assembly","mine","castle_shaft","void_hangar"]:
		var m:=AnimatableBody3D.new();world.add_child(m);m.collision_layer=1;m.collision_mask=0
		var shape:=CollisionShape3D.new();var b:=BoxShape3D.new();b.size=Vector3(3,.35,2.6);shape.shape=b;shape.position.y=-.18;m.add_child(shape)
		var art:=model("lift");m.add_child(art);art.scale=Vector3(.94,1,.9)
		var base:=Vector3(room_width*.53,.7,0);m.position=base
		movers.append({"node":m,"base":base});audio.machine(m,"lift",-23)
	var hazard:=str(LevelDesign.profile(room_id)[2])
	if hazard in ["steam","rune","pulse"] and not room.has("boss"):
		var x:=safe_ground_spawn(room_width*.56).x
		var tint:Color={"steam":Color(1,.40,.08),"rune":Color(.35,.7,1),"pulse":Color(.64,.25,1)}[hazard]
		var pad:=cube(world,Vector3(x,.055,0),Vector3(1.5,.09,2.5),tint.darkened(.78))
		var beam:=cube(world,Vector3(x,1.7,0),Vector3(.16,3.4,.1),tint,true);beam.visible=false
		var title:=label3({"steam":"蒸汽喷口","rune":"脉冲符文","pulse":"虚空电弧"}[hazard]+" · 等待熄灭",Vector3(x,3.7,0),tint,22)
		hazards.append({"x":x,"phase":0.0,"pad":pad,"beam":beam,"color":tint,"label":title})

func build_interactables() -> void:
	save_position=Vector3(-999,0,0)
	if room.has("save") or room.has("boss") or room_id=="hub":
		var x:=3.8
		if room.has("save"):x=clampf(float(room.save.x)/64.0,2.5,room_width-3)
		save_position=Vector3(x,0,0)
		var station:=model("console");world.add_child(station);station.position=save_position+Vector3(0,0,-.65)
		label3("E  同步存档 / 补给",save_position+Vector3(0,2.7,0),Color(.31,.94,.95),24)
	if room_id=="hub":
		merchant_position=Vector3(8,0,0)
		var npc:=model("merchant");world.add_child(npc);npc.position=merchant_position;npc.rotation.y=-.35
		var a:AnimationPlayer=npc.find_child("AnimationPlayer",true,false)
		if a and a.has_animation("idle"):a.get_animation("idle").loop_mode=Animation.LOOP_LINEAR;a.play("idle")
		label3("拾荒商人 · 赫克\nE  交谈 / 交易",merchant_position+Vector3(0,2.9,0),Color(.96,.71,.36),25)
		for i in range(3):cube(world,Vector3(9+i*.55,.35,-.8),Vector3(.5,.7,.7),Color(.27,.17,.08))
		label3("中央车站 / CENTRAL TERMINAL",Vector3(13,7,-2.5),Color(.72,.82,.83),42)
		var guide:=model("surveyor");world.add_child(guide);guide.position=npc_position;guide.rotation.y=-.45
		var animation:AnimationPlayer=guide.find_child("AnimationPlayer",true,false)
		if animation:animation.get_animation("idle").loop_mode=Animation.LOOP_LINEAR;animation.play("idle")
		label3("巡线员 · 莉娅\nE  交谈 / 委托",npc_position+Vector3(0,2.95,0),Color(.69,.95,.48),24)
	if room_id=="dawn_beacon":
		beacon_position=Vector3(room_width-4,0,0)
		var beacon:=model("console");world.add_child(beacon);beacon.position=beacon_position
		var tower:=model("beacon_tower");world.add_child(tower);tower.position=beacon_position+Vector3(-2,0,-4)
		beacon_glow=cube(world,tower.position+Vector3(0,4.8,0),Vector3(.8,.95,.8),Color(.8,1,.48),true)
		beacon_lamp=OmniLight3D.new();world.add_child(beacon_lamp);beacon_lamp.position=beacon_glow.position;beacon_lamp.light_color=Color(.85,1,.55);beacon_lamp.light_energy=4;beacon_lamp.omni_range=13
		beacon_label=label3("",beacon_position+Vector3(0,3,0),Color(.8,1,.5),25)
		update_beacon_visual()
	var sources:Array=room.get("items",[]).duplicate()
	if room.get("hidden_room",false):sources.append([room_width*32,float(room.bounds[3])-45,"chest",""])
	for i in range(sources.size()):
		var p:Array=sources[i];var id:=room_id+":"+str(i)
		if Reforged.collected.has(id):continue
		var x:=clampf(float(p[0])/64.0,3,room_width-3)
		if not platforms.is_empty() and str(p[2])=="chest":x=platforms[platforms.size()-1].x
		var pos:=Vector3(x,surface_y(x,true)+.9,.1)
		var art:=model("amulet" if str(p[2])=="chest" else "ring");world.add_child(art);art.position=pos;art.scale=Vector3.ONE*.6
		pickups.append({"id":id,"pos":pos,"node":art,"chest":str(p[2])=="chest"})

func spawn_enemy(kind: String, pos: Vector3, is_boss := false) -> Node3D:
	var e:=CharacterBody3D.new();e.set_script(EnemyScript);e.game=self;e.kind=kind;e.is_boss=is_boss;e.position=pos
	e.max_hp=65.0+float(Reforged.level-1)*3
	world.add_child(e);enemies.append(e);return e

func _physics_process(dt: float) -> void:
	if not is_instance_valid(player) or ui.panel_open or transitioning:return
	for pair in [["r_left","move"],["r_right","move"],["r_jump","jump"],["r_dash","dash"],["r_attack","attack"]]:
		if controls.just_pressed(pair[0]) and not Reforged.tutorial.get(pair[1],false):Reforged.tutorial[pair[1]]=true;Reforged.save_game()
	time+=dt;transition_cooldown=maxf(0,transition_cooldown-dt)
	for strike in strikes.duplicate():
		strike.remaining-=dt
		if is_instance_valid(strike.node):strike.node.scale.y=1.0+sin(strike.remaining*18)*.10
		if strike.remaining<=0:
			var pos:Vector3=strike.pos
			burst(pos+Vector3.UP*.25,strike.color,22);audio.play("explosion",-12);shake=.1
			var height:=4.4 if bool(strike.column) else 1.0
			if absf(player.position.x-pos.x)<float(strike.width)*.5 and player.position.y<pos.y+height and player.position.y>pos.y-1.8:player.take_damage(strike.damage,signf(player.position.x-pos.x))
			companions.area_damage(pos,float(strike.width)*.5,height,strike.damage)
			if bool(strike.column):
				var pillar:=cube(world,pos+Vector3.UP*2.2,Vector3(.20,4.4,.20),strike.color,true)
				var tw:=pillar.create_tween();tw.tween_property(pillar,"scale",Vector3(.05,1,.05),.25);tw.tween_callback(pillar.queue_free)
			strike.node.queue_free();strike.label.queue_free();strikes.erase(strike)
	for m in movers:
		m.node.position=m.base+Vector3(0,(sin(time*.6)+1)*2.3,0)
	for d in doors:
		if d.has("lift_node") and is_instance_valid(d.lift_node):
			var target:=player.position.y if player.climbing and absf(player.climb_x-float(d.x))<.1 else 0.0
			d.lift_node.position.y=move_toward(d.lift_node.position.y,target,dt*5)
	for h in hazards:
		var cycle:=fmod(time,4.8)
		h.beam.visible=cycle>3.4
		h.pad.material_override=mat(h.color if cycle>2.3 else h.color.darkened(.78),cycle>2.3)
		h.beam.transparency=.68
		if cycle>3.4:
			if int(time*16)%3==0:burst(Vector3(h.x,.4,0),Color(1,.42,.14),2)
			if absf(player.position.x-float(h.x))<.8 and player.position.y<3.4:player.take_damage(16,signf(player.position.x-float(h.x)))
			companions.area_damage(Vector3(h.x,0,0),.8,3.4,16)
	for p in pickups.duplicate():
		if not is_instance_valid(p.node):continue
		p.node.rotation.y+=dt
		if player.position.distance_to(p.pos)<1.55:
			Reforged.collected[p.id]=true;Reforged.coins+=55 if p.chest else 10
			if p.chest:Reforged.inventory.append(Reforged.make_item(Reforged.SLOTS[randi()%6],1))
			toast("发现精工装备与金币" if p.chest else "+10 金币");audio.play("save",-9)
			p.node.queue_free();pickups.erase(p);Reforged.commit()
	var in_water:bool=room.theme=="water" and player.position.y<.35 and player.position.x>2 and player.position.x<room_width-2
	if in_water != player.water:
		audio.play("splash");burst(player.position,Color(.1,.65,.7),16);player.water=in_water
	var hint:=""
	if room_id=="hub" and player.position.distance_to(npc_position)<1.65:
		ui.hint.text=controls.prompt("E  与莉娅交谈 · 晨曦温室委托")
		if controls.just_pressed("r_interact"):ui.open_npc()
		return
	if room_id=="dawn_beacon" and player.position.distance_to(beacon_position)<1.8:
		ui.hint.text=controls.prompt("E  重启引航灯")
		if controls.just_pressed("r_interact"):activate_beacon()
		return
	var nearest_door:Dictionary={}
	var interaction_distance:=player.position.distance_to(save_position)
	if room_id=="hub":interaction_distance=minf(interaction_distance,player.position.distance_to(merchant_position))
	for d in doors:
		if d.side not in ["left","right"] or player.position.y>1.5:continue
		var distance:=player.position.distance_to(Vector3(float(d.x),0,0))
		if distance<1.5 and distance<interaction_distance:
			nearest_door=d;interaction_distance=distance
	if not nearest_door.is_empty():
		hint="E  前往 "+str(World.ROOMS[str(nearest_door.to)].name)
		if controls.just_pressed("r_interact"):use_door(nearest_door)
	elif player.position.distance_to(save_position)<1.8:
		hint="E  同步存档 · 恢复生命、药剂和弹药"
		if controls.just_pressed("r_interact"):
			Reforged.rest(room_id,save_position+Vector3(.85,.08,0));audio.play("save");toast("存档已同步 · 死亡后将返回这里")
	elif room_id=="hub" and player.position.distance_to(merchant_position)<2:
		hint="E  与赫克交易 · 装备回收 / 回购"
		if controls.just_pressed("r_interact"):
			var gift:=Reforged.first_trade();ui.open_shop()
			if gift:toast("赫克：带上余烬护符，打赢了就能吸回一点血。已赠送并装备。",6)
	ui.hint.text=controls.prompt(hint)

func _process(dt: float) -> void:
	if not is_instance_valid(player):return
	for gear in gears:
		if is_instance_valid(gear):gear.rotation.z+=dt*.13
	var target:=Vector3(clampf(player.position.x+player.facing*1.5,8,room_width-8),maxf(4.8,player.position.y+2.5),21)
	camera.position=camera.position.lerp(target,1.0-exp(-dt*5))
	shake=maxf(0,shake-dt)
	if shake>0:camera.position+=Vector3(randf_range(-shake,shake),randf_range(-shake,shake),0)*float(Reforged.settings.shake)
	if capture_timer>0:
		capture_timer-=dt
		if capture_timer<=0:
			player.set_physics_process(false);player.visual.visible=true
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var result:=get_viewport().get_texture().get_image().save_png(capture_path)
			print("REMASTER_CAPTURE ",result," ",capture_path)
			# Let the scene and its active audio players release before the engine
			# exits. The timer belongs to SceneTree and survives this scene.
			get_tree().create_timer(.25).timeout.connect(get_tree().quit.bind(0 if result==OK else 1))
			queue_free()

func try_climb(vertical: float) -> bool:
	if transition_cooldown>0:return false
	for l in ladders:
		if absf(player.position.x-float(l.x))>1.0:continue
		if vertical<0 and str(l.door.side)=="up" and player.position.y<.35:continue
		if vertical<0 and str(l.door.side)=="down" and absf(player.position.y-float(l.low))<.4:
			use_door(l.door);return true
		if vertical>0 and str(l.door.side)=="up" and absf(player.position.y-float(l.high))<.4:
			use_door(l.door);return true
		if vertical>0 and player.position.y>=float(l.high)-.05:continue
		if vertical<0 and player.position.y<=float(l.low)+.05:continue
		if player.position.y<float(l.low)-.3 or player.position.y>float(l.high)+.4:continue
		if gate_reason(str(l.door.to))!="":toast(gate_reason(str(l.door.to)));return false
		player.climbing=true;player.climb_x=l.x;player.climb_low=l.low;player.climb_high=l.high;player.climb_door=l.door
		player.climb_lift=bool(l.lift)
		player.climb_kind=str(l.get("kind","ladder"));player.climb_start_y=0.0
		player.climb_entry_x=l.x;player.climb_exit_x=float(l.get("exit_x",l.x))
		if player.climb_kind=="stairs":player.facing=signf(player.climb_exit_x-player.climb_entry_x)
		player.velocity=Vector3.ZERO;player.position.x=l.x
		if l.lift:audio.play("lift",-9)
		return true
	return false

func gate_reason(target: String) -> String:
	if target=="castle_gate" and not Reforged.bosses.has("void_throne"):
		return "王城封印：先击败虚空要塞·天龙王座的天龙机甲"
	if target=="void_throne":
		for id in ["temple_sanctum","mine_boss","water_boss","boss"]:
			if not Reforged.bosses.has(id):return "天龙王座需要四枚区域核心：神殿 / 矿坑 / 水道 / 铸造厂"
	if room_id=="castle_knights" and target=="castle_shaft" and not Reforged.bosses.has("castle_knights"):
		return "击败铸魂骑士团后，君王升降井才会开启"
	return ""

func use_door(d: Dictionary) -> void:
	if transitioning or transition_cooldown>0:return
	var reason:=gate_reason(str(d.to))
	if reason!="":toast(reason);player.climbing=false;return
	transitioning=true;player.lock_input=true;Reforged.save_game()
	var previous:=room_id
	await ui.fade(true)
	load_room(str(d.to),previous)
	await ui.fade(false)
	player.lock_input=false

func respawn() -> void:
	Reforged.respawn();load_room(Reforged.checkpoint_room,"",true)
	toast("从存档点重生 · "+str(World.ROOMS[room_id].name))

func boss_defeated(e: Node3D) -> void:
	for strike in strikes:
		strike.node.queue_free();strike.label.queue_free()
	strikes.clear()
	if audio.has_method("set_region"):audio.set_region(str(room.theme),false)
	Reforged.bosses[room_id]=true;Reforged.reward(true);toast("核心回收 · "+e.boss_name+"  |  +150 金币",5)
	if room_id=="castle_throne":ui.show_ending.call_deferred()

func objective() -> String:
	if Reforged.story.get("beacon_accepted",false) and not Reforged.story.get("beacon_claimed",false):
		if Reforged.story.get("beacon_online",false):return "委托：返回中央车站，向莉娅报告\nN 查看任务 / M 查看地图"
		var next:=next_hop(room_id,"dawn_beacon")
		return "委托：重启晨曦温室的引航灯\n"+("清理守卫，在终端按 E" if room_id=="dawn_beacon" else "路线 → "+str(World.ROOMS[next].name) if next!="" else "M 查看地图")
	return main_objective()

func activate_beacon() -> bool:
	if room_id!="dawn_beacon":return false
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead:toast("先清理灯塔里的失控守卫，再重启终端。");return false
	if not Reforged.story.get("beacon_online",false):
		Reforged.story["beacon_online"]=true;Reforged.commit();audio.play("save");burst(beacon_position+Vector3.UP,Color(.7,1,.4),36)
	update_beacon_visual()
	toast("引航灯已重启 · 返回中央车站向莉娅报告",5);return true

func update_beacon_visual() -> void:
	if room_id!="dawn_beacon" or not is_instance_valid(beacon_lamp):return
	var online:bool=Reforged.story.get("beacon_online",false)
	beacon_lamp.visible=online;beacon_glow.visible=online
	beacon_label.text="引航灯已重启\n返回车站向莉娅报告" if online else "引航终端\nE  清理守卫后重启"

func main_objective() -> String:
	if not Reforged.merchant_gift:return "与中央车站的赫克交谈，领取余烬护符"
	for id in ["temple_sanctum","mine_boss","water_boss","boss","void_throne","castle_knights","castle_throne"]:
		if not Reforged.bosses.has(id):
			var next:=next_hop(room_id,id)
			return "回收核心："+str(World.ROOMS[id].name)+( "\n路线 → "+str(World.ROOMS[next].name) if next!="" and next!=room_id else "\n观察橙色前摇，利用跳跃与冲刺反击")
	return "光核已重启 · 探索七处秘室，完成机械城图鉴"

func next_hop(start: String, target: String) -> String:
	if start==target:return start
	var q:Array=[start];var previous:Dictionary={start:""}
	while not q.is_empty():
		var id:String=q.pop_front()
		for d in World.ROOMS[id].get("doors",[]):
			var dest:=str(d.to)
			if previous.has(dest):continue
			previous[dest]=id
			if dest==target:
				while previous[dest]!=start:dest=previous[dest]
				return dest
			q.append(dest)
	return ""

func toast(message: String, seconds := 3.2) -> void:
	ui.toast(message,seconds)

func clear_sight(a: Vector3, b: Vector3) -> bool:
	var q:=PhysicsRayQueryParameters3D.create(a,b,1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func projectile(pos: Vector3, vel: Vector3, damage: float, friendly: bool, color: Color, piercing := false, lifesteal := true) -> void:
	var p:=Node3D.new();p.set_script(ProjectileScript);p.game=self;p.position=pos;p.velocity=vel;p.damage=damage;p.friendly=friendly;p.piercing=piercing;p.lifesteal=lifesteal
	# Check the first shot segment from the hunter to the barrel, so a nearby
	# enemy cannot be skipped when the rendered barrel extends past its body.
	if friendly and lifesteal:p.sweep_origin=Vector3(player.position.x,pos.y,0)
	world.add_child(p);cube(p,Vector3.ZERO,Vector3(.7,.15,.15) if not piercing else Vector3(.4,1.5,.18),color,true)
	var light:=OmniLight3D.new();p.add_child(light);light.light_color=color;light.light_energy=.65;light.omni_range=2

func burst(pos: Vector3, color: Color, count: int) -> void:
	var p:=CPUParticles3D.new();world.add_child(p);p.position=pos;p.amount=count;p.lifetime=.48;p.one_shot=true;p.explosiveness=.95
	p.direction=Vector3.UP;p.spread=140;p.initial_velocity_min=2;p.initial_velocity_max=6;p.gravity=Vector3(0,-12,0)
	var mesh:=BoxMesh.new();mesh.size=Vector3(.055,.055,.14);mesh.material=mat(color,true);p.mesh=mesh;p.emitting=true
	var t:=create_tween();t.tween_interval(.9);t.tween_callback(p.queue_free)

func slash(pos: Vector3, _direction: float, color: Color, radius: float) -> void:
	# Open arc with a tapered leading edge; the arc lies in the combat plane.
	var verts:=PackedVector3Array();var colors:=PackedColorArray()
	for i in range(24):
		var angle_a:=lerpf(-1.2,1.45,float(i)/24);var angle_b:=lerpf(-1.2,1.45,float(i+1)/24)
		var inner:=radius*(.72+float(i)/24*.18)
		for v in [Vector3(cos(angle_a)*radius*_direction,sin(angle_a)*radius,0),Vector3(cos(angle_b)*radius*_direction,sin(angle_b)*radius,0),Vector3(cos(angle_a)*inner*_direction,sin(angle_a)*inner,0),Vector3(cos(angle_b)*radius*_direction,sin(angle_b)*radius,0),Vector3(cos(angle_b)*inner*_direction,sin(angle_b)*inner,0),Vector3(cos(angle_a)*inner*_direction,sin(angle_a)*inner,0)]:
			verts.append(v);colors.append(Color(color,1.0-float(i)/28))
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=verts;arrays[Mesh.ARRAY_COLOR]=colors
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.vertex_color_use_as_albedo=true;material.emission_enabled=true;material.emission=color;material.emission_energy_multiplier=1.6
	var m:=MeshInstance3D.new();m.mesh=mesh;m.material_override=material;world.add_child(m);m.position=pos+Vector3(0,0,.35)
	var tw:=m.create_tween();tw.tween_property(m,"scale",Vector3(1.25,1.25,1),.13);tw.parallel().tween_property(m,"transparency",1.0,.17);tw.tween_callback(m.queue_free)

func trail(pos: Vector3, color: Color) -> void:
	var m:=cube(world,pos,Vector3(.18,1.3,.15),color,true)
	var tw:=create_tween();tw.tween_property(m,"scale",Vector3.ONE*.01,.18);tw.tween_callback(m.queue_free)

func telegraph(pos: Vector3, width: float, duration: float, attack: String) -> void:
	var m:=cube(world,pos,Vector3(width,.035,2.4),Color(.85,.18,.025),true)
	var l:=label3({"slam":"震地 · 跳跃躲避","charge":"冲锋 · 越过敌人","beam":"低位弹幕 · 跳跃","volley":"瞄准 · 移动躲避","summon":"召唤增援","melee":"近战起手","lunge":"骑士突刺 · 越过敌人","combo":"连续斩击 · 拉开距离","dive":"锁定俯冲 · 离开落点","bite":"巨鳄撕咬 · 后退","tail":"尾部蓄力 · 准备跳跃","tide":"潮汐 · 跳跃","rune":"符文唤醒 · 观察落点","rift":"空间撕裂 · 观察落点","rocks":"岩层崩落 · 持续移动","furnace":"炉压上升 · 避开喷口"}.get(attack,"预警"),pos+Vector3(0,1.2,0),Color(1,.51,.15),24)
	var tw:=m.create_tween();tw.tween_interval(duration);tw.tween_callback(l.queue_free);tw.tween_callback(m.queue_free)

func schedule_strike(pos: Vector3, width: float, delay: float, damage: float, color: Color, message: String, column := false) -> void:
	var marker:=cube(world,pos+Vector3.UP*.035,Vector3(width,.035,2.4),color.darkened(.25),true)
	var title:=label3(message,pos+Vector3.UP*1.7,Color(1,.73,.42),22)
	strikes.append({"pos":pos,"width":width,"remaining":delay,"damage":damage,"color":color,"node":marker,"label":title,"column":column})

func damage_number(pos: Vector3, value: int) -> void:
	var l:=label3(str(value),pos,Color(1,.84,.39),32)
	var tw:=create_tween();tw.tween_property(l,"position",pos+Vector3(0,1,0),.6);tw.parallel().tween_property(l,"modulate:a",0,.6);tw.tween_callback(l.queue_free)
