# Stage 13.4.1 Skill Showcase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 补齐六武器战斗技能节点，并让技能树右侧预览清楚展示起手、技能主体、命中、残留和收招。

**Architecture:** `skills_data.gd` 继续作为技能教学数据源；新增无伤害的 `SkillPreviewEffect` 只负责程序化绘制，`SkillPreview` 负责时序与角色/假人动作。真实战斗继续复用 `player.gd` 和 `SkillFxProfile`，预览不得生成碰撞或修改 Game。

**Tech Stack:** Godot 4.7 GDScript、SubViewport、Node2D `_draw()`、Tween、现有 SkillFxProfile、源码 Godot 测试与 godot-capture。

---

### Task 1: 新技能与预览合同

**Files:**
- Create: `tests/test_stage_13_4_1.gd`
- Read: `scripts/skills_data.gd`
- Read: `scripts/skill_preview.gd`

- [ ] **Step 1: 写失败测试**

测试必须加载 `SkillsData.TREE`，要求以下 ID 存在：

```gdscript
const EXPECTED := [
	"sword_thunder_spin", "sword_shadow_dragon",
	"hammer_core_burst", "hammer_rail_drive",
	"cannon_overpressure_rise", "cannon_star_pressure",
	"dual_mirror_storm", "dual_rift_prison",
	"spear_skywheel_rise", "spear_dragon_drill",
	"crossbow_rift_rain", "crossbow_hunter_terminal",
]
```

每个节点必须拥有 `input / usage / preview_pattern / preview_intensity / weapon_required`，并检查预览源码包含 `SkillPreviewEffect`、五阶段标题、`PREVIEW_SIZE := Vector2i(410, 190)`，同时不得包含 `Area2D.new()`、`Game.spend` 或 `save_game`。

- [ ] **Step 2: 运行并确认 RED**

```powershell
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --script res://tests/test_stage_13_4_1.gd
```

预期：退出码 1，报告缺少 12 个技能和预览效果类。

- [ ] **Step 3: 提交测试**

```powershell
git add tests/test_stage_13_4_1.gd
git commit -m "test(13.4.1): define skill showcase contracts"
```

### Task 2: 技能数据补齐

**Files:**
- Modify: `scripts/skills_data.gd`
- Test: `tests/test_stage_13_4_1.gd`

- [ ] **Step 1: 为六家族加入十二个节点**

每个节点使用以下完整结构，位置保持在技能画布 `x=100..660 / y=60..380`：

```gdscript
{"id":"hammer_core_burst", "name":"熔核震爆", "page":"战斗", "family":"铁锤",
 "pos":Vector2(340,330), "type":"主动", "max":3, "cost":1,
 "req":["hammer_demolition"], "weapon_required":"hammer",
 "desc":"下砸伤害与地裂范围随等级提升",
 "usage":"装备铁锤后按 ↓ + K；适合破甲和近身清场。",
 "input":"↓ + K", "preview":"hammer_core_burst",
 "preview_pattern":"ground_smash", "preview_intensity":"signature"}
```

十二个节点的固定数据如下；`desc` 描述成长，`usage` 直接采用对应输入和表中用途，不留空字符串：

| ID | 名称/家族 | 位置 | 输入 | 前置 | pattern/intensity |
| --- | --- | --- | --- | --- | --- |
| `sword_thunder_spin` | 雷霆旋风斩/刀剑 | `(460,80)` | `J → J → J` | `atk` | `slash_spin/signature` |
| `sword_shadow_dragon` | 无影狂龙斩/刀剑 | `(600,340)` | `→ → + K，随后 V` | `spin,ultimate` | `shadow_dash/ultimate` |
| `hammer_core_burst` | 熔核震爆/铁锤 | `(340,330)` | `↓ + K` | `hammer_demolition` | `ground_smash/signature` |
| `hammer_rail_drive` | 磁轨飞锤/铁锤 | `(560,120)` | `→ → + K` | `hammer_core_burst` | `shadow_dash/signature` |
| `cannon_overpressure_rise` | 过压升焰/蒸汽枪炮 | `(340,80)` | `↑ + K` | `cannon_steam_jet` | `pressure_jet/signature` |
| `cannon_star_pressure` | 贯星压力炮/蒸汽枪炮 | `(560,340)` | `↓ + K` | `cannon_overpressure_rise` | `pressure_beam/signature` |
| `dual_mirror_storm` | 镜影风暴/双刀 | `(520,80)` | `↓ ↓ + K` | `dual_cross` | `cross_slash/signature` |
| `dual_rift_prison` | 裂空瞬狱/双刀 | `(600,220)` | `怒气满 → V` | `dual_execution` | `cross_slash/ultimate` |
| `spear_skywheel_rise` | 天轮升龙/长枪 | `(500,80)` | `↑ + K` | `spear_mastery` | `spear_rise/signature` |
| `spear_dragon_drill` | 龙脊钻星/长枪 | `(600,300)` | `→ → + K` | `spear_dragon` | `spear_drill/signature` |
| `crossbow_rift_rain` | 裂隙箭雨/弓弩 | `(500,80)` | `↓ ↓ + K` | `crossbow_burst` | `arrow_rain/signature` |
| `crossbow_hunter_terminal` | 猎杀终端/弓弩 | `(600,220)` | `怒气满 → V` | `crossbow_barrage` | `reticle_burst/ultimate` |

