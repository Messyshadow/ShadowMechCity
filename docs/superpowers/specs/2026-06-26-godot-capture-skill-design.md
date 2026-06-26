# godot-capture 画面验证技能 — 设计方案

> 日期：2026-06-26
> 项目：暗影机械城（GDScript / Windows / Godot 4.7）
> 来源灵感：godogen 的「不信代码只信画面」逐帧自检思想，移植为 GDScript + Windows 可用的项目内技能。

## 目标

给本项目（用 Claude Code 开发）增加一个**画面/效果验证**能力：改完代码后，能自动跑游戏、以确定性脚本驱动一段操作、抖出 PNG 帧序列并编码成视频，让 Claude **直接看帧找毛病**（穿模 / 错位 / 缩放错误 / 动作卡顿 / 缺资源 / 打击感不对），而不是只凭"代码看起来对"。

**野心档位：抖帧 + 看图（起步）。** 技能只负责"把画面抖出来"，判断与修复由 Claude 在主流程里完成；不内置自动改→再抖的闭环。

## 非目标（YAGNI）

- 不做自动自修复闭环（看完帧后自动改代码再重抖）。
- 不接任何付费 AI 素材生成 API（Gemini/Grok/Tripo3D）。
- 不引入 C#/.NET。
- 不做 Linux/xvfb 兼容（本机 Windows + 硬件 GPU，直接 `--write-movie` 即可）。
- 不做全局技能；技能与录制驱动均为本项目专属。

## 环境前提（已确认）

- Godot 可执行：`E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.exe`
- ffmpeg：`D:\ffmpeg\ffmpeg-N-122528-gdd2976b9e1-win64-lgpl\bin\ffmpeg.exe`（不在 PATH，脚本内写绝对路径）
- 输入系统使用 `Input.is_action_*`，因此可用 `Input.action_press/release(...)` 在录制脚本里确定性地模拟按键。
- 已有 `--shot` 单张截图模式（main.gd / title_menu.gd）作为参考。
- 主场景为 `res://title.tscn`；游玩主场景为 `res://main.tscn`，autoload 单例 `Game`。

## 架构总览

三个部件：

```
run_capture.ps1  ──►  godot --capture <剧本>  ──►  PNG 帧序列  ──►  ffmpeg  ──►  video.mp4
(技能封装脚本)        (游戏内录制模式)            screenshots/<剧本>/        screenshots/<剧本>/
```

### 部件 1 · 游戏内录制模式（GDScript，新增）

确定性、只在命令行触发、不污染正常游玩。

- **触发参数**：`--capture <剧本名>`（如 `--capture combat`）。在 main.gd 早期检测 `OS.get_cmdline_user_args()`，若存在则进入录制模式：跳过标题流程，直接构建对应剧本的场景。
- **新文件 `scripts/capture_driver.gd`**：仅在录制模式下挂载的节点，职责：
  1. `seed(<固定值>)` 固定随机种子，保证每次抖帧一致。
  2. 按「帧号 → 动作」脚本表，用 `Input.action_press/release("attack"/"move_right"/"dash"/...)` 模拟玩家输入。
  3. 必要时锁定/平移相机。
  4. 剧本以字典数据驱动，新增剧本只填数据，不改流程代码。
- **专用靶场**：`combat` 剧本不在现有房间里录，而是由 capture_driver 现场搭一个干净场景——一块平台 + 一个可控的假人敌人（受控站桩或简单挪动），画面干净、最确定性，专看攻击动作与打击感。
- **起步内置 2 个剧本**：
  - `combat`：专用靶场内，走到假人旁 → J 连击 → K 重击 → 冲刺。看攻击动画/刀光判定/打击反馈。
  - `room`：在当前房间内平移相机扫一遍。看布局/缩放/美术/视差。
- **录制机制**：交给 Godot 自带 `--write-movie frame.png --fixed-fps 30 --quit-after <N>`，引擎按固定时间步逐帧写 PNG（无需每帧手动 `save_png`）。`--fixed-fps 30` 保证物理与动作确定性。

### 部件 2 · 技能本体 `.claude/skills/godot-capture/`

- **`SKILL.md`**：何时用（改了战斗/动画/场景/UI/资源后做视觉验证时）、怎么用（调封装脚本）、产物在哪、如何看帧并报告缺陷。强调"代码与画面不一致时以画面为准；任务是找还坏在哪，不是论证它大概没问题"。
- **`run_capture.ps1`**：Windows 封装脚本，一条命令完成：
  1. 调 Godot 以 `--path . res://main.tscn --capture <剧本> --write-movie screenshots/<剧本>/frame.png --fixed-fps 30 --quit-after <N>` 抖帧。
  2. 调 ffmpeg 把 `frame*.png` 编码成 `screenshots/<剧本>/video.mp4`。
  3. 打印产物路径。
  - 入参：剧本名、可选帧数（默认按剧本预设，例如 combat≈150 帧/5 秒，room≈80 帧）。
  - Godot 与 ffmpeg 路径写绝对路径常量。
- **产物**：`screenshots/<剧本>/frame0001.png …` + `video.mp4`。Claude 直接 Read 这些 PNG 看画面。

### 部件 3 · 工程卫生

- `screenshots/.gdignore`：让 Godot 不去 import 抖出的帧。
- `.gitignore` 追加 `screenshots/`：帧与视频不进 git。

## 数据流与确定性

1. 封装脚本启动 Godot 录制模式。
2. capture_driver 固定种子 + 按帧脚本注入输入，`--fixed-fps 30` 固定时间步 → 每次帧序列一致。
3. Godot 逐帧写 `frameXXXX.png`（+ 一个忽略的 `frame.wav`）。
4. ffmpeg 编码为 mp4。
5. Claude Read PNG 帧 → 判断 → 必要时改代码 → 重跑。

## 失败/边界处理

- 若帧序列每帧 hash 相同（画面没动）→ 说明输入注入或时间步接错了，不能当成"通过"。
- 若 `--capture` 参数缺剧本名 → 报错并列出可用剧本。
- 录制模式只读最小状态，不依赖存档，避免存档污染影响确定性。
- `--quit-after` 负责正常退出；封装脚本仍设一个超时上限兜底，防止卡死。

## 验收标准

- `--capture combat` 能在专用靶场抖出一段非静止的 PNG 序列（帧间有差异），并编码出可播放的 `video.mp4`。
- `--capture room` 能抖出当前房间的平移序列。
- 正常双击 `play_game.bat` 启动不受任何影响（录制代码只在 `--capture` 下生效）。
- 技能 SKILL.md 能让 Claude 在"改完视觉相关代码后"正确触发并看帧。

## 后续可扩展（不在本次范围）

- 更多剧本（特定 Boss 战、技能特效、某区域视差）。
- 升级到"自修复闭环"档（看帧 → 自动改 → 重抖）。
- 把技能泛化成可复用于其它 Godot 项目的全局技能。
