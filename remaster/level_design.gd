extends RefCounted
## Authored traversal profiles, in metres; independent of the old pixel layout.
## [path height, upper reward ledge, hazard, traversal, visual landmark].
const PROFILES := {
	"hub": [2.8,5.2,"none","lift","station"],
	"temple": [2.6,4.9,"rune","stairs","pilgrimage"],
	"temple_atrium": [2.9,5.2,"rune","stairs","orrery"],
	"temple_undercroft": [2.6,4.8,"rune","ladder","crypt"],
	"temple_runes": [2.7,5.0,"rune","stairs","runes"],
	"temple_sanctum": [0.0,0.0,"none","stairs","sanctum"],
	"mine": [2.7,5.0,"steam","ladder","rail"],
	"depths": [2.8,5.2,"steam","ladder","excavation"],
	"tunnel": [2.5,4.8,"steam","ladder","tunnel"],
	"cavern": [2.7,5.1,"steam","ladder","crystal"],
	"mine_boss": [0.0,0.0,"none","ladder","quarry"],
	"water_grotto": [2.5,4.8,"water","pipe","cistern"],
	"water_channel": [2.6,4.9,"water","pipe","pumps"],
	"water_boss": [0.0,0.0,"none","pipe","reservoir"],
	"factory_entry": [2.7,5.0,"steam","stairs","gate"],
	"factory_works": [2.8,5.1,"steam","stairs","press"],
	"factory_foundry": [2.6,4.9,"steam","ladder","furnace"],
	"factory_conveyor": [2.8,5.2,"steam","lift","conveyor"],
	"boss": [0.0,0.0,"none","lift","boiler"],
	"void_deck": [2.8,5.1,"pulse","lift","dock"],
	"void_bridge": [2.6,4.9,"pulse","lift","bridge"],
	"void_hangar": [2.8,5.0,"pulse","lift","hangar"],
	"void_core": [2.7,5.0,"pulse","lift","singularity"],
	"void_throne": [0.0,0.0,"none","lift","dragon"],
	"castle_gate": [2.7,4.9,"rune","stairs","portcullis"],
	"castle_gallery": [2.8,5.0,"rune","stairs","gallery"],
	"castle_chapel": [2.6,4.9,"rune","stairs","chapel"],
	"castle_knights": [0.0,0.0,"none","lift","arena"],
	"castle_shaft": [2.8,5.1,"pulse","lift","shaft"],
	"castle_throne": [0.0,0.0,"none","lift","throne"],
	"secret_hub_archive": [2.5,4.7,"none","ladder","archive"],
	"secret_mine_cache": [2.6,4.8,"none","ladder","cache"],
	"secret_factory_heat": [2.5,4.8,"none","ladder","heat"],
	"secret_water_cistern": [2.6,4.9,"none","pipe","cistern"],
	"secret_temple_orbit": [2.7,4.9,"none","stairs","orrery"],
	"secret_void_observatory": [2.6,4.8,"none","lift","observatory"],
	"secret_castle_ossuary": [2.6,4.9,"none","stairs","ossuary"],
	"dawn_garden":[2.5,4.7,"none","lift","garden"],
	"dawn_conduit":[2.6,4.8,"rune","stairs","prism"],
	"dawn_beacon":[2.6,4.9,"none","ladder","beacon"],
}

static func profile(id: String) -> Array:
	return PROFILES.get(id,[2.6,4.9,"none","ladder","hall"])

static func platforms(id: String, width: float, shafts: Array) -> Array:
	var p:=profile(id)
	if float(p[0])==0:return []
	# Three steps form a legible jump route. The central ground lane remains clear.
	var result:Array=[]
	var index:=PROFILES.keys().find(id)
	var xs:Array=[.28,.48,.69,.84] if index%2==0 else [.22,.40,.61,.79]
	for i in range(xs.size()):
		var x:float=width*float(xs[i]);var y:float=float(p[1]) if i==1 else float(p[0])
		var w:=3.0 if i!=1 else 3.4
		# Keep an entire player capsule clear of the shaft, even on the upper route.
		var intersects:=false
		for sx in shafts:
			if absf(x-float(sx))<w*.5+(4.5 if str(p[3])=="stairs" else 1.35):intersects=true
		if not intersects:result.append(Vector3(x,y,w))
	return result

static func enemy_kind(theme: String, index: int) -> String:
	if theme=="dawn":return "warden" if index%2==0 else "stalker"
	var formations:={"mine":["sentry","drone","sentry"],"water":["drone","gunner","sentry"],"factory":["gunner","sentry","drone"],"temple":["sentry","gunner","sentry"],"void":["drone","gunner","drone"],"castle":["sentry","gunner","sentry"]}
	var choices:Array=formations.get(theme,["sentry"])
	return str(choices[index%choices.size()])
