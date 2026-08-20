---
name: stage-11-feature-systems
description: Plan, implement, review, or extend Shadow Mech City Stage 11 feature systems: robot summons, satellite quantum hardware patches, hacking, and living/combat quantum spaces. Use for any Stage 11 design or code change, including robot capture, companion AI, equipment brands/upgrades, hacking status effects, save migration, skill-tree integration, and Stage 11 Godot Capture QA.
---

# Stage 11 feature systems

Implement only the explicitly approved Stage 11 sub-batch. Do not build all four systems in one pass.

## Required reading

1. Read `docs/design/STAGE_11_FEATURE_SYSTEMS.md` completely.
2. Read `.claude/skills/stage-11-feature-systems/references/authority.md`.
3. Read the current `docs/DEV_PLAN.md` Stage 11 section.
4. Read the affected runtime files listed in the design document before writing contracts.
5. Use `.claude/skills/godot-capture/SKILL.md` for visual QA.

## Workflow

1. Audit current save fields, existing UI, combat director, factions, collision layers, and affected signals.
2. State the exact sub-batch boundary and non-goals in commentary.
3. Add a failing contract test before production code.
4. Add data/save migration before gameplay that persists new state.
5. Keep rules data-driven and keep UI separate from pure calculations.
6. Preserve existing equipment levels, inventory entries, skills, weapons, story flags, and room progress.
7. Add deterministic QA hooks for probabilistic hacking/capture logic; never weaken normal gameplay randomness to make screenshots pass.
8. Run all tests and scan every `ERROR` / `SCRIPT ERROR`.
9. Capture and inspect actual PNGs for every delivered state. Fix overlap, unclear prompts, collision, targeting, and scale defects.
10. Write `docs/qa/<stage>-review.md`, update plans, export the source-engine release, verify it, and commit only intended files.

## Non-negotiable rules

- Cap simultaneous summons at three and prohibit duplicate models in active slots.
- Bootstrap 11.1 with a starter robot roster; later migrate the same roster into 11.4 without changing IDs.
- Reuse `Game.coins` as the prototype currency. Do not create a parallel wallet merely to rename it “齿轮币”.
- Give every persistent equipment item and robot a stable instance ID; never persist an array index as identity.
- Treat temporary hacking allegiance and permanent quantum capture as different state transitions.
- Do not permanently capture story NPCs, organic enemies, unique Bosses, or scripted encounter controllers.
- Keep Boss hacking restricted to explicitly whitelisted debuffs/data scanning.
- Do not let summoned allies consume enemy combat-director attack tokens.
- Do not open the living space in combat. Do not pause the main tree for the combat-space bubble.
- Keep all new save fields optional and migrate old saves idempotently.

## Completion gate

Do not mark a sub-batch complete until its contract, runtime, screenshot, QA report, release package, and Git commit all pass. Record subjective balance or audio/feel checks separately from automated proof.
