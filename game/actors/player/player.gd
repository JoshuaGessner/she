class_name Player
extends CharacterBody3D

## `M1-T01` — the first-person controller. Walk, sprint, crouch, stamina, and
## weight felt in the hands (DES-009 Movement, DES-005 Layer 1).
##
## **Unjuiced on purpose.** Swink's ordering is a production rule here, not a
## theory: real-time control, then a predictable simulated space, then polish
## that *amplifies* what already works. There is no head bob, no landing
## shake, no camera kick and no footstep audio in this file, and there must not
## be until the controller is judged decent without them — juice cannot rescue
## bad control, it can only hide it long enough to build a game on top.
##
## Deliberately absent, not stubbed (ADR-064): mantling and ledge-hanging
## (unscheduled), fall damage (unscheduled), footstep Clamor (`M1-T04`).
##
## `M1-T02` added the weapon, health and a hurtbox. Still absent, and still on
## purpose: the heavy attack, block, shove and throw (DES-009's remaining
## verbs), and every juice layer in its M1 protocol.
##
## ## `M1-T05`: which peer decides what (ADR-082, `TEC-004`)
##
## **The owning peer is authoritative over this body's transform. The host is
## authoritative over every consequence.** `TEC-004` asks for client-side
## prediction of local movement while banning rollback and lag compensation —
## and prediction with no reconciliation is not prediction, it is authority. So
## the split is stated rather than implied, and it is visible in the node tree:
##
## | Synchroniser | Authority | Carries |
## |---|---|---|
## | `MotionSync` | the peer playing this body | position, yaw, pitch, stance, grounded |
## | `StateSync` | the host | health, carried weight, clamor |
##
## Everything with a consequence — damage, loot, noise — travels host→peer.
## Nothing a client says about those is believed, because it is never asked.
##
## A remote copy runs no input and no `move_and_slide`: its transform arrives.
## What it *does* run is the weapon phase machine, so a swing is visible on
## every screen and — on the host — arms a hitbox that can actually hurt
## something.

## Metres in front of your feet a dropped item lands. Far enough that you do
## not immediately pick it back up, close enough that abandoning something is
## visibly abandoning it *here* — `DES-005`'s cached loot is a later system,
## but "my gold is still down there" starts with being able to see where.
const DROP_DISTANCE: float = 0.9

## How far below the last ground you stood on counts as having left the level
## (`M2-T15`).
##
## **Relative, and that is not a detail.** An absolute floor is the obvious
## implementation and it would have been catastrophic here: the Chamber is an
## overlay parked **2000 m below the camp** (ADR-102), so any fixed threshold
## generous enough to catch a fall would also decide that every player standing
## in their own hoard room had fallen out of the world, and yank them back to
## the fire. Measuring from where you last stood works at any altitude and needs
## to know nothing about where levels put themselves.
const VOID_DROP: float = 45.0

## Godot's host is always peer 1, including the offline peer a solo launch
## gets, which is why none of this needs a single-player branch.
const HOST_PEER: int = 1

## `DES-012` targets 1–4 players, so there are four seats and four of anything
## keyed to them.
const MAX_PARTY: int = 4

## Loot leaving the bag. `CoopSession` listens and spawns the `WorldItem`,
## because a child never reaches into the tree above it for a service — signals
## up, calls down (`TEC-002`).
## The **instance**, not its id. A dungeon turns it into a `WorldItem`; the
## Chamber turns it into tribute or into stash (`DES-014`). Both need more than
## a definition name to do that — whose ember it was, which of two identical
## coins this is — and passing the id alone made *putting something down* mean
## less than it does.
signal dropped(item: ItemInstance, at: Vector3, yaw: float, launch: Vector3)
## A shot resolved on the host (`M3-T11`). **Signals up, calls down**: spawning
## is `CoopSession`'s job alone (ADR-112), so the body says an arrow left it and
## the session is what puts one in the world.
signal loosed_arrow(at: Vector3, travel: Vector3, kit: RangedTrait, shooter: int)
## A trap set, host-side. Same seam, same reason — and the session is also where
## *one live at a time* is enforced, because the session owns every spawned
## actor and a body counting its own traps is a second tally to get wrong.
signal set_snare(at: Vector3, placer: int)

## Left the floor alive, by Waystone. The level decides what that means — a
## body does not get to end its own run (`TEC-004`: consequences have one
## owner, and this is the largest one there is).
signal extracted(player: Player)

## Bled out (`M2-T05`, `DES-012`). The level drops the ember, because where a
## life ends up is the level's business and the body is past having opinions.
signal died_here(player: Player, at: Vector3)

## A blow that a raised guard took the weight of (`M3-T02`), carrying how much
## never reached you. Raised host-side, where the decision is made — the Foley
## and the shield-shake that `DES-018` will want a visual twin for hang off
## this rather than off the input, so a client sees its own block land because
## the host said it did.
signal blocked(stopped: float, from: Node)

## Metres per second a thrown item leaves the hand at, and how far the arc is
## tilted up from where you are looking ⟨tune⟩. `DES-017` wants a purse to go
## *down a side corridor*, so the throw has to buy real distance — baiting is
## worth nothing if the gold lands at your feet.
const THROW_SPEED: float = 11.0
const THROW_LIFT_DEGREES: float = 14.0

## Replication rate for a player body. `TEC-004`'s budget was measured at 20 Hz
## (ADR-068) and the ceiling is ~29 continuously-moving entities, so a party of
## four costs a rounding error of it.
const REPLICATION_HZ: float = 20.0

## What the owning peer sends, and how.
##
## `ALWAYS` for the three values that move continuously. ADR-068 measured
## `ON_CHANGE` costing **more** than `ALWAYS` for those (711 vs 528 kbps),
## because delta encoding adds overhead and never gets to elide anything — a
## body that is walking changes its position every single frame.
const MOTION_PROPERTIES: Dictionary = {
	# Assigned before the body enters the tree and never changed after, so it
	# rides the spawn packet and costs nothing thereafter.
	".:party_slot": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	# **Shadows, not the transform itself** (ADR-102). Writing straight to
	# `position` meant a remote body held still for three rendered frames and
	# then jumped, twenty times a second — which is exactly what "a little
	# jittery" looks like. These land in `net_*` and `_ease_toward_the_wire`
	# carries the body there.
	".:net_position": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	".:net_yaw": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	".:net_pitch": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	# These two genuinely idle — you are standing or crouched, on the floor or
	# not — which is the case `ON_CHANGE` is actually for.
	".:stance": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	".:grounded": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	# Idles the same way: a guard is up or it is not (`M3-T02`).
	".:blocking": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	# `ALWAYS`, unlike the two above: it moves continuously while it matters,
	# and what it drives is a collision layer every other peer's enemies have
	# to agree about. ADR-068 measured `ON_CHANGE` costing *more* for a value
	# that changes every frame.
	".:planted": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
}

## What the host sends. All three are consequences, and all three idle: health
## only moves when something hits you, weight only when you pick something up,
## clamor only while you are making noise.
const STATE_PROPERTIES: Dictionary = {
	"Health:current": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	"CarriedWeight:kilograms": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	"ClamorSource:level": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	# The bleed-out window and the revive (`M2-T05`). `ALWAYS` for both: they
	# move continuously the whole time they matter, and they are what a teammate
	# deciding whether to come for you is reading. ADR-068 measured `ON_CHANGE`
	# costing *more* than `ALWAYS` for values that change every frame.
	".:bleeding": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	".:revival": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
	".:spent": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
	# Spending a Waystone (`M2-T14`). `ALWAYS`, for the same reason as the two
	# above: it moves every frame while it matters, and it is driving a ring
	# somebody is watching. It has to replicate at all because `_spending` is
	# host-side — so a client spending their way home saw **nothing happen**
	# for the whole channel, exactly as they saw nothing standing in the Shaft.
	".:leaving": SceneReplicationConfig.REPLICATION_MODE_ALWAYS,
}

## Which seat in the party this body took, 0-3. Assigned once by `CoopSession`
## and never reused while a run lasts.
##
## **Peer ids are unusable as identity.** Godot's are large arbitrary integers
## (`player_854569567`), they differ per session, and the host's is always 1 no
## matter who is hosting — so nothing can be keyed to them that a human has to
## read or that art has to vary on. A slot is small, stable and countable,
## which is what `DES-019`'s party frames need and what tells one **ember**
## from another (`M2-T05`).
##
## At `M3-T02` the class silhouette becomes the real answer to *whose is that*
## (`DES-020`: teammates can read your loadout across a room). The slot is what
## carries it until there are classes to look at.
var party_slot: int = 0

## 0 standing, 1 fully crouched. Replicated, because a crouched teammate must
## be crouched on every screen *and* present a shorter capsule to the host's
## hit detection — a body whose collider disagrees with its silhouette is the
## unexplainable death `PRO-005` §5 forbids.
var stance: float = 0.0:
	set(value):
		stance = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply_stance()

## Replicated so the host can tell a landing from a step for *any* body, not
## just the one it is playing. Deriving it from position would mean inferring
## contact from a curve that arrives at 20 Hz.
var grounded: bool = true

## Which of the Sworn this body is (`M3-T02`, `DES-011`).
##
## Set from the spawn payload before the body enters the tree, so it rides the
## packet exactly like `party_slot` and every peer builds the same Húskarl from
## the same data. **Not read from `GameState`**, which knows only the class of
## the person sitting at *this* machine — the host builds four bodies and three
## of them belong to somebody else.
##
## Empty is a real value: a body with no class is what the gym, the probes and
## a profile that has not sworn yet all produce, and it takes the shared
## profile unmodified.
var sworn: StringName = &""

