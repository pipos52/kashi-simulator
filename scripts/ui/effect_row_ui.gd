class_name EffectRowUI
extends Node
# EffectRow UI 构建层（所有节点创建代码）

const ALL_CONSTRAINT_NAMES: Dictionary = {
	"CO01": "一回合一次", "CO02": "一局一次", "CO03": "使用后破坏",
	"CO04": "使用后除外", "CO05": "消耗生命", "CO06": "弃手牌",
	"CO07": "消耗能量", "CO08": "仅己方回合", "CO09": "仅对方回合",
	"CO10": "需盖放", "CO11": "需满足条件", "CO12": "非永久",
	"CO13": "不可攻击", "CO14": "不可被攻击"
}

# ── 样式工厂 ──────────────────────────────────

static func flat_style(bg: Color, border_color := Color(0,0,0,0), border_w := 0,
	corner := 6, pad := 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	if border_w > 0:
		s.border_color = border_color
		s.border_width_left = border_w; s.border_width_right = border_w
		s.border_width_top = border_w; s.border_width_bottom = border_w
	s.corner_radius_top_left = corner; s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner; s.corner_radius_bottom_right = corner
	s.content_margin_left = pad; s.content_margin_right = pad
	s.content_margin_top = pad; s.content_margin_bottom = pad
	return s

static func option_popup_style() -> Dictionary:
	var bg = Color(0.15, 0.18, 0.28)
	return {
		"panel_bg": bg, "item_font_size": 56,
		"item_padding_top": 20, "item_padding_bottom": 20,
		"vseparation": 10
	}

static func apply_option_style(opt: OptionButton, font_size: int = 52):
	var bg = Color(0.15, 0.18, 0.28)
	var s = flat_style(bg, Color(0,0,0,0), 0, 6, 12)
	opt.add_theme_stylebox_override("normal", s)
	opt.add_theme_font_size_override("font_size", font_size)
	var pop = opt.get_popup()
	pop.add_theme_font_size_override("font_size", 56)
	pop.add_theme_constant_override("item_padding_top", 20)
	pop.add_theme_constant_override("item_padding_bottom", 20)
	pop.add_theme_constant_override("vseparation", 10)

static func line_style() -> StyleBoxFlat:
	return flat_style(Color(0.15, 0.18, 0.28), Color(0,0,0,0), 0, 6, 10)

# ── 标准行容器 ──────────────────────────────────

static func std_row() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 90)
	return row

static func std_label(text: String, font_size: int = 52) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(100, 0)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl

static func std_spin(minv: int = 1, maxv: int = 99, default: float = 1, fs: int = 56) -> SpinBox:
	var sb = SpinBox.new()
	sb.custom_minimum_size = Vector2(130, 70)
	sb.add_theme_font_size_override("font_size", fs)
	sb.min_value = minv; sb.max_value = maxv
	sb.value = default; sb.step = 1
	var le = sb.get_line_edit()
	if le: le.add_theme_font_size_override("font_size", fs)
	return sb

static func std_line(placeholder: String, min_w: int = 160) -> LineEdit:
	var le = LineEdit.new()
	le.placeholder_text = placeholder
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.custom_minimum_size = Vector2(min_w, 70)
	le.add_theme_font_size_override("font_size", 48)
	le.add_theme_stylebox_override("normal", line_style())
	return le

# ── 选项卡选项填充 ──────────────────────────────────

static func populate_option(opt: OptionButton, items: Array, default_idx: int = 0) -> PopupMenu:
	apply_option_style(opt)
	for i in range(items.size()):
		opt.add_item(items[i][1], i)
		opt.set_item_metadata(i, items[i][0])
	opt.select(default_idx)
	return opt.get_popup()

# ── 触发器行 ──────────────────────────────────

static func build_trigger_row(parent: VBoxContainer, owner,
	trigger_option: OptionButton,
	trigger_counter_type_edit: LineEdit,
	trigger_threshold_spin: SpinBox) -> void:

	var row = std_row()
	parent.add_child(row)
	row.add_child(std_label("触发"))

	var triggers = [
		["TR01", "主动使用"], ["TR02", "入场"], ["TR03", "离场"],
		["TR04", "攻击"], ["TR05", "被攻击"], ["TR08", "回合开始"],
		["TR09", "回合结束"], ["TR16", "指示物变化时"], ["TR17", "指示物达到阈值"],
		["TR18", "敌方发动效果"]
	]
	populate_option(trigger_option, triggers, 1)
	trigger_option.item_selected.connect(owner._on_trigger_changed)
	row.add_child(trigger_option)

	trigger_counter_type_edit.placeholder_text = "指示物类型"
	trigger_counter_type_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trigger_counter_type_edit.custom_minimum_size = Vector2(200, 70)
	trigger_counter_type_edit.add_theme_font_size_override("font_size", 48)
	trigger_counter_type_edit.add_theme_stylebox_override("normal", line_style())
	trigger_counter_type_edit.text_changed.connect(owner._on_data_changed)
	row.add_child(trigger_counter_type_edit)

	trigger_threshold_spin.custom_minimum_size = Vector2(130, 70)
	trigger_threshold_spin.add_theme_font_size_override("font_size", 56)
	trigger_threshold_spin.min_value = 1; trigger_threshold_spin.max_value = 99
	trigger_threshold_spin.value = 5; trigger_threshold_spin.step = 1
	trigger_threshold_spin.value_changed.connect(owner._on_data_changed)
	var le = trigger_threshold_spin.get_line_edit()
	if le: le.add_theme_font_size_override("font_size", 56)
	row.add_child(trigger_threshold_spin)

