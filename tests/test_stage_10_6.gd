extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var rooms: Dictionary = load("res://scripts/rooms.gd").ROOMS
	var ids := ["castle_gate", "castle_gallery", "castle_chapel", "castle_knights", "castle_shaft", "castle_throne"]
	for id in ids:
		_check(rooms.has(id), "missing castle room: " + id)
	for i in range(ids.size() - 1):
		if rooms.has(ids[i]):
			_check(_links_to(rooms[ids[i]], ids[i + 1]), "%s must link to %s" % [ids[i], ids[i + 1]])
	if rooms.has("castle_gate"):
		_check(rooms["castle_gate"].get("theme", "") == "castle", "castle rooms need castle theme")
		_check(not rooms["castle_gate"].get("shafts", []).is_empty(), "castle gate needs a vertical shaft")
	if rooms.has("castle_knights"):
		_check(rooms["castle_knights"].get("boss", {}).get("mode", "") == "soul_knights", "knight arena needs soul_knights boss")
	if rooms.has("castle_throne"):
		_check(rooms["castle_throne"].get("boss", {}).get("mode", "") == "void_king", "throne needs void_king boss")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for enemy in ["soul_shield", "soul_spear", "soul_cannon"]:
		_check(main_source.contains('"%s"' % enemy), "missing castle enemy: " + enemy)
	_check(main_source.contains("_make_shaft"), "main must build detailed shafts")
	_check(main_source.contains("_play_shaft_transition"), "down doors need a shaft camera transition")
	_check(main_source.replace(" ", "").contains("camera.target=player"), "shaft transition must restore camera follow")
	_check(main_source.contains("_has_required_abilities"), "castle entrance needs all-ability gating")
	_check(main_source.contains("_arena_block_for_door"), "boss arenas need four-direction door blockers")
	_check(main_source.contains("soul_knights_boss.gd"), "main must dispatch the knight council boss")
	_check(main_source.contains("void_king_boss.gd"), "main must dispatch the three-phase final boss")
	_check(main_source.contains("_show_ending"), "final boss defeat needs an ending presentation")
	_check(FileAccess.file_exists("res://scripts/soul_knights_boss.gd"), "missing soul knights boss script")
	_check(FileAccess.file_exists("res://scripts/void_king_boss.gd"), "missing void king boss script")
	var knights_source := FileAccess.get_file_as_string("res://scripts/soul_knights_boss.gd")
	_check(knights_source.contains("_apply_role_visual"), "knight phases need distinct role silhouettes")
	_check(knights_source.contains("_joint_attack"), "final knight phase needs a joint attack")
	_check(knights_source.contains("active_member"), "knight council needs explicit sequential members")
	var king_source := FileAccess.get_file_as_string("res://scripts/void_king_boss.gd")
	_check(king_source.contains("randi()%(phase+1)"), "king moves must not unlock before their phase")
	_check(king_source.contains("_warn_core_pulse"), "core pulse needs a dodge warning")
	_check(king_source.contains("_warn_teleport"), "teleport barrage needs a target warning")
	_check(king_source.contains("body_col.shape.size=body_size"), "king phases need collision silhouette updates")
	_check(king_source.contains("touch_col.shape.size=body_size"), "king phases need touch silhouette updates")
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	_check(player_source.contains("weapon_switch"), "weapon switching needs upgraded FX")
	var bar_source := FileAccess.get_file_as_string("res://scripts/boss_bar.gd")
	_check(bar_source.contains("第3阶段"), "boss bar must label the final phase")
	if failures.is_empty():
		print("PASS stage 10.6 contracts"); quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _links_to(room: Dictionary, target: String) -> bool:
	for door in room.get("doors", []):
		if door.get("to", "") == target: return true
	return false

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
