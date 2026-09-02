class_name RepresentativeRouteQueryResult
extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const PlayerStatProfileScript := preload(
	"res://src/content/definitions/player_stat_profile_resource.gd"
)
const RepresentativeRouteContractScript := preload(
	"res://src/content/definitions/representative_route_contract_resource.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)

var _contract: RepresentativeRouteContractScript
var _stage_end_minimum_player_stats: PlayerStatProfileScript
var _stage_end_available_blueprints: Array[BlueprintDefinitionScript] = []
var _issue: ContentValidationIssueScript


func _init(
	contract: RepresentativeRouteContractScript,
	stage_end_minimum_player_stats: PlayerStatProfileScript,
	stage_end_available_blueprints: Array[BlueprintDefinitionScript],
	issue: ContentValidationIssueScript,
) -> void:
	if contract != null:
		_contract = RepresentativeRouteContractScript.snapshot(contract)
	if stage_end_minimum_player_stats != null:
		_stage_end_minimum_player_stats = PlayerStatProfileScript.snapshot(
			stage_end_minimum_player_stats
		)
	for blueprint: BlueprintDefinitionScript in stage_end_available_blueprints:
		_stage_end_available_blueprints.append(
			BlueprintDefinitionScript.snapshot(blueprint)
		)
	_stage_end_available_blueprints.make_read_only()
	if issue != null:
		_issue = issue.snapshot()


static func found(
	contract: RepresentativeRouteContractScript,
	stage_end_minimum_player_stats: PlayerStatProfileScript,
	stage_end_available_blueprints: Array[BlueprintDefinitionScript],
) -> RepresentativeRouteQueryResult:
	return RepresentativeRouteQueryResult.new(
		contract,
		stage_end_minimum_player_stats,
		stage_end_available_blueprints,
		null,
	)


static func failed(
	issue: ContentValidationIssueScript,
) -> RepresentativeRouteQueryResult:
	var no_blueprints: Array[BlueprintDefinitionScript] = []
	return RepresentativeRouteQueryResult.new(null, null, no_blueprints, issue)


func succeeded() -> bool:
	return _issue == null


func contract() -> RepresentativeRouteContractScript:
	if _contract == null:
		return null
	return RepresentativeRouteContractScript.snapshot(_contract)


func stage_end_minimum_player_stats() -> PlayerStatProfileScript:
	if _stage_end_minimum_player_stats == null:
		return null
	return PlayerStatProfileScript.snapshot(_stage_end_minimum_player_stats)


func stage_end_available_blueprint_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for blueprint: BlueprintDefinitionScript in _stage_end_available_blueprints:
		result.append(blueprint.content_id)
	return result


func stage_end_available_blueprints() -> Array[BlueprintDefinitionScript]:
	var result: Array[BlueprintDefinitionScript] = []
	for blueprint: BlueprintDefinitionScript in _stage_end_available_blueprints:
		result.append(BlueprintDefinitionScript.snapshot(blueprint))
	return result


func issue() -> ContentValidationIssueScript:
	if _issue == null:
		return null
	return _issue.snapshot()
