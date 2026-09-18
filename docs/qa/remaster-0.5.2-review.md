# 重制版 0.5.2 设备自动切换验收

2026-09-19。按用户要求，提示模式由连接状态决定：无 Xbox 时默认 PC，启动前已有或游玩中连接 Xbox / XInput 时自动切换；键鼠操作不抢走提示，键鼠仍可用。最后一只断开后恢复 PC，当前使用的手柄断开时暂停；重新接入不自动恢复战斗。

设备识别读取本地 Godot SDL 实现提供的名称、raw_name、vendor_id 与 xinput_index；兼容该构建把设备 ID 返回为十进制字符串的行为。不把 DualSense、Switch Pro 或未知 USB Joystick 直接标成 Xbox。只保留识别出的设备编号，不保存硬件序列号。

## 测试

新增 [设备切换专项](../../remaster/tests/test_device_switch.gd) 30 项通过，原 [手柄专项](../../remaster/tests/test_controller.gd) 59 项通过；连同世界、战斗、动作、任务、存档与伙伴回归共 752 项，0 失败。[发布与日志索引](../../remaster/qa/RELEASE_0_5_2.md)。

专项覆盖默认 PC、启动时已有连接、热接入注册、识别不同设备信息格式、键鼠不抢提示、键盘在菜单中只移动一次、键鼠游玩仍有效、非 Xbox 不抢占、多只手柄、非当前手柄断开、当前手柄断开暂停、最后一只断开、重连保持暂停，以及通知更新。

当前环境没有实体手柄。设备描述和标准输入事件由测试注入；真实系统的 USB / 蓝牙驱动和热插拔事件仍未验收。不能以这些测试宣称实体 Xbox 已完成实测。

## GPU 截图

使用实际 Vulkan / RTX 5070 Laptop 运行游戏；以下五张最终截图均逐张查看。

| 截图 | 判断 |
|---|---|
| [默认 PC](../../remaster/qa/device_default_pc.png) | 标题显示 Enter / Esc，没有 Xbox 导航页脚 |
| [连接后标题](../../remaster/qa/device_connected_title.png) | 未按手柄即切成 A / B，连接通知可见 |
| [连接后 HUD](../../remaster/qa/device_connected_hud.png) | 注入鼠标移动后仍显示 Xbox、RB 交互和摇杆梯井标记 |
| [断开后 PC 暂停](../../remaster/qa/device_disconnected_pc.png) | Esc/J/空格/W/S/R/H 恢复，游戏处于暂停 |
| [重连后暂停](../../remaster/qa/device_reconnected_pause.png) | Xbox 文案恢复、连接通知更新，仍在暂停菜单 |

初版截图发现断开通知与暂停菜单底部按钮重叠，已把菜单中的临时通知移到顶部。最终通知与按钮不重叠；测试描述注入与真实连接回调共用同一注册和通知路径。

另外逐张查看了 [独立发布 EXE 标题](../../remaster/qa/published_0_5_2_title.png)：版本 0.5.2，无实体设备时默认 PC 提示。画面合计 6 张。GPU stderr 为空；headless 仍有本机证书读取限制，详见发布记录。
