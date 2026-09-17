class_name InkStyle
extends ShaderMaterial

## A shader material is still designer data. Validate its authored parameters
## in the same corpus sweep as gameplay Resources, before a bad value can make
## every surface unreadable.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if shader == null:
		problems.append("ink style has no shader")
		return problems
	for parameter: String in ["hatch_scale", "hatch_strength", "hatch_width"]:
		var value: Variant = get_shader_parameter(parameter)
		if not (value is float or value is int) or not is_finite(float(value)):
			problems.append("%s must be a finite number" % parameter)
			continue
		var number: float = float(value)
		if parameter == "hatch_scale" and number <= 0.0:
			problems.append("hatch_scale must be positive")
		elif parameter == "hatch_strength" and (number < 0.0 or number > 1.0):
			problems.append("hatch_strength must lie between zero and one")
		elif parameter == "hatch_width" and (number <= 0.0 or number >= 0.5):
			problems.append("hatch_width must leave a gap between strokes")
	return problems
