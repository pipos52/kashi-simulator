# effect_row.gd
# 可折叠、可增删复制、可配置参数的效果行控制器
# UI 构建委托给 EffectRowUI 静态方法
extends Control

signal removed
signal copied
signal data_changed

# UI节点
var header: PanelContainer
var expand_icon: Label
var summary_label: Label
var content: VBoxContainer

# 触发
var trigger_option: OptionButton
var trigger_counter_type_edit: LineEdit
var trigger_threshold_spin: SpinBox

# 条件
var condition_option: OptionButton
var condition_value: SpinBox
var condition_field_edit: LineEdit
var condition_counter_type_edit: LineEdit
var condition_counter_op_option: OptionButton

# 动作
var action_option: OptionButton
var action_value: SpinBox
var action_field_edit: LineEdit
var action_counter_type_edit: LineEdit

# 目标
var target_btn: Button
var target_option: OptionButton
var target_field_edit: LineEdit
var _tgt_popup: PopupMenu
var _tgt_all_data: Array = []

# 约束
var _constraint_btns: Array[Button] = []
var _constraint_btn_container: HBoxContainer

var effect_index: int = 0
var is_expanded: bool = true

func _init():
	_build()

func _build():
	var root = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	header = PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", EffectRowUI.header_style())
	header.gui_input.connect(_on_header_click)
	root.add_child(header)

	var hh = HBoxContainer.new()
	header.add_child(hh)

	expand_icon = Label.new()
	expand_icon.text = "▼"
	expand_icon.add_theme_font_size_override("font_size", 56)
	expand_icon.add_theme_color_override("font_color", Color(0.7, 0.7, 1, 1))
	expand_icon.custom_minimum_size = Vector2(50, 0)
	hh.add_child(expand_icon)

	summary_label = Label.new()
	summary_label.text = "效果1: 入场 无条件 伤害 2 敌方全体"
	summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_label.add_theme_font_size_override("font_size", 60)
	summary_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5, 1))
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hh.add_child(summary_label)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	_setup_options()
	_setup_constraints()
	_setup_buttons()
	_update_summary()
	_refresh_field_visibility()

func _setup_options():
	trigger_option = OptionButton.new()
	trigger_counter_type_edit = LineEdit.new()
	trigger_threshold_spin = SpinBox.new()
	EffectRowUI.build_trigger_row(content, self, trigger_option,
		trigger_counter_type_edit, trigger_threshold_spin)

	condition_option = OptionButton.new()
	condition_value = EffectRowUI.std_spin(1, 99, 1)
	condition_field_edit = EffectRowUI.std_line("输入字段名")
	condition_counter_type_edit = EffectRowUI.std_line("指示物类型")
	condition_counter_op_option = OptionButton.new()
	EffectRowUI.build_condition_row(content, self, condition_option,
		condition_value, condition_field_edit, condition_counter_type_edit,
		condition_counter_op_option)

	action_option = OptionButton.new()
	action_value = EffectRowUI.std_spin(1, 99, 2)
	action_field_edit = EffectRowUI.std_line("输入字段名")
	action_counter_type_edit = EffectRowUI.std_line("指示物类型")
	EffectRowUI.build_action_row(content, self, action_option,
		action_value, action_field_edit, action_counter_type_edit)

	_tgt_popup = PopupMenu.new()
	EffectRowUI.build_target_row(content, self, target_btn, target_option,
		target_field_edit, _tgt_popup, _tgt_all_data)

func _setup_constraints():
	_constraint_btn_container = HBoxContainer.new()
	EffectRowUI.build_constraint_buttons_row(content, self,
		_constraint_btn_container, _constraint_btns, _on_add_constraint)
	for btn in _constraint_btns:
		_constraint_btn_container.add_child(btn)

func _setup_buttons():
	EffectRowUI.build_action_buttons(content, _on_delete, _on_copy)

# ── 字段可见性 ──────────────────────────────────

func _refresh_field_visibility():
	var t_type = trigger_option.get_selected_metadata()
	trigger_counter_type_edit.visible = CardEffect.trigger_has_counter_type(t_type)
	trigger_threshold_spin.visible = CardEffect.trigger_has_threshold(t_type)

	var c_type = condition_option.get_selected_metadata()
	condition_value.visible = (c_type in ["C02", "C03", "C13"])
	condition_field_edit.visible = (c_type == "C04")
	condition_counter_type_edit.visible = CardEffect.condition_has_counter_type(c_type)
	condition_counter_op_option.visible = CardEffect.condition_has_counter_type(c_type)

	var a_type = action_option.get_selected_metadata()
	action_value.visible = CardEffect.action_has_value(a_type)
	action_field_edit.visible = CardEffect.action_has_field(a_type)
	action_counter_type_edit.visible = CardEffect.action_has_counter_type(a_type)

	var tg_type = target_option.get_meta("selected")
	target_field_edit.visible = CardEffect.target_has_field(tg_type)

# ── 约束 ──────────────────────────────────

