# material.gd
# 阶段2：材料准备界面（纯代码UI）
# 不再金币购买，改为从背包选择
extends Control

# 当前选择
var _selected_paper: String = "PG00"
var _selected_ink: String = "INK00"
var _selected_core: String = "EC04"
var _selected_aux: Array[String] = []

# 当前选中显示标签（用于刷新）
var _paper_sel_lbl: Label = null
var _ink_sel_lbl: Label = null
var _core_sel_lbl: Label = null
var _aux_sel_lbl: Label = null

var _paper_add_btn: Button = null
var _ink_add_btn: Button = null
var _core_add_btn: Button = null
var _aux_add_btn: Button = null

var _next_btn: Button = null


func _enter_tree():
	_build()


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
	vbox.add_child(_make_nav("🎨 材料准备"))
	vbox.add_child(HSeparator.new())

	# 滚动区域
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)

	# 说明
	var hint = Label.new()
	hint.text = "选择制作卡牌所需的材料\n从背包中选择，或使用默认材料"
	hint.add_theme_font_size_override("font_size", 32)
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)
	content.add_child(_sp(8))

	# ── 卡纸 ──
	content.add_child(_section_title("📄 卡纸（影响能量上限）"))
	content.add_child(_make_material_row("paper", "PG00", "不使用卡纸（默认）"))
	content.add_child(_sp(8))

	# ── 墨线 ──
	content.add_child(_section_title("🖌️ 墨线（影响品质加成）"))
	content.add_child(_make_material_row("ink", "INK00", "不使用墨线（默认）"))
	content.add_child(_sp(8))

	# ── 能量核 ──
	content.add_child(_section_title("💎 能量核（影响属性加成）"))
	content.add_child(_make_material_row("core", "EC04", "中立核（无消耗）"))
	content.add_child(_sp(8))

	# ── 辅材 ──
	content.add_child(_section_title("⚗️ 辅材（可选）"))
	content.add_child(_make_aux_row())
	content.add_child(_sp(16))

	vbox.add_child(HSeparator.new())

	# ── 底部按钮 ──
	var bottom = HBoxContainer.new()
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.size_flags_vertical = 0
	bottom.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(bottom)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)

	_next_btn = Button.new()
	_next_btn.text = "下一步 →"
	_next_btn.custom_minimum_size = Vector2(220, 70)
	_next_btn.add_theme_font_size_override("font_size", 34)
	_next_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.2, 0.5, 0.85)
	ns.corner_radius_top_left = 8; ns.corner_radius_top_right = 8
	ns.corner_radius_bottom_left = 8; ns.corner_radius_bottom_right = 8
	_next_btn.add_theme_stylebox_override("normal", ns)
	var ns2 = ns.duplicate()
	ns2.bg_color = Color(0.15, 0.4, 0.7)
	_next_btn.add_theme_stylebox_override("pressed", ns2)
	_next_btn.pressed.connect(_on_next)
	bottom.add_child(_next_btn)


# ─────────────────────────────────────────
# 材料行（选择按钮 + 当前选中显示）
# ─────────────────────────────────────────

func _make_material_row(mat_type: String, default_id: String, default_name: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 130)

	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.12, 0.14, 0.22)
	ns.border_width_left = 2; ns.border_width_right = 2
	ns.border_width_top = 2; ns.border_width_bottom = 2
	ns.border_color = Color(0.3, 0.3, 0.45)
	ns.corner_radius_top_left = 10; ns.corner_radius_top_right = 10
	ns.corner_radius_bottom_left = 10; ns.corner_radius_bottom_right = 10
	ns.content_margin_left = 16; ns.content_margin_right = 16
	ns.content_margin_top = 12; ns.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ns)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)

	# 左侧：当前选中
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var cur_lbl = Label.new()
	cur_lbl.text = "当前: " + default_name
	cur_lbl.add_theme_font_size_override("font_size", 38)
	cur_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	info.add_child(cur_lbl)

	var hint_lbl = Label.new()
	hint_lbl.text = "点击右侧按钮从背包选择"
	hint_lbl.add_theme_font_size_override("font_size", 28)
	hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
	info.add_child(hint_lbl)

	# 右侧：添加按钮
	var add_btn = Button.new()
	add_btn.text = "+ 添加"
	add_btn.custom_minimum_size = Vector2(160, 70)
	add_btn.add_theme_font_size_override("font_size", 34)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.15, 0.25, 0.15)
	bs.border_width_left = 2; bs.border_width_right = 2
	bs.border_width_top = 2; bs.border_width_bottom = 2
	bs.border_color = Color(0.3, 0.8, 0.3)
	bs.corner_radius_top_left = 8; bs.corner_radius_top_right = 8
	bs.corner_radius_bottom_left = 8; bs.corner_radius_bottom_right = 8
	add_btn.add_theme_stylebox_override("normal", bs)
	var bs2 = bs.duplicate()
	bs2.bg_color = Color(0.1, 0.2, 0.1)
	add_btn.add_theme_stylebox_override("pressed", bs2)
	add_btn.pressed.connect(_on_add_click.bind(mat_type))
	hbox.add_child(add_btn)

	# 记录引用
	match mat_type:
		"paper": _paper_sel_lbl = cur_lbl; _paper_add_btn = add_btn
		"ink": _ink_sel_lbl = cur_lbl; _ink_add_btn = add_btn
		"core": _core_sel_lbl = cur_lbl; _core_add_btn = add_btn

	return panel


