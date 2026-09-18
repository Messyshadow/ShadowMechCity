# 0.6.0 Windows 开发试玩版发布验收

2026-09-19。接入原版五种探索模块、六生命碎片、七记忆核心与秘室条件；新增炸弹破封板、八区域补给箱、三页档案和地图收藏统计。七种新增 Blender 资产及源文件保留。完整重制仍在进行。

## 自动检查

最终 **934 项、0 失败**。使用隔离 `.godot-user` 和 `--remaster-test`，未更改真实玩家存档。

| 测试 | 数量 | 日志 |
|---|---:|---|
| 基础世界与系统 | 287 | [test_remaster](exploration_test_remaster.log) |
| 战斗 | 18 | [test_combat_release](exploration_test_combat_release.log) |
| 动作与关卡 | 88 | [test_revision](exploration_test_revision.log) |
| 体验与设置 | 155 | [test_experience](exploration_test_experience.log) |
| 存档与伤害 | 38 | [test_preview](exploration_test_preview.log) |
| 武器与伙伴 | 77 | [test_arsenal](exploration_test_arsenal.log) |
| Xbox 输入与菜单 | 59 | [test_controller](exploration_test_controller.log) |
| 设备自动切换 | 30 | [test_device_switch](exploration_test_device_switch.log) |
| 探索、补给与收藏 | 182 | [test_exploration](exploration_test_exploration.log) |

探索专项覆盖原数据数量、40 房间拾取物、奖励去重、库存上限、已到达秘室兼容、实际炸弹计时/碰撞/伤害、封板破坏与重访、死亡拒收、存档往返、键盘和模拟 Xbox 组合键、焦点滚动、从地面双跳取得生命碎片，以及商人/敌人/Boss/存档点补给数值。

原有回归发现新增低台影响行走和治疗伙伴视线；最终取消额外平台，把奖励放在既有跳跃台上。保留原测试断言，全部复测通过。

已扫描全部 ERROR / SCRIPT ERROR 行。当前受限环境下 headless、GPU 和独立 EXE 都记录 `Failed to read the root certificate store`，其余未发现脚本、物理或资源错误。不能将这些 stderr 描述为空。

## 实机画面

RTX 5070 Laptop、Vulkan Forward+、1280×720。11 张最终内容图与 2 张发布 EXE 图均逐张检查，详见 [画面验收](../../docs/qa/remaster-0.6.0-review.md)。截图只验证可见内容，不能代替完整人工通关或实体手柄测试。

## Windows 本机交付

ZIP 内 6 个文件逐项验证，发行目录复制后再次逐个比较 SHA256，保留旧版本 ZIP。实际发行目录 EXE 分别打开标题与新增档案页，均成功截图并退出 0。

- 目录：`E:\Godot\release\暗影机械城重制版`。
- ZIP：`E:\Godot\release\暗影机械城重制版-0.6.0.zip`。
- ZIP 大小：97,088,979 字节。
- ZIP SHA256：`65443c5cfc0cdf32b2367951f3f95c500f6b1dbfc8ed55c91424537d45009b6e`。
- ShadowMechCityReforged.exe SHA256：`aa167ac0c75f71d733eff95c40427708367a797dd98525e2e03846b8084e139a`。
- ShadowMechCityReforged.pck SHA256：`ee2d7c914f811b8b8fc1cee02045aa5e6f70749973df173075ac84e80b8447f8`。

[EXE 标题](published_0_6_0_title.png) / [日志](published_0_6_0_title.log) / [stderr](published_0_6_0_title_errors.log)；[EXE 档案](published_0_6_0_collection.png) / [日志](published_0_6_0_collection.log) / [stderr](published_0_6_0_collection_errors.log)。

未上架 itch.io。原五 NPC 与支线、复杂环境机关、量子完整升级、黑客与虚拟空间、艺术精修及正式发布验收仍待推进，参见重制对照表。