func _on_add_constraint():
	var selected_ids: Array[String] = []
	for btn in _constraint_btns:
		if btn.button_pressed:
			selected_ids.append(btn.get_meta("id"))
	var sel = load("res://scripts/ui/constraint_selector.gd").new(selected_ids)
	sel.confirmed.connect(_on_constraints_confirmed)
	get_tree().root.add_child(sel)
	sel.build()

func _on_constraints_confirmed(selected_ids: Array[String]):
	for btn in _constraint_btns.duplicate():
		_sync_constraint_btns(btn.get_meta("id"), false)
	for cid in selected_ids:
		_sync_constraint_btns(cid, true)
	_on_data_changed()

func _sync_constraint_btns(constraint_id: String, selected: bool):
	if selected:
		var exists = _constraint_btns.any(func(b): return b.get_meta("id") == constraint_id)
		if not exists:
			var new_btn = _make_constraint_btn_only(constraint_id,
				EffectRowUI.ALL_CONSTRAINT_NAMES.get(constraint_id, constraint_id))
			var add_btn_idx = -1
			for i in range(_constraint_btn_container.get_child_count()):
				var ch = _constraint_btn_container.get_child(i)
				if ch is Button and "添加约束" in ch.text:
					add_btn_idx = i; break
			if add_btn_idx >= 0:
				_constraint_btn_container.add_child(new_btn)
				_constraint_btn_container.move_child(new_btn, add_btn_idx)
			else:
				_constraint_btn_container.add_child(new_btn)
	else:
		for btn in _constraint_btns:
			if btn.get_meta("id") == constraint_id:
				_constraint_btn_container.remove_child(btn)
				btn.queue_free()
				_constraint_btns.erase(btn)
				break

func _make_constraint_btn_only(id: String, text: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(70, 70)
	btn.set_toggle_mode(true)
	btn.button_pressed = true
	btn.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			EffectRowUI.update_constraint_btn_style(btn, btn.button_pressed)
			_on_data_changed()
			if not btn.button_pressed:
				_constraint_btn_container.remove_child(btn)
				btn.queue_free()
				_constraint_btns.erase(btn)
	)
	EffectRowUI.update_constraint_btn_style(btn, true)
	btn.set_meta("id", id)
	_constraint_btns.append(btn)
	return btn

# ── 目标选择 ──────────────────────────────────

func _on_target_selected(idx: int):
	target_btn.text = _tgt_popup.get_item_text(idx)
	target_option.set_meta("selected", _tgt_popup.get_item_metadata(idx))
	_refresh_field_visibility()
	_on_data_changed()
	var a_type = action_option.get_selected_metadata()
	if a_type == "A09":
		_update_target_popup_for_A09()

func _update_target_popup_for_A09():
	_tgt_popup.clear()
	var filtered = [["T11", "卡组"], ["T10", "墓地"], ["T14", "除外区"]]
	for i in range(filtered.size()):
		_tgt_popup.add_item(filtered[i][1], i)
		_tgt_popup.set_item_metadata(i, filtered[i][0])
	_tgt_popup.index_pressed.connect(_on_target_selected)

# ── 信号处理 ──────────────────────────────────

