# 重制版 0.5.0 画面与发布验收

2026-09-19。使用实际 GPU 场景截图检查最终画面，没有以 headless 输出代替渲染。20 张场景截图与 2 张发布 EXE 截图均逐张查看。全部检查结果及发布包校验见 [发布验收记录](../../remaster/qa/RELEASE_0_5_0.md)。

## 检查发现与修正

- 长枪初版预览朝向镜头、枪身显短：调整展示朝向及相机范围后，完整枪杆与枪尖可见。
- 编队状态文字与亮色地面混合：增加深色底板，高度随当前阵容变化；三台伙伴的生命/重构文字可读。
- 画面采集原先按渲染帧等待，不能可靠推进修复计时：改用物理帧，并断言生命恢复至 64 后采集；空场景关闭测试玩家的闪烁无敌，避免主角恰好隐去。
- 新武器技能页保留七种武器名称、分页、前置和详情，预览模型可见；伙伴四张详情卡模型区别清楚，没有发现文字越界或按钮被裁切。

## 最终截图索引

下列是最后一轮实际输出，已分别查看。

| 画面 | 核验重点 |
|---|---|
| [标题](../../remaster/qa/arsenal_title.png) | 0.5.0 与开发试玩版标识 |
| [存档恢复](../../remaster/qa/arsenal_recovery.png) | 恢复说明、重试与新游戏确认入口 |
| [双刀技能](../../remaster/qa/arsenal_skills_4.png) | 武器名称、三个节点与预览 |
| [长枪技能](../../remaster/qa/arsenal_skills_5.png) | 完整长枪预览及前置关系 |
| [弓弩技能](../../remaster/qa/arsenal_skills_6.png) | 弩模型、贯穿与弹药说明 |
| [先锋犬](../../remaster/qa/arsenal_roster_hound.png) | 地面攻击伙伴详情与模型 |
| [壁垒鼹](../../remaster/qa/arsenal_roster_mole.png) | 防护伙伴详情与模型 |
| [天轨蜂](../../remaster/qa/arsenal_roster_bee.png) | 飞行攻击伙伴详情与模型 |
| [流明萤](../../remaster/qa/arsenal_roster_wisp.png) | 飞行修复伙伴详情与模型 |
| [三台编队](../../remaster/qa/arsenal_squad.png) | 地面/空中站位、生命状态栏对比度 |
| [双刀帧一](../../remaster/qa/arsenal_weapon_4_windup.png) / [帧二](../../remaster/qa/arsenal_weapon_4_strike.png) | 双持与不同攻击姿态 |
| [长枪帧一](../../remaster/qa/arsenal_weapon_5_windup.png) / [帧二](../../remaster/qa/arsenal_weapon_5_strike.png) | 枪身与挥刺姿态 |
| [弓弩帧一](../../remaster/qa/arsenal_weapon_6_windup.png) / [帧二](../../remaster/qa/arsenal_weapon_6_strike.png) | 射击姿态和弹道 |
| [修复前](../../remaster/qa/arsenal_repair_windup.png) / [修复后](../../remaster/qa/arsenal_repair_resolve.png) | 60 → 64 生命与修复反馈 |
| [损毁重构](../../remaster/qa/arsenal_reconstruction.png) | 重构倒计时与其他伙伴仍在场 |
| [操作指南](../../remaster/qa/arsenal_guide.png) | C 部署/回收、G 阵容及七武器操作 |
| [发布 EXE 标题](../../remaster/qa/published_0_5_0_title.png) | 独立包实际版本 |
| [发布 EXE 伙伴](../../remaster/qa/published_0_5_0_companions.png) | 新档一栏位与可用技能点、实际模型 |

## 验收边界

663 项自动检查通过，包括三伙伴参与七位 Boss 二阶段的受控专项；这不代表完整人工通关。截图中的帧名用于记录采集顺序，静态图不用于断言逐毫秒出招时序或手感。当前模型为风格化低多边形，精修、声音试听、长流程平衡和不同硬件性能仍需继续。

原设计所有步骤与新增需求保留在 [重制对照表](../REMASTER_ROADMAP.md)，未将 2D 原版的完成勾选直接转记为 3D 完成。
