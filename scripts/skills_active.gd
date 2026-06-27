class_name SkillsActive
extends RefCounted
## 主动技能原型(按输入定义). 各武器变体由 player 按当前武器分派实现.
## 详见 docs/design/技能系统_v2_设计定稿.md
## 输入: ground=K(或↓K) / upper=↑K / dash_atk=双击前进+K / ult=V(满怒气)

const ARCHETYPES := {
	"ground":   {"name": "地面波", "mp": 15.0, "cd": 0.55},
	"upper":    {"name": "上挑",   "mp": 16.0, "cd": 0.90},
	"dash_atk": {"name": "突进斩", "mp": 20.0, "cd": 1.00},
	"burst":    {"name": "环身爆发", "mp": 30.0, "cd": 1.30},
	"ult":      {"name": "终结大招", "mp": 0.0, "cd": 0.30, "rage": 100.0},
}
