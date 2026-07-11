extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var rooms_script = load("res://scripts/rooms.gd")
	var rooms: Dictionary = rooms_script.ROOMS
	for id in ["void_deck", "void_bridge", "void_hangar", "void_core", "void_throne"]:
		_check(rooms.has(id), "missing room: " + id)
	if rooms.has("void_deck"):
		_check(_has_ability(rooms["void_deck"], "shadow_glider"), "void_deck must grant shadow_glider")
	if rooms.has("void_bridge"):
		_check(not rooms["void_bridge"].get("winds", []).is_empty(), "void_bridge must contain wind")
	if rooms.has("void_throne"):
		_check(rooms["void_throne"].get("boss", {}).get("mode", "") == "void_dragon", "void_throne must use void_dragon boss mode")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for id in ["void_eagle", "void_wyvern", "storm_mage"]:
		_check(main_source.contains('"%s"' % id), "missing enemy definition: " + id)
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	_check(game_source.contains('"shadow_glider"'), "missing shadow_glider ability")
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	_check(player_source.contains('Input.get_axis("move_left", "move_right")'), "melee attacks must only lunge with directional input")
	var pickup_source := FileAccess.get_file_as_string("res://scripts/pickup.gd")
	_check(pickup_source.contains("MAGNET_RADIUS"), "rewards need baseline pickup magnetism")
	_check(game_source.contains("cleared_rooms"), "room combat clear state must survive door revisits")
	_check(main_source.contains("reload_current_room_after_death"), "death must immediately rebuild the current encounter")
	var dragon_source := FileAccess.get_file_as_string("res://scripts/void_dragon_boss.gd")
	_check(dragon_source.contains("create_timer(0.5)"), "dragon lightning needs a dodge telegraph before damage")
	_check(dragon_source.contains("body_col.shape.size = body_size"), "dragon phase two must update its collision shape")
	if failures.is_empty():
		print("PASS stage 10.5 contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _has_ability(room: Dictionary, id: String) -> bool:
	for ability in room.get("abilities", []):
		if ability.size() >= 3 and ability[2] == id:
			return true
	return false

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
