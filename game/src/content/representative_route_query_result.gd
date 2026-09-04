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
	# 审计 INCR-10：字段私有且读取边界统一做单次快照；传入资源由封印注册表
	# 保证不可变（注册表封印时已快照至私有只读存储；关卡末属性为注册表每次
	# 查询新建的局部快照），构造时直接持有引用，不再做构造期防御拷贝。
	# 蓝图数组的容器拷贝保留：其职责是隔离调用方数组（防止构造后被外部改写）
	# 并封印内部字段为只读，数组元素本身不再逐个快照——读取边界已做单次快照。
	_contract = contract
	_stage_end_minimum_player_stats = stage_end_minimum_player_stats
	for blueprint: BlueprintDefinitionScript in stage_end_available_blueprints:
		_stage_end_available_blueprints.append(blueprint)
	_stage_end_available_blueprints.make_read_only()
	_issue = issue


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
