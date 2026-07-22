# Stage 13D.3 Functional Weapon Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为刀剑、铁锤、蒸汽枪炮、双刀、长枪和弓弩各交付一个可解锁、可预览、可在场景中实际触发的功能型技能，同时保持旧炸弹墙和旧存档兼容。

**Architecture:** 新建独立 `SkillInteractable` 场景组件，通过统一 `try_skill_interaction(tag, actor)` 协议响应六类技能标签，房间只声明目标类型与坐标，武器代码不硬编码房间 ID。技能数据补齐环境标签、资源限制和五阶段预览数据；预览器同时绘制角色、假人、环境目标。主场景提供确定性 13D.3 截图入口，以便实际 Godot PNG 验收。

**Tech Stack:** Godot 4 / GDScript、程序化 Node2D/StaticBody2D 场景、现有 `Game` 技能存档、源码编译 Godot、项目 `godot-capture` 工作流。

---

### Task 1: Contract tests

**Files:**
- Create: `tests/test_stage_13_d_3.gd`

- [ ] **Step 1: Write the failing test**

测试必须断言：组件文件存在且公开统一协议；六个技能节点都拥有 `interaction_tags`、`resource_rule`、`preview_stages`、`environment_use`；玩家发出六类标签；房间包含六类可选交互目标；预览包含假人和环境目标；主场景包含 `SHOT_13D3`。

- [ ] **Step 2: Run test to verify it fails**

Run: `godot.windows.editor.x86_64.console.exe --headless --path . -s res://tests/test_stage_13_d_3.gd`

Expected: `STAGE_13_D_3` failure mentioning missing `skill_interactable.gd` and missing functional nodes.

### Task 2: Unified environment interaction component

**Files:**
- Create: `scripts/skill_interactable.gd`
- Modify: `scripts/main.gd`
- Modify: `scripts/bomb.gd`
- Modify: `scripts/rooms.gd`

- [ ] **Step 1: Implement the minimal protocol**

`SkillInteractable` extends `StaticBody2D`, exposes `setup(kind, size)` and `try_skill_interaction(tag, actor) -> bool`, and maps:

- `relay` → `sword_wave`
- `brittle_wall` → `hammer_charge` or `bomb`
- `steam_anchor` → `cannon_steam`
- `grapple_anchor` → `dual_grapple`
- `drill_wall` → `spear_drill`
- `remote_switch` → `crossbow_remote`

Walls disappear after a valid interaction; anchors apply one bounded impulse and cooldown; relay/switch reveal a short energy platform. Each kind has a unique commercial-readable color, icon and label.

- [ ] **Step 2: Connect room data and legacy bombs**

`main.gd` builds `room.skill_targets`; `bomb.gd` calls the protocol when present and preserves `queue_free()` fallback for legacy breakables. Add targets only to optional/secret spaces so failure cannot block the main route.

- [ ] **Step 3: Run the focused test**

Expected: component and room protocol assertions pass while player/data/preview assertions remain red.

### Task 3: Six weapon skills and data

**Files:**
- Modify: `scripts/player.gd`
- Modify: `scripts/skills_data.gd`

- [ ] **Step 1: Add six representative nodes**

Add stable IDs `sword_resonance`, `hammer_demolition`, `cannon_steam_jet`, `dual_grapple`, `spear_drill`, `crossbow_remote`, each with a weapon prerequisite, active input, environment description, bounded resource rule, one interaction tag and exactly five preview stages: `startup`, `travel`, `impact`, `interaction`, `recovery`.

- [ ] **Step 2: Emit interactions from existing heavy/skill attacks**

Use a shared player helper that searches nearby `skill_interactable` nodes, respects range and facing, and invokes the protocol. Hook sword heavy, hammer heavy, cannon upper, dual-blade dash, spear dash and crossbow heavy. Skills remain inert until their node is unlocked; impulses are supplied by the environment component so they cannot become universal flight or grapple.

- [ ] **Step 3: Run the focused test**

Expected: six data and player markers pass; only preview/capture assertions may remain red.

### Task 4: Five-stage preview and deterministic capture

**Files:**
- Modify: `scripts/skill_preview.gd`
- Modify: `scripts/main.gd`

- [ ] **Step 1: Expand the preview composition**

Add a training dummy, environment target, stage caption and interaction beam. `play_node()` chooses the target glyph from `interaction_tags` and loops startup → travel → impact → interaction → recovery without gameplay hitboxes or resource consumption.

- [ ] **Step 2: Add `SHOT_13D3` capture setup**

Support `SHOT_13D3=hammer_wall|cannon_steam|dual_grapple|spear_drill|sword_relay|crossbow_switch`; seed the representative skill, equip its weapon, move the player and target into a stable 1280×720 composition, trigger the correct skill and save multiple frames.

- [ ] **Step 3: Run focused and full contract suites**

Expected: `STAGE_13_D_3_PASS` and all existing `tests/test_*.gd` exit 0.

### Task 5: Visual QA, documentation, release and commit

**Files:**
- Create: `docs/qa/13D.3-review.md`
- Modify: `docs/DEV_PLAN.md`
- Create: `screenshots/13d3/*.png`

- [ ] **Step 1: Run and scan errors**

Run the editor parse check and main scene for at least 240 frames. Scan every output line containing `ERROR` or `SCRIPT ERROR`, excluding only documented Godot exit noise.

- [ ] **Step 2: Capture and inspect actual PNGs**

Capture all six skill previews plus hammer wall, steam anchor and grapple/drill interactions. Open every PNG, verify labels do not overlap, targets are visible, impulses remain inside the room and effects communicate the correct weapon. Fix and recapture any failure.

- [ ] **Step 3: Record evidence**

Write commands, hashes, screenshots, observed visual issues/fixes and remaining limitations to `docs/qa/13D.3-review.md`. Mark only `13D.3` complete in `DEV_PLAN.md`; keep parent `13D` and `13.4` open until the remaining global skill-effect pass is delivered.

- [ ] **Step 4: Export and verify the release**

Export the Windows preset to `E:\Godot\release\暗影机械城\ShadowMechCity.exe`, verify both EXE and PCK timestamps/hashes, launch the packaged build and scan its log for all executable errors.

- [ ] **Step 5: Commit only scoped files**

Stage the exact 13D.3 source, tests, screenshots and documentation files. Do not add, delete or overwrite existing unrelated untracked files. Commit message: `feat(13d3): add functional weapon interactions`.
