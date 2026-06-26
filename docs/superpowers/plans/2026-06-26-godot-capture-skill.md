# godot-capture 画面验证技能 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给暗影机械城增加最小化的「画面/动作」视觉验收能力——复用现有 `--shot`，新增动作连拍分支与一个小技能文档，让 Claude 改完代码后能跑出截图直接看画面找毛病。

**Architecture:** 不引入新类、不搭靶场、不做视频编码。复用 main.gd 现有的 `_auto_screenshot()`（已支持 `SHOT_ROOM` 进房间存单张 `_shot.png`）。仅新增一个 `SHOT_MOTION=1` 分支：在角色面前放一个站桩假人、触发一次攻击、连存若干帧到 `screenshots/motion/`。再加一个 `.claude/skills/godot-capture/SKILL.md` 记录命令与"看图找毛病"纪律。

**Tech Stack:** Godot 4.7 / GDScript / Windows。Godot 可执行：`E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.exe`。

## Global Constraints

- 不改动现有正常游玩流程：所有新逻辑只在命令行带 `--shot` 且环境变量 `SHOT_MOTION=1` 时生效。
- 不新增 .gd 文件、不新增类、不接 ffmpeg/视频、不搭专用靶场（简单优先原则）。
- 输入用 `Input.action_press/action_release`，动作名沿用项目既有 `"attack"`。
- 截图输出目录 `screenshots/` 必须带 `.gdignore`，避免 Godot 把帧当资源导入。
- 攻击动作名、敌人类型 key 必须取自现有定义：攻击动作 `"attack"`（见 [player.gd:312](../../scripts/player.gd#L312)）；敌人类型取自 main.gd 的 `ENEMY_DEFS`（如 `"slime"`）。

---

### Task 1: 工程卫生——screenshots 目录与 .gdignore

**Files:**
- Create: `screenshots/.gdignore`

**Interfaces:**
- Produces: 一个被 Godot 导入系统忽略的 `screenshots/` 目录，供 Task 2 的连拍与现有 `--shot` 共用。

- [ ] **Step 1: 创建忽略标记文件**

创建 `screenshots/.gdignore`，内容为空（文件存在即让 Godot 跳过该目录的资源导入）。

- [ ] **Step 2: 验证目录存在**

Run（项目根目录下，Bash）：`ls -la screenshots/.gdignore`
Expected: 列出该文件，无报错。

- [ ] **Step 3: 提交（若项目已是 git 仓库；否则跳过）**

```bash
git add screenshots/.gdignore 2>/dev/null && git commit -m "chore: 忽略 screenshots 截图目录" || echo "非 git 仓库，跳过提交"
```

---

### Task 2: 在 _auto_screenshot 增加 SHOT_MOTION 动作连拍分支

**Files:**
- Modify: `scripts/main.gd`（在 `_auto_screenshot()` 内插入分支，文件末尾新增 `_motion_burst()`）

**Interfaces:**
- Consumes: 现有 `player`（CharacterBody2D，含 `.position`）、`_spawn_enemy(x: float, y: float, type: String)`、`ENEMY_DEFS`、`_enter_room(id, from)`。
- Produces: 环境变量驱动的连拍：`SHOT_MOTION=1` → 在 `screenshots/motion/frame_0.png` … `frame_4.png` 写出一次攻击的连续帧。

- [ ] **Step 1: 在 `_auto_screenshot()` 顶部 SHOT_ROOM 处理之后插入 MOTION 分支**

把 [main.gd:755-758](../../scripts/main.gd#L755) 现有开头：

```gdscript
func _auto_screenshot() -> void:
	var rid := OS.get_environment("SHOT_ROOM")
	if rid != "" and Rooms.ROOMS.has(rid):
		_enter_room(rid, "")
```

改为（在其后增加 MOTION 分支并提前返回，不影响后续 SHOT_INV/单张逻辑）：

```gdscript
func _auto_screenshot() -> void:
	var rid := OS.get_environment("SHOT_ROOM")
	if rid != "" and Rooms.ROOMS.has(rid):
		_enter_room(rid, "")
	if OS.get_environment("SHOT_MOTION") == "1":
		await _motion_burst()
		return
```

- [ ] **Step 2: 在 main.gd 末尾新增 `_motion_burst()` 函数**

在文件末尾（[main.gd:772](../../scripts/main.gd#L772) 之后）追加：

```gdscript
# 动作连拍: 角色面前放站桩假人, 触发一次攻击, 连存若干帧供视觉验收
func _motion_burst() -> void:
	var dummy_type := OS.get_environment("SHOT_ENEMY")
	if dummy_type == "" or not ENEMY_DEFS.has(dummy_type):
		dummy_type = "slime"
	# 假人放在角色右前方, 让攻击/刀光打在它身上
	_spawn_enemy(player.position.x + 90.0, player.position.y, dummy_type)
	# 等镜头与场景稳定
	await get_tree().create_timer(0.5).timeout
	var out_dir := ProjectSettings.globalize_path("res://screenshots/motion")
	DirAccess.make_dir_recursive_absolute(out_dir)
	# 触发一次攻击输入(按一帧再松开, 让 just_pressed 生效)
	Input.action_press("attack")
	await get_tree().process_frame
	Input.action_release("attack")
	# 连拍 5 帧, 每帧间隔 ~0.12s, 覆盖整段挥砍
	for i in range(5):
		await get_tree().create_timer(0.12).timeout
		await RenderingServer.frame_post_draw
		var p := "%s/frame_%d.png" % [out_dir, i]
		get_viewport().get_texture().get_image().save_png(p)
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
```

- [ ] **Step 3: 运行动作连拍**

Run（项目根目录，Bash）：

```bash
SHOT_MOTION=1 "/e/SourceCode/Games/engine/big_engine/godot/bin/godot.windows.editor.x86_64.exe" \
  --path . res://main.tscn --shot
```

Expected: 进程自行退出（无需手动关窗），无脚本报错。

- [ ] **Step 4: 验证连拍产物存在且画面有变化**

Run：`ls -la screenshots/motion/`
Expected: 出现 `frame_0.png` … `frame_4.png` 共 5 个文件。
然后用 Read 工具逐张看 `frame_0.png`～`frame_4.png`：应能看到角色攻击动作在帧间推进（挥砍/刀光位置变化），而非每帧完全相同。若每帧相同 → 输入注入或时序接错，需排查（参考下方"边界处理"）。

- [ ] **Step 5: 验证不影响正常游玩**

Run：`"/e/SourceCode/Games/engine/big_engine/godot/bin/godot.windows.editor.x86_64.exe" --path . res://title.tscn`（不带任何 SHOT 环境变量）
Expected: 正常进入标题→可游玩，连拍逻辑完全不触发。手动关窗结束。

- [ ] **Step 6: 提交（若 git 仓库；否则跳过）**

```bash
git add scripts/main.gd 2>/dev/null && git commit -m "feat: --shot 增加 SHOT_MOTION 动作连拍, 用于打击感视觉验收" || echo "非 git 仓库，跳过提交"
```

**边界处理（排查参考，不是步骤）：**
- 每帧画面相同：确认 `"attack"` 动作名与 player.gd 一致；确认 player 已落地可攻击；可加大 `await` 间隔或把假人换成会被打中的近距离位置。
- 角色背对假人：把假人改到 `player.position.x - 90.0`，或在连拍前设置角色朝向（视 player.gd 的朝向字段而定）。

---

### Task 3: 新增 godot-capture 技能文档

**Files:**
- Create: `.claude/skills/godot-capture/SKILL.md`

**Interfaces:**
- Consumes: Task 2 的 `SHOT_MOTION` 连拍、现有 `SHOT_ROOM` 单张截图。
- Produces: 一个让 Claude 在"改完视觉相关代码后"能稳定触发截图并按"看图找毛病"纪律验收的技能。

- [ ] **Step 1: 写 SKILL.md**

创建 `.claude/skills/godot-capture/SKILL.md`，内容：

````markdown
---
name: godot-capture
description: 跑暗影机械城并抓截图做画面/动作视觉验收。改完战斗/动画/场景/UI/资源相关代码后，用它看实际画面找毛病，而不是只凭代码判断。
---

# Godot 画面验证（暗影机械城）

工作目录：游戏项目根 `E:\Godot\test-project\我的第一个godot游戏`。
Godot：`E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.exe`

## 何时用

改了战斗手感、动画、特效、角色/敌人外观、房间布局、UI 之后，要确认"画面上真的对"时。

## 两条命令

### 1) 房间/布局/美术 单张截图

```bash
SHOT_ROOM=<房间id> "<godot.exe>" --path . res://main.tscn --shot
```

产物：项目根 `_shot.png`。用于看布局/缩放/穿模/美术/视差。`<房间id>` 取自 Rooms.ROOMS。

### 2) 动作/打击感 连拍

```bash
SHOT_MOTION=1 "<godot.exe>" --path . res://main.tscn --shot
```

可选 `SHOT_ENEMY=<敌人type>` 指定站桩假人（默认 slime，type 取自 main.gd ENEMY_DEFS）。
产物：`screenshots/motion/frame_0.png` … `frame_4.png`，覆盖一次攻击全过程。

## 验收纪律

- **代码与画面不一致时，以画面为准。** 任务是找出还坏在哪，不是论证它大概没问题。
- 逐张 Read 截图，明确指出：穿模 / 错位 / 缩放错 / 动作卡顿或不连贯 / 刀光没碰到敌人 / 缺资源 / 打击反馈弱。
- 连拍每帧相同 = 没动 = 验证无效，先修录制再下结论。
- 看完给出"按严重度排序的问题清单"，再决定改什么。
````

- [ ] **Step 2: 验证技能文件存在**

Run：`ls -la .claude/skills/godot-capture/SKILL.md`
Expected: 列出该文件。

- [ ] **Step 3: 提交（若 git 仓库；否则跳过）**

```bash
git add .claude/skills/godot-capture/SKILL.md 2>/dev/null && git commit -m "feat: 新增 godot-capture 画面验证技能" || echo "非 git 仓库，跳过提交"
```

---

## Self-Review

**Spec coverage：**
- 游戏内录制模式 → Task 2（简化为 SHOT_MOTION 连拍分支，无独立类/靶场，符合"简单优先"再定调）。
- 技能本体 → Task 3。
- 工程卫生（.gdignore）→ Task 1。
- 视频编码 / ffmpeg / 专用靶场 / capture_driver 类：依"简单优先"原则**主动移出范围**，spec 后续可扩展节已列。

**Placeholder scan：** 无 TBD/TODO；每个代码步骤均给出完整可粘贴代码。

**Type consistency：** `_spawn_enemy(x, y, type)`、`player.position`、动作名 `"attack"`、`ENEMY_DEFS` 均与 main.gd / player.gd 现状一致。`SHOT_MOTION` / `SHOT_ROOM` / `SHOT_ENEMY` 环境变量命名前后一致。
