extends Control

var _excluded_names: Array = []  # 来自牌组界面：需屏蔽的卡名

func mark_deck_cards(deck_names: Array):
	_excluded_names = deck_names
	call_deferred("_update_card_states")


func _update_card_states():
	# _card_panels 和 _card_names 并行，一一对应
	for i in range(_card_panels.size()):
		var panel = _card_panels[i]
		var name = ""
		if i < _card_names.size():
			name = _card_names[i]
		var is_excluded = name in _excluded_names
		panel.modulate = Color(0.45, 0.45, 0.45, 0.8) if is_excluded else Color(1, 1, 1, 1)
		panel.set_mouse_filter(Control.MOUSE_FILTER_IGNORE if is_excluded else Control.MOUSE_FILTER_STOP)

var _scroll: ScrollContainer
var _grid: GridContainer
var _card_panels: Array = []
var _card_names: Array = []  # 与 _card_panels 并行：对应每张卡的卡名

# 触摸阈值（区分短摸/滚动 与 长按/点击）
const TAP_THRESHOLD: float = 25.0
var _tap_start_pos: Vector2 = Vector2.ZERO
var _last_tapped_panel: Control = null  # 当前按住的卡面板


# ─────────────────────────────────────────
# 构建界面
# ─────────────────────────────────────────

func _enter_tree():
	# 如果是从牌组界面唤起，读取屏蔽卡名列表
	var ps = get_node_or_null("/root/PlayerSave")
	if ps != null and ps.card_sel_excluded.size() > 0:
		_excluded_names = ps.card_sel_excluded.duplicate()
	_build()
	_update_card_states()  # _build 同步创建 UI，可立即调用


func _build():
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0; bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0; vbox.anchor_top = 0.0; vbox.anchor_right = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = 0; vbox.offset_top = 0; vbox.offset_right = 0; vbox.offset_bottom = 0
	add_child(vbox)

	# 导航栏
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.size_flags_vertical = 0
	nav.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(nav)

	var back = Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(70, 70)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(_on_back)
	nav.add_child(back)

	var nav_title = Label.new()
	nav_title.text = "📚 卡册"
	nav_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nav_title.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	nav_title.add_theme_font_size_override("font_size", 48)
	nav.add_child(nav_title)

	vbox.add_child(HSeparator.new())

	# 滚动区域
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.columns = 2
	_grid.add_theme_constant_override("hseparation", 16)
	_grid.add_theme_constant_override("vseparation", 16)
	_scroll.add_child(_grid)

	vbox.add_child(HSeparator.new())

	# 底部返回按钮
	var bottom_row = HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.size_flags_vertical = 0
	bottom_row.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(bottom_row)

	var home_btn = Button.new()
	home_btn.text = "🏠 返回主界面"
	home_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_btn.custom_minimum_size = Vector2(0, 70)
	home_btn.add_theme_font_size_override("font_size", 34)
	home_btn.pressed.connect(_on_back)
	bottom_row.add_child(home_btn)

	_refresh()


# ─────────────────────────────────────────
# 刷新卡牌列表
# ─────────────────────────────────────────

func _refresh():
	for panel in _card_panels:
		panel.queue_free()
	_card_panels.clear()
	_card_names.clear()
	for child in _grid.get_children():
		child.queue_free()

	var dir = DirAccess.open("user://")
	if not dir or not dir.dir_exists("cards"):
		_show_empty()
		return

	dir = DirAccess.open("user://cards/")
	if not dir:
		_show_empty()
		return

	var files = dir.get_files()
	var card_files: Array[String] = []
	for f in files:
		if f.ends_with(".json"):
			card_files.append(f)

	if card_files.size() == 0:
		_show_empty()
		return

	card_files.sort()
	card_files.reverse()

	for fname in card_files:
		var path = "user://cards/" + fname
		var data = _load_card(path)
		if data:
			var panel = _make_card_panel(data, path)
			_grid.add_child(panel)
			_card_panels.append(panel)
			_card_names.append(data.get("name", ""))


