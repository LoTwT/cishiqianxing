extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const ContactCombatEventScript := preload(
	"res://src/rules/contact_combat_event.gd"
)
const ContactCombatOpponentStateScript := preload(
	"res://src/rules/contact_combat_opponent_state.gd"
)
const ContactCombatResolutionScript := preload(
	"res://src/rules/contact_combat_resolution.gd"
)
const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const PlayerProgressionSnapshotScript := preload(
	"res://src/rules/player_progression_snapshot.gd"
)
const PlayerProgressionStateScript := preload(
	"res://src/rules/player_progression_state.gd"
)


class StatefulPlayerState extends PlayerProgressionStateScript:
	var _reads: int = 0

	func copy() -> PlayerProgressionState:
		_reads += 1
		return super.copy()

	func is_valid() -> bool:
		_reads += 1
		return true

	func profile_id() -> StringName:
		_reads += 1
		return &"progression.player.loer"

	func read_count() -> int:
		return _reads


class StatefulOpponentState extends ContactCombatOpponentStateScript:
	var _reads: int = 0

	func copy() -> ContactCombatOpponentState:
		_reads += 1
		return super.copy()

	func is_valid() -> bool:
		_reads += 1
		return true

	func opponent_instance_id() -> StringName:
		_reads += 1
		return &"opponent.derived"

	func read_count() -> int:
		return _reads


class StatefulCommand extends ContactCombatCommandScript:
	var _reads: int = 0

	func _init() -> void:
		super(
			ContactCombatCommandScript.Kind.EVALUATE,
			ContactCombatCommandScript.Side.PLAYER,
			ContactCombatCommandScript.TemporaryEffect.NONE,
			0,
		)

	func copy() -> ContactCombatCommand:
		_reads += 1
		return super.copy()

	func kind() -> int:
		_reads += 1
		return ContactCombatCommandScript.Kind.EVALUATE

	func initiator_side() -> int:
		_reads += 1
		return ContactCombatCommandScript.Side.PLAYER

	func read_count() -> int:
		return _reads


class StatefulRegistry extends ContentRegistryScript:
	var _reads: int = 0

	func is_initialized() -> bool:
		_reads += 1
		return true

	func schema_version() -> int:
		_reads += 1
		return 4

	func content_version() -> int:
		_reads += 1
		return 4

	func read_count() -> int:
		return _reads


class DerivedPlayerSnapshot extends PlayerProgressionSnapshotScript:
	var _reads: int = 0

	func copy() -> PlayerProgressionSnapshot:
		_reads += 1
		return super.copy()

	func is_valid() -> bool:
		_reads += 1
		return true

	func current_health() -> int:
		_reads += 1
		return 20

	func read_count() -> int:
		return _reads


class DerivedResolution extends ContactCombatResolutionScript:
	func _init() -> void:
		super(
			&"progression.player.loer",
			4,
			4,
			&"opponent.derived-resolution",
			ContactCombatCommandScript.Side.PLAYER,
			ContactCombatCommandScript.Side.PLAYER,
			ContactCombatCommandScript.TemporaryEffect.NONE,
			false,
			0,
			0,
			10,
			5,
			10,
			6,
			6,
			9,
			4,
			1,
			true,
			2,
			2,
			1,
			20,
			19,
			8,
			0,
			false,
			false,
			false,
			true,
			ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED,
			ContactCombatResolutionScript.BlockReason.NONE,
		)


class DerivedEvent extends ContactCombatEventScript:
	func _init() -> void:
		var exact_resolution := ContactCombatResolutionScript.new(
			&"progression.player.loer",
			4,
			4,
			&"opponent.derived-event",
			ContactCombatCommandScript.Side.PLAYER,
			ContactCombatCommandScript.Side.PLAYER,
			ContactCombatCommandScript.TemporaryEffect.NONE,
			false,
			0,
			0,
			10,
			5,
			10,
			6,
			6,
			9,
			4,
			1,
			true,
			2,
			2,
			1,
			20,
			19,
			8,
			0,
			false,
			false,
			false,
			true,
			ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED,
			ContactCombatResolutionScript.BlockReason.NONE,
		)
		super(
			ContactCombatEventScript.Kind.CONTACT_RESOLUTION_CANDIDATE,
			exact_resolution,
		)
