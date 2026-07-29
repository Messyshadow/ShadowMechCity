extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var rooms: Dictionary = load("res://scripts/rooms.gd").ROOMS
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_check(source.contains("func _make_downward_portal"), "all down doors need a shared visible shaft portal")
	_check(source.contains("_make_downward_portal(room, d)"), "down doors must build the shared shaft portal")
	_check(source.contains("DOWNWARD_PORTAL_VISUAL"), "down portals need the dedicated solid visual component")
	_check(source.contains("func _add_theme_atmosphere"), "water and mine need dedicated atmospheric foreground layers")
	_check(source.contains("_add_theme_atmosphere(theme)"), "parallax must add theme atmosphere")
	_check(source.contains("_make_room_atmosphere(room)"), "rooms need visible theme atmosphere behind gameplay")
	_check(source.contains("portal_visual.position = Vector2(d[\"p\"], portal_bounds[3] - 4)"), "portal rim must be embedded in the floor instead of floating above it")
	_check(source.contains("_play_shaft_transition.call_deferred(d[\"to\"], \"down\")"), "down doors must use the shaft camera transition")
	_check(not source.contains("d[\"side\"] == \"down\" and not Rooms.ROOMS[room_id].get(\"shafts\", []).is_empty()"), "shaft transition must not be limited to castle shaft rooms")
	for room_id in ["depths", "mine", "temple", "factory_entry", "void_core"]:
		_check(rooms.has(room_id), "missing expected downward-route room: " + room_id)
		if rooms.has(room_id):
			_check(_has_down_door(rooms[room_id]), room_id + " needs a visible down portal")
	if failures.is_empty():
		print("PASS downward portal coverage")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _has_down_door(room: Dictionary) -> bool:
	for door in room.get("doors", []):
		if door.get("side", "") == "down":
			return true
	return false

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
