# 0.5.1 Windows 开发试玩版发布验收

2026-09-19。加入 Xbox 布局、菜单焦点导航、地图操作、摇杆死区、输入隔离、断开暂停与设备提示切换。完整操作见 [玩家指南](../PLAYER_GUIDE.md)，画面判断见 [手柄验收记录](../../docs/qa/remaster-0.5.1-review.md)。

## 检查结果

七套测试均正常结束，**722 项检查、0 失败**。使用隔离的 `.godot-user` 和测试模式，不操作真实玩家存档。

| 测试 | 检查数 | 日志 |
|---|---:|---|
| 基础世界与系统 | 287 | [test_remaster](controller_test_remaster.log) |
| 战斗 | 18 | [test_combat_release](controller_test_combat_release.log) |
| 动作与关卡 | 88 | [test_revision](controller_test_revision.log) |
| 设置、任务等体验 | 155 | [test_experience](controller_test_experience.log) |
| 存档与伤害 | 38 | [test_preview](controller_test_preview.log) |
| 武器与伙伴 | 77 | [test_arsenal](controller_test_arsenal.log) |
| Xbox 模拟事件与菜单 | 59 | [test_controller](controller_tests.log) |

headless 测试与导出日志只有已知本机根证书读取错误 `Failed to read the root certificate store`，未发现脚本错误或测试失败；实际 GPU 运行的 stderr 为空。

实际 GPU 运行完成 7 张场景截图，最终图片逐张查看，另查看发布 EXE 标题截图，共 8 张。已修正手柄焦点不明显、场景键名未切换及指南换行问题。[截图日志](controller_visual.log) 显示 0 失败，[stderr](controller_visual_errors.log) 为空。

## 独立包

Windows release 导出与 ZIP 构建成功。包内 6 个文件逐个校验一致，复制到发布目录后再次核对全部 SHA256；旧版 ZIP 保留。

- 本机目录：`E:\Godot\release\暗影机械城重制版`。
- 本机包：`E:\Godot\release\暗影机械城重制版-0.5.1.zip`。
- ZIP：92,309,640 字节，SHA256 `6e2304a18252c8719849d4d01ec454b8ff68686da37a7f2f031d7019c0447ac2`。
- EXE SHA256：`e49e5b2fabcb08e92c8869d30e25296afd023dc476110d0a5b44205575e7eaba`。
- PCK SHA256：`d7ce3843c6d0aa2b5dce0a4f1b5573039297d48d50c9fe8a5bb91164f6d633a7`。

直接从本机发布目录启动独立 EXE，使用 Vulkan / RTX 5070 Laptop 正常显示 0.5.1 标题并退出 0：[截图](published_0_5_1_title.png)、[stdout](published_0_5_1_title.log)、[空 stderr](published_0_5_1_title_errors.log)。独立包启动截图使用键盘模式；Xbox 提示和输入逻辑的验证由前述场景截图及专项测试提供。

## 明确保留的限制

`Input.get_connected_joypads()` 返回空数组。本轮使用标准 Xbox 按钮与轴事件模拟，不代表真实 USB / 蓝牙手柄、驱动兼容性、物理热插拔或输入延迟已经验收。按键重绑、震动、多玩家未实现。本机发布不等于 itch.io 已上架，完整重制也尚未完成。
