@tool
extends EditorScenePostImport

## ART-006 uses COLOR_0 as ink metadata, not as albedo. Godot's standard glTF
## importer enables vertex tint on coloured surfaces; that turns stone yellow
## and changes each material family according to its B identifier. Preserve
## the mesh data for the ink pass while keeping the authored flat palette.
func _post_import(scene: Node) -> Object:
	_prepare(scene)
	return scene


func _prepare(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for surface: int in range(instance.mesh.get_surface_count()):
				var material := instance.mesh.surface_get_material(surface) as BaseMaterial3D
				if material != null:
					material.vertex_color_use_as_albedo = false
	for child: Node in node.get_children():
		_prepare(child)
