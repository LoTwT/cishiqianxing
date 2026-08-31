extends SceneTree

const REQUIRED_GODOT_MAJOR := 4
const REQUIRED_GODOT_MINOR := 7
const REQUIRED_GODOT_PATCH := 2
const REQUIRED_GODOT_STATUS := "stable"
const REQUIRED_GODOT_BUILD := "official"
const REQUIRED_GODOT_FEATURE := "4.7.2.stable.official"


func _initialize() -> void:
	var failures: Array[String] = []
	var version: Dictionary = Engine.get_version_info()

	if (
		int(version.get("major", -1)) != REQUIRED_GODOT_MAJOR
		or int(version.get("minor", -1)) != REQUIRED_GODOT_MINOR
		or int(version.get("patch", -1)) != REQUIRED_GODOT_PATCH
		or String(version.get("status", "")) != REQUIRED_GODOT_STATUS
		or String(version.get("build", "")) != REQUIRED_GODOT_BUILD
	):
		failures.append(
			"需要 Godot 4.7.2 stable official，当前为 %s。"
			% String(version.get("string", "unknown"))
		)

	var project_features: PackedStringArray = ProjectSettings.get_setting(
		"application/config/features", PackedStringArray()
	)
	if not project_features.has(REQUIRED_GODOT_FEATURE):
		failures.append(
			"项目必须要求 %s 特性，以锁定 Godot 4.7.2 Standard official。"
			% REQUIRED_GODOT_FEATURE
		)
	if (
		OS.has_feature("mono")
		or OS.has_feature("dotnet")
		or ClassDB.class_exists("CSharpScript")
		or project_features.has("C#")
	):
		failures.append("需要 Godot Standard，不得使用 .NET/Mono 构建。")

	var rendering_method := String(
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
	)
	if rendering_method != "forward_plus":
		failures.append("项目必须配置为 Forward+，当前为 %s。" % rendering_method)

	var active_rendering_method := RenderingServer.get_current_rendering_method()
	if active_rendering_method != "forward_plus":
		failures.append(
			"当前进程必须实际使用 Forward+，当前为 %s。" % active_rendering_method
		)

	var fallback_to_opengl3 := bool(
		ProjectSettings.get_setting("rendering/rendering_device/fallback_to_opengl3", true)
	)
	if fallback_to_opengl3:
		failures.append("必须关闭 Forward+ 到 Compatibility/OpenGL 3 的自动回退。")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print(
		"环境检查通过：Godot %s、Standard、Forward+、Compatibility 自动回退已关闭。"
		% String(version.get("string", "4.7.2"))
	)
	quit(0)
