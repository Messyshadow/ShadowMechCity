class_name AnimLoader
extends RefCounted
## 运行时从 assets/ 的 PNG 序列帧构建 SpriteFrames, 避免手写 .tres

## 把一段动画加入 SpriteFrames. frame_paths 为纹理路径数组.
static func add(sf: SpriteFrames, anim: String, frame_paths: Array, fps: float, loop: bool) -> void:
	if not sf.has_animation(anim):
		sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	for p in frame_paths:
		var tex: Texture2D = load(p)
		if tex != null:
			sf.add_frame(anim, tex)

## 生成 "dir/00.png".."dir/(n-1).png" 路径数组
static func seq(dir: String, count: int) -> Array:
	var arr: Array = []
	for i in range(count):
		arr.append("%s/%02d.png" % [dir, i])
	return arr

## 主角: rvros Adventurer 序列帧 (自带真实剑士攻击动画)
static func build_player() -> SpriteFrames:
	var sf := SpriteFrames.new()
	var h := "res://assets/hero_adv/"
	add(sf, "idle",       seq(h + "idle", 4), 8.0, true)
	add(sf, "run",        seq(h + "run", 6), 14.0, true)
	add(sf, "jump",       seq(h + "jump", 4), 12.0, false)
	add(sf, "fall",       seq(h + "fall", 2), 8.0, true)
	add(sf, "dash",       [h + "jump/01.png"], 1.0, false)
	add(sf, "wall_slide", seq(h + "fall", 2), 8.0, true)
	add(sf, "hurt",       seq(h + "hurt", 3), 12.0, false)
	# 真实攻击动画 (挥砍/连斩)
	add(sf, "attack1",    seq(h + "attack1", 5), 18.0, false)
	add(sf, "attack2",    seq(h + "attack2", 6), 20.0, false)
	add(sf, "attack3",    seq(h + "attack3", 6), 20.0, false)
	return sf

static func build_enemy(name: String, frames: int, fps: float) -> SpriteFrames:
	var sf := SpriteFrames.new()
	var dir := "res://assets/enemies/" + name
	add(sf, "move", seq(dir, frames), fps, true)
	return sf

static func build_slash() -> SpriteFrames:
	return build_effect("slash", 7, 18.0)

## 通用特效构建 (动画名统一为 "swing", 供 Fx.play_slash / 弹丸复用)
static func build_effect(name: String, count: int, fps: float) -> SpriteFrames:
	var sf := SpriteFrames.new()
	add(sf, "swing", seq("res://assets/effects/" + name, count), fps, false)
	return sf
