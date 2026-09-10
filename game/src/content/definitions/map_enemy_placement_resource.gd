class_name MapEnemyPlacementResource
extends Resource

@export var instance_id: StringName = &""
@export var profile_id: StringName = &""
@export var cell: Vector3i = Vector3i.ZERO


static func snapshot(source: MapEnemyPlacementResource) -> MapEnemyPlacementResource:
	var result := MapEnemyPlacementResource.new()
	result.instance_id = source.instance_id
	result.profile_id = source.profile_id
	result.cell = source.cell
	return result