## **The rules this life has bought** (`M3-T01`, `DES-004`, `TEC-006`).
##
## Set from the spawn payload before the body enters the tree, exactly like
## `sworn` and for exactly the same reason: `GameState` knows only this
## machine's tree, and the host builds four bodies of which three belong to
## somebody else. A system that asked `GameState.has_effect` on the host would
## give the host's whole party the host's own nodes — ADR-121's fault arriving
## one task later through a different door.
##
## Tags rather than node ids, per `TEC-006`: the node never contains logic, it
## names a rule, and the system that owns that rule reads it here.
var effects: PackedStringArray = PackedStringArray()

## **Planted** (`M3-T02`, `DES-011`) — the Húskarl's verb, *Hold*.
##
## 0 loose, 1 fully planted, and it crosses the wire for a harder reason than
## `stance` does: while this is 1 the body carries `CollisionLayers.BULWARK`,
## which is what makes it *a wall to everything hostile*. A layer applied only
## on the owner would give a client a doorway nobody else's enemies believed in.
##
## `DES-011`: *"plant and become an immovable object. Nothing pushes past you.
## Allies can retreat through you."* The last sentence is the layer's doing —
## enemies mask `BULWARK` and players never do, so teammates pass through with
## no rule anywhere saying "except teammates".
var planted: float = 0.0

## Guard up (`M3-T02`, `DES-009`).
##
## **Replicated for the same reason `stance` is, and it is not cosmetic.** The
## owning peer decides to raise a guard; the *host* decides what a blow does,
## because `TEC-004` gives consequences one owner. So a client's block has to
## reach the host or it stops a blow on that screen and nowhere else — a
## teammate who watched you block and then watched you take it in full is the
## unexplainable death `PRO-005` §5 forbids, arriving over the wire.
var blocking: bool = false

var _yaw: float = 0.0
var _pitch: float = 0.0
var _crouching: bool = false
var _crouch_latched: bool = false
var _is_local: bool = false
## False while a menu has the player's attention. See `set_driving`.
var _driving: bool = true

## Where the wire says this body is. The owner writes them from its own
## simulation; everybody else reads them and eases toward them.
##
## `TEC-004` has described enemy transforms as *"synchronized, interpolated"*
## since it was written, and nothing in the project interpolated anything —
## another line of documentation describing a thing that was never built.
var net_position: Vector3 = Vector3.ZERO
var net_yaw: float = 0.0
var net_pitch: float = 0.0
## Host-side: has the peer that owns this body confirmed it has a copy? Until
## it has, there is nothing to send a bag to. See `_push_bag`.
var _owner_ready_for_bag: bool = false

## 0 shut, 1 fully open. A float rather than a bool because `DES-019` charges
## *time* for opening the bag — you kneel and rummage while the floor keeps
## happening — so the same number drives the screen's fade and the movement
## penalty, and neither can get ahead of the other.
var _bag: float = 0.0
var _bag_wanted: bool = false
var _bag_screen: BagScreen = null
## The item the local player would take if they pressed interact right now.
var _reaching_for: WorldItem = null
## Seconds left on a Waystone being spent. Host-side; zero when not leaving.
var _spending: float = 0.0
## Seconds the current spend started with, so the fraction below has a
## denominator. Host-side; the fraction is what travels.
var _spending_total: float = 0.0

## How far through spending a Waystone, 0–1, on every peer. Replicated because
## the countdown that drives it is not.
var leaving: float = 0.0

## Seconds of bleeding left, or 0 when up. **Replicated**, because `DES-012`
## makes the window itself the decision — *"a visible, shortening window; your
## ember is going out whether you choose or not"* (ADR-050) — and a teammate
## deciding whether to come for you has to see the same clock you do.
var bleeding: float = 0.0
## How far through a revive someone has got, 0..1. Replicated for the same
## reason: the person on the floor watches it too.
var revival: float = 0.0
## `true` once the window ran out. The body stays where it fell (`DES-012`: you
## become a Vörðr) rather than vanishing, so there is a place the ember is.
var spent: bool = false

## Solo's single self-recovery (ADR-050) — *"once per run, costly, and never
## better than having a friend."* Spent, not regenerating.
var _self_recovery: bool = true
## A remote rescuer's held `interact`, as told to the host.
var _reviving: bool = false

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _collider: CollisionShape3D = $CollisionShape3D
@onready var _capsule: CapsuleShape3D = _collider.shape as CapsuleShape3D
@onready var _body: MeshInstance3D = $Body
@onready var _body_mesh: CapsuleMesh = _body.mesh as CapsuleMesh
@onready var stamina: Stamina = $Stamina
@onready var carried: CarriedWeight = $CarriedWeight
@onready var inventory: Inventory = $Inventory
@onready var health: Health = $Health
@onready var weapon: MeleeWeapon = $Head/Weapon
## A bow, or null (`M3-T11`). Built in `_ready` only when the class carries
## one, rather than sitting hidden in `player.tscn` for the five of `DES-011`'s
## six that do not — see `RangedWeapon`.
var ranged: RangedWeapon = null
## How far through setting a Snare, 0 to 1. **Not replicated**, unlike the
## Húskarl's `planted`: that one crosses the wire because it changes a collision
## layer and the host's enemies have to collide with it. This changes nothing
## anyone else's machine has to agree about — the legible event is the trap
## appearing, and the trap is a spawned actor that appears for everybody.
var _setting: float = 0.0
@onready var clamor: ClamorSource = $ClamorSource
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _ink: InkPass = $Head/Camera3D/InkPass

var _step_accumulator: float = 0.0
var _was_grounded: bool = true
var _last_position: Vector3 = Vector3.ZERO
## The last place this body was genuinely standing, and where a fall out of the
## world puts it back (`M2-T15`). Seeded from the spawn by `_apply_teleport`,
## so it is never the origin by accident.
var _last_solid: Vector3 = Vector3.ZERO


## Build this body's two synchronisers and hand it to a peer.
##
## Called by `CoopSession` **before** the node enters the tree, so `_ready`
## already knows whose body it is. Deciding afterwards costs one frame of a
## teammate's body holding the camera and capturing the mouse, which is exactly
## as bad as it sounds.
##
## The order matters: `set_multiplayer_authority` is recursive by default, so
## it has to run before the host-owned synchroniser exists, or it would hand
## the host's half of the split to the client as well.
func configure_replication(owning_peer: int) -> void:
	set_multiplayer_authority(owning_peer)
	add_child(_build_sync("MotionSync", owning_peer, MOTION_PROPERTIES))
	add_child(_build_sync("StateSync", HOST_PEER, STATE_PROPERTIES))


func _build_sync(sync_name: String, authority: int,
		properties: Dictionary) -> MultiplayerSynchronizer:
	var config := SceneReplicationConfig.new()
	for path: String in properties:
		var property := NodePath(path)
		config.add_property(property)
		# In the spawn packet as well as the stream, so a player who joins
		# mid-session sees everyone where they are and as hurt as they are,
		# rather than at the origin at full health until the next update.
		config.property_set_spawn(property, true)
		config.property_set_replication_mode(property, int(properties[path]))

	var sync := MultiplayerSynchronizer.new()
	sync.name = sync_name
	sync.replication_config = config
	# **Both** intervals, never one (ADR-068). `ON_CHANGE` properties travel
	# the delta channel, which has its own `delta_interval` defaulting to every
	# network frame — setting only `replication_interval` leaves deltas running
	# at the physics rate and silently costs about 4x the bandwidth.
	sync.replication_interval = 1.0 / REPLICATION_HZ
	sync.delta_interval = 1.0 / REPLICATION_HZ
	sync.set_multiplayer_authority(authority)
	return sync


func _ready() -> void:
	add_to_group("player")
	_is_local = is_multiplayer_authority()
	if _is_local:
		# One group for "every player" and one for "the body this process is
		# playing". The debug views want the second; the enemies want the
		# first, and getting those the wrong way round makes a teammate
		# invisible to every enemy in the level.
		add_to_group("local_player")

	var tuning: TuningProfile = Config.tuning
	_capsule.radius = tuning.body_radius
	_body_mesh.radius = tuning.body_radius
	_camera.fov = tuning.field_of_view
	_apply_stance()
	# **The class shapes the body, and it is not a stat block** (`M3-T02`).
	# `DES-009` Q22 refused a third build axis; these are multipliers on one
	# shared profile so a Húskarl *walks* like a Húskarl. Applied before
	# `restore()` so the pool it fills is the right size, and on every peer
	# from the spawn payload rather than from local state — `GameState` knows
	# only this machine's class, and the host has to build everybody's body.
	var body: ClassResource = ClassCatalogue.by_id(sworn)
	health.maximum = tuning.player_health * (body.health_scale if body else 1.0)
	health.restore()
	_last_position = global_position
	# **Where this body starts is ground it has stood on** (`M2-T16`, ADR-108).
	#
	# `_last_solid` used to be seeded only by `_apply_teleport`, and the Chamber
	# does not teleport its body in — it assigns `position` and adds the child,
	# because the room is built around its own origin. So the one body in the
	# game that spawns 2000 m down began life measuring itself against a memory
	# of the camp, read `-2000 < 0 - 45` on its first physics frame, and was
	# returned to a camp that had just been hidden. ADR-107 rejected an absolute
	# floor for exactly this reason; the threshold was relative and the *seed*
	# was not.
	#
	# Beside `_last_position` because they are the same kind of fact — where
	# this body was a moment ago — and a body that seeds one and not the other
	# is the asymmetry that caused this.
	_last_solid = global_position

	# Damage arrives here only on the host: `Hitbox` refuses to resolve an
	# overlap anywhere else, so this connection is host-authoritative by
	# construction rather than by a second guard that could drift out of step.
	_hurtbox.hit.connect(_on_hurt)
	# Zero health is **down**, not dead (`DES-012`). Death is what happens when
	# the window runs out with nobody's hand on you, and it is a separate event
	# with a separate consequence.
	health.died.connect(_on_health_emptied)
	weapon.swing_started.connect(_on_swing_started)
	weapon.connected.connect(_on_swing_connected)
	_arm_from_kit(body)
	# **The tree configures the components** (`M3-T01`, `TEC-006`). Calls down,
	# never up: `Inventory` is told what rules are on rather than reaching for a
	# body to ask, and the body is the only thing that knows whose tree it is.
	# From `effects`, which came off the spawn payload — so the host sets four
	# bags from four trees rather than four bags from its own.
	inventory.weightless_materials = has_effect(&"weightless_materials")
	inventory.unlimited = has_effect(&"carry_no_limit")
	inventory.weight_costs_double = has_effect(&"weight_costs_double")
	# Loot is the only gameplay source of carried weight. `CarriedWeight`'s own
	# note said the value was driven by hand *until `M2-T01`*, and the dev keys
	# that did it are gone with this line rather than left beside it — two
	# writers to one number is the second weight path ADR-064 bans.
	inventory.changed.connect(_on_inventory_changed)
	_on_inventory_changed()
	# A remote owner tells the host it is ready to be handed its bag. The host
	# plays its own body, so it never has to ask itself.
	if _is_local and not multiplayer.is_server():
		_ask_for_my_bag.rpc_id(HOST_PEER)

	# First person: you are inside your own body, so you never draw it, and
	# the ink pass is a clip-space quad that would composite over everyone
	# else's view if a teammate's copy kept one.
	_body.visible = not _is_local
	_ink.visible = _is_local
	set_process_unhandled_input(_is_local)
	if _is_local:
		_camera.make_current()
		if InputDevices.pointer_allowed():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Only the body this process is playing draws a bag. A teammate's copy
		# building one would put four inventory screens on one screen.
		_bag_screen = BagScreen.attach(self)
		# The Ear, for the same reason and on the same terms (`M2-T03`). It
		# reports what *this* player is emitting and what has noticed them, so
		# a teammate's copy would be answering someone else's question.
		Ear.attach(self)
	else:
		_camera.current = false


