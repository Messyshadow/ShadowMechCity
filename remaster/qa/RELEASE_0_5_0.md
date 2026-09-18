# 0.5.0 Windows 开发试玩版验收

日期：2026-09-19。范围：七类武器、33 个技能节点、四种机械伙伴与最多三台编队，以及存档恢复和战斗结算修复。完整重制尚未完成，范围见 [原设计与新需求对照表](../../docs/REMASTER_ROADMAP.md)。

## 自动回归

所有测试使用隔离的 `.godot-user` 和 `--remaster-test`，不改写玩家存档。六套测试均退出 0，共 **663 项检查，0 失败**。

| 测试 | 检查数 | 结果日志 |
|---|---:|---|
| 原有基础系统与房间连接 | 287 | [test_remaster](arsenal_test_remaster.log) |
| 发布战斗回归 | 18 | [test_combat_release](arsenal_test_combat_release.log) |
| 动作、通道、技能与扩展回归 | 88 | [test_revision](arsenal_test_revision.log) |
| 设置、新区域、任务等体验回归 | 155 | [test_experience](arsenal_test_experience.log) |
| 存档恢复、死亡加载、实际伤害吸血 | 38 | [test_preview](arsenal_test_preview.log) |
| 新武器、伙伴与七位 Boss 专项 | 77 | [test_arsenal](arsenal_test_arsenal.log) |

新增检查覆盖双刀连击与多段技能、长枪范围/破盾/墙体遮挡、弩箭贯穿及弹药、技能前置、武器切换与动作资源；伙伴栏位费用、唯一阵容、地面/空中跟随、独立生命、弹道拦截、修复、损毁重构、菜单暂停、回收/切房保存及过热。

七位 Boss 专项分别运行三台伙伴参与的二阶段 AI，每场推进 600 个物理帧，验证 Boss 实际受伤、编队数量和数据有效性。为控制场景，玩家设为无敌；这不是完整人工通关或难度平衡验收。

存档专项覆盖损坏主档恢复备份、临时档恢复、错误结构/重复装备 UID/未知格式/非法数值、提交失败回退、损坏文件原样归档、新游戏确认、旧重制档迁移、死亡时加载和未知房间回退。伤害专项检查减伤后吸血、过量伤害上限、死亡目标和死亡玩家不能被迟到奖励复活。

已扫描以上完整日志：无脚本错误或测试失败。沙箱 headless 启动仍报告 `ERROR: Failed to read the root certificate store.`，是本机证书读取限制；没有将它写成“所有日志无 ERROR”。下述真实 GPU 运行的 stderr 均为空。

## 真实 GPU 画面检查

Godot 4.7 rc custom / Vulkan 1.4.329 / Forward+ / NVIDIA GeForce RTX 5070 Laptop GPU。使用 [capture_arsenal.gd](../tests/capture_arsenal.gd) 运行实际场景，20 张最终截图全部逐张查看；两次发布 EXE 截图也单独查看，共 **22 张**。

- [20 张截图运行日志](arsenal_visual.log)，截图失败数 0；[stderr](arsenal_visual_errors.log) 为空。
- [技能分支与长枪预览](arsenal_skills_5.png)、[三台伙伴实机](arsenal_squad.png)、[伙伴详情](arsenal_roster_wisp.png)。
- 修正长枪预览朝向和相机范围，完整枪身可见；为伙伴 HUD 添加按阵容高度自适应的深色底板。
- 双刀、长枪、弓弩分别检查两帧姿态；修复检查实际生命从 60 到 64；损毁检查显示重构倒计时。
- [详细画面记录与全部截图索引](../../docs/qa/remaster-0.5.0-review.md)。截图验证不替代连续操作手感、音频混音或多硬件性能测试。

## 构建与本机发布

Blender 4.2.9 实际生成三种新武器、四种伙伴及其 `.blend` / `.glb`，并重建主角动画。运行时共有 54 个 GLB；主角 46 段动画，四种伙伴各 5 段。

Windows release 导出与 `source/package_release.py` 均成功。ZIP 内 6 个文件与构建目录逐个校验一致，本机发布目录与 ZIP 的 SHA256 也与构建结果一致。旧版本 ZIP 保留。

- 独立运行目录：`E:\Godot\release\暗影机械城重制版`。
- 压缩包：`E:\Godot\release\暗影机械城重制版-0.5.0.zip`，92,297,792 字节。
- ZIP SHA256：`87165ab889fa725586cb43711c4861684e26117ccd1804c2336293508229f090`。
- EXE SHA256：`a0d629eff4e3b0005a41fc2bfc63f2d735041bc9e1517742816cd59c6c8ef916`。
- PCK SHA256：`e9456b446c1432d7bdf4589ee65640a72aebfa988781a6011a16124201c9ec29`。
- 包含玩家操作说明、启动说明、版本说明与校验清单。

从发布目录直接启动 EXE 两次，分别打开标题和伙伴面板；均正常截图并退出 0，stderr 为空，使用隔离测试数据。

| 场景 | 截图 | stdout | stderr |
|---|---|---|---|
| 0.5.0 标题 | [图片](published_0_5_0_title.png) | [日志](published_0_5_0_title.log) | [空日志](published_0_5_0_title_errors.log) |
| 新档伙伴面板 | [图片](published_0_5_0_companions.png) | [日志](published_0_5_0_companions.log) | [空日志](published_0_5_0_companions_errors.log) |

这里的发布指本机 Windows 包交付。itch.io 仅准备了 [页面草稿](../publishing/ITCH_PAGE_DRAFT.md)，尚未创建公开商品页。

## 保留限制

- 当前是开发试玩版。40 房间、七类武器、七位 Boss 不等于商业 GDD 的全部体量。
- 旧能力获取/专属机关、全部 NPC/支线、黑客入侵、虚拟量子空间与原量子升级体系等仍有未迁入内容。
- 七种武器在试玩版直接提供；旧变体武器的解锁、获取与特性尚未全部还原。
- 美术/动作/音效精修、完整人工通关、多硬件/分辨率测试、手柄和按键重绑仍待完成。
- 版本号不代表完成百分比，不能以此保证明晚完成全部重制范围。
