# 暗影机械城 · 重铸余烬

当前开发试玩版 **0.5.2**：Xbox 操作与菜单导航、七武器家族、33 个技能节点、四种量子伙伴与最多三台编队，补强存档恢复和伤害结算。详见 [发布验收记录](qa/RELEASE_0_5_2.md) 和 [原设计与新需求对照表](../docs/REMASTER_ROADMAP.md)。完整重制仍在进行。

这是一套可运行的 **Godot 4.7 / 3D 横版平台动作重制版**。场景、角色、敌人、武器、建筑模块均为 Blender 建模并导出的 GLB；实际使用 CharacterBody3D、骨骼动画、3D 碰撞、灯光和粒子，角色活动限制在横版平面。

## 启动

- 工程根目录双击 `play_game.bat`，或打开 `project.godot` 按 F5。
- 独立版本：`build/Reforged/ShadowMechCityReforged.exe`，需要同目录的 `.pck`。
- 最新本机包：`build/Reforged/ShadowMechCityReforged.exe`，版本 **0.5.2**。
- 本机发布目录：`E:\Godot\release\暗影机械城重制版`；发布包：`E:\Godot\release\暗影机械城重制版-0.5.2.zip`。
- 原 2D 版本代码和资源保留，双击 `play_classic.bat` 可运行。
- 重制版使用独立文件 `remaster_v1.json`，不改写原版 `save.json`。保存位置沿用原项目的用户数据目录。

## 本次实现

| 系统 | 内容 |
|---|---|
| 世界 | 八个区域、40 个命名房间；新增晨曦温室三房间；七处秘室；区域建筑、移动平台、周期蒸汽、水面与通行标识 |
| 3D 资产 | 54 个 Blender 模型，包括猎魂者、商人、巡线员、五类普通敌人、七位 Boss、四种伙伴、建筑与装备；10 张 512px 装备渲染图 |
| 动作 | 主角 46 段、其余原有 14 个角色各 36 段、四种伙伴各 5 段骨骼动画；分武器连击、空中攻击、射击装填、楼梯、爬梯与技能预览 |
| 敌人 | 接近、瞄准、攻击预警、出招、收招、受击硬直；新增正面减伤盾卫和蓄力冲锋潜袭者；命中闪光、短暂停顿、保留死亡动作 |
| Boss | 七位核心守卫，按角色组合冲锋、震地、弹幕、低位波束、召唤；半血进入第二阶段 |
| 战斗分支 | 长刃、重锤、蒸汽炮、动力拳套、双刀、长枪、弓弩，21 个武器技能节点；拳套升龙、多段双刀、长枪破盾、贯穿弩箭 |
| 技能分页 | 战斗、身法、暗影 / 机械；共 33 节点，前置连线、详情和 3D 预览；三段跳、滑翔、蹬墙、水下推进、冲刺强化、受击保护、收招反击、生命强化、快速装填和超频均有实际效果 |
| 量子伙伴 | 先锋犬/壁垒鼹/天轨蜂/流明萤，两地面两空中，最多三台；独立生命、跟随、攻击/修复、弹道拦截、损毁重构、错峰、输出缩放和过热；阵容、生命与重构存档 |
| 弹药 | 8 发弹匣，有限备弹，R 装填；商人售弹，击败敌人回收弹药 |
| 商人 | 赫克首次交谈赠送并自动装备 3% 吸血护符；买补给/装备、卖装备、批量卖白装、独立永久回购栏；回购保留原 UID 与属性 |
| 掉落 | 后续仅护符随机掉落有 2% 概率附带吸血，取消通用装备的高频吸血；吸血合计上限 8% |
| 生存 | 初始 120 生命；手动激活终端确定重生房间及坐标；过房间不更新重生点；药剂、最低弹药补给、存档备份 |
| 装备 | 六槽装备概览、替换属性对比、最高 +5 强化；出售、回购和读档保持强化属性 |
| 地图 | 完整房间名称、探索状态、核心/秘室/存档点标记，滚轮缩放、拖动、当前位置和全图按钮 |
| 剧情引导 | 首次商人赠礼 → 四区域核心 → 天龙王座 → 王城骑士 → 虚空君王；任务文本指出下一相邻房间；通关结尾 |
| NPC 委托 | 巡线员莉娅「让灯再次亮起」：前往温室、清理守卫、重启灯塔、返回交付；80 金币 / 2 技能点，仅可领取一次，进度保存 |
| 设置与教学 | F11 全屏、独立分项音量、静音、亮度、镜头震动、教学开关；设置单独保存；序章、操作指南、情境提示、N 任务记录 |
| 声音 | 20 段原创合成音效；新增七区域与 Boss 共 8 段立体声循环配乐 |

## Xbox 手柄

A 跳跃、X 普攻、Y 武器技能、B 冲刺；左摇杆 / 方向键移动攀爬。View 打开背包，LB / RB 切换背包、技能、地图、任务与伙伴；Menu 暂停。无手柄默认 PC 提示；检测到 Xbox / XInput 连接即自动切换，连接期间键鼠操作不会切回 PC，最后一只断开后恢复。更多肩键、扳机、地图操作见 [玩家指南](PLAYER_GUIDE.md)。已验证模拟输入与实际画面，实体 USB / 蓝牙、长时间手感尚待测试；重绑与震动未实现。

## 通道修正

上下门有实体检修梯或升降机、护边与下层落脚平台。W / S 控制上下行，梯井方向与目的地显示在场景中。原破碎甲板与中央车站可双向往返；误落井底仍可按 S 进入下层或按 W 返回。骑士竞技场、君王升降井的重叠上下入口已分开，避免输入抓错梯井。低平台至少抬至 2.8 米，减少出生点顶头。

