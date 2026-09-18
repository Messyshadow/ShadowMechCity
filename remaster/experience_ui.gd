extends RefCounted
const World = preload("res://remaster/world_data.gd")

static func paragraph(u: Node, parent: Control, value: String, rect: Rect2, size := 18, color := Color(.82,.88,.92)) -> Label:
	var label:=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.position=rect.position;label.size=rect.size;label.text=value
	label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.set_meta("paragraph_width",rect.size.x)
	parent.add_child(label);label.set_deferred("size",rect.size)
	return label

static func title(u: Node) -> void:
	var body:Control=u.shell("title","暗影机械城","SHADOW MECH CITY  /  REFORGED 0.3.0")
	u.text(body,"重铸余烬",Vector2(54,136),62,u.TEXT)
	u.text(body,"停转的城市，仍有人守着光。",Vector2(59,226),22,u.GOLD)
	paragraph(u,body,"来自晨曦温室的引航信号突然熄灭。\n沿着最后亮起的灯，寻找仍在运转的机械之心。",Rect2(61,280,515,78),18)
	u.button(body,"继续旅程   /   Enter",Rect2(61,383,327,50),u.continue_journey,true).grab_focus()
	u.button(body,"开始新旅程",Rect2(61,446,327,42),func():
		if not u.title_new_armed:u.title_new_armed=true;u.toast("再次点击开始新旅程，将重置重制版进度。",5)
		else:Reforged.new_game();u.game.load_room("hub","",true);u.open_story())
	u.button(body,"设置",Rect2(61,504,154,42),func():u.open_settings("title"))
	u.button(body,"操作与引导",Rect2(230,504,158,42),u.open_guide)
	u.button(body,"退出游戏",Rect2(61,560,327,37),u.game.quit_game)
	u.make_preview(body,Rect2(625,126,454,393),"idle")
	u.text(body,"猎魂者 / HUNTER",Vector2(730,517),18,u.CYAN)
	u.text(body,"八个区域  ·  四十个房间",Vector2(690,551),19,u.TEXT)
	u.text(body,"存档点："+str(World.ROOMS[Reforged.checkpoint_room].name),Vector2(665,588),14,u.GOLD)

static func settings(u: Node, source: String) -> void:
	u.settings_return=source
	var body:Control=u.shell("settings","设置","DISPLAY & AUDIO  /  即时预览，自动保存")
	u.text(body,"声音",Vector2(38,109),23,u.CYAN)
	u.button(body,"取消静音" if Reforged.mute else "静音",Rect2(393,107,135,34),func():
		Reforged.mute=not Reforged.mute;Reforged.apply_settings();Reforged.commit();u.open_settings(source),Reforged.mute)
	var rows:=[ ["master","总音量"],["music","音乐"],["effects","动作与打击音效"],["ambience","环境与机械音"] ]
	for i in range(rows.size()):slider(u,body,rows[i][0],rows[i][1],Vector2(38,166+i*79),0,1)
	u.text(body,"画面与辅助",Vector2(650,109),23,u.GOLD)
	u.button(body,"全屏："+("开启" if Reforged.settings.fullscreen else "关闭")+"   F11",Rect2(650,156,440,42),func():
		Reforged.set_setting("fullscreen",not Reforged.settings.fullscreen);u.open_settings(source),Reforged.settings.fullscreen)
	slider(u,body,"brightness","场景亮度",Vector2(650,225),.85,1.5,440)
	slider(u,body,"shake","镜头震动强度",Vector2(650,313),0,1,440)
	u.button(body,"情境教学："+("开启" if Reforged.settings.tutorial else "关闭"),Rect2(650,406,440,42),func():
		Reforged.set_setting("tutorial",not Reforged.settings.tutorial);u.open_settings(source),Reforged.settings.tutorial)
	paragraph(u,body,"调整亮度时观察背景中的人物和平台边缘：暗处应可辨认，灯光仍保留明暗层次。",Rect2(650,468,440,75),16)
	u.button(body,"恢复默认设置",Rect2(38,555,213,43),func():
		Reforged.settings=Reforged.DEFAULT_SETTINGS.duplicate();Reforged.mute=false;Reforged.apply_settings();Reforged.save_settings();u.game.apply_visibility();u.open_settings(source))
	u.button(body,"完成并返回",Rect2(877,555,213,43),u.return_from_settings,true)

