class_name EnemyWorldResolver
extends RefCounted

const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const EnemyInstanceResolutionResultScript := preload(
	"res://src/rules/enemy_instance_resolution_result.gd"
)
const EnemyInstanceResolverScript := preload(
	"res://src/rules/enemy_instance_resolver.gd"
)
const EnemyInstanceStateScript := preload(
	"res://src/rules/enemy_instance_state.gd"
)
const EnemyWorldAddressScript := preload(
	"res://src/rules/enemy_world_address.gd"
)
const EnemyWorldRecordScript := preload(
	"res://src/rules/enemy_world_record.gd"
)
const EnemyWorldResolutionResultScript := preload(
	"res://src/rules/enemy_world_resolution_result.gd"
)
const EnemyWorldStateScript := preload(
	"res://src/rules/enemy_world_state.gd"
)
const ValidationSupportScript := preload("res://src/rules/validation_support.gd")


static func resolve(
	world_state_candidate: RefCounted,
	registry: RefCounted,
) -> EnemyWorldResolutionResultScript:
	if not _is_exact_world_state(world_state_candidate):
		return _failure(
			EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STATE
		)
	var candidate: EnemyWorldStateScript = (
		world_state_candidate as EnemyWorldStateScript
	).copy()
	if not candidate._initialized:
		return _failure(
			EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STATE
		)
	if not candidate._record_input_types_valid:
		return _failure(
			EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_RECORD
		)
	if not candidate._address_input_types_valid:
		return _failure(
			EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_ADDRESS
		)
	var records: Array[EnemyWorldRecordScript] = []
	for record: EnemyWorldRecordScript in candidate._records:
		if (
			not _is_exact_record(record)
			or not record._initialized
			or not record._instance_state_type_valid
			or not _is_exact_instance_state(record._instance_state)
		):
			return _failure(
				EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_RECORD
			)
		records.append(record.copy())
	if (
		candidate._world_step < 0
		or candidate._world_step > ValidationSupportScript.MAX_WORLD_STEP
	):
		return _failure(
			EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_STEP
		)
	records.sort_custom(_record_less_than)
	for record: EnemyWorldRecordScript in records:
		if (
			record.lifecycle() != EnemyWorldRecordScript.Lifecycle.ACTIVE
			and record.lifecycle() != EnemyWorldRecordScript.Lifecycle.RESOLVED
		):
			return _failure(
				EnemyWorldResolutionResultScript.FailureReason.INVALID_LIFECYCLE,
				record.instance_id(),
			)

	var addresses: Dictionary[StringName, EnemyWorldAddressScript] = {}
	var address_ids: Array[StringName] = []
	for instance_id: StringName in candidate._addresses_by_instance_id:
		address_ids.append(instance_id)
	address_ids.sort_custom(ValidationSupportScript.id_less_than)
	for instance_id: StringName in address_ids:
		var address: EnemyWorldAddressScript = (
			candidate._addresses_by_instance_id[instance_id]
		)
		if (
			not EnemyInstanceStateScript.is_valid_instance_id(instance_id)
			or not _is_exact_address(address)
			or not address.is_valid()
		):
			return _failure(
				EnemyWorldResolutionResultScript.FailureReason.INVALID_WORLD_ADDRESS,
				instance_id,
				address.space_id() if _is_exact_address(address) else &"",
			)
		addresses[instance_id] = address.copy()

	for index: int in range(1, records.size()):
		if records[index].instance_id() == records[index - 1].instance_id():
			return _failure(
				EnemyWorldResolutionResultScript.FailureReason.DUPLICATE_INSTANCE_ID,
				records[index].instance_id(),
			)

	var resolved_records: Array[EnemyWorldRecordScript] = []
	if records.is_empty() and not _is_valid_registry(registry):
		return _failure(
			EnemyWorldResolutionResultScript.FailureReason.ENEMY_INSTANCE_REJECTED,
			&"",
			&"",
			EnemyInstanceResolutionResultScript.FailureReason.INVALID_REGISTRY,
		)
	for record: EnemyWorldRecordScript in records:
		var instance_result: EnemyInstanceResolutionResultScript = (
			EnemyInstanceResolverScript.resolve(record.instance_state(), registry)
		)
		if not instance_result.succeeded():
			return _failure(
				EnemyWorldResolutionResultScript.FailureReason.ENEMY_INSTANCE_REJECTED,
				record.instance_id(),
				&"",
				instance_result.failure_reason(),
			)
		resolved_records.append(
			EnemyWorldRecordScript.create(
				instance_result.instance_state(),
				record.lifecycle(),
			)
		)

	var known_instance_ids: Dictionary[StringName, bool] = {}
	for record: EnemyWorldRecordScript in resolved_records:
		known_instance_ids[record.instance_id()] = true
	for instance_id: StringName in address_ids:
		if not known_instance_ids.has(instance_id):
			return _failure(
				EnemyWorldResolutionResultScript.FailureReason.ORPHAN_GRID_ACTOR,
				instance_id,
				addresses[instance_id].space_id(),
			)

	for record: EnemyWorldRecordScript in resolved_records:
		var current_durability: int = record.instance_state().current_durability()
		if (
			record.lifecycle() == EnemyWorldRecordScript.Lifecycle.ACTIVE
			and current_durability == 0
		):
			return _failure(
				(
					EnemyWorldResolutionResultScript
					.FailureReason
					.ACTIVE_REQUIRES_POSITIVE_DURABILITY
				),
				record.instance_id(),
			)
		if (
			record.lifecycle() == EnemyWorldRecordScript.Lifecycle.RESOLVED
			and current_durability > 0
		):
			return _failure(
				(
					EnemyWorldResolutionResultScript
					.FailureReason
					.RESOLVED_REQUIRES_ZERO_DURABILITY
				),
				record.instance_id(),
			)

	for record: EnemyWorldRecordScript in resolved_records:
		var has_address: bool = addresses.has(record.instance_id())
		if (
			record.lifecycle() == EnemyWorldRecordScript.Lifecycle.ACTIVE
			and not has_address
		):
			return _failure(
				(
					EnemyWorldResolutionResultScript
					.FailureReason
					.ACTIVE_REQUIRES_WORLD_ADDRESS
				),
				record.instance_id(),
			)
		if (
			record.lifecycle() == EnemyWorldRecordScript.Lifecycle.RESOLVED
			and has_address
		):
			return _failure(
				(
					EnemyWorldResolutionResultScript
					.FailureReason
					.RESOLVED_CANNOT_OCCUPY_WORLD_ADDRESS
				),
				record.instance_id(),
				addresses[record.instance_id()].space_id(),
			)

	var occupied_addresses: Dictionary[String, StringName] = {}
	for record: EnemyWorldRecordScript in resolved_records:
		if record.lifecycle() != EnemyWorldRecordScript.Lifecycle.ACTIVE:
			continue
		var address: EnemyWorldAddressScript = addresses[record.instance_id()]
		var address_key: String = address.canonical_slot_key()
		if occupied_addresses.has(address_key):
			return _failure(
				EnemyWorldResolutionResultScript.FailureReason.DUPLICATE_WORLD_ADDRESS,
				record.instance_id(),
				address.space_id(),
			)
		occupied_addresses[address_key] = record.instance_id()

	var resolved_state: EnemyWorldStateScript = EnemyWorldStateScript.create(
		resolved_records,
		addresses,
		candidate.world_step(),
	)
	if not resolved_state.is_valid():
		return _failure(
			EnemyWorldResolutionResultScript.FailureReason.INVALID_RESULT
		)
	return EnemyWorldResolutionResultScript.success(resolved_state, registry)


static func _failure(
	failure_reason: int,
	failed_instance_id: StringName = &"",
	failed_space_id: StringName = &"",
	enemy_instance_failure_reason: int = (
		EnemyInstanceResolutionResultScript.FailureReason.NONE
	),
) -> EnemyWorldResolutionResultScript:
	return EnemyWorldResolutionResultScript.failure(
		failure_reason,
		failed_instance_id,
		failed_space_id,
		enemy_instance_failure_reason,
	)


static func _is_valid_registry(registry: RefCounted) -> bool:
	return (
		registry != null
		and is_instance_valid(registry)
		and registry.get_script() == ContentRegistryScript
		and (registry as ContentRegistryScript).is_initialized()
	)


static func _is_exact_world_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldStateScript
	)


static func _is_exact_record(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldRecordScript
	)


static func _is_exact_instance_state(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyInstanceStateScript
	)


static func _is_exact_address(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == EnemyWorldAddressScript
	)


static func _record_less_than(
	left: EnemyWorldRecordScript,
	right: EnemyWorldRecordScript,
) -> bool:
	return String(left.instance_id()) < String(right.instance_id())


