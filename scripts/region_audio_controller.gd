class_name RegionAudioController
extends Node
## 七区域动态音乐与程序化环境声。复用项目现有主题曲，不引入来源不明的新音频资产。

signal profile_changed(snapshot: Dictionary)

const REGION_PROFILES := {
	"city": {"name":"中央车站", "arrangement":"冷钢序曲", "ambient":"rail_hum", "pitch":1.00, "music_db":-17.0, "offset":0.0, "tone":55.0, "color":Color("55d9ff")},
	"mine": {"name":"废铁矿坑", "arrangement":"岩层脉冲", "ambient":"mine_pulse", "pitch":0.86, "music_db":-18.5, "offset":21.0, "tone":38.0, "color":Color("ff7138")},
	"factory": {"name":"蒸汽铸造厂", "arrangement":"过压锻炉", "ambient":"steam_engine", "pitch":1.08, "music_db":-16.5, "offset":44.0, "tone":46.0, "color":Color("ff9b38")},
	"water": {"name":"腐化水道", "arrangement":"沉没回声", "ambient":"water_cistern", "pitch":0.78, "music_db":-19.0, "offset":68.0, "tone":62.0, "color":Color("54e8e8")},
	"temple": {"name":"遗迹神殿", "arrangement":"星轮祭仪", "ambient":"rune_chime", "pitch":0.94, "music_db":-18.0, "offset":92.0, "tone":110.0, "color":Color("d6a8ff")},
	"void": {"name":"虚空要塞", "arrangement":"裂隙风暴", "ambient":"void_wind", "pitch":1.13, "music_db":-16.0, "offset":116.0, "tone":72.0, "color":Color("8b82ff")},
	"castle": {"name":"暗影王城", "arrangement":"君王挽歌", "ambient":"castle_organ", "pitch":0.82, "music_db":-15.5, "offset":142.0, "tone":49.0, "color":Color("c765da")},
}

const SAMPLE_RATE := 22050.0
const FADE_SECONDS := 1.15

var _music_players: Array[AudioStreamPlayer] = []
var _ambient_player: AudioStreamPlayer
var _ambient_playback: AudioStreamGeneratorPlayback
var _base_stream: AudioStream
var _active_index := 0
var _theme := "city"
var _intensity := 0
var _sample_clock := 0
var _noise_state := 17341
var _fade_tween: Tween


func setup(base_stream: AudioStream) -> void:
	_base_stream = base_stream
	if _base_stream is AudioStreamMP3:
		(_base_stream as AudioStreamMP3).loop = true
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "RegionMusic%d" % i
		player.stream = _base_stream
		player.volume_db = -50.0
		add_child(player)
		_music_players.append(player)
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.35
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "RegionAmbience"
	_ambient_player.stream = generator
	_ambient_player.volume_db = -24.0
	add_child(_ambient_player)
	_ambient_player.play()
	_ambient_playback = _ambient_player.get_stream_playback() as AudioStreamGeneratorPlayback
	transition_to("city", 0, false, true)


func transition_to(theme: String, enemy_count: int = 0, boss: bool = false, immediate: bool = false) -> void:
	if not REGION_PROFILES.has(theme):
		push_warning("Unknown region audio theme: " + theme)
		theme = "city"
	var target_intensity := 2 if boss else (1 if enemy_count > 0 else 0)
	if theme == _theme and not immediate:
		set_intensity(target_intensity)
		return
	_theme = theme
	_intensity = target_intensity
	var profile: Dictionary = REGION_PROFILES[_theme]
	var old_player := _music_players[_active_index]
	_active_index = 1 - _active_index
	var next_player := _music_players[_active_index]
	next_player.stream = _base_stream
	next_player.pitch_scale = _target_pitch()
	next_player.volume_db = -50.0
	next_player.play(float(profile["offset"]))
	if is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(next_player, "volume_db", _target_music_db(), 0.01 if immediate else FADE_SECONDS)
	if old_player.playing:
		_fade_tween.tween_property(old_player, "volume_db", -50.0, 0.01 if immediate else FADE_SECONDS)
		_fade_tween.chain().tween_callback(old_player.stop)
	_update_ambient_gain()
	profile_changed.emit(debug_snapshot())


