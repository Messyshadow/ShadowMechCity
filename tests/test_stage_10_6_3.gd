extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_check(FileAccess.file_exists("res://scripts/theme_backdrop.gd"), "missing dedicated castle/void backdrop renderer")
	_check(FileAccess.file_exists("res://scripts/downward_portal_visual.gd"), "missing dedicated downward portal renderer")
	_check(main_source.contains("const DOWN_PORTAL_HALF_WIDTH := 90.0"), "down portal opening must be 180px wide")
	_check(main_source.contains("_make_theme_backdrop(room)"), "rooms must build dedicated theme backdrop")
	_check(main_source.contains("_bg_fill_layer(theme)"), "all themes need a full-canvas fallback to prevent gray gaps")
	_check(main_source.contains("pbg.layer = -20"), "parallax fallback must stay behind world and HUD")
	_check(main_source.contains("THEME_BACKDROP_SCRIPT"), "main must dispatch theme backdrop renderer")
	_check(main_source.contains("DOWNWARD_PORTAL_VISUAL"), "main must dispatch portal visual renderer")
	_check(main_source.contains("if shaft[3] >= 500"), "short castle shafts must not stack a giant pit over the floor portal")
	_check(main_source.contains("size = Vector2(DOWN_PORTAL_HALF_WIDTH * 2.0"), "down door trigger must match the widened opening")
	if FileAccess.file_exists("res://scripts/theme_backdrop.gd"):
		var backdrop := FileAccess.get_file_as_string("res://scripts/theme_backdrop.gd")
		_check(backdrop.contains('"castle"'), "backdrop renderer needs castle art direction")
		_check(backdrop.contains('"void"'), "backdrop renderer needs void art direction")
		_check(backdrop.contains("_draw_castle"), "castle needs dedicated silhouettes")
		_check(backdrop.contains("_draw_void"), "void needs dedicated rift architecture")
		_check(backdrop.contains("var sy: float"), "void star coordinates need explicit float typing under warnings-as-errors")
	if FileAccess.file_exists("res://scripts/downward_portal_visual.gd"):
		var portal := FileAccess.get_file_as_string("res://scripts/downward_portal_visual.gd")
		_check(portal.contains("draw_colored_polygon"), "portal needs solid filled geometry")
		_check(portal.contains("draw_polyline"), "portal needs readable metal edges")
	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	_check(enemy_source.contains("_add_theme_role_visual"), "10.6 enemies need dedicated role silhouettes")
	for role in ["soul_shield", "soul_spear", "soul_cannon", "storm_mage"]:
		_check(enemy_source.contains('"%s"' % role), "missing visual role: " + role)
	_check(main_source.contains('"soul_cannon": {"sprite": "golem"'), "soul cannon must not reuse the mushroom mage sprite")
	_check(main_source.contains('"storm_mage": {"sprite": "jelly"'), "storm mage needs a mechanical floating silhouette")
	_check(main_source.contains('"void_eagle": {"sprite": "bat"'), "void eagle needs a dark flying silhouette")
	if failures.is_empty():
		print("PASS stage 10.6.3 visual contracts")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
