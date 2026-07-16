extends RefCounted
## 阶段 12.4 演出静态数据；UI 与流程由 cinematic_panel.gd 负责。

const INTRO := [
	{"eyebrow":"序章 · 01", "title":"熄灭之城", "text":"第七码头停摆后的第 4,821 个夜晚，机械城所有炉心在同一秒失去回声。", "accent":Color(0.28, 0.78, 0.95), "glyph":"CITY//OFFLINE"},
	{"eyebrow":"序章 · 02", "title":"天幕之外", "text":"紫色裂隙从云层背面张开。它没有摧毁机器，只是教会它们服从另一种心跳。", "accent":Color(0.68, 0.36, 1.0), "glyph":"VOID//SIGNAL"},
	{"eyebrow":"序章 · 03", "title":"零号班次", "text":"一列没有时刻表的列车穿过封锁线，携带最后一枚未被改写的光核抵达中央车站。", "accent":Color(1.0, 0.58, 0.25), "glyph":"RAIL//ARRIVAL"},
	{"eyebrow":"序章 · 04", "title":"残响苏醒", "text":"你在冷却舱中睁开眼。城市没有请求拯救——它只把仍能打开的门留给了你。", "accent":Color(0.48, 0.95, 0.88), "glyph":"ECHO//AWAKE"},
]

const ENDING := [
	{"eyebrow":"终章 · 01", "title":"伪王停机", "text":"王座的第二副骨架终于停止发号施令。被囚禁的光核第一次听见自己的声音。", "accent":Color(1.0, 0.34, 0.52), "glyph":"THRONE//SILENT"},
	{"eyebrow":"终章 · 02", "title":"七区重连", "text":"矿脉、炉群、水道、星轮、天幕与王城逐一亮起。遗失的线路重新在黑暗中握手。", "accent":Color(0.35, 0.85, 1.0), "glyph":"GRID//RESTORED"},
	{"eyebrow":"终章 · 03", "title":"黎明之前", "text":"暗影没有消失，虚空仍在城外凝视。但机械城重新呼吸，而下一班列车已经鸣笛。", "accent":Color(1.0, 0.72, 0.32), "glyph":"CITY//BREATHING"},
]
