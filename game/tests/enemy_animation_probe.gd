extends Node

## A clip can pass a skeleton test and still never play on a live enemy. This
## instantiates the production actors, interrupts their actions, and checks the
## resulting pose without permitting visual code to move gameplay collision.
var _failures: int = 0


func _ready() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", label])
	if not ok:
		_failures += 1


func _run() -> void:
	var world := Node3D.new()
	add_child(world)
	for kind: String in ["wretch", "sling_wretch", "bellringer", "hall_warden", "hoard_keeper"]:
		var enemy := (load("res://actors/enemies/enemy.tscn") as PackedScene).instantiate() as Enemy
		enemy.archetype = StringName("enm_" + kind)
		world.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.set_process(false)
		var visual := enemy.get_node("Visual") as EnemyVisual
		var rigs: Array[Node] = visual.find_children("*", "Skeleton3D", true, false)
		_check(rigs.size() == 1, kind + " uses one production skeleton")
		if rigs.size() != 1:
			enemy.free()
			continue
		var rig := rigs[0] as Skeleton3D
		var hand: int = rig.find_bone("hand_r")
		var start: Transform3D = enemy.transform
		visual.present_enemy(Enemy.State.UNAWARE, Enemy.Attack.NONE, 0, 0, Vector3.ZERO, 0.2)
		rig.force_update_all_bone_transforms()
		var resting: Vector3 = rig.get_bone_global_pose(hand).origin
		visual.present_enemy(Enemy.State.ALERTED, Enemy.Attack.TELEGRAPH, 0, 1, Vector3.ZERO, 0.2)
		rig.force_update_all_bone_transforms()
		var raised: Vector3 = rig.get_bone_global_pose(hand).origin
		_check(resting.distance_to(raised) > 0.10, kind + " visibly winds up through the actor visual")
		visual.present_enemy(Enemy.State.ALERTED, Enemy.Attack.ACTIVE, 0, 1, Vector3.ZERO, 0.2)
		rig.force_update_all_bone_transforms()
		_check(raised.distance_to(rig.get_bone_global_pose(hand).origin) > 0.10,
			kind + " follows through when the hit becomes active")
		# **Every blow its own clip** (ADR-391): each blow an archetype lists
		# with a clip family has all three phases baked, and its wind-up puts
		# the knife hand somewhere the swing's does not — a lunge that looked
		# like a swipe would be read as one.
		var anim := visual.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var kind_data: EnemyResource = EnemyCatalogue.by_id(StringName("enm_" + kind))
		for blow: AttackResource in kind_data.attacks:
			if blow.clip == &"":
				continue
			for phase: String in ["telegraph", "attack", "recovery"]:
				_check(anim.has_animation("%s_%s" % [blow.clip, phase]),
					"%s has %s_%s baked" % [kind, blow.clip, phase])
			visual.present_enemy(Enemy.State.ALERTED, Enemy.Attack.TELEGRAPH, 0, 1, Vector3.ZERO,
				0.2, blow.clip)
			rig.force_update_all_bone_transforms()
			var coiled: Vector3 = rig.get_bone_global_pose(hand).origin
			_check(coiled.distance_to(raised) > 0.15, "%s's %s winds up unlike its swing (%.2f m apart)"
				% [kind, blow.clip, coiled.distance_to(raised)])
		if kind == "sling_wretch":
			var stone := visual.find_child("sling_stone", true, false) as MeshInstance3D
			_check(stone != null and not stone.visible, "sling releases its visible stone with the missile")
			visual.present_enemy(Enemy.State.ALERTED, Enemy.Attack.RECOVERY, 0, 1, Vector3.ZERO, 0.2)
			_check(stone != null and stone.visible, "sling reloads after recovery")
		# **Feet move when the body does** (ADR-275) — every state a body can
		# travel in, and the still ones hold their own clip. One stride of
		# travel must also carry the walk once round, which is what keeps a foot
		# planted rather than skating.
		var travels: Array = [
			[Enemy.State.UNAWARE, &"walk", &"idle"],
			[Enemy.State.SUSPICIOUS, &"walk", &"search"],
			[Enemy.State.ALERTED, &"run", &"idle"],
			[Enemy.State.SWARM, &"run", &"idle"],
		]
		for row: Array in travels:
			visual.present_enemy(row[0], Enemy.Attack.NONE, 0, 0, Vector3(0, 0, 0), 0.1)
			visual.present_enemy(row[0], Enemy.Attack.NONE, 0, 0, Vector3(0, 0, 0.1), 0.1)
			var moving: StringName = visual.get("_clip")
			visual.present_enemy(row[0], Enemy.Attack.NONE, 0, 0, Vector3(0, 0, 0.1), 0.1)
			var still: StringName = visual.get("_clip")
			_check(moving == row[1] and still == row[2], "%s in state %d %s moving, %s still (got %s, %s)"
				% [kind, row[0], row[1], row[2], moving, still])
		var player := visual.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		# Measured as an advance, from wherever the rows above left the cycle.
		visual.present_enemy(Enemy.State.UNAWARE, Enemy.Attack.NONE, 0, 0, Vector3(0, 0, 1.0), 0.1)
		visual.present_enemy(Enemy.State.UNAWARE, Enemy.Attack.NONE, 0, 0, Vector3(0, 0, 1.01), 0.1)
		var from: float = player.current_animation_position / player.current_animation_length
		visual.present_enemy(Enemy.State.UNAWARE, Enemy.Attack.NONE, 0, 0,
			Vector3(0, 0, 1.01 + EnemyVisual.ENEMY_WALK_STRIDE * 0.5), 0.1)
		var to: float = player.current_animation_position / player.current_animation_length
		var advance: float = fposmod(to - from, 1.0)
		_check(absf(advance - 0.5) < 0.02,
			"%s walks half a cycle in half a stride (advanced %.2f)" % [kind, advance])
		if kind == "bellringer":
			visual.present_enemy(Enemy.State.CALLING, Enemy.Attack.NONE, 0.5, 0, Vector3.ZERO, 0.1)
			_check(visual.get("_clip") == &"call", "bellringer rings while it calls")
		visual.present_enemy(Enemy.State.STAGGERED, Enemy.Attack.NONE, 0.3, 0, Vector3.ZERO, 0.2)
		_check(visual.get("_clip") == &"stagger", kind + " interrupts into stagger")
		visual.present_enemy(Enemy.State.DEAD, Enemy.Attack.ACTIVE, 1, 0, Vector3.ZERO, 0.2)
		rig.force_update_all_bone_transforms()
		_check(rig.get_bone_global_pose(rig.find_bone("head")).origin.y < 0.5,
			kind + " falls to the floor")
		_check(enemy.transform.is_equal_approx(start), kind + " animation never moves actor collision")
		enemy.free()
	var hunter := Gullsjukr.new()
	world.add_child(hunter)
	hunter.set_process(false)
	hunter.set_physics_process(false)
	var hunter_visual := hunter.get_node("Visual") as EnemyVisual
	for row: Array in [[Gullsjukr.State.DISTANT, &"walk", &"idle"],
			[Gullsjukr.State.COURSING, &"walk", &"walk"],
			[Gullsjukr.State.SIGHTED, &"run", &"idle"],
			[Gullsjukr.State.LOST, &"walk", &"search"]]:
		hunter_visual.present_hunter(row[0], EnemyVisual.HunterPresentation.NONE, 0, Vector3(0, 0, 0), 0.1)
		hunter_visual.present_hunter(row[0], EnemyVisual.HunterPresentation.NONE, 0, Vector3(0, 0, 0.1), 0.1)
		var going: StringName = hunter_visual.get("_clip")
		hunter_visual.present_hunter(row[0], EnemyVisual.HunterPresentation.NONE, 0, Vector3(0, 0, 0.1), 0.1)
		var halted: StringName = hunter_visual.get("_clip")
		_check(going == row[1] and halted == row[2], "hunter in state %d %s moving, %s still (got %s, %s)"
			% [row[0], row[1], row[2], going, halted])
	for phase: int in [EnemyVisual.HunterPresentation.COLLECT,
		EnemyVisual.HunterPresentation.TAKE, EnemyVisual.HunterPresentation.SHRUG]:
		hunter_visual.present_hunter(Gullsjukr.State.COLLECTING, phase, 0.5, Vector3.ZERO, 0.2)
		_check(hunter_visual.get("_clip") == ([&"collect", &"take", &"shrug"][phase - 1]),
			"hunter presents replicated action %d" % phase)
	hunter.free()
	world.free()
	await get_tree().process_frame
	print("[enemy-animation] %d failure(s)" % _failures)
	get_tree().quit(1 if _failures else 0)
