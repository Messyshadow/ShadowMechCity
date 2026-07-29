# Stage 13.3.1 Bidirectional Shafts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把上下行入口统一为可操作机械竖井，下行可控降落，上行可通过基础墙跳或攀墙能力完成。

**Architecture:** 复用 `shaft_transition.gd` 的真实 Player 物理，以 `direction` 参数构建下行 620px 或上行 480px 井道；`main.gd` 只负责入口路由、镜头模式和房间切换。碰撞与美术由竖井组件封装。

**Tech Stack:** Godot 4.7 CharacterBody2D、StaticBody2D、单向 CollisionShape2D、Area2D 终点触发、FollowCamera、godot-capture。

---

### Task 1: 双向竖井合同

**Files:**
- Create: `tests/test_stage_13_3_1.gd`
- Read: `scripts/shaft_transition.gd`
- Read: `scripts/main.gd`

- [ ] **Step 1: 写失败测试**

测试要求：

```text
shaft_transition.gd:
  const DOWN_DEPTH := 620.0
  const UP_DEPTH := 480.0
  func setup(p_theme, p_player, p_direction)
  direction == "up"
  _make_finish_trigger
  三处 _make_ledge
  两侧 _make_wall

main.gd:
  _play_shaft_transition(to_room, direction)
  down -> "down"
  up -> "up"
  SHOT_SHAFT_DIRECTION
```

同时保留旧测试所需的 `SHAFT_DEPTH` 兼容常量、`call_deferred("_emit_finished")` 与中央落线。

- [ ] **Step 2: 运行并确认 RED**

预期退出码 1，缺少上行方向和抓图入口。

- [ ] **Step 3: 提交测试**

```powershell
git add tests/test_stage_13_3_1.gd
git commit -m "test(13.3.1): define bidirectional shaft contracts"
```

### Task 2: 方向化竖井组件

**Files:**
- Modify: `scripts/shaft_transition.gd`
- Test: `tests/test_stage_13_3_1.gd`

- [ ] **Step 1: 增加方向状态**

```gdscript
const DOWN_DEPTH := 620.0
const UP_DEPTH := 480.0
const SHAFT_DEPTH := DOWN_DEPTH
var direction := "down"
var depth := DOWN_DEPTH

func setup(p_theme: String, p_player: CharacterBody2D, p_direction: String = "down") -> void:
	direction = "up" if p_direction == "up" else "down"
	depth = UP_DEPTH if direction == "up" else DOWN_DEPTH
```

- [ ] **Step 2: 生成可墙跳几何**

两侧墙的碰撞高度使用 `depth + 120`；踏板：

```gdscript
var ledges := [
	Vector2(-52, depth * 0.28),
	Vector2(52, depth * 0.54),
	Vector2(-52, depth * 0.79),
]
```

平台宽 50px、中央保持至少 54px 通线。上行出生在 `depth - 54`，终点触发在 `y=24`；下行出生在 `y=52`，终点触发在 `depth - 24`。

- [ ] **Step 3: 调整完成条件**

下行检测玩家到达井底；上行检测玩家到达井顶。超时只作为测试/卡死保险，上行超时不得把玩家判定为成功，应调用 `cancelled` 或由主场景恢复入口。

- [ ] **Step 4: 方向化绘制**

墙板、灯、悬链与雾覆盖 `depth`；上行顶部增加亮边出口，下行底部保持深色收束。

- [ ] **Step 5: 运行组件合同**

预期只剩主场景路由和抓图入口失败。

### Task 3: 主场景路由与镜头

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/follow_camera.gd`
- Test: `tests/test_stage_13_3_1.gd`

- [ ] **Step 1: 统一入口**

将入口分支改为：

```gdscript
if d["side"] in ["down", "up"]:
	_play_shaft_transition.call_deferred(d["to"], d["side"])
else:
	_enter_room.call_deferred(d["to"], room_id)
```

隐藏 `up` 门继续走原隐藏入口逻辑，不强制进入竖井。

- [ ] **Step 2: 配置玩家出生和速度**

```gdscript
shaft.setup(room.get("theme", "city"), player, direction)
if direction == "up":
	player.global_position = shaft.global_position + Vector2(0, shaft.depth - 54)
	player.velocity = Vector2.ZERO
else:
	player.global_position = shaft.global_position + Vector2(0, 52)
	player.velocity = Vector2(0, 90)
```

全过程保持 `player.shaft_mode = true`，因此战斗关闭但左右移动、跳跃、墙滑和墙跳可用。

- [ ] **Step 3: 扩展相机**

`begin_shaft(target_y, direction)` 接收方向；向上时相机目标从井底缓动到井顶，结束后 `end_shaft()` 恢复普通跟随和限制。

- [ ] **Step 4: 运行测试并确认 GREEN**

新旧竖井测试均通过。

- [ ] **Step 5: 提交**

```powershell
git add scripts/shaft_transition.gd scripts/main.gd scripts/follow_camera.gd tests/test_stage_13_3_1.gd
git commit -m "feat(13.3.1): add playable bidirectional shafts"
```

### Task 4: 上下行连续截图

**Files:**
- Modify: `scripts/main.gd`
- Create: `docs/qa/13.3.1-review.md`
- Modify: `docs/DEV_PLAN.md`

- [ ] **Step 1: 扩展抓图**

`SHOT_SHAFT_DIRECTION=down|up` 选择方向；每 0.32–0.38 秒保存至少 8 帧。上行抓图脚本周期性按住朝向墙面的方向键并触发跳跃，确保帧中能看到墙滑/墙跳位移。

- [ ] **Step 2: 实拍**

矿坑→地下水道下行、水道→矿坑上行各拍至少 8 帧。

- [ ] **Step 3: 逐张目视**

确认墙面连续、踏板可达、中央下落线没有封死、玩家不穿墙、镜头连续且顶部/底部出口可读。

- [ ] **Step 4: 全回归**

运行全部测试、编辑器解析、主场景与发布版 240 帧；扫描全部 `ERROR` / `SCRIPT ERROR`。

- [ ] **Step 5: QA、发布与最终提交**

更新 DEV_PLAN，导出到 `E:\Godot\release\暗影机械城`，记录 EXE/PCK 时间、尺寸与 SHA-256，然后提交本批次 QA/计划状态。
