extends Node
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var ambient: AudioStreamPlayer
var music: AudioStreamPlayer
var score_id := ""
var playback_enabled := true

func _ready() -> void:
	playback_enabled=DisplayServer.get_name()!="headless"
	for id in ["jump","wall_jump","land","step","climb","slash","hit","hurt","punch","shot","empty","reload","explosion","splash","dash","save","warning","gear","lift","ambience"]:
		sounds[id] = load("res://remaster/assets/audio/" + id + ".wav")
	for i in range(16):
		var v := AudioStreamPlayer.new(); add_child(v); voices.append(v)
	ambient = AudioStreamPlayer.new(); add_child(ambient)
	ambient.stream = sounds.ambience; ambient.volume_db = -24
	ambient.finished.connect(func(): ambient.play())
	if playback_enabled:ambient.play()
	music=AudioStreamPlayer.new();add_child(music);music.volume_db=-24
	music.finished.connect(func():music.play())

func set_region(region: String, boss := false) -> void:
	var next:="boss" if boss else region
	if score_id==next:return
	var path:="res://remaster/assets/audio/score_"+next+".wav"
	if not ResourceLoader.exists(path):return
	score_id=next;music.stream=load(path)
	if playback_enabled:music.play()

func play(id: String, gain := 0.0, pitch := 1.0) -> void:
	if not playback_enabled or Reforged.mute or not sounds.has(id): return
	for v in voices:
		if not v.playing:
			v.stream = sounds[id]; v.volume_db = -10 + gain
			v.pitch_scale = pitch * randf_range(.96,1.04); v.play(); return

func machine(parent: Node3D, id: String, gain := -23.0) -> void:
	var v := AudioStreamPlayer3D.new(); parent.add_child(v)
	v.stream = sounds[id]; v.volume_db = gain; v.unit_size = 5; v.max_distance = 24
	# Muting is handled by the master bus; loops keep running and resume on unmute.
	v.finished.connect(func():v.play())
	if playback_enabled:v.play()

func _process(_delta: float) -> void:
	ambient.volume_db = -80 if Reforged.mute else -24
	AudioServer.set_bus_mute(0,Reforged.mute)