func _show_empty():
	var lbl = Label.new()
	lbl.text = "📭 还没有保存的卡牌\n去制作一张吧！"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.add_child(lbl)


# ─────────────────────────────────────────
# 触摸处理：区分短摸（打开详情）/ 滚动
# ─────────────────────────────────────────

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			_tap_start_pos = event.position
			_last_tapped_panel = null
			for i in range(_card_panels.size()):
				var panel = _card_panels[i]
				if panel.get_global_rect().has_point(event.position):
					_last_tapped_panel = panel
					break
		else:
			if _last_tapped_panel != null:
				var dist = (event.position - _tap_start_pos).length()
				if dist <= TAP_THRESHOLD:
					_handle_card_tap()
					# 阻止事件继续传播到 ScrollContainer
					get_viewport().set_input_as_handled()
			_last_tapped_panel = null
			# 未点卡牌时，不拦截事件，让 ScrollContainer 正常滚动

func _handle_card_tap():
	# _last_tapped_panel 是 PanelContainer，从中取出对应卡牌数据
	# 找它在 _card_panels 数组中的索引
	var idx = _card_panels.find(_last_tapped_panel)
	if idx < 0:
		return

	var card_name = ""
	if idx < _card_names.size():
		card_name = _card_names[idx]

	var file_path = "user://cards/" + card_name + ".json"
	var data = _load_card(file_path)
	if data.is_empty():
		return

	_show_card_detail(data, file_path)

	# 如果是从牌组界面唤起（pending_slot >= 0），自动加入牌组
	var ps = get_node_or_null("/root/PlayerSave")
	if ps != null and ps.card_sel_pending_slot >= 0:
		var already_in = false
		for existing in ps.deck_cards:
			if existing == card_name and card_name != "":
				already_in = true
				break
		if not already_in:
			var deck_copy = ps.deck_cards.duplicate()
			while deck_copy.size() <= ps.card_sel_pending_slot:
				deck_copy.append("")
			deck_copy[ps.card_sel_pending_slot] = card_name
			ps.deck_cards = deck_copy
			ps.card_sel_pending_slot = -1
		get_tree().change_scene_to_file(ps.card_sel_return_scene)


func _load_card(path: String) -> Dictionary:
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var json_str = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(json_str) == OK:
		return json.data as Dictionary
	return {}


# ─────────────────────────────────────────
# 创建单张卡牌面板（1:1.4竖版卡牌比例）
# ─────────────────────────────────────────

func _make_card_panel(data: Dictionary, file_path: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 1:1.4 比例：宽度自适应，高度=宽度×1.4
	# 用custom_minimum_size的y作为高度基准，配合size_flags_stretch_ratio
	panel.custom_minimum_size = Vector2(0, 280)  # 高度
	panel.size_flags_stretch_ratio = 1.0

	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.14, 0.22, 1.0)
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.border_color = Color(0.35, 0.35, 0.45)
	s.corner_radius_top_left = 10; s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10; s.corner_radius_bottom_right = 10
	s.content_margin_left = 12; s.content_margin_right = 12
	s.content_margin_top = 12; s.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", s)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	# 顶部：类型图标 + 卡名
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.size_flags_vertical = 0
	header.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(header)

	var icon_lbl = Label.new()
	icon_lbl.text = "⚔️"
	icon_lbl.add_theme_font_size_override("font_size", 40)
	header.add_child(icon_lbl)

	var name_lbl = Label.new()
	var fields_arr: Array = data.get("fields", [])
	var display_name = data.get("name", "未知卡牌")
	if fields_arr.size() > 0:
		display_name = fields_arr[0] + "·" + display_name
	name_lbl.text = display_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 38)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(name_lbl)

	# 属性条
	var stat_row = HBoxContainer.new()
	stat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.size_flags_vertical = 0
	stat_row.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(stat_row)

	var atk = data.get("attack", 0)
	var hp = data.get("health", 0)
	var spd = data.get("speed", 0)
	var stat_lbl = Label.new()
	stat_lbl.text = "⚔️%d  ❤️%d  ⚡%d" % [atk, hp, spd]
	stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_lbl.add_theme_font_size_override("font_size", 32)
	stat_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	stat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stat_row.add_child(stat_lbl)

	# 能量标签
	var energy_lbl = Label.new()
	energy_lbl.text = "💎 %.1f" % data.get("energy", 0.0)
	energy_lbl.add_theme_font_size_override("font_size", 30)
	energy_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	energy_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stat_row.add_child(energy_lbl)

	# 效果展示（核心！）
	var effects_arr: Array = data.get("effects", [])
	if effects_arr.size() > 0:
		var eff_scroll = ScrollContainer.new()
		eff_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eff_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(eff_scroll)

		var eff_vbox = VBoxContainer.new()
		eff_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eff_scroll.add_child(eff_vbox)

		for i in range(effects_arr.size()):
			var eff = effects_arr[i]
			var eff_lbl = Label.new()
			eff_lbl.text = "• %s" % _format_effect_brief(eff)
			eff_lbl.add_theme_font_size_override("font_size", 28)
			eff_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.5))
			eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			eff_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			eff_vbox.add_child(eff_lbl)
	else:
		var no_eff = Label.new()
		no_eff.text = "(无效果)"
		no_eff.add_theme_font_size_override("font_size", 28)
		no_eff.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		no_eff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(no_eff)

	# 不再在这里连 gui_input，改为 _input 全局处理
	return panel