static func slider(u: Node, body: Control, key: String, title_text: String, pos: Vector2, low: float, high: float, width := 490.0) -> void:
	u.text(body,title_text,pos,17,u.TEXT)
	var number:Label=u.text(body,"%d%%"%roundi(float(Reforged.settings[key])*100),pos+Vector2(width-62,0),17,u.GOLD)
	var control:=HSlider.new();body.add_child(control);control.position=pos+Vector2(0,31);control.size=Vector2(width,25)
	control.name="Setting_"+key;control.min_value=low;control.max_value=high;control.step=.01;control.value=float(Reforged.settings[key])
	control.value_changed.connect(func(value: float):
		Reforged.set_setting(key,value);number.text="%d%%"%roundi(value*100);u.game.apply_visibility())
	control.drag_ended.connect(func(_changed: bool):
		if key=="effects":u.game.audio.play("hit",-3))

static func skills(u: Node) -> void:
	var body:Control=u.shell("skills","猎魂者技能树","SKILL TREE  /  选择节点查看效果、操作方式与前置条件")
	for i in range(3):
		var page:String=["战斗","身法","暗影 / 机械"][i]
		u.button(body,page,Rect2(30+i*238,101,220,43),func():u.skill_page=page;u.skill_selection="";u.open_skills(),page==u.skill_page)
	u.text(body,"技能点  %d"%Reforged.points,Vector2(843,112),23,u.GOLD)
	var ids:Array=[]
	if u.skill_page=="战斗":
		for i in range(4):
			u.button(body,Reforged.WEAPON_NAMES[i],Rect2(30+i*182,165,173,43),func():u.skill_family=i;u.skill_selection="";u.open_skills(),i==u.skill_family)
		for i in range(1,4):ids.append(Reforged.WEAPONS[u.skill_family]+"_"+str(i))
	elif u.skill_page=="身法":ids=["stride","dash_flow","triple_jump","wall_drive","glide","water_drive"]
	else:ids=["shadow_guard","shadow_step","shadow_edge","core_shell","fast_loader","overclock"]
	if u.skill_selection not in ids:u.skill_selection=ids[0]
	u.plate(body,Rect2(30,230,733,372),Color(.034,.061,.082))
	var positions:Dictionary={}
	for i in range(ids.size()):positions[ids[i]]=Vector2(51+(i%3)*235,315+(i/3 as int)*164)
	if u.skill_page=="战斗":
		u.text(body,"武器分支 / "+Reforged.WEAPON_NAMES[u.skill_family],Vector2(51,252),20,u.CYAN)
		paragraph(u,body,"连线表示学习顺序；选中节点后，在右侧学习。\n第三阶解锁本武器的 K 技能。",Rect2(51,466,645,87),18)
	elif u.skill_page=="身法":
		u.text(body,"疾行与腾空",Vector2(51,252),19,u.CYAN);u.text(body,"壁行与环境移动",Vector2(51,424),19,u.CYAN)
	else:
		u.text(body,"暗影 · 生存与反击",Vector2(51,252),19,Color(.76,.57,1));u.text(body,"机械 · 核心与超频",Vector2(51,424),19,u.GOLD)
	for id in ids:
		var d:Array=Reforged.SKILLS[id];var req:String=d[3]
		if positions.has(req):
			var line:=Line2D.new();body.add_child(line);line.width=3
			line.default_color=u.CYAN if Reforged.skills.has(req) else Color(.23,.32,.38)
			line.points=PackedVector2Array([positions[req]+Vector2(194,34),positions[id]+Vector2(0,34)])
			if id=="wall_drive":line.points=PackedVector2Array([positions[req]+Vector2(0,34),Vector2(40,349),Vector2(40,513),positions[id]+Vector2(0,34)])
			if id=="water_drive":line.points=PackedVector2Array([positions[req]+Vector2(98,70),Vector2(149,580),Vector2(619,580),positions[id]+Vector2(98,70)])
	for id in ids:
		var d:Array=Reforged.SKILLS[id];var known:bool=Reforged.skills.has(id)
		var unlocked:bool=str(d[3])=="" or Reforged.skills.has(d[3])
		var node:Button=u.button(body,str(d[0])+"\n"+("已学习" if known else "可学习 · %d 点"%d[4] if unlocked else "前置未满足"),Rect2(positions[id],Vector2(196,70)),func():u.skill_selection=id;u.open_skills(),id==u.skill_selection)
		node.add_theme_font_size_override("font_size",16);node.tooltip_text=str(d[1])
		if not unlocked:node.modulate=Color(.60,.65,.70)
	var selected:Array=Reforged.SKILLS[u.skill_selection]
	var family:String=selected[2]
	var clip_name:String={"stride":"run","dash_flow":"dash","triple_jump":"jump","wall_drive":"wall_slide","glide":"fall","water_drive":"swim","shadow_guard":"hurt","shadow_step":"dash","shadow_edge":"blade_3","core_shell":"idle","fast_loader":"reload","overclock":"cast"}.get(u.skill_selection,"idle")
	u.make_preview(body,Rect2(793,161,336,225),clip_name)
	if family in Reforged.WEAPONS:u.preview_skill(u.skill_selection,false)
	u.text(body,str(selected[0]),Vector2(798,390),24,u.CYAN)
	paragraph(u,body,str(selected[1]),Rect2(798,429,326,74),17)
	var req:String=selected[3];var learned:bool=Reforged.skills.has(u.skill_selection)
	paragraph(u,body,"前置："+(str(Reforged.SKILLS[req][0]) if req!="" else "无")+"\n"+("已生效" if learned else "消耗 %d 技能点"%selected[4]),Rect2(798,505,326,50),15,u.GOLD)
	var can_learn:bool=not learned and Reforged.points>=int(selected[4]) and (req=="" or Reforged.skills.has(req))
	var learn_button:Button=u.button(body,"已学习" if learned else "学习技能" if can_learn else "技能点不足" if Reforged.points<int(selected[4]) else "请先学习前置",Rect2(798,563,326,39),func():
		if Reforged.learn(u.skill_selection):u.game.audio.play("save",-8)
		u.open_skills(),can_learn)
	learn_button.disabled=not can_learn