# ── 条件行 ──────────────────────────────────

static func build_condition_row(parent: VBoxContainer, owner,
	condition_option: OptionButton,
	condition_value: SpinBox,
	condition_field_edit: LineEdit,
	condition_counter_type_edit: LineEdit,
	condition_counter_op_option: OptionButton) -> void:

	var row = std_row()
	parent.add_child(row)
	row.add_child(std_label("条件"))

	var conditions = [
		["C01", "无条件"], ["C02", "生命值≥"], ["C03", "手牌数≥"],
		["C04", "有字段"], ["C13", "指示物数量≥"]
	]
	populate_option(condition_option, conditions)
	condition_option.item_selected.connect(owner._on_condition_changed)
	row.add_child(condition_option)
	row.add_child(condition_value)

	condition_field_edit.placeholder_text = "输入字段名"
	condition_field_edit.text_changed.connect(owner._on_condition_field_changed)
	row.add_child(condition_field_edit)

	condition_counter_type_edit.placeholder_text = "指示物类型"
	condition_counter_type_edit.text_changed.connect(owner._on_condition_field_changed)
	row.add_child(condition_counter_type_edit)

	condition_counter_op_option.custom_minimum_size = Vector2(100, 70)
	condition_counter_op_option.add_theme_font_size_override("font_size", 48)
	condition_counter_op_option.add_theme_stylebox_override("normal", line_style())
	var ops = [[">=", ">="], ["<=", "<="], [">", ">"], ["<", "<"], ["==", "=="]]
	for i in range(ops.size()):
		condition_counter_op_option.add_item(ops[i][1], i)
		condition_counter_op_option.set_item_metadata(i, ops[i][0])
	condition_counter_op_option.select(0)
	condition_counter_op_option.item_selected.connect(owner._on_condition_field_changed)
	row.add_child(condition_counter_op_option)

# ── 动作行 ──────────────────────────────────

static func build_action_row(parent: VBoxContainer, owner,
	action_option: OptionButton,
	action_value: SpinBox,
	action_field_edit: LineEdit,
	action_counter_type_edit: LineEdit) -> void:

	var row = std_row()
	parent.add_child(row)
	row.add_child(std_label("动作"))

	var actions = [
		["A01", "伤害", true], ["A02", "恢复", true], ["A03", "破坏", false],
		["A04", "除外", false], ["A05", "抽牌", true],
		["A08", "特殊召唤(夺取)", false], ["A09", "检索·字段", false],
		["A11", "增减攻击", true], ["A14", "赋予字段", false],
		["A15", "移除字段", false], ["A17", "复制效果", false],
		["A24", "添加指示物", true], ["A25", "移除指示物", true], ["A26", "设定指示物", true]
	]
	populate_option(action_option, actions)
	action_option.item_selected.connect(owner._on_action_changed)
	action_option.item_selected.connect(owner._on_data_changed)
	row.add_child(action_option)
	row.add_child(action_value)

	action_field_edit.placeholder_text = "输入字段名"
	action_field_edit.text_changed.connect(owner._on_data_changed)
	row.add_child(action_field_edit)

	action_counter_type_edit.placeholder_text = "指示物类型"
	action_counter_type_edit.text_changed.connect(owner._on_data_changed)
	row.add_child(action_counter_type_edit)

# ── 目标行 ──────────────────────────────────

