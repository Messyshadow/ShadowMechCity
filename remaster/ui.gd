extends CanvasLayer
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
	text(keys,"A D 移动    空格 二段跳 / 蹬墙    W S 梯井 / 升降机    J 连击    K 技能    Shift 冲刺    Q 换武器    R 装填    H 治疗",Vector2(16,5),15,TEXT)
	text(keys,"E 交互       I 背包       T 技能       M 地图       Esc 暂停",Vector2(16,26),12,Color(.42,.57,.65))
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
	var l:=Label.new();parent.add_child(l);l.text=value;l.position=pos;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;return l

func button(parent: Node, value: String, rect: Rect2, action: Callable, accent := false) -> Button:
	var b:=Button.new();parent.add_child(b);b.text=value;b.position=rect.position;b.size=rect.size
	b.add_theme_font_size_override("font_size",16)
	b.add_theme_stylebox_override("normal",style(Color(.07,.14,.18) if accent else Color(.045,.073,.095),CYAN if accent else Color(.2,.3,.36)))
	b.add_theme_stylebox_override("hover",style(Color(.12,.22,.26),GOLD));b.add_theme_stylebox_override("focus",style(Color(.09,.17,.22),CYAN))
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
	health.max_value=Reforged.max_health();health.value=Reforged.hp
	hp_label.text="猎魂者  %d / %d"%[ceili(Reforged.hp),int(Reforged.max_health())]
	stats.text="Lv.%02d    ◈ %d    技能点 %d    药剂 %d"%[Reforged.level,Reforged.coins,Reforged.points,Reforged.potions]
	ammo.text=Reforged.WEAPON_NAMES[Reforged.weapon]+("    弹匣 %d / 8  ·  备弹 %d"%[Reforged.magazine,Reforged.ammo] if Reforged.weapon==2 else "    J 连击 / 空中攻击")
	if game.player.reload_time>0:ammo.text+="  装填中…"
	room_label.text=str(game.room.get("name",""))
	objective_label.text="当前目标 / OBJECTIVE\n"+game.objective()
	boss_health.visible=is_instance_valid(game.boss) and not game.boss.dead and not panel_open
	boss_title.visible=boss_health.visible
	if boss_health.visible:
		boss_title.text=game.boss.boss_name+"  /  阶段 "+str(game.boss.phase)
		boss_health.max_value=game.boss.max_hp;boss_health.value=game.boss.hp
	toast_time=maxf(0,toast_time-dt);toast_label.visible=toast_time>0
	banner_time=maxf(0,banner_time-dt);banner.visible=banner_time>0 and not panel_open;banner.modulate.a=minf(1,banner_time)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("r_pause"):
		if panel_open:close()
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
	if panel_kind=="title" and event is InputEventKey and event.pressed and event.physical_keycode==KEY_ENTER:close()

func toast(value: String, seconds := 3.2) -> void:
	toast_label.text=value;toast_time=seconds;root.move_child(toast_label,-1)

func region_banner(value: String, theme: String) -> void:
	banner.text=value+"\n— "+theme.to_upper()+" —";banner_time=3.5

func fade(black: bool) -> void:
	root.move_child(transition,-1)
	var tw:=create_tween();tw.tween_property(transition,"color:a",1.0 if black else 0.0,.22);await tw.finished

func close() -> void:
	if panel:panel.queue_free();panel=null
	panel_open=false;panel_kind="";hud.visible=true;skill_preview=null;preview_model=null;preview_weapon=null;map_view=null
	Reforged.save_game()

func shell(kind: String, title: String, subtitle: String) -> Control:
	close();panel_open=true;panel_kind=kind;hud.visible=false
	panel=Control.new();root.add_child(panel);panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade:=ColorRect.new();panel.add_child(shade);shade.color=Color(.006,.016,.029,.8);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body:=plate(panel,Rect2(54,40,1172,640))
	text(body,title,Vector2(28,20),30,TEXT);text(body,subtitle,Vector2(29,63),14,Color(.42,.61,.69))
	button(body,"关闭  Esc",Rect2(1020,22,123,38),close)
	root.move_child(toast_label,-1)
	return body

func open_title() -> void:
	var body:=shell("title","暗影机械城","SHADOW MECH CITY  /  REFORGED")
	text(body,"重 铸 余 烬",Vector2(55,133),56,TEXT)
	text(body,"在停转的巨城里，找回最后一束光。",Vector2(60,216),22,GOLD)
	text(body,"3D 横版动作冒险\n七大区域 · 七位核心守卫 · 四条武器分支\n从中央车站出发，回收核心，重启机械城。",Vector2(60,284),19,TEXT)
	button(body,"继续探索   /   Enter",Rect2(60,431,290,51),close,true).grab_focus()
	button(body,"开始新旅程",Rect2(60,497,290,44),func():
		if not title_new_armed:
			title_new_armed=true;toast("再次点击「开始新旅程」以重置重制版进度。旧版存档保留。",5)
		else:
			Reforged.new_game();game.load_room("hub","",true);close())
	make_preview(body,Rect2(635,107,455,460),"idle")
	text(body,"A / D 移动   ·   空格跳跃   ·   J 攻击   ·   E 交互",Vector2(61,569),15,Color(.44,.63,.7))