# 字段图标 — 不再需要类型图标，统一用 ⚔️


# 效果简短描述（用于卡面板）
func _format_effect_brief(eff: Dictionary) -> String:
	var trigger_names = {
		"TR01": "主动", "TR02": "入场", "TR03": "离场",
		"TR04": "攻击", "TR05": "被攻击", "TR08": "回合开始", "TR09": "回合结束"
	}
	var action_names = {
		"A01": "伤害", "A02": "恢复", "A03": "破坏",
		"A04": "除外", "A05": "抽牌"
	}
	var target_names = {
		"T01": "自身", "T02": "敌方单体", "T03": "友方单体",
		"T04": "敌方全体", "T05": "友方全体"
	}
	var t = trigger_names.get(eff.get("trigger", ""), "?")
	var a = action_names.get(eff.get("action", {}).get("type", ""), "?")
	var v = eff.get("action", {}).get("value", "?")
	var tg = target_names.get(eff.get("target", {}).get("type", ""), "?")
	return "%s→%s%s→%s" % [t, a, v, tg]


# ─────────────────────────────────────────
# 卡牌详情弹窗
# ─────────────────────────────────────────

func _show_card_detail(data: Dictionary, file_path: String):
	# 半透明遮罩（用ColorRect，不是Panel）
	var overlay = ColorRect.new()
	overlay.z_index = 200
	overlay.anchor_left = 0.0; overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0; overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	add_child(overlay)

	var dialog = PanelContainer.new()
	dialog.z_index = 201
	dialog.anchor_left = 0.5; dialog.anchor_right = 0.5
	dialog.anchor_top = 0.5; dialog.anchor_bottom = 0.5
	dialog.offset_left = -450; dialog.offset_right = 450
	dialog.offset_top = -500; dialog.offset_bottom = 500
	var ds = StyleBoxFlat.new()
	ds.bg_color = Color(0.1, 0.12, 0.2, 0.98)
	ds.border_width_left = 2; ds.border_width_right = 2
	ds.border_width_top = 2; ds.border_width_bottom = 2
	ds.border_color = Color(0.5, 0.5, 0.6)
	ds.corner_radius_top_left = 14; ds.corner_radius_top_right = 14
	ds.corner_radius_bottom_left = 14; ds.corner_radius_bottom_right = 14
	ds.content_margin_left = 20; ds.content_margin_right = 20
	ds.content_margin_top = 20; ds.content_margin_bottom = 20
	dialog.add_theme_stylebox_override("panel", ds)
	overlay.add_child(dialog)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog.add_child(vbox)

	# 标题栏
	var title_row = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_row)

	var icon_lbl = Label.new()
	icon_lbl.text = "⚔️"
	icon_lbl.add_theme_font_size_override("font_size", 52)
	title_row.add_child(icon_lbl)

	var title_lbl = Label.new()
	title_lbl.text = data.get("name", "未知")
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 52)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title_lbl)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(60, 60)
	close_btn.add_theme_font_size_override("font_size", 36)
	close_btn.pressed.connect(func():
		overlay.queue_free()
	)
	title_row.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# 详情滚动区
	var detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(detail_scroll)

	var detail_vbox = VBoxContainer.new()
	detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(detail_vbox)

	# 基本信息
	var fields_arr: Array = data.get("fields", [])
	_add_detail_row(detail_vbox, "🏷️ 字段", "无" if fields_arr.size() == 0 else " ".join(fields_arr))
	var atk = data.get("attack", 0)
	var hp = data.get("health", 0)
	var spd = data.get("speed", 0)
	_add_detail_row(detail_vbox, "⚔️ 属性", "攻击%d / 生命%d / 速度%d" % [atk, hp, spd])
	_add_detail_row(detail_vbox, "⚡ 能量", "%.1f" % data.get("energy", 0.0))

	# 效果列表
	var effects_arr: Array = data.get("effects", [])
	if effects_arr.size() > 0:
		var eff_title = Label.new()
		eff_title.text = "─── 效果 ───"
		eff_title.add_theme_font_size_override("font_size", 38)
		eff_title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
		detail_vbox.add_child(eff_title)

		for i in range(effects_arr.size()):
			var eff = effects_arr[i]
			var eff_lbl = Label.new()
			eff_lbl.text = "%d. %s" % [i + 1, _format_effect_full(eff)]
			eff_lbl.add_theme_font_size_override("font_size", 34)
			eff_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.6))
			eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			detail_vbox.add_child(eff_lbl)

	vbox.add_child(HSeparator.new())

	# 操作按钮
	var btn_row = HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(btn_row)

	var load_btn = Button.new()
	load_btn.text = "📝 加载到制卡器"
	load_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_btn.add_theme_font_size_override("font_size", 34)
	load_btn.pressed.connect(func():
		_load_to_crafter(data)
		overlay.queue_free()
	)
	btn_row.add_child(load_btn)

	var del_btn = Button.new()
	del_btn.text = "🗑️ 删除"
	del_btn.add_theme_font_size_override("font_size", 34)
	del_btn.custom_minimum_size = Vector2(180, 70)
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	del_btn.pressed.connect(func():
		_confirm_delete(data, file_path, overlay)
	)
	btn_row.add_child(del_btn)


