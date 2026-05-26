# deck_gui.gd
# 牌组界面 — 列表显示20张卡牌，必须满20张才能保存
extends Control

const SLOT_COUNT = 20

var _slots: Array[Button] = []
var _deck: Array = []           # 当前编辑的卡牌名称列表
var _all_cards: Array = []    # 所有可用的卡牌名称列表
var _ps: Node = null
var _count_lbl: Label = null
var _hint_lbl: Label = null
var _bg: ColorRect = null
var _panel: PanelContainer = null
var _scroll: ScrollContainer = null
var _pending_slot: int = -1  # 当前正在填充的槽位索引

signal deck_saved(deck: Array)

func _ready():
	_ps = get_node("/root/PlayerSave")
	# 填满视口
	anchor_left = 0; anchor_right = 1
	anchor_top = 0; anchor_bottom = 1
	offset_left = 0; offset_top = 0
	offset_right = 0; offset_bottom = 0
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	_build()
	_refresh_all_cards()
	_load_deck()
	_refresh_list()

func _build():
	# 全屏背景
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.12, 0.97)
	bg.anchor_left = 0; bg.anchor_right = 1
	bg.anchor_top = 0; bg.anchor_bottom = 1
	bg.offset_left = 0; bg.offset_right = 0
	bg.offset_top = 0; bg.offset_bottom = 0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			_close()
	)
	add_child(bg)
	_bg = bg

	# 主面板（铺满全屏）
	var panel = PanelContainer.new()
	panel.anchor_left = 0; panel.anchor_right = 1
	panel.anchor_top = 0; panel.anchor_bottom = 1
	panel.offset_left = 0; panel.offset_right = 0
	panel.offset_top = 0; panel.offset_bottom = 0
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.10, 0.17, 1.0)
	ps.border_width_left = 2; ps.border_width_right = 2
	ps.border_color = Color(0.4, 0.4, 0.65)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)
	_panel = panel

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	# 标题栏
	var title_row = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(title_row)

	var back_btn = Button.new()
	back_btn.text = "←返回"
	back_btn.custom_minimum_size = Vector2(140, 70)
	var bbs = StyleBoxFlat.new()
	bbs.bg_color = Color(0.3, 0.25, 0.4, 1.0)
	bbs.corner_radius_top_left = 10; bbs.corner_radius_top_right = 10
	bbs.corner_radius_bottom_left = 10; bbs.corner_radius_bottom_right = 10
	back_btn.add_theme_stylebox_override("normal", bbs)
	back_btn.add_theme_font_size_override("font_size", 28)
	back_btn.pressed.connect(_close)
	title_row.add_child(back_btn)

	var title_lbl = Label.new()
	title_lbl.text = "⚔️ 牌组"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	title_lbl.add_theme_font_size_override("font_size", 40)
	title_row.add_child(title_lbl)

	# 空占位（与返回按钮等宽）
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(140, 70)
	title_row.add_child(spacer)

	vbox.add_child(HSeparator.new())

	# 人数标签
	var count_lbl = Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.text = "已放置: 0 / 20"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	count_lbl.add_theme_font_size_override("font_size", 30)
	count_lbl.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(count_lbl)
	_count_lbl = count_lbl

	# 滚动区域（卡牌列表）
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll = scroll
	vbox.add_child(scroll)

	var list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(list_container)

	for i in range(SLOT_COUNT):
		var slot_btn = Button.new()
		slot_btn.text = "[%02d] 空" % (i + 1)
		slot_btn.custom_minimum_size = Vector2(900, 60)
		slot_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var slot_s = StyleBoxFlat.new()
		slot_s.bg_color = Color(0.14, 0.14, 0.22, 1.0)
		slot_s.border_width_left = 1; slot_s.border_width_right = 1
		slot_s.border_width_top = 1; slot_s.border_width_bottom = 1
		slot_s.border_color = Color(0.3, 0.3, 0.5, 0.8)
		slot_s.corner_radius_top_left = 6; slot_s.corner_radius_top_right = 6
		slot_s.corner_radius_bottom_left = 6; slot_s.corner_radius_bottom_right = 6
		slot_btn.add_theme_stylebox_override("normal", slot_s)
		var slot_s2 = slot_s.duplicate()
		slot_s2.bg_color = Color(0.18, 0.18, 0.30, 1.0)
		slot_btn.add_theme_stylebox_override("hover", slot_s2)
		var slot_s3 = slot_s.duplicate()
		slot_s3.bg_color = Color(0.22, 0.22, 0.35, 1.0)
		slot_btn.add_theme_stylebox_override("pressed", slot_s3)
		slot_btn.add_theme_font_size_override("font_size", 26)
		slot_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		slot_btn.pressed.connect(_on_slot_pressed.bind(i))
		list_container.add_child(slot_btn)
		_slots.append(slot_btn)

	vbox.add_child(HSeparator.new())

	# 提示标签
	var hint_lbl = Label.new()
	hint_lbl.name = "HintLabel"
	hint_lbl.text = "点击槽位选择卡牌"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
	hint_lbl.add_theme_font_size_override("font_size", 24)
	hint_lbl.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(hint_lbl)
	_hint_lbl = hint_lbl

	# 按钮行
	var btn_row = HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.custom_minimum_size = Vector2(0, 80)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 60)
	vbox.add_child(btn_row)

	var save_btn = Button.new()
	save_btn.name = "SaveBtn"
	save_btn.text = "💾 保存牌组"
	save_btn.custom_minimum_size = Vector2(300, 75)
	var sbs = StyleBoxFlat.new()
	sbs.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	sbs.corner_radius_top_left = 12; sbs.corner_radius_top_right = 12
	sbs.corner_radius_bottom_left = 12; sbs.corner_radius_bottom_right = 12
	save_btn.add_theme_stylebox_override("normal", sbs)
	save_btn.add_theme_font_size_override("font_size", 30)
	save_btn.pressed.connect(_on_save)
	btn_row.add_child(save_btn)

	var clear_btn = Button.new()
	clear_btn.text = "🗑 清空"
	clear_btn.custom_minimum_size = Vector2(180, 75)
	var cbs = StyleBoxFlat.new()
	cbs.bg_color = Color(0.5, 0.2, 0.2, 1.0)
	cbs.corner_radius_top_left = 12; cbs.corner_radius_top_right = 12
	cbs.corner_radius_bottom_left = 12; cbs.corner_radius_bottom_right = 12
	clear_btn.add_theme_stylebox_override("normal", cbs)
	clear_btn.add_theme_font_size_override("font_size", 28)
	clear_btn.pressed.connect(_on_clear)
	btn_row.add_child(clear_btn)


