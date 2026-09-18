# 重制版 0.5.1 Xbox 手柄验收

2026-09-19。基于 0.5.0 增加 Xbox 布局、菜单导航与设备提示切换。本机没有连接实体手柄，专项通过 `Input.parse_input_event()` 注入标准按钮/轴事件并运行真实游戏逻辑；不能代替 USB、蓝牙或长时间操作手感验证。

## 操作与关键行为

- A 跳跃、X 普攻、Y 终阶技能、B 冲刺；左摇杆或方向键移动攀爬。
- LB 换武器、RB 交互、LT 治疗、RT 装填；L3 部署/回收，R3 阵容。
- View 打开背包；LB/RB 轮换背包、技能、地图、任务、伙伴。Menu 暂停，菜单 A 确认、B 返回。
- 地图右摇杆平移、LT/RT 缩放、X 定位、Y 全图；设置左右调整滑块，背包跟随焦点滚动。
- 动作映射注册可重复调用，保留键盘操作。菜单关闭时已按住的动作必须先释放，防止误跳跃、冲刺、治疗和装填。
- 左摇杆死区 0.25，菜单方向有启动延迟与持续重复。最后使用的手柄断开时暂停；工程配置忽略后台手柄输入。

## 自动检查

[手柄专项日志](../../remaster/qa/controller_tests.log)：59 项检查，0 失败。覆盖动作映射、真实角色响应、模拟漂移、模拟按住/释放、界面确认和返回、五个功能页、焦点恢复、滑块连按、地图、商人交互、背包滚动、断开回调与键盘恢复、双设备提示和标题/序章返回。

原有六套回归共 663 项，合计 722 项。逐份结果见 [发布记录](../../remaster/qa/RELEASE_0_5_1.md)。headless 沙箱仍有本机根证书读取错误；不得将其描述为所有日志无 ERROR。实际 GPU 截图 stderr 为空。

输入实现参考 [Godot 官方手柄文档](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html) 的动作映射、死区、方向重复及后台输入说明。项目逻辑以本地测试为依据，不因引擎支持列表就宣称所有硬件可用。

## GPU 画面复核

实际运行 Godot 4.7 rc custom、Vulkan Forward+、RTX 5070 Laptop。最终七张图片逐张查看；采集日志记录七次成功及 0 失败。

| 截图 | 检查结果 |
|---|---|
| [标题](../../remaster/qa/controller_title.png) | 版本 0.5.1；A 确认提示；金色焦点清晰 |
| [游戏 HUD](../../remaster/qa/controller_hud.png) | Xbox 按键、RB 交互、L3/R3 提示和摇杆梯井标记可读 |
| [技能](../../remaster/qa/controller_skills.png) | 金色焦点与蓝色已选择分支可区分，Y 技能提示，功能页导航 |
| [设置](../../remaster/qa/controller_settings.png) | 聚焦滑块为金色，底部说明左右调整 |
| [地图](../../remaster/qa/controller_map.png) | 右摇杆/扳机操作说明，当前按钮的金色焦点 |
| [指南](../../remaster/qa/controller_guide.png) | 独立手柄说明，避免替换键名后产生孤行或拥挤 |
| [背包](../../remaster/qa/controller_inventory.png) | 列表已向下滚动，底部选中装备按钮可见 |

本轮修正了初版中焦点与普通高亮难以区分、场景仍显示 E/W/S、指南换行不自然的问题。静态截图只用于检查布局和标记，不当作跳跃手感或输入延迟证明。

## 仍待验证或实现

实体 Xbox 手柄的 USB / 蓝牙、热插拔实际事件、模拟轴与扳机手感、不同设备驱动兼容性；按键重绑和震动未实现。完整重制项目仍有 [开发对照表](../REMASTER_ROADMAP.md) 中的其他未完成内容。
