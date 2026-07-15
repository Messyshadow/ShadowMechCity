class_name NpcData
extends RefCounted
## 阶段 12.1 NPC 元数据。只描述身份和视觉参数，不创建场景节点。

const NPCS := {
	"smith": {
		"name": "炉心铸造师·格里夫", "role": "炉心铸造师", "route": "smith",
		"accent": Color(0.91, 0.43, 0.20), "emblem": "hammer", "build": "heavy",
	},
	"alchemist": {
		"name": "雾酿术士·塞芙拉", "role": "雾酿术士", "route": "alchemist",
		"accent": Color(0.31, 0.84, 0.68), "emblem": "flask", "build": "slender",
	},
	"cartographer": {
		"name": "轨图解析师·弥娅", "role": "轨图解析师", "route": "cartographer",
		"accent": Color(0.34, 0.77, 0.94), "emblem": "map", "build": "light",
	},
	"collector": {
		"name": "遗物收藏家·奥德里克", "role": "遗物收藏家", "route": "collector",
		"accent": Color(0.67, 0.43, 0.92), "emblem": "memory", "build": "robed",
	},
	"bounty": {
		"name": "鸦眼赏金追踪者·罗克", "role": "赏金追踪者", "route": "bounty",
		"accent": Color(0.91, 0.29, 0.29), "emblem": "target", "build": "hunter",
	},
}