func _make_aux_row() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 130)

	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.12, 0.14, 0.22)
	ns.border_width_left = 2; ns.border_width_right = 2
	ns.border_width_top = 2; ns.border_width_bottom = 2
	ns.border_color = Color(0.3, 0.3, 0.45)
	ns.corner_radius_top_left = 10; ns.corner_radius_top_right = 10
	ns.corner_radius_bottom_left = 10; ns.corner_radius_bottom_right = 10
	ns.content_margin_left = 16; ns.content_margin_right = 16
	ns.content_margin_top = 12; ns.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ns)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	_aux_sel_lbl = Label.new()
	_aux_sel_lbl.text = "当前: 不使用辅材"
	_aux_sel_lbl.add_theme_font_size_override("font_size", 38)
	_aux_sel_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	info.add_child(_aux_sel_lbl)

	var hint_lbl = Label.new()
	hint_lbl.text = "点击右侧按钮从背包选择"
	hint_lbl.add_theme_font_size_override("font_size", 28)
	hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
	info.add_child(hint_lbl)

	_aux_add_btn = Button.new()
	_aux_add_btn.text = "+ 添加"
	_aux_add_btn.custom_minimum_size = Vector2(160, 70)
	_aux_add_btn.add_theme_font_size_override("font_size", 34)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.15, 0.25, 0.15)
	bs.border_width_left = 2; bs.border_width_right = 2
	bs.border_width_top = 2; bs.border_width_bottom = 2
	bs.border_color = Color(0.3, 0.8, 0.3)
	bs.corner_radius_top_left = 8; bs.corner_radius_top_right = 8
	bs.corner_radius_bottom_left = 8; bs.corner_radius_bottom_right = 8
	_aux_add_btn.add_theme_stylebox_override("normal", bs)
	var bs2 = bs.duplicate()
	bs2.bg_color = Color(0.1, 0.2, 0.1)
	_aux_add_btn.add_theme_stylebox_override("pressed", bs2)
	_aux_add_btn.pressed.connect(_on_add_click.bind("aux"))
	hbox.add_child(_aux_add_btn)

	return panel


# ─────────────────────────────────────────
# 背包选择
# ─────────────────────────────────────────

func _on_add_click(mat_type: String):
	var backpack = Control.new()
	backpack.set_script(load("res://scripts/ui/backpack_gui.gd"))
	
	get_tree().root.add_child(backpack)
	backpack.open(mat_type)
	backpack.material_selected.connect(_on_material_selected)


func _on_material_selected(mat_type: String, mat_id: String):
	match mat_type:
		"paper":
			_selected_paper = mat_id
			_update_paper_label()
		"ink":
			_selected_ink = mat_id
			_update_ink_label()
		"core":
			_selected_core = mat_id
			_update_core_label()
		"aux":
			if mat_id == "AU03":
				_selected_aux.clear()
			else:
				_selected_aux = [mat_id]
			_update_aux_label()


func _update_paper_label():
	var name = _get_item_name("paper", _selected_paper)
	_paper_sel_lbl.text = "当前: " + name
	_paper_sel_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))


func _update_ink_label():
	var name = _get_item_name("ink", _selected_ink)
	_ink_sel_lbl.text = "当前: " + name
	_ink_sel_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))


func _update_core_label():
	var name = _get_item_name("core", _selected_core)
	_core_sel_lbl.text = "当前: " + name
	_core_sel_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))


func _update_aux_label():
	if _selected_aux.is_empty():
		_aux_sel_lbl.text = "当前: 不使用辅材"
		_aux_sel_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	else:
		var name = _get_item_name("aux", _selected_aux[0])
		_aux_sel_lbl.text = "当前: " + name
		_aux_sel_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))


func _get_item_name(mat_type: String, mat_id: String) -> String:
	match mat_type:
		"paper":
			if mat_id == "PG00": return "不使用卡纸（默认）"
			for wc in PlayerSave.owned_white_cards:
				if wc.get("id", "") == mat_id:
					return wc.get("name", "白卡")
			return mat_id
		"ink":
			if mat_id == "INK00": return "不使用墨线（默认）"
			for ik in PlayerSave.owned_inks:
				if ik.get("id", "") == mat_id:
					return ik.get("name", "墨线")
			return mat_id
		"core":
			var cores = MaterialData.get_energy_cores()
			for ec in cores:
				if ec["id"] == mat_id: return ec["name"]
			return mat_id
		"aux":
			if mat_id == "AU03": return "不使用辅材"
			var auxs = MaterialData.get_aux_materials()
			for a in auxs:
				if a["id"] == mat_id: return a["name"]
			return mat_id
	return mat_id


# ─────────────────────────────────────────
# 下一步
# ─────────────────────────────────────────

func _on_next():
	var materials = {
		"paper": _selected_paper,
		"ink": _selected_ink,
		"core": _selected_core,
		"aux": _selected_aux.duplicate()
	}
	CraftManager.start_bottom_draw(materials)


# ─────────────────────────────────────────
# UI 构建辅助
# ─────────────────────────────────────────

func _make_nav(title: String) -> HBoxContainer:
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.size_flags_vertical = 0
	nav.custom_minimum_size = Vector2(0, 70)

	var back = Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(70, 70)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/crafter/crafter.tscn")
	)
	nav.add_child(back)

	var lbl = Label.new()
	lbl.text = title
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	lbl.add_theme_font_size_override("font_size", 48)
	nav.add_child(lbl)

	var spacer_nav = Control.new()
	spacer_nav.custom_minimum_size = Vector2(70, 0)
	nav.add_child(spacer_nav)

	return nav


func _section_title(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 1.0))
	return lbl


func _sp(h: int) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
