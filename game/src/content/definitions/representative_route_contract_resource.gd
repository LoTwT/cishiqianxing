class_name RepresentativeRouteContractResource
extends Resource

@export var contract_id: StringName = &""
@export var stage_start_chapter: int = 0
@export var stage_end_chapter: int = 0
@export var player_profile_id: StringName = &""
@export var mainline_progression_reference_ids: Array[StringName] = []
@export var available_blueprint_reference_ids: Array[StringName] = []
@export var backpack_slot_capacity: int = 0
@export var encounter_group_minimum: int = 0
@export var encounter_group_maximum: int = 0
@export var encounter_group_hard_cap: int = 0
@export var low_loss_contact_minimum: int = 0
@export var low_loss_contact_maximum: int = 0
@export var intuitive_contact_minimum: int = 0
@export var intuitive_contact_maximum: int = 0
@export var low_loss_minimum_exit_health_percent: int = 0
@export var intuitive_minimum_exit_health_percent: int = 0
@export var minimum_fixed_recovery_points: int = 0
@export var fixed_recovery_amount: int = 0
@export var minimum_legal_route_count: int = 0
@export var minimum_legal_loadout_count: int = 0
@export var tradeoff_dimension_ids: Array[StringName] = []
@export var minimum_distinct_tradeoff_dimensions: int = 0
@export var requires_non_dominated_route_set: bool = false


static func snapshot(
	source: RepresentativeRouteContractResource,
) -> RepresentativeRouteContractResource:
	var copied_contract := RepresentativeRouteContractResource.new()
	copied_contract.contract_id = source.contract_id
	copied_contract.stage_start_chapter = source.stage_start_chapter
	copied_contract.stage_end_chapter = source.stage_end_chapter
	copied_contract.player_profile_id = source.player_profile_id
	for content_id: StringName in source.mainline_progression_reference_ids:
		copied_contract.mainline_progression_reference_ids.append(content_id)
	for content_id: StringName in source.available_blueprint_reference_ids:
		copied_contract.available_blueprint_reference_ids.append(content_id)
	copied_contract.backpack_slot_capacity = source.backpack_slot_capacity
	copied_contract.encounter_group_minimum = source.encounter_group_minimum
	copied_contract.encounter_group_maximum = source.encounter_group_maximum
	copied_contract.encounter_group_hard_cap = source.encounter_group_hard_cap
	copied_contract.low_loss_contact_minimum = source.low_loss_contact_minimum
	copied_contract.low_loss_contact_maximum = source.low_loss_contact_maximum
	copied_contract.intuitive_contact_minimum = source.intuitive_contact_minimum
	copied_contract.intuitive_contact_maximum = source.intuitive_contact_maximum
	copied_contract.low_loss_minimum_exit_health_percent = (
		source.low_loss_minimum_exit_health_percent
	)
	copied_contract.intuitive_minimum_exit_health_percent = (
		source.intuitive_minimum_exit_health_percent
	)
	copied_contract.minimum_fixed_recovery_points = (
		source.minimum_fixed_recovery_points
	)
	copied_contract.fixed_recovery_amount = source.fixed_recovery_amount
	copied_contract.minimum_legal_route_count = source.minimum_legal_route_count
	copied_contract.minimum_legal_loadout_count = source.minimum_legal_loadout_count
	for dimension_id: StringName in source.tradeoff_dimension_ids:
		copied_contract.tradeoff_dimension_ids.append(dimension_id)
	copied_contract.minimum_distinct_tradeoff_dimensions = (
		source.minimum_distinct_tradeoff_dimensions
	)
	copied_contract.requires_non_dominated_route_set = (
		source.requires_non_dominated_route_set
	)
	return copied_contract


func is_equal_to(other: RepresentativeRouteContractResource) -> bool:
	return (
		other != null
		and other.contract_id == contract_id
		and other.stage_start_chapter == stage_start_chapter
		and other.stage_end_chapter == stage_end_chapter
		and other.player_profile_id == player_profile_id
		and (
			other.mainline_progression_reference_ids
			== mainline_progression_reference_ids
		)
		and (
			other.available_blueprint_reference_ids
			== available_blueprint_reference_ids
		)
		and other.backpack_slot_capacity == backpack_slot_capacity
		and other.encounter_group_minimum == encounter_group_minimum
		and other.encounter_group_maximum == encounter_group_maximum
		and other.encounter_group_hard_cap == encounter_group_hard_cap
		and other.low_loss_contact_minimum == low_loss_contact_minimum
		and other.low_loss_contact_maximum == low_loss_contact_maximum
		and other.intuitive_contact_minimum == intuitive_contact_minimum
		and other.intuitive_contact_maximum == intuitive_contact_maximum
		and (
			other.low_loss_minimum_exit_health_percent
			== low_loss_minimum_exit_health_percent
		)
		and (
			other.intuitive_minimum_exit_health_percent
			== intuitive_minimum_exit_health_percent
		)
		and (
			other.minimum_fixed_recovery_points
			== minimum_fixed_recovery_points
		)
		and other.fixed_recovery_amount == fixed_recovery_amount
		and other.minimum_legal_route_count == minimum_legal_route_count
		and other.minimum_legal_loadout_count == minimum_legal_loadout_count
		and other.tradeoff_dimension_ids == tradeoff_dimension_ids
		and (
			other.minimum_distinct_tradeoff_dimensions
			== minimum_distinct_tradeoff_dimensions
		)
		and (
			other.requires_non_dominated_route_set
			== requires_non_dominated_route_set
		)
	)
