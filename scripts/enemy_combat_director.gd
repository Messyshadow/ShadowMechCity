extends Node
class_name EnemyCombatDirector

## 房间级敌人节奏调度器：只分配短期行动许可与相对站位，不接管敌人的具体动作。
const RANGED_GAP := 0.42

const ROLE_SLOTS := {
	"vanguard": Vector2(120, 0),
	"lancer": Vector2(220, -10),
	"artillery": Vector2(430, -20),
	"harrier": Vector2(180, -190),
	"ambusher": Vector2(280, -150),
	"controller": Vector2(390, -170),
}

var _members: Array[Dictionary] = []
var _leases: Dictionary = {}
var _clock := 0.0
var _last_ranged := -99.0

func _process(delta: float) -> void:
	_clock += delta
	_expire_leases()
	_cleanup_members()

func register_enemy(enemy: Node, role: String) -> void:
	if not is_instance_valid(enemy):
		return
	for entry in _members:
		if entry["enemy"] == enemy:
			return
	_members.append({"enemy": enemy, "role": role})

func unregister_enemy(enemy: Node) -> void:
	var kept: Array[Dictionary] = []
	for entry in _members:
		if entry["enemy"] != enemy:
			kept.append(entry)
	_members = kept
	notify_action_finished(enemy)

func request_action(enemy: Node, channel: String, duration: float) -> bool:
	if not is_instance_valid(enemy) or channel not in ["melee", "ranged", "mobility"]:
		return false
	_expire_leases()
	for owned_channel in _leases:
		if is_instance_valid(_leases[owned_channel]["enemy"]) and _leases[owned_channel]["enemy"] == enemy:
			return false
	if _leases.has(channel):
		return false
	if channel == "ranged" and _clock - _last_ranged < RANGED_GAP:
		return false
	_leases[channel] = {"enemy": enemy, "expires": _clock + maxf(duration, 0.1)}
	if channel == "ranged":
		_last_ranged = _clock
	return true

func notify_action_finished(enemy: Node, channel: String = "") -> void:
	for owned_channel in _leases.keys():
		var owner: Node = _leases[owned_channel]["enemy"]
		if owner == enemy and (channel.is_empty() or channel == owned_channel):
			_leases.erase(owned_channel)

func formation_offset(enemy: Node, role: String) -> Vector2:
	var member_index := 0
	for i in range(_members.size()):
		if _members[i]["enemy"] == enemy:
			member_index = i
			break
	var side := -1.0 if member_index % 2 == 0 else 1.0
	var base: Vector2 = ROLE_SLOTS.get(role, Vector2(180, 0))
	return Vector2(base.x * side, base.y)

func _expire_leases() -> void:
	for channel in _leases.keys():
		var lease: Dictionary = _leases[channel]
		if not is_instance_valid(lease["enemy"]) or float(lease["expires"]) <= _clock:
			_leases.erase(channel)

func _cleanup_members() -> void:
	var kept: Array[Dictionary] = []
	for entry in _members:
		if is_instance_valid(entry["enemy"]):
			kept.append(entry)
	_members = kept