func _on_swing_started() -> void:
	# Tell the other peers to play the swing this client has already committed
	# to and paid for. `call_remote`: the swing is already running here.
	if _is_local:
		_replay_swing.rpc()
	# DES-009: the wind-up is audible. Host-only, because noise is a
	# consequence and consequences have one owner.
	if multiplayer.is_server():
		clamor.add(Config.tuning.clamor_swing)


## Play a swing another peer's client began.
##
## Stamina was spent on their machine. Charging it again here would let the
## host refuse a swing that legitimately happened — and the host's copy is the
## one whose hitbox decides whether anything was hurt.
@rpc("any_peer", "call_remote", "reliable")
func _replay_swing() -> void:
	# Only the peer playing this body may swing it. Not anti-cheat — `TEC-004`
	# is explicit that co-op cheating mostly harms the cheater — but a mis-
	# addressed RPC animating the wrong body is a bug that would take a day to
	# find and one line to reject.
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	weapon.begin_owned_swing()


func _on_swing_connected(_hurtbox_hit: Hurtbox) -> void:
	# DES-009: blunt weapons are loudest, and connecting is the loud part. This
	# is the main combat-to-pressure coupling — a whiff is cheap, a fight is not.
	# Reached only on the host, for the same reason `_on_hurt` is.
	clamor.add(Config.tuning.clamor_hit)


## A blow arrives, and the guard is the only thing between it and you.
##
## **Host-side, and that is what makes the block real.** `TEC-004` gives
## consequences one owner, so this runs on the host for every body — reading the
## replicated `blocking` rather than the local input, which is why the flag has
## to cross the wire at all.
##
## `DES-009`: *"Block with weapon or shield, costs stamina, reduces damage,
## doesn't negate it."* All three clauses are here, and the third is the one
## that matters — `validate()` refuses a fraction of 1.0, because a guard that
## makes you invulnerable turns every fight into a holding contest and deletes
## the positional defence the rest of the model is built on.
##
## The stamina is spent **per blow, not per second.** A guard held through a
## quiet corridor costs nothing; a guard held into a fight empties you. That is
## the version where blocking is a decision about *this swing* rather than a
## stance you adopt on the way in.
func _on_hurt(amount: float, from: Node) -> void:
	if blocking and stamina.current >= Config.tuning.block_stamina_minimum:
		var tuning: TuningProfile = Config.tuning
		stamina.spend(tuning.block_stamina_cost)
		var through: float = amount * (1.0 - tuning.block_damage_fraction)
		blocked.emit(amount - through, from)
		health.apply_damage(through, from)
		return
	health.apply_damage(amount, from)


func _unhandled_input(event: InputEvent) -> void:
	# Only the owning peer processes input at all; `set_process_unhandled_input`
	# is switched off on every other copy in `_ready`.
	# Looking is suspended while the bag is open. You are looking at your bag —
	# that is the vulnerability `DES-019` is buying, and a player who can still
	# scan the room while rummaging is not paying for it.
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var tuning: TuningProfile = Config.tuning
		var limit: float = deg_to_rad(tuning.pitch_limit_degrees)
		# The tuned value is the baseline; the player's preference scales it, so
		# "default" always means the number the designer chose (`Settings`).
		var speed: float = tuning.mouse_sensitivity * Settings.look_scale()
		_yaw -= motion.relative.x * speed
		_pitch = clampf(_pitch - motion.relative.y * speed * Settings.pitch_sign(),
			-limit, limit)
		rotation.y = _yaw
		_head.rotation.x = _pitch
	# `ui_cancel` is **not** handled here. `PauseMenu` owns Escape and closes
	# the bag through `close_bag()` when it is open, because two
	# `_unhandled_input` handlers competing for one key resolve by tree order —
	# which is not a thing to rely on for the key that gets you out.
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if InputDevices.pointer_allowed() and not _bag_wanted:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("bag") and not is_incapacitated():
		_bag_wanted = not _bag_wanted
	elif event.is_action_pressed("drop") and not is_incapacitated():
		_ask_to_drop(false)
	elif event.is_action_pressed("throw") and not is_incapacitated():
		_ask_to_drop(true)
	elif event.is_action_pressed("use_waystone"):
		# On the floor, the same key is your one way back up (ADR-050). A
		# downed player has exactly one thing to spend and this is it, so it
		# does not need a binding of its own.
		if is_downed():
			ask_to_self_recover()
		else:
			ask_to_spend_waystone()
	elif event.is_action_pressed("interact") and _bag <= 0.0 and not is_incapacitated():
		_tell_host_reviving(true)
		# The Shaft first: standing in one and pressing interact means leaving,
		# not picking up whatever is also lying there. A player in the exit
		# reaching for their way home should never get a lump of bog iron.
		if not _reach_for_shaft():
			_reach_for_loot()
	elif event.is_action_released("interact"):
		_tell_host_reviving(false)
	elif event.is_action_pressed("debug_ink"):
		show_ink(not _ink.visible)


# ── loot ──────────────────────────────────────────────────────────────────
#
# `TEC-004` and ADR-082: **loot is host-authoritative and pickup is a
# host-validated request.** The client says only *"I am reaching for it"*; the
# host decides, using its own copy of where that client is standing.
#
# This is the room set's Prize logic, moved rather than copied (ADR-073). There
# is one loot path in the project and the level has none of it.


## Shut it, without toggling. `PauseMenu` calls this so one press of Escape
## closes the bag and a second one opens the menu.
##
## Reads `_bag_wanted` rather than `bag_is_open()`, which is about the *visual*
## transition and stays true for a moment after the bag has been told to shut —
## long enough that a second Escape would be swallowed by a bag already closing.
func wants_bag() -> bool:
	return _bag_wanted


func close_bag() -> void:
	_bag_wanted = false


## What this body would pick up right now, or null. Read by `Reticle`, which is
## the first thing that ever drew it — the value has existed since `M2-T01` and
## the player had no way to see it.
func reaching_for() -> WorldItem:
	return _reaching_for


## Whether this body is taking orders. `PauseMenu` turns it off while a menu is
## open — the world keeps running, so the consequence of opening one is that
## you stand still in it.
func set_driving(on: bool) -> void:
	_driving = on
	if not on:
		_bag_wanted = false


## The bag changed on whichever peer holds it.
func _on_inventory_changed() -> void:
	# Weight is host-owned and replicated (`STATE_PROPERTIES`). A client
	# writing it would be overwritten a twentieth of a second later and the bug
	# would read as "the weight is sometimes wrong".
	if multiplayer.is_server():
		carried.kilograms = inventory.total_weight()
		_push_bag()
	# Derived on every peer from the bag that peer holds, so no second
	# replicated property is needed and a client's debug ring cannot disagree
	# with the host's simulation about what this body gives away.
	# **Not party-scaled, deliberately** (`M2-T07`, ADR-096). The party
	# multiplier is on what people *do*, in `ClamorSource.add()`; a coin clinks
	# the same whoever you came with. Scaling a *floor* would put every party
	# above the hearing threshold permanently and delete `DES-005`'s "hide and
	# let it pass". `--scaling-probe` holds both halves of that line.
	# **Ballast** (`hrd_ballast`) cuts the standing noise of a full bag to
	# nothing; **Weight of Kings** doubles what is left, so the keystone taken
	# after it is loud again — deliberately, because `DES-004` requires every
	# keystone to have a real drawback and this one's is that the whole floor
	# hears the vault leaving.
	var floor_noise: float = 0.0 if has_effect(&"weight_is_silent") \
		else inventory.total_clamor() * Config.tuning.clamor_carried_fraction
	if has_effect(&"weight_costs_double"):
		floor_noise *= 2.0
	clamor.carried_floor = floor_noise


