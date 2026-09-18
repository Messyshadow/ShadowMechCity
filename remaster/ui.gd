extends CanvasLayer
const World=preload("res://remaster/world_data.gd")
const Experience=preload("res://remaster/experience_ui.gd")
const MapScript=preload("res://remaster/map.gd")
var game: Node3D
var root: Control
var hud: Control
var panel: Control
var panel_open := false
var panel_kind := ""
var health: ProgressBar
var hp_label: Label
var stats: Label
var ammo: Label
var objective_label: Label
var room_label: Label
var hint: Label
var toast_label: Label
var toast_time := 0.0
var boss_health: ProgressBar
var boss_title: Label
var transition: ColorRect
var banner: Label
var banner_time := 0.0
var skill_preview: AnimationPlayer
var preview_weapon: Node3D
var title_new_armed := false
var preview_model: Node3D
var preview_socket: Node3D
var map_view: Control
var preview_family := ""
var preview_offhand: Node3D
var skill_page := "战斗"
var skill_family := 0
var skill_selection := ""
var settings_return := "pause"
var tutorial_label: Label
var tutorial_back: Panel
var squad_label:Label
var squad_back:Panel
var companion_selection:="hound"
var keyboard_hint:Label
var menu_hint:Label
var shown_gamepad := false
var guide_return := "pause"
const CONTROLLER_PAGES := ["inventory","skills","map","journal","companions"]
const INK:=Color(.027,.043,.062,.97)
const CYAN:=Color(.22,.83,.91)
const GOLD:=Color(.97,.68,.28)
const TEXT:=Color(.82,.88,.92)

func _ready() -> void:
	layer=10
	root=Control.new();add_child(root);root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var theme:=Theme.new();theme.default_font_size=18
	var font:=SystemFont.new();font.font_names=PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","Noto Sans CJK SC"])
	theme.default_font=font;root.theme=theme
	hud=Control.new();root.add_child(hud);hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var status:=plate(hud,Rect2(24,22,308,114))
	hp_label=text(status,"猎魂者 / HUNTER",Vector2(16,10),16,GOLD)
	health=bar(status,Rect2(16,43,276,9),CYAN)
	stats=text(status,"",Vector2(16,65),15,TEXT)
	ammo=text(hud,"",Vector2(27,151),17,TEXT)
	room_label=text(hud,"",Vector2(860,24),20,CYAN);room_label.size=Vector2(393,30);room_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	objective_label=text(hud,"",Vector2(874,63),15,TEXT);objective_label.size=Vector2(380,100);objective_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint=text(hud,"",Vector2(220,568),20,GOLD);hint.size=Vector2(840,36);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var keys:=plate(hud,Rect2(24,651,1232,47))
	keyboard_hint=text(keys,"",Vector2(16,5),15,TEXT)
	menu_hint=text(keys,"",Vector2(16,26),12,Color(.62,.73,.80))
	tutorial_back=plate(hud,Rect2(24,202,340,98),Color(.027,.043,.062,.85));tutorial_back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tutorial_label=text(tutorial_back,"",Vector2(12,9),16,GOLD);tutorial_label.size=Vector2(316,83);tutorial_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	squad_back=plate(hud,Rect2(24,312,318,109),Color(.027,.043,.062,.84));squad_back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	squad_label=text(squad_back,"",Vector2(10,8),14,Color(.66,.9,.86))
	toast_label=text(root,"",Vector2(175,610),18,GOLD);toast_label.size=Vector2(930,36);toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	boss_title=text(hud,"",Vector2(360,535),17,GOLD);boss_title.size=Vector2(560,26);boss_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	boss_health=bar(hud,Rect2(360,562,560,7),Color(.95,.34,.16))
	banner=text(hud,"",Vector2(330,181),29,TEXT);banner.size=Vector2(620,70);banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	transition=ColorRect.new();root.add_child(transition);transition.color=Color(0,0,0,0);transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);transition.mouse_filter=Control.MOUSE_FILTER_IGNORE

func plate(parent: Node, rect: Rect2, color := INK) -> Panel:
	var p:=Panel.new();parent.add_child(p);p.position=rect.position;p.size=rect.size
	p.add_theme_stylebox_override("panel",style(color,Color(.18,.29,.35)))
	return p