func open_pause() -> void:
	var body:=shell("pause","旅途暂停","PROGRESS SAVED  /  存档点决定重生位置")
	text(body,"当前存档点\n"+str(Rooms.ROOMS[Reforged.checkpoint_room].name),Vector2(45,139),23,CYAN)
	button(body,"返回旅途",Rect2(45,242,300,48),close,true).grab_focus()
	button(body,"返回最后存档点",Rect2(45,309,300,45),func():close();game.respawn())
	button(body,"声音："+("关闭" if Reforged.mute else "开启"),Rect2(45,371,300,45),func():Reforged.mute=not Reforged.mute;Reforged.commit();open_pause())
	button(body,"保存并退出",Rect2(45,433,300,45),func():Reforged.save_game();game.get_tree().quit())
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
	var list:=VBoxContainer.new();s.add_child(list);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",8);return list

func item_row(list: VBoxContainer, it: Dictionary, mode: String) -> void:
	var row:=Panel.new();list.add_child(row);row.custom_minimum_size=Vector2(0,91)
	row.add_theme_stylebox_override("panel",style(Color(.042,.066,.088),Color(.16,.26,.31)))
	icon(row,item_icon(it),Rect2(9,6,75,75))
	var rarity:Color=[Color(.7,.76,.8),CYAN,Color(.7,.47,1),GOLD][clampi(int(it.rarity),0,3)]
	text(row,str(it.name),Vector2(92,12),18,rarity)
	text(row,item_stats(it),Vector2(92,44),14,TEXT)
	var is_equipped:bool=int(Reforged.equipped.get(it.slot,{}).get("uid",-1))==int(it.uid)
	if mode=="inventory":
		button(row,"已装备" if is_equipped else "装备",Rect2(530,23,90,37),func():Reforged.equip_item(int(it.uid));open_inventory(),not is_equipped).disabled=is_equipped
	elif mode=="sell":
		button(row,"已装备" if is_equipped else "出售 ◈"+str(it.price),Rect2(465,25,130,36),func():Reforged.sell(int(it.uid));open_shop("sell")).disabled=is_equipped
	else:
		button(row,"回购 ◈"+str(it.buyback_price),Rect2(465,25,130,36),func():
			if not Reforged.repurchase(int(it.uid)):toast("金币不足，物品仍保留在回购栏")
			open_shop("buyback"))

func open_inventory() -> void:
	var body:=shell("inventory","行者装备库","EQUIPMENT  /  点击装备会替换同槽装备，原装备保留在背包")
	text(body,"◈ %d   |   Lv.%d   |   生命 %d   护甲 %.1f   攻击 %.1f"%[Reforged.coins,Reforged.level,int(Reforged.max_health()),Reforged.stat("armor"),Reforged.attack_damage()],Vector2(28,100),17,GOLD)
	var list:=item_scroll(body,Rect2(28,145,665,457))
	for it in Reforged.inventory:item_row(list,it,"inventory")
	if Reforged.inventory.is_empty():text(body,"尚无装备，探索宝箱或到商人处购买。",Vector2(42,174),18,TEXT)
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
	text(body,"「活着回来，货和故事我都收。\n白装不要扔，卖给我就行。」\n\n首次见面赠送：余烬吸血护符\n命中恢复伤害量的 3% 生命\n\n药剂恢复 60 生命\n弹药箱补充 24 发备用子弹\n存档终端可获得最低补给",Vector2(775,199),19,TEXT)
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
			button(row,"购买 ◈"+str(prices[i]),Rect2(520,25,135,39),func():
				if not Reforged.buy(ids[i]):toast("金币不足或补给已满")
				open_shop("buy"),true)
	else:
		var list:=item_scroll(body,Rect2(30,175,690,374))
		var items:Array=Reforged.inventory if tab=="sell" else Reforged.buyback
		for it in items:item_row(list,it,tab)
		if items.is_empty():text(body,"这里暂时没有物品。",Vector2(54,205),20,TEXT)
		if tab=="sell":button(body,"一键出售未装备白装",Rect2(30,565,285,42),func():
			var n:=Reforged.sell_white();open_shop("sell");toast("已出售 %d 件白装，可在回购栏找回"%n),true)

