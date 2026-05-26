extends Control

var _ps: Node

# ── 建筑定义 ──
const BUILDINGS: Array[Dictionary] = [
	{"id": "guild",  "name": "🏛️ 制卡师公会",  "scene": "res://scenes/workshop/workshop_scene.tscn",  "desc": "接受委托任务"},
	{"id": "shop",   "name": "🏪 材料商店",    "scene": "res://scenes/workshop/shop_scene.tscn",      "desc": "购买刷新与道具"},
	{"id": "paper",  "name": "📄 造纸工坊",    "scene": "res://scenes/workshop/paper_craft_scene.tscn","desc": "制作空白卡牌"},
	{"id": "ink",    "name": "🖊️ 制墨工坊",    "scene": "res://scenes/workshop/ink_craft_scene.tscn", "desc": "调制墨线"},
	{"id": "arena",  "name": "⚔️ 训练场",      "scene": "res://scenes/world/world_map_scene.tscn", "desc": "测试卡组强度"},
	{"id": "craft",  "name": "🎨 制卡工坊",    "scene": "res://scenes/crafter/crafter.tscn",        "desc": "设计新卡牌"},
	{"id": "deck",   "name": "🃏 牌组",        "scene": "res://scenes/workshop/deck_scene.tscn",      "desc": "构建卡组"},
	{"id": "card_lib","name":"📚 卡册",         "scene": "res://scenes/workshop/card_library.tscn",    "desc": "浏览所有卡牌"},
]

func _ready():
	_ps = get_node("/root/PlayerSave")
	_build()

