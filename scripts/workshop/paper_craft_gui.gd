extends Control

# 状态机: "select" -> "game" -> "result"
var _state: String = "select"
var _selected_materials: Array[String] = []  # 选中的素材ID列表
var _minigame_score: int = 0  # 0-3
var _result_props: Dictionary = {}

# UI 引用
var _content: VBoxContainer
var _game_scroll: ScrollContainer
var _nav: HBoxContainer
var _title_lbl: Label
var _hint_lbl: Label
var _btn_start: Button
var _btn_confirm: Button
var _btn_back: Button

# 小游戏参数
var _pulp_value: float = 0.0
var _pulp_dir: int = 1
var _pressure_value: float = 0.0
var _pressure_dir: int = 1
var _temp_value: float = 50.0

func _enter_tree():
	_build()
	_show_material_select()

func _build():
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0
	bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0; vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = 0; vbox.offset_top = 0
	vbox.offset_right = 0; vbox.offset_bottom = 0
	add_child(vbox)
	
	_nav = _make_nav()
	vbox.add_child(_nav)
	vbox.add_child(HSeparator.new())
	
	_title_lbl = Label.new()
	_title_lbl.text = "造纸工坊"
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_lbl.add_theme_font_size_override("font_size", 42)
	_title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 1.0))
	vbox.add_child(_title_lbl)
	
	_hint_lbl = Label.new()
	_hint_lbl.text = "选择2-4个素材来造纸"
	_hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_lbl.add_theme_font_size_override("font_size", 28)
	_hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(_hint_lbl)
	
	_game_scroll = ScrollContainer.new()
	_game_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_game_scroll)
	
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	_game_scroll.add_child(_content)
	
	vbox.add_child(HSeparator.new())
	
	_btn_confirm = Button.new()
	_btn_confirm.text = "确认素材"
	_btn_confirm.custom_minimum_size = Vector2(0, 80)
	_btn_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_confirm.add_theme_font_size_override("font_size", 40)
	_btn_confirm.disabled = true
	var css = StyleBoxFlat.new()
	css.bg_color = Color(0.15, 0.4, 0.15)
	css.corner_radius_top_left = 8; css.corner_radius_top_right = 8
	css.corner_radius_bottom_left = 8; css.corner_radius_bottom_right = 8
	_btn_confirm.add_theme_stylebox_override("normal", css)
	_btn_confirm.pressed.connect(_on_confirm_materials)
	vbox.add_child(_btn_confirm)
	
	_btn_start = Button.new()
	_btn_start.set_meta("is_start_btn", true)
	_btn_start.text = "开始造纸"
	_btn_start.visible = false
	_btn_start.custom_minimum_size = Vector2(0, 80)
	_btn_start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_start.add_theme_font_size_override("font_size", 42)
	var nss = StyleBoxFlat.new()
	nss.bg_color = Color(0.2, 0.5, 0.85)
	nss.corner_radius_top_left = 8; nss.corner_radius_top_right = 8
	nss.corner_radius_bottom_left = 8; nss.corner_radius_bottom_right = 8
	_btn_start.add_theme_stylebox_override("normal", nss)
	_btn_start.pressed.connect(_on_start_game)
	vbox.add_child(_btn_start)
	
	_btn_back = Button.new()
	_btn_back.text = "返回"
	_btn_back.custom_minimum_size = Vector2(0, 70)
	_btn_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_back.add_theme_font_size_override("font_size", 36)
	var bss = StyleBoxFlat.new()
	bss.bg_color = Color(0.2, 0.2, 0.3)
	bss.corner_radius_top_left = 8; bss.corner_radius_top_right = 8
	bss.corner_radius_bottom_left = 8; bss.corner_radius_bottom_right = 8
	_btn_back.add_theme_stylebox_override("normal", bss)
	_btn_back.pressed.connect(_on_back)
	vbox.add_child(_btn_back)

func _make_nav() -> HBoxContainer:
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.custom_minimum_size = Vector2(0, 70)
	
	var back = Button.new()
	back.text = "<"
	back.custom_minimum_size = Vector2(70, 70)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(_on_back)
	nav.add_child(back)
	
	var lbl = Label.new()
	lbl.text = "造纸工坊"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	lbl.add_theme_font_size_override("font_size", 48)
	nav.add_child(lbl)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(70, 0)
	nav.add_child(spacer)
	
	return nav

