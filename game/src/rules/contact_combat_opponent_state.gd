class_name ContactCombatOpponentState
extends RefCounted

var _opponent_instance_id: StringName = &""
var _maximum_durability: int = 0
var _current_durability: int = 0
var _attack: int = 0
var _defense: int = 0
var _speed: int = 0
var _shield_intact: bool = false
var _initialized: bool = false


static func create(
	opponent_instance_id: StringName,
	maximum_durability: int,
	current_durability: int,
	attack: int,
	defense: int,
	speed: int,
	shield_intact: bool = false,
) -> ContactCombatOpponentState:
	var state := new()
	state._opponent_instance_id = opponent_instance_id
	state._maximum_durability = maximum_durability
	state._current_durability = current_durability
	state._attack = attack
	state._defense = defense
	state._speed = speed
	state._shield_intact = shield_intact
	state._initialized = true
	return state


func copy() -> ContactCombatOpponentState:
	var copied_state := new()
	copied_state._opponent_instance_id = _opponent_instance_id
	copied_state._maximum_durability = _maximum_durability
	copied_state._current_durability = _current_durability
	copied_state._attack = _attack
	copied_state._defense = _defense
	copied_state._speed = _speed
	copied_state._shield_intact = _shield_intact
	copied_state._initialized = _initialized
	return copied_state


func is_valid() -> bool:
	return (
		_initialized
		and not String(_opponent_instance_id).is_empty()
		and _maximum_durability > 0
		and _current_durability >= 0
		and _current_durability <= _maximum_durability
		and _attack > 0
		and _defense > 0
		and _speed > 0
	)


func opponent_instance_id() -> StringName:
	return _opponent_instance_id


func maximum_durability() -> int:
	return _maximum_durability


func current_durability() -> int:
	return _current_durability


func attack() -> int:
	return _attack


func defense() -> int:
	return _defense


func speed() -> int:
	return _speed


func shield_intact() -> bool:
	return _shield_intact


func is_equal_to(other: ContactCombatOpponentState) -> bool:
	return (
		other != null
		and is_instance_valid(other)
		and other.get_script() == get_script()
		and other._initialized == _initialized
		and other.opponent_instance_id() == _opponent_instance_id
		and other.maximum_durability() == _maximum_durability
		and other.current_durability() == _current_durability
		and other.attack() == _attack
		and other.defense() == _defense
		and other.speed() == _speed
		and other.shield_intact() == _shield_intact
	)
