extends RefCounted
## Validate a whole snapshot before applying it; retain a usable generation on failure.
const SLOTS := ["helmet","armor","gloves","boots","amulet","ring"]
const SquadData=preload("res://remaster/squad_data.gd")

static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid_item(item: Variant) -> bool:
	if not item is Dictionary:return false
	if not number(item.get("uid")) or float(item.uid)<1:return false
	if item.get("slot") not in SLOTS or not item.get("name") is String:return false
	for key in ["rarity","price","attack","armor","health","lifesteal"]:
		if not number(item.get(key)) or float(item[key])<0:return false
	if float(item.rarity)>3:return false
	for key in ["upgrade","buyback_price"]:
		if item.has(key) and (not number(item[key]) or float(item[key])<0):return false
	return true

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version")!=1:return false
	if data.has("squad") and not SquadData.valid(data.squad):return false
	for key in ["coins","xp","level","points","weapon","hp","ammo","magazine","potions","serial","deaths"]:
		if not number(data.get(key)) or float(data[key])<0:return false
	if not data.get("checkpoint_room") is String:return false
	var position:Variant=data.get("checkpoint")
	if not position is Array or position.size()!=3:return false
	for coordinate in position:
		if not number(coordinate):return false
	for key in ["skills","equipped","visited","bosses","collected"]:
		if not data.get(key) is Dictionary:return false
	for key in ["story","tutorial"]:
		if data.has(key) and not data[key] is Dictionary:return false
	for key in ["inventory","buyback"]:
		if not data.get(key) is Array:return false
	var identities:Dictionary={}
	for item in data.inventory+data.buyback:
		if not valid_item(item) or identities.has(int(item.uid)):return false
		identities[int(item.uid)]=true
	for slot in data.equipped:
		var item:Variant=data.equipped[slot]
		if slot not in SLOTS or not valid_item(item) or item.slot!=slot:return false
	return true

static func read_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):return null
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:return null
	return parser.data if valid(parser.data) else null

static func read_best(path: String) -> Dictionary:
	var exists:=false
	for candidate in [path,path+".tmp",path+".bak",path+".old"]:
		exists=exists or FileAccess.file_exists(candidate)
		var snapshot:Variant=read_file(candidate)
		if snapshot!=null:return {"data":snapshot,"source":candidate,"broken":false}
	return {"data":null,"source":"","broken":exists}

static func replace_file(source: String, target: String) -> Error:
	var previous:=target+".old"
	var had_previous:=FileAccess.file_exists(target)
	if had_previous:
		if FileAccess.file_exists(previous):
			var removed:=DirAccess.remove_absolute(previous)
			if removed!=OK:return removed
		var moved:=DirAccess.rename_absolute(target,previous)
		if moved!=OK:return moved
	var result:=DirAccess.rename_absolute(source,target)
	if result!=OK:
		if had_previous:DirAccess.rename_absolute(previous,target)
		return result
	if had_previous:DirAccess.remove_absolute(previous)
	return OK

static func write(path: String, data: Dictionary) -> bool:
	if not valid(data):return false
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(data));file.flush();var error:=file.get_error();file.close()
	if error!=OK or read_file(path+".tmp")==null:return false
	# Never replace a good backup with a corrupt primary after recovery.
	if read_file(path)!=null:
		if DirAccess.copy_absolute(path,path+".bak.tmp")!=OK:return false
		if replace_file(path+".bak.tmp",path+".bak")!=OK:return false
	return replace_file(path+".tmp",path)==OK

static func archive(path: String) -> String:
	var folder:=path+".recovery-"+str(Time.get_unix_time_from_system()).replace(".","-")
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:return ""
	for suffix in ["",".bak",".tmp",".old"]:
		var source:String=path+str(suffix)
		if FileAccess.file_exists(source):
			var target:String=folder.path_join("save"+str(suffix)+".json")
			if DirAccess.copy_absolute(source,target)!=OK:return ""
			if FileAccess.get_sha256(source)!=FileAccess.get_sha256(target):return ""
	return folder
