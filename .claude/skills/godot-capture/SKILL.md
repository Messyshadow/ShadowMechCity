---
name: godot-capture
description: 跑「暗影机械城」并抓截图做画面/动作视觉验收。改完战斗/动画/场景/UI/能力/资源相关代码后，用它把实际画面拍出来逐张看，找代码看不出的画面毛病（穿模/错位/缩放/打击感/动画卡顿/摆放/缺资源），而不是只凭代码判断。也用于按 DEV_PLAN 每阶段交付时的"截图验证"。
---

# Godot 画面验证（暗影机械城）

**定位**：这是"相机+人看"——工具只负责把游戏副本跑起来、自动产出 PNG；**判断由你（Claude）看图完成**。不自动改代码（自修复闭环是后续升级）。

- 工作目录：游戏项目根（本仓库）。
- Godot 可执行：`E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.exe`
- 触发逻辑写在 `scripts/main.gd` 的 `_auto_screenshot()` / `_motion_burst()`，只在命令行带 `--shot` 时生效，正常游玩不受影响。

## 何时用

改了战斗手感、动画、特效、能力（如 8.3 攀墙/滑翔）、角色/敌人外观、房间布局、UI、美术资源之后，要确认"画面上真的对"时。

## 命令（Bash；env 变量驱动）

设 `GODOT="/e/SourceCode/Games/engine/big_engine/godot/bin/godot.windows.editor.x86_64.exe"`，都在项目根运行。

### 1) 房间取景单张截图（看布局/摆放/美术）

```bash
SHOT_ROOM=cavern SHOT_AT=110,150 SHOT_ZOOM=0.7 timeout 60 "$GODOT" --path . res://main.tscn --shot
```

- `SHOT_ROOM=<id>`：进哪个房间（id 见 `scripts/rooms.gd` 的 `ROOMS`，如 hub/temple/mine/depths/tunnel/cavern/mine_boss）。
- `SHOT_AT="x,y"`：把镜头钉在房间坐标 (x,y)，脱离玩家跟随——**用它对准新内容**（如奖励高台、拾取物），解决"镜头锁在出生点看不全"。
- `SHOT_ZOOM=0.7`：<1 看更广，>1 拉近，默认 1。
- 产物：项目根 `_shot.png`（每次覆盖；要保留多张就 `cp _shot.png screenshots/xxx.png`）。

### 2) 动作连拍（看打击感/攻击动画）

```bash
SHOT_ROOM=cavern SHOT_MOTION=1 timeout 60 "$GODOT" --path . res://main.tscn --shot
```

- 在角色前方放一排假人(3个)，自动触发并连拍，覆盖整段动作。
- 可选 `SHOT_ENEMY=<type>` 指定假人（默认 slime，type 见 main.gd `ENEMY_DEFS`）。
- 可选 `SHOT_SKILL=<招式>` 触发主动技能(9.2)而非普攻：
  - `ground` ↓K地面波 / `upper` ↑K上挑 / `dash` →→K突进斩 / `ult` V大招(自动给满怒气)
  - 突进/大招为拍效果直接预置状态(arm 搓招窗口/满怒气)，不验输入容错(那靠代码审查+试玩)。
- 产物：`screenshots/motion/frame_0.png` … （普攻5帧/技能7-9帧）。

> 运行时常见 `ERROR: 1 resources still in use at exit` 是 Godot 退出噪音，不影响截图。

## 错误检测（必读·别再漏）

跑连拍/截图时**必须扫描所有 `ERROR:` 行**，不要只 grep 某一句固定错误串。Godot 物理类报错至少有两种不同措辞：
- `Function blocked during in/out signal`（在碰撞信号回调里改 monitoring）
- `Can't change this state while flushing queries`（在物理 flush 期加/配碰撞 shape）

二者都要 `set_deferred`/`call_deferred` 修。**只匹配其中一句会漏报另一句**（9.3 就因此漏过一个 bug）。推荐：`... 2>&1 | grep -iE "ERROR|SCRIPT ERROR" | grep -v "resources still in use\|ObjectDB instances"`（后两句是退出噪音，可忽略）。

## 验收纪律

- **代码与画面不一致时，以画面为准。** 任务是找出还坏在哪，不是论证它大概没问题。
- 逐张 Read 截图，明确指出：穿模 / 错位 / 缩放错 / 摆放不合理 / 拾取物或平台不可达 / 动作卡顿或不连贯 / 刀光没碰到敌人 / 缺资源 / 打击反馈弱。
- 连拍每帧相同 = 没动 = 验证无效，先排查（攻击动作名、角色是否落地、间隔）。
- **移动类机制（攀墙/滑翔/跳跃手感）静态图测不出"手感"**——只能验摆放与几何，手感需手动试玩或后续做移动脚本化连拍。

## 输出去向（双线程协调）

验收结论写进 `docs/qa/<阶段>-review.md`（版本化、可被游戏开发线程 pull 读取），不靠对话复制。开工前 `git pull`、收工后 `git push`。
