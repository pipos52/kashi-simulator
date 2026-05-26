extends Control

var _commissions: Array[CommissionData] = []
var _commission_panels: Array[PanelContainer] = []
var _card_list: Array[PanelContainer] = []
var _card_grid: GridContainer
var _comm_vbox: VBoxContainer
var _selected_commission: CommissionData = null
var _selected_card_path: String = ""

func _enter_tree():
	_build()

func _build():
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0
	bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	add_child(bg)
	
	var hbox = HBoxContainer.new()
	hbox.anchor_left = 0.0; hbox.anchor_top = 0.0
	hbox.anchor_right = 1.0; hbox.anchor_bottom = 1.0
	hbox.offset_left = 0; hbox.offset_top = 0
	hbox.offset_right = 0; hbox.offset_bottom = 0
	add_child(hbox)
	
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(480, 0)
	var lps = StyleBoxFlat.new()
	lps.bg_color = Color(0.06, 0.06, 0.1)
	lps.border_width_right = 2
	lps.border_color = Color(0.2, 0.2, 0.25)
	left_panel.add_theme_stylebox_override("panel", lps)
	hbox.add_child(left_panel)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(left_vbox)
	
	var nav = _make_nav()
	left_vbox.add_child(nav)
	left_vbox.add_child(HSeparator.new())
	
	var comm_title = Label.new()
	comm_title.text = "委托列表"
	comm_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comm_title.add_theme_font_size_override("font_size", 36)
	comm_title.add_theme_color_override("font_color", Color(0.7, 0.75, 1.0))
	left_vbox.add_child(comm_title)
	
	var comm_scroll = ScrollContainer.new()
	comm_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comm_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(comm_scroll)
	
	_comm_vbox = VBoxContainer.new()
	_comm_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comm_vbox.add_theme_constant_override("separation", 10)
	comm_scroll.add_child(_comm_vbox)
	
	left_vbox.add_child(HSeparator.new())
	
	var submit_btn = Button.new()
	submit_btn.text = "提交卡牌"
	submit_btn.custom_minimum_size = Vector2(0, 70)
	submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_btn.add_theme_font_size_override("font_size", 36)
	var nss = StyleBoxFlat.new()
	nss.bg_color = Color(0.15, 0.4, 0.15)
	nss.corner_radius_top_left = 8; nss.corner_radius_top_right = 8
	nss.corner_radius_bottom_left = 8; nss.corner_radius_bottom_right = 8
	submit_btn.add_theme_stylebox_override("normal", nss)
	var pss = nss.duplicate()
	pss.bg_color = Color(0.1, 0.3, 0.1)
	submit_btn.add_theme_stylebox_override("pressed", pss)
	submit_btn.pressed.connect(_on_submit)
	left_vbox.add_child(submit_btn)
	
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rps = StyleBoxFlat.new()
	rps.bg_color = Color(0.06, 0.06, 0.1)
	right_panel.add_theme_stylebox_override("panel", rps)
	hbox.add_child(right_panel)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_vbox)
	
	var right_nav = _make_right_nav()
	right_vbox.add_child(right_nav)
	right_vbox.add_child(HSeparator.new())
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(scroll)
	
	_card_grid = GridContainer.new()
	_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_grid.columns = 2
	_card_grid.add_theme_constant_override("hseparation", 12)
	_card_grid.add_theme_constant_override("vseparation", 12)
	scroll.add_child(_card_grid)
	
	_refresh()

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
	lbl.text = "委托工坊"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	lbl.add_theme_font_size_override("font_size", 48)
	nav.add_child(lbl)
	
	var gold_lbl = Label.new()
	gold_lbl.set_meta("is_gold", true)
	gold_lbl.text = "100金"
	gold_lbl.add_theme_font_size_override("font_size", 32)
	gold_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	nav.add_child(gold_lbl)

	var refresh_btn = Button.new()
	refresh_btn.text = "🔄"
	refresh_btn.custom_minimum_size = Vector2(70, 70)
	refresh_btn.add_theme_font_size_override("font_size", 36)
	var rfs = StyleBoxFlat.new()
	rfs.bg_color = Color(0.15, 0.15, 0.3)
	rfs.corner_radius_top_left = 8; rfs.corner_radius_top_right = 8
	rfs.corner_radius_bottom_left = 8; rfs.corner_radius_bottom_right = 8
	refresh_btn.add_theme_stylebox_override("normal", rfs)
	refresh_btn.pressed.connect(_on_refresh_commissions)
	nav.add_child(refresh_btn)

	return nav

