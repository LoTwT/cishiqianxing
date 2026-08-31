extends RefCounted

var _assertion_count: int = 0
var _failures: Array[String] = []


func expect_true(condition: bool, message: String) -> void:
	_assertion_count += 1
	if not condition:
		_failures.append(message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assertion_count += 1
	if actual != expected:
		_failures.append(
			"%s Expected <%s>, got <%s>." % [message, str(expected), str(actual)]
		)


func record_runner_failure(message: String) -> void:
	_failures.append(message)


func assertion_count() -> int:
	return _assertion_count


func failures() -> Array[String]:
	var copied_failures: Array[String] = []
	for failure: String in _failures:
		copied_failures.append(failure)
	return copied_failures
