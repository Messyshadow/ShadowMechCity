# Stage 13B Weapon Families Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将双刀、长枪、弓弩交付为能获取、保存、装备、切换、造成伤害并拥有专属组合节点的真实武器家族。

**Architecture:** 沿用 `Weapons.LIST → Game.unlocked_weapons → Player` 的数据链，不另建平行装备系统。公共输入仍是 J、K、方向+K、V；`player.gd` 仅在武器身份确有差异的位置分派到聚焦的小函数，技能树直接描述这些实际招式。获取点复用可回访的七区域秘室，一次性奖励继续由现有房间武器掉落协议负责。

**Tech Stack:** Godot 4.7 custom source build、GDScript、程序化/原创 SVG、SceneTree 契约测试、godot-capture PNG QA。

---

### Task 1: 13B 武器契约

**Files:**
- Create: `tests/test_stage_13_b.gd`

- [ ] **Step 1: Write the failing contract test**

测试必须断言 `Weapons.LIST` 包含 `dual_blades/spear/crossbow`，三者含 `family/acquisition/combo` 元数据，原创 SVG 存在，三个秘室各有一次性奖励，玩家源码含三类普攻/重击/主动技能分派，技能树每个家族至少有根、两个基础节点和一个组合节点。

- [ ] **Step 2: Run test to verify RED**

Run:
`godot.windows.editor.x86_64.console.exe --headless --path . -s res://tests/test_stage_13_b.gd`

Expected: exit 1，明确报告缺少三种 13B 武器。

- [ ] **Step 3: Commit the red contract**

`git add tests/test_stage_13_b.gd tests/test_stage_13_b.gd.uid && git commit -m "test(13b): define weapon family contracts"`

### Task 2: 武器数据与原创外观

**Files:**
- Modify: `scripts/weapons.gd`
- Create: `assets/weapons/dual_blades.svg`
- Create: `assets/weapons/spear.svg`
- Create: `assets/weapons/crossbow.svg`
- Create: `docs/assets/13B-original-assets.md`

- [ ] **Step 1: Add minimal data for the three weapon identities**

双刀使用近战四连、短攻击时长与双段语义；长枪使用近战三连、最长直线判定与控距；弓弩使用远程两连、较慢射速与高穿透。每项包含实际获取文案、技能家族和组合技 ID。

- [ ] **Step 2: Draw original SVG silhouettes**

使用项目内原创矢量图：青紫双短刃、金青机械长枪、暗红铜机械弩；记录为项目原创、无外部素材依赖。

- [ ] **Step 3: Re-run contract**

Expected: 武器与资源断言通过；获取、战斗、技能树断言仍失败。

- [ ] **Step 4: Commit**

`git add scripts/weapons.gd assets/weapons docs/assets/13B-original-assets.md && git commit -m "feat(13b): add three original weapon families"`

### Task 3: 一次性获取与存档兼容

**Files:**
- Modify: `scripts/rooms.gd`
- Modify: `scripts/items_data.gd`
- Test: `tests/test_stage_13_b.gd`

- [ ] **Step 1: Add rewards to existing reachable secrets**

将双刀放入 `secret_factory_heat`，长枪放入 `secret_temple_orbit`，弓弩放入 `secret_void_observatory`。继续使用 `weapons` 数组和 `Game.unlock_weapon()`，不修改旧存档版本、不自动赠送新武器。

- [ ] **Step 2: Expose unlocked weapons in the inventory category**

把已解锁武器投影为只读唯一物品，显示来源、伤害、家族和组合定位；装备动作更新 `Game.weapon_index`，不可丢弃。

- [ ] **Step 3: Run 13B and migration tests**

Expected: 13B 获取契约、13A 幂等迁移、10.7 旧武器保存均通过。

- [ ] **Step 4: Commit**

`git add scripts/rooms.gd scripts/items_data.gd tests/test_stage_13_b.gd && git commit -m "feat(13b): place persistent weapon rewards"`

### Task 4: 三类普攻和 K 重击

**Files:**
- Modify: `scripts/player.gd`
- Test: `tests/test_stage_13_b.gd`

- [ ] **Step 1: Implement family-specific normal attacks**

双刀以交替刃光和四段终结表达高速连击；长枪用窄长判定、微步推进表达控距；弓弩的普通射击使用更快较小弹矢并提高基础穿透。所有伤害继续读取统一属性快照。

- [ ] **Step 2: Implement family-specific K attacks**

