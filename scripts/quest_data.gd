extends RefCounted
## 阶段 12.2 主线任务静态数据。状态计算由 quest_runtime.gd 负责。

const MAIN_ORDER := ["echo_coordinates", "broken_network", "void_skyline", "last_light"]

const SIDE_ORDER := ["forged_arsenal", "sealed_memories", "beyond_the_map", "last_witnesses", "lord_hunt"]
const COLLECTIBLE_ORDER := ["memory_hub_archive", "memory_mine_cache", "memory_factory_heat", "memory_water_cistern", "memory_temple_orbit", "memory_void_observatory", "memory_castle_ossuary"]

const SIDE_QUESTS := {
	"forged_arsenal": {"title":"百炼兵装谱", "giver":"炉心铸造师·格里夫", "unlock":"met_smith", "summary":"让不同年代的兵器在同一座炉台上共鸣，复原失传的兵装谱。", "objectives":[{"type":"count", "field":"weapon_count", "target":6, "text":"解锁六种武器", "hint":"探索宝箱、Boss 奖励与隐藏区域"}]},
	"sealed_memories": {"title":"雾中封存物", "giver":"雾酿术士·塞菈", "unlock":"met_alchemist", "summary":"收集未被虚空彻底污染的记忆核心，确认机械意识是否仍可被净化。", "objectives":[{"type":"count", "field":"memory_count", "target":4, "text":"同步四枚记忆核心", "hint":"能力门后的区域秘室"}]},
	"beyond_the_map": {"title":"地图之外", "giver":"轨图解析师·弥娅", "unlock":"met_cartographer", "summary":"被人为抹去的房间正重新出现在轨图边缘。找出所有七处断层空间。", "objectives":[{"type":"count", "field":"hidden_count", "target":7, "text":"发现七个隐藏房间", "hint":"查看地图上的能力门与紫色秘室标记"}]},
	"last_witnesses": {"title":"最后的见证者", "giver":"遗物收藏家·奥德里克", "unlock":"met_collector", "summary":"七枚核心合在一起，才能复原机械城覆灭前的最后一段证词。", "objectives":[{"type":"count", "field":"memory_count", "target":7, "text":"复原全部七份记忆档案", "hint":"每个区域各藏有一枚记忆核心"}]},
	"lord_hunt": {"title":"七区猎杀令", "giver":"鸦眼赏金追踪者·罗克", "unlock":"met_bounty", "summary":"失控领主仍在封锁交通网。终止七场区域级威胁，让名单彻底熄灭。", "objectives":[{"type":"count", "field":"boss_count", "target":7, "text":"击败七名区域领主", "hint":"矿坑、工厂、水道、神殿、要塞与王城"}]},
}

const COLLECTIBLES := {
	"memory_hub_archive":{"region":"中央车站", "title":"零号班次", "lore":"末班列车从未离站。调度核心把所有乘客姓名改写成了同一个空白符号。"},
	"memory_mine_cache":{"region":"废铁矿坑", "title":"岩层下的心跳", "lore":"矿机在无操作员指令时继续向下挖掘，因为深处有某种东西在模仿炉心的脉冲。"},
	"memory_factory_heat":{"region":"蒸汽铸造厂", "title":"被拒绝的停机令", "lore":"工人连续七次拉下总闸，炉群却用城市电网重新点燃了自己。"},
	"memory_water_cistern":{"region":"腐化水道", "title":"沉没的净化协议", "lore":"过滤塔报告水质安全；同一秒，所有养护机械都选择潜入水底并切断通信。"},
	"memory_temple_orbit":{"region":"遗迹神殿", "title":"星轮偏移", "lore":"观测者发现天空并未旋转，转动的是包围城市的一层巨大机械外壳。"},
	"memory_void_observatory":{"region":"虚空要塞", "title":"天幕裂口", "lore":"第一道紫光出现时，天龙机甲没有攻击城市——它试图挡住裂口另一侧的目光。"},
	"memory_castle_ossuary":{"region":"暗影王城", "title":"王的第二副骨架", "lore":"王座记录显示君王早已死亡；此后发布命令的，是穿着他轮廓的另一套机械。"},
}

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