## Send the owning client its own bag. The whole bag, not a delta: it is a few
## dozen rows, it changes on pickup rather than per frame, and a full snapshot
## cannot drift the way an accumulated patch stream can.
func _push_bag() -> void:
	var owner_peer: int = get_multiplayer_authority()
	if owner_peer == HOST_PEER:
		return
	# **Not until they have asked** (ADR-102). `_ready` recomputes the bag, so
	# the host used to push it in the same frame the body was created — before
	# the spawn had been replicated, into a node path the client did not have
	# yet. Every join and every return through a door printed "Node not found
	# … Invalid packet received", twice, for a body that was about to exist.
	#
	# The client asks once its own copy is in the tree, which is the only
	# moment either side can be sure the other has it.
	if not _owner_ready_for_bag:
		return
	_receive_bag.rpc_id(owner_peer, inventory.pack())


## The owning client, reporting that its body exists and it can be spoken to.
@rpc("any_peer", "reliable")
func _ask_for_my_bag() -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	_owner_ready_for_bag = true
	_push_bag()


## `any_peer` with an explicit host check rather than `authority`: this node's
## multiplayer authority is the *client* playing it (ADR-082), so an
## `authority` RPC here would mean the opposite of what it reads as.
@rpc("any_peer", "reliable")
func _receive_bag(rows: Array) -> void:
	if multiplayer.get_remote_sender_id() != HOST_PEER:
		return
	inventory.unpack(rows)


## Highlight whatever the local player could take. Recomputed per frame rather
## than on an `Area3D` signal so the nearest item is always the one that gets
## taken, including when two are within reach of each other.
func _update_reach() -> void:
	var found: WorldItem = null
	# **Ready Hand** (`hrd_ready_hand`). `DES-019` makes rummaging a vulnerable
	# posture and this does not change that — you are still slow, still unable
	# to swing, still unable to sprint. What it buys is not having to shut the
	# bag to pick the next thing up.
	if _bag <= 0.0 or has_effect(&"take_with_bag_open"):
		found = WorldItem.nearest(self, global_position, Config.tuning.interact_reach)
	if found != _reaching_for and is_instance_valid(_reaching_for):
		_reaching_for.highlight(false)
	_reaching_for = found
	if found != null:
		found.highlight(true)


func _reach_for_loot() -> void:
	if _reaching_for == null or not is_instance_valid(_reaching_for):
		return
	reach_for(_reaching_for)


## Reach for one specific item. The client says only *this one*; the host
## decides whether they were close enough, using its own copy of where they
## are. Public because the probes drive it — through this path and not around
## it, so what they measure is what ships.
func reach_for(item: WorldItem) -> void:
	if item == null or not is_instance_valid(item):
		return
	var path: NodePath = item.get_path()
	if multiplayer.is_server():
		_take(path)
	else:
		_request_take.rpc_id(HOST_PEER, path)


@rpc("any_peer", "reliable")
func _request_take(path: NodePath) -> void:
	if not multiplayer.is_server():
		return
	# Only the peer playing this body may reach with it. Not anti-cheat —
	# `TEC-004` is explicit that co-op cheating mostly harms the cheater — but
	# a mis-addressed RPC filling the wrong player's bag is a bug that would
	# take a day to find and one line to reject.
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	_take(path)


## Host-side. Every refusal here is silent and that is correct: each one is a
## race the other peer already lost, not an error anyone can act on.
func _take(path: NodePath) -> void:
	# Gone means someone else got it first. Two players lunging for one item
	# therefore cannot both take it — the second request arrives to find the
	# node already freed, which is the same guarantee the Prize had.
	var item := get_node_or_null(path) as WorldItem
	if item == null:
		return
	var definition: ItemResource = item.definition()
	if definition == null:
		return
	var tuning: TuningProfile = Config.tuning
	var span: float = tuning.interact_reach + tuning.interact_reach_slack
	if global_position.distance_to(item.global_position) > span:
		return
	# A full bag refuses, and the item stays on the floor. Silently swallowing
	# something there was no room for would delete the spatial half of
	# `DES-019` the first time it mattered.
	var taken: ItemInstance = inventory.add(definition)
	if taken == null:
		return
	# Whose it is comes with it. For everything but an ember this is zero, and
	# for an ember it is the whole point — the bag now knows it is carrying
	# somebody (`DES-012`).
	taken.bound_to = item.bound()
	clamor.add(_handling_clamor(definition))
	# Pitched by how heavy the thing is, so a plate and a gemstone are not the
	# same event (`ART-002` — the player should hear what they are carrying).
	Foley.at(self, Foley.Sound.EMBER if taken.is_ember() else Foley.Sound.CLINK,
		lerpf(1.35, 0.75, clampf(definition.weight / 12.0, 0.0, 1.0)))
	item.queue_free()


## Ask to put something down. Bag open: whatever the cursor is on. Bag shut:
## **the heaviest thing you have** — the panic dump, and weight rather than
## value because `DES-005` Layer 1 puts the cost of greed in your legs, so that
## is the one whose removal you actually feel.
func _ask_to_drop(thrown: bool) -> void:
	var target: ItemInstance = null
	if _bag > 0.0:
		if _bag_screen != null:
			target = _bag_screen.hovered()
	elif thrown:
		# A throw reaches for the most *valuable* thing, not the heaviest. It is
		# a bait (`DES-017`), and what makes a bait work is what she would pay
		# for it — the Gullsjúkr is drawn by tribute, so throwing the mail
		# byrnie because it happens to be heavy would buy nothing at all.
		target = inventory.richest()
	else:
		target = inventory.heaviest()
	if target == null:
		return
	ask_to_drop_instance(target.instance_id, thrown)


## Put down one specific thing, or throw it. `BagScreen` calls this when an item
## is dragged out of the grid — the same gesture as setting something on a
## table, and the same path the panic dump takes.
func ask_to_drop_instance(instance_id: int, thrown: bool = false) -> void:
	if multiplayer.is_server():
		_put_down(instance_id, thrown)
	else:
		_request_drop.rpc_id(HOST_PEER, instance_id, thrown)


@rpc("any_peer", "reliable")
func _request_drop(instance_id: int, thrown: bool) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	_put_down(instance_id, thrown)


func _put_down(instance_id: int, thrown: bool) -> void:
	var item: ItemInstance = inventory.remove(instance_id)
	if item == null:
		return
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0:
		forward = forward.normalized()
	else:
		forward = Vector3.FORWARD
	# Setting something heavy down is as loud as lifting it. The bag's clamor
	# floor has already fallen by this point, which is the trade: one loud
	# moment buys lasting quiet, and that is the decision `DES-005` wants a
	# player cornered by the Hunt to have to make.
	clamor.add(_handling_clamor(item.definition))

	# **Sure Grip** (`hrd_sure_grip`). At your feet rather than a stride away,
	# which is the difference between stashing something behind a doorway and
	# watching it skid into the room you are backing out of.
	var reach: float = 0.0 if has_effect(&"drop_at_feet") else DROP_DISTANCE
	var at: Vector3 = global_position + forward * reach
	# Putting an ember down is allowed, and it is meant to be a decision you
	# can make. `DES-012` never says the rescuer is committed — the sacrifice is
	# real precisely because it can be abandoned partway home.
	var launch: Vector3 = Vector3.ZERO
	if thrown:
		# From the hand, not the feet, or the arc starts underground and the
		# first physics step buries it.
		at = global_position + Vector3(0.0, _head.position.y, 0.0) + forward * 0.4
		var tilt: float = deg_to_rad(THROW_LIFT_DEGREES)
		launch = (forward * cos(tilt) + Vector3.UP * sin(tilt)) * THROW_SPEED
	dropped.emit(item, at, rotation.y, launch)
	# A throw is lighter and sharper than setting something down; both are the
	# sound of your bag getting lighter, which `DES-005` wants to feel like
	# relief rather than loss.
	Foley.at(self, Foley.Sound.THUMP, 1.3 if thrown else 0.95)


## Ask to move something within the grid. Host-authoritative like everything
## else about the bag: arrangement changes no outcome, but a second writer to
## the same array costs a reconciliation rule to save about 60 ms of drag
## latency, and `M1-T05` already recorded why half-prediction is the wrong
## trade. If it feels laggy on a real link that is an M4 revision with data.
func ask_to_move(instance_id: int, to: Vector2i, rotated: bool) -> void:
	if multiplayer.is_server():
		_move_within_bag(instance_id, to, rotated)
	else:
		_request_move.rpc_id(HOST_PEER, instance_id, to, rotated)


@rpc("any_peer", "reliable")
func _request_move(instance_id: int, to: Vector2i, rotated: bool) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	_move_within_bag(instance_id, to, rotated)


func _move_within_bag(instance_id: int, to: Vector2i, rotated: bool) -> void:
	if not inventory.move(instance_id, to, rotated):
		return
	# Rummaging is audible. `DES-019` makes opening your bag a vulnerable act;
	# this is what stops it being a free one, and it is why sorting loot while
	# something approaches is the tension generator the doc says it is.
	clamor.add(Config.tuning.clamor_rummage)


# ── going down, and what a friend can do about it ────────────────────────
#
# `DES-012`'s three stages, and the reason they exist: ADR-004 wipes your LIFE
# on death, and in co-op you can die to a teammate's mistake. Unmitigated that
# is a friendship-ending mechanic. The answer converts the harshest rule in the
# game into **the most heroic thing a friend can do for you**.
#
#   1. **Downed** — zero health puts you on the floor, crawling, unable to
#      fight. A teammate can get you up at a real cost.
#   2. **Ember** — bleed out and you die *for the run*, and your ember drops
#      where you fell. It is heavy and it is loud.
#   3. **Carried out** — if it reaches an exit, your LIFE survives.
#
# The weight and the noise are the whole point: rescue has to be a **genuine
# sacrifice**, because a free revive is not a decision. That falls out for
# nothing here — the ember is an `ItemResource` and goes in the bag, so it
# costs the rescuer squares, kilograms and quiet exactly like loot does.