# ─────────────────────────────────────────
# 阶段1: 素材选择
# ─────────────────────────────────────────

func _show_material_select():
	_state = "select"
	_title_lbl.text = "造纸工坊"
	_hint_lbl.text = "选择2-4个素材来造纸"
	_btn_confirm.visible = true
	_btn_confirm.disabled = true
	_btn_start.visible = false
	
	# 清空内容
	for c in _content.get_children():
		c.queue_free()
	
	# 收集玩家拥有的素材
	var owned: Array[Dictionary] = []
	for mid in PlayerSave.material_inventory:
		var cnt = PlayerSave.get_material_count(mid)
		if cnt > 0:
			var m = MaterialData.get_material(mid)
			if not m.is_empty():
				owned.append({"id": mid, "count": cnt, "data": m})
	
	if owned.is_empty():
		var empty = Label.new()
		empty.text = "没有可用的素材\n先去探险收集素材吧!"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 32)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		_content.add_child(empty)
		return
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("hseparation", 12)
	grid.add_theme_constant_override("vseparation", 12)
	_content.add_child(grid)
	
	for item in owned:
		var m = item["data"]
		var card = _make_material_card(m, item["count"])
		grid.add_child(card)

func _make_material_card(m: Dictionary, count: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 140)
	panel.set_meta("material_id", m["id"])
	
	var rarity_colors = [
		Color(0.5, 0.5, 0.5),  # 普通
		Color(0.2, 0.6, 1.0),   # 稀有
		Color(0.7, 0.3, 1.0),   # 史诗
		Color(1.0, 0.7, 0.1)   # 传说
	]
	var rc = rarity_colors[clampi(m["rarity"] - 1, 0, 3)]
	
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.1, 0.12, 0.18)
	s.border_width_left = 3; s.border_width_right = 3
	s.border_width_top = 3; s.border_width_bottom = 3
	s.border_color = rc * Color(0.5, 0.5, 0.5)
	s.corner_radius_top_left = 10; s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10; s.corner_radius_bottom_right = 10
	s.content_margin_left = 12; s.content_margin_right = 12
	s.content_margin_top = 10; s.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", s)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	var top = HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top)
	
	var name_lbl = Label.new()
	name_lbl.text = m["name"]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.add_theme_color_override("font_color", rc)
	top.add_child(name_lbl)
	
	var count_lbl = Label.new()
	count_lbl.text = "x%d" % count
	count_lbl.add_theme_font_size_override("font_size", 28)
	count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	top.add_child(count_lbl)
	
	var stats = HBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stats)
	
	var props = [
		["纤", m["fiber"]], ["亲", m["affinity"]], ["纯", m["purity"]],
		["灵", m["spirit"]], ["稳", m["stability"]]
	]
	for p in props:
		var lbl = Label.new()
		lbl.text = "%s:%02d" % [p[0], p[1]]
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		stats.add_child(lbl)
	
	panel.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_toggle_material(m["id"])
	)
	
	return panel

func _toggle_material(mid: String):
	if mid in _selected_materials:
		_selected_materials.erase(mid)
	else:
		if _selected_materials.size() >= 4:
			_show_toast("最多选择4个素材")
			return
		_selected_materials.append(mid)
	_refresh_material_selection()

func _refresh_material_selection():
	var count = _selected_materials.size()
	var valid = (count >= 2 and count <= 4)
	
	_btn_confirm.disabled = not valid
	var css = StyleBoxFlat.new()
	css.bg_color = Color(0.15, 0.4, 0.15) if valid else Color(0.1, 0.15, 0.1)
	css.corner_radius_top_left = 8; css.corner_radius_top_right = 8
	css.corner_radius_bottom_left = 8; css.corner_radius_bottom_right = 8
	_btn_confirm.add_theme_stylebox_override("normal", css)
	
	# 更新卡片边框
	var grid = _content.get_child(0) if _content.get_child_count() > 0 else null
	if grid:
		for card in grid.get_children():
			var m_id = card.get_meta("material_id", "")
			var is_sel = (m_id in _selected_materials)
			var m = MaterialData.get_material(m_id)
			var rc = Color(0.2, 0.6, 1.0)
			if not m.is_empty():
				var rarity_colors = [Color(0.5,0.5,0.5), Color(0.2,0.6,1.0), Color(0.7,0.3,1.0), Color(1.0,0.7,0.1)]
				rc = rarity_colors[clampi(m["rarity"]-1, 0, 3)]
			var s = StyleBoxFlat.new()
			s.bg_color = Color(0.12, 0.18, 0.12) if is_sel else Color(0.1, 0.12, 0.18)
			s.border_width_left = 3; s.border_width_right = 3
			s.border_width_top = 3; s.border_width_bottom = 3
			s.border_color = rc * Color(1.2, 1.2, 0.5) if is_sel else rc * Color(0.5, 0.5, 0.5)
			s.corner_radius_top_left = 10; s.corner_radius_top_right = 10
			s.corner_radius_bottom_left = 10; s.corner_radius_bottom_right = 10
			s.content_margin_left = 12; s.content_margin_right = 12
			s.content_margin_top = 10; s.content_margin_bottom = 10
			card.add_theme_stylebox_override("panel", s)

