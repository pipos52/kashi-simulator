extends Control

var _selected_area: int = -1
var _area_panels: Array[PanelContainer] = []

const AREAS: Array[Dictionary] = [
	{"name": "火焰森林", "level": 1, "desc": "火系素材采集地，掉落火核、火之核", "drops": ["M01", "M05", "M08"]},
	{"name": "冰霜洞穴", "level": 1, "desc": "水系素材采集地，掉落水之核、冰晶粉", "drops": ["M02", "M05", "M07"]},
	{"name": "雷光高地", "level": 2, "desc": "雷系素材采集地，掉落雷之核、雷光粉", "drops": ["M03", "M05", "M06", "M08"]},
	{"name": "神秘遗迹", "level": 3, "desc": "稀有素材采集地，掉落龙血墨囊、星辉石粉", "drops": ["M04", "M09", "M02", "M10"]}
]

func _enter_tree():
	_build()
	# 检查是否有战斗结果返回
	_check_explore_result()

func _check_explore_result():
	var em = get_node("/root/ExploreManager")
	if em.last_battle_won and not em.last_drops.is_empty():
		_show_rewards_dialog(em.last_drops)
		em.last_battle_won = false
		em.last_drops.clear()

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
	
	var nav = _make_nav()
	vbox.add_child(nav)
	vbox.add_child(HSeparator.new())
	
	var title = Label.new()
	title.text = "野外探险"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 1.0))
	vbox.add_child(title)
	
	var hint = Label.new()
	hint.text = "选择要探索的区域"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_font_size_override("font_size", 28)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(hint)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.columns = 2
	grid.add_theme_constant_override("hseparation", 16)
	grid.add_theme_constant_override("vseparation", 16)
	scroll.add_child(grid)
	
	_area_panels.clear()
	for i in range(AREAS.size()):
		var area = AREAS[i]
		var panel = _make_area_panel(area, i)
		grid.add_child(panel)
		_area_panels.append(panel)
	
	vbox.add_child(HSeparator.new())
	
	var info_lbl = Label.new()
	info_lbl.set_meta("is_info", true)
	info_lbl.text = "选择一个区域后点击出发"
	info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_lbl.add_theme_font_size_override("font_size", 32)
	info_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(info_lbl)
	
	var go_btn = Button.new()
	go_btn.text = "出发"
	go_btn.custom_minimum_size = Vector2(0, 90)
	go_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go_btn.add_theme_font_size_override("font_size", 48)
	var nss = StyleBoxFlat.new()
	nss.bg_color = Color(0.2, 0.5, 0.2)
	nss.corner_radius_top_left = 8; nss.corner_radius_top_right = 8
	nss.corner_radius_bottom_left = 8; nss.corner_radius_bottom_right = 8
	go_btn.add_theme_stylebox_override("normal", nss)
	go_btn.pressed.connect(_on_go)
	vbox.add_child(go_btn)

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
	lbl.text = "野外探险"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	lbl.add_theme_font_size_override("font_size", 48)
	nav.add_child(lbl)
	
	var gold_lbl = Label.new()
	gold_lbl.set_meta("is_gold", true)
	gold_lbl.text = "0金"
	gold_lbl.add_theme_font_size_override("font_size", 32)
	gold_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	nav.add_child(gold_lbl)
	
	return nav

func _make_area_panel(area: Dictionary, idx: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 180)
	
	var nor_s = StyleBoxFlat.new()
	nor_s.bg_color = Color(0.12, 0.14, 0.22)
	nor_s.border_width_left = 3; nor_s.border_width_right = 3
	nor_s.border_width_top = 3; nor_s.border_width_bottom = 3
	nor_s.border_color = Color(0.3, 0.3, 0.4)
	nor_s.corner_radius_top_left = 12; nor_s.corner_radius_top_right = 12
	nor_s.corner_radius_bottom_left = 12; nor_s.corner_radius_bottom_right = 12
	nor_s.content_margin_left = 16; nor_s.content_margin_right = 16
	nor_s.content_margin_top = 12; nor_s.content_margin_bottom = 12
	
	panel.add_theme_stylebox_override("panel", nor_s.duplicate())
	panel.set_meta("idx", idx)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = area["name"]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 38)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = area["desc"]
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 26)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	var level_lbl = Label.new()
	level_lbl.text = "难度: Lv%d" % area["level"]
	level_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_lbl.add_theme_font_size_override("font_size", 24)
	level_lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	vbox.add_child(level_lbl)
	
	panel.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_select_area(idx)
	)
	
	return panel