func is_downed() -> bool:
	return bleeding > 0.0 and not spent


## Down, dead, or otherwise not playing. Movement, the weapon and the bag all
## ask this rather than each testing three things and drifting apart.
func is_incapacitated() -> bool:
	return bleeding > 0.0 or spent


func _on_health_emptied(_from: Node) -> void:
	if not multiplayer.is_server():
		return
	_go_down()


func _go_down() -> void:
	if is_incapacitated():
		return
	bleeding = Config.tuning.bleed_out_seconds
	revival = 0.0
	# Whatever you were doing, you are not doing it. The bag shuts on its own —
	# `DES-019` makes rummaging a vulnerable act and being on the floor is not
	# the moment to be sorting loot.
	_bag_wanted = false
	_spending = 0.0
	leaving = 0.0


## Host-side, per frame. The window shortens whatever anyone is doing about it,
## because ADR-050 makes the shortening itself the decision: *"your ember is
## going out whether you choose or not, so the decision is forced by the
## fiction rather than by a UI timer."*
func _tick_bleeding(delta: float) -> void:
	if bleeding <= 0.0 or spent:
		return
	bleeding = maxf(0.0, bleeding - delta)
	if bleeding > 0.0:
		return
	# Nobody got here in time.
	spent = true
	revival = 0.0
	# Everything you were carrying stays with the body. `DES-012`: rescue saves
	# your LIFE, never your loot — *"you lose the run, your carried loot, and
	# take a Scar."*
	inventory.clear()
	died_here.emit(self, global_position)


## A hand on the shoulder. Called per frame while a teammate holds interact on
## a downed body; letting go stops it where it is rather than resetting, so a
## rescue interrupted by a swing can be resumed rather than restarted.
func revive_by(rescuer: Player, delta: float) -> void:
	if not multiplayer.is_server() or not is_downed():
		return
	if rescuer == self or rescuer.is_incapacitated():
		return
	revival += delta / maxf(Config.tuning.revive_seconds, 0.001)
	# Kneeling over someone is loud and it is *their* rescuer making the noise,
	# which is the exposure `DES-012` charges for a revive.
	rescuer.clamor.add(Config.tuning.revive_clamor * delta)
	if revival < 1.0:
		return
	_stand_up(Config.tuning.revive_health_fraction)


## Solo's single self-recovery (ADR-050) — *"once per run, costly, and never
## better than having a friend."*
##
## Costly two ways: it is gone for the rest of the run, and it returns less
## health than a friend's hand does. `DES-012` asks for a solo analogue so
## downing is not strictly worse alone, and is explicit that it must stay the
## worse option.
func ask_to_self_recover() -> void:
	if multiplayer.is_server():
		_self_recover()
	else:
		_request_self_recover.rpc_id(HOST_PEER)


@rpc("any_peer", "reliable")
func _request_self_recover() -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	_self_recover()


func _self_recover() -> void:
	if not is_downed() or not _self_recovery:
		return
	_self_recovery = false
	clamor.add(Config.tuning.revive_clamor)
	_stand_up(Config.tuning.self_recovery_health_fraction)


func has_self_recovery() -> bool:
	return _self_recovery


func _stand_up(fraction: float) -> void:
	bleeding = 0.0
	revival = 0.0
	health.revive(health.maximum * fraction)


## Host-side, per frame, on the *rescuer*. Whoever is holding interact next to
## a downed teammate is picking them up.
##
## Held rather than pressed, and that is `DES-012` being specific: a revive
## costs *"time, exposure, noise"*. A press would cost none of the three, and
## the whole reason the ember rescue is the emotional peak of a co-op session
## is that getting someone up is dangerous for you.
##
## The intent is read from the owning peer's input on the host's frame, which
## works because `interact` is already a held key rather than a tap for this
## one purpose. A client's held state arrives as part of nothing at all — so a
## remote rescuer sends it, and that is what `_reviving` carries.
func _offer_a_hand(delta: float) -> void:
	var holding: bool = _reviving
	if _is_local:
		holding = Input.is_action_pressed("interact") and _bag <= 0.0
	if not holding:
		return
	var reach: float = Config.tuning.interact_reach + Config.tuning.interact_reach_slack
	for node: Node in get_tree().get_nodes_in_group("player"):
		var fallen := node as Player
		if fallen == null or fallen == self or not fallen.is_downed():
			continue
		if global_position.distance_to(fallen.global_position) > reach:
			continue
		fallen.revive_by(self, delta)
		return


## A client telling the host it is holding interact. Sent on change rather than
## per frame: it is a held boolean, and one packet per press is the whole cost.
@rpc("any_peer", "reliable")
func _set_reviving(holding: bool) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	_reviving = holding


## Back on your feet for a fresh descent. Host-side, called by the level.
##
## Not a revive and not a heal: this is a *new run*, which is the one moment
## the design allows hit points to return to full (`DES-009` bans regeneration
## within a run, not between them). `DES-012`'s **Return** — walking back in
## with nothing, at the floor entrance, your ember extinguished — is what this
## becomes once `M3` gives a LIFE to lose, and it is absent rather than
## approximated in the meantime.
func restore_for_descent() -> void:
	if not multiplayer.is_server():
		return
	bleeding = 0.0
	revival = 0.0
	spent = false
	_spending = 0.0
	leaving = 0.0
	_reviving = false
	_self_recovery = true
	health.restore()


func _tell_host_reviving(holding: bool) -> void:
	if multiplayer.is_server():
		_reviving = holding
	else:
		_set_reviving.rpc_id(HOST_PEER, holding)


## Where the ember goes. Public because the level spawns it and the probe reads
## it, and because a body on the floor is exactly where `DES-012` says the
## ember drops.
func fell_at() -> Vector3:
	return global_position


## The body a peer is playing, on this process, or `null`.
##
## By group rather than by node path: the path depends on the session's node
## naming and this has to work from a `WorldItem` that knows only a peer id.
static func find_by_peer(from: Node, peer: int) -> Player:
	if peer == 0 or from.get_tree() == null:
		return null
	for node: Node in from.get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player != null and player.get_multiplayer_authority() == peer:
			return player
	return null


## The party seat a peer holds, or `-1` if that body is not here. Falls back to
## the peer id's low bits rather than guessing zero: two embers must never look
## identical because one owner happened to disconnect.
static func slot_for_peer(from: Node, peer: int) -> int:
	var player: Player = find_by_peer(from, peer)
	if player != null:
		return player.party_slot
	if peer == 0:
		return -1
	return peer % MAX_PARTY


# ── leaving ───────────────────────────────────────────────────────────────
#
# Two ways out, and ADR-015 makes them cost different things: the **Shaft** is
# always there and charges you time in a known place, the **Waystone** is loot
# you had to find and charges you the squares it occupied all run.


## The Shaft underfoot, or `null` (`M2-T14`, ADR-106).
##
## Read by the Reticle so the way out can announce itself. Until this existed
## the exit was the only interaction in the game with **no prompt of any kind**:
## you had to stand on an unmarked pad, press a key nothing suggested, and then
## hold position for four seconds with no progress shown anywhere. A playtester
## crossed the whole floor and reported that there was no way out — and on the
## evidence available to them, there wasn't.
func shaft_underfoot() -> Shaft:
	return Shaft.nearest(self, global_position)


## Start using whatever Shaft is underfoot. Public for the probes, which drive
## the shipping path rather than reaching past it.
func reach_for_shaft_now() -> bool:
	return _reach_for_shaft()


## True if a Shaft was reached for, so the caller knows not to grab loot too.
func _reach_for_shaft() -> bool:
	var shaft: Shaft = Shaft.nearest(self, global_position)
	if shaft == null:
		return false
	if multiplayer.is_server():
		shaft.begin(self)
	else:
		_request_shaft.rpc_id(HOST_PEER)
	return true


@rpc("any_peer", "reliable")
func _request_shaft() -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	# The host finds it from **its** copy of where this body is, which is the
	# whole point of the request being a request.
	var shaft: Shaft = Shaft.nearest(self, global_position)
	if shaft != null:
		shaft.begin(self)


## Spend the way home. `DES-005`: *"choosing to end the run now, with what you
## have"* — which is why it is deliberately not a confirmation dialog
## (`DES-019` refuses those) and deliberately not instantaneous either. It
## costs a moment you can be interrupted in.
func ask_to_spend_waystone() -> void:
	if multiplayer.is_server():
		_spend_waystone()
	else:
		_request_waystone.rpc_id(HOST_PEER)


@rpc("any_peer", "reliable")
func _request_waystone() -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	_spend_waystone()


func _spend_waystone() -> void:
	var stone: ItemInstance = inventory.waystone()
	if stone == null or _spending > 0.0:
		return
	_spending = _waystone_seconds(stone)
	_spending_total = _spending
	leaving = 0.0


func _waystone_seconds(stone: ItemInstance) -> float:
	for item_trait: ItemTrait in stone.definition.traits:
		var extraction := item_trait as ExtractionTrait
		if extraction != null:
			return maxf(extraction.channel_seconds, 0.01)
	return 0.01