func _on_confirm_materials():
	if _selected_materials.size() < 2:
		_show_toast("请至少选择2个素材")
		return
	
	var validation = MaterialData.validate_paper_recipe(_selected_materials)
	if not validation["valid"]:
		_show_toast(validation["reason"])
		return
	
	_show_minigame()

# ─────────────────────────────────────────
# 阶段2: 小游戏
# ─────────────────────────────────────────

func _show_minigame():
	_state = "game"
	_title_lbl.text = "造纸小游戏"
	_hint_lbl.text = "控制三个参数，停在绿色区间!"
	_btn_confirm.visible = false
	_btn_start.visible = true
	
	for c in _content.get_children():
		c.queue_free()
	
	var pulp = _make_param_section("纸浆浓度", "停在绿色区域(40-60)")
	pulp.set_meta("param", "pulp")
	_content.add_child(pulp)
	
	var pressure = _make_param_section("压制力度", "停在绿色区域(30-70)")
	pressure.set_meta("param", "pressure")
	_content.add_child(pressure)
	
	var temp = _make_temp_section()
	_content.add_child(temp)

func _make_param_section(name: String, hint: String) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(header)
	
	var name_lbl = Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	header.add_child(name_lbl)
	
	var hint_lbl = Label.new()
	hint_lbl.text = hint
	hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_lbl.add_theme_font_size_override("font_size", 24)
	hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.4))
	header.add_child(hint_lbl)
	
	var bar_bg = PanelContainer.new()
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_bg.custom_minimum_size = Vector2(0, 50)
	var bar_s = StyleBoxFlat.new()
	bar_s.bg_color = Color(0.1, 0.1, 0.15)
	bar_s.corner_radius_top_left = 6; bar_s.corner_radius_top_right = 6
	bar_s.corner_radius_bottom_left = 6; bar_s.corner_radius_bottom_right = 6
	bar_bg.add_theme_stylebox_override("panel", bar_s)
	vbox.add_child(bar_bg)
	
	var bar_inner = PanelContainer.new()
	bar_inner.set_meta("is_bar", true)
	bar_inner.anchor_left = 0.0; bar_inner.anchor_right = 0.0
	bar_inner.offset_left = 0; bar_inner.offset_right = 100
	bar_inner.offset_top = 0; bar_inner.offset_bottom = 50
	var inner_s = StyleBoxFlat.new()
	inner_s.bg_color = Color(0.3, 0.85, 0.3)
	inner_s.corner_radius_top_left = 6; inner_s.corner_radius_top_right = 6
	inner_s.corner_radius_bottom_left = 6; inner_s.corner_radius_bottom_right = 6
	bar_inner.add_theme_stylebox_override("panel", inner_s)
	bar_bg.add_child(bar_inner)
	
	return vbox

func _make_temp_section() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(header)
	
	var name_lbl = Label.new()
	name_lbl.text = "烘干温度"
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	header.add_child(name_lbl)
	
	var hint_lbl = Label.new()
	hint_lbl.text = "滑动调节(0-100)"
	hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_lbl.add_theme_font_size_override("font_size", 24)
	hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	header.add_child(hint_lbl)
	
	var slider = HSlider.new()
	slider.set_meta("is_slider", true)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 50)
	slider.min_value = 0
	slider.max_value = 100
	slider.value = 50
	slider.value_changed.connect(_on_temp_changed)
	vbox.add_child(slider)
	
	return vbox

