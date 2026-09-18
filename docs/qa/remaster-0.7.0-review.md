# 0.7.0 进化技能画面验收

2026-09-19，RTX 5070 Laptop，Vulkan Forward+，1280×720。13 张开发运行图和 2 张独立发布 EXE 图均分别打开检查。

| 图片（remaster/qa） | 核查结论 |
|---|---|
| evolution_shadow_tree.png | 进化分页、暗影子分支、投入点数及前置连线清楚；强化后显示实际 14 秒 |
| evolution_shadow_summon_preview.png | 影侍预览、16 秒说明、学习状态完整 |
| evolution_mechanical_tree.png | 机械子分支、战甲预览、移速代价和减伤说明均可读 |
| evolution_mechanical_summon_preview.png | 炮台预览及不耗弹药说明完整 |
| evolution_xbox_tree.png | 变身/召唤组合键提示正确，详情无裁切 |
| evolution_pc_guide.png / evolution_xbox_guide.png | 新控制说明在指南内完整显示，没有压住底部按钮 |
| evolution_shadow_form.png | 修正侧面过薄的翼饰后，暗影轮廓、核心及倒计时可辨认 |
| evolution_mechanical_form.png | 肩甲、背部动力装置和当前形态提示可见 |
| evolution_shadow_summon_windup.png / evolution_shadow_summon_strike.png | 影侍接近目标、命中后伤害数字可见，日志记录一次实际攻击 |
| evolution_mechanical_summon_windup.png / evolution_mechanical_summon_strike.png | 浮游炮台位置与命中反馈可辨，日志记录敌人减少 16 HP |
| published_0_7_0_title.png | 实际发行 EXE 显示 0.7.0 |
| published_0_7_0_evolution.png | 实际发行 EXE 加载进化分页、未学习前置状态及新 Blender 外观 |

第一轮变身截图碰到入场无敌闪烁，玩家恰好隐藏；最终诊断截图清除入场无敌后重拍。暗影模型在侧面过薄，已调整翼饰纵深和影侍展示角度后重拍。技能说明最初固定显示基础时长，已改为学习强化后显示真实时长。

变身目前使用附加装甲/翼饰与属性变化，沿用猎魂者骨架；召唤有移动、浮动、攻击起手和打击效果，仍属于待精修的美术动作。截图不代表已完成长时间手感、全部动作穿插或完整通关测试。实体 Xbox 未连接，只验模拟输入。

独立 EXE 不执行外部测试脚本的尝试没有产生截图，不计成功。最终通过既有内置截图入口及新增技能页选择参数运行实际发行目录 EXE，两次取得 REMASTER_CAPTURE 0，并退出 0；结果图已逐张查看。