## Host-side, per frame. Finishing consumes the stone and takes you out.
func _tick_waystone(delta: float) -> void:
	if _spending <= 0.0:
		return
	var stone: ItemInstance = inventory.waystone()
	if stone == null:
		_spending = 0.0
		leaving = 0.0
		return
	_spending -= delta
	leaving = clampf(1.0 - _spending / maxf(_spending_total, 0.001), 0.0, 1.0)
	if _spending > 0.0:
		return
	_spending = 0.0
	leaving = 0.0
	for item_trait: ItemTrait in stone.definition.traits:
		var extraction := item_trait as ExtractionTrait
		if extraction != null:
			clamor.add(extraction.clamor)
	# Consumed. It leaves the bag before extraction is announced, so what you
	# carried out never includes the thing that carried you.
	inventory.remove(stone.instance_id)
	extracted.emit(self)


## Noise made picking one thing up or setting it down: a fixed handling cost
## plus whatever the item itself gives away. An altar-plate coming off stone is
## most of the level's attention; a gemstone is nearly nothing.
func _handling_clamor(definition: ItemResource) -> float:
	# **Quiet Hands** (`hrd_quiet_hands`) silences all of it; **Coin-Sense**
	# (`hrd_coin_sense`) silences gold alone, which is the cheaper half of the
	# same idea and the node that leads to it.
	if has_effect(&"silent_handling"):
		return 0.0
	if has_effect(&"silent_gilt") and definition.tags.has(&"glitter"):
		return 0.0
	return Config.tuning.clamor_rummage + definition.clamor


## True while the bag is open at all — the weapon and the sprint both refuse.
func bag_is_open() -> bool:
	return _bag > 0.0


## Advance the open/shut transition and pay for it in mouse mode.
func _update_bag(delta: float) -> void:
	var goal: float = 1.0 if _bag_wanted else 0.0
	var step: float = delta / maxf(Config.tuning.bag_open_time, 0.001)
	# **Close the Lid** (`hrd_close_the_lid`). Opening still takes as long as it
	# ever did — `DES-019` charges for rummaging and this does not refund that.
	# What it removes is the tail: being caught half-shut on the way back out.
	if goal == 0.0 and has_effect(&"instant_bag_close"):
		step = 1.0
	var before: float = _bag
	_bag = move_toward(_bag, goal, step)
	if is_equal_approx(before, _bag):
		return
	if _bag_screen != null:
		_bag_screen.set_openness(_bag)
	if not InputDevices.pointer_allowed():
		return
	# The mouse is released as soon as the bag starts opening and recaptured
	# only once it is fully shut, so a half-open bag is never a state where
	# neither the cursor nor the camera answers to the mouse.
	if _bag > 0.0 and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif is_zero_approx(_bag) and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Put this body somewhere, whoever is playing it.
##
## The transform belongs to the owning peer, so the host cannot simply assign
## it — the next synchroniser packet would drag the body back. It has to ask
## the owner, which is the shape every future teleport has: extraction, gate
## arrival (ADR-016), and the gym's reset key.
## **Falling out of the world puts you back, in every level** (`M2-T15`,
## ADR-107).
##
## There were no world bounds and no recovery anywhere in this project. A
## playtester walked off the edge of the camp — which is a 34 m slab with walls
## on three sides — and fell, indefinitely, with nothing to stop them and no way
## back. The Deep and the Chamber had the same hole; the camp is simply where it
## is easiest to find.
##
## Recovering to the **last ground you actually stood on** rather than to a
## point the level nominates, because that needs no per-level configuration and
## so cannot be forgotten by the next level somebody builds. It is the standard
## treatment and it is nearly always invisible: you were somewhere solid a
## second ago, and that is where you turn up.
##
## **It is not a punishment.** Nothing is taken, because falling through a hole
## in a blockout is not a decision the player made and `DES-002`'s losses are
## meant to be legible ones. It does print, so a hole that keeps catching people
## shows up in a log rather than only in a shrug.
func _remember_solid_ground() -> void:
	if global_position.y < _last_solid.y - VOID_DROP:
		_return_from_the_void()
		return
	# Only while genuinely standing: mid-jump and mid-fall are exactly the
	# moments whose position must not be remembered as safe.
	if is_on_floor() and velocity.y <= 0.1:
		_last_solid = global_position


func _return_from_the_void() -> void:
	print("[void] %s fell out of the world at y %.0f — back to %.1f, %.1f" % [
		name, global_position.y, _last_solid.x, _last_solid.z])
	teleport(_last_solid + Vector3(0.0, 0.5, 0.0), _yaw)
	velocity = Vector3.ZERO


func teleport(to: Vector3, yaw: float) -> void:
	if _is_local:
		_apply_teleport(to, yaw)
		return
	# **There is nobody to ask if the owner has gone** (`M2-T16`, ADR-108).
	#
	# The host frees a departed peer's body in `_on_peer_disconnected`, but a
	# teleport issued inside that window addresses a peer the wire no longer
	# has — *"Attempt to call RPC with unknown peer ID"*. Same rule as
	# `_end_the_run`'s: a body can outlive its peer by a frame, and nothing is
	# owed to somebody who is not there. It prints, because a teleport that
	# quietly does nothing is otherwise indistinguishable from one that worked.
	var owner: int = get_multiplayer_authority()
	if not multiplayer.get_peers().has(owner):
		print("[net] %s belongs to peer %d, which is not connected — not moving it"
			% [name, owner])
		return
	_apply_teleport.rpc_id(owner, to, yaw)


@rpc("any_peer", "reliable")
func _apply_teleport(to: Vector3, yaw: float) -> void:
	# Only from the host, or from this process itself (sender 0).
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != HOST_PEER:
		return
	global_position = to
	velocity = Vector3.ZERO
	_yaw = yaw
	rotation.y = yaw
	_last_position = to
	_step_accumulator = 0.0
	# Wherever we have just been put is the new ground of record. Without this
	# the Chamber — 2000 m down — would be measured against a memory of the camp
	# and read as a 2000 m fall on the first frame you arrived (`M2-T15`).
	_last_solid = to


## The ink pass is a clip-space quad, so it fills whatever camera draws it —
## including cameras that are not this player's. A debug or spectator camera
## must be able to switch it off, or it composites over their view as well.
func show_ink(on: bool) -> void:
	_ink.visible = on


## Stick and arrow-key look (ADR-075).
##
## Rate-based, not delta-based: a mouse reports how far it moved, a stick
## reports how far it is *held*, and treating the second like the first gives
## the sluggish, floaty aim that makes people call controller support "added
## but unusable". Full deflection turns at a fixed rate in radians per second.
##
## The response curve matters as much as the rate. A linear stick is precise
## nowhere — too twitchy for fine aim, too slow for turning round — so small
## deflections are compressed and large ones are not.
func _apply_stick_look(delta: float, tuning: TuningProfile) -> void:
	# While the bag is open the right stick drives the bag's cell cursor instead
	# (`BagScreen`). Reusing the look actions rather than adding a pair is what
	# keeps ADR-075's parity honest without a second binding to maintain: every
	# bag function is reachable from either device, because the device already
	# had the input.
	if bag_is_open():
		return
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look.length_squared() <= 0.0:
		return
	var magnitude: float = minf(look.length(), 1.0)
	var shaped: Vector2 = look.normalized() * pow(magnitude, tuning.stick_look_curve)
	var limit: float = deg_to_rad(tuning.pitch_limit_degrees)
	_yaw -= shaped.x * tuning.stick_look_rate * delta
	_pitch = clampf(_pitch - shaped.y * tuning.stick_look_rate * delta, -limit, limit)
	rotation.y = _yaw
	_head.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	var tuning: TuningProfile = Config.tuning
	if _is_local:
		_remember_solid_ground()
		net_position = position
		net_yaw = _yaw
		net_pitch = _pitch
	else:
		_ease_toward_the_wire(delta)

	# The weapon runs on every peer. On the owner it is the swing they asked
	# for; on the host it is the swing whose hitbox decides damage; elsewhere
	# it is the reason a teammate is visibly swinging rather than gliding.
	#
	# A swing is refused outright while the bag is open. `DES-019` is explicit
	# that rummaging leaves you unable to fight well; a player who could still
	# swing at full strength with their bag open is not paying the cost the
	# no-pause design charges, and the tension it exists to create evaporates.
	if (_is_local and not bag_is_open() and not is_incapacitated()
			and Input.is_action_just_pressed("attack")):
		# One weapon in the hands (`M3-T11`). A body carrying a bow does not
		# also swing, which is `DES-011`'s *"poor in a straight fight"* written
		# as a missing verb rather than as a penalty — and it is why the bow
		# needs no button of its own.
		if ranged != null:
			ranged.request_draw(stamina)
		else:
			weapon.request_swing(stamina)
	weapon.advance(delta, stamina)
	if ranged != null:
		# Anything that takes your hands abandons the draw, on the same rule the
		# guard follows: the bag is a vulnerable act (`DES-019`) and being down
		# is not a state you shoot from.
		if _is_local and (bag_is_open() or is_incapacitated()):
			ranged.cancel()
		ranged.advance(delta)

	if _is_local:
		_update_bag(delta)
		_update_reach()
		_drive(delta, tuning)
	# A hand on a fallen teammate, held. Driven from the *rescuer's* frame on
	# the host, so it is the host that decides whether they are close enough and
	# the host that charges them the noise — same shape as every other
	# consequence (`TEC-004`).
	if multiplayer.is_server() and not is_incapacitated():
		_offer_a_hand(delta)

	# Noise is a consequence, so the host derives it for *every* body from the
	# motion it can see — its own directly, a client's from the transform that
	# just arrived. One authority, so the ring you draw and the ears that hear
	# you cannot disagree.
	if multiplayer.is_server():
		_emit_movement_clamor(delta, tuning)
		_tick_waystone(delta)
		_tick_bleeding(delta)


