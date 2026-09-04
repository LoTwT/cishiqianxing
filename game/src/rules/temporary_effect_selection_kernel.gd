class_name TemporaryEffectSelectionKernel
extends RefCounted

const ContactCombatCommandScript := preload(
	"res://src/rules/contact_combat_command.gd"
)
const PortableInventoryResolutionResultScript := preload(
	"res://src/rules/portable_inventory_resolution_result.gd"
)
const PortableInventoryResolverScript := preload(
	"res://src/rules/portable_inventory_resolver.gd"
)
const PortableInventoryStackScript := preload(
	"res://src/rules/portable_inventory_stack.gd"
)
const PortableInventoryStateScript := preload(
	"res://src/rules/portable_inventory_state.gd"
)
const TemporaryEffectSelectionCommandScript := preload(
	"res://src/rules/temporary_effect_selection_command.gd"
)
const TemporaryEffectSelectionResultScript := preload(
	"res://src/rules/temporary_effect_selection_result.gd"
)


static func execute(
	state: RefCounted,
	command: RefCounted,
	registry: RefCounted,
) -> TemporaryEffectSelectionResultScript:
	var current_resolution: PortableInventoryResolutionResultScript = (
		PortableInventoryResolverScript.resolve(state, registry)
	)
	if not current_resolution.succeeded():
		return TemporaryEffectSelectionResultScript.rejected(
			&"",
			(
				TemporaryEffectSelectionResultScript
				.RejectionReason
				.INVENTORY_STATE_REJECTED
			),
			current_resolution.failure_reason(),
		)
	if not _is_exact_command(command):
		return TemporaryEffectSelectionResultScript.rejected(
			&"",
			TemporaryEffectSelectionResultScript.RejectionReason.INVALID_COMMAND,
		)
	var authoritative_command: TemporaryEffectSelectionCommandScript = (
		command as TemporaryEffectSelectionCommandScript
	).copy()
	var requested_stack_id: StringName = authoritative_command.stack_id()
	if authoritative_command.kind() != TemporaryEffectSelectionCommandScript.Kind.SELECT:
		return TemporaryEffectSelectionResultScript.rejected(
			requested_stack_id,
			TemporaryEffectSelectionResultScript.RejectionReason.INVALID_COMMAND,
		)
	if (
		authoritative_command.expected_revision() < 0
		or authoritative_command.expected_revision()
		> PortableInventoryStateScript.MAXIMUM_REVISION
	):
		return TemporaryEffectSelectionResultScript.rejected(
			requested_stack_id,
			(
				TemporaryEffectSelectionResultScript
				.RejectionReason
				.INVALID_EXPECTED_REVISION
			),
		)
	if String(requested_stack_id).is_empty():
		return TemporaryEffectSelectionResultScript.rejected(
			requested_stack_id,
			TemporaryEffectSelectionResultScript.RejectionReason.EMPTY_STACK_ID,
		)
	if not PortableInventoryStackScript.is_valid_stack_id(requested_stack_id):
		return TemporaryEffectSelectionResultScript.rejected(
			requested_stack_id,
			TemporaryEffectSelectionResultScript.RejectionReason.INVALID_STACK_ID,
		)
	if authoritative_command.expected_revision() != current_resolution.revision():
		return TemporaryEffectSelectionResultScript.rejected(
			requested_stack_id,
			TemporaryEffectSelectionResultScript.RejectionReason.STALE_REVISION,
		)
	var requested_stack: PortableInventoryStackScript = (
		current_resolution.stack_snapshot(requested_stack_id)
	)
	if requested_stack == null:
		return TemporaryEffectSelectionResultScript.rejected(
			requested_stack_id,
			TemporaryEffectSelectionResultScript.RejectionReason.UNKNOWN_STACK_ID,
		)
	if (
		PortableInventoryStateScript.temporary_effect_for_blueprint_id(
			requested_stack.blueprint_id()
		)
		== ContactCombatCommandScript.TemporaryEffect.NONE
	):
		return TemporaryEffectSelectionResultScript.rejected(
			requested_stack_id,
			(
				TemporaryEffectSelectionResultScript
				.RejectionReason
				.STACK_NOT_TEMPORARY_EFFECT
			),
		)
	var current_selected_stack_id: StringName = (
		current_resolution.selected_temporary_effect_stack_id()
	)
	if current_selected_stack_id == requested_stack_id:
		return TemporaryEffectSelectionResultScript.unchanged(
			authoritative_command,
			current_resolution,
		)
	if current_resolution.revision() >= PortableInventoryStateScript.MAXIMUM_REVISION:
		return TemporaryEffectSelectionResultScript.rejected(
			requested_stack_id,
			TemporaryEffectSelectionResultScript.RejectionReason.REVISION_OVERFLOW,
		)
	if (
		not String(current_selected_stack_id).is_empty()
		and not authoritative_command.replacement_confirmed()
	):
		return TemporaryEffectSelectionResultScript.confirmation_required(
			authoritative_command,
			current_resolution,
		)
	var next_state: PortableInventoryStateScript = PortableInventoryStateScript.create(
		current_resolution.content_schema_version(),
		current_resolution.content_version(),
		current_resolution.capacity(),
		current_resolution.revision() + 1,
		current_resolution.stack_snapshots(),
		requested_stack_id,
	)
	var next_resolution: PortableInventoryResolutionResultScript = (
		PortableInventoryResolverScript.resolve(next_state, registry)
	)
	if not next_resolution.succeeded():
		return TemporaryEffectSelectionResultScript.rejected(
			requested_stack_id,
			(
				TemporaryEffectSelectionResultScript
				.RejectionReason
				.NEXT_STATE_REJECTED
			),
		)
	return TemporaryEffectSelectionResultScript.selected(
		authoritative_command,
		current_resolution,
		next_resolution,
	)


static func _is_exact_command(candidate: RefCounted) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.get_script() == TemporaryEffectSelectionCommandScript
	)
