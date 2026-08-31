extends RefCounted

var name: String
var body: Callable


func _init(test_name: String, test_body: Callable) -> void:
	name = test_name
	body = test_body