func _add_detail_row(parent: VBoxContainer, label_text: String, value_text: String):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	row.add_child(lbl)

	var val = Label.new()
	val.text = value_text
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 36)
	val.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	row.add_child(val)


func _format_effect_full(eff: Dictionary) -> String:
	var trigger_names = {
		"TR01": "主动使用", "TR02": "入场时", "TR03": "离场时",
		"TR04": "攻击时", "TR05": "被攻击时", "TR08": "回合开始时", "TR09": "回合结束时"
	}
	var action_names = {
		"A01": "造成伤害", "A02": "恢复生命", "A03": "破坏",
		"A04": "除外", "A05": "抽牌"
	}
	var target_names = {
		"T01": "自身", "T02": "敌方单体", "T03": "友方单体",
		"T04": "敌方全体", "T05": "友方全体"
	}
	var t = trigger_names.get(eff.get("trigger", ""), "??")
	var a = action_names.get(eff.get("action", {}).get("type", ""), "??")
	var v = eff.get("action", {}).get("value", "?")
	var tg = target_names.get(eff.get("target", {}).get("type", ""), "??")
	var constraints: Array = eff.get("constraints", [])
	var cons_str = ""
	if constraints.size() > 0:
		var cons_names = {
			"CO01": "一回合一次", "CO02": "一局一次", "CO03": "使用后破坏",
			"CO04": "使用后除外", "CO05": "消耗生命", "CO06": "弃手牌",
			"CO07": "消耗能量", "CO08": "仅己方回合", "CO09": "仅对方回合",
			"CO10": "需盖放", "CO11": "需满足条件", "CO12": "非永久",
			"CO13": "不可攻击"
		}
		var parts: Array[String] = []
		for c in constraints:
			parts.append(cons_names.get(c, c))
		cons_str = " [%s]" % " ".join(parts)
	return "%s，对%s%s%s×%s" % [t, tg, a, v, cons_str]


