# constraint_selector.gd
# 约束选择弹窗组件（独立封装）
# 使用：var sel = ConstraintSelector.new(selected_ids); sel.confirmed.connect(on_constraints_confirmed)
extends Node

signal confirmed(selected_ids: Array[String])

const ALL_CONSTRAINTS: Array = [
	["CO01", "一回合一次", "效果每回合只能触发一次"],
	["CO02", "一局一次", "效果整局只能触发一次"],
	["CO03", "使用后破坏", "效果触发后破坏卡牌"],
	["CO04", "使用后除外", "效果触发后移出对战"],
	["CO05", "消耗生命", "效果触发需支付生命"],
	["CO06", "弃手牌", "效果触发需弃置手牌"],
	["CO07", "消耗能量", "效果触发需消耗能量"],
	["CO08", "仅己方回合", "效果仅在己方回合可用"],
	["CO09", "仅对方回合", "效果仅在对方回合可用"],
	["CO10", "需盖放", "效果需盖放才能触发"],
	["CO11", "需满足条件", "效果需满足特定条件"],
	["CO12", "非永久", "效果为非永久效果"],
	["CO13", "不可攻击", "此卡无法进行攻击"],
	["CO14", "不可被攻击", "此卡无法被选为攻击目标"]
]

var _popup: Panel
var _selected: Array[String]
var _check_rows: Array[Dictionary] = []  # {row, cid, check}

func _init(initial_selected: Array[String] = []):
	_selected = initial_selected.duplicate()

func build() -> Panel:
	_popup = Panel.new()
	_popup.anchor_left = 0.0
	_popup.anchor_top = 0.0
	_popup.anchor_right = 1.0
	_popup.anchor_bottom = 1.0
	_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	_popup.add_theme_stylebox_override("panel", bg)
	get_tree().root.add_child(_popup)

	# 居中卡片
	var card = PanelContainer.new()
	card.anchor_left = 0.0; card.anchor_top = 0.0
	card.anchor_right = 1.0; card.anchor_bottom = 1.0
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var card_bg = StyleBoxFlat.new()
	card_bg.bg_color = Color(0.12, 0.14, 0.22, 1.0)
	card_bg.corner_radius_top_left = 12; card_bg.corner_radius_top_right = 12
	card_bg.corner_radius_bottom_left = 12; card_bg.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", card_bg)
	_popup.add_child(card)

	var margin = MarginContainer.new()
	margin.anchor_left = 0.0; margin.anchor_top = 0.0
	margin.anchor_right = 1.0; margin.anchor_bottom = 1.0
	margin.offset_left = 40; margin.offset_top = 120
	margin.offset_right = -40; margin.offset_bottom = -120
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "选择约束"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)

	for cs in ALL_CONSTRAINTS:
		var row_data = _make_row(cs, list_vbox)
		_check_rows.append(row_data)

	var btn_row = HBoxContainer.new()
	btn_row.custom_minimum_size = Vector2(0, 100)
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "✖ 取消"
	cancel_btn.custom_minimum_size = Vector2(0, 80)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 40)
	cancel_btn.pressed.connect(_on_cancel)
	btn_row.add_child(cancel_btn)

	var ok_btn = Button.new()
	ok_btn.text = "✅ 确定"
	ok_btn.custom_minimum_size = Vector2(0, 80)
	ok_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_btn.add_theme_font_size_override("font_size", 40)
	var okbs = StyleBoxFlat.new()
	okbs.bg_color = Color(0.2, 0.35, 0.2)
	ok_btn.add_theme_stylebox_override("normal", okbs)
	ok_btn.pressed.connect(_on_ok)
	btn_row.add_child(ok_btn)

	return _popup

func _make_row(cs: Array, parent: VBoxContainer) -> Dictionary:
	var is_selected = cs[0] in _selected
	var row = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 90)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row_bg = StyleBoxFlat.new()
	row_bg.bg_color = Color(0.18, 0.2, 0.3, 0.8) if is_selected else Color(0.15, 0.16, 0.28, 0.8)
	row_bg.corner_radius_top_left = 6; row_bg.corner_radius_top_right = 6
	row_bg.corner_radius_bottom_left = 6; row_bg.corner_radius_bottom_right = 6
	row.add_theme_stylebox_override("panel", row_bg)
	row.set_meta("cid", cs[0])
	row.set_meta("selected", is_selected)
	parent.add_child(row)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.custom_minimum_size = Vector2(0, 90)
	row.add_child(hbox)

	var check = CheckBox.new()
	check.button_pressed = is_selected
	check.custom_minimum_size = Vector2(50, 50)
	check.size_flags_horizontal = 0
	hbox.add_child(check)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_lbl = Label.new()
	name_lbl.text = cs[1]
	name_lbl.add_theme_font_size_override("font_size", 40)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	info.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = cs[2]
	desc_lbl.add_theme_font_size_override("font_size", 26)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	info.add_child(desc_lbl)

	var toggle_fn = func():
		var new_val = not check.button_pressed
		check.button_pressed = new_val
		row.set_meta("selected", new_val)
		var bg2 = StyleBoxFlat.new()
		bg2.bg_color = Color(0.18, 0.2, 0.3, 0.8) if new_val else Color(0.15, 0.16, 0.28, 0.8)
		bg2.corner_radius_top_left = 6; bg2.corner_radius_top_right = 6
		bg2.corner_radius_bottom_left = 6; bg2.corner_radius_bottom_right = 6
		row.add_theme_stylebox_override("panel", bg2)

	row.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			toggle_fn.call()
	)
	check.toggled.connect(func(pressed):
		row.set_meta("selected", pressed)
		var bg3 = StyleBoxFlat.new()
		bg3.bg_color = Color(0.18, 0.2, 0.3, 0.8) if pressed else Color(0.15, 0.16, 0.28, 0.8)
		bg3.corner_radius_top_left = 6; bg3.corner_radius_top_right = 6
		bg3.corner_radius_bottom_left = 6; bg3.corner_radius_bottom_right = 6
		row.add_theme_stylebox_override("panel", bg3)
	)

	return {"row": row, "cid": cs[0], "check": check}

func _on_cancel():
	if is_instance_valid(_popup):
		_popup.queue_free()

func _on_ok():
	var result: Array[String] = []
	for rd in _check_rows:
		if rd["check"].button_pressed:
			result.append(rd["cid"])
	confirmed.emit(result)
	if is_instance_valid(_popup):
		_popup.queue_free()

func get_selected() -> Array[String]:
	var result: Array[String] = []
	for rd in _check_rows:
		if rd["check"].button_pressed:
			result.append(rd["cid"])
	return result
