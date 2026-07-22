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
		"platforms": [[300, 440, 180, 24], [900, 400, 200, 24], [0, 160, 200, 22], [1040,300,150,22,true], [1180,205,150,22,true], [1120,105,170,22,true]],
		"oneways": [[600, 470, 150]],
		"enemies": [],   # 中央车站=新手村, 安全区不刷敌人
		"items": [[1240, 520, "coin", ""]],
		"secrets": [[100, 138, "heart", "heart_hub"]],   # 站台高处生命碎片(需攀墙, 回到新手村探索)
		"npcs": [
			[320, 520, "cartographer"],
			[500, 520, "smith"],
			[900, 520, "alchemist"],
			[1080, 520, "collector"],
			[1250, 520, "bounty"],
		],
		"doors": [
			{"side": "left", "p": 430, "to": "temple"},
			{"side": "right", "p": 430, "to": "mine"},
			{"side": "up", "p": 700, "to": "void_deck"},
			{"side": "up", "p": 1120, "to": "secret_hub_archive", "hidden": true, "requires": ["wall_climb"]},
		],
		"save": Vector2(220, 560),
		"start_spawn": Vector2(160, 500),
	},
	# ============================ 遗迹神殿区域(阶段10.3): 前厅/中庭/地宫/符文回廊 + 守护神Boss, 符文机关 ============================
	"temple": {
		"name": "古代神殿·前厅", "theme": "temple", "map": Vector2i(-1, 0),
		"bounds": [0, 0, 1600, 700],
		"pits": [[820, 300, 2]],   # 中部断裂地坑(跨平台必经)
		"platforms": [
			[350, 470, 170, 24], [560, 570, 150, 24], [1000, 570, 150, 24],
			[700, 460, 150, 24], [860, 460, 150, 24],   # 跨坑岩台
			[620, 350, 170, 24], [950, 340, 180, 24], [1260, 470, 170, 24],
		],
		"walls": [[1380, 300, 44, 400]],
		"oneways": [[480, 470, 150]],
		"hazards": [[760, 700, 100, 20, 1, "rune"]],   # 符文光柱(周期, 预警)
		"enemies": [[400, 660, "guard"], [1180, 660, "gargoyle"], [950, 300, "priest"]],
		"items": [[950, 310, "chest", ""]],
		"secrets": [[90, 640, "heart", "heart_temple"]],
		"breakables": [[200, 200, 40, 500]],   # 左侧暗墙(炸弹炸开=回溯取碎片; 封住左侧死角口袋)
		"save": Vector2(340, 700),
		"start_spawn": Vector2(360, 660),
		"doors": [
			{"side": "right", "p": 560, "to": "hub"},
			{"side": "down", "p": 1150, "to": "temple_runes"},
		],
	},
	# 神殿·中庭: 攀墙竖井(高处生命碎片, 回溯) + 多层
	"temple_atrium": {
		"name": "神殿·中庭", "theme": "temple", "map": Vector2i(-2, 0),
		"bounds": [0, 0, 1700, 720],
		"pits": [[900, 360, 2]],
		"platforms": [
			[300, 540, 160, 24], [600, 440, 150, 24],
			[1100, 540, 160, 24], [1380, 430, 160, 24],
			[60, 180, 180, 24], [60, 360, 160, 24],   # 左壁攀墙竖井台阶(攀墙到顶=碎片)
			[800, 300, 200, 24],
		],
		"walls": [[1250, 300, 44, 420]],
		"oneways": [[480, 470, 150], [1500, 470, 150]],
		"hazards": [[600, 700, 160, 20, 1, "rune"]],
		"secrets": [[120, 150, "heart", "heart_temple_climb"]],   # 攀墙到顶(可选, 不软锁)
		"enemies": [[400, 680, "guard"], [1300, 680, "gargoyle"], [820, 260, "priest"]],
		"items": [[820, 270, "chest", ""]],
		"start_spawn": Vector2(250, 680),
		"doors": [
			{"side": "down", "p": 900, "to": "temple_undercroft"},
			{"side": "left", "p": 260, "to": "secret_temple_orbit", "hidden": true, "requires": ["double_jump", "wall_climb"]},
		],
	},
	# 神殿·地宫: 机械守卫精英 + 齿轮古机关 + 多层迷宫
	"temple_undercroft": {
		"name": "神殿·地宫", "theme": "temple", "map": Vector2i(-2, 1),
		"bounds": [0, 0, 1900, 720],
		"pits": [[600, 320, 2], [1300, 320, 2]],
		"platforms": [
			[300, 540, 160, 24], [600, 440, 150, 24], [900, 540, 160, 24],
			[1180, 470, 150, 24], [1500, 540, 160, 24],
			[900, 300, 200, 24],
		],
		"walls": [[450, 460, 44, 260], [1050, 300, 44, 420]],
		"oneways": [[750, 470, 150], [1400, 470, 150]],
		"hazards": [[600, 460, 80, 80, 2, "gear"], [1300, 460, 80, 80, 2, "gear"]],
		"enemies": [[350, 680, "guard"], [1600, 680, "gargoyle"],
			[900, 260, "priest"], [1100, 680, "guard_elite"]],
		"items": [[900, 270, "chest", ""]],
		"start_spawn": Vector2(250, 680),
		"doors": [
			{"side": "up", "p": 900, "to": "temple_atrium"},
			{"side": "right", "p": 590, "to": "temple_runes"},
		],
	},
	# 符文回廊: 招牌符文机关——踩亮 3 符文板解除封门(通往守护神殿) + 符文光柱陷阱
	"temple_runes": {
		"name": "神殿·符文回廊", "theme": "temple", "map": Vector2i(-1, 1),
		"bounds": [0, 0, 1900, 720],
		"pits": [[1000, 300, 2]],
		"platforms": [
			[300, 540, 170, 24], [620, 420, 160, 24], [900, 540, 160, 24],
			[1150, 440, 160, 24], [1450, 360, 180, 24], [1680, 520, 170, 24],
		],
		"walls": [[1600, 300, 44, 420]],
		"oneways": [[480, 470, 150], [1300, 470, 150]],
		"hazards": [[760, 700, 100, 20, 2, "rune"], [1250, 700, 100, 20, 2, "rune"]],
		"runes": [[360, 528], [680, 408], [1500, 348]],   # 3 符文板(一处需跳台/越坑)
		"rune_gates": [[1788, 300, 44, 420]],              # 符文封门: 挡右门(守护神殿), 踩满解除
		"enemies": [[450, 680, "guard"], [1150, 680, "gargoyle"], [820, 500, "priest"], [1450, 320, "priest"]],
		"start_spawn": Vector2(220, 680),
		"doors": [
			{"side": "up", "p": 400, "to": "temple"},
			{"side": "left", "p": 590, "to": "temple_undercroft"},
			{"side": "right", "p": 590, "to": "temple_sanctum"},
		],
	},
	# 守护神殿: 远古机械守护神 封闭竞技场
	"temple_sanctum": {
		"name": "神殿·守护神殿", "theme": "temple", "map": Vector2i(0, 1),
		"bounds": [0, 0, 1500, 620], "weapons": [[750, 540, "relic_blade"]],
		"platforms": [[300, 440, 180, 24], [1020, 440, 180, 24]],
		"oneways": [],
		"enemies": [],
		"items": [],
		"boss": {"x": 1020, "y": 620, "sprite": "golem", "name": "远古机械守护神",
			"hp": 240, "scale": 2.0, "size": Vector2(128, 150),
			"summon": true, "summon_type": "gargoyle", "tint": Color(0.85, 0.78, 0.55)},
		"doors": [{"side": "left", "p": 480, "to": "temple_runes"}],
	},
	"mine": {
		"name": "废弃矿坑", "theme": "mine", "map": Vector2i(1, 0),
		"bounds": [0, 0, 2200, 720],
		"pits": [[640, 280, 2], [1520, 300, 2]],   # 熔铁坑(跨平台/矿车必经)
		"movers": [[1080, 560, 210, "h", 330, 4.2, 0.0]],   # 矿车(水平长轨, 招牌)
		"platforms": [
			[320, 540, 160, 24], [860, 500, 160, 24],   # pit1 两侧
			[600, 360, 170, 24], [950, 330, 180, 24],
			[1300, 520, 160, 24], [1720, 520, 160, 24],   # pit2 两侧
			[1450, 370, 180, 24], [1900, 440, 170, 24],
			[1080, 250, 220, 24],   # 高处
			[1900, 310, 160, 22, true], [1900, 185, 160, 22, true], [1900, 80, 170, 22, true],
		],
		"oneways": [[470, 470, 150], [1640, 460, 150]],
		"enemies": [[420, 660, "drillworm"], [1320, 660, "moltenslime"], [1980, 660, "drillworm"],
			[760, 320, "gearbat"], [900, 660, "drill_brute"]],
		"items": [[1080, 220, "chest", ""]],   # 高处奖励(矿车/平台上行)
		"start_spawn": Vector2(180, 660),
		"doors": [
			{"side": "left", "p": 560, "to": "hub"},
			{"side": "right", "p": 560, "to": "factory_entry", "locked": "red_key"},
			{"side": "down", "p": 1080, "to": "depths"},
			{"side": "up", "p": 1900, "to": "secret_mine_cache", "hidden": true, "requires": ["bomb"]},
		],
	},
	"depths": {
		"name": "地下水道", "theme": "water", "map": Vector2i(1, 1),
		"bounds": [0, 0, 1300, 560],
		# 宽容回程链：每级抬升 <= 90px 且相邻平台重叠/近接，通到顶部 x=600 上行门
		"platforms": [
			[180, 475, 170, 22, true], [320, 390, 170, 22, true], [250, 305, 170, 22, true],
			[390, 220, 170, 22, true], [510, 130, 180, 22, true],
			[950, 430, 180, 22],
		],
		"oneways": [[760, 470, 150]],
		"enemies": [[520, 560, "slime"], [1080, 560, "beast"], [760, 380, "jelly"]],
		"items": [[600, 300, "key", "red_key"], [1120, 520, "chest", ""]],
		"doors": [{"side": "up", "p": 600, "to": "mine"}, {"side": "right", "p": 430, "to": "tunnel"},
			{"side": "down", "p": 300, "to": "water_grotto"}],
	},
	"tunnel": {
		"name": "坍塌隧道", "theme": "mine", "map": Vector2i(2, 1),
		"bounds": [0, 0, 1400, 560],
		"pits": [[980, 240, 2]],   # 塌方裂坑(跨平台必经)
		"platforms": [[300, 430, 170, 22], [760, 360, 170, 22], [1140, 430, 170, 22]],
		"oneways": [[540, 460, 150]],
		"enemies": [[420, 540, "drillworm"], [1200, 540, "moltenslime"], [760, 320, "gearbat"]],
		"items": [[1250, 520, "coin", ""]],
		"gates": [[300, -40, 44, 600]],
		"abilities": [[600, 360, "wall_climb"]],
		"doors": [{"side": "left", "p": 430, "to": "depths"}, {"side": "right", "p": 430, "to": "cavern"}],
	},
	"cavern": {
		"name": "熔岩腔穴", "theme": "mine", "map": Vector2i(3, 1),
		"bounds": [0, 0, 1500, 560],
		"pits": [[800, 240, 3]],   # 熔岩池(兑现"熔岩", 跨平台必经)
		"movers": [[800, 360, 170, "h", 150, 3.0, 0.0]],   # 矿车: 跨熔岩池
		"platforms": [[260, 410, 170, 22], [620, 330, 160, 22], [1040, 400, 170, 22], [1260, 320, 160, 22],
			[0, 150, 220, 22]],   # 左上高台(攀墙到达)
		"oneways": [[460, 460, 150], [1180, 470, 150]],
		"enemies": [[380, 560, "moltenslime"], [1100, 560, "drillworm"],
			[1380, 560, "moltenslime"], [620, 290, "gearbat"], [1260, 280, "gearbat"]],
		"items": [[1400, 520, "chest", ""]],
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
	# ============================ 腐化水道区域(阶段10.2): 淹没洞窟 + 水流闸门 + 深渊巨鳄, 水域机制 ============================
	# 淹没洞窟: 大水池游泳introduction + 水下推进器拾取(基础游泳即可到, 不软锁); 上→地下水道 右→激流回廊
	"water_grotto": {
		"name": "腐化水道·淹没洞窟", "theme": "water", "map": Vector2i(1, 2),
		"bounds": [0, 0, 1800, 760],
		"water": [[900, 560, 1760, 420]],   # 下半淹没大水池
		"platforms": [
			[250, 430, 180, 24], [560, 320, 170, 24], [900, 250, 200, 24],   # 上层干燥岩架
			[1250, 340, 180, 24], [1550, 460, 180, 24],
			[700, 600, 160, 24], [1100, 620, 160, 24],                       # 水下岩台
		],
		"walls": [[1350, 420, 44, 340]],
		"oneways": [[420, 470, 150]],
		"hazards": [[300, 740, 200, 20, 1, "poison"]],   # 角落毒沼
		"abilities": [[1560, 420, "aqua"]],              # 水下推进器(上层岩架, 基础游泳/跳跃可达)
		"enemies": [[500, 720, "fishman"], [1000, 560, "snake"], [1300, 720, "fishman"], [760, 300, "frog"]],
		"items": [[900, 220, "chest", ""]],
		"start_spawn": Vector2(280, 300),
		"doors": [
			{"side": "up", "p": 300, "to": "depths"},
			{"side": "right", "p": 620, "to": "water_channel"},
		],
	},
	# 激流回廊: 水流闸门(基础划水顶不住, 需水下推进器) + 暗墙后生命碎片; 左→淹没洞窟 右→深渊巢穴
	"water_channel": {
		"name": "腐化水道·激流回廊", "theme": "water", "map": Vector2i(2, 2),
		"bounds": [0, 0, 2000, 760],
		"water": [
			[450, 560, 880, 420],                       # 左池
			[1150, 430, 360, 700, -210.0, 0.0],         # 中部激流(向左推 210 > 基础划水120): 需推进器逆流
			[1750, 560, 480, 420],                      # 右池(通往Boss)
		],
		"platforms": [
			[250, 430, 170, 24], [620, 360, 160, 24],
			[1150, 250, 200, 24],                        # 激流上方干道(有推进器也可走上面绕)
			[1700, 360, 170, 24], [1900, 500, 160, 24],
			[300, 620, 150, 24], [1800, 620, 150, 24],   # 水下台
			[1750, 225, 160, 22, true], [1750, 105, 170, 22, true],
		],
		"walls": [[900, 300, 44, 460], [1400, 300, 44, 460]],   # 把激流夹成必经通道
		"hazards": [[600, 740, 220, 20, 1, "poison"], [1850, 740, 220, 20, 1, "poison"]],
		"breakables": [[120, 560, 40, 200]],   # 左侧暗墙(炸弹回溯)
		"secrets": [[70, 700, "heart", "heart_water"]],
		"enemies": [[400, 720, "fishman"], [1750, 720, "fishman"], [600, 320, "frog"], [1800, 360, "snake"]],
		"start_spawn": Vector2(250, 400),
		"doors": [
			{"side": "left", "p": 620, "to": "water_grotto"},
			{"side": "right", "p": 620, "to": "water_boss"},
			{"side": "up", "p": 1750, "to": "secret_water_cistern", "hidden": true, "requires": ["aqua"]},
		],
	},
	# 深渊巢穴: 深渊机械巨鳄 封闭竞技场(半淹没)
	"water_boss": {
		"name": "腐化水道·深渊巢穴", "theme": "water", "map": Vector2i(3, 2),
		"bounds": [0, 0, 1600, 620],
		"water": [[800, 480, 1560, 320]],
		"platforms": [[300, 410, 180, 24], [1120, 410, 180, 24]],
		"oneways": [], "weapons": [[800, 540, "corrupt_scythe"]],
		"enemies": [],
		"items": [],
		"boss": {"x": 1120, "y": 620, "sprite": "lion", "name": "深渊机械巨鳄",
			"hp": 220, "scale": 1.7, "size": Vector2(118, 116), "frames": 4, "fps": 3.3,
			"summon": true, "summon_type": "snake", "tint": Color(0.5, 0.85, 0.9)},
		"doors": [{"side": "left", "p": 480, "to": "water_channel"}],
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
			[1010, 165, 170, 22, true], [1010, 72, 180, 22, true],
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
			{"side": "up", "p": 1010, "to": "secret_factory_heat", "hidden": true, "requires": ["dash", "bomb"]},
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
	# ============================ 虚空要塞(阶段10.5) ============================
	"void_deck": {
		"name": "虚空要塞·破碎甲板", "theme": "void", "map": Vector2i(0, -1),
		"bounds": [0, 0, 1900, 720],
		"platforms": [[260, 560, 180, 24, true], [560, 460, 170, 24, true], [900, 360, 190, 24, true], [1260, 450, 180, 24, true], [1580, 540, 180, 24, true]],
		"oneways": [[720, 520, 160]],
		"winds": [[1100, 390, 420, 300, 80, -270]],
		"abilities": [[420, 420, "shadow_glider"]],
		"enemies": [[760, 320, "void_eagle"], [1320, 410, "storm_mage"]],
		"save": Vector2(210, 720), "start_spawn": Vector2(700, 90),
		"doors": [{"side": "down", "p": 700, "to": "hub"}, {"side": "right", "p": 590, "to": "void_bridge"}],
	},
	"void_bridge": {
		"name": "虚空要塞·风暴舰桥", "theme": "void", "map": Vector2i(1, -1),
		"bounds": [0, 0, 2200, 720], "pits": [[820, 420, 3], [1540, 360, 3]],
		"platforms": [[300, 560, 180, 24, true], [620, 470, 150, 24, true], [1020, 420, 170, 24, true], [1320, 330, 180, 24, true], [1740, 450, 170, 24, true], [2020, 560, 150, 24, true]],
		"winds": [[820, 420, 520, 360, -420, 0], [1540, 400, 460, 380, 390, -40]],
		"enemies": [[620, 420, "void_eagle"], [1100, 360, "void_wyvern"], [1840, 410, "storm_mage"]],
		"start_spawn": Vector2(180, 680),
		"doors": [{"side": "left", "p": 590, "to": "void_deck"}, {"side": "right", "p": 590, "to": "void_hangar"}],
	},
	"void_hangar": {
		"name": "虚空要塞·裂隙机库", "theme": "void", "map": Vector2i(2, -1),
		"bounds": [0, 0, 2100, 820], "pits": [[1050, 620, 3]],
		"platforms": [[260, 650, 180, 24, true], [520, 520, 160, 24, true], [820, 390, 170, 24, true], [1050, 210, 200, 24, true], [1340, 390, 170, 24, true], [1650, 520, 160, 24, true], [1900, 650, 150, 24, true]],
		"winds": [[1050, 500, 260, 600, 0, -360]],
		"hazards": [[1450, 800, 140, 20, 2, "rune"]],
		"enemies": [[580, 470, "void_eagle"], [980, 180, "void_wyvern"], [1420, 340, "storm_mage"], [1740, 470, "void_eagle"]],
		"items": [[1050, 180, "chest", ""]], "start_spawn": Vector2(180, 780),
		"doors": [{"side": "left", "p": 690, "to": "void_bridge"}, {"side": "right", "p": 690, "to": "void_core"}, {"side": "up", "p": 1050, "to": "secret_void_observatory", "hidden": true, "requires": ["shadow_glider"]}],
	},
	"void_core": {
		"name": "虚空要塞·核心舱", "theme": "void", "map": Vector2i(3, -1),
		"bounds": [0, 0, 1700, 700],
		"platforms": [[300, 520, 180, 24, true], [620, 410, 170, 24, true], [950, 300, 190, 24, true], [1300, 470, 180, 24, true]],
		"winds": [[900, 430, 230, 430, 0, -300]],
		"enemies": [[650, 360, "storm_mage"], [1100, 260, "void_wyvern"]],
		"save": Vector2(260, 700), "start_spawn": Vector2(180, 660), "weapons": [[950, 260, "void_blade"]],
		"doors": [{"side": "left", "p": 570, "to": "void_hangar"}, {"side": "right", "p": 570, "to": "void_throne"}, {"side": "down", "p": 850, "to": "castle_gate", "requires":["dash","bomb","aqua","wall_climb","glide","shadow_glider"]}],
	},
	"void_throne": {
		"name": "虚空要塞·天龙王座", "theme": "void", "map": Vector2i(4, -1),
		"bounds": [0, 0, 1800, 700], "platforms": [[360, 500, 180, 24], [900, 360, 220, 24], [1420, 500, 180, 24]],
		"oneways": [], "enemies": [], "items": [],
		"boss": {"x": 1250, "y": 300, "sprite": "bat", "name": "虚空天龙机甲", "hp": 320, "scale": 2.3, "size": Vector2(150, 110), "frames": 4, "fps": 8.5, "mode": "void_dragon", "tint": Color(0.65, 0.4, 1.0)},
		"doors": [{"side": "left", "p": 570, "to": "void_core"}],
	},
	# ============================ 暗影王城终章(阶段10.6) ============================
	"castle_gate": {"name":"暗影王城·城门高塔","theme":"castle","map":Vector2i(3,0),"bounds":[0,0,1900,760],"shafts":[[950,560,190,260]],"platforms":[[260,580,180,24,true],[620,450,180,24,true],[1050,390,190,24,true],[1450,520,180,24,true]],"enemies":[[520,410,"soul_shield"],[1120,350,"soul_spear"],[1540,480,"soul_cannon"]],"save":Vector2(220,760),"start_spawn":Vector2(850,90),"doors":[{"side":"up","p":850,"to":"void_core"},{"side":"down","p":950,"to":"castle_gallery"}]},
	"castle_gallery": {"name":"暗影王城·铸魂长廊","theme":"castle","map":Vector2i(3,1),"bounds":[0,0,2100,760],"shafts":[[1600,560,180,260]],"platforms":[[300,560,190,24,true],[680,430,180,24,true],[1050,300,200,24,true],[1420,440,180,24,true],[1800,580,170,24,true]],"enemies":[[420,520,"soul_spear"],[980,260,"soul_cannon"],[1450,400,"soul_shield"]],"start_spawn":Vector2(950,90),"doors":[{"side":"up","p":950,"to":"castle_gate"},{"side":"down","p":1600,"to":"castle_chapel"}]},
	"castle_chapel": {"name":"暗影王城·机械礼拜堂","theme":"castle","map":Vector2i(3,2),"bounds":[0,0,2000,780],"shafts":[[1000,590,210,260]],"platforms":[[260,600,180,24,true],[560,470,170,24,true],[1000,330,220,24,true],[1440,470,170,24,true],[1740,600,180,24,true]],"enemies":[[520,430,"soul_shield"],[980,290,"soul_cannon"],[1500,430,"soul_spear"]],"save":Vector2(240,780),"start_spawn":Vector2(1600,90),"doors":[{"side":"up","p":1600,"to":"castle_gallery"},{"side":"down","p":1000,"to":"castle_knights"},{"side":"right","p":560,"to":"secret_castle_ossuary","hidden":true,"requires":["dash","bomb","aqua","wall_climb","glide","shadow_glider"]}]},
	"castle_knights": {"name":"暗影王城·骑士竞技场","theme":"castle","map":Vector2i(3,3),"bounds":[0,0,1800,700],"platforms":[[360,500,180,24],[900,360,220,24],[1420,500,180,24]],"enemies":[],"boss":{"x":1250,"y":700,"sprite":"golem","name":"王城铸魂骑士团","hp":420,"scale":1.8,"size":Vector2(120,145),"mode":"soul_knights","summon":true,"summon_type":"soul_spear","tint":Color(0.65,0.5,0.9)},"doors":[{"side":"up","p":900,"to":"castle_chapel"},{"side":"down","p":900,"to":"castle_shaft"}]},
	"castle_shaft": {"name":"暗影王城·君王升降井","theme":"castle","map":Vector2i(3,4),"bounds":[0,0,1700,900],"shafts":[[850,180,300,700]],"platforms":[[280,720,170,24,true],[560,570,160,24,true],[960,430,170,24,true],[1260,280,170,24,true]],"enemies":[[420,680,"soul_spear"],[1050,390,"soul_cannon"],[1330,240,"soul_shield"]],"save":Vector2(250,900),"start_spawn":Vector2(900,90),"doors":[{"side":"up","p":900,"to":"castle_knights"},{"side":"down","p":850,"to":"castle_throne"}]},
	"castle_throne": {"name":"暗影王城·虚空王座","theme":"castle","map":Vector2i(3,5),"bounds":[0,0,1900,760],"platforms":[[380,540,200,24],[950,390,240,24],[1500,540,200,24]],"enemies":[],"boss":{"x":1320,"y":760,"sprite":"golem","name":"虚空机械君王","hp":600,"scale":2.1,"size":Vector2(140,170),"mode":"void_king","tint":Color(0.55,0.25,0.85)},"doors":[{"side":"up","p":950,"to":"castle_shaft"}]},

	# ============================ 阶段10.8：七区域独立秘室 ============================
	"secret_hub_archive": {
		"name":"秘室·遗失档案库", "theme":"city", "region":"hub", "hidden_room":true, "map":Vector2i(0,-2), "bounds":[0,0,1500,680],
		"platforms":[[260,540,180,24,true],[520,420,170,24,true],[800,300,190,24,true],[1080,430,170,24,true],[1320,540,160,24,true]],
		"walls":[[720,360,44,320]], "oneways":[[980,520,150]], "enemies":[],
		"items":[[1180,390,"chest","secret_chest_hub"]], "secrets":[[800,260,"memory","memory_hub_archive"]],
		"start_spawn":Vector2(180,640), "doors":[{"side":"left","p":540,"to":"hub"}]},
	"secret_mine_cache": {
		"name":"秘室·熔脉私藏间", "theme":"mine", "region":"mine", "hidden_room":true, "map":Vector2i(2,-1), "bounds":[0,0,1700,720],
		"pits":[[850,380,3]], "platforms":[[260,560,170,24],[540,450,160,24],[820,350,170,24],[1120,450,160,24],[1450,560,170,24]],
		"movers":[[850,520,150,"h",150,3.0,0.0]], "hazards":[[850,680,180,20,2,"steam"]], "enemies":[[520,410,"gearbat"],[1200,410,"drillworm"]],
		"items":[[1450,520,"chest","secret_chest_mine"]], "secrets":[[850,310,"memory","memory_mine_cache"]],
		"skill_targets":[[360,520,"brittle_wall",48,160],[1260,380,"drill_wall",48,150]],
		"start_spawn":Vector2(180,680), "doors":[{"side":"left","p":590,"to":"mine"}]},
	"secret_factory_heat": {
		"name":"秘室·废热回收仓", "theme":"factory", "region":"factory", "hidden_room":true, "map":Vector2i(4,0), "bounds":[0,0,1800,740],
		"belts":[[480,720,300,24,130],[1320,720,300,24,-130]], "updrafts":[[900,500,180,420,320]],
		"platforms":[[280,560,170,24],[620,460,160,24],[900,270,190,24],[1180,460,160,24],[1520,560,170,24]],
		"hazards":[[720,700,100,20,2,"steam"],[1080,700,100,20,2,"gear"]], "enemies":[[480,680,"mech_soldier"],[1320,680,"steam_brute"]],
		"items":[[900,230,"chest","secret_chest_factory"]], "secrets":[[1540,520,"memory","memory_factory_heat"]],
		"weapons":[[900,420,"dual_blades"]], "skill_targets":[[720,430,"steam_anchor"],[1280,410,"relay"]],
		"start_spawn":Vector2(170,700), "doors":[{"side":"left","p":600,"to":"factory_works"}]},
	"secret_water_cistern": {
		"name":"秘室·沉没蓄水池", "theme":"water", "region":"water", "hidden_room":true, "map":Vector2i(2,3), "bounds":[0,0,1700,760],
		"water":[[850,450,1660,620,170.0,0.0]], "platforms":[[250,360,170,24],[600,510,160,24],[980,610,180,24],[1370,430,170,24]],
		"walls":[[820,300,44,460]], "hazards":[[1180,740,180,20,1,"poison"]], "enemies":[[620,470,"fishman"],[1220,570,"snake"]],
		"items":[[1450,390,"chest","secret_chest_water"]], "secrets":[[980,570,"memory","memory_water_cistern"]],
		"start_spawn":Vector2(180,700), "doors":[{"side":"left","p":620,"to":"water_channel"}]},
	"secret_temple_orbit": {
		"name":"秘室·星轮观测室", "theme":"temple", "region":"temple", "hidden_room":true, "map":Vector2i(-3,0), "bounds":[0,0,1600,800],
		"platforms":[[260,650,160,24,true],[480,520,150,24,true],[720,390,160,24,true],[980,260,180,24,true],[1260,420,160,24,true],[1450,570,150,24,true]],
		"runes":[[480,508],[980,248],[1260,408]], "hazards":[[800,780,100,20,2,"rune"]], "enemies":[[720,350,"priest"],[1280,380,"gargoyle"]],
		"items":[[980,220,"chest","secret_chest_temple"]], "secrets":[[1450,530,"memory","memory_temple_orbit"]],
		"weapons":[[980,180,"spear"]],
		"start_spawn":Vector2(180,760), "doors":[{"side":"right","p":650,"to":"temple_atrium"}]},
	"secret_void_observatory": {
		"name":"秘室·裂隙观星台", "theme":"void", "region":"void", "hidden_room":true, "map":Vector2i(2,-2), "bounds":[0,0,1900,780],
		"pits":[[950,620,3]], "platforms":[[260,620,170,24,true],[560,500,160,24,true],[900,340,190,24,true],[1280,460,170,24,true],[1620,590,170,24,true]],
		"winds":[[950,450,520,520,260,-150]], "hazards":[[1480,760,120,20,2,"rune"]], "enemies":[[700,440,"void_eagle"],[1320,400,"storm_mage"]],
		"items":[[1620,550,"chest","secret_chest_void"]], "secrets":[[900,300,"memory","memory_void_observatory"]],
		"weapons":[[260,580,"crossbow"]], "skill_targets":[[760,360,"grapple_anchor"],[1440,500,"remote_switch"]],
		"start_spawn":Vector2(180,740), "doors":[{"side":"left","p":650,"to":"void_hangar"}]},
	"secret_castle_ossuary": {
		"name":"秘室·君王遗骨库", "theme":"castle", "region":"castle", "hidden_room":true, "map":Vector2i(4,2), "bounds":[0,0,1900,820],
		"shafts":[[950,210,220,590]], "platforms":[[280,650,180,24,true],[560,520,160,24,true],[900,380,190,24,true],[1220,500,160,24,true],[1580,640,180,24,true]],
		"winds":[[950,520,220,500,0,-260]], "hazards":[[720,800,120,20,2,"rune"],[1320,800,120,20,2,"gear"]], "enemies":[[560,480,"soul_spear"],[1250,460,"soul_cannon"]],
		"items":[[1580,600,"chest","secret_chest_castle"]], "secrets":[[900,340,"memory","memory_castle_ossuary"]],
		"start_spawn":Vector2(180,780), "doors":[{"side":"left","p":680,"to":"castle_chapel"}]},
}

# 区域瓦片色调
const THEME_TINT := {
	"city": Color(1, 1, 1),
	"mine": Color(1.0, 0.78, 0.55),
	"water": Color(0.65, 0.95, 1.0),
	"temple": Color(0.85, 0.72, 1.0),
	"factory": Color(1.0, 0.82, 0.55),
	"void": Color(0.62, 0.55, 1.0),
	"castle": Color(0.56, 0.48, 0.72),
}
