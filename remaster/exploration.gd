extends Node
const Data=preload("res://remaster/exploration_data.gd")
var game:Node3D
var seals:Array=[]
var bombs:Array=[]
var cooldown:=0.0

func build() -> void:
	seals.clear();bombs.clear();cooldown=0
	var special_index:=0
	for id in Data.catalog():
		var data:Dictionary=Data.catalog()[id]
		if data.room!=game.room_id or Reforged.collected.get(id,false)==true:continue
		var x:=clampf(float(data.x),3,game.room_width-3)
		var ground:Vector3=game.safe_ground_spawn(x)
		var pos:=ground+Vector3(0,.75,0)
		if data.kind=="chest" and not game.platforms.is_empty():
			var platform:Vector3=game.platforms[(game.platforms.size()-1-int(data.get("index",0)))%game.platforms.size()]
			pos=Vector3(platform.x,platform.y+.5,.1)
		elif data.kind in ["heart","memory"]:
			# Use the existing traversal shelves: added low decks can block walking,
			# companion healing rays and the approach to a vertical passage.
			if not game.platforms.is_empty():
				var shelf:Vector3=game.platforms[special_index%game.platforms.size()]
				pos=Vector3(shelf.x-.4,shelf.y+.75,0);special_index+=1
		elif data.kind=="module":
			# Modules are always on the main floor before the secret gates that need them.
			pos=ground+Vector3(0,1.0,0)
		elif data.kind=="supply":
			for candidate in [x,game.room_width*.27,game.room_width-4]:
				var point:Vector3=game.safe_ground_spawn(candidate)
				if game.enemies.any(func(enemy):return is_instance_valid(enemy) and absf(enemy.position.x-point.x)<2.4):continue
				pos=point+Vector3(0,.25,0);break
		var model_name:String={"coin":"ring","chest":"loot_chest","supply":"supply_crate","heart":"life_shard","memory":"memory_core","module":"ability_module"}[data.kind]
		var art:Node3D=game.model(model_name);game.world.add_child(art);art.position=pos
		if data.kind=="coin":art.scale=Vector3.ONE*.5
		var tint:Color={"coin":Color(1,.7,.3),"chest":Color(1,.7,.3),"supply":Color(.3,.95,.65),"heart":Color(1,.32,.3),"memory":Color(.72,.52,1),"module":Color(.3,.86,1)}[data.kind]
		var sign_node:Label3D=game.label3(str(data.name),pos+Vector3(0,1.05,0),tint,23)
		var pickup:Dictionary={"id":id,"pos":pos,"node":art,"chest":data.kind=="chest","label":sign_node,"kind":data.kind,"locked":false}
		if bool(data.get("sealed",false)) and not Reforged.collected.get("seal_"+str(id),false):
			pickup.locked=true
			sign_node.position=pos+Vector3(0,1.4,.85)
			var cover:Node3D=game.model("breakable_seal");game.world.add_child(cover);cover.position=pos-Vector3(0,.7,-.55)
			var body:StaticBody3D=game.solid(pos,Vector3(1.7,1.9,.32));body.position.z=.55
			sign_node.set_meta("prompt_source","橙色封板 · F 炸开");sign_node.text=game.controls.prompt("橙色封板 · F 炸开")
			seals.append({"id":id,"node":cover,"body":body,"pickup":pickup,"pos":pos})
		game.pickups.append(pickup)

func tick(dt:float) -> void:
	cooldown=maxf(0,cooldown-dt)
	for pickup in game.pickups.duplicate():
		if not is_instance_valid(pickup.node):continue
		if pickup.kind in ["heart","memory","module","coin"]:pickup.node.rotation.y+=dt
		if pickup.locked or game.player.position.distance_to(pickup.pos)>1.55:continue
		if not game.clear_sight(game.player.position+Vector3.UP*.8,pickup.pos):continue
		var result:=Data.collect(Reforged,str(pickup.id))
		if result.is_empty():continue
		game.toast(result,5);game.audio.play("save",-9);game.burst(pickup.pos,Color(.4,.8,1),14)
		pickup.node.queue_free();pickup.label.queue_free();game.pickups.erase(pickup)
	for bomb in bombs.duplicate():
		bomb.time-=dt;bomb.velocity.y-=18*dt
		var start:Vector3=bomb.node.position;var finish:Vector3=start+bomb.velocity*dt
		var query:=PhysicsRayQueryParameters3D.create(start,finish,1)
		var hit:Dictionary=game.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			bomb.node.position=hit.position+hit.normal*.13;bomb.velocity=bomb.velocity.bounce(hit.normal)*.4
		else:bomb.node.position=finish
		bomb.node.rotate_z(dt*4)
		if bomb.time<=0:
			detonate(bomb.node.position);bomb.node.queue_free();bombs.erase(bomb)

func throw_bomb() -> bool:
	if game.ui.panel_open or game.transitioning or game.player.death_time>0 or Reforged.hp<=0:return false
	if not Data.has_module(Reforged,"bomb"):
		game.toast("炸弹模块位于废铁矿坑·熔岩腔穴，获得后可使用 F。");return false
	if cooldown>0:return false
	cooldown=3.5
	var node:Node3D=game.model("pulse_bomb");game.world.add_child(node)
	node.position=game.player.position+Vector3(0,1.1,0)
	bombs.append({"node":node,"velocity":Vector3(game.player.facing*7,5,0),"time":1.2})
	game.audio.play("reload",-9);return true

func detonate(pos:Vector3) -> void:
	game.burst(pos,Color(1,.44,.1),32);game.audio.play("explosion",-7);game.shake=.16
	for seal in seals.duplicate():
		if pos.distance_to(seal.pos)>3.0:continue
		Reforged.collected["seal_"+str(seal.id)]=true;seal.pickup.locked=false
		seal.body.collision_layer=0;seal.body.queue_free();seal.node.queue_free()
		seal.pickup.label.text="生命碎片 · 最大生命 +10";seal.pickup.label.set_meta("prompt_source",seal.pickup.label.text)
		seals.erase(seal);Reforged.commit()
	for enemy in game.enemies:
		if is_instance_valid(enemy) and not enemy.dead and pos.distance_to(enemy.position+Vector3.UP)<3.0 and game.clear_sight(pos,enemy.position+Vector3.UP):
			enemy.take_hit(60,signf(enemy.position.x-pos.x))
