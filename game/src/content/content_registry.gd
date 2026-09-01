class_name ContentRegistry
extends RefCounted

const BlueprintDefinitionScript := preload(
	"res://src/content/definitions/blueprint_definition_resource.gd"
)
const RecipeDefinitionScript := preload(
	"res://src/content/definitions/recipe_definition_resource.gd"
)
const ContentLookupResultScript := preload("res://src/content/content_lookup_result.gd")
const ContentContractFingerprintScript := preload(
	"res://src/content/content_contract_fingerprint.gd"
)
const ContentValidationIssueScript := preload(
	"res://src/content/content_validation_issue.gd"
)

var _schema_version: int
var _content_version: int
var _material_ids: Array[StringName] = []
var _blueprint_ids: Array[StringName] = []
var _recipe_ids: Array[StringName] = []
var _blueprints_by_id: Dictionary[StringName, BlueprintDefinitionScript] = {}
var _recipes_by_id: Dictionary[StringName, RecipeDefinitionScript] = {}


func _init() -> void:
	pass


func _initialize_validated(
	schema_version: int,
	content_version: int,
	blueprints: Array[BlueprintDefinitionScript],
	recipes: Array[RecipeDefinitionScript],
) -> void:
	if is_initialized():
		return
	if not ContentContractFingerprintScript.matches(
		schema_version,
		content_version,
		blueprints,
		recipes,
	):
		return
	var stored_material_ids: Array[StringName] = (
		RecipeDefinitionScript.allowed_material_ids()
	)
	var stored_blueprint_ids: Array[StringName] = []
	var stored_recipe_ids: Array[StringName] = []
	var stored_blueprints_by_id: Dictionary[StringName, BlueprintDefinitionScript] = {}
	var stored_recipes_by_id: Dictionary[StringName, RecipeDefinitionScript] = {}
	for blueprint: BlueprintDefinitionScript in blueprints:
		var stored_blueprint: BlueprintDefinitionScript = (
			BlueprintDefinitionScript.snapshot(blueprint)
		)
		stored_blueprint_ids.append(stored_blueprint.content_id)
		stored_blueprints_by_id[stored_blueprint.content_id] = stored_blueprint
	for recipe: RecipeDefinitionScript in recipes:
		var stored_recipe: RecipeDefinitionScript = RecipeDefinitionScript.snapshot(recipe)
		stored_recipe_ids.append(stored_recipe.recipe_id)
		stored_recipes_by_id[stored_recipe.recipe_id] = stored_recipe
	stored_blueprint_ids.sort_custom(_content_id_less_than)
	stored_recipe_ids.sort_custom(_content_id_less_than)
	stored_material_ids.sort_custom(_content_id_less_than)
	stored_material_ids.make_read_only()
	stored_blueprint_ids.make_read_only()
	stored_recipe_ids.make_read_only()
	stored_blueprints_by_id.make_read_only()
	stored_recipes_by_id.make_read_only()
	_schema_version = schema_version
	_content_version = content_version
	_material_ids = stored_material_ids
	_blueprint_ids = stored_blueprint_ids
	_recipe_ids = stored_recipe_ids
	_blueprints_by_id = stored_blueprints_by_id
	_recipes_by_id = stored_recipes_by_id


func is_initialized() -> bool:
	return _has_valid_contract()


func schema_version() -> int:
	return _schema_version if is_initialized() else 0


func content_version() -> int:
	return _content_version if is_initialized() else 0


func blueprint_count() -> int:
	return _blueprint_ids.size() if is_initialized() else 0


func recipe_count() -> int:
	return _recipe_ids.size() if is_initialized() else 0


func material_count() -> int:
	return _material_ids.size() if is_initialized() else 0


func material_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_material_ids)


func has_material(material_id: StringName) -> bool:
	return is_initialized() and _material_ids.has(material_id)


func blueprint_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_blueprint_ids)


func recipe_ids() -> Array[StringName]:
	if not is_initialized():
		return []
	return _copy_ids(_recipe_ids)


func blueprints() -> Array[BlueprintDefinitionScript]:
	var result: Array[BlueprintDefinitionScript] = []
	if not is_initialized():
		return result
	for content_id: StringName in _blueprint_ids:
		result.append(BlueprintDefinitionScript.snapshot(_blueprints_by_id[content_id]))
	return result


