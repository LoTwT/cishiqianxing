extends RefCounted

const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")
const PRIMARY_ACTOR_ID := &"actor.loer"
const SECONDARY_ACTOR_ID := &"actor.aria"
const DEFAULT_ACTOR_POSITION := Vector3i(1, 0, 1)
const SECONDARY_ACTOR_POSITION := Vector3i(1, 0, 0)
const BLOCKED_CELL := Vector3i(2, 0, 1)


static func create_state(
	actor_position: Vector3i = DEFAULT_ACTOR_POSITION,
	include_secondary_actor: bool = false,
	world_step: int = 0,
) -> GridRuleStateScript:
	var grid_cells: Array[Vector3i] = []
	for z: int in range(3):
		for x: int in range(3):
			grid_cells.append(Vector3i(x, 0, z))

	var blocked_cells: Array[Vector3i] = [BLOCKED_CELL]
	var actor_positions: Dictionary[StringName, Vector3i] = {
		PRIMARY_ACTOR_ID: actor_position,
	}
	if include_secondary_actor:
		actor_positions[SECONDARY_ACTOR_ID] = SECONDARY_ACTOR_POSITION

	return GridRuleStateScript.create(
		grid_cells,
		blocked_cells,
		actor_positions,
		world_step,
	)
