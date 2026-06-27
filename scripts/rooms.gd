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
		"platforms": [[300, 520, 260, 24], [720, 400, 240, 24], [1180, 520, 260, 24],
			[1500, 360, 240, 24], [1760, 540, 260, 24]],
		"walls": [[620, 460, 44, 260], [1450, 200, 44, 340]],
		"oneways": [[980, 470, 160], [1600, 320, 150]],
		"hazards": [[380, 700, 180, 20, 1, "steam"], [1280, 700, 180, 20, 1, "steam"]],
		"enemies": [[500, 720, "mech_soldier"], [1320, 720, "mech_soldier"], [820, 350, "ghost_spider"]],
		"save": Vector2(150, 720),
		"start_spawn": Vector2(260, 700),
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
		"platforms": [[250, 540, 240, 24], [640, 420, 240, 24], [1000, 300, 260, 24],
			[1480, 440, 240, 24], [1850, 540, 240, 24]],
		"walls": [[520, 460, 44, 260], [1340, 220, 44, 280], [1720, 360, 44, 360]],
		"oneways": [[900, 480, 150], [1620, 300, 150]],
		"hazards": [[700, 632, 96, 96, 2, "gear"], [1560, 632, 96, 96, 2, "gear"]],
		"enemies": [[400, 720, "mech_soldier"], [1950, 720, "mech_soldier"],
			[1000, 260, "drone"], [1500, 400, "ghost_spider"], [1200, 720, "steam_brute"]],
		"items": [[1000, 270, "chest", ""]],
		"start_spawn": Vector2(260, 700),
		"doors": [
			{"side": "left", "p": 590, "to": "factory_entry"},
			{"side": "down", "p": 1100, "to": "factory_conveyor"},
		],
	},
	# 熔铁回廊: 竖向多层 + 熔铁陷阱 + 暗墙后生命碎片(需炸弹回溯); 上→熔炉大厅 右→传送链区
	"factory_foundry": {
		"name": "铸造厂·熔铁回廊", "theme": "factory", "map": Vector2i(2, 1),
		"bounds": [0, 0, 2100, 720],
		"platforms": [[980, 560, 180, 24], [1000, 400, 180, 24], [1020, 240, 180, 24], [1000, 92, 180, 24],
			[300, 520, 240, 24], [600, 380, 220, 24], [1500, 500, 240, 24], [1800, 360, 220, 24]],
		"walls": [[500, 440, 44, 280], [1380, 260, 44, 460]],
		"oneways": [[400, 470, 150], [1650, 440, 150]],
		"hazards": [[640, 700, 260, 20, 2, "lava"], [1450, 700, 300, 20, 2, "lava"]],
		"enemies": [[350, 720, "mech_soldier"], [1600, 720, "mech_soldier"], [720, 340, "drone"]],
		"breakables": [[120, 560, 40, 160]],   # 左侧暗墙(炸弹炸开=回溯, 非关键路径)
		"secrets": [[70, 700, "heart", "heart_factory"]],
		"start_spawn": Vector2(300, 700),
		"doors": [
			{"side": "up", "p": 1050, "to": "factory_entry"},
			{"side": "right", "p": 590, "to": "factory_conveyor"},
		],
	},
	# 传送链区: 无人机/幽灵蜘蛛 + 冲刺门结构化动线; 左→熔铁回廊 上→装配车间 右→Boss厂房
	"factory_conveyor": {
		"name": "铸造厂·传送链区", "theme": "factory", "map": Vector2i(3, 1),
		"bounds": [0, 0, 2200, 720],
		"platforms": [[1020, 560, 180, 24], [1060, 400, 180, 24], [1040, 240, 180, 24], [1080, 92, 180, 24],
			[300, 520, 240, 24], [650, 400, 220, 24], [1500, 500, 220, 24], [1820, 380, 220, 24]],
		"walls": [[520, 440, 44, 280], [1500, 240, 44, 260]],
		"oneways": [[420, 470, 150], [1650, 440, 150]],
		"hazards": [[380, 700, 180, 20, 1, "steam"], [1700, 632, 96, 96, 2, "gear"]],
		"gates": [[1960, -40, 44, 760]],   # 冲刺门: 相位穿越到 Boss 门(冲刺为初始能力, 不软锁)
		"enemies": [[350, 720, "drone"], [1400, 720, "mech_soldier"],
			[800, 360, "ghost_spider"], [1850, 340, "drone"]],
		"start_spawn": Vector2(300, 700),
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