func recipes() -> Array[RecipeDefinitionScript]:
	var result: Array[RecipeDefinitionScript] = []
	if not is_initialized():
		return result
	for recipe_id: StringName in _recipe_ids:
		result.append(RecipeDefinitionScript.snapshot(_recipes_by_id[recipe_id]))
	return result


func lookup_blueprint(content_id: StringName) -> ContentLookupResultScript:
	if not is_initialized():
		return _uninitialized_lookup(ContentLookupResultScript.Kind.BLUEPRINT, content_id)
	if not _blueprints_by_id.has(content_id):
		return ContentLookupResultScript.failed(
			ContentLookupResultScript.Kind.BLUEPRINT,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_BLUEPRINT_ID,
				content_id,
				"content_id",
				"No blueprint is registered for ID '%s'." % String(content_id),
			),
		)
	return ContentLookupResultScript.found_blueprint(_blueprints_by_id[content_id])


func lookup_recipe(recipe_id: StringName) -> ContentLookupResultScript:
	if not is_initialized():
		return _uninitialized_lookup(ContentLookupResultScript.Kind.RECIPE, recipe_id)
	if not _recipes_by_id.has(recipe_id):
		return ContentLookupResultScript.failed(
			ContentLookupResultScript.Kind.RECIPE,
			ContentValidationIssueScript.new(
				ContentValidationIssueScript.LOOKUP_UNKNOWN_RECIPE_ID,
				recipe_id,
				"recipe_id",
				"No standard recipe is registered for ID '%s'." % String(recipe_id),
			),
		)
	return ContentLookupResultScript.found_recipe(_recipes_by_id[recipe_id])


func _uninitialized_lookup(kind: int, requested_id: StringName) -> ContentLookupResultScript:
	return ContentLookupResultScript.failed(
		kind,
		ContentValidationIssueScript.new(
			ContentValidationIssueScript.LOOKUP_REGISTRY_UNINITIALIZED,
			requested_id,
			"registry",
			"Content registry has not passed manifest validation and initialization.",
		),
	)


func _has_valid_contract() -> bool:
	var expected_material_ids: Array[StringName] = (
		RecipeDefinitionScript.allowed_material_ids()
	)
	expected_material_ids.sort_custom(_content_id_less_than)
	if _material_ids != expected_material_ids:
		return false
	if (
		_blueprint_ids.size() != _blueprints_by_id.size()
		or _recipe_ids.size() != _recipes_by_id.size()
	):
		return false
	var ordered_blueprint_ids: Array[StringName] = _copy_ids(_blueprint_ids)
	var ordered_recipe_ids: Array[StringName] = _copy_ids(_recipe_ids)
	ordered_blueprint_ids.sort_custom(_content_id_less_than)
	ordered_recipe_ids.sort_custom(_content_id_less_than)
	if _blueprint_ids != ordered_blueprint_ids or _recipe_ids != ordered_recipe_ids:
		return false
	var blueprints: Array[BlueprintDefinitionScript] = []
	for content_id: StringName in _blueprint_ids:
		if not _blueprints_by_id.has(content_id):
			return false
		var blueprint_resource: Resource = _blueprints_by_id[content_id] as Resource
		if (
			blueprint_resource == null
			or blueprint_resource.get_script() != BlueprintDefinitionScript
		):
			return false
		var blueprint: BlueprintDefinitionScript = (
			blueprint_resource as BlueprintDefinitionScript
		)
		if blueprint.content_id != content_id:
			return false
		blueprints.append(blueprint)
	var recipes: Array[RecipeDefinitionScript] = []
	for recipe_id: StringName in _recipe_ids:
		if not _recipes_by_id.has(recipe_id):
			return false
		var recipe_resource: Resource = _recipes_by_id[recipe_id] as Resource
		if (
			recipe_resource == null
			or recipe_resource.get_script() != RecipeDefinitionScript
		):
			return false
		var recipe: RecipeDefinitionScript = recipe_resource as RecipeDefinitionScript
		if recipe.recipe_id != recipe_id:
			return false
		recipes.append(recipe)
	return ContentContractFingerprintScript.matches(
		_schema_version,
		_content_version,
		blueprints,
		recipes,
	)


static func _copy_ids(source: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for content_id: StringName in source:
		result.append(content_id)
	return result


static func _content_id_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