func _on_temp_changed(val: float):
	_temp_value = val

func _on_start_game():
	# 消耗素材
	if not PlayerSave.consume_materials(_selected_materials):
		_show_toast("素材不足!")
		return
	
	# 计算小游戏得分
	var pulp = randf() * 100.0
	var pressure = randf() * 100.0
	var temp = _temp_value
	
	var pulp_ok = (pulp >= 40.0 and pulp <= 60.0)
	var pressure_ok = (pressure >= 30.0 and pressure <= 70.0)
	var temp_ok = (temp >= 35.0 and temp <= 65.0)
	
	_minigame_score = 0
	if pulp_ok: _minigame_score += 1
	if pressure_ok: _minigame_score += 1
	if temp_ok: _minigame_score += 1
	
	# 计算白卡属性
	_result_props = MaterialData.calc_paper_properties(_selected_materials)
	
	_show_result()

# ─────────────────────────────────────────
# 阶段3: 结果
# ─────────────────────────────────────────

func _show_result():
	_state = "result"
	_title_lbl.text = "造纸完成"
	_hint_lbl.text = ""
	_btn_confirm.visible = false
	_btn_start.visible = false
	
	for c in _content.get_children():
		c.queue_free()
	
	var grade = _result_props.get("grade", "普通白卡")
	var energy_cap = _result_props.get("energy_cap", 0.0)
	var quality_cap = _result_props.get("quality_cap", 0.0)
	var toughness = _result_props.get("toughness", 0.0)
	var affinity = _result_props.get("affinity_type", "无")
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 16)
	_content.add_child(info)
	
	var grade_lbl = Label.new()
	grade_lbl.text = "产出: " + grade
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_lbl.add_theme_font_size_override("font_size", 52)
	grade_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	info.add_child(grade_lbl)
	
	var mat_names = ""
	for mid in _selected_materials:
		var m = MaterialData.get_material(mid)
		mat_names += m.get("name", mid) + " + "
	mat_names = mat_names.trim_suffix(" + ")
	var mat_lbl = Label.new()
	mat_lbl.text = "素材: " + mat_names
	mat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mat_lbl.add_theme_font_size_override("font_size", 26)
	mat_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
	mat_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(mat_lbl)
	
	var score_lbl = Label.new()
	var score_names = ["", "普通", "普通", "精良", "高级"]
	var score_lbl_text = "小游戏: %s (%d/3)" % [score_names[_minigame_score], _minigame_score]
	score_lbl.text = score_lbl_text
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_size_override("font_size", 28)
	score_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.4))
	info.add_child(score_lbl)
	
	var sep = HSeparator.new()
	info.add_child(sep)
	
	var stats_lbl = Label.new()
	stats_lbl.text = "能量上限: %.1f\n品质系数: %.2f\n韧性: %.2f\n属性亲和: %s" % [
		energy_cap, quality_cap, toughness, affinity
	]
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 32)
	stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(stats_lbl)
	
	# 存到PlayerSave，生成唯一ID
	_result_props["id"] = "PG_" + str(Time.get_unix_time_from_system())
	_result_props["name"] = _result_props.get("grade", "白卡")
	PlayerSave.add_white_card(_result_props)

func _show_toast(msg: String):
	var overlay = ColorRect.new()
	overlay.z_index = 150
	overlay.anchor_left = 0.0; overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0; overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	add_child(overlay)
	
	var toast = Label.new()
	toast.z_index = 151
	toast.text = msg
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.anchor_left = 0.5; toast.anchor_right = 0.5
	toast.anchor_top = 0.5; toast.anchor_bottom = 0.5
	toast.offset_left = -300; toast.offset_right = 300
	toast.offset_top = -60; toast.offset_bottom = 60
	toast.add_theme_font_size_override("font_size", 36)
	toast.add_theme_color_override("font_color", Color(1, 1, 1))
	var ts = StyleBoxFlat.new()
	ts.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	ts.corner_radius_top_left = 12; ts.corner_radius_top_right = 12
	ts.corner_radius_bottom_left = 12; ts.corner_radius_bottom_right = 12
	toast.add_theme_stylebox_override("normal", ts)
	overlay.add_child(toast)
	
	await get_tree().create_timer(2.0).timeout
	overlay.queue_free()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/world/city_map_scene.tscn")
