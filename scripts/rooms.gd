class_name Rooms
extends RefCounted
## 银河城房间世界. 房间通过四向门互联, 可来回探索.
## door: {side:"left"/"right"/"down"/"up", p:<L/R为门y, U/D为门x>, to:<房间id>, locked:<钥匙id或null>}
## bounds:[L,T,R,B]  B=地面.  map=小地图网格坐标.

const START := "hub"

const ROOMS := {
	"hub": {
		"name": "中央车站", "theme": "city", "map": Vector2i(0, 0),
		"bounds": [0, 0, 1400, 560],
		"platforms": [[300, 440, 180, 24], [900, 400, 200, 24], [0, 160, 200, 22]],   # 左上高台(攀墙回溯)
		"oneways": [[600, 470, 150]],
		"enemies": [],   # 中央车站=新手村, 安全区不刷敌人
		"items": [[1240, 520, "coin", ""]],
		"secrets": [[100, 138, "heart", "heart_hub"]],   # 站台高处生命碎片(需攀墙, 回到新手村探索)
		"doors": [
			{"side": "left", "p": 430, "to": "temple"},
			{"side": "right", "p": 430, "to": "mine"},
		],
		"save": Vector2(220, 560),
		"start_spawn": Vector2(160, 500),
	},
	"temple": {
		"name": "古代神殿", "theme": "temple", "map": Vector2i(-1, 0),
		"bounds": [0, 0, 1200, 560],
		"platforms": [[250, 420, 180, 24], [700, 350, 180, 24], [950, 460, 160, 24]],
		"oneways": [[480, 440, 150]],
		"enemies": [[420, 560, "slime"], [820, 350, "jelly"], [1050, 560, "bird"]],
		"items": [[760, 320, "chest", ""]],
		"secrets": [[90, 500, "heart", "heart_temple"]],   # 暗墙后生命碎片(需炸弹)
		"breakables": [[200, -40, 40, 600]],   # 炸弹炸开左侧暗墙得藏宝(回溯解锁)
		"doors": [{"side": "right", "p": 430, "to": "hub"}],
	},
	"mine": {
		"name": "废弃矿坑", "theme": "mine", "map": Vector2i(1, 0),
		"bounds": [0, 0, 1700, 560],
		"platforms": [[350, 440, 180, 24], [1150, 420, 220, 24]],
		"oneways": [[640, 460, 150]],
		"enemies": [[480, 560, "beast"], [1000, 560, "bat"], [1400, 560, "mushroom"]],
		"items": [[300, 520, "coin", ""]],
		"doors": [
			{"side": "left", "p": 430, "to": "hub"},
			{"side": "right", "p": 430, "to": "factory_entry", "locked": "red_key"},
			{"side": "down", "p": 850, "to": "depths"},
		],
	},
	"depths": {
		"name": "地下水道", "theme": "water", "map": Vector2i(1, 1),
		"bounds": [0, 0, 1300, 560],
		# 左中区做一条向上爬升的阶梯, 通到顶部(x≈600)的上行门
		"platforms": [
			[180, 450, 150, 22], [420, 350, 150, 22], [220, 250, 150, 22], [500, 140, 180, 22],
			[950, 430, 180, 22],
		],
		"oneways": [[760, 470, 150]],
		"enemies": [[520, 560, "slime"], [1080, 560, "beast"], [760, 380, "jelly"]],
		"items": [[600, 300, "key", "red_key"], [1120, 520, "chest", ""]],
		"doors": [{"side": "up", "p": 600, "to": "mine"}, {"side": "right", "p": 430, "to": "tunnel"}],
	},
	"tunnel": {
		"name": "坍塌隧道", "theme": "mine", "map": Vector2i(2, 1),
		"bounds": [0, 0, 1400, 560],
		"platforms": [[300, 430, 170, 22], [760, 360, 170, 22], [1080, 440, 170, 22]],
		"oneways": [[540, 460, 150]],
		"enemies": [[900, 560, "beast"], [1150, 560, "slime"], [760, 320, "mage"]],
		"items": [[1250, 520, "coin", ""]],
		"gates": [[300, -40, 44, 600]],
		"abilities": [[600, 360, "wall_climb"]],
		"doors": [{"side": "left", "p": 430, "to": "depths"}, {"side": "right", "p": 430, "to": "cavern"}],
	},
	"cavern": {
		"name": "熔岩腔穴", "theme": "mine", "map": Vector2i(3, 1),
		"bounds": [0, 0, 1500, 560],
		"platforms": [[260, 410, 170, 22], [620, 330, 160, 22], [980, 400, 170, 22], [1240, 320, 160, 22],
			[0, 150, 220, 22]],   # 左上高台(攀墙到达)
		"oneways": [[460, 460, 150], [1120, 470, 150]],
		"enemies": [[400, 560, "slime"], [700, 560, "bat"], [1100, 560, "beast"],
			[1350, 560, "mushroom"], [620, 290, "mage"], [1240, 280, "jelly"]],
		"items": [[1380, 520, "chest", ""]],
		"secrets": [[110, 120, "heart", "heart_cavern_climb"]],   # 左上高台生命碎片(需攀墙)
		"abilities": [[700, 300, "bomb"], [400, 300, "glide"]],
		"doors": [{"side": "left", "p": 430, "to": "tunnel"}, {"side": "right", "p": 430, "to": "mine_boss"}],
	},
	"mine_boss": {
		"name": "岩核之巢", "theme": "mine", "map": Vector2i(4, 1),
		"bounds": [0, 0, 1500, 560],
		"platforms": [[300, 410, 180, 24], [1020, 410, 180, 24]],
		"oneways": [],
		"enemies": [],
		"items": [],
		"boss": {"x": 1080, "y": 560, "sprite": "lion", "name": "岩核机甲巨兽",
			"hp": 200, "scale": 1.7, "size": Vector2(110, 116), "frames": 4, "fps": 3.3,
			"summon": true, "summon_type": "bat", "tint": Color(1.0, 0.82, 0.6)},
		"doors": [{"side": "left", "p": 430, "to": "cavern"}],
	},
	# ============================ 蒸汽铸造厂区域(阶段10.1): 4 大迷宫房间 + 泰坦Boss, 互联成环 ============================
	# 入口熔炉大厅: 多层 + 蒸汽阀陷阱; 左→矿坑(红钥匙门) 右→装配车间 下→熔铁回廊
	"factory_entry": {
		"name": "铸造厂·熔炉大厅", "theme": "factory", "map": Vector2i(2, 0),
		"bounds": [0, 0, 2100, 720],
		"walls": [[1250, 240, 180, 480], [1660, 430, 44, 290]],   # 中央巨型高炉(实体塔, 翻越) + 右分隔
		"decor": [[250, 590, "factory/furnace", 1.5], [170, 380, "factory/pipes", 1.1], [1900, 360, "factory/gearwheel", 1.2]],
		"pits": [[520, 360, 2]],                                  # 底部熔铁池: 跨坑走岩桥=必经
		"updrafts": [[1140, 470, 150, 360, 300]],                 # 热气流: 托举上行(垂直动线)
		"platforms": [
			[350, 580, 140, 24], [490, 490, 140, 24], [630, 580, 140, 24],   # 岩桥跨熔铁池
			[780, 470, 150, 24],
			[1080, 250, 220, 24],                                            # 热气流顶/高处奖励
			[1180, 430, 150, 24], [1330, 300, 170, 24],                      # 翻越高炉
			[1500, 430, 160, 24], [1780, 540, 220, 24],                      # 右侧下降到右门
		],
		"oneways": [[960, 560, 200]],   # 桥接下行门(可走顶/可掉落)
		"hazards": [[850, 700, 120, 20, 1, "steam"], [1560, 700, 120, 20, 1, "steam"]],
		"enemies": [[230, 700, "mech_soldier"], [1550, 720, "mech_soldier"], [1000, 360, "ghost_spider"]],
		"items": [[1160, 220, "chest", ""]],   # 高处奖励, 逼上行
		"save": Vector2(150, 720),
		"start_spawn": Vector2(150, 700),
		"doors": [
			{"side": "left", "p": 590, "to": "mine"},
			{"side": "right", "p": 590, "to": "factory_works"},
			{"side": "down", "p": 1050, "to": "factory_foundry"},
		],
	},
	# 装配车间: 齿轮陷阱 + 精英重装蒸汽兵; 左→熔炉大厅 下→传送链区
	"factory_works": {
		"name": "铸造厂·装配车间", "theme": "factory", "map": Vector2i(3, 0),
		"bounds": [0, 0, 2200, 720],
		"pits": [[760, 320, 2], [1720, 300, 2]],                   # 底部双坑
		"belts": [[400, 700, 320, 24, 110], [1320, 700, 320, 24, -120]],   # 传送带(招牌): 流水线推动
		"decor": [[480, 690, "factory/conveyor", 1.0], [1400, 690, "factory/conveyor", 1.0], [1010, 360, "factory/gearwheel", 1.5], [2120, 560, "factory/pipes", 1.0]],
		"platforms": [
			[600, 470, 150, 24],
			[1020, 560, 160, 24], [880, 470, 140, 24], [1180, 470, 140, 24],   # 跨左坑/下行门两侧
			[1500, 520, 150, 24], [1640, 420, 150, 24], [1860, 520, 160, 24],  # 跨右坑
			[1010, 280, 240, 24],                                              # 高处奖励
		],
		"walls": [[520, 470, 44, 250], [1340, 220, 44, 300]],
		"oneways": [[1060, 470, 160]],
		"hazards": [[760, 460, 80, 80, 2, "gear"], [1720, 460, 80, 80, 2, "gear"]],   # 齿轮在坑上窄道(看时机)
		"enemies": [[300, 700, "mech_soldier"], [2030, 720, "mech_soldier"],
			[1010, 240, "drone"], [1500, 380, "ghost_spider"], [1280, 720, "steam_brute"]],
		"items": [[1070, 250, "chest", ""]],
		"start_spawn": Vector2(180, 700),
		"doors": [
			{"side": "left", "p": 590, "to": "factory_entry"},
			{"side": "down", "p": 1100, "to": "factory_conveyor"},
		],
	},
	# 熔铁回廊: 竖向多层 + 熔铁陷阱 + 暗墙后生命碎片(需炸弹回溯); 上→熔炉大厅 右→传送链区
	"factory_foundry": {
		"name": "铸造厂·熔铁回廊", "theme": "factory", "map": Vector2i(2, 1),
		"bounds": [0, 0, 2100, 720],
		"pits": [[1150, 620, 3]],   # 熔铁河: 贯穿中部底部的宽坑(伤3), 岩桥跨越=必经
		"decor": [[560, 600, "factory/furnace", 1.2], [1500, 500, "factory/pipes", 1.1], [1880, 250, "factory/gearwheel", 1.0]],
		"platforms": [
			[320, 560, 160, 24], [360, 400, 150, 24], [330, 240, 150, 24], [360, 96, 160, 24],  # 左侧上行门攀爬栈(x≈400)
			[640, 520, 150, 24],
			[860, 540, 130, 24], [1050, 460, 120, 24], [1240, 540, 130, 24],   # 熔铁河断桥(需跳)
			[1150, 300, 160, 24],                                              # 河上高处奖励
			[1560, 520, 160, 24], [1800, 400, 180, 24],                        # 右侧到右门
		],
		"walls": [[1500, 300, 44, 420]],
		"oneways": [[660, 470, 150], [1620, 440, 150]],
		"hazards": [[1050, 410, 80, 80, 2, "gear"]],   # 河中央上方齿轮(过桥看时机)
		"enemies": [[330, 700, "mech_soldier"], [1750, 720, "mech_soldier"], [700, 340, "drone"]],
		"breakables": [[120, 560, 40, 160]],   # 左侧暗墙(炸弹炸开=回溯, 非关键路径)
		"secrets": [[70, 700, "heart", "heart_factory"]],
		"items": [[1150, 270, "chest", ""]],
		"start_spawn": Vector2(250, 700),
		"doors": [
			{"side": "up", "p": 400, "to": "factory_entry"},
			{"side": "right", "p": 590, "to": "factory_conveyor"},
		],
	},
	# 传送链区: 无人机/幽灵蜘蛛 + 冲刺门结构化动线; 左→熔铁回廊 上→装配车间 右→Boss厂房
	"factory_conveyor": {
		"name": "铸造厂·传送链区", "theme": "factory", "map": Vector2i(3, 1),
		"bounds": [0, 0, 2200, 720],
		"pits": [[700, 360, 2], [1500, 320, 2]],   # 底部双坑, 靠链条平台跨越
		"decor": [[1100, 170, "factory/gearwheel", 1.6], [480, 560, "factory/pipes", 1.1], [1900, 450, "factory/conveyor", 0.9]],
		"movers": [
			[1100, 400, 160, "v", 200, 3.2, 0.0],    # 链条升降机(招牌·垂直)→上行门
			[700, 520, 150, "h", 170, 3.0, 0.0],      # 链条平台(水平)跨左坑
			[1500, 520, 150, "h", 165, 3.4, 1.5],     # 链条平台(水平)跨右坑
		],
		"platforms": [
			[300, 560, 150, 24], [1000, 540, 150, 24], [1220, 540, 150, 24],   # 上行门两侧
			[1080, 250, 200, 24],                                              # 升降顶接上行门/奖励
			[1880, 470, 180, 24],
		],
		"walls": [[460, 440, 44, 280], [1340, 260, 44, 300]],
		"oneways": [[1040, 470, 170]],
		"hazards": [[1720, 632, 96, 96, 2, "gear"], [340, 700, 120, 20, 1, "steam"]],
		"gates": [[1980, -40, 44, 760]],   # 冲刺门: 相位穿越到 Boss 门(冲刺初始能力, 不软锁)
		"enemies": [[350, 720, "drone"], [1250, 720, "mech_soldier"],
			[850, 360, "ghost_spider"], [1900, 340, "drone"]],
		"items": [[1080, 220, "chest", ""]],
		"start_spawn": Vector2(180, 700),
		"doors": [
			{"side": "left", "p": 590, "to": "factory_foundry"},
			{"side": "up", "p": 1100, "to": "factory_works"},
			{"side": "right", "p": 590, "to": "boss"},
		],
	},
	"boss": {
		"name": "蒸汽工厂", "theme": "factory", "map": Vector2i(4, 1),
		"bounds": [0, 0, 1500, 560],
		"platforms": [[280, 410, 180, 24], [1040, 410, 180, 24]],
		"oneways": [],
		"enemies": [],
		"items": [],
		"boss": {"x": 1050, "y": 560, "sprite": "golem", "name": "蒸汽机甲·泰坦",
			"hp": 160, "scale": 1.9, "size": Vector2(120, 150)},
		"doors": [{"side": "left", "p": 430, "to": "factory_conveyor"}],
	},
}

# 区域瓦片色调
const THEME_TINT := {
	"city": Color(1, 1, 1),
	"mine": Color(1.0, 0.78, 0.55),
	"water": Color(0.65, 0.95, 1.0),
	"temple": Color(0.85, 0.72, 1.0),
	"factory": Color(1.0, 0.82, 0.55),
}
