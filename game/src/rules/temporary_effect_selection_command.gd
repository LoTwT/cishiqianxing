class_name TemporaryEffectSelectionCommand
extends RefCounted

const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)

enum Kind {
	SELECT = 1,
}

var _kind: int = 0
var _stack_id: StringName = &""
var _expected_revision: int = -1
var _replacement_confirmed: bool = false


func _init(
	kind: int,
	stack_id: StringName,
	expected_revision: int,
	replacement_confirmed: bool,
) -> void:
	_kind = kind
	_stack_id = stack_id
	_expected_revision = expected_revision
	_replacement_confirmed = replacement_confirmed


static func select(
	stack_id: StringName,
	expected_revision: int,
	replacement_confirmed: bool = false,
) -> TemporaryEffectSelectionCommand:
	return new(
		Kind.SELECT,
		stack_id,
		expected_revision,
		replacement_confirmed,
	)


func copy() -> TemporaryEffectSelectionCommand:
	return new(
		_kind,
		_stack_id,
		_expected_revision,
		_replacement_confirmed,
	)


func kind() -> int:
	return _kind


func stack_id() -> StringName:
	return _stack_id


func expected_revision() -> int:
	return _expected_revision


func replacement_confirmed() -> bool:
	return _replacement_confirmed


func is_valid() -> bool:
	return (
		_kind == Kind.SELECT
		and PortableInventoryStackScript.is_valid_stack_id(_stack_id)
		and _expected_revision >= 0
		and _expected_revision <= PortableInventoryStateScript.MAXIMUM_REVISION
	)