- [ ] **Step 2: 验证技能图**

在测试中调用 `SkillGraph.validate(SkillsData.TREE)`，预期 `errors` 为空；每个家族至少 6 个节点且空间位置没有完全重叠。

- [ ] **Step 3: 运行测试**

预期仍失败，但只剩预览类和五阶段渲染合同。

### Task 3: 独立程序化预览特效

**Files:**
- Create: `scripts/skill_preview_effect.gd`
- Modify: `scripts/skill_fx_profile.gd`
- Test: `tests/test_stage_13_4_1.gd`

- [ ] **Step 1: 创建纯视觉节点**

接口固定为：

```gdscript
class_name SkillPreviewEffect
extends Node2D

var pattern := "passive"
var primary := Color.CYAN
var secondary := Color.WHITE
var intensity := "basic"
var phase := 0
var progress := 0.0

func configure(data: Dictionary) -> void:
	pattern = str(data.get("pattern", "passive"))
	primary = data.get("primary", Color.CYAN)
	secondary = data.get("secondary", Color.WHITE)
	intensity = str(data.get("intensity", "basic"))
	queue_redraw()

func set_phase(value: int, value_progress: float = 0.0) -> void:
	phase = clampi(value, 0, 4)
	progress = clampf(value_progress, 0.0, 1.0)
	queue_redraw()
```

`_draw()` 对八类图形分别绘制弧线、地裂多边形、蒸汽锥/束、交叉刀线、枪轴/螺旋、扇形箭线和准星；`ultimate` 的尺寸系数不超过 `1.55`，透明度不超过 `0.92`。

- [ ] **Step 2: 扩展共享配置查询**

在 `SkillFxProfile` 增加：

```gdscript
static func preview_profile(weapon_id: String, pattern: String, intensity: String) -> Dictionary:
	var base := profile(weapon_id, "ultimate" if intensity == "ultimate" else "burst")
	base["pattern"] = pattern
	base["intensity"] = intensity
	return base
```

- [ ] **Step 3: 运行测试**

预期：特效配置合同通过，仍缺 `SkillPreview` 接入。

### Task 4: 五阶段 SkillPreview

**Files:**
- Modify: `scripts/skill_preview.gd`
- Modify: `scripts/skill_panel.gd`
- Test: `tests/test_stage_13_4_1.gd`

- [ ] **Step 1: 放大预览**

将预览设为 `Vector2i(410, 190)`；角色缩放到约 `1.55`，假人放到 `x≈275`，为弹道保留 `x=125..330` 空间。技能详情最小高度同步压缩，确保升级按钮仍可见。

- [ ] **Step 2: 接入效果节点**

预览持有：

```gdscript
var effect: SkillPreviewEffect
var flash_overlay: ColorRect
var input_caption: Label
```

`play_node()` 先复位角色、假人、武器和效果，再通过 `SkillFxProfile.preview_profile()` 配置颜色/图形。

- [ ] **Step 3: 实现五阶段循环**

循环标题固定为：

```text
① 起手预警
② 技能释放
③ 命中反馈
④ 残留效果
⑤ 收招复位
```

每阶段调用 `effect.set_phase(0..4)`；命中阶段假人偏移 8–14px 并闪白，预览闪屏 alpha 上限 `0.16`。被动节点使用“触发条件 / 生效反馈 / 数值成长”，不播放假人受击。

- [ ] **Step 4: 运行测试并确认 GREEN**

预期：`PASS stage 13.4.1 skill showcase contracts`。

- [ ] **Step 5: 提交**

```powershell
git add scripts/skills_data.gd scripts/skill_fx_profile.gd scripts/skill_preview_effect.gd scripts/skill_preview.gd scripts/skill_panel.gd tests/test_stage_13_4_1.gd
git commit -m "feat(13.4.1): expand weapon skills and preview effects"
```

### Task 5: 确定性截图与验收

**Files:**
- Modify: `scripts/main.gd`
- Create: `docs/qa/13.4.1-review.md`
- Modify: `docs/DEV_PLAN.md`

- [ ] **Step 1: 添加抓图入口**

新增 `SHOT_SKILL_SHOWCASE=<node_id>`，打开对应页/家族后以 0.22 秒间隔保存 8 帧至 `screenshots/13_4_1/<node_id>/frame_0..7.png`。

- [ ] **Step 2: 抓取代表节点**

至少抓取：

```text
sword_shadow_dragon
hammer_core_burst
cannon_star_pressure
dual_rift_prison
spear_dragon_drill
crossbow_rift_rain
atk（被动）
```

- [ ] **Step 3: 逐张查看并修复**

检查角色/假人比例、技能主体是否明显、命中帧是否变化、文字裁切和闪光遮挡；相同帧视为失败。

- [ ] **Step 4: 全测试与错误扫描**

运行全部 `tests/test_*.gd`、源码编辑器解析、主场景 240 帧，扫描所有 `ERROR` / `SCRIPT ERROR`。

- [ ] **Step 5: 写 QA 与 DEV_PLAN**

记录 PNG 数量、目视问题闭环、测试数和素材来源（程序化效果，无新增外部素材）。