## 操作

| 按键 | 操作 |
|---|---|
| A / D 或左右 | 移动 |
| 空格 | 跳跃、二段跳、蹬墙跳 |
| W / S 或上下 | 楼梯、梯井、升降机和排水管上下行 |
| J / K | 普通攻击 / 已学习的武器终阶技能 |
| Shift / L | 无敌冲刺 |
| Q | 切换七类武器；也可在 T 技能树直接装备 |
| C / G | 伙伴部署/回收 / 阵容 |
| R / H | 装填 / 治疗 |
| E | 交易、存档、水平房间入口 |
| I / U、T、M | 背包、技能、地图 |
| N / F11 | 任务记录 / 全屏切换 |
| Esc | 关闭面板 / 暂停 |

## 可编辑来源与复现

- `source/*.blend`：可编辑 Blender 源文件，含角色骨架和动作；`source/build_assets.py` 生成基础建筑、装备模型与图标。
- `source/build_cast.py`：重建 12 个角色与 Boss，各含 36 段动画；`source/build_architecture.py` 重建 8 个区域建筑模块。
- `source/build_experience_assets.py`：重建盾卫、潜袭者、莉娅、花箱和引航灯塔；三个新增角色各含 36 段动画。
- `source/build_arsenal.py`：重建双刀/长枪/弓弩与四种伙伴；新增主角动画由 `build_cast.py -- hero` 生成。
- `source/build_score.py`：生成七个区域与 Boss 的原创立体声循环配乐；装备图标提高到 512px。
- `assets/models/*.glb`：运行时模型。无需安装 Blender 即可玩导出版。
- `source/build_audio.py`：Python 标准库生成原创音效。
- `state.gd`：独立存档、交易、回购、成长和装备。
- `controls.gd`：Xbox / 键盘动作注册、设备提示切换、菜单输入隔离和断开暂停。
- `save_io.gd`：完整快照验证、有效备份和损坏文件保留；`companions.gd` / `companion.gd` / `squad_data.gd`：伙伴编队、行为与持久化数据。
- `main.gd`：3D 世界、双向通道、任务线路；`world_data.gd` 独立复制原房间图后扩展，保留 2D 原版的 37 房间。
- `actor.gd` / `enemy.gd`：玩家与敌人动作、战斗、Boss AI。
- `ui.gd` / `experience_ui.gd` / `map.gd`：面板、三大技能分页、设置、对话与 3D 动作预览。

资产重建命令（在工程根目录运行）：

```powershell
& 'D:\Blender\blender-4.2.9-windows-x64\blender.exe' -b -t 6 -P remaster/source/build_assets.py
& 'D:\Blender\blender-4.2.9-windows-x64\blender.exe' -b -t 6 -P remaster/source/build_cast.py
& 'D:\Blender\blender-4.2.9-windows-x64\blender.exe' -b -t 6 -P remaster/source/build_architecture.py
& 'D:\Blender\blender-4.2.9-windows-x64\blender.exe' -b -t 6 -P remaster/source/build_experience_assets.py
python remaster/source/build_audio.py
python remaster/source/build_score.py
```

验证命令：

```powershell
$env:APPDATA = Join-Path $PWD '.godot-user'
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --fixed-fps 60 --script remaster/tests/test_remaster.gd -- --remaster-test
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --fixed-fps 60 --script remaster/tests/test_combat_release.gd -- --remaster-test
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --fixed-fps 60 --script remaster/tests/test_revision.gd -- --remaster-test
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --fixed-fps 60 --script remaster/tests/test_experience.gd -- --remaster-test
```

0.5.2 游戏检查共 **752 项通过**（287 项世界/系统 + 18 项实际战斗 + 88 项动作/关卡 + 155 项体验 + 38 项存档/伤害 + 77 项新武器/伙伴 + 59 项手柄 + 30 项设备切换）。新检查入口为 `tests/test_device_switch.gd`、`tests/test_controller.gd`、`tests/test_preview.gd` 与 `tests/test_arsenal.gd`，沿用上方命令方式。实机截图另行验证；历史发布记录保留在 `qa/`。

导出 `Windows Desktop Remaster` 后，运行 `python remaster/source/package_release.py` 更新启动说明、操作说明、版本说明、SHA-256 清单及版本 ZIP，并逐项校验压缩内容。生成文件留在 `build/`，不加入源码 Git。

## 范围与现状

这是可玩重制开发版，采用原创、风格化机械造型；模型精度、布景密度和动作细腻程度仍需精修。0.5.0 已迁入双刀/长枪/弓弩三家族与四种伙伴的战斗闭环，原版更多武器变体、组合主动技能、NPC/任务、能力门控与收藏仍未迁全。本版声音和配乐为原创程序合成，后续仍需听音混音与拟音精修。

自动化检查覆盖存档恢复、交易与委托奖励不可复制、技能前置与实际运动、40 个场景、新区域往返入口、七 Boss、弹药、死亡和菜单，以及新武器与伙伴参与七 Boss 战。画面另经 GPU 运行截图检查；这不等同于整轮人工通关、多硬件或长时间性能测试。量子升级完整流程、黑客入侵、虚拟空间和正式版发布验收仍待开发。

查看了用户提供的 [开源游戏目录](https://github.com/bobeff/open-source-games)；此实现没有复制其中游戏的代码或素材。新增模型、图标、音效均由本工程脚本生成。
