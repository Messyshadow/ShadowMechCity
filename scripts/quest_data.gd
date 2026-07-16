extends RefCounted
## 阶段 12.2 主线任务静态数据。状态计算由 quest_runtime.gd 负责。

const MAIN_ORDER := ["echo_coordinates", "broken_network", "void_skyline", "last_light"]

const QUESTS := {
	"echo_coordinates": {
		"chapter": "I",
		"title": "残响坐标",
		"summary": "中央车站的轨图仍在接收一段来自废铁矿坑的求救残响。弥娅需要一枚完整的岩核来校准失落线路。",
		"giver": "轨图解析师·弥娅",
		"objectives": [
			{"type":"flag", "id":"met_cartographer", "text":"与轨图解析师·弥娅交谈", "hint":"中央车站"},
			{"type":"visited", "id":"mine", "text":"进入废铁矿坑", "hint":"中央车站西侧线路"},
			{"type":"item", "id":"boss_mine_boss", "text":"击败岩核机甲巨兽", "hint":"废铁矿坑·岩核巢穴"},
		],
	},
	"broken_network": {
		"chapter": "II",
		"title": "断裂的传送网",
		"summary": "岩核坐标揭示三处被虚空污染的枢纽。夺回区域光核，才能重新接通通往天空的传送链。",
		"giver": "炉心铸造师·格里夫",
		"objectives": [
			{"type":"item", "id":"boss_boss", "text":"夺回铸造厂光核", "hint":"蒸汽铸造厂·泰坦炉心"},
			{"type":"item", "id":"boss_water_boss", "text":"夺回水道光核", "hint":"腐化水道·深渊巢穴"},
			{"type":"item", "id":"boss_temple_sanctum", "text":"夺回神殿光核", "hint":"遗迹神殿·守护圣所"},
		],
	},
	"void_skyline": {
		"chapter": "III",
		"title": "越过虚空天幕",
		"summary": "三枚区域光核打开了天空航路。穿过失控气流，在虚空天龙摧毁城市上空的最后锚点前击落它。",
		"giver": "鸦眼赏金追踪者·罗克",
		"objectives": [
			{"type":"visited", "id":"void_gate", "text":"进入虚空要塞", "hint":"中央车站上行传送链"},
			{"type":"item", "id":"boss_void_throne", "text":"击败虚空天龙机甲", "hint":"虚空要塞·风暴王座"},
		],
	},
	"last_light": {
		"chapter": "IV",
		"title": "最后的光核",
		"summary": "天幕破裂后，暗影王城重新显现。沿铸魂竖井抵达王座，让被囚禁的城市光核停止为君王供能。",
		"giver": "遗物收藏家·奥德里克",
		"objectives": [
			{"type":"visited", "id":"castle_gate", "text":"进入暗影王城", "hint":"虚空要塞后的王城门廊"},
			{"type":"visited", "id":"castle_throne", "text":"抵达虚空王座", "hint":"暗影王城最深处"},
			{"type":"item", "id":"boss_castle_throne", "text":"击败虚空机械君王", "hint":"暗影王城·虚空王座"},
		],
	},
}

