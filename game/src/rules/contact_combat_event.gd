class_name ContactCombatEvent
extends RefCounted

const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
)

enum Kind {
	CONTACT_RESOLUTION_CANDIDATE = 1,
}

var _kind: int = 0
var _resolution: ContactCombatResolutionScript


func _init(kind: int, resolution: ContactCombatResolutionScript) -> void:
	_kind = kind
	if (
		resolution != null
		and is_instance_valid(resolution)
		and resolution.get_script() == ContactCombatResolutionScript
	):
		_resolution = resolution.copy()


static func contact_resolution_candidate(
	resolution: ContactCombatResolutionScript,
) -> ContactCombatEvent:
	return new(Kind.CONTACT_RESOLUTION_CANDIDATE, resolution)


func kind() -> int:
	return _kind


func resolution() -> ContactCombatResolutionScript:
	if not is_valid():
		return null
	return _resolution.copy()


func is_valid() -> bool:
	return (
		_kind == Kind.CONTACT_RESOLUTION_CANDIDATE
		and _resolution != null
		and _resolution.get_script() == ContactCombatResolutionScript
		and _resolution.is_valid()
		and _resolution.is_resolution_candidate()
	)


func is_resolution_candidate() -> bool:
	return is_valid()


func is_commit_boundary() -> bool:
	return false


func copy() -> ContactCombatEvent:
	return new(_kind, _resolution)


func is_equal_to(other: ContactCombatEvent) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other._kind == _kind
		and other._resolution != null
		and _resolution != null
		and other._resolution.is_equal_to(_resolution)
	)