func _on_header_click(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_expanded = not is_expanded
		content.visible = is_expanded
		expand_icon.text = "▼" if is_expanded else "▶"

func _on_trigger_changed(_idx: int):
	_refresh_field_visibility()
	_on_data_changed()

func _on_condition_changed(_idx: int):
	_refresh_field_visibility()
	_on_data_changed()

func _on_condition_field_changed(_txt: String):
	_on_data_changed()

func _on_action_changed(_idx: int):
	var id = action_option.get_selected_metadata()
	action_value.visible = CardEffect.action_has_value(id)
	action_field_edit.visible = CardEffect.action_has_field(id)
	action_counter_type_edit.visible = CardEffect.action_has_counter_type(id)
	if id == "A09":
		_update_target_popup_for_A09()
	else:
		_tgt_popup.clear()
		for i in range(_tgt_all_data.size()):
			_tgt_popup.add_item(_tgt_all_data[i][1], i)
			_tgt_popup.set_item_metadata(i, _tgt_all_data[i][0])
		_tgt_popup.index_pressed.connect(_on_target_selected)
	_refresh_field_visibility()
	_on_data_changed()

func _on_data_changed(_val = null):
	_update_summary()
	data_changed.emit()

func _update_summary():
	var ti = trigger_option.selected
	var trigger_name = trigger_option.get_item_text(ti) if ti >= 0 else "?"
	var t_type = trigger_option.get_selected_metadata()
	var t_ctr = trigger_counter_type_edit.text.strip_edges()
	if CardEffect.trigger_has_counter_type(t_type) and t_ctr != "":
		trigger_name += "[%s]" % t_ctr
		if CardEffect.trigger_has_threshold(t_type):
			trigger_name += "阈%d" % int(trigger_threshold_spin.value)

	var ci = condition_option.selected
	var cond_name = condition_option.get_item_text(ci) if ci >= 0 else "?"
	var c_type = condition_option.get_selected_metadata()
	if c_type == "C04" and condition_field_edit.text.strip_edges() != "":
		cond_name += "[%s]" % condition_field_edit.text.strip_edges()
	elif c_type == "C13":
		var c_ctr = condition_counter_type_edit.text.strip_edges()
		var c_op = condition_counter_op_option.get_item_text(
			condition_counter_op_option.selected) if condition_counter_op_option.selected >= 0 else ">="
		cond_name = "「%s」%s%d" % [c_ctr, c_op, int(condition_value.value)] if c_ctr != "" else "指示物%s%d" % [c_op, int(condition_value.value)]

	var ai = action_option.selected
	var act_name = action_option.get_item_text(ai) if ai >= 0 else "?"
	var a_type = action_option.get_selected_metadata()
	var a_ctr = action_counter_type_edit.text.strip_edges()
	if CardEffect.action_has_counter_type(a_type) and a_ctr != "":
		act_name = action_option.get_item_text(ai) + "[%s]" % a_ctr
	elif CardEffect.action_has_field(a_type) and action_field_edit.text.strip_edges() != "":
		act_name += "[%s]" % action_field_edit.text.strip_edges()
	var av = int(action_value.value) if action_value.visible else 0

	var tgt_type = target_option.get_meta("selected")
	var tgt_name = CardEffect._target_name(tgt_type)
	if CardEffect.target_has_field(tgt_type) and target_field_edit.text.strip_edges() != "":
		tgt_name = "场上[%s]" % target_field_edit.text.strip_edges()

	summary_label.text = "效果%d: %s %s %s %d %s" % [
		effect_index + 1, trigger_name, cond_name, act_name, av, tgt_name]

func _on_delete():
	removed.emit()
	queue_free()

func _on_copy():
	copied.emit()

func set_index(idx: int):
	effect_index = idx
	_update_summary()

# ── 数据读写 ──────────────────────────────────

func get_effect_data() -> Dictionary:
	var cons: Array = []
	for btn in _constraint_btns:
		if btn.button_pressed:
			cons.append(btn.get_meta("id"))
	return {
		"trigger": trigger_option.get_selected_metadata(),
		"counter_type": trigger_counter_type_edit.text.strip_edges(),
		"threshold": int(trigger_threshold_spin.value),
		"condition": {
			"type": condition_option.get_selected_metadata(),
			"field": condition_field_edit.text.strip_edges(),
			"value": int(condition_value.value),
			"counter_type": condition_counter_type_edit.text.strip_edges(),
			"op": condition_counter_op_option.get_item_metadata(condition_counter_op_option.selected)
		},
		"action": {
			"type": action_option.get_selected_metadata(),
			"value": int(action_value.value),
			"field": action_field_edit.text.strip_edges(),
			"counter_type": action_counter_type_edit.text.strip_edges()
		},
		"target": {
			"type": target_option.get_meta("selected"),
			"field": target_field_edit.text.strip_edges()
		},
		"constraints": cons
	}

func load_from_data(data: Dictionary, idx: int):
	effect_index = idx
	var trig = data.get("trigger", "TR02")
	for i in range(trigger_option.item_count):
		if trigger_option.get_item_metadata(i) == trig:
			trigger_option.select(i); break
	trigger_counter_type_edit.text = data.get("counter_type", "")
	trigger_threshold_spin.value = data.get("threshold", 5)

	var cd = data.get("condition", {})
	var c_type = cd.get("type", "C01")
	for i in range(condition_option.item_count):
		if condition_option.get_item_metadata(i) == c_type:
			condition_option.select(i); break
	condition_value.value = cd.get("value", 1)
	condition_field_edit.text = cd.get("field", "")
	condition_counter_type_edit.text = cd.get("counter_type", "")
	var c_op = cd.get("op", ">=")
	for i in range(condition_counter_op_option.item_count):
		if condition_counter_op_option.get_item_metadata(i) == c_op:
			condition_counter_op_option.select(i); break

	var act = data.get("action", {})
	var act_type = act.get("type", "A01")
	for i in range(action_option.item_count):
		if action_option.get_item_metadata(i) == act_type:
			action_option.select(i); break
	action_value.value = act.get("value", 2)
	action_field_edit.text = act.get("field", "")
	action_counter_type_edit.text = act.get("counter_type", "")

	var tgt = data.get("target", {})
	var tgt_type = tgt.get("type", "T04")
	target_option.set_meta("selected", tgt_type)
	for i in range(_tgt_popup.get_item_count()):
		if _tgt_popup.get_item_metadata(i) == tgt_type:
			target_btn.text = _tgt_popup.get_item_text(i); break
	target_field_edit.text = tgt.get("field", "")

	for cid in data.get("constraints", []):
		_sync_constraint_btns(cid, true)
	_refresh_field_visibility()
	_update_summary()
