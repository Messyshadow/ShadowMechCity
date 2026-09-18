# 0.3.0 体验与内容验收

2026-09-19，Windows / Godot 4.7.rc 自定义构建 / Vulkan Forward+ / RTX 5070 Laptop GPU。

## 交付范围

- 场景提高环境光、补光和平台边缘可见度，保留各区域暗色背景。增加 85%–150% 可保存亮度设置。
- 主菜单、设置、序章、操作指南、任务记录与 NPC 对话；F11 全屏和窗口切换，四类独立音量、静音、震动和教学开关。
- 战斗、身法、暗影 / 机械三大技能分页。四类武器保留，技能从 12 扩充为 24；前置连线、学习条件、实际效果与动作预览清晰显示。
- 新增晨曦温室的升光庭院、棱镜回廊、引航灯塔，世界由 37 扩充至 40 房间；2D 原版的房间数据不受影响。
- 新增盾卫、潜袭者、巡线员莉娅、花箱与引航灯塔的 Blender 源文件及运行时模型，模型共 47 个，动画角色共 15 个。
- 「让灯再次亮起」委托可接取、完成、返回领奖，清敌条件、一次性奖励和保存恢复有效；灯塔重启后实际点亮。
- 敌人受击闪光、短暂停顿、出招动作重播和死亡动作保留；商店补给上限、价格与赠礼状态显示。

## 自动检查

| 套件 | 通过 | 内容与证据 |
|---|---:|---|
| test_remaster | 287 | 原世界、交易、回购、存档、原入口、Boss 和 UI；[日志](experience_test_remaster.log) |
| test_combat_release | 18 | 实际命中、掩体、弹药、连击和吸血；[日志](experience_test_combat_release.log) |
| test_revision | 88 | 原 30 个普通房间碰撞通行、楼梯、强化、骨骼姿态和七位 Boss 招式；[日志](experience_test_revision.log) |
| test_experience | 155 | 新区域往返入口及实际移动跳跃、委托防重复、全部新技能学习和实际物理/战斗效果、设置控件信号、配置/存档往返、菜单段落布局；[日志](experience_test_experience.log) |

共 **548 项，0 失败**，四个 Godot 进程退出码均为 0。测试禁用正式持久化，使用独立测试文件与 `.godot-user` 数据目录。Headless 的唯一 ERROR 为受限运行环境读取根证书库失败；没有脚本错误或游戏断言失败，GPU 错误日志为空。

## 实机画面

`capture_experience.gd` 捕获 26 张 1280×720 实际渲染截图，并检查操作系统已切换为全屏/窗口模式。截图用于检查画面与动作姿态，不代替完整人工操作通关。

逐张检查的画面：

- 七个旧区域：`experience_hub`、`temple`、`mine`、`water_grotto`、`factory_works`、`void_deck`、`castle_gallery`。前景人物、平台边缘、入口和机关能与背景区分；保留暗色层次。工厂截图处于楼梯边缘下落状态，通行另由物理测试验证。
- 三个新房间：`dawn_garden`、`dawn_conduit`、`dawn_beacon`。花箱、棱镜回廊的涡轮、灯塔分别作为场景标识，未发现缺失材质。
- `tutorial`、`open_title`、`open_story`、`open_guide`、`open_settings`、`open_shop`、`open_npc`、`open_journal`、`skills_0`、`skills_1`、`skills_2`、`map`。修复长段中文初始最小宽度导致的换行失效；身法连线改为绕开节点和标题；NPC 使用实际莉娅模型预览。
- `stalker_windup`、`stalker_lunge`、`warden_hit`、`beacon_online`。潜袭者起手/冲锋姿态不同，盾卫有受击亮闪和减伤提示，灯塔开启后有持续照明。敌人姿态截图使用冻结布置，实际状态与伤害由测试覆盖。

证据：[渲染日志](experience_visual.log)、[错误日志](experience_visual_errors.log)。所有截图以 `experience_` 为前缀保存在本目录。

## 尚未完成

这是可玩开发版，不能标为完整重制完成。旧版双刀、长枪、弓弩、召唤伙伴与更多旧技能尚未迁入。新敌人沿用同一机械骨架体系，模型、动作、美术布局、音效混音和难度曲线仍需精修；只有一条新增支线委托，没有完成大型剧情/NPC 系统。未进行全流程人工通关、长时间压力测试、多显卡兼容性或人工听音验收。