static func story(u: Node) -> void:
	var body:Control=u.shell("story","最后亮起的灯","PROLOGUE  /  猎魂者醒来")
	u.text(body,"城市停转之后",Vector2(62,143),42,u.GOLD)
	paragraph(u,body,"你在中央车站的同步舱里醒来。蒸汽管线仍在呼吸，远处的引航灯却接连熄灭。\n\n商人赫克保管着余烬护符。巡线员莉娅正在寻找能走进晨曦温室的人。\n\n先在青色终端同步，再和他们交谈。每次回到存档点，都是下一次出发的起点。",Rect2(65,212,615,325),20)
	u.make_preview(body,Rect2(760,157,340,350),"idle")
	u.button(body,"醒来，前往车站",Rect2(64,553,306,46),func():Reforged.story["intro_seen"]=true;Reforged.commit();u.close(),true).grab_focus()
	u.button(body,"跳过序章",Rect2(397,553,150,46),func():Reforged.story["intro_seen"]=true;Reforged.commit();u.close())

static func guide(u: Node) -> void:
	var body:Control=u.shell("guide","操作与旅途指南","FIELD MANUAL  /  随时按 N 查看任务，按 M 查看地图")
	paragraph(u,body,"移动与探索\n\nA / D 移动，空格跳跃与二段跳。\n贴墙时再按空格蹬墙；Shift 冲刺。\nW / S 沿楼梯、检修梯和升降机上下行。\n靠近入口或 NPC 按 E 交互。\n\n亮边平台可以站立；橙色预警即将攻击。\n等待攻击落空后的收招，再靠近反击。",Rect2(44,132,501,404),21)
	paragraph(u,body,"战斗与成长\n\nJ 连击，Q 切换四种武器。\nT 查看技能树，学习第三阶后按 K 释放。\n蒸汽炮弹药有限，R 装填；H 使用药剂。\nI 查看装备和强化，M 缩放与拖动地图。\n\n青色终端按 E 保存并补给。死亡返回该点。\n商人首谈赠护符，已卖装备可从回购页找回。",Rect2(621,132,501,404),21)
	u.button(body,"重新显示情境教学",Rect2(46,558,300,43),func():Reforged.tutorial.clear();Reforged.set_setting("tutorial",true);u.close();u.toast("教学已重置，将根据实际操作逐步推进。"),true)

