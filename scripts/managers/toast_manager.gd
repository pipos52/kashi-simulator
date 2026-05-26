# toast_manager.gd
# 全局 Toast 提示管理器（autoload）
# 使用：ToastManager.show("消息内容")
extends Node

func _ready() -> void:
	# 确保不重复添加
	pass

static func show(text: String, is_error: bool = false, duration: float = 2.0):
	var tree = Engine.get_main_loop()
	if not tree:
		return
	var root = tree.root
	if not root:
		return

	var panel = PanelContainer.new()
	panel.z_index = 10000
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -400.0
	panel.offset_right = 400.0
	panel.offset_top = -60.0
	panel.offset_bottom = 60.0

	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.9, 0.2, 0.2, 1.0) if is_error else Color(0.2, 0.85, 0.3, 1.0)
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", s)

	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0) if is_error else Color(0.3, 1.0, 0.4, 1.0))
	panel.add_child(lbl)

	root.add_child(panel)

	await tree.create_timer(duration).timeout
	if is_instance_valid(panel) and panel.is_inside_tree():
		panel.queue_free()