func _make_right_nav() -> HBoxContainer:
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.custom_minimum_size = Vector2(0, 60)
	
	var lbl = Label.new()
	lbl.text = "我的卡牌"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 1.0))
	lbl.add_theme_font_size_override("font_size", 36)
	nav.add_child(lbl)
	
	return nav

func _refresh():
	_commissions = CommissionGenerator.generate_commissions(3)
	_refresh_commissions()
	_refresh_card_list()

func _refresh_commissions():
	for child in _comm_vbox.get_children():
		child.queue_free()
	_commission_panels.clear()
	
	if _commissions.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "暂无可用委托"
		empty_lbl.add_theme_font_size_override("font_size", 28)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		_comm_vbox.add_child(empty_lbl)
		return
	
	for i in range(_commissions.size()):
		var c = _commissions[i]
		var item = _build_commission_item(c, i)
		_comm_vbox.add_child(item)
		_commission_panels.append(item)

func _on_refresh_commissions():
	_refresh()
	ToastManager.show("委托已刷新")

func _build_commission_item(c: CommissionData, idx: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var nor_style = StyleBoxFlat.new()
	nor_style.bg_color = Color(0.12, 0.14, 0.22)
	nor_style.border_width_left = 2; nor_style.border_width_right = 2
	nor_style.border_width_top = 2; nor_style.border_width_bottom = 2
	nor_style.border_color = Color(0.3, 0.3, 0.4)
	nor_style.corner_radius_top_left = 10; nor_style.corner_radius_top_right = 10
	nor_style.corner_radius_bottom_left = 10; nor_style.corner_radius_bottom_right = 10
	nor_style.content_margin_left = 14; nor_style.content_margin_right = 14
	nor_style.content_margin_top = 10; nor_style.content_margin_bottom = 10
	
	panel.add_theme_stylebox_override("panel", nor_style)
	panel.set_meta("idx", idx)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	var title_row = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_row)
	
	var title_lbl = Label.new()
	title_lbl.text = c.title
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_row.add_child(title_lbl)
	
	var reward_lbl = Label.new()
	reward_lbl.text = "+%d金" % c.reward_gold
	reward_lbl.add_theme_font_size_override("font_size", 32)
	reward_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title_row.add_child(reward_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = c.description
	desc_lbl.add_theme_font_size_override("font_size", 28)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	panel.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_select_commission(idx)
	)
	
	return panel

func _select_commission(idx: int):
	_selected_commission = _commissions[idx]
	for i in range(_commission_panels.size()):
		var p = _commission_panels[i]
		var is_sel = (i == idx)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.2, 0.15) if is_sel else Color(0.12, 0.14, 0.22)
		style.border_width_left = 3 if is_sel else 2
		style.border_width_right = 3 if is_sel else 2
		style.border_width_top = 3 if is_sel else 2
		style.border_width_bottom = 3 if is_sel else 2
		style.border_color = Color(0.3, 0.8, 0.3) if is_sel else Color(0.3, 0.3, 0.4)
		style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
		style.content_margin_left = 14; style.content_margin_right = 14
		style.content_margin_top = 10; style.content_margin_bottom = 10
		p.add_theme_stylebox_override("panel", style)
	_refresh_card_list()

func _refresh_card_list():
	for child in _card_grid.get_children():
		child.queue_free()
	_card_list.clear()
	
	var player = get_node("/root/PlayerSave")
	var files = player.get_all_card_files()
	
	if files.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "暂无卡牌\n请先制作卡牌"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 36)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		empty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_card_grid.add_child(empty_lbl)
		return
	
	for fpath in files:
		var data = _load_card(fpath)
		if data.is_empty():
			continue
		var panel = _make_card_panel(data, fpath)
		_card_grid.add_child(panel)
		_card_list.append(panel)

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