func _build():
	# 全屏背景
	var bg = ColorRect.new()
	bg.name = "BG"
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	bg.color = Color(0.06, 0.07, 0.1, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0
	bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	bg.offset_left = 0; bg.offset_top = 0
	bg.offset_right = 0; bg.offset_bottom = 0
	add_child(bg)

	# 顶部导航栏
	var nav = Panel.new()
	nav.name = "NavBar"
	nav.mouse_filter = MOUSE_FILTER_IGNORE
	nav.anchor_left = 0.0; nav.anchor_top = 0.0
	nav.anchor_right = 1.0; nav.anchor_bottom = 0.0
	nav.offset_top = 0
	nav.offset_bottom = 130
	var nav_ss = StyleBoxFlat.new()
	nav_ss.bg_color = Color(0.08, 0.08, 0.15, 0.95)
	nav_ss.border_color = Color(0.3, 0.3, 0.5, 0.5)
	nav_ss.border_width_bottom = 2
	nav.add_theme_stylebox_override("panel", nav_ss)
	nav.z_index = 100
	add_child(nav)

	# 返回按钮
	var back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.text = "← 返回"
	back_btn.anchor_left = 0.0; back_btn.anchor_top = 0.5
	back_btn.anchor_right = 0.0; back_btn.anchor_bottom = 0.5
	back_btn.offset_left = 15
	back_btn.offset_top = -22
	back_btn.offset_right = 120
	back_btn.offset_bottom = 22
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(_on_back_pressed)
	nav.add_child(back_btn)

	# 标题
	var title_lbl = Label.new()
	title_lbl.name = "Title"
	title_lbl.text = "🏙️ 工坊小镇"
	title_lbl.anchor_left = 0.5; title_lbl.anchor_top = 0.0
	title_lbl.anchor_right = 0.5; title_lbl.anchor_bottom = 1.0
	title_lbl.offset_left = -120; title_lbl.offset_top = 0
	title_lbl.offset_right = 120; title_lbl.offset_bottom = 0
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	nav.add_child(title_lbl)

	# 金币
	var gold_lbl = Label.new()
	gold_lbl.name = "GoldLbl"
	gold_lbl.text = "💰 %d 金" % _ps.gold
	gold_lbl.anchor_left = 1.0; gold_lbl.anchor_top = 0.0
	gold_lbl.anchor_right = 1.0; gold_lbl.anchor_bottom = 1.0
	gold_lbl.offset_left = -150; gold_lbl.offset_top = 0
	gold_lbl.offset_right = -15; gold_lbl.offset_bottom = 0
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_lbl.add_theme_font_size_override("font_size", 24)
	nav.add_child(gold_lbl)

	# 内容层
	var scroll = ScrollContainer.new()
	scroll.name = "Content"
	scroll.anchor_left = 0.0; scroll.anchor_top = 0.0
	scroll.anchor_right = 1.0; scroll.anchor_bottom = 1.0
	scroll.offset_left = 20; scroll.offset_top = 140
	scroll.offset_right = -20; scroll.offset_bottom = -20
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var inner = VBoxContainer.new()
	inner.name = "Inner"
	inner.add_theme_constant_override("separation", 20)
	scroll.add_child(inner)

	# 提示语
	var hint = Label.new()
	hint.text = "选择要前往的设施"
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(hint)

	# 建筑按钮列表
	var grid = GridContainer.new()
	grid.name = "BuildingGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	inner.add_child(grid)

	for building in BUILDINGS:
		var panel = _make_building_panel(building)
		grid.add_child(panel)

	# 底部信息栏
	var info_bar = Panel.new()
	info_bar.name = "InfoBar"
	info_bar.anchor_left = 0.0; info_bar.anchor_top = 1.0
	info_bar.anchor_right = 1.0; info_bar.anchor_bottom = 1.0
	info_bar.offset_left = 0; info_bar.offset_top = -100
	info_bar.offset_right = 0; info_bar.offset_bottom = 0
	var info_ss = StyleBoxFlat.new()
	info_ss.bg_color = Color(0.06, 0.06, 0.12, 0.95)
	info_ss.border_color = Color(0.25, 0.25, 0.4, 0.4)
	info_ss.border_width_top = 1
	info_bar.add_theme_stylebox_override("panel", info_ss)
	info_bar.z_index = 100
	add_child(info_bar)

	var deck_count_lbl = Label.new()
	deck_count_lbl.name = "DeckCount"
	deck_count_lbl.text = "牌组: %d / 20 张" % _ps.deck_cards.size()
	deck_count_lbl.anchor_left = 0.0; deck_count_lbl.anchor_top = 0.5
	deck_count_lbl.anchor_right = 0.5; deck_count_lbl.anchor_bottom = 0.5
	deck_count_lbl.offset_left = 20; deck_count_lbl.offset_top = -16
	deck_count_lbl.offset_right = 0; deck_count_lbl.offset_bottom = 16
	deck_count_lbl.add_theme_font_size_override("font_size", 22)
	deck_count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85, 1.0))
	info_bar.add_child(deck_count_lbl)

	var card_count_lbl = Label.new()
	card_count_lbl.name = "CardCount"
	card_count_lbl.text = "卡牌: %d 张" % _ps.owned_card_paths.size()
	card_count_lbl.anchor_left = 0.5; card_count_lbl.anchor_top = 0.5
	card_count_lbl.anchor_right = 1.0; card_count_lbl.anchor_bottom = 0.5
	card_count_lbl.offset_left = 0; card_count_lbl.offset_top = -16
	card_count_lbl.offset_right = -20; card_count_lbl.offset_bottom = 16
	card_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card_count_lbl.add_theme_font_size_override("font_size", 22)
	card_count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85, 1.0))
	info_bar.add_child(card_count_lbl)

func _make_building_panel(building: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.name = "Bld_%s" % building["id"]
	panel.custom_minimum_size = Vector2(460, 160)
	var ss = StyleBoxFlat.new()
	ss.bg_color = Color(0.1, 0.12, 0.2, 0.95)
	ss.border_color = Color(0.4, 0.38, 0.2, 0.7)
	ss.border_width_left = 2
	ss.border_width_right = 2
	ss.border_width_top = 2
	ss.border_width_bottom = 2
	ss.corner_radius_top_left = 12
	ss.corner_radius_top_right = 12
	ss.corner_radius_bottom_left = 12
	ss.corner_radius_bottom_right = 12
	ss.content_margin_left = 20
	ss.content_margin_right = 20
	ss.content_margin_top = 20
	ss.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", ss)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = building["name"]
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = building["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 22)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.78, 1.0))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_lbl)

	var enter_btn = Button.new()
	enter_btn.text = "进入"
	enter_btn.add_theme_font_size_override("font_size", 26)
	enter_btn.pressed.connect(func(): _on_building_entered(building))
	vbox.add_child(enter_btn)

	return panel

func _on_building_entered(building: Dictionary):
	_ps.last_scene = "res://scenes/world/city_map_scene.tscn"
	_ps.save_data()
	get_tree().change_scene_to_file(building["scene"])

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/world/world_map_scene.tscn")
