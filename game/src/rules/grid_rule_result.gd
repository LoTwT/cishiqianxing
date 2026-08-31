class_name GridRuleResult
extends RefCounted

const GridRuleEventScript := preload("res://src/rules/grid_rule_event.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")

var _next_state: GridRuleStateScript
var _domain_events: Array[GridRuleEventScript] = []


func _init(
	next_state: GridRuleStateScript,
	domain_events: Array[GridRuleEventScript],
) -> void:
	_next_state = next_state.copy()
	for domain_event: GridRuleEventScript in domain_events:
		_domain_events.append(domain_event.copy())
	_domain_events.make_read_only()


func next_state() -> GridRuleStateScript:
	return _next_state.copy()


func domain_events() -> Array[GridRuleEventScript]:
	var copied_events: Array[GridRuleEventScript] = []
	for domain_event: GridRuleEventScript in _domain_events:
		copied_events.append(domain_event.copy())
	return copied_events
