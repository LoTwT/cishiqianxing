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
		super()
		_kind = Kind.EVALUATE
		_initiator_side = Side.PLAYER
		_temporary_effect = TemporaryEffect.NONE
		_supporting_opponents_alive = 0
		_initialized = true

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
		# 该值不会被读取——规则层用 get_script() 精确身份检查先行拒绝替身，
		# 此值仅为避免误导维护者而与现行版本保持一致。
		return 5

	func content_version() -> int:
		_reads += 1
		# 该值不会被读取——规则层用 get_script() 精确身份检查先行拒绝替身，
		# 此值仅为避免误导维护者而与现行版本保持一致。
		return 5

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
		# 审计 INCR-7：GDScript 的 super() 只支持位置传参，不支持具名实参。
		# 此处用具名局部变量逐一对应基类 _init 的具名参数（变量名即参数名），
		# 再按原参数顺序位置传入 super()，构造出的字段值与改造前逐字节一致。
		var player_profile_id := &"progression.player.loer"
		var content_schema_version := 4
		var content_version := 4
		var opponent_instance_id := &"opponent.derived-resolution"
		var initiator_side := ContactCombatCommandScript.Side.PLAYER
		var first_attacker_side := ContactCombatCommandScript.Side.PLAYER
		var temporary_effect := ContactCombatCommandScript.TemporaryEffect.NONE
		var temporary_effect_should_be_consumed := false
		var supporting_opponents_alive := 0
		var support_attack_bonus := 0
		var effective_player_attack := 10
		var effective_player_defense := 5
		var effective_player_speed := 10
		var effective_opponent_attack := 6
		var effective_opponent_defense := 6
		var effective_opponent_speed := 9
		var player_damage_per_attack := 4
		var opponent_damage_per_attack := 1
		var has_finite_player_attack_requirement := true
		var player_attacks_required_to_clear := 2
		var player_attacks_executed := 2
		var opponent_attacks_executed := 1
		var previous_player_health := 20
		var next_player_health := 19
		var previous_opponent_durability := 8
		var next_opponent_durability := 0
		var opponent_shield_intact_before := false
		var opponent_shield_absorbed_attack := false
		var opponent_shield_intact_after := false
		var is_resolution_candidate := true
		var outcome := ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED
		var block_reason := ContactCombatResolutionScript.BlockReason.NONE
		super(
			player_profile_id,
			content_schema_version,
			content_version,
			opponent_instance_id,
			initiator_side,
			first_attacker_side,
			temporary_effect,
			temporary_effect_should_be_consumed,
			supporting_opponents_alive,
			support_attack_bonus,
			effective_player_attack,
			effective_player_defense,
			effective_player_speed,
			effective_opponent_attack,
			effective_opponent_defense,
			effective_opponent_speed,
			player_damage_per_attack,
			opponent_damage_per_attack,
			has_finite_player_attack_requirement,
			player_attacks_required_to_clear,
			player_attacks_executed,
			opponent_attacks_executed,
			previous_player_health,
			next_player_health,
			previous_opponent_durability,
			next_opponent_durability,
			opponent_shield_intact_before,
			opponent_shield_absorbed_attack,
			opponent_shield_intact_after,
			is_resolution_candidate,
			outcome,
			block_reason,
		)


class DerivedEvent extends ContactCombatEventScript:
	func _init() -> void:
		# 审计 INCR-7：同 DerivedResolution——用具名局部变量对应基类 _init 的
		# 具名参数，再按原参数顺序位置传入，构造出的字段值与改造前逐字节一致。
		# 注意 exact_resolution 必须直接构造基类脚本实例：事件层以
		# get_script() 精确身份检查 resolution，DerivedResolution 会被拒绝。
		var player_profile_id := &"progression.player.loer"
		var content_schema_version := 4
		var content_version := 4
		var opponent_instance_id := &"opponent.derived-event"
		var initiator_side := ContactCombatCommandScript.Side.PLAYER
		var first_attacker_side := ContactCombatCommandScript.Side.PLAYER
		var temporary_effect := ContactCombatCommandScript.TemporaryEffect.NONE
		var temporary_effect_should_be_consumed := false
		var supporting_opponents_alive := 0
		var support_attack_bonus := 0
		var effective_player_attack := 10
		var effective_player_defense := 5
		var effective_player_speed := 10
		var effective_opponent_attack := 6
		var effective_opponent_defense := 6
		var effective_opponent_speed := 9
		var player_damage_per_attack := 4
		var opponent_damage_per_attack := 1
		var has_finite_player_attack_requirement := true
		var player_attacks_required_to_clear := 2
		var player_attacks_executed := 2
		var opponent_attacks_executed := 1
		var previous_player_health := 20
		var next_player_health := 19
		var previous_opponent_durability := 8
		var next_opponent_durability := 0
		var opponent_shield_intact_before := false
		var opponent_shield_absorbed_attack := false
		var opponent_shield_intact_after := false
		var is_resolution_candidate := true
		var outcome := ContactCombatResolutionScript.Outcome.OPPONENT_CLEARED
		var block_reason := ContactCombatResolutionScript.BlockReason.NONE
		var exact_resolution := ContactCombatResolutionScript.new(
			player_profile_id,
			content_schema_version,
			content_version,
			opponent_instance_id,
			initiator_side,
			first_attacker_side,
			temporary_effect,
			temporary_effect_should_be_consumed,
			supporting_opponents_alive,
			support_attack_bonus,
			effective_player_attack,
			effective_player_defense,
			effective_player_speed,
			effective_opponent_attack,
			effective_opponent_defense,
			effective_opponent_speed,
			player_damage_per_attack,
			opponent_damage_per_attack,
			has_finite_player_attack_requirement,
			player_attacks_required_to_clear,
			player_attacks_executed,
			opponent_attacks_executed,
			previous_player_health,
			next_player_health,
			previous_opponent_durability,
			next_opponent_durability,
			opponent_shield_intact_before,
			opponent_shield_absorbed_attack,
			opponent_shield_intact_after,
			is_resolution_candidate,
			outcome,
			block_reason,
		)
		var kind := ContactCombatEventScript.Kind.CONTACT_RESOLUTION_CANDIDATE
		super(
			kind,
			exact_resolution,
		)
