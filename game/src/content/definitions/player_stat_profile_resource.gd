class_name PlayerStatProfileResource
extends Resource

@export var profile_id: StringName = &""
@export var maximum_health: int = 0
@export var attack: int = 0
@export var defense: int = 0
@export var speed: int = 0


static func snapshot(source: PlayerStatProfileResource) -> PlayerStatProfileResource:
	var copied_profile := PlayerStatProfileResource.new()
	copied_profile.profile_id = source.profile_id
	copied_profile.maximum_health = source.maximum_health
	copied_profile.attack = source.attack
	copied_profile.defense = source.defense
	copied_profile.speed = source.speed
	return copied_profile


func is_equal_to(other: PlayerStatProfileResource) -> bool:
	return (
		other != null
		and other.profile_id == profile_id
		and other.maximum_health == maximum_health
		and other.attack == attack
		and other.defense == defense
		and other.speed == speed
	)
