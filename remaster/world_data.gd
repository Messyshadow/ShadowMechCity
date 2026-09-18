extends RefCounted
## Expand the remaster without changing the classic game's room graph.
const Legacy = preload("res://scripts/rooms.gd")
static var ROOMS: Dictionary = build_rooms()

static func build_rooms() -> Dictionary:
	var rooms: Dictionary = Legacy.ROOMS.duplicate(true)
	rooms.hub.doors.append({"side":"down","p":1344,"to":"dawn_garden"})
	rooms["dawn_garden"] = {
		"name":"晨曦温室·升光庭院","theme":"dawn","bounds":[0,0,1664,640],
		"save":Vector2(240,640),"items":[[1024,600,"coin",""]],
		"doors":[{"side":"up","p":1280,"to":"hub"},{"side":"right","p":540,"to":"dawn_conduit"}]}
	rooms["dawn_conduit"] = {
		"name":"晨曦温室·棱镜回廊","theme":"dawn","bounds":[0,0,1920,640],
		"pits":[[760,230,2]],"items":[[1300,350,"chest",""]],
		"doors":[{"side":"left","p":540,"to":"dawn_garden"},{"side":"right","p":540,"to":"dawn_beacon"}]}
	rooms["dawn_beacon"] = {
		"name":"晨曦温室·引航灯塔","theme":"dawn","bounds":[0,0,1664,640],
		"save":Vector2(220,640),"items":[],
		"doors":[{"side":"left","p":540,"to":"dawn_conduit"}]}
	return rooms
