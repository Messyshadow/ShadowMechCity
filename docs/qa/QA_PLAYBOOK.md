# QA 工作守则 — 单线程「开发 + 自我QA」闭环

> 适用：开发线程单线程包揽 开发 + 自我验收（"QA厕所"）时的每阶段操作守则。
> 工具：`.claude/skills/godot-capture/`（godot-capture 画面验证）。
> 由来：原为开发/QA 双线程，现合并为单线程；本守则把当时的验收纪律固化下来。

## 核心风险（先读）

**自己测自己 = 容易"自我确认"**：作者倾向证明自己对，而非找自己的错。双线程的价值就是"换一双眼睛挑刺"，单线程丢了这个，必须靠**客观证据**补回来——
- **实拍帧**（godot-capture 截图）和**全错误扫描**是不依赖"自我感觉"的硬证据。
- 第 3、4 步必须**真跑、真看、真扫**，不能"我觉得没问题"。

## 每阶段闭环（别跳步）

1. **开发**：按 `docs/DEV_PLAN.md` + 相关设计稿（如 `docs/design/技能系统_v2_设计定稿.md`）实现。
2. **代码自查**：审自己改的逻辑。**铁律**：任何在碰撞/信号回调或物理 flush 期改物理状态（`monitoring` / `collision_layer` / `disabled` / `add_child` 带碰撞体的节点）一律用 `set_deferred(...)` / `call_deferred(...)`。
3. **画面验证**（关键，别只信代码）——用 godot-capture（命令见 `.claude/skills/godot-capture/SKILL.md`）：
   - 战斗/技能/特效 → `SHOT_MOTION=1 SHOT_WEAPON=<sword/hammer/cannon> SHOT_SKILL=<ground/upper/dash/burst/ult>` 拍技能帧。
   - 房间/摆放/UI → `SHOT_ROOM=<id> SHOT_AT=x,y [SHOT_ZOOM=]` 取景拍。
   - **真的 Read 那些 PNG 去看**，明确指出：穿模 / 错位 / 缩放错 / 摆放或拾取不可达 / 形态无差异 / 打击感弱 / 缺资源。不可达、形态没差异、画面没动 = 没过。
4. **全错误扫描**（血的教训，别搜窄）：
   ```bash
   <跑游戏命令> 2>&1 | grep -iE "ERROR" | grep -v "resources still in use\|ObjectDB"
   ```
   **扫所有 ERROR 行**，不要只 grep 某一句。Godot 物理报错至少两种措辞，漏一句就漏 bug：
   - `Function blocked during in/out signal`（信号回调里改 monitoring）
   - `Can't change this state while flushing queries`（flush 期加/配碰撞 shape）
   两者都用 `set_deferred`/`call_deferred` 修。应归零。
5. **写验收报告** `docs/qa/<阶段>-review.md`：✅通过项 + ⚠️发现项(带修法+证据截图名) + 诚实边界。
6. **commit + push**。

## 心态硬要求

- 第 3、4 步切换成**挑刺视角**：目标是"找出还坏在哪"，不是"证明它对"。
- 以实拍帧 + 错误日志为准，不以自我感觉为准。
- 手感 / 数值平衡这类静态测不出的，老实标 **"待人工试玩"**，别假装验过。

## 工具能力与边界

- godot-capture 能验：技能特效、命中、HUD、摆放、缩放、穿模、是否报错。
- **测不出**：移动/攀爬/打击的**手感节奏**、键盘搓招真实容错率、数值平衡 → 这些靠人工试玩。
- 详见 [godot-capture SKILL.md](../../.claude/skills/godot-capture/SKILL.md)。

## 历史 QA 报告

`docs/qa/8.3-review.md` … `9.3-review.md`：含各阶段发现项与复验结论，可作"同类坑"参照（尤其 9.2/9.3 的 `set_deferred`/`call_deferred` 系列物理坑）。