static func build_target_row(parent: VBoxContainer, owner,
	target_btn: Button,
	target_option: OptionButton,
	target_field_edit: LineEdit,
	tgt_popup: PopupMenu,
	tgt_all_data: Array) -> void:

	var row = std_row()
	parent.add_child(row)
	row.add_child(std_label("目标"))

	target_btn.text = "敌方全体"
	target_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_btn.custom_minimum_size = Vector2(180, 70)
	var tbs = flat_style(Color(0.15, 0.18, 0.28), Color(0,0,0,0), 0, 6, 12)
	target_btn.add_theme_stylebox_override("normal", tbs)
	target_btn.add_theme_font_size_override("font_size", 52)
	row.add_child(target_btn)

	tgt_popup.add_theme_font_size_override("font_size", 56)
	tgt_popup.add_theme_constant_override("item_padding_top", 20)
	tgt_popup.add_theme_constant_override("item_padding_bottom", 20)
	tgt_popup.add_theme_constant_override("vseparation", 10)
	var tps = flat_style(Color(0.12, 0.14, 0.22), Color(0.4, 0.4, 0.5), 1, 8, 8)
	tgt_popup.add_theme_stylebox_override("panel", tps)

	var tgt_targets = [
		["T01", "自身"], ["T02", "敌方单体"], ["T03", "友方单体"],
		["T04", "敌方全体"], ["T05", "友方全体"],
		["T06", "随机敌方"], ["T07", "随机友方"],
		["T13", "场上指定字段"]
	]
	for i in range(tgt_targets.size()):
		tgt_popup.add_item(tgt_targets[i][1], i)
		tgt_popup.set_item_metadata(i, tgt_targets[i][0])
	tgt_popup.index_pressed.connect(owner._on_target_selected)
	target_btn.pressed.connect(func():
		var r = target_btn.get_global_rect()
		tgt_popup.position = Vector2i(r.position.x, r.end.y)
		tgt_popup.popup()
	)
	row.add_child(tgt_popup)

	target_option.set_meta("selected", "T04")
	target_field_edit.placeholder_text = "输入字段名"
	target_field_edit.text_changed.connect(owner._on_data_changed)
	row.add_child(target_field_edit)

# ── 约束按钮行 ──────────────────────────────────

static func build_constraint_buttons_row(parent: VBoxContainer, owner,
	container: HBoxContainer, constraint_btns: Array[Button],
	add_pressed_cb: Callable) -> void:

	var con_lbl = Label.new()
	con_lbl.text = "约束"
	con_lbl.add_theme_font_size_override("font_size", 52)
	con_lbl.custom_minimum_size = Vector2(0, 60)
	parent.add_child(con_lbl)

	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.custom_minimum_size = Vector2(0, 90)
	parent.add_child(container)

	var add_btn = Button.new()
	add_btn.text = "➕ 添加约束"
	add_btn.custom_minimum_size = Vector2(200, 70)
	add_btn.size_flags_horizontal = 0
	add_btn.add_theme_font_size_override("font_size", 44)
	var abs = flat_style(Color(0.2, 0.25, 0.4), Color(0.4, 0.5, 0.8), 2, 8, 8)
	add_btn.add_theme_stylebox_override("normal", abs)
	add_btn.pressed.connect(add_pressed_cb)
	container.add_child(add_btn)

	for btn in constraint_btns:
		container.add_child(btn)

# ── 底部按钮行 ──────────────────────────────────

static func build_action_buttons(parent: VBoxContainer,
	delete_cb: Callable, copy_cb: Callable) -> void:

	var btn_row = HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.custom_minimum_size = Vector2(0, 110)
	parent.add_child(btn_row)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var del = Button.new()
	del.text = "删除"
	del.custom_minimum_size = Vector2(200, 90)
	del.add_theme_font_size_override("font_size", 56)
	del.pressed.connect(delete_cb)
	btn_row.add_child(del)

	var copy = Button.new()
	copy.text = "复制"
	copy.custom_minimum_size = Vector2(200, 90)
	copy.add_theme_font_size_override("font_size", 56)
	copy.pressed.connect(copy_cb)
	btn_row.add_child(copy)

# ── 约束按钮样式 ──────────────────────────────────

static func update_constraint_btn_style(btn: Button, pressed: bool):
	var s = StyleBoxFlat.new()
	if pressed:
		s.bg_color = Color(0.9, 0.6, 0.1, 1.0)
		s.border_color = Color(1.0, 0.8, 0.2, 1.0)
	else:
		s.bg_color = Color(0.15, 0.15, 0.22, 1.0)
		s.border_color = Color(0.5, 0.5, 0.6, 1.0)
	s.border_width_left = 3; s.border_width_right = 3
	s.border_width_top = 3; s.border_width_bottom = 3
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", s)
	btn.add_theme_stylebox_override("pressed", s)

# ── Header 样式 ──────────────────────────────────

static func header_style() -> StyleBoxFlat:
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.12, 0.12, 0.18, 1.0)
	hs.border_color = Color(0.3, 0.3, 0.4, 1.0)
	hs.border_width_left = 1; hs.border_width_right = 1
	hs.border_width_top = 1; hs.border_width_bottom = 1
	hs.corner_radius_top_left = 4; hs.corner_radius_top_right = 4
	hs.corner_radius_bottom_left = 4; hs.corner_radius_bottom_right = 4
	hs.content_margin_left = 12; hs.content_margin_right = 12
	hs.content_margin_top = 10; hs.content_margin_bottom = 10
	return hs
