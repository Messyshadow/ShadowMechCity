# 阶段 13.1 主角视觉统一实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不改变碰撞和玩法的前提下，让角色、六武器、双刀副手与挤压拉伸共享统一视觉骨架，并完成确定性动作抓图。

**Architecture:** 新建只读姿态配置 `PlayerVisualProfile`；`player.gd` 用 `VisualRoot` 组合角色、机械核心、主副手武器和脚底阴影。现有动画、武器数据与攻击逻辑继续作为权威来源，视觉配置只负责姿态与显示。

**Tech Stack:** Godot 4.7 GDScript、程序化 CanvasItem、现有 SpriteFrames、源码 Godot、godot-capture。

---

### Task 1: 主角视觉契约

**Files:**
- Create: `tests/test_stage_13_1.gd`
- Create: `scripts/player_visual_profile.gd`

- [ ] **Step 1: Write the failing test**

测试六家族姿态字段、副手规则、远程持续可见、视觉根节点与 `SHOT_13_1`。

- [ ] **Step 2: Run test to verify it fails**

Run: `godot.windows.editor.x86_64.console.exe --headless --path . -s res://tests/test_stage_13_1.gd`

Expected: FAIL，因为 `player_visual_profile.gd` 和新节点尚不存在。

- [ ] **Step 3: Write minimal profile implementation**

实现 `PlayerVisualProfile.pose(weapon_id)`，返回 `hand`、`sprite_offset`、`visual_scale`、`rest_rot`、`swing_from`、`swing_to`、`upper_from`、`upper_to`、`offhand` 和 `recoil`。

- [ ] **Step 4: Run test to verify profile passes**

Expected: 只剩玩家接入与抓图入口相关失败。

### Task 2: 统一视觉骨架

**Files:**
- Modify: `scripts/player.gd`
- Test: `tests/test_stage_13_1.gd`

- [ ] **Step 1: Add VisualRoot contract assertions**

断言 `_build_nodes` 创建 `visual_root`、`ground_shadow`、`core_glow`、`offhand_pivot`、`offhand_weapon_sprite`。

- [ ] **Step 2: Run RED**

Expected: FAIL，提示视觉根与副手未接入。

- [ ] **Step 3: Implement visual hierarchy**

把角色与武器放入 `VisualRoot`；脚底阴影保持低层，机械核心保持低透明度；双刀副手按配置显示。

- [ ] **Step 4: Move squash to VisualRoot**

`_squash` 和 `_update_squash` 修改 `visual_root.scale`，角色自身始终保持 `HERO_SCALE`。

- [ ] **Step 5: Run GREEN**

Expected: stage 13.1 contracts pass。

### Task 3: 姿态与武器显示

**Files:**
- Modify: `scripts/player.gd`
- Modify: `scripts/weapons.gd`
- Test: `tests/test_stage_13_1.gd`

- [ ] **Step 1: Add pose behavior assertions**

验证远程武器攻击时保持可见、双刀副手可见、切换武器重置旋转。

- [ ] **Step 2: Run RED**

Expected: FAIL，旧 `_update_weapon` 会隐藏远程攻击武器。

- [ ] **Step 3: Apply profile in `_apply_weapon`**

设置主副手纹理、握点、缩放、角度和后坐；主副手都按朝向镜像。

- [ ] **Step 4: Apply pose in `_swing_weapon` and `_update_weapon`**

使用配置摆幅；远程武器除死亡状态外持续显示；贴墙时收拢武器。

- [ ] **Step 5: Run GREEN and full regression**

Expected: stage 13.1 与既有测试全部通过。

### Task 4: 确定性抓图与目视修复

**Files:**
- Modify: `scripts/main.gd`
- Test: `tests/test_stage_13_1.gd`

- [ ] **Step 1: Add capture contract and run RED**

断言 `SHOT_13_1`、`_prepare_13_1_capture` 与六武器循环入口。

- [ ] **Step 2: Implement capture**

在安全平地清场、固定角色位置和镜头；locomotion 连拍状态变化，weapons 连拍当前武器待机与攻击。

- [ ] **Step 3: Run source Godot captures**

对 locomotion 和六武器各抓实际 PNG，扫描所有 `ERROR` / `SCRIPT ERROR`。

- [ ] **Step 4: Inspect every PNG and fix**

检查脚底基线、武器握持、副手、远程开火、挤压同步和遮挡；发现问题后重新抓图。

### Task 5: QA、发布与提交

**Files:**
- Create: `docs/qa/13.1-review.md`
- Modify: `docs/DEV_PLAN.md`

- [ ] **Step 1: Run all tests and 240-frame main scene**

Expected: 全部通过且无 `ERROR` / `SCRIPT ERROR`。

- [ ] **Step 2: Write QA and update plan**

记录红绿测试、PNG 目视发现、修复、资产许可与发布证据，勾选 13.1。

- [ ] **Step 3: Export with source release template**

导出到 `E:\Godot\release\暗影机械城`，直启发布版 240 帧并记录时间、大小与 SHA-256。

- [ ] **Step 4: Commit only scoped files**

保留所有用户未跟踪文件，不纳入提交。
