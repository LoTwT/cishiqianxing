class_name PortableInventoryStack
extends RefCounted

const ValidationSupportScript := preload("res://src/rules/validation_support.gd")
const MAXIMUM_STACK_ID_LENGTH: int = 128
const MAXIMUM_QUANTITY: int = 9

enum Provenance {
	CRAFTED_FROM_RECIPE = 1,
	NON_DISMANTLABLE_GIFT = 2,
}

var _stack_id: StringName = &""
var _blueprint_id: StringName = &""
var _provenance: int = 0
var _source_recipe_id: StringName = &""
var _quantity: int = 0
var _initialized: bool = false


static func create(
	stack_id: StringName,
	blueprint_id: StringName,
	provenance: int,
	source_recipe_id: StringName,
	quantity: int,
) -> PortableInventoryStack:
	var stack := new()
	stack._stack_id = stack_id
	stack._blueprint_id = blueprint_id
	stack._provenance = provenance
	stack._source_recipe_id = source_recipe_id
	stack._quantity = quantity
	stack._initialized = true
	return stack


func copy() -> PortableInventoryStack:
	var copied_stack := new()
	copied_stack._stack_id = _stack_id
	copied_stack._blueprint_id = _blueprint_id
	copied_stack._provenance = _provenance
	copied_stack._source_recipe_id = _source_recipe_id
	copied_stack._quantity = _quantity
	copied_stack._initialized = _initialized
	return copied_stack


func is_valid() -> bool:
	if (
		not _initialized
		or not is_valid_stack_id(_stack_id)
		or String(_blueprint_id).is_empty()
		or _quantity < 1
		or _quantity > MAXIMUM_QUANTITY
	):
		return false
	if _provenance == Provenance.CRAFTED_FROM_RECIPE:
		return not String(_source_recipe_id).is_empty()
	if _provenance == Provenance.NON_DISMANTLABLE_GIFT:
		return String(_source_recipe_id).is_empty()
	return false


static func is_valid_stack_id(stack_id: StringName) -> bool:
	return ValidationSupportScript.is_valid_identifier(
		stack_id,
		MAXIMUM_STACK_ID_LENGTH
	)


func stack_id() -> StringName:
	return _stack_id


func blueprint_id() -> StringName:
	return _blueprint_id


func provenance() -> int:
	return _provenance


func source_recipe_id() -> StringName:
	return _source_recipe_id


func quantity() -> int:
	return _quantity


func is_equal_to(other: PortableInventoryStack) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and other._initialized == _initialized
		and other._stack_id == _stack_id
		and other._blueprint_id == _blueprint_id
		and other._provenance == _provenance
		and other._source_recipe_id == _source_recipe_id
		and other._quantity == _quantity
	)
