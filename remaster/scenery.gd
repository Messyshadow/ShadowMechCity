extends RefCounted
## Eight region compositions, with the playable lane brighter than the background.
static func place(g: Node3D, id: String, pos: Vector3, scale := Vector3.ONE) -> Node3D:
	var n:Node3D=g.model(id);g.world.add_child(n);n.position=pos;n.scale=scale;return n

static func build(g: Node3D, theme: String) -> void:
	var tint:Color=g.REGION_COLORS[theme]
	var width:float=g.room_width
	var sky:Color={"city":Color(.060,.10,.14),"mine":Color(.055,.049,.044),"water":Color(.038,.087,.083),"factory":Color(.088,.055,.043),"temple":Color(.076,.077,.093),"void":Color(.043,.037,.09),"castle":Color(.066,.079,.12),"dawn":Color(.20,.32,.35)}[theme]
	g.environment.background_color=sky;g.environment.fog_light_color=sky.lightened(.05)
	g.environment.fog_density=.012 if theme in ["mine","water"] else .006
	# A dark, distant silhouette layer gives the foreground room breathing space.
	if theme in ["city","factory","void","castle"]:
		for i in range(-2,8):
			var n:=place(g,"tower",Vector3(i*9,-5,-26),Vector3(1.2,1.1+posmod(i*7,5)*.22,1.2))
			if theme=="void":n.rotation.z=.05 if i%2==0 else -.07
			if theme=="castle":place(g,"buttress",Vector3(i*9,6,-25),Vector3.ONE*1.7)
	if theme in ["mine","water"]:
		for i in range(-1,7):
			var rock:=place(g,"rock_wall",Vector3(i*7,-1,-10),Vector3(1.4,1.6,1.0))
			rock.rotation.z=sin(float(i)*1.7)*.13
			for mesh in rock.find_children("*","MeshInstance3D",true,false):mesh.material_override=g.mat(Color(.085,.105,.125))
	# Strong region-specific landmarks; none occupy the movement plane.
	match theme:
		"dawn":
			for i in range(5):
				place(g,"gothic_arch",Vector3(i*8,0,-7),Vector3(1.15,1.15,1))
				place(g,"garden_planter",Vector3(i*7+2,0,-3.4),Vector3.ONE*1.15)
				g.cube(g.world,Vector3(i*8+3,5.5,-9),Vector3(4.6,7,.12),Color(.19,.36,.40))
			var sun:=DirectionalLight3D.new();g.world.add_child(sun);sun.rotation_degrees=Vector3(-48,-34,0);sun.light_color=Color(1,.87,.64);sun.light_energy=.8
			if g.room_id=="dawn_garden":place(g,"station_clock",Vector3(width*.58,5.6,-5),Vector3.ONE*1.4)
			elif g.room_id=="dawn_conduit":
				for i in range(3):place(g,"turbine",Vector3(5+i*9,2,-4.5),Vector3.ONE*1.2)
		"city":
			for i in range(3):
				place(g,"gantry",Vector3(i*12,0,-4.8))
				place(g,"pipe",Vector3(i*12+2,0,-5.0),Vector3(1.4,2.0,1.4))
			var wheel:=place(g,"gear",Vector3(width*.68,5.7,-7),Vector3.ONE*2.2);g.gears.append(wheel)
			place(g,"station_clock",Vector3(width*.32,5.6,-4.0),Vector3.ONE*1.3)
		"mine":
			for i in range(4):
				place(g,"gantry",Vector3(i*9,-.15,-3.8),Vector3(.75,.75,.7))
				place(g,"crystals",Vector3(i*9+3,-.4,-3.9),Vector3.ONE*(1.2+float(i%2)*.6))
			for x in range(0,int(width),5):g.cube(g.world,Vector3(x,6.7,-3.7),Vector3(5,.12,.18),Color(.20,.14,.08))
		"water":
			for i in range(4):
				place(g,"culvert",Vector3(i*10+2,0,-5),Vector3(1.2,1.3,1))
				place(g,"turbine",Vector3(i*10+6,0,-4.8))
				var p:=place(g,"pipe",Vector3(i*10,4.8,-3.4),Vector3(2,2.5,2));p.rotation.z=PI/2
		"factory":
			for i in range(4):
				place(g,"reactor",Vector3(i*9+3,0,-5),Vector3.ONE*1.2)
				place(g,"gantry",Vector3(i*9,0,-6.8),Vector3(.8,1.15,1))
				var wheel:=place(g,"gear",Vector3(i*9+6,4.5,-5.5),Vector3.ONE*1.4);g.gears.append(wheel);g.audio.machine(wheel,"gear",-31)
		"temple":
			for i in range(5):
				place(g,"gothic_arch",Vector3(i*9,0,-7.5),Vector3(1.4,1.2,1))
				place(g,"buttress",Vector3(i*9-3,0,-4.1),Vector3(1,1.25,1))
			var star:=place(g,"station_clock",Vector3(width*.56,5.6,-6),Vector3.ONE*2.0);g.gears.append(star)
		"void":
			for i in range(3):
				place(g,"gantry",Vector3(i*13,0,-5.6),Vector3(1.3,1.2,1))
				var r:=place(g,"void_ring",Vector3(i*13+7,5.2,-9),Vector3.ONE*1.6);g.gears.append(r)
			g.cube(g.world,Vector3(width*.5,-3,-7),Vector3(width,.08,1),tint,true)
		"castle":
			for i in range(5):
				place(g,"gothic_arch",Vector3(i*8,0,-6),Vector3(1.2,1.4,1))
				place(g,"buttress",Vector3(i*8-3.1,0,-3.8),Vector3(.8,1.45,.8))
				place(g,"banner",Vector3(i*8+2,4.6,-4.0))
	# Lamps cast warm pools on the stage; fewer competing emissive elements.
	for x in range(3,int(width),7):
		place(g,"lamp",Vector3(x,3.9,-2.2))
		var light:=OmniLight3D.new();g.world.add_child(light);light.position=Vector3(x,3.4,1.4)
		light.light_color=Color(.91,.82,.64).lerp(tint,.16);light.light_energy=2.0;light.omni_range=9
		g.cube(g.world,Vector3(x,-1.5,-.4),Vector3(.2,2.8,1.8),Color(.055,.075,.09))
	# Back safety rail and front exposed structure establish spatial depth.
	for x in range(0,int(width),4):
		g.cube(g.world,Vector3(x,.6,-1.65),Vector3(.065,1.2,.065),Color(.24,.20,.15))
		g.cube(g.world,Vector3(x+2,1.15,-1.65),Vector3(4,.045,.045),Color(.33,.26,.16))
		g.cube(g.world,Vector3(x+2,-2.6,-.4),Vector3(4,.25,1.8),Color(.038,.05,.064))
	var dust:=CPUParticles3D.new();g.world.add_child(dust);dust.position=Vector3(width*.5,5,-1)
	dust.amount=45;dust.lifetime=12;dust.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;dust.emission_box_extents=Vector3(width*.5,5,2)
	dust.gravity=Vector3.ZERO;dust.direction=Vector3.UP;dust.initial_velocity_min=.05;dust.initial_velocity_max=.13
	var mesh:=SphereMesh.new();mesh.radius=.017;mesh.height=.034;mesh.material=g.mat(tint.darkened(.4),true);dust.mesh=mesh
