extends RefCounted
const Data=preload("res://remaster/exploration_data.gd")
const Experience=preload("res://remaster/experience_ui.gd")

static func open(u:Node,page:String) -> void:
	var body:Control=u.shell("collection","城市档案与探索","EXPEDITION  /  收藏自动保存 · 宝箱与补给箱每个存档只能领取一次")
	for i in range(3):
		var tab:String=["记忆档案","探索模块","补给与进度"][i]
		u.button(body,tab,Rect2(35+i*248,108,232,42),func():u.open_collection(tab),page==tab)
	u.button(body,"返回任务记录",Rect2(835,108,260,42),u.open_journal)
	var list:VBoxContainer=u.item_scroll(body,Rect2(35,173,1070,415))
	if page=="记忆档案":
		for id in Data.Archives.COLLECTIBLE_ORDER:
			var data:Dictionary=Data.Archives.COLLECTIBLES[id];var found:bool=Reforged.collected.get(id,false)==true
			var row:Button=u.button(list,"",Rect2(0,0,1035,113),func():pass)
			row.custom_minimum_size=Vector2(1035,113);row.tooltip_text=data.title
			u.text(row,("已同步 · " if found else "未同步 · ")+str(data.title),Vector2(20,12),23,u.CYAN if found else u.GOLD)
			Experience.paragraph(u,row,str(data.lore) if found else "寻找"+str(data.region)+"的区域秘室，同步记忆核心以恢复档案。",Rect2(20,49,985,54),18)
	elif page=="探索模块":
		for id in Data.MODULES:
			var data:Array=Data.MODULES[id];var found:bool=Reforged.collected.get("module_"+str(id),false)==true
			var location:String=Data.World.ROOMS[Data.catalog()["module_"+str(id)].room].name
			var row:Button=u.button(list,"",Rect2(0,0,1035,106),func():pass)
			row.custom_minimum_size=Vector2(1035,106);row.tooltip_text=data[0]
			u.text(row,("已取得 · " if found else "待探索 · ")+str(data[0]),Vector2(20,12),23,u.CYAN if found else u.GOLD)
			Experience.paragraph(u,row,str(data[1])+"\n位置："+location,Rect2(20,47,985,52),17)
	else:
		var stats:PackedStringArray=[]
		for pair in [["heart","生命碎片"],["memory","记忆档案"],["module","探索模块"],["chest","装备宝箱"],["supply","巡线补给箱"]]:
			var n:=Data.count(Reforged,pair[0]);stats.append("%s  %d / %d"%[pair[1],n.x,n.y])
		var row:=Control.new();row.custom_minimum_size=Vector2(1035,395);list.add_child(row)
		u.text(row,"    ·    ".join(stats),Vector2(14,13),19,u.CYAN)
		Experience.paragraph(u,row,"免费休整：在青色存档终端按 E，回满生命和 8 发弹匣，备弹保底 24 发、药剂保底 3 瓶。\n\n赫克商店：25 游戏金币购买 24 发备弹。普通敌人 +1 发，弹药回收技能使其变为 +3 发；Boss +6 发。\n\n绿色巡线补给箱：24 发备弹 +1 瓶药剂。备弹最多 120 发、药剂最多 9 瓶；两项都满时保留箱子，部分未满时按剩余容量领取，溢出部分不储存。\n\n红色生命碎片：每枚永久 +10 最大生命；紫色记忆核心：同步原版城市档案。橙色封板需脉冲炸弹炸开。\n\n蒸汽炮和弓弩共享弹匣与备弹。炸弹使用独立能量冷却，不消耗枪械弹药。",Rect2(14,60,1002,321),19)