func _select_area(idx: int):
	_selected_area = idx
	for i in range(_area_panels.size()):
		var p = _area_panels[i]
		var is_sel = (i == idx)
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.15, 0.2, 0.15) if is_sel else Color(0.12, 0.14, 0.22)
		s.border_width_left = 3; s.border_width_right = 3
		s.border_width_top = 3; s.border_width_bottom = 3
		s.border_color = Color(0.3, 0.85, 0.3) if is_sel else Color(0.3, 0.3, 0.4)
		s.corner_radius_top_left = 12; s.corner_radius_top_right = 12
		s.corner_radius_bottom_left = 12; s.corner_radius_bottom_right = 12
		s.content_margin_left = 16; s.content_margin_right = 16
		s.content_margin_top = 12; s.content_margin_bottom = 12
		p.add_theme_stylebox_override("panel", s)

func _on_go():
	if _selected_area < 0:
		ToastManager.show("请先选择一个区域")
		return
	
	var em = get_node("/root/ExploreManager") as Node
	em.set("selected_area_index", _selected_area)
	em.set("last_drops", [] as Array[Dictionary])
	
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")

func _show_rewards_dialog(drops: Array[Dictionary]):
	var overlay = ColorRect.new()
	overlay.z_index = 100
	overlay.anchor_left = 0.0; overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0; overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	add_child(overlay)
	
	var dialog = PanelContainer.new()
	dialog.z_index = 101
	dialog.anchor_left = 0.5; dialog.anchor_right = 0.5
	dialog.anchor_top = 0.5; dialog.anchor_bottom = 0.5
	dialog.offset_left = -380; dialog.offset_right = 380
	dialog.offset_top = -350; dialog.offset_bottom = 350
	var ds = StyleBoxFlat.new()
	ds.bg_color = Color(0.1, 0.12, 0.18)
	ds.border_width_left = 3; ds.border_width_right = 3
	ds.border_width_top = 3; ds.border_width_bottom = 3
	ds.border_color = Color(0.85, 0.6, 0.1)
	ds.corner_radius_top_left = 14; ds.corner_radius_top_right = 14
	ds.corner_radius_bottom_left = 14; ds.corner_radius_bottom_right = 14
	ds.content_margin_left = 24; ds.content_margin_right = 24
	ds.content_margin_top = 24; ds.content_margin_bottom = 24
	dialog.add_theme_stylebox_override("panel", ds)
	overlay.add_child(dialog)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog.add_child(vbox)
	
	var ok_lbl = Label.new()
	ok_lbl.text = "探险胜利!"
	ok_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ok_lbl.add_theme_font_size_override("font_size", 48)
	ok_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	vbox.add_child(ok_lbl)
	
	var drops_lbl = Label.new()
	drops_lbl.text = "获得素材:"
	drops_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drops_lbl.add_theme_font_size_override("font_size", 32)
	drops_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
	vbox.add_child(drops_lbl)
	
	var drop_str = ""
	for drop in drops:
		var mid = drop.get("id", "?")
		var cnt = drop.get("count", 1)
		var m = MaterialData.get_material(mid)
		var mname = m.get("name", mid) if not m.is_empty() else mid
		drop_str += "%s x%d\n" % [mname, cnt]
	
	var reward_lbl = Label.new()
	reward_lbl.text = drop_str
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_font_size_override("font_size", 36)
	reward_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	reward_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(reward_lbl)
	
	var close_btn = Button.new()
	close_btn.text = "确定"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.custom_minimum_size = Vector2(0, 70)
	close_btn.add_theme_font_size_override("font_size", 36)
	var nss = StyleBoxFlat.new()
	nss.bg_color = Color(0.2, 0.5, 0.2)
	nss.corner_radius_top_left = 8; nss.corner_radius_top_right = 8
	nss.corner_radius_bottom_left = 8; nss.corner_radius_bottom_right = 8
	close_btn.add_theme_stylebox_override("normal", nss)
	close_btn.pressed.connect(func():
		overlay.queue_free()
	)
	vbox.add_child(close_btn)

func _on_back():
	get_tree().change_scene_to_file("res://scenes/world/city_map_scene.tscn")