## Everything the owning peer simulates for itself. `TEC-004`: prediction for
## local movement, and nothing else predicted anywhere.
func _drive(delta: float, tuning: TuningProfile) -> void:
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta

	_apply_stick_look(delta, tuning)
	_update_stance(delta, tuning)

	var wish: Vector3 = _wish_direction()
	var sprinting: bool = _resolve_sprint(wish, delta, tuning)
	var speed: float = _target_speed(sprinting, tuning)
	var accel: float = _acceleration(tuning)

	# Horizontal movement only; gravity owns Y. Accelerating toward a target
	# velocity rather than assigning it is what gives the controller mass, and
	# it is the single knob DES-009's "grounded and physical" lives in.
	var target: Vector3 = wish * speed
	var planar: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = accel if wish != Vector3.ZERO else tuning.ground_friction
	if not is_on_floor():
		rate = tuning.air_acceleration
	planar = planar.move_toward(target, rate * delta)
	velocity.x = planar.x
	velocity.z = planar.z

	# Attacking does not root the player. DES-009 makes defence positional —
	# spacing, cover, doorways, retreat — with no dodge-roll and no i-frames,
	# so being unable to move during a swing would delete the only defence the
	# design gives. The swing itself commits; your feet do not.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not _crouching:
		# **Long Haul** (`hrd_long_haul`). Load costs you height everywhere else
		# in the game; here it stops costing you the ledge. Nothing about the
		# speed or the noise changes, so a loaded Hoard build still crosses a
		# floor slowly and loudly — it simply gets over things.
		var lift: float = 1.0 if has_effect(&"jump_at_any_load") \
			else carried.scale_by_load(tuning.jump_at_capacity)
		velocity.y = tuning.jump_velocity * lift

	move_and_slide()
	grounded = is_on_floor()


## Footfalls and landings, the continuous half of DES-005 Layer 1.
##
## Measured in distance walked rather than elapsed time, so sprinting is louder
## for two compounding reasons — more ground per second *and* a multiplier —
## while crouch-walking is quiet in both. Weight raises it further, which is the
## coupling the whole layer exists for: your greed is audible.
##
## `M1-T05` moved this to the host and to *displacement*, from the owner and
## from `velocity`. A remote body has no velocity here — nobody integrated one
## — but it has a position that moved, and how far you actually travelled is a
## better definition of a footstep than what you intended anyway.
func _emit_movement_clamor(delta: float, tuning: TuningProfile) -> void:
	var here: Vector3 = global_position
	var moved: Vector3 = here - _last_position
	_last_position = here
	moved.y = 0.0
	var distance: float = moved.length()

	var landed: bool = grounded and not _was_grounded
	_was_grounded = grounded
	if landed:
		# **Steady Step** (`hrd_steady_step`). The weight is still there; the
		# thump is not — which is what makes a drop down into a room a way in
		# rather than an announcement.
		var thump: float = 0.0 if has_effect(&"silent_landing") \
			else tuning.clamor_landing
		clamor.add(thump * carried.scale_by_load(
			tuning.clamor_footstep_at_capacity
		))
		_footfall(0.82)
		return
	if not grounded:
		return

	_step_accumulator += distance
	if _step_accumulator < tuning.clamor_step_distance:
		return
	_step_accumulator = 0.0
	var amount: float = tuning.clamor_footstep
	if stance > 0.5:
		amount *= tuning.clamor_crouch_multiplier
	elif _is_sprinting(distance / maxf(delta, 0.0001), tuning):
		amount *= tuning.clamor_sprint_multiplier
	clamor.add(amount * carried.scale_by_load(tuning.clamor_footstep_at_capacity))
	_footfall(1.0 if stance <= 0.5 else 1.22)


## **The sound of your own greed** (`ART-002`). A footfall drops in pitch and
## rises in level with what you are carrying, so a full bag *sounds* heavy on
## every single step rather than being a number on a bar.
##
## This is the cheapest version of the loop `ART-002` says the whole game rests
## on — *"if a player can close their eyes and hear how rich they are, this
## system works"* — and it costs two lines because `CarriedWeight` already
## knows the answer.
func _footfall(pitch: float) -> void:
	var load: float = carried.encumbrance()
	Foley.at(self, Foley.Sound.STEP, pitch * lerpf(1.0, 0.72, load),
		lerpf(-6.0, 1.0, load))


## Sprinting, as the host can see it: fast enough that walking does not explain
## it. The threshold sits midway between the two target speeds and carries the
## same load scaling they do, so a heavily laden sprint still reads as one.
func _is_sprinting(speed: float, tuning: TuningProfile) -> bool:
	var scale: float = carried.scale_by_load(tuning.speed_at_capacity)
	return speed > (tuning.walk_speed + tuning.sprint_speed) * 0.5 * scale


## Carry a remote body toward where the wire last said it was.
##
## Snapshot interpolation, and the rate is the thing that matters: cover the
## gap in roughly one replication interval, so the body is always about one
## packet behind and never waiting. Faster and it snaps — which is the jitter
## this exists to remove; slower and a teammate is somewhere they left.
##
## `move_toward` on the angles rather than `lerp_angle` alone, so a body
## turning through the wrap at ±180° takes the short way round instead of
## spinning the long way.
func _ease_toward_the_wire(delta: float) -> void:
	var rate: float = clampf(delta * REPLICATION_HZ, 0.0, 1.0)
	position = position.lerp(net_position, rate)
	_yaw = lerp_angle(_yaw, net_yaw, rate)
	_pitch = lerp_angle(_pitch, net_pitch, rate)
	rotation.y = _yaw
	_head.rotation.x = _pitch


func _wish_direction() -> Vector3:
	# Hands off the controls while a menu is up. The world does **not** pause
	# (`PauseMenu`), so this is not safety — it is the opposite: you stopped
	# driving, and the Deep did not stop with you.
	if not _driving:
		return Vector3.ZERO
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input.x, 0.0, input.y))
	direction.y = 0.0
	return direction.normalized() if direction.length_squared() > 0.0 else Vector3.ZERO


func _resolve_sprint(wish: Vector3, delta: float, tuning: TuningProfile) -> bool:
	# No sprinting with your bag open, at any openness. Not a balance number:
	# you have both hands in a satchel. Nor on the floor, for reasons that need
	# no explanation.
	if bag_is_open() or is_incapacitated():
		return false
	if _crouching or wish == Vector3.ZERO or not Input.is_action_pressed("sprint"):
		return false
	# The minimum stops a one-step sprint stutter at the bottom of the bar.
	if stamina.is_empty() or (stamina.current < tuning.sprint_minimum
			and not Input.is_action_just_pressed("sprint")):
		return false
	var drain: float = tuning.sprint_drain * carried.scale_by_load(
		tuning.stamina_drain_at_capacity
	)
	return stamina.drain(drain, delta)


func _target_speed(sprinting: bool, tuning: TuningProfile) -> float:
	var base: float = tuning.walk_speed
	if _crouching:
		base = tuning.crouch_speed
	elif sprinting:
		base = tuning.sprint_speed
	# Crawling. `DES-012`: down means *"crawling, bleeding, unable to fight"* —
	# you can still move, and you cannot get anywhere, which is what makes
	# whether a friend comes for you *their* decision rather than yours.
	if is_downed():
		return tuning.walk_speed * tuning.downed_speed_fraction
	# Planted is planted (`M3-T02`). Nothing about the doorway works if the
	# thing in it can be walked out of.
	if planted > 0.0:
		return 0.0
	if spent:
		return 0.0
	# Two multipliers, and they compound on purpose. Load is `DES-005` Layer 1 —
	# greed in your legs. The bag term is `DES-019`'s vulnerable act, scaled by
	# how far open it is so the penalty arrives with the screen rather than
	# ahead of it.
	# A third multiplier, on the same principle: a guard slows you but never
	# roots you. `DES-009` makes movement the primary defence — *"no dodge-roll,
	# no i-frames, defense is positional"* — so a block that took your feet away
	# would be trading the better defence for the worse one.
	var body: ClassResource = ClassCatalogue.by_id(sworn)
	var of_class: float = body.speed_scale if body else 1.0
	return (base * of_class * carried.scale_by_load(tuning.speed_at_capacity)
		* lerpf(1.0, tuning.bag_speed_multiplier, _bag)
		* (tuning.block_speed_multiplier if blocking else 1.0))


func _acceleration(tuning: TuningProfile) -> float:
	return tuning.ground_acceleration * carried.scale_by_load(
		tuning.acceleration_at_capacity
	)


func _update_stance(delta: float, tuning: TuningProfile) -> void:
	# Hold and toggle, both live, because they suit different hands and neither
	# is correct for everyone: hold reads better for a quick peek, toggle for
	# the long quiet approach DES-005 Layer 1 actually rewards — and holding a
	# key for a two-minute crouched crossing is a genuine accessibility cost
	# (DES-018). The toggle is the latch; hold ORs on top of it, so releasing
	# ctrl never cancels a crouch you toggled on.
	if Input.is_action_just_pressed("crouch_toggle"):
		_crouch_latched = not _crouch_latched
	var wants_crouch: bool = _crouch_latched or Input.is_action_pressed("crouch")
	if _crouching and not wants_crouch and _blocked_above(tuning):
		wants_crouch = true  # something overhead; stay down
	_crouching = wants_crouch

	var goal: float = 1.0 if _crouching else 0.0
	var step: float = delta / maxf(tuning.crouch_time, 0.001)
	stance = move_toward(stance, goal, step)

	# **A guard you cannot raise is not a guard that flickers** (`M3-T02`).
	# Below the minimum the button does nothing at all, which is `sprint_minimum`'s
	# rule and for the same reason: a shield blinking on and off at empty
	# stamina is unreadable, and unreadable defence is `PRO-005` §5's
	# unexplainable death waiting to happen. Not while rummaging, not while
	# down — both are already states in which your hands are full of something
	# else. The bag is the interesting one, because `DES-019` sells opening it
	# as a vulnerable act and a guard you could hold through it would refund
	# exactly the vulnerability being paid for.
	_hold(delta, tuning)
	_snare(delta, tuning)
	blocking = (Input.is_action_pressed("block")
		and stamina.current >= tuning.block_stamina_minimum
		and _bag <= 0.0
		and not is_incapacitated())


