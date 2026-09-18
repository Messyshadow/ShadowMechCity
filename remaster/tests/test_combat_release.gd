extends SceneTree
## Release checks exercise damage and collision, not just animation startup.
var game: Node3D
var state: Node
var target: Node3D
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func strike() -> void:
	Input.action_press("r_attack")
	await frames(2)
	Input.action_release("r_attack")
	await frames(28)

func arrange(weapon: int) -> void:
	state.weapon = weapon
	game.player.position = Vector3(8,.02,0)
	game.player.velocity = Vector3.ZERO
	game.player.facing = 1
	game.player.combo_window = 0
	game.player.attack_time = 0
	game.player.buffered_attack = false
	target.position = Vector3(9.35,.02,0)
	target.hp = 5000

func run() -> void:
	state = root.get_node("Reforged")
	state.persistence_enabled = false
	state.new_game()
	state.bosses["temple_sanctum"] = true
	game = load("res://remaster/main.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.ui.close(); game.load_room("temple_sanctum")
	target = game.spawn_enemy("sentry",Vector3(9.35,.02,0))
	target.set_physics_process(false); target.max_hp = 5000
	await frames(10)
	arrange(0)
	await strike()
	check(target.hp < 5000,"J applies melee damage to a visible target ahead")
	arrange(0); target.position.x = 6
	await strike()
	check(target.hp == 5000,"ordinary melee does not hit behind the hunter")
	arrange(0)
	var wall: StaticBody3D = game.solid(Vector3(8.75,1.5,0),Vector3(.2,3,2.5))
	await frames(3); await strike()
	check(target.hp == 5000,"solid cover blocks melee damage")
	arrange(2); state.magazine = 8; state.ammo = 0
	await frames(3); await strike(); await frames(15)
	check(target.hp == 5000,"solid cover blocks projectile damage")
	check(state.magazine == 7,"blocked projectile still consumes ammunition")
	wall.queue_free(); await frames(3)
	arrange(2); state.magazine = 8
	await strike(); await frames(15)
	check(target.hp < 5000,"unobstructed projectile deals damage")
	arrange(0); state.first_trade(); state.hp = 60
	await strike()
	check(state.hp > 60 and state.hp < 62,"gift lifesteal heals proportionally to a landed strike")
	arrange(3)
	for i in range(4): await strike()
	check(game.player.combo == 3,"four timed gauntlet inputs reach the fourth combo step")
	check(target.hp <= 4946.01,"all four gauntlet strikes apply damage")
	state.points = 4
	check(state.learn("gauntlet_1") and state.learn("gauntlet_2") and state.learn("gauntlet_3"),"release character can learn the complete gauntlet branch")
	arrange(3); game.player.skill_cooldown = 0
	Input.action_press("r_skill"); await frames(2); Input.action_release("r_skill")
	await frames(65)
	check(5000 - target.hp > state.attack_damage()*3,"overdrive applies follow-up hits beyond its initial blow")
	arrange(0); state.hp = 90; game.player.invulnerable = 0
	Input.action_press("r_dash"); await frames(2); Input.action_release("r_dash")
	game.player.take_damage(30,-1)
	check(state.hp == 90,"dash invulnerability rejects incoming damage")
	await frames(60)
	arrange(0); game.player.invulnerable = 0; state.hp = 120
	target.set_physics_process(true); target.timer = 0
	await frames(90)
	check(state.hp < 120,"enemy attack actually damages a stationary hunter after its windup")
	state.bosses.clear(); game.load_room("void_core"); game.player.invulnerable = 100
	check(game.gate_reason("void_throne") != "","dragon throne remains locked before four regional cores")
	for id in ["temple_sanctum","mine_boss","water_boss","boss"]: state.bosses[id] = true
	check(game.gate_reason("void_throne") == "","four regional cores unlock the dragon throne")
	game.load_room("void_throne"); game.player.invulnerable = 100
	check(game.gate_reason("castle_gate") != "","castle remains locked while dragon is alive")
	var coins: int = state.coins
	game.boss.take_hit(game.boss.hp+1,1)
	await frames(3)
	check(state.bosses.has("void_throne") and state.coins == coins+150,"boss death grants exactly one core and the boss reward")
	check(game.gate_reason("castle_gate") == "","defeating the dragon unlocks the castle route")
	print("RELEASE COMBAT TESTS: ",checks," checks; ",failures.size()," failures")
	game.queue_free(); await frames(3)
	quit(0 if failures.is_empty() else 1)