func _refresh_all_cards():
	_all_cards.clear()
	# 从 player_save 的 owned_card_paths 加载所有卡牌名称
	var paths = _ps.owned_card_paths as Array
	for path in paths:
		if path is String and path.ends_with(".json"):
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var txt = f.get_as_text()
				f.close()
				var d = JSON.parse_string(txt)
				if d is Dictionary and d.has("name"):
					_all_cards.append(d["name"])
	# 也从 player_save 的 owned_white_cards 读取白卡名称
	for wc in _ps.owned_white_cards:
		if wc is Dictionary and wc.has("name"):
			_all_cards.append(wc["name"])


func _load_deck():
	_deck.clear()
	for name in _ps.deck_cards:
		_deck.append(name)
	# 补齐空位
	while _deck.size() < SLOT_COUNT:
		_deck.append("")


func _refresh_list():
	var count = 0
	for i in range(SLOT_COUNT):
		var name = _deck[i] if i < _deck.size() else ""
		if name != "" and name != null:
			_slots[i].text = "[%02d] %s" % [i + 1, name]
			_slots[i].add_theme_color_override("font_color", Color(0.95, 0.90, 0.60))
			count += 1
		else:
			_slots[i].text = "[%02d] 空" % (i + 1)
			_slots[i].add_theme_color_override("font_color", Color(0.4, 0.4, 0.55))

	if _count_lbl:
		_count_lbl.text = "已放置: %d / 20" % count
	if _hint_lbl:
		if count < SLOT_COUNT:
			_hint_lbl.text = "还需 %d 张卡牌才能保存" % (SLOT_COUNT - count)
			_hint_lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		else:
			_hint_lbl.text = "✓ 牌组已满，可以保存"
			_hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))


func _on_slot_pressed(idx: int):
	_pending_slot = idx
	# 通过 PlayerSave 传递选卡上下文，再切换到卡库场景
	var excluded: Array = []
	for i in range(SLOT_COUNT):
		if i != idx and i < _deck.size() and _deck[i] != "" and _deck[i] != null:
			excluded.append(_deck[i])
	var ps = get_node("/root/PlayerSave")
	ps.card_sel_return_scene = "res://scenes/workshop/deck_scene.tscn"
	ps.card_sel_pending_slot = idx
	ps.card_sel_excluded = excluded
	get_tree().change_scene_to_file("res://scenes/workshop/card_library.tscn")


func _show_hint(msg: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = msg
	get_tree().root.add_child(popup)
	popup.popup_centered(Vector2(400, 200))
	await popup.confirmed
	popup.queue_free()


func _on_save():
	var filled = _deck.filter(func(n): return n != "" and n != null).size()
	if filled < SLOT_COUNT:
		await _show_hint("牌组未满 %d/%d！" % [filled, SLOT_COUNT])
		return
	_ps.deck_cards = _deck.duplicate()
	_ps.save_data()
	await _show_hint("✓ 牌组已保存！")
	deck_saved.emit(_deck)


func _on_clear():
	_deck.clear()
	for i in range(SLOT_COUNT):
		_deck.append("")
	_refresh_list()


func _save_deck():
	_ps.deck_cards = _deck.duplicate()
	_ps.save_data()

func _close():
	var ps = get_node("/root/PlayerSave")
	var return_scene = ps.last_scene if ps.last_scene != "" else "res://scenes/world/world_map_scene.tscn"
	ps.last_scene = ""
	get_tree().change_scene_to_file(return_scene)
