# 0.5.2 Windows 开发试玩版发布验收

2026-09-19。默认 PC 提示，检测到 Xbox / XInput 手柄连接时自动切换，最后一只断开后回 PC。连接期间键鼠操作不会切走 Xbox 提示；当前手柄断开暂停，重连保持暂停。菜单只轮询手柄轴，避免键盘方向键重复响应。

## 验证结果

共 **752 项检查、0 失败**。测试使用隔离的 `.godot-user` 和 `--remaster-test`，不改写真实玩家存档。

| 测试 | 数量 | 日志 |
|---|---:|---|
| 基础世界与系统 | 287 | [test_remaster](device_test_remaster.log) |
| 战斗 | 18 | [test_combat_release](device_test_combat_release.log) |
| 动作与关卡 | 88 | [test_revision](device_test_revision.log) |
| 体验与设置 | 155 | [test_experience](device_test_experience.log) |
| 存档与伤害 | 38 | [test_preview](device_test_preview.log) |
| 武器与伙伴 | 77 | [test_arsenal](device_test_arsenal.log) |
| Xbox 输入和菜单 | 59 | [test_controller](device_test_controller.log) |
| 连接状态切换 | 30 | [test_device_switch](device_test_device_switch.log) |

已扫描完整日志。headless 测试及导出存在已知的本机 `Failed to read the root certificate store`，未发现脚本错误或测试失败。GPU 场景的 [stdout](device_visual.log) 记录五次截图成功、0 失败，[stderr](device_visual_errors.log) 为空。

最终五张场景图及一张独立 EXE 标题图均逐张查看。布局修正和验证边界见 [画面验收](../../docs/qa/remaster-0.5.2-review.md)。

## Windows 本机交付

release 导出、打包成功；ZIP 内 6 个文件逐个核对，复制到本机发行目录后再次核对 SHA256。旧版本 ZIP 保留。

- 目录：`E:\Godot\release\暗影机械城重制版`。
- ZIP：`E:\Godot\release\暗影机械城重制版-0.5.2.zip`，92,311,740 字节。
- ZIP SHA256：`1f06eb64ea4cbf1dc3869fca272395d46f1dcc74b17f32213e979fffde9d8244`。
- EXE SHA256：`5253e08aa5cf94804db7e3fe912fb412616cba0645241998ce9a4b4eb37b5f6f`。
- PCK SHA256：`fceeb637949cbb445f457ac0687ce095997c5b6b9537ce5172f5cd19dc47ad6b`。

发布目录中的 EXE 使用实际显卡启动成功并退出 0：[标题截图](published_0_5_2_title.png)、[stdout](published_0_5_2_title.log)、[空 stderr](published_0_5_2_title_errors.log)。实际无实体手柄，因此发布 EXE 显示 PC 按键。

本版仍是开发试玩版，未上架 itch.io。手柄相关检查使用模拟设备描述和输入事件；真实 Xbox USB / 蓝牙、物理热插拔、手感、重绑、震动及完整重制的其他未完成项仍待处理。
