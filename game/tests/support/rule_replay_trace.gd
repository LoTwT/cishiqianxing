extends RefCounted

const GridRuleEventScript := preload("res://src/rules/grid_rule_event.gd")
const GridRuleStateScript := preload("res://src/rules/grid_rule_state.gd")

var final_state: GridRuleStateScript
var domain_events: Array[GridRuleEventScript] = []


func _init(
	state: GridRuleStateScript,
	events: Array[GridRuleEventScript],
) -> void:
	final_state = state
	for domain_event: GridRuleEventScript in events:
		domain_events.append(domain_event)
