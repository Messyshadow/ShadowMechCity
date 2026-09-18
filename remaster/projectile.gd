extends Node3D
var game: Node3D
var velocity := Vector3.ZERO
var damage := 12.0
var friendly := false
var life := 3.0
var piercing := false
var lifesteal := true
var hit_ids: Array[int] = []
var sweep_origin := Vector3.INF

func _physics_process(dt: float) -> void:
	if game.ui.panel_open or game.transitioning: return
	life-=dt
	if life<=0: queue_free(); return
	var previous := position
	if sweep_origin.is_finite():previous=sweep_origin;sweep_origin=Vector3.INF
	position+=velocity*dt
	var ray := PhysicsRayQueryParameters3D.create(previous,position,1)
	ray.hit_from_inside=true
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		game.burst(position,Color(1,.5,.1),4); queue_free(); return
	if friendly:
		for e in game.enemies:
			if not is_instance_valid(e) or e.dead or hit_ids.has(e.get_instance_id()): continue
			var lower:Vector3=e.position+Vector3.UP*e.radius
			var upper:Vector3=e.position+Vector3.UP*(e.body_height-e.radius)
			var closest:=Geometry3D.get_closest_points_between_segments(previous,position,lower,upper)
			if closest[0].distance_to(closest[1])<e.radius+.10:
				hit_ids.append(e.get_instance_id())
				var dealt:float=e.take_hit(damage,signf(velocity.x),false,previous)
				if lifesteal:Reforged.recover_life(dealt)
				if not piercing: queue_free(); return
	else:
		if game.companions.intercept(previous,position,damage):queue_free();return
		if segment_distance(game.player.position+Vector3.UP,previous,position)<.65:
			game.player.take_damage(damage,signf(velocity.x)); queue_free()

func segment_distance(point: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b-a
	return point.distance_to(a+ab*clampf((point-a).dot(ab)/maxf(.0001,ab.length_squared()),0,1))
