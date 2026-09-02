extends "res://src/rules/permanent_growth_claim_event.gd"


func _init() -> void:
	super(
		Kind.APPLIED,
		&"progression.player.loer",
		3,
		3,
		&"progression.reward.main.chapter.01.attack",
		2,
		1,
		100,
		100,
	)
