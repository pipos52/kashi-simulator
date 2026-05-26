# energy_bar.gd
# 能量条控件（纯代码，无tscn）
extends HBoxContainer

signal energy_changed(current: float, max_val: float)

var energy_label: Label
var progress_bar: ProgressBar
var balance_label: Label

var current_energy: float = 0.0
var max_energy: float = 15.0

func _init():
	_build()

func _build():
	custom_minimum_size = Vector2(0, 70)

	energy_label = Label.new()
	energy_label.text = "0 / 15"
	energy_label.custom_minimum_size = Vector2(160, 0)
	energy_label.add_theme_font_size_override("font_size", 60)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(energy_label)

	var sep1 = VBoxContainer.new()
	sep1.custom_minimum_size = Vector2(12, 0)
	add_child(sep1)

	progress_bar = ProgressBar.new()
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.custom_minimum_size = Vector2(0, 36)
	progress_bar.show_percentage = false
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	var pg = StyleBoxFlat.new()
	pg.bg_color = Color(0.15, 0.15, 0.22, 1.0)
	pg.corner_radius_top_left = 4; pg.corner_radius_top_right = 4
	pg.corner_radius_bottom_left = 4; pg.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("background", pg)
	var fg = StyleBoxFlat.new()
	fg.bg_color = Color(0.3, 0.8, 0.4, 1.0)
	fg.corner_radius_top_left = 4; fg.corner_radius_top_right = 4
	fg.corner_radius_bottom_left = 4; fg.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("fill", fg)
	add_child(progress_bar)

	var sep2 = VBoxContainer.new()
	sep2.custom_minimum_size = Vector2(12, 0)
	add_child(sep2)

	balance_label = Label.new()
	balance_label.text = "✓ 平衡良好"
	balance_label.custom_minimum_size = Vector2(300, 0)
	balance_label.add_theme_font_size_override("font_size", 44)
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(balance_label)

	_update_display()

func set_energy(value: float):
	current_energy = clamp(value, 0, max_energy * 1.2)
	_update_display()
	energy_changed.emit(current_energy, max_energy)

func set_max_energy(value: float):
	max_energy = value
	_update_display()

func _update_display():
	energy_label.text = "%.1f / %.1f" % [current_energy, max_energy]
	var percent = (current_energy / max_energy) * 100.0
	progress_bar.value = clamp(percent, 0, 120)

	if current_energy > max_energy:
		progress_bar.modulate = Color(1, 0.3, 0.2)
		balance_label.text = "⚠️ 能量超标！"
		balance_label.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
	elif current_energy > max_energy * 0.85:
		progress_bar.modulate = Color(1, 0.6, 0.2)
		balance_label.text = "⚡ 偏高，建议增加约束"
		balance_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	elif current_energy < max_energy * 0.3:
		progress_bar.modulate = Color(0.3, 0.7, 1.0)
		balance_label.text = "💪 偏低，可以加强效果"
		balance_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	else:
		progress_bar.modulate = Color(0.3, 0.8, 0.4)
		balance_label.text = "✓ 平衡良好"
		balance_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
