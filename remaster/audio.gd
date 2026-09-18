extends Node
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var ambient: AudioStreamPlayer

func _ready() -> void:
	for id in ["jump","wall_jump","land","step","climb","slash","hit","hurt","punch","shot","empty","reload","explosion","splash","dash","save","warning","gear","lift","ambience"]:
		sounds[id] = load("res://remaster/assets/audio/" + id + ".wav")
	for i in range(16):
		var v := AudioStreamPlayer.new(); add_child(v); voices.append(v)
	ambient = AudioStreamPlayer.new(); add_child(ambient)
	ambient.stream = sounds.ambience; ambient.volume_db = -24
	ambient.finished.connect(func(): ambient.play())
	ambient.play()

func play(id: String, gain := 0.0, pitch := 1.0) -> void:
	if Reforged.mute or not sounds.has(id): return
	for v in voices:
		if not v.playing:
			v.stream = sounds[id]; v.volume_db = -10 + gain
			v.pitch_scale = pitch * randf_range(.96,1.04); v.play(); return

func machine(parent: Node3D, id: String, gain := -23.0) -> void:
	var v := AudioStreamPlayer3D.new(); parent.add_child(v)
	v.stream = sounds[id]; v.volume_db = gain; v.unit_size = 5; v.max_distance = 24
	v.finished.connect(func():
		if not Reforged.mute: v.play())
	if not Reforged.mute: v.play()

func _process(_delta: float) -> void:
	ambient.volume_db = -80 if Reforged.mute else -24
	AudioServer.set_bus_mute(0,Reforged.mute)