func set_intensity(level: int) -> void:
	_intensity = clampi(level, 0, 2)
	if _music_players.is_empty(): return
	var active := _music_players[_active_index]
	var tween := create_tween().set_parallel(true)
	tween.tween_property(active, "volume_db", _target_music_db(), 0.45)
	tween.tween_property(active, "pitch_scale", _target_pitch(), 0.45)
	_update_ambient_gain()
	profile_changed.emit(debug_snapshot())


func debug_snapshot() -> Dictionary:
	var profile: Dictionary = REGION_PROFILES.get(_theme, REGION_PROFILES["city"])
	return {
		"theme": _theme,
		"region": profile["name"],
		"arrangement": profile["arrangement"],
		"ambient": profile["ambient"],
		"intensity": _intensity,
		"pitch": _target_pitch(),
		"music_db": _target_music_db(),
		"color": profile["color"],
	}


func show_debug_overlay() -> void:
	var old := get_node_or_null("AudioQAOverlay")
	if old != null: old.queue_free()
	var layer := CanvasLayer.new()
	layer.name = "AudioQAOverlay"
	layer.layer = 30
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(300, 88)
	panel.custom_minimum_size = Vector2(680, 168)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015,0.025,0.05,0.96)
	style.border_color = Color(debug_snapshot()["color"])
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 24; style.content_margin_right = 24
	style.content_margin_top = 16; style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var snapshot := debug_snapshot()
	var label := Label.new()
	label.text = "区域音频状态  ·  DYNAMIC AUDIO\n%s  /  %s\n环境层：%s    强度：%s    音高：%.2f    音量：%.1f dB" % [
		snapshot["region"], snapshot["arrangement"], snapshot["ambient"],
		["探索","战斗","Boss"][snapshot["intensity"]], snapshot["pitch"], snapshot["music_db"]]
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.82,0.94,1.0))
	panel.add_child(label)


func _target_music_db() -> float:
	return float(REGION_PROFILES[_theme]["music_db"]) + float(_intensity) * 1.7


func _target_pitch() -> float:
	return float(REGION_PROFILES[_theme]["pitch"]) * (1.0 + float(_intensity) * 0.025)


func _update_ambient_gain() -> void:
	if is_instance_valid(_ambient_player):
		_ambient_player.volume_db = -25.0 + float(_intensity) * 1.4


func _process(_delta: float) -> void:
	if _ambient_playback == null: return
	var frames := _ambient_playback.get_frames_available()
	for i in range(frames):
		var sample := _ambient_sample(float(_sample_clock) / SAMPLE_RATE)
		var pan := sin(float(_sample_clock) * 0.00019) * 0.12
		_ambient_playback.push_frame(Vector2(sample * (1.0-pan), sample * (1.0+pan)))
		_sample_clock += 1


func _ambient_sample(t: float) -> float:
	var profile: Dictionary = REGION_PROFILES[_theme]
	var tone := float(profile["tone"])
	var ambient := str(profile["ambient"])
	var wave := sin(TAU * tone * t)
	match ambient:
		"rail_hum":
			var tick := 0.12 * exp(-fmod(t, 2.0) * 45.0) * sin(TAU * 880.0 * t)
			return wave * 0.035 + tick
		"mine_pulse":
			var knock := 0.16 * exp(-fmod(t, 2.7) * 16.0) * sin(TAU * 76.0 * t)
			return wave * (0.025 + 0.02*sin(TAU*0.35*t)) + knock
		"steam_engine":
			return wave * 0.025 + _noise() * (0.025 + 0.018 * maxf(0.0, sin(TAU*1.4*t)))
		"water_cistern":
			var bubble := 0.09 * exp(-fmod(t, 1.65) * 12.0) * sin(TAU * (380.0 + fmod(t,1.65)*220.0) * t)
			return wave * 0.022 + bubble
		"rune_chime":
			return (wave + sin(TAU*tone*1.5*t)*0.55 + sin(TAU*tone*2.0*t)*0.28) * 0.028
		"void_wind":
			return _noise() * (0.028 + 0.022*sin(TAU*0.13*t)) + wave*0.018
		"castle_organ":
			return (wave + sin(TAU*tone*1.2*t)*0.62 + sin(TAU*tone*1.5*t)*0.38) * 0.028
	return wave * 0.025


func _noise() -> float:
	_noise_state = int((_noise_state * 1103515245 + 12345) & 0x7fffffff)
	return float(_noise_state % 2001) / 1000.0 - 1.0
