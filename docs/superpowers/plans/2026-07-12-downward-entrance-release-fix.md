# Downward Entrance and Release Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the mine/depths vertical route comfortably reversible and ship a genuinely source-built Windows game executable.

**Architecture:** Room data owns the traversal chain, the existing portal renderer owns entrance art, and the Windows export preset points at a source-built release template. Automated contracts guard geometry and release configuration; Godot capture verifies the rendered result.

**Tech Stack:** Godot 4.7, GDScript, SCons, Windows Desktop export.

---

### Task 1: Reachability contract

**Files:**
- Create: `tests/test_stage_10_6_4.gd`
- Modify: `scripts/rooms.gd`

- [ ] Add a conservative platform-route check for `depths` to its up door.
- [ ] Run the test and confirm the old 110-pixel steps fail.
- [ ] Replace the route with overlapping one-way platforms whose rises are at most 90 pixels.
- [ ] Run the test and confirm it passes.

### Task 2: Entrance visual contract

**Files:**
- Modify: `scripts/downward_portal_visual.gd`
- Test: `tests/test_stage_10_6_4.gd`

- [ ] Require structural lintel, braces, guide lamps and landing cues in the portal renderer.
- [ ] Enhance the renderer without changing collision ownership.
- [ ] Capture `mine` and `depths` PNG images and inspect geometry, layering and landing alignment.

### Task 3: Source-built release

**Files:**
- Modify: `export_presets.cfg`
- Modify: `docs/DEV_PLAN.md`
- Create: `docs/qa/10.6.4-entrance-release-review.md`

- [ ] Build `target=template_release` from the existing custom Godot source tree.
- [ ] Configure the Windows preset to use that exact template.
- [ ] Run all GDScript tests and scan runtime output for `ERROR` and `SCRIPT ERROR`.
- [ ] Export EXE + PCK to `E:/Godot/release/暗影机械城`.
- [ ] Launch the release EXE, capture the published build, record timestamps and hashes, then update QA and DEV_PLAN.
