extends RefCounted
const Data=preload("res://remaster/evolution_data.gd")
static func render(u:Node,body:Control) -> void:
	if u.evolution_branch not in Data.BRANCHES:u.evolution_branch="shadow"
	var branch:String=u.evolution_branch
	var ids:Array=Data.NODES[branch]
	for i in range(2):
		var id:String=Data.BRANCHES[i]
		u.button(body,Data.NAMES[id]+" · 已投入 %d 点"%Data.spent(Reforged,id),Rect2(30+i*238,161,220,40),func():u.evolution_branch=id;u.skill_selection="";u.open_skills(),id==branch)
	var selected_branch:bool=Reforged.evolution.branch==branch
	var equip:Button=u.button(body,"当前装配" if selected_branch else "装配"+Data.NAMES[branch]+"路线",Rect2(506,161,236,40),func():
		if u.game.evolution.select_branch(branch):u.open_skills(),selected_branch)
	equip.disabled=selected_branch
	u.plate(body,Rect2(30,217,733,385),Color(.034,.061,.082))
	u.text(body,"基础进化 · 被动能力",Vector2(51,232),18,Data.COLORS[branch])
	u.text(body,"主动进化 · 限时变身与召唤",Vector2(51,387),18,Data.COLORS[branch])
	if u.skill_selection not in ids:u.skill_selection=ids[3]
	var positions:Dictionary={}
	for i in range(ids.size()):positions[ids[i]]=Vector2(51+(i%3)*235,269+(i/3 as int)*153)
	for id in ids:
		var req:String=Reforged.SKILLS[id][3]
		if positions.has(req):
			var line:=Line2D.new();body.add_child(line);line.width=3
			line.default_color=Data.COLORS[branch] if Reforged.skills.has(req) else Color(.23,.32,.38)
			line.points=PackedVector2Array([positions[req]+Vector2(196,34),positions[id]+Vector2(0,34)])
			if id==branch+"_form":line.points=PackedVector2Array([positions[req]+Vector2(0,34),Vector2(40,303),Vector2(40,456),positions[id]+Vector2(0,34)])
	for id in ids:
		var d:Array=Reforged.SKILLS[id];var known:bool=Reforged.skills.has(id)
		var unlocked:bool=d[3]=="" or Reforged.skills.has(d[3])
		var node:Button=u.button(body,str(d[0])+"\n"+("已学习" if known else "可学习 · %d 点"%d[4] if unlocked else "前置未满足"),Rect2(positions[id],Vector2(196,69)),func():u.skill_selection=id;u.open_skills(),u.skill_selection==id)
		node.name="EvolutionNode_"+id;node.tooltip_text=str(d[1])
		if not unlocked:node.modulate=Color(.60,.65,.70)
	u.Experience.paragraph(u,body,"两条路线可兼修；Z 变身，V 召唤，使用当前装配路线。\n限时效果互不占用；召唤独立于 C 的机器人阵容。",Rect2(51,517,689,65),16)
	var selected:Array=Reforged.SKILLS[u.skill_selection]
	var summoning:bool=u.skill_selection.ends_with("_summon")
	u.make_preview(body,Rect2(793,161,336,209),"cast" if summoning else "idle")
	if u.skill_selection.ends_with("_form") or u.skill_selection.ends_with("_mastery"):
		u.preview_model.add_child(u.game.model("evolution_"+branch))
	if summoning:
		var summon:Node3D=u.game.model("summon_"+branch);u.preview_model.add_child(summon);summon.position=Vector3(.95,1.55,0)
	u.text(body,str(selected[0]),Vector2(798,378),24,Data.COLORS[branch])
	var description:String=selected[1]
	if Reforged.skills.has(branch+"_mastery"):
		description=description.replace("10 秒","14 秒（已强化）").replace("12 秒","16 秒（已强化）")
	u.Experience.paragraph(u,body,description,Rect2(798,417,326,94),16)
	var req:String=selected[3];var learned:bool=Reforged.skills.has(u.skill_selection)
	u.Experience.paragraph(u,body,"前置："+(str(Reforged.SKILLS[req][0]) if req!="" else "无")+"\n"+("已学习" if learned else "消耗 %d 技能点"%selected[4]),Rect2(798,514,326,47),15,u.GOLD)
	var can_learn:bool=not learned and Reforged.points>=int(selected[4]) and (req=="" or Reforged.skills.has(req))
	var learn:Button=u.button(body,"已学习" if learned else "学习技能" if can_learn else "技能点不足" if Reforged.points<int(selected[4]) else "请先学习前置",Rect2(798,566,326,39),func():
		if Reforged.learn(u.skill_selection):u.game.audio.play("save",-8)
		u.open_skills(),can_learn)
	learn.disabled=not can_learn
