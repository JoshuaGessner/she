class_name PackTrait
extends ItemTrait

## A bag, as equipment (`M3-T07`, `DES-020`, `DES-019`).
##
## > *"Your bag is equipment, and it is the most interesting armour slot in the
## > game. Bigger pack → more grid → more weight → more Clamor. **The upgrade
## > that makes you more powerful is the upgrade that makes you louder.**"*
##
## That is Pillar P1 as a piece of gear, and it is why this is a trait rather
## than a number on the class: the pack is a thing you find, lose and choose,
## and `DES-008` makes it a sidegrade — a bigger frame is not a better frame,
## it is a louder one.
##
## It carries **no capacity in kilograms.** `DES-019` is explicit that space and
## weight are two different constraints, and a pack that raised both would
## collapse them into one instrument again.

## Cells wide and tall. Read by `Equipment.grid_size()`; with no pack at all you
## get `TuningProfile.inventory_grid`, which `DES-019` Q106 always described as
## the *no pack* grid rather than the only one.
@export var grid: Vector2i = Vector2i(6, 5)


func kind() -> String:
	return "pack"


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if grid.x < 1 or grid.y < 1:
		problems.append("a pack with a %s grid holds nothing" % grid)
	return problems
