extends SceneTree
## Offline asset authoring only. Generated scenes contain meshes, not runtime builders.
const OUT = "res://games/ocean_rescue/scenes/3d/"
func _initialize():
	call_deferred("build")
func mat(color: Color, rough := 0.45) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m
func add_mesh(root: Node3D, name: String, mesh: Mesh, material: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.name = name
	n.mesh = mesh
	n.material_override = material
	n.position = pos
	root.add_child(n)
	n.owner = root
	return n
func sphere(root, name, pos, size, material):
	var mesh = SphereMesh.new()
	mesh.radial_segments = 32
	mesh.rings = 16
	var n = add_mesh(root,name,mesh,material,pos)
	n.scale = size
	return n
func beam(root, name, a: Vector3, b: Vector3, radius: float, material):
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 12
	var n = add_mesh(root,name,mesh,material,(a+b)*0.5)
	n.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
	return n
func tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3):
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
func rounded(size: Vector3, radius: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half = size*0.5
	var inner = half-Vector3.ONE*radius
	for axis in range(3):
		for side in [-1,1]:
			for i in range(10):
				for j in range(10):
					var pts = []
					for uv in [Vector2(i,j),Vector2(i+1,j),Vector2(i+1,j+1),Vector2(i,j+1)]:
						var p = Vector3.ZERO
						p[axis] = half[axis]*side
						p[(axis+1)%3] = (uv.x/10.0*2-1)*half[(axis+1)%3]
						p[(axis+2)%3] = (uv.y/10.0*2-1)*half[(axis+2)%3]
						var q = p.clamp(-inner,inner)
						pts.append(q+(p-q).normalized()*radius)
					if side == 1:
						tri(st,pts[0],pts[2],pts[1]);tri(st,pts[0],pts[3],pts[2])
					else:
						tri(st,pts[0],pts[1],pts[2]);tri(st,pts[0],pts[2],pts[3])
	st.generate_normals()
	st.index()
	return st.commit()
func box(root,name,pos,size,material,radius=0.04):
	return add_mesh(root,name,rounded(size,radius),material,pos)
func hull_point(theta: float, width: float, length: float, y: float) -> Vector3:
	var z = cos(theta)
	return Vector3(sin(theta)*width*(1.0-0.20*maxf(z,0.0)),y,z*length)
func hull(root,name,levels,material):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(levels.size()-1):
		for i in range(80):
			var a = i*TAU/80.0
			var b = (i+1)*TAU/80.0
			var lo = levels[r];var hi = levels[r+1]
			var p = hull_point(a,lo.y,lo.z,lo.x)
			var q = hull_point(b,lo.y,lo.z,lo.x)
			var v = hull_point(a,hi.y,hi.z,hi.x)
			var w = hull_point(b,hi.y,hi.z,hi.x)
			tri(st,p,v,q);tri(st,q,v,w)
	st.generate_normals()
	st.index()
	add_mesh(root,name,st.commit(),material)
func save_scene(root: Node3D, file: String):
	# Collapse decorative static parts into one surface per material for low draw-call cost.
	if root.name in ["RescueBoat", "Palm"]:
		var groups = {}
		for child in root.get_children():
			if not child is MeshInstance3D: continue
			var material = child.material_override
			var key = material.get_instance_id()
			if not groups.has(key):
				var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[key] = {"st": st, "material": material}
			for surface in range(child.mesh.get_surface_count()):
				groups[key].st.append_from(child.mesh, surface, child.transform)
			root.remove_child(child); child.free()
		for key in groups:
			add_mesh(root,"BakedSurface",groups[key].st.commit(),groups[key].material)
	var packed = PackedScene.new()
	assert(packed.pack(root) == OK)
	assert(ResourceSaver.save(packed,OUT+file) == OK)
	root.free()
func boat():
	var root = Node3D.new();root.name = "RescueBoat"
	var coral = mat(Color("e96d4c"),0.3)
	var gold = mat(Color("f7c443"),0.3)
	var ivory = mat(Color("fff0d0"),0.4)
	var wood = mat(Color("ac7546"),0.68)
	var blue = mat(Color("164951"),0.16)
	var metal = mat(Color("54696a"),0.28)
	var rope = mat(Color("dfc99a"),0.85)
	hull(root,"RoundedCoralHull",[Vector3(-0.32,0.03,1.1),Vector3(-0.18,0.64,1.55),Vector3(0.12,0.94,1.94),Vector3(0.46,1.04,2.05)],coral)
	hull(root,"GoldenGunwale",[Vector3(0.42,1.045,2.06),Vector3(0.55,1.06,2.08),Vector3(0.62,1.0,2.01),Vector3(0.5,0.96,1.94)],gold)
	hull(root,"Deck",[Vector3(0.50,0.97,1.95),Vector3(0.50,0.001,0.001)],wood)
	for i in range(11):
		box(root,"DeckSeam%d"%i,Vector3(0,0.507,-1.4+i*0.26),Vector3(1.65,0.006,0.012),rope,0.002)
	box(root,"CabinBase",Vector3(0,0.75,-0.6),Vector3(1.45,0.5,1.48),gold,0.12)
	box(root,"CabinGlass",Vector3(0,1.38,-0.6),Vector3(1.27,0.87,1.22),blue,0.10)
	for x in [-0.69,0.69]:
		for z in [-1.27,0.07]:
			beam(root,"WindowPost",Vector3(x,0.94,z),Vector3(x,1.98,z),0.065,ivory)
		beam(root,"WindowCrossbar",Vector3(x,1.0,-1.27),Vector3(x,1.0,0.07),0.045,ivory)
		beam(root,"WindowMullion",Vector3(x,1.0,-0.62),Vector3(x,1.98,-0.62),0.035,ivory)
	box(root,"RoofCreamEdge",Vector3(0,1.99,-0.6),Vector3(1.73,0.13,1.78),ivory,0.06)
	box(root,"CoralRoof",Vector3(0,2.09,-0.6),Vector3(1.69,0.15,1.74),coral,0.07)
	beam(root,"Mast",Vector3(0,2.14,-0.85),Vector3(0,3.0,-0.85),0.035,ivory)
	beam(root,"Aerial",Vector3(0.28,2.15,-1.13),Vector3(0.28,2.8,-1.13),0.012,metal)
	beam(root,"CrossMast",Vector3(-0.25,2.72,-0.85),Vector3(0.25,2.72,-0.85),0.025,ivory)
	sphere(root,"NavigationLight",Vector3(0,3.02,-0.85),Vector3(0.12,0.15,0.12),coral)
	for x in [-1.0,1.0]:
		var torus = TorusMesh.new();torus.inner_radius=0.17;torus.outer_radius=0.29;torus.rings=32;torus.ring_segments=16
		var life = add_mesh(root,"Lifebuoy",torus,coral,Vector3(x,0.72,-0.55));life.rotation.z=PI/2
		for angle in range(4):
			var a=angle*PI/2
			box(root,"BuoyBand",Vector3(x,0.72+sin(a)*0.225,-0.55+cos(a)*0.225),Vector3(0.13,0.1,0.10),ivory,0.025)
		for z in [0.25,1.05]:
			beam(root,"RailPost",Vector3(x*0.88,0.58,z),Vector3(x*0.88,0.96,z),0.025,ivory)
		beam(root,"DeckRail",Vector3(x*0.88,0.96,0.2),Vector3(x*0.88,0.96,1.1),0.03,ivory)
		for z in [-1.3,0.1]:
			sphere(root,"Fender",Vector3(x,0.37,z),Vector3(0.18,0.48,0.18),ivory)
	save_scene(root,"rescue_boat_detailed.tscn")
func palm():
	var root=Node3D.new();root.name="Palm"
	var bark=mat(Color("9c7750"),0.9)
	var leaf=mat(Color("5d982e"),0.72);leaf.cull_mode=BaseMaterial3D.CULL_DISABLED
	var vein=mat(Color("b4bd4d"),0.8)
	for i in range(18):
		var t=i/18.0;var u=(i+1)/18.0
		beam(root,"Trunk",Vector3(t*t*0.38,t*1.65,0),Vector3(u*u*0.38,u*1.65,0),0.074-t*0.028,bark)
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center=Vector3(0.38,1.68,0)
	for f in range(10):
		var angle=f*TAU/10.0
		var dir=Vector3(cos(angle),0,sin(angle))
		var crossdir=Vector3(-sin(angle),0,cos(angle))
		var length=0.84+0.13*sin(f*2.1)
		for j in range(13):
			var t=j/13.0;var u=(j+1)/13.0
			var a=center+dir*t*length+Vector3.UP*(0.4*sin(t*PI)-0.2*t)
			var b=center+dir*u*length+Vector3.UP*(0.4*sin(u*PI)-0.2*u)
			beam(root,"LeafSpine",a,b,0.008,vein)
			for side in [-1,1]:
				var reach=0.24*sin((t*0.86+0.10)*PI)
				var tip=a+crossdir*side*reach+dir*0.12-Vector3.UP*0.10
				tri(st,a,b,tip)
				tri(st,b,tip+dir*0.035,tip)
	st.generate_normals()
	st.index()
	add_mesh(root,"FeatheredFronds",st.commit(),leaf)
	for i in range(3):sphere(root,"Coconut",center+Vector3(cos(i*2)*0.09,-0.06,sin(i*2)*0.09),Vector3(0.11,0.13,0.11),bark)
	save_scene(root,"palm_detailed.tscn")
func profile_mesh(profile: Array) -> ArrayMesh:
	# Rings along the forward Z axis: (z, radius_x, radius_y, center_y).
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(profile.size()-1):
		for i in range(64):
			var a=i*TAU/64.0;var b=(i+1)*TAU/64.0
			var r=profile[j];var s=profile[j+1]
			var p=Vector3(cos(a)*r.y,sin(a)*r.z+r.w,r.x)
			var q=Vector3(cos(b)*r.y,sin(b)*r.z+r.w,r.x)
			var v=Vector3(cos(a)*s.y,sin(a)*s.z+s.w,s.x)
			var w=Vector3(cos(b)*s.y,sin(b)*s.z+s.w,s.x)
			tri(st,p,v,q);tri(st,q,v,w)
	st.generate_normals()
	st.index()
	return st.commit()
func fin_mesh(points: Array, thickness: float) -> ArrayMesh:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center=Vector3.ZERO
	for p in points:center+=p
	center/=points.size()
	for side in [-1,1]:
		for i in range(points.size()):
			var a=points[i];var b=points[(i+1)%points.size()]
			var c=center+Vector3.UP*thickness*side
			if side==1:tri(st,a,c,b)
			else:tri(st,a,b,c)
	st.generate_normals()
	st.index()
	return st.commit()
func dolphin():
	var root=Node3D.new();root.name="DolphinRig"
	var blue=mat(Color("52778a"),0.24)
	var belly=mat(Color("c6dadb"),0.36)
	var black=mat(Color("122b36"),0.18)
	var white=mat(Color.WHITE,0.2)
	var body=profile_mesh([Vector4(-1.28,0.03,0.04,0),Vector4(-1.1,0.10,0.09,0),Vector4(-0.85,0.16,0.15,0.02),Vector4(-0.5,0.26,0.25,0.04),Vector4(0,0.34,0.33,0.07),Vector4(0.4,0.33,0.34,0.1),Vector4(0.65,0.27,0.27,0.11),Vector4(0.81,0.15,0.16,0.08),Vector4(0.85,0.015,0.03,0.08)])
	add_mesh(root,"Body",body,blue)
	sphere(root,"Belly",Vector3(0,-0.115,0.03),Vector3(0.49,0.28,1.35),belly)
	sphere(root,"Beak",Vector3(0,0.005,0.88),Vector3(0.27,0.20,0.67),blue)
	sphere(root,"LowerJaw",Vector3(0,-0.07,0.88),Vector3(0.25,0.065,0.62),belly)
	for side in [-1,1]:
		sphere(root,"Eye",Vector3(side*0.245,0.17,0.64),Vector3(0.085,0.085,0.085),black)
		sphere(root,"EyeGlint",Vector3(side*0.270,0.19,0.665),Vector3(0.023,0.023,0.023),white)
		beam(root,"Smile",Vector3(side*0.13,-0.035,0.98),Vector3(side*0.20,-0.03,0.64),0.009,black)
		var fin=add_mesh(root,"FlipperLeft" if side<0 else "FlipperRight",fin_mesh([Vector3(0,0,0.18),Vector3(side*0.27,0,0.12),Vector3(side*0.57,-0.07,-0.37),Vector3(side*0.45,-0.055,-0.39),Vector3(0,0,-0.20)],0.045),blue,Vector3(side*0.2,-0.11,0.23))
	var dorsal=add_mesh(root,"DorsalFin",fin_mesh([Vector3(0,0,0.25),Vector3(0.35,0,0.03),Vector3(0.59,0,-0.27),Vector3(0.43,0,-0.21),Vector3(0,0,-0.40)],0.06),blue,Vector3(0,0.32,-0.1));dorsal.rotation.z=PI/2
	var tail=Node3D.new();tail.name="Tail";root.add_child(tail);tail.owner=root;tail.position=Vector3(0,0,-1.17)
	var fluke=add_mesh(tail,"Flukes",fin_mesh([Vector3(0,0,0.17),Vector3(0.27,0,0.1),Vector3(0.67,0,-0.19),Vector3(0.57,0,-0.27),Vector3(0.13,0,-0.2),Vector3(0,0,-0.27),Vector3(-0.13,0,-0.2),Vector3(-0.57,0,-0.27),Vector3(-0.67,0,-0.19),Vector3(-0.27,0,0.1)],0.045),blue);fluke.owner=root
	var anim=Animation.new();anim.length=1.4;anim.loop_mode=Animation.LOOP_LINEAR
	for path in ["Tail:rotation:x","FlipperLeft:rotation:z","FlipperRight:rotation:z"]:
		var track=anim.add_track(Animation.TYPE_VALUE);anim.track_set_path(track,path)
		for i in range(5):anim.track_insert_key(track,i*0.35,sin(i*PI/2)*0.22)
	var lib=AnimationLibrary.new();lib.add_animation("Armature|Swim",anim)
	var player=AnimationPlayer.new();player.name="AnimationPlayer";player.add_animation_library("",lib);root.add_child(player);player.owner=root
	save_scene(root,"dolphin_detailed.tscn")

func collectibles():
	var root=Node3D.new();root.name="Litter"
	var plastic=mat(Color("65b8cf"),0.2)
	plastic.metallic=0.12
	var label=mat(Color("fff4d9"),0.6)
	var capmat=mat(Color("267ea5"),0.28)
	var model=Node3D.new();model.name="Model";root.add_child(model);model.owner=root;model.rotation=Vector3(0.1,0.35,0.15)
	var body=add_mesh(model,"Bottle",profile_mesh([Vector4(-0.66,0.03,0.03,0),Vector4(-0.61,0.18,0.18,0),Vector4(-0.49,0.20,0.20,0),Vector4(0.25,0.20,0.20,0),Vector4(0.39,0.17,0.17,0),Vector4(0.49,0.085,0.085,0),Vector4(0.60,0.085,0.085,0),Vector4(0.63,0.01,0.01,0)]),plastic);body.owner=root
	var wrap=CylinderMesh.new();wrap.top_radius=0.203;wrap.bottom_radius=0.203;wrap.height=0.32;wrap.radial_segments=40
	var n=add_mesh(model,"PaperLabel",wrap,label,Vector3(0,0,-0.05));n.rotation.x=PI/2;n.owner=root
	var cap=CylinderMesh.new();cap.top_radius=0.10;cap.bottom_radius=0.10;cap.height=0.13;cap.radial_segments=32
	n=add_mesh(model,"Cap",cap,capmat,Vector3(0,0,0.62));n.rotation.x=PI/2;n.owner=root
	for z in [-0.48,-0.36,0.23]:
		var ring=TorusMesh.new();ring.inner_radius=0.191;ring.outer_radius=0.208;ring.rings=32;ring.ring_segments=8
		n=add_mesh(model,"BottleRib",ring,plastic,Vector3(0,0,z));n.rotation.x=PI/2;n.owner=root
	save_scene(root,"bottle_detailed.tscn")
	root=Node3D.new();root.name="Litter"
	box(root,"Container",Vector3(0,0.03,0),Vector3(0.8,0.3,0.6),label,0.09)
	box(root,"Lid",Vector3(0,0.21,0),Vector3(0.87,0.10,0.67),mat(Color("e9a98b"),0.7),0.045)
	box(root,"LidInset",Vector3(0,0.267,0),Vector3(0.63,0.02,0.44),label,0.009)
	save_scene(root,"container_detailed.tscn")

func build():
	boat()
	palm()
	collectibles()
	dolphin()
	print("Baked detailed boat, palm, animated dolphin and collectible scenes")
	quit()