func make_preview(parent: Control, rect: Rect2, clip_name: String) -> void:
	var container:=SubViewportContainer.new();parent.add_child(container);container.position=rect.position;container.size=rect.size
	container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var viewport:=SubViewport.new();viewport.size=Vector2i(rect.size);container.add_child(viewport);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var world:=Node3D.new();viewport.add_child(world)
	var cam:=Camera3D.new();world.add_child(cam);cam.position=Vector3(2.3,1.4,4);cam.look_at(Vector3(0,1.05,0));cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.8
	var l:=DirectionalLight3D.new();world.add_child(l);l.rotation_degrees=Vector3(-35,-35,0);l.light_energy=2;l.light_color=Color(.5,.8,1)
	var fill:=DirectionalLight3D.new();world.add_child(fill);fill.rotation_degrees=Vector3(-15,130,0);fill.light_energy=1.4;fill.light_color=Color(1,.5,.2)
	preview_model=game.model("hero");world.add_child(preview_model)
	preview_socket=preview_model
	var skeletons:=preview_model.find_children("*","Skeleton3D",true,false)
	if not skeletons.is_empty():
		var socket:=BoneAttachment3D.new();skeletons[0].add_child(socket);socket.bone_name="foreR";preview_socket=socket
	preview_weapon=game.model(Reforged.WEAPONS[Reforged.weapon]);preview_socket.add_child(preview_weapon);preview_weapon.position=Vector3(0,.32,0);preview_weapon.rotation.x=1.7;preview_weapon.scale=Vector3.ONE*.8
	skill_preview=preview_model.find_child("AnimationPlayer",true,false)
	if skill_preview and skill_preview.has_animation(clip_name):
		skill_preview.get_animation(clip_name).loop_mode=Animation.LOOP_LINEAR;skill_preview.play(clip_name)

func preview_skill(id: String) -> void:
	if skill_preview and skill_preview.has_animation("skill"):skill_preview.play("skill",.1)
	if preview_weapon:preview_weapon.queue_free()
	preview_weapon=game.model(str(Reforged.SKILLS[id][2]));preview_socket.add_child(preview_weapon)
	preview_weapon.position=Vector3(0,.32,0);preview_weapon.rotation.x=1.7;preview_weapon.scale=Vector3.ONE*.8
	toast(str(Reforged.SKILLS[id][0])+"："+str(Reforged.SKILLS[id][1]),4)

func open_skills() -> void:
	var body:=shell("skills","猎魂者战斗协议","COMBAT PROTOCOLS  /  选择节点预览动作，学习后立即生效")
	text(body,"可用技能点："+str(Reforged.points),Vector2(29,100),20,GOLD)
	for branch in range(4):
		var x:=30+branch*202
		icon(body,Reforged.WEAPONS[branch],Rect2(x+42,149,100,87))
		text(body,Reforged.WEAPON_NAMES[branch],Vector2(x+5,243),18,CYAN)
		for tier in range(1,4):
			var id:String=Reforged.WEAPONS[branch]+"_"+str(tier);var d:Array=Reforged.SKILLS[id]
			var known:bool=Reforged.skills.has(id);var y:=283+(tier-1)*99
			button(body,("✓ " if known else "")+str(d[0]),Rect2(x,y,182,40),func():preview_skill(id),known)
			button(body,"已学习" if known else "学习 · %d 点"%int(d[4]),Rect2(x,y+45,182,29),func():
				if not Reforged.learn(id):toast("需要足够技能点，并先学习上一个节点")
				open_skills();preview_skill(id)).disabled=known
	make_preview(body,Rect2(863,145,275,344),"attack1")
	text(body,"动作演示\n近战 · 空中 · 武器技能\n\n学习第 3 阶解锁 K 技能\n技能冷却 4 秒",Vector2(872,500),15,TEXT)

func open_map() -> void:
	var body:=shell("map","机械城 · 完整世界地图","WORLD ATLAS  /  滚轮缩放 · 左键拖动 · 保留完整房间名称")
	map_view=Control.new();map_view.set_script(MapScript);map_view.game=game;body.add_child(map_view);map_view.position=Vector2(25,111);map_view.size=Vector2(1122,443)
	map_view.center_player.call_deferred()
	button(body,"− 缩小",Rect2(28,575,125,37),func():map_view.set_zoom(map_view.zoom/1.2))
	button(body,"+ 放大",Rect2(168,575,125,37),func():map_view.set_zoom(map_view.zoom*1.2))
	button(body,"定位当前位置",Rect2(308,575,170,37),func():map_view.center_player(),true)
	button(body,"全图",Rect2(493,575,90,37),func():map_view.fit_all())
	text(body,"探索 %d / %d     核心 %d / 7     ◇ 最后存档点"%[Reforged.visited.size(),Rooms.ROOMS.size(),Reforged.bosses.size()],Vector2(623,582),16,GOLD)

func show_ending() -> void:
	var body:=shell("ending","光核重新点亮","THE CITY BREATHES AGAIN")
	text(body,"机械城，醒来了。",Vector2(80,153),48,GOLD)
	text(body,"你切断了虚空君王的控制，七座炉心重新开始跳动。\n赫克的商铺会继续亮着灯，未探索的秘室仍等待着你。\n\n回收核心 %d / 7     探索房间 %d / %d\n等级 %d     倒下 %d 次"%[Reforged.bosses.size(),Reforged.visited.size(),Rooms.ROOMS.size(),Reforged.level,Reforged.deaths],Vector2(85,247),22,TEXT)
	button(body,"继续探索机械城",Rect2(85,473,290,51),close,true)
