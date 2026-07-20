# 13B QA：双刀、长枪与弓弩武器家族

日期：2026-07-20

## 交付范围

- 新增三件可持久解锁、可在装备仓库查看并立即装备的真实武器：影铸双刃、天穹齿轮枪、裂隙连发弩。
- 三件武器分别放入熔炉区秘室“废热回收井”、遗迹圣殿秘室“星轨祭坛”、虚空要塞秘室“裂隙观星台”；奖励点与敌人生成点保持安全距离，避免拾取物与敌人重叠。
- 双刀实现高速四段普攻、交叉处决、上挑刃舞、追身突进、环形刃爆与终结技；长枪实现三段突刺、直线重击、上挑、蓄力贯穿、环扫与终结技；弓弩实现二段射击、重弩箭、对空射击、后撤连射、环形齐射与终结技。
- 技能矩阵的战斗页新增双刀、长枪、弓弩三套真实树，每套含家族根节点、成长节点和组合技节点；右侧同步显示武器动作预览、触发按键、组合输入、使用方法、效果、等级与前置条件。
- 装备仓库的武器分类直接投影当前存档已解锁武器；选中后显示来源、攻击力、攻击节奏、组合技，并可设为当前武器。

## TDD 与回归证据

- 新增 `tests/test_stage_13_b.gd`，覆盖武器数据与素材、秘室奖励、敌人安全半径、战斗实现标记、技能节点、背包投影、截图选择索引、武器缩放与世界拾取物真实外观。
- 开发过程中先让缺失契约出现 RED，再按武器数据、奖励与装备、攻击差异、技能树接入、截图缺陷修复逐批转为 GREEN。
- 最终全量运行 15 项测试：`VERIFY_TOTAL=15`、`VERIFY_FAILED=`；每项 `EXIT=0`、有效错误数为 0。
- 编辑器全项目解析：`EDITOR_EXIT=0`、`EDITOR_ERRORS=0`。

## godot-capture 目视验收

以下 PNG 均由项目指定的源码编译 Godot 实际运行生成，并已逐张打开查看：

- `screenshots/13B/skill-dual.png`、`skill-spear.png`、`skill-crossbow.png`：三套武器树在 1280×720 安全区内完整显示；选中双环、连线、动作预览和组合教学无裁切。
- `screenshots/13B/inventory-weapons.png`：三件新武器出现在武器分类中；修复了 QA 虚拟源索引导致右侧详情空白的问题。
- `screenshots/13B/motion-dual-normal/`、`motion-spear-dash/`、`motion-crossbow-burst/`：连续帧显示三类武器的攻击轮廓、位移和弹道确有区分；修复了新武器投影过大的问题。
- `screenshots/13B/pickup-dual.png`、`pickup-spear.png`、`pickup-crossbow.png`：世界奖励由通用光球改为真实武器 SVG、家族色光环与名称；虚空弩奖励经两次移位后与风暴法师、机械鹰均不重叠。
- `screenshots/13B/release-skill-tree.png`：从发布目录直接启动 EXE 后，弓弩页选中“裂隙钉阵”，右侧显示动作预览、`J → J，随后 ↓ + K` 和使用方法。
- `screenshots/13B/release-inventory.png`：从发布目录直接启动 EXE 后，装备仓库选中“裂隙连发弩”，显示秘室来源、攻击 6、二段射击及组合技 `crossbow_barrage`。

## 运行与错误扫描

- 实际主场景由 `Godot Engine v4.7.rc.custom_build.df6235838` 启动，Vulkan Forward+ 使用 NVIDIA GeForce RTX 5070 Laptop GPU。
- 主场景运行 240 帧结果：`RUNTIME_EXIT=0`、`RUNTIME_ERROR_COUNT=0`；扫描全部 `ERROR:` / `SCRIPT ERROR`，未发现有效错误。
- 发布版技能树与背包两次直启截图进程均为 `Exit 0`。第一次未设置 `SHOT_ROOM` 时只截到标题菜单，已明确判为无效证据；补充现有直达钩子后重抓并目视通过。

## 素材与许可证

- `assets/weapons/dual_blades.svg`、`spear.svg`、`crossbow.svg` 均为本项目原创程序化 SVG，未使用外部下载素材或商业游戏截图。
- 详细来源与许可记录见 `docs/assets/13B-original-assets.md`，无第三方署名义务。

## 发布证明

- 使用项目指定的源码编译 Godot 与自定义 Windows release 模板导出到 `E:\Godot\release\暗影机械城`。
- `ShadowMechCity.exe`：68,143,616 bytes，2026-07-20 20:52:41，SHA-256 `1529C04A88DAAAD7C2683259388EBBE1B730F10F9DC9FE9A1EA81C0CE7619B0F`。
- `ShadowMechCity.pck`：10,879,188 bytes，2026-07-20 20:52:45，SHA-256 `A1FA85738938701E03129D2A4C8DA7D62C9AAFCA997D3DE19D63CFC309A47F86`。
- EXE 是稳定的源码编译 release 模板，玩法变更主要体现在同目录 PCK；本次 PCK 时间、体积与 SHA-256 均已更新，且发布版直启截图证明 13B 内容已进入包体。

## 诚实边界

- 自动化与逐帧截图可以证明数据接入、布局、碰撞安全距离、动画/特效差异和发布包内容，不能替代策划使用键鼠长期试玩后的节奏与数值平衡评价。
- 本阶段未宣称完成后续 13C“敌人多样性/协同进攻”与 13D“多层打击感/全区美术音频统一”；这些仍按 DEV_PLAN 保留为下一批次。