# ─────────────────────────────────────────
# 确认删除
# ─────────────────────────────────────────

func _confirm_delete(data: Dictionary, file_path: String, parent_overlay: Node):
	var confirm_overlay = ColorRect.new()
	confirm_overlay.z_index = 202
	confirm_overlay.anchor_left = 0.0; confirm_overlay.anchor_top = 0.0
	confirm_overlay.anchor_right = 1.0; confirm_overlay.anchor_bottom = 1.0
	confirm_overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	parent_overlay.add_child(confirm_overlay)

	var box = PanelContainer.new()
	box.z_index = 203
	box.anchor_left = 0.5; box.anchor_right = 0.5
	box.anchor_top = 0.5; box.anchor_bottom = 0.5
	box.offset_left = -300; box.offset_right = 300
	box.offset_top = -180; box.offset_bottom = 180
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.12, 0.12, 0.18)
	bs.border_width_left = 2; bs.border_width_right = 2
	bs.border_width_top = 2; bs.border_width_bottom = 2
	bs.border_color = Color(0.8, 0.3, 0.3)
	bs.corner_radius_top_left = 12; bs.corner_radius_top_right = 12
	bs.corner_radius_bottom_left = 12; bs.corner_radius_bottom_right = 12
	bs.content_margin_left = 20; bs.content_margin_right = 20
	bs.content_margin_top = 20; bs.content_margin_bottom = 20
	box.add_theme_stylebox_override("panel", bs)
	confirm_overlay.add_child(box)

	var vbox = VBoxContainer.new()
	box.add_child(vbox)

	var warn_lbl = Label.new()
	warn_lbl.text = "⚠️ 确认删除？"
	warn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_lbl.add_theme_font_size_override("font_size", 44)
	warn_lbl.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	vbox.add_child(warn_lbl)

	var name_lbl = Label.new()
	name_lbl.text = data.get("name", "未知卡牌")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(name_lbl)

	var hint_lbl = Label.new()
	hint_lbl.text = "此操作不可恢复"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 32)
	hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(hint_lbl)

	var btn_row = HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.add_theme_font_size_override("font_size", 34)
	cancel_btn.pressed.connect(func():
		confirm_overlay.queue_free()
	)
	btn_row.add_child(cancel_btn)

	var sure_btn = Button.new()
	sure_btn.text = "确认删除"
	sure_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sure_btn.add_theme_font_size_override("font_size", 34)
	sure_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	sure_btn.pressed.connect(func():
		_delete_card(file_path)
		confirm_overlay.queue_free()
		parent_overlay.queue_free()
	)
	btn_row.add_child(sure_btn)


func _delete_card(file_path: String):
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists(file_path):
		var err = dir.remove(file_path)
		if err == OK:
			_refresh()
			return
	ToastManager.show("❌ 删除失败", true)


# ─────────────────────────────────────────
# 加载到制卡器
# ─────────────────────────────────────────

func _load_to_crafter(data: Dictionary):
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var crafter_scene = ResourceLoader.load("res://scenes/crafter/crafter.tscn", "PackedScene")
	if crafter_scene:
		var crafter = crafter_scene.instantiate()
		get_tree().root.add_child(crafter)
		crafter.load_card_data(data)


# ─────────────────────────────────────────
# 导航
# ─────────────────────────────────────────

func _on_back():
	var ps = get_node_or_null("/root/PlayerSave")
	var return_scene = "res://scenes/main.tscn"
	if ps != null and ps.card_sel_return_scene != "":
		return_scene = ps.card_sel_return_scene
		ps.card_sel_return_scene = ""
		ps.card_sel_pending_slot = -1
		ps.card_sel_excluded.clear()
	queue_free()
	get_tree().change_scene_to_file(return_scene)
