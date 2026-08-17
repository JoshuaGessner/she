extends Node

## `Config` — the first autoload, created at M1-T01 because it now has real
## work (ADR-066: autoloads are created when they have work, not registered in
## advance against a budget).
##
## Its whole job is that no tunable number lives in code. TEC-001 makes this a
## rule rather than a preference, because balance iteration happens hundreds of
## times and recompiling to change a timer is how projects stall.
##
## No `class_name`: an autoload is reached through its singleton name, and a
## matching global class would shadow it.

const PROFILE_PATH: String = "res://data/tuning/default_tuning.tres"

var tuning: TuningProfile


func _ready() -> void:
	tuning = load(PROFILE_PATH) as TuningProfile
	if tuning == null:
		# Loud and immediate. No default-constructed fallback: a silently
		# invented profile would make every number in the game a lie, and a
		# second source of tuning values is the parallel path ADR-064 bans.
		push_error("Config: %s is missing or is not a TuningProfile" % PROFILE_PATH)
		return
	# A tuning value that breaks a documented hard rule must fail at boot, not
	# produce a subtly unfair game. See TuningProfile.validate().
	for problem: String in tuning.validate():
		push_error("Config: %s" % problem)
	# Player preferences, as opposed to design tuning. Loaded here because this
	# is the autoload that already owns "read the numbers at boot", and applied
	# immediately so the first frame honours them.
	Settings.load_once()
	if OS.get_cmdline_user_args().has("--export-probe"):
		_export_probe()


## **The packed-content census** (ADR-086, rehomed by ADR-099).
##
## `en.en.translation` is gitignored and rebuilt by the importer, and every
## `.tres` is re-serialised on export. So a build can boot perfectly, at full
## size, and still ship an empty item table with every item called
## `item.wpn_seax.name` — silently, because nothing in the running game reads
## either yet. This is the check that would notice, and it has to run *inside*
## the exported binary, which is the only place the question can be asked.
##
## **It lives in an autoload because it stopped running when it lived in a
## level.** ADR-086 put it in the movement gym, which was the main scene; nine
## commits later ADR-095 made the Threshold the main scene and the census
## became unreachable — a check that quietly stops running, which is the exact
## failure ADR-095's own text warns about while fixing the *other* place it had
## happened. Naming the gym explicitly would have fixed this instance and left
## the shape intact. An autoload runs whatever boots, so there is no main scene
## anyone can choose that strands it again.
##
## Nothing here is about the Config's own job. It is here because this is the
## thing that always runs, and a census of the pack has no natural level.
func _export_probe() -> void:
	# Through `ItemCatalogue`, which is what the running game asks (the ADR-073
	# rule — one authority, not a second copy that walks the folder its own way
	# and stops being a census of what the game can actually see).
	var items: Array[ItemResource] = ItemCatalogue.all()

	print("[export] engine        %s" % Engine.get_version_info()["string"])
	print("[export] items packed  %d" % items.size())
	print("[export] tuning loaded %s" % (tuning != null))
	# The translation, read the way the game reads it. A key coming back
	# unchanged means the table did not ship.
	print("[export] translation   'item.wpn_seax.name' -> '%s'"
		% tr("item.wpn_seax.name"))
	print("[export] probe complete")
	get_tree().quit()