func style(bg: Color, border: Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(1);s.set_corner_radius_all(5)
	s.content_margin_left=14;s.content_margin_right=14;s.content_margin_top=7;s.content_margin_bottom=7
	return s

func text(parent: Node, value: String, pos: Vector2, font_size := 18, color := TEXT) -> Label:
	var l:=Label.new();parent.add_child(l);l.text=game.controls.prompt(value);l.position=pos;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if not value.is_empty():l.set_meta("prompt_source",value)
	return l

func button(parent: Node, value: String, rect: Rect2, action: Callable, accent := false) -> Button:
	var b:=Button.new();parent.add_child(b);b.text=value;b.position=rect.position;b.size=rect.size
	b.set_meta("prompt_source",value);b.text=game.controls.prompt(value)
	b.add_theme_font_size_override("font_size",16)
	b.add_theme_stylebox_override("normal",style(Color(.07,.14,.18) if accent else Color(.045,.073,.095),CYAN if accent else Color(.2,.3,.36)))
	b.add_theme_stylebox_override("hover",style(Color(.12,.22,.26),GOLD))
	var focus_style:=style(Color(.09,.17,.22),GOLD);focus_style.set_border_width_all(3);b.add_theme_stylebox_override("focus",focus_style)
	b.add_theme_stylebox_override("pressed",style(Color(.12,.3,.35),CYAN));b.pressed.connect(action);return b

func bar(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var p:=ProgressBar.new();parent.add_child(p);p.position=rect.position;p.size=rect.size;p.show_percentage=false
	var bg:=style(Color(.06,.12,.16),Color(.12,.19,.23));var fg:=style(color,color)
	for box in [bg,fg]:box.content_margin_top=0;box.content_margin_bottom=0
	p.add_theme_stylebox_override("background",bg)
	p.add_theme_stylebox_override("fill",fg);p.size=rect.size;return p

func icon(parent: Node, id: String, rect: Rect2) -> TextureRect:
	var path:="res://remaster/assets/icons/"+id+".png"
	var t:=TextureRect.new();parent.add_child(t);t.position=rect.position;t.size=rect.size;t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(path):t.texture=load(path)
	return t

func _process(dt: float) -> void:
	if not is_instance_valid(game.player):return
	if shown_gamepad!=game.controls.gamepad:
		shown_gamepad=game.controls.gamepad
		for node in root.find_children("*","Control",true,false):
			if node.has_meta("prompt_source"):node.text=game.controls.prompt(str(node.get_meta("prompt_source")))
			if shown_gamepad and node.has_meta("gamepad_source"):node.text=str(node.get_meta("gamepad_source"))
			if node.has_meta("controller_footer"):node.visible=shown_gamepad
		if is_instance_valid(game.world):
			for node in game.world.find_children("*","Label3D",true,false):
				if node.has_meta("prompt_source"):node.text=game.controls.prompt(str(node.get_meta("prompt_source")))
	keyboard_hint.text="左摇杆 / 方向键 移动与攀爬    A 跳跃    X 普攻    Y 技能    B 冲刺    LB 换武器    RB 交互" if game.controls.gamepad else "A D 移动    空格 二段跳 / 蹬墙    W S 梯井 / 升降机    J 连击    K 技能    Shift 冲刺    Q 换武器    R 装填    H 治疗"
	menu_hint.text="LT 治疗    RT 装填    L3 伙伴部署 / 回收    R3 阵容    View 背包（LB / RB 切页面）    Menu 暂停" if game.controls.gamepad else "E 交互       I 背包       T 技能       M 地图       N 任务       Esc 暂停       F11 全屏"
	if is_instance_valid(preview_weapon) and preview_family in ["cannon","crossbow"]:preview_weapon.global_rotation=Vector3(PI/2,0,0)
	if is_instance_valid(preview_weapon) and preview_family=="spear":preview_weapon.global_rotation=Vector3(0,0,-PI/2+.15)
	if is_instance_valid(game.companions):
		squad_label.text=game.controls.prompt(game.companions.hud_text());squad_back.size.y=35+Reforged.squad.loadout.size()*21 if Reforged.squad.deployed else 35
	health.max_value=Reforged.max_health();health.value=Reforged.hp
	hp_label.text="猎魂者  %d / %d"%[ceili(Reforged.hp),int(Reforged.max_health())]
	stats.text="Lv.%02d    ◈ %d    技能点 %d    药剂 %d"%[Reforged.level,Reforged.coins,Reforged.points,Reforged.potions]
	ammo.text=Reforged.WEAPON_NAMES[Reforged.weapon]+("    弹匣 %d / 8  ·  备弹 %d"%[Reforged.magazine,Reforged.ammo] if Reforged.weapon in [2,6] else "    J 连击 / 空中攻击")
	if game.player.reload_time>0:ammo.text+="  装填中…"
	ammo.text=game.controls.prompt(ammo.text)
	var step:Array=Reforged.tutorial_step()
	tutorial_label.visible=bool(Reforged.settings.tutorial) and not step.is_empty() and not panel_open
	tutorial_back.visible=tutorial_label.visible
	if not step.is_empty():tutorial_label.text=game.controls.prompt("旅途提示\n"+str(step[1]))
	room_label.text=str(game.room.get("name",""))
	objective_label.text="当前目标 / OBJECTIVE\n"+game.objective()
	boss_health.visible=is_instance_valid(game.boss) and not game.boss.dead and not panel_open
	boss_title.visible=boss_health.visible
	if boss_health.visible:
		boss_title.text=game.boss.boss_name+"  /  阶段 "+str(game.boss.phase)
		boss_health.max_value=game.boss.max_hp;boss_health.value=game.boss.hp
	toast_time=maxf(0,toast_time-dt);toast_label.visible=toast_time>0
	toast_label.position.y=4 if panel_open else 610
	banner_time=maxf(0,banner_time-dt);banner.visible=banner_time>0 and not panel_open;banner.modulate.a=minf(1,banner_time)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F11:
		Reforged.set_setting("fullscreen",not Reforged.settings.fullscreen)
		if panel_kind=="settings":open_settings(settings_return)
		get_viewport().set_input_as_handled();return
	if Reforged.save_blocked:
		if event.is_action_pressed("r_pause"):open_title();get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("r_roster"):
		if panel_kind=="companions":close()
		else:open_companions()
		get_viewport().set_input_as_handled();return
	if event.is_action_pressed("r_journal"):
		if panel_kind=="journal":close()
		else:open_journal()
		get_viewport().set_input_as_handled();return
	if event.is_action_pressed("r_pause"):
		if panel_kind=="settings":return_from_settings()
		elif panel_open:close()
		else:open_pause()
		get_viewport().set_input_as_handled();return
	if event.is_action_pressed("r_inventory"):
		if panel_kind=="inventory":close()
		else:open_inventory()
	if event.is_action_pressed("r_skills"):
		if panel_kind=="skills":close()
		else:open_skills()
	if event.is_action_pressed("r_map"):
		if panel_kind=="map":close()
		else:open_map()
	if panel_kind=="title" and event is InputEventKey and event.pressed and event.physical_keycode==KEY_ENTER:continue_journey()

func toast(value: String, seconds := 3.2) -> void:
	toast_label.text=game.controls.prompt(value);toast_time=seconds;root.move_child(toast_label,-1)

func region_banner(value: String, theme: String) -> void:
	banner.text=value+"\n— "+theme.to_upper()+" —";banner_time=3.5

func fade(black: bool) -> void:
	root.move_child(transition,-1)
	var tw:=create_tween();tw.tween_property(transition,"color:a",1.0 if black else 0.0,.22);await tw.finished

func close(replacing := false) -> void:
	if Reforged.save_blocked and not replacing:open_save_recovery();return
	if panel_open:game.controls.suppress_held_actions()
	if panel:panel.queue_free();panel=null
	panel_open=false;panel_kind="";hud.visible=true;skill_preview=null;preview_model=null;preview_weapon=null;map_view=null
	preview_offhand=null;preview_family=""
	if is_instance_valid(game.world):game.world.process_mode=Node.PROCESS_MODE_INHERIT
	if is_instance_valid(game.player):game.player.process_mode=Node.PROCESS_MODE_INHERIT
	Reforged.save_game()

func shell(kind: String, title: String, subtitle: String) -> Control:
	var old_kind:=panel_kind
	var old_focus:=get_viewport().gui_get_focus_owner()
	var old_text:String=str(old_focus.get_meta("prompt_source","")) if is_instance_valid(old_focus) else ""
	var old_index:=controller_focusables().find(old_focus)
	close(true);panel_open=true;panel_kind=kind;hud.visible=false
	if is_instance_valid(game.world):game.world.process_mode=Node.PROCESS_MODE_DISABLED
	if is_instance_valid(game.player):game.player.process_mode=Node.PROCESS_MODE_DISABLED
	panel=Control.new();root.add_child(panel);panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade:=ColorRect.new();panel.add_child(shade);shade.color=Color(.006,.016,.029,.8);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body:=plate(panel,Rect2(54,40,1172,640))
	text(body,title,Vector2(28,20),30,TEXT);text(body,subtitle,Vector2(29,63),14,Color(.42,.61,.69))
	button(body,"返回  Esc" if kind=="settings" else "关闭  Esc",Rect2(1020,22,123,38),return_from_settings if kind=="settings" else continue_journey if kind=="title" else close)
	var footer:=text(panel,"",Vector2(54,686),14,TEXT)
	footer.text="A 确认 · B 返回 · 左摇杆 / 方向键选择"
	if kind=="settings":footer.text+=" · 左右调整设置滑块"
	if kind=="title":footer.text="A 确认 · 左摇杆 / 方向键选择 · 游戏中按 Menu 暂停，View 打开背包"
	if kind in CONTROLLER_PAGES:footer.text="A 确认 · B 返回 · 左摇杆 / 方向键选择 · LB / RB 切换背包、技能、地图、任务、伙伴"
	if kind=="map":footer.text="右摇杆移动地图 · LT 缩小 / RT 放大 · X 定位 / Y 全图 · A 确认 / B 返回 · LB / RB 切页面"
	footer.visible=game.controls.gamepad;footer.set_meta("controller_footer",true)
	restore_controller_focus.call_deferred(panel,old_text if kind==old_kind else "",old_index if kind==old_kind else -1)
	root.move_child(toast_label,-1)
	return body

func open_title() -> void:
	Experience.title(self)

func continue_journey() -> void:
	if Reforged.save_blocked:open_save_recovery();return
	if not Reforged.story.get("intro_seen",false):open_story()
	else:close()

func open_save_recovery() -> void:Experience.save_recovery(self)

func start_new_journey() -> void:
	if not title_new_armed:
		title_new_armed=true
		toast("再次点击开始新旅程：先保留损坏文件副本，再建立新进度。" if Reforged.save_blocked else "再次点击开始新旅程，将重置重制版进度。",6)
		return
	if not Reforged.begin_new_journey():toast("无法保留存档副本。原进度未更改，请检查存档目录是否可写。",8);return
	title_new_armed=false;game.load_room("hub","",true);open_story()

func open_settings(source := "pause") -> void:Experience.settings(self,source)
func return_from_settings() -> void:
	if settings_return=="title":open_title()
	else:open_pause()
func open_story() -> void:Experience.story(self)
func open_guide() -> void:
	guide_return=panel_kind;Experience.guide(self)
func open_journal() -> void:Experience.journal(self)
func open_npc() -> void:Experience.npc(self)
func open_companions() -> void:Experience.companions(self)

func open_pause() -> void:
	var body:=shell("pause","旅途暂停","PROGRESS SAVED  /  存档点决定重生位置")
	text(body,"当前存档点\n"+str(World.ROOMS[Reforged.checkpoint_room].name),Vector2(45,139),23,CYAN)
	button(body,"返回旅途",Rect2(45,242,300,48),close,true).grab_focus()
	button(body,"返回最后存档点",Rect2(45,309,300,45),func():close();game.respawn())
	button(body,"设置 · 音量 / 全屏 / 亮度",Rect2(45,371,300,45),func():open_settings("pause"))
	button(body,"任务与新手指南",Rect2(45,433,300,45),open_journal)
	button(body,"保存并返回主菜单",Rect2(45,495,300,45),open_title)
	button(body,"保存并退出",Rect2(45,556,300,40),game.quit_game)
	text(body,"生存指南\n\n连按 J 衔接连击，空中也能攻击。\n贴墙按空格可蹬墙；W / S 沿梯井攀爬。\n蒸汽炮弹药有限，R 装填，H 使用治疗剂。\n橙色地面表示敌人即将出招，跳跃或冲刺躲避。\n同步存档终端会补给，死亡返回该终端。",Vector2(450,146),20,TEXT)

func item_stats(it: Dictionary) -> String:
	var result:=""
	for key in ["attack","armor","health","lifesteal"]:
		var value:float=it.get(key,0)
		if value<=0:continue
		result+={"attack":"攻击 +","armor":"护甲 +","health":"生命 +","lifesteal":"吸血 "}[key]+("%d%%"%int(value*100) if key=="lifesteal" else str(value))+"   "
	return result

func item_icon(it: Dictionary) -> String:
	return "gauntlet" if it.slot=="gloves" else str(it.slot)

func item_scroll(parent: Control, rect: Rect2) -> VBoxContainer:
	var s:=ScrollContainer.new();parent.add_child(s);s.position=rect.position;s.size=rect.size;s.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	s.follow_focus=true
	var list:=VBoxContainer.new();s.add_child(list);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",8);return list

func item_row(list: VBoxContainer, it: Dictionary, mode: String) -> void:
	var row:=Panel.new();list.add_child(row);row.custom_minimum_size=Vector2(0,116 if mode=="inventory" else 91)
	row.add_theme_stylebox_override("panel",style(Color(.042,.066,.088),Color(.16,.26,.31)))
	icon(row,item_icon(it),Rect2(9,6,75,75))
	var rarity:Color=[Color(.7,.76,.8),CYAN,Color(.7,.47,1),GOLD][clampi(int(it.rarity),0,3)]
	text(row,str(it.name)+("  +"+str(it.upgrade) if int(it.get("upgrade",0))>0 else ""),Vector2(92,12),18,rarity)
	text(row,item_stats(it),Vector2(92,44),14,TEXT)
	var is_equipped:bool=int(Reforged.equipped.get(it.slot,{}).get("uid",-1))==int(it.uid)
	if mode=="inventory":
		button(row,"已装备" if is_equipped else "装备",Rect2(530,23,90,37),func():Reforged.equip_item(int(it.uid));open_inventory(),not is_equipped).disabled=is_equipped
		var current:Dictionary=Reforged.equipped.get(it.slot,{})
		var delta_text:="当前装备" if is_equipped else "替换后："
		if not is_equipped:
			for key in ["attack","armor","health"]:
				var delta:float=float(it.get(key,0))-float(current.get(key,0))
				if not is_zero_approx(delta):delta_text+={"attack":"攻击","armor":"护甲","health":"生命"}[key]+"%+.1f  "%delta
		text(row,delta_text,Vector2(92,78),13,CYAN)
		var cost:=Reforged.upgrade_cost(it)
		button(row,"已满级" if int(it.get("upgrade",0))>=5 else "强化 ◈%d"%cost,Rect2(514,70,108,31),func():
			if Reforged.upgrade_item(int(it.uid)):game.audio.play("save",-8)
			open_inventory()).disabled=int(it.get("upgrade",0))>=5 or Reforged.coins<cost
	elif mode=="sell":
		button(row,"已装备" if is_equipped else "出售 ◈"+str(it.price),Rect2(465,25,130,36),func():Reforged.sell(int(it.uid));open_shop("sell")).disabled=is_equipped
	else:
		button(row,"回购 ◈"+str(it.buyback_price),Rect2(465,25,130,36),func():
			if not Reforged.repurchase(int(it.uid)):toast("金币不足，物品仍保留在回购栏")
			open_shop("buyback"))

func open_inventory() -> void:
	var body:=shell("inventory","行者装备库","EQUIPMENT  /  装备对比 · 六个装备槽 · 强化最高 +5 · 出售后可向赫克回购")
	text(body,"◈ %d   |   Lv.%d   |   生命 %d   护甲 %.1f   攻击 %.1f"%[Reforged.coins,Reforged.level,int(Reforged.max_health()),Reforged.stat("armor"),Reforged.attack_damage()],Vector2(28,100),17,GOLD)
	var slot_names:=["面甲","胸甲","护手","铁靴","护符","戒指"]
	for i in range(6):
		var slot: String=Reforged.SLOTS[i];var it:Dictionary=Reforged.equipped.get(slot,{})
		var tile:=plate(body,Rect2(28+i*111,137,102,62),Color(.047,.081,.102))
		icon(tile,"gauntlet" if slot=="gloves" else slot,Rect2(3,8,40,40))
		text(tile,slot_names[i],Vector2(46,8),13,TEXT)
		text(tile,"空槽" if it.is_empty() else "已装备",Vector2(43,34),12,CYAN if not it.is_empty() else Color(.45,.5,.54))
		tile.tooltip_text="尚未装备" if it.is_empty() else str(it.name)+"\n"+item_stats(it)
	var list:=item_scroll(body,Rect2(28,213,665,389))
	for it in Reforged.inventory:item_row(list,it,"inventory")
	if Reforged.inventory.is_empty():text(body,"尚无装备，探索宝箱或到商人处购买。",Vector2(42,234),18,TEXT)
	make_preview(body,Rect2(740,124,370,305),"idle")
	text(body,"当前武器  /  "+Reforged.WEAPON_NAMES[Reforged.weapon],Vector2(738,454),20,CYAN)
	for i in range(4):
		icon(body,Reforged.WEAPONS[i],Rect2(735+i*95,494,78,78))
		button(body,str(i+1),Rect2(757+i*95,577,36,28),func():Reforged.weapon=i;open_inventory(),i==Reforged.weapon)

func open_shop(tab := "buy") -> void:
	var body:=shell("shop","赫克的拾荒铺","HEK'S SALVAGE  /  出售装备永久保留在独立回购栏，可按原出售价格买回")
	text(body,"◈ "+str(Reforged.coins)+" 金币",Vector2(942,78),20,GOLD)
	for i in range(3):
		var id:String=["buy","sell","buyback"][i]
		button(body,["购买补给","出售装备","回购物品"][i],Rect2(30+i*195,110,180,43),func():open_shop(id),tab==id)
	text(body,"「活着回来，货和故事我都收。」\n\n余烬护符："+("已领取" if Reforged.merchant_gift else "首次交谈赠送")+"\n\n持有药剂  %d / 9\n备用弹药  %d / 120\n\n已装备物品不会被出售。\n回购保留原属性与强化等级。\n同步终端提供最低补给。"%[Reforged.potions,Reforged.ammo],Vector2(775,199),17,TEXT)
	icon(body,"amulet",Rect2(840,442,150,150))
	if tab=="buy":
		var ids:=["potion","ammo","armor","gloves"]
		var labels:=["修复药剂","蒸汽弹药箱","精工胸甲","精工护手"]
		var prices:=[30,25,115,110]
		for i in range(4):
			var y:=179+i*104
			var row:=plate(body,Rect2(30,y,685,94));icon(row,["potion","cannon","armor","gauntlet"][i],Rect2(8,7,76,76))
			text(row,labels[i],Vector2(105,14),20,CYAN)
			text(row,["恢复 60 生命 / 上限 9 瓶","24 发备弹 / 上限 120 发","护甲 +2.5 / 生命 +9","攻击 +4"][i],Vector2(105,49),15,TEXT)
			var full:bool=(ids[i]=="ammo" and Reforged.ammo>=120) or (ids[i]=="potion" and Reforged.potions>=9)
			var affordable:bool=Reforged.coins>=prices[i]
			var purchase:=button(row,"已满" if full else "金币不足" if not affordable else "购买 ◈"+str(prices[i]),Rect2(520,25,135,39),func():
				var success:bool=Reforged.buy(ids[i]);open_shop("buy")
				toast("已购入 "+labels[i]+" · -%d 金币"%prices[i] if success else "金币不足或补给已满"),not full and affordable)
			purchase.disabled=full or not affordable
	else:
		var list:=item_scroll(body,Rect2(30,175,690,374))
		var items:Array=Reforged.inventory if tab=="sell" else Reforged.buyback
		for it in items:item_row(list,it,tab)
		if items.is_empty():text(body,"这里暂时没有物品。",Vector2(54,205),20,TEXT)
		if tab=="sell":button(body,"一键出售未装备白装",Rect2(30,565,285,42),func():
			var n:=Reforged.sell_white();open_shop("sell");toast("已出售 %d 件白装，可在回购栏找回"%n),true)

func make_preview(parent: Control, rect: Rect2, clip_name: String, model_id := "hero") -> void:
	var container:=SubViewportContainer.new();parent.add_child(container);container.position=rect.position;container.size=rect.size
	container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var viewport:=SubViewport.new();viewport.size=Vector2i(rect.size);container.add_child(viewport);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var world:=Node3D.new();viewport.add_child(world)
	var cam:=Camera3D.new();world.add_child(cam);cam.position=Vector3(2.3,1.4,4);cam.look_at(Vector3(0,1.05,0));cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.8
	var l:=DirectionalLight3D.new();world.add_child(l);l.rotation_degrees=Vector3(-35,-35,0);l.light_energy=2;l.light_color=Color(.5,.8,1)
	var fill:=DirectionalLight3D.new();world.add_child(fill);fill.rotation_degrees=Vector3(-15,130,0);fill.light_energy=1.4;fill.light_color=Color(1,.5,.2)
	if model_id!="hero":cam.size=3.3;cam.look_at(Vector3(0,1.3,0))
	if model_id.begins_with("ally_"):cam.size=2.0;cam.look_at(Vector3(0,.58,0))
	preview_model=game.model(model_id);world.add_child(preview_model)
	preview_socket=preview_model
	var skeletons:=preview_model.find_children("*","Skeleton3D",true,false)
	if not skeletons.is_empty() and model_id=="hero":
		var socket:=BoneAttachment3D.new();skeletons[0].add_child(socket);socket.bone_name="foreR";preview_socket=socket
	if model_id=="hero":
		preview_weapon=game.model(Reforged.WEAPONS[Reforged.weapon]);preview_socket.add_child(preview_weapon);preview_weapon.position=Vector3(0,.32,0);preview_weapon.rotation.x=-1.5;preview_weapon.scale=Vector3.ONE*.8
		preview_family=Reforged.WEAPONS[Reforged.weapon]
		update_preview_offhand()
	skill_preview=preview_model.find_child("AnimationPlayer",true,false)
	if skill_preview and skill_preview.has_animation(clip_name):
		skill_preview.get_animation(clip_name).loop_mode=Animation.LOOP_LINEAR;skill_preview.play(clip_name)

func preview_skill(id: String, notify := true) -> void:
	var clip_name:="crossbow_shoot" if id.begins_with("crossbow") else "shoot" if id.begins_with("cannon") else "uppercut" if id=="gauntlet_2" else "gauntlet_4" if id=="gauntlet_3" else "air_blade" if id=="blade_2" else "slam" if id=="hammer_3" else id
	if skill_preview and skill_preview.has_animation(clip_name):
		skill_preview.get_animation(clip_name).loop_mode=Animation.LOOP_LINEAR;skill_preview.play(clip_name,.1)
	if preview_weapon:preview_weapon.queue_free()
	preview_weapon=game.model(str(Reforged.SKILLS[id][2]));preview_socket.add_child(preview_weapon)
	preview_weapon.position=Vector3(0,.32,0);preview_weapon.rotation.x=-1.5;preview_weapon.scale=Vector3.ONE*.8
	preview_family=str(Reforged.SKILLS[id][2]);update_preview_offhand()
	if preview_family=="spear":
		var cameras:=preview_model.get_parent().find_children("*","Camera3D",false,false)
		if not cameras.is_empty():cameras[0].size=3.5;cameras[0].look_at(Vector3(.4,1.05,0))
	if notify:toast(str(Reforged.SKILLS[id][0])+"："+str(Reforged.SKILLS[id][1]),4)

func update_preview_offhand() -> void:
	if is_instance_valid(preview_offhand):preview_offhand.queue_free()
	if preview_family not in ["gauntlet","dual"]:return
	var skeletons:=preview_model.find_children("*","Skeleton3D",true,false)
	if skeletons.is_empty():return
	var socket:=BoneAttachment3D.new();skeletons[0].add_child(socket);socket.bone_name="foreL"
	preview_offhand=game.model(preview_family);socket.add_child(preview_offhand)
	preview_offhand.position=Vector3(0,.32,0);preview_offhand.rotation.x=-1.5;preview_offhand.scale=Vector3.ONE*.8

func open_skills() -> void:
	Experience.skills(self)

func open_map() -> void:
	var body:=shell("map","机械城 · 完整世界地图","WORLD ATLAS  /  滚轮缩放 · 左键拖动 · 保留完整房间名称")
	map_view=Control.new();map_view.set_script(MapScript);map_view.game=game;body.add_child(map_view);map_view.position=Vector2(25,111);map_view.size=Vector2(1122,443)
	map_view.center_player.call_deferred()
	button(body,"− 缩小",Rect2(28,575,125,37),func():map_view.set_zoom(map_view.zoom/1.2))
	button(body,"+ 放大",Rect2(168,575,125,37),func():map_view.set_zoom(map_view.zoom*1.2))
	button(body,"定位当前位置",Rect2(308,575,170,37),func():map_view.center_player(),true)
	button(body,"全图",Rect2(493,575,90,37),func():map_view.fit_all())
	text(body,"探索 %d / %d     核心 %d / 7     ◇ 最后存档点"%[Reforged.visited.size(),World.ROOMS.size(),Reforged.bosses.size()],Vector2(623,582),16,GOLD)

func show_ending() -> void:
	var body:=shell("ending","光核重新点亮","THE CITY BREATHES AGAIN")
	text(body,"机械城，醒来了。",Vector2(80,153),48,GOLD)
	text(body,"你切断了虚空君王的控制，七座炉心重新开始跳动。\n赫克的商铺会继续亮着灯，未探索的秘室仍等待着你。\n\n回收核心 %d / 7     探索房间 %d / %d\n等级 %d     倒下 %d 次"%[Reforged.bosses.size(),Reforged.visited.size(),World.ROOMS.size(),Reforged.level,Reforged.deaths],Vector2(85,247),22,TEXT)
	button(body,"继续探索机械城",Rect2(85,473,290,51),close,true)

func controller_focusables() -> Array[Control]:
	var result:Array[Control]=[]
	if not is_instance_valid(panel):return result
	for node in panel.find_children("*","Control",true,false):
		if (node is Button and not node.disabled) or node is HSlider:
			if node.is_visible_in_tree():result.append(node)
	return result

func restore_controller_focus(expected:Control,old_text:String,index:int) -> void:
	if not is_instance_valid(expected) or panel!=expected:return
	var items:=controller_focusables()
	if items.is_empty():return
	for item in items:
		if not old_text.is_empty() and str(item.get_meta("prompt_source",""))==old_text:item.grab_focus();return
	var owner:=get_viewport().gui_get_focus_owner()
	if owner in items and index<0:return
	items[clampi(index if index>=0 else 1,0,items.size()-1)].grab_focus()

func controller_move(direction:Vector2) -> void:
	var items:=controller_focusables()
	if items.is_empty():return
	var focus:=get_viewport().gui_get_focus_owner()
	if focus not in items:items[mini(1,items.size()-1)].grab_focus();return
	if focus is HSlider and direction.x!=0:
		focus.value+=direction.x*.05;return
	var origin:Vector2=focus.get_global_rect().get_center()
	var best:Control=null;var score:=INF
	for item in items:
		if item==focus:continue
		var delta:Vector2=item.get_global_rect().get_center()-origin
		var along:=delta.dot(direction)
		if along<1:continue
		var across:=absf(delta.cross(direction))
		var cost:=along+across*4
		if cost<score:best=item;score=cost
	if best==null:
		var offset:=1 if direction.x+direction.y>0 else -1
		best=items[posmod(items.find(focus)+offset,items.size())]
	best.grab_focus()

func controller_button(code:int) -> void:
	if code==JOY_BUTTON_B or code==JOY_BUTTON_START:
		if panel_kind=="settings":return_from_settings()
		elif panel_kind=="title":continue_journey()
		elif panel_kind in ["story","save_recovery"]:open_title()
		elif panel_kind=="guide":open_title() if guide_return=="title" else open_journal()
		elif panel_kind!="title":close()
		return
	if code in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER] and panel_kind in CONTROLLER_PAGES:
		var offset:=1 if code==JOY_BUTTON_RIGHT_SHOULDER else -1
		call("open_"+CONTROLLER_PAGES[posmod(CONTROLLER_PAGES.find(panel_kind)+offset,CONTROLLER_PAGES.size())]);return
	if panel_kind=="map" and is_instance_valid(map_view):
		if code==JOY_BUTTON_X:map_view.center_player();return
		if code==JOY_BUTTON_Y:map_view.fit_all();return
	if code==JOY_BUTTON_A:
		var focus:=get_viewport().gui_get_focus_owner()
		if focus is Button and focus in controller_focusables() and not focus.disabled:focus.pressed.emit()