## Collider, silhouette and eye height, from one number.
##
## Runs on every peer, driven by the replicated `stance`, so a crouched
## teammate is short everywhere — including in the host's hit detection, which
## is the copy that decides whether a swing over their head connected.
func _apply_stance() -> void:
	var tuning: TuningProfile = Config.tuning
	var height: float = lerpf(tuning.stand_height, tuning.crouch_height, stance)
	_capsule.height = height
	_body_mesh.height = height
	# Godot centres a capsule on its origin, so the collider rides at half
	# height to keep the feet at y = 0.
	_collider.position.y = height * 0.5
	_body.position.y = height * 0.5
	_head.position.y = height - tuning.eye_drop


func _blocked_above(tuning: TuningProfile) -> bool:
	var rise: float = tuning.stand_height - tuning.crouch_height
	return test_move(global_transform, Vector3.UP * rise)


## Metres per second on the horizontal plane — for the debug readout, which
## only ever reads the body this process is playing.
func planar_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()


## The collider's current height. Read by the co-op probe, which asserts that
## two players in one process have *different* ones while one of them is
## crouched — the scene's capsule is a sub-resource, and a shared sub-resource
## would give both bodies the same number and nobody a reason to look.
func capsule_height() -> float:
	return _capsule.height


## **Hold** (`M3-T02`, `DES-011`) — the Húskarl's verb, and only theirs.
##
## *"Plant and become an immovable object. Nothing pushes past you. Allies can
## retreat through you."*
##
## Three things, and each is one line because the systems were already there:
##
## - **Immovable** is `_speed()` returning nothing while planted. Not a physics
##   change, not a new movement state — you simply cannot walk, which is what
##   makes it a *decision to stop* rather than a stance you drift into.
## - **Nothing pushes past you** is `CollisionLayers.BULWARK`. Enemies mask it,
##   players do not, so the same layer that makes you a wall makes you thin air
##   to your own party. There is no "except teammates" rule to get wrong.
## - **A real cost** (`DES-011`'s rule for every unique verb) is stamina per
##   second. Not per blow: the clock runs while you are the only thing in the
##   doorway, whether or not anything comes.
##
## Planting **takes `hold_plant_seconds`** and unplanting is immediate. That
## asymmetry is the commitment: `DES-009` refuses reflex-timed defence, so this
## is a thing you decide to do a beat before you need it, and an ally has time
## to read that you have done it.
func _hold(delta: float, tuning: TuningProfile) -> void:
	# Only a class with the verb has the verb. `DES-011`: identity comes from
	# the verb, not the stat line — so this is the line that makes a Húskarl
	# recognisable from ten seconds of watching, and it is gated on nothing but
	# whether you are one.
	var body: ClassResource = ClassCatalogue.by_id(sworn)
	var wants: bool = (body != null and body.verb == &"hold"
		and Input.is_action_pressed("verb")
		and not is_incapacitated()
		and _bag <= 0.0
		and stamina.current > 0.0)
	var step: float = delta / maxf(tuning.hold_plant_seconds, 0.001)
	planted = minf(planted + step, 1.0) if wants else 0.0
	if planted > 0.0:
		stamina.spend(tuning.hold_stamina_drain * delta)
	_apply_bulwark()


## **The class kit is what puts a bow in the hand** (`M3-T11`, ADR-123).
##
## `ClassResource.kit` already names real catalogue ids, so a designer arms a
## class by editing a `.tres` and nothing here knows what a Veiðimaðr is — which
## is `CLAUDE.md`'s data-over-code rule applied to a weapon rather than to a
## stat. `M3-T07` re-points this at an equipment slot when slots exist; it moves
## the seam rather than growing a second one beside it.
##
## Runs on **every** peer from the replicated `sworn`, for the reason the body
## scales above it do: the host builds four bodies and three of them belong to
## somebody else, so a bow read out of local state would arm the wrong people.
## Does this body have that rule? The one question any system asks the tree.
func has_effect(tag: StringName) -> bool:
	return effects.has(String(tag))


func _arm_from_kit(body: ClassResource) -> void:
	if body == null:
		return
	var kit: RangedTrait = null
	for id: StringName in body.kit:
		var definition: ItemResource = ItemCatalogue.by_id(id)
		if definition == null:
			continue
		var found: ItemTrait = definition.first_trait(RangedTrait)
		if found != null:
			kit = found as RangedTrait
			break
	if kit == null:
		return
	ranged = RangedWeapon.new()
	ranged.name = "Bow"
	_head.add_child(ranged)
	ranged.equip(kit)
	ranged.draw_started.connect(_on_draw_started)
	ranged.loosed.connect(_on_loosed)
	# The blade goes away rather than being carried and never used. A visible
	# weapon that cannot be swung is the most direct kind of lie a blockout can
	# tell a playtester (ADR-064).
	weapon.visible = false


func _on_draw_started() -> void:
	# Same shape as `_on_swing_started`: the other peers play a draw this client
	# has already committed to and paid for.
	if _is_local:
		_replay_draw.rpc()


## Play a draw another peer's client began. `_replay_swing`'s argument applies
## unchanged, including why it does not consult stamina.
@rpc("any_peer", "call_remote", "reliable")
func _replay_draw() -> void:
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	if ranged != null:
		ranged.begin_owned_draw()


## The string is released. Runs on every peer because every peer ran the phase
## machine, and **only the owner's copy is worth listening to** — the aim is the
## shooter's, and a remote copy's is a replicated approximation arriving a frame
## behind the decision.
func _on_loosed() -> void:
	if not _is_local:
		return
	var aim: Vector3 = -_camera.global_transform.basis.z
	if multiplayer.is_server():
		_loose_arrow(aim)
	else:
		_loose_arrow.rpc_id(HOST_PEER, aim)


## The host makes the arrow (`TEC-004`: consequences have one owner).
##
## **Direction from the shooter, origin from the host's own copy of them.** The
## aim is a decision and belongs to whoever made it; where the body *is* is the
## host's answer already — the same copy whose hurtbox decides what a blow did —
## so taking the origin from anywhere else would let an arrow leave from a place
## the host does not think anybody is standing.
@rpc("any_peer", "call_local", "reliable")
func _loose_arrow(aim: Vector3) -> void:
	if not multiplayer.is_server():
		return
	var from: int = multiplayer.get_remote_sender_id()
	if from == 0:
		from = multiplayer.get_unique_id()
	if from != get_multiplayer_authority():
		return
	if ranged == null or aim.length() < 0.5:
		return
	var travel: Vector3 = aim.normalized()
	loosed_arrow.emit(_head.global_position + travel * 0.5, travel,
		ranged.kit(), from)
	# What the archer pays, and it is deliberately small. The loud half happens
	# where the arrow lands (`Arrow._land`), which is the whole tactic.
	clamor.add(ranged.kit().clamor_loose)


## **Snare** (`M3-T11`, `DES-011`) — the Veiðimaðr's verb, and only theirs.
##
## > *"Place traps that hold, wound, or misdirect — including against the
## > Hunter, the only reliable way to buy time during the Sealing."*
##
## Held rather than tapped, and it takes `snare_place_seconds`, for the reason
## the Húskarl's plant takes time: `DES-009` refuses reflex-timed play, so this
## is a thing you decide to do a beat before you need it. Releasing early
## abandons it and costs nothing — the stamina is spent when the trap exists,
## not when you start thinking about it.
##
## It goes at your feet. Not ahead of you, which would need an aim and a preview
## and a rule about walls; at your feet is somewhere you have just proved you
## can stand, and *"set it and back away through it"* is a legible gesture with
## nothing to learn.
func _snare(delta: float, tuning: TuningProfile) -> void:
	var body: ClassResource = ClassCatalogue.by_id(sworn)
	var wants: bool = (body != null and body.verb == &"snare"
		and Input.is_action_pressed("verb")
		and not is_incapacitated()
		and _bag <= 0.0
		and stamina.current >= tuning.snare_stamina_cost)
	if not wants:
		_setting = 0.0
		return
	_setting += delta / maxf(tuning.snare_place_seconds, 0.001)
	if _setting < 1.0:
		return
	_setting = 0.0
	if not stamina.spend(tuning.snare_stamina_cost):
		return
	if multiplayer.is_server():
		_place_snare(global_position)
	else:
		_place_snare.rpc_id(HOST_PEER, global_position)


## The host is told a trap was set. It does not set it — `CoopSession` does,
## including clearing the one this peer already had, because the session owns
## every spawned actor and *one live at a time* is a fact about the world rather
## than about this body.
@rpc("any_peer", "call_local", "reliable")
func _place_snare(at: Vector3) -> void:
	if not multiplayer.is_server():
		return
	var from: int = multiplayer.get_remote_sender_id()
	if from == 0:
		from = multiplayer.get_unique_id()
	if from != get_multiplayer_authority():
		return
	set_snare.emit(at, from)


## The layer, applied wherever the body is — owner or remote copy — because the
## host's enemies collide against *its* copy and a client's against theirs.
## Driven by the replicated `planted`, exactly as `_apply_stance` is driven by
## the replicated `stance`, and for the same reason: a body whose collider
## disagrees with its silhouette is `PRO-005` §5's unexplainable death.
func _apply_bulwark() -> void:
	var wall: bool = planted >= 1.0
	var has: bool = (collision_layer & CollisionLayers.BULWARK) != 0
	if wall == has:
		return
	if wall:
		collision_layer |= CollisionLayers.BULWARK
	else:
		collision_layer &= ~CollisionLayers.BULWARK