static func journal(u: Node) -> void:
	var body:Control=u.shell("journal","旅途记录","QUEST JOURNAL  /  主线与委托")
	u.text(body,"主线 · 重启机械城",Vector2(44,123),26,u.CYAN)
	paragraph(u,body,u.game.main_objective()+"\n\n区域核心 %d / 7"%Reforged.bosses.size(),Rect2(44,179,491,221),21)
	u.text(body,"委托 · 让灯再次亮起",Vector2(623,123),26,u.GOLD)
	paragraph(u,body,beacon_status()+"\n\n委托人：中央车站 · 巡线员莉娅\n奖励：80 金币、2 技能点\n路线：中央车站下行升降机 → 晨曦温室",Rect2(623,179,490,271),20)
	u.button(body,"查看地图",Rect2(44,539,223,44),u.open_map,true)
	u.button(body,"查看新手指南",Rect2(292,539,223,44),u.open_guide)

static func beacon_status() -> String:
	if Reforged.story.get("beacon_claimed",false):return "委托完成。引航灯再次亮起，莉娅会继续守着这条线路。"
	if Reforged.story.get("beacon_online",false):return "引航灯已重启。返回中央车站向莉娅领取奖励。"
	if Reforged.story.get("beacon_accepted",false):return "沿升光庭院和棱镜回廊前往引航灯塔。\n清理灯塔守卫后，在灯塔终端按 E 重启。"
	return "莉娅正在车站等待。与她交谈，了解温室里熄灭的引航灯。"

static func npc(u: Node) -> void:
	var body:Control=u.shell("npc","巡线员 · 莉娅","DAWN SIGNAL  /  晨曦温室委托")
	u.text(body,"「只要灯还亮着，就能找到回家的路。」",Vector2(47,130),27,u.GOLD)
	paragraph(u,body,"温室的自动守卫失去了识别信号。盾卫封住主路，潜袭者会蓄力扑击。\n\n留意它们出招前的光圈和起手动作；等盾卫收招时绕到背后。到最深处清理守卫，在引航终端按 E。\n\n"+beacon_status(),Rect2(49,202,717,285),21)
	u.make_preview(body,Rect2(816,194,296,258),"idle","surveyor")
	u.text(body,"80 金币  +  2 技能点",Vector2(827,453),19,u.CYAN)
	if not Reforged.story.get("beacon_accepted",false):
		u.button(body,"接下委托",Rect2(49,551,255,46),func():Reforged.story["beacon_accepted"]=true;Reforged.commit();u.open_npc(),true)
	elif Reforged.story.get("beacon_online",false) and not Reforged.story.get("beacon_claimed",false):
		u.button(body,"报告并领取奖励",Rect2(49,551,255,46),func():
			if Reforged.claim_beacon_reward():u.game.audio.play("save");u.toast("委托完成 · +80 金币 / +2 技能点")
			u.open_npc(),true)
	else:u.button(body,"打开任务记录",Rect2(49,551,255,46),u.open_journal,true)
