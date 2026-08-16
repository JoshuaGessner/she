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
