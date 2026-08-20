# Authority and integration map

Use this precedence when sources conflict:

1. The user's latest explicit Stage 11 request.
2. `docs/design/STAGE_11_FEATURE_SYSTEMS.md` for implementation decisions and scope.
3. `docs/design/暗影机械城_GDD(2).md` for the base game theme and progression.
4. `docs/design/暗影机械城_GDD——强化.md` for detailed Stage 11 ideas.
5. `docs/future_systems.md` as the historical idea record.

Current integration points to audit rather than replace:

- Save/progression/equipment: `scripts/game.gd`, `scripts/progression_migration.gd`, `scripts/items_data.gd`
- Inventory and equipment presentation: `scripts/inventory_panel.gd`, `scripts/character_equipment_preview.gd`
- Skill graph: `scripts/skills_data.gd`, `scripts/skill_graph.gd`, `scripts/skill_panel.gd`
- Enemies and coordination: `scripts/enemy.gd`, `scripts/enemy_combat_director.gd`, `scripts/boss.gd`
- Room/runtime assembly: `scripts/main.gd`, `scripts/rooms.gd`

Do not assume the speculative class names in the strengthened GDD already exist. Adapt the design to the repository's current programmatic scene architecture.
