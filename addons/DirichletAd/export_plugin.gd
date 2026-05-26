@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin

func _enter_tree():
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree():
	remove_export_plugin(export_plugin)
	export_plugin = null

class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name = "DirichletAd"

	func _supports_platform(platform) -> bool:
		if platform is EditorExportPlatformAndroid:
			return true
		return false

	func _get_android_libraries(platform, debug) -> PackedStringArray:
		# 返回插件 AAR 的路径（相对于 addons/ 目录）
		var lib_path = _plugin_name + "/build/outputs/aar/" + _plugin_name + "-" + ("debug" if debug else "release") + ".aar"
		return PackedStringArray([lib_path])

	func _get_android_dependencies(platform, debug) -> PackedStringArray:
		# Dirichlet SDK 的第三方依赖（OkHttp、Glide 等）
		# 这些由 Dirichlet AAR 内部包含，这里列出以确保 Gradle 能找到
		return PackedStringArray([
			"com.squareup.okhttp3:okhttp:3.12.1",
			"com.android.support:appcompat-v7:28.0.0",
			"com.android.support:support-v4:28.0.0",
			"com.github.bumptech.glide:glide:4.9.0",
			"com.android.support:recyclerview-v7:28.0.0",
		])

	func _get_name() -> String:
		return _plugin_name
