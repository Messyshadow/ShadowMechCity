class_name DialogueData
extends RefCounted
## 数据驱动对话图。所有节点显式包含 next / choices / events，便于校验与迁移。

const ROUTES := {
	"smith": {
		"entries": [
			{"node":"smith_arsenal", "conditions":{"weapon_count_gte":5}},
			{"node":"smith_first", "conditions":{"flag_missing":"met_smith"}},
			{"node":"smith_repeat", "conditions":{}},
		],
		"nodes": {
			"smith_first": {"text":"这座城的主炉熄了，但你的武器还肯呼吸。", "next":"smith_link", "choices":[], "events":["set:met_smith"]},
			"smith_link": {"text":"等轨道储能链恢复，我能让钢铁从天空获得新的形态。", "next":"", "choices":[], "events":["set:foreshadow_quantum_upgrade"]},
			"smith_arsenal": {"text":"五种兵器都认得你了。接下来该让它们形成自己的技艺枝干。", "next":"", "choices":[], "events":[]},
			"smith_repeat": {"text":"别让漂亮的火花骗你，真正的好武器先要可靠。", "next":"", "choices":[], "events":[]},
		},
	},
	"alchemist": {
		"entries": [
			{"node":"alchemist_memory", "conditions":{"memory_count_gte":4}},
			{"node":"alchemist_first", "conditions":{"flag_missing":"met_alchemist"}},
			{"node":"alchemist_repeat", "conditions":{}},
		],
		"nodes": {
			"alchemist_first": {"text":"别碰那团紫雾。虚空不是魔法，它会改写机械与血肉遵守的规则。", "next":"alchemist_warning", "choices":[], "events":["set:met_alchemist"]},
			"alchemist_warning": {"text":"如果你带回会发光的记忆核心，先让我检查污染层。", "next":"", "choices":[], "events":[]},
			"alchemist_memory": {"text":"这些核心没有继续扩散，说明有人在毁灭前主动封住了自己的记忆。", "next":"", "choices":[], "events":[]},
			"alchemist_repeat": {"text":"药雾变甜时最危险，那代表过滤器已经开始撒谎。", "next":"", "choices":[], "events":[]},
		},
	},
	"cartographer": {
		"entries": [
			{"node":"cartographer_secret", "conditions":{"hidden_count_gte":1}},
			{"node":"cartographer_network", "conditions":{"visited_count_gte":20}},
			{"node":"cartographer_first", "conditions":{"flag_missing":"met_cartographer"}},
			{"node":"cartographer_repeat", "conditions":{}},
		],
		"nodes": {
			"cartographer_first": {"text":"旧轨图被切成了七块。你每走过一间房，车站就能记起一段线路。", "next":"cartographer_map", "choices":[], "events":["set:met_cartographer"]},
			"cartographer_map": {"text":"按 M 查看世界地图，紫色菱形只会标记你亲自发现的秘室。", "next":"", "choices":[], "events":[]},
			"cartographer_secret": {"text":"你已经找到轨图之外的空间。秘室不是漏画的，它们曾被人故意删除。", "next":"", "choices":[], "events":[]},
			"cartographer_network": {"text":"主干线路大半恢复了。剩下的空白多半藏在能力门和回程支线后。", "next":"", "choices":[], "events":[]},
			"cartographer_repeat": {"text":"地图不会替你探索，但会提醒你哪里仍在沉默。", "next":"", "choices":[], "events":[]},
		},
	},
	"collector": {
		"entries": [
			{"node":"collector_archive", "conditions":{"memory_count_gte":3}},
			{"node":"collector_first", "conditions":{"flag_missing":"met_collector"}},
			{"node":"collector_repeat", "conditions":{}},
		],
		"nodes": {
			"collector_first": {"text":"记忆核心保存的不是影像，而是机器临终前最后一次感知。", "next":"collector_space", "choices":[], "events":["set:met_collector"]},
			"collector_space": {"text":"旧档案还提到一层能容纳机械意识的封闭空间，可惜入口协议已经失传。", "next":"", "choices":[], "events":["set:foreshadow_quantum_space"]},
			"collector_archive": {"text":"三枚核心互相校验后，指向同一句警告：王城的影子并不属于王。", "next":"", "choices":[], "events":[]},
			"collector_repeat": {"text":"别急着给遗物命名。名字有时比锈蚀更会掩盖真相。", "next":"", "choices":[], "events":[]},
		},
	},
	"bounty": {
		"entries": [
			{"node":"bounty_veteran", "conditions":{"boss_count_gte":3}},
			{"node":"bounty_first", "conditions":{"flag_missing":"met_bounty"}},
			{"node":"bounty_repeat", "conditions":{}},
		],
		"nodes": {
			"bounty_first": {"text":"机械城的领主、巨兽和失控机甲，都在我的猎杀名单上。", "next":"bounty_choice", "choices":[], "events":["set:met_bounty"]},
			"bounty_choice": {"text":"你想先听哪类情报？", "next":"", "choices":[{"text":"区域领主", "to":"bounty_lords"}, {"text":"加密悬赏", "to":"bounty_cipher"}], "events":[]},
			"bounty_lords": {"text":"领主会把最安全的动作重复给你看。活下来，等它第一次打破自己的节奏。", "next":"", "choices":[], "events":[]},
			"bounty_cipher": {"text":"有个破解者把遗产藏进了铸造厂网络。等悬赏终端修好，我会把坐标交给你。", "next":"", "choices":[], "events":["set:foreshadow_hacker_legacy"]},
			"bounty_veteran": {"text":"三个领主已经沉默。现在名单开始害怕你的名字了。", "next":"", "choices":[], "events":[]},
			"bounty_repeat": {"text":"情报只负责让你多活一秒，剩下的要靠手里的武器。", "next":"", "choices":[], "events":[]},
		},
	},
}