func _make_card_panel(data: Dictionary, fpath: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 160)
	
	var normal_s = StyleBoxFlat.new()
	normal_s.bg_color = Color(0.12, 0.14, 0.22)
	normal_s.border_width_left = 2; normal_s.border_width_right = 2
	normal_s.border_width_top = 2; normal_s.border_width_bottom = 2
	normal_s.border_color = Color(0.3, 0.3, 0.4)
	normal_s.corner_radius_top_left = 10; normal_s.corner_radius_top_right = 10
	normal_s.corner_radius_bottom_left = 10; normal_s.corner_radius_bottom_right = 10
	normal_s.content_margin_left = 12; normal_s.content_margin_right = 12
	normal_s.content_margin_top = 10; normal_s.content_margin_bottom = 10
	
	panel.add_theme_stylebox_override("panel", normal_s.duplicate())
	panel.set_meta("fpath", fpath)
	panel.set_meta("selected", false)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	var fields_arr: Array = data.get("fields", [])
	var display_name = data.get("name", "未知")
	if fields_arr.size() > 0:
		display_name = fields_arr[0] + " " + display_name
	
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(header)
	
	var card_type = data.get("card_type", "怪兽")
	var type_lbl = Label.new()
	type_lbl.text = card_type
	type_lbl.add_theme_font_size_override("font_size", 28)
	type_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	header.add_child(type_lbl)
	
	var name_lbl = Label.new()
	name_lbl.text = display_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 34)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(name_lbl)
	
	var atk = data.get("attack", 0)
	var hp = data.get("health", 0)
	var spd = data.get("speed", 0)
	var stat_lbl = Label.new()
	stat_lbl.text = "ATK:%d HP:%d SPD:%d" % [atk, hp, spd]
	stat_lbl.add_theme_font_size_override("font_size", 26)
	stat_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(stat_lbl)
	
	var qual = data.get("quality_score", 0.0)
	var qual_lbl = Label.new()
	qual_lbl.text = "品质:%.0f" % qual
	qual_lbl.add_theme_font_size_override("font_size", 24)
	qual_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(qual_lbl)
	
	if _selected_commission != null:
		var check = _selected_commission.check_card(data)
		var check_lbl = Label.new()
		check_lbl.text = "符合" if check["pass"] else check["reason"]
		check_lbl.add_theme_font_size_override("font_size", 24)
		check_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3) if check["pass"] else Color(0.85, 0.3, 0.3))
		vbox.add_child(check_lbl)
	
	panel.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_select_card(fpath, panel)
	)
	
	return panel

func _select_card(fpath: String, panel: PanelContainer):
	_selected_card_path = fpath
	for p in _card_list:
		var is_sel = (p == panel)
		p.set_meta("selected", is_sel)
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.12, 0.14, 0.22)
		s.border_width_left = 2; s.border_width_right = 2
		s.border_width_top = 2; s.border_width_bottom = 2
		s.border_color = Color(0.3, 0.85, 0.3) if is_sel else Color(0.3, 0.3, 0.4)
		s.corner_radius_top_left = 10; s.corner_radius_top_right = 10
		s.corner_radius_bottom_left = 10; s.corner_radius_bottom_right = 10
		s.content_margin_left = 12; s.content_margin_right = 12
		s.content_margin_top = 10; s.content_margin_bottom = 10
		p.add_theme_stylebox_override("panel", s)

func _on_submit():
	if _selected_commission == null:
		ToastManager.show("请先选择要提交的委托")
		return
	if _selected_card_path.is_empty():
		ToastManager.show("请先选择要提交的卡牌")
		return
	
	var card_data = _load_card(_selected_card_path)
	var check = _selected_commission.check_card(card_data)
	if not check["pass"]:
		ToastManager.show("卡牌不符合: " + check["reason"])
		return
	
	var player = get_node("/root/PlayerSave")
	player.add_gold(_selected_commission.reward_gold)
	player.commissions_completed += 1
	player.remove_card_path(_selected_card_path)
	_dir_delete_card(_selected_card_path)
	player.save_data()
	
	_show_success_dialog(_selected_commission)

func _show_success_dialog(c: CommissionData):
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
	dialog.offset_left = -350; dialog.offset_right = 350
	dialog.offset_top = -280; dialog.offset_bottom = 280
	var ds = StyleBoxFlat.new()
	ds.bg_color = Color(0.1, 0.12, 0.18)
	ds.border_width_left = 3; ds.border_width_right = 3
	ds.border_width_top = 3; ds.border_width_bottom = 3
	ds.border_color = Color(0.3, 0.85, 0.3)
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
	ok_lbl.text = "委托完成!"
	ok_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ok_lbl.add_theme_font_size_override("font_size", 52)
	ok_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	vbox.add_child(ok_lbl)
	
	var reward_lbl = Label.new()
	reward_lbl.text = "+%d金" % c.reward_gold
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_font_size_override("font_size", 64)
	reward_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	vbox.add_child(reward_lbl)
	
	var title_lbl = Label.new()
	title_lbl.text = c.title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 36)
	title_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(title_lbl)
	
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
		_refresh()
		_selected_card_path = ""
		_selected_commission = null
	)
	vbox.add_child(close_btn)


func _dir_delete_card(path: String):
	if path.is_empty():
		return
	if DirAccess.remove_absolute(path) == OK:
		print("已删除卡牌: ", path)
	else:
		print("删除失败: ", path)

func _on_back():
	get_tree().change_scene_to_file("res://scenes/world/city_map_scene.tscn")

# ── 广告集成（预留） ──