双刀 K 为交叉处决近身双斩，长枪 K 为蓄势贯穿刺，弓弩 K 为爆裂重弩。每招具有不同位移、范围、击退和特效，不复用默认剑气结果。

- [ ] **Step 3: Run 13B and combat regressions**

Expected: 新分派标记通过，阶段 9/10 武器行为契约无回归。

- [ ] **Step 4: Commit**

`git add scripts/player.gd tests/test_stage_13_b.gd && git commit -m "feat(13b): implement distinct weapon attacks"`

### Task 5: 主动技能变体与组合技能树

**Files:**
- Modify: `scripts/player.gd`
- Modify: `scripts/skills_data.gd`
- Modify: `scripts/skill_preview.gd`
- Modify: `scripts/inventory_panel.gd`
- Test: `tests/test_stage_13_b.gd`

- [ ] **Step 1: Add active variants**

双刀：上挑轮舞、影步追击、刃环；长枪：升龙挑、冲锋贯穿、回马环扫；弓弩：防空弩、后跃三连、环射钉阵，并提供各自终结技。共用 MP/怒气/冷却协议。

- [ ] **Step 2: Add real spatial skill nodes**

每个家族加入基础被动、重击强化和一项组合节点；组合详情明确输入、前置、触发、用途及实际技能名。武器未获取时整支仍锁定，获取后可正常加点。

- [ ] **Step 3: Make preview and inventory consume real weapon data**

技能预览读取家族实际武器，背包武器分类不再显示“13B 后续加入”占位文案。

- [ ] **Step 4: Run 13A + 13B tests**

Expected: 图结构无重复/缺失/循环，四向导航和详情协议保持通过。

- [ ] **Step 5: Commit**

`git add scripts/player.gd scripts/skills_data.gd scripts/skill_preview.gd scripts/inventory_panel.gd tests/test_stage_13_b.gd && git commit -m "feat(13b): connect combos to the spatial skill tree"`

### Task 6: 自动截图、全回归和视觉修复

**Files:**
- Modify: `scripts/main.gd`
- Modify as required by observed defects: `scripts/player.gd`, `scripts/skill_panel.gd`, `scripts/skill_preview.gd`, `scripts/inventory_panel.gd`

- [ ] **Step 1: Extend deterministic capture hooks**

`SHOT_WEAPON` 接受三种新 ID；动作连拍覆盖普通攻击、ground、upper、dash、burst、ult；技能树与背包钩子可直接打开三个新家族/武器条目。

- [ ] **Step 2: Run all 15 SceneTree tests and editor parse**

Expected: 15/15，非退出噪声的 `ERROR:` / `SCRIPT ERROR:` 为 0。

- [ ] **Step 3: Capture and inspect real PNGs**

至少保存三套普通/重击或主动技能动作连拍、三张技能树、三张背包/获取画面。逐张检查武器挂点、尺寸、判定方向、弹道、刀光遮挡、文本溢出、圆形节点和平台可达性；发现问题先写回归断言再修复并重拍。

- [ ] **Step 4: Commit QA hooks and observed fixes**

`git add scripts tests && git commit -m "test(13b): add weapon capture coverage"`

### Task 7: QA、计划、发布和 Git 收尾

**Files:**
- Create: `docs/qa/13B-review.md`
- Modify: `docs/DEV_PLAN.md`

- [ ] **Step 1: Record evidence**

报告列出功能矩阵、测试命令、全部错误扫描、截图路径与目视结论、素材许可证、旧存档兼容、已知的人工平衡项。

- [ ] **Step 2: Mark 13B complete only after evidence passes**

更新 `DEV_PLAN.md`，保持 13C、13D 和阶段 11 未完成。

- [ ] **Step 3: Export with the source-built Godot**

使用 `E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe` 导出到 `E:\Godot\release\暗影机械城`，记录 EXE/PCK 时间、大小和 SHA-256；直接启动发布 EXE 抓取证明 PNG 并扫描错误。

- [ ] **Step 4: Verify protected files and final status**

确认 `assets/decor/mine/`、`docs/godot.code-workspace`、`策划的提议.docx` 仍存在且未加入提交；只提交 13B 相关文件。

- [ ] **Step 5: Final commit**

`git add docs/DEV_PLAN.md docs/qa/13B-review.md docs/superpowers/plans/2026-07-20-stage-13b-weapon-families.md && git commit -m "docs(qa): record stage 13B release verification"`
