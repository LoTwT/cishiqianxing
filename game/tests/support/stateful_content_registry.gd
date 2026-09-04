extends "res://src/content/content_registry.gd"

var _initialization_reads: int = 0
var _schema_reads: int = 0
var _content_reads: int = 0


func is_initialized() -> bool:
	_initialization_reads += 1
	return true


func schema_version() -> int:
	_schema_reads += 1
	# 该值不会被读取——规则层用 get_script() 精确身份检查先行拒绝替身，
	# 此值仅为避免误导维护者而与现行版本保持一致。
	return 5


func content_version() -> int:
	_content_reads += 1
	# 该值不会被读取——规则层用 get_script() 精确身份检查先行拒绝替身，
	# 此值仅为避免误导维护者而与现行版本保持一致。
	return 5


func read_count() -> int:
	return _initialization_reads + _schema_reads + _content_reads
