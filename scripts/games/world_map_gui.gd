extends Control

# ── 区域定义 ──
const AREAS: Array[Dictionary] = [
	{
		"id": 0,
		"name": "🔥 火焰森林",
		"level": 1,
		"desc": "火系素材采集地",
		"drops": ["M01", "M05", "M08"],
		"enemy_level": 1,
		"node_count": 4
	},
	{
		"id": 1,
		"name": "❄️ 冰霜洞穴",
		"level": 1,
		"desc": "水系素材采集地",
		"drops": ["M02", "M05", "M07"],
		"enemy_level": 1,
		"node_count": 4
	},
	{
		"id": 2,
		"name": "⚡ 雷光高地",
		"level": 2,
		"desc": "雷系素材采集地",
		"drops": ["M03", "M05", "M06", "M08"],
		"enemy_level": 2,
		"node_count": 5
	},
	{
		"id": 3,
		"name": "✨ 神秘遗迹",
		"level": 3,
		"desc": "稀有素材采集地",
		"drops": ["M04", "M09", "M02", "M10"],
		"enemy_level": 3,
		"node_count": 5
	}
]

# 节点类型
const NODE_BATTLE = "battle"
const NODE_ELITE = "elite"
const NODE_SHOP = "shop"
const NODE_EVENT = "event"
const NODE_BOSS = "boss"

var _ps: Node
var _nav_bar: Panel
var _content: Control  # 当前内容层（区域列表 或 节点列表）
var _area_buttons: Array = []
var _node_buttons: Array = []
var _current_area: Dictionary = {}
var _overlay_count: int = 0

func _ready():
	_ps = get_node("/root/PlayerSave")
	_build()

func _build():
	# 清除旧内容
	if _content:
		_content.queue_free()
	_content = null
	for btn in _area_buttons:
		if btn:
			btn.queue_free()
	_area_buttons.clear()
	for btn in _node_buttons:
		if btn:
			btn.queue_free()
	_node_buttons.clear()

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
	_nav_bar = Panel.new()
	_nav_bar.name = "NavBar"
	_nav_bar.mouse_filter = MOUSE_FILTER_IGNORE
	_nav_bar.anchor_left = 0.0; _nav_bar.anchor_top = 0.0
	_nav_bar.anchor_right = 1.0; _nav_bar.anchor_bottom = 0.0
	_nav_bar.offset_top = 0
	_nav_bar.offset_bottom = 130
	var nav_ss = StyleBoxFlat.new()
	nav_ss.bg_color = Color(0.08, 0.08, 0.15, 0.95)
	nav_ss.border_color = Color(0.3, 0.3, 0.5, 0.5)
	nav_ss.border_width_bottom = 2
	_nav_bar.add_theme_stylebox_override("panel", nav_ss)
	add_child(_nav_bar)

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
	_nav_bar.add_child(back_btn)

	# 工坊按钮
	var city_btn = Button.new()
	city_btn.name = "CityBtn"
	city_btn.text = "🏙️ 工坊"
	city_btn.anchor_left = 1.0; city_btn.anchor_top = 0.5
	city_btn.anchor_right = 1.0; city_btn.anchor_bottom = 0.5
	city_btn.offset_left = -120
	city_btn.offset_top = -22
	city_btn.offset_right = -15
	city_btn.offset_bottom = 22
	city_btn.add_theme_font_size_override("font_size", 22)
	city_btn.pressed.connect(_on_city_pressed)
	_nav_bar.add_child(city_btn)

	# 标题
	var title_lbl = Label.new()
	title_lbl.name = "Title"
	title_lbl.text = "🗺️ 冒险地图"
	title_lbl.anchor_left = 0.5; title_lbl.anchor_top = 0.0
	title_lbl.anchor_right = 0.5; title_lbl.anchor_bottom = 1.0
	title_lbl.offset_left = -120; title_lbl.offset_top = 0
	title_lbl.offset_right = 120; title_lbl.offset_bottom = 0
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	_nav_bar.add_child(title_lbl)

	# 金币显示
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
	_nav_bar.add_child(gold_lbl)

	# 内容层
	_content = Control.new()
	_content.name = "Content"
	_content.anchor_left = 0.0; _content.anchor_top = 0.0
	_content.anchor_right = 1.0; _content.anchor_bottom = 1.0
	_content.offset_left = 0; _content.offset_top = 130
	_content.offset_right = 0; _content.offset_bottom = 0
	add_child(_content)
	_content.z_index = 10

	_show_area_list()

func _show_area_list():
	if _content:
		_content.queue_free()
	_content = null

	var wrap = VBoxContainer.new()
	wrap.name = "AreaList"
	wrap.anchor_left = 0.0; wrap.anchor_top = 0.0
	wrap.anchor_right = 1.0; wrap.anchor_bottom = 1.0
	wrap.offset_left = 20; wrap.offset_top = 140
	wrap.offset_right = -20; wrap.offset_bottom = -10
	wrap.add_theme_constant_override("separation", 20)
	add_child(wrap)
	_content = wrap

	# 区域标题
	var hint = Label.new()
	hint.text = "选择要挑战的区域"
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wrap.add_child(hint)

	# 2x2 区域网格
	var grid = GridContainer.new()
	grid.name = "AreaGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	wrap.add_child(grid)

	for area in AREAS:
		var panel = _make_area_panel(area)
		grid.add_child(panel)
		_area_buttons.append(panel)

func _make_area_panel(area: Dictionary) -> Panel:
	var complete_node: int = _ps.get_area_node_complete(area["id"])
	var total_nodes: int = area["node_count"]
	var is_cleared: bool = complete_node >= total_nodes - 1

	var panel = Panel.new()
	panel.name = "Area_%d" % area["id"]
	panel.custom_minimum_size = Vector2(480, 260)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ss = StyleBoxFlat.new()
	ss.bg_color = Color(0.12, 0.14, 0.22, 0.95)
	ss.border_color = Color(0.4, 0.4, 0.6, 0.7) if not is_cleared else Color(0.3, 0.7, 0.3, 0.8)
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
	name_lbl.text = area["name"]
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5, 1.0))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = area["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 22)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1.0))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_lbl)

	var level_lbl = Label.new()
	level_lbl.text = "难度: Lv%d" % area["level"]
	level_lbl.add_theme_font_size_override("font_size", 20)
	level_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1.0))
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_lbl)

	var progress_lbl = Label.new()
	if is_cleared:
		progress_lbl.text = "✅ 已通关"
	else:
		progress_lbl.text = "进度: %d / %d 层" % [complete_node + 1, total_nodes]
	progress_lbl.add_theme_font_size_override("font_size", 20)
	progress_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5, 1.0))
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(progress_lbl)

	var enter_btn = Button.new()
	enter_btn.text = "进入" if not is_cleared else "再次挑战"
	enter_btn.add_theme_font_size_override("font_size", 26)
	enter_btn.pressed.connect(func(): _on_area_entered(area))
	vbox.add_child(enter_btn)

	return panel

func _on_area_entered(area: Dictionary):
	_ps.current_area_index = area["id"]
	_current_area = area
	_show_node_list(area)

func _show_node_list(area: Dictionary):
	if _content:
		_content.queue_free()
	_content = null

	_content = VBoxContainer.new()
	_content.name = "NodeList"
	_content.anchor_left = 0.0; _content.anchor_top = 0.0
	_content.anchor_right = 1.0; _content.anchor_bottom = 1.0
	_content.offset_left = 0; _content.offset_top = 140
	_content.offset_right = 0; _content.offset_bottom = 0
	_content.add_theme_constant_override("separation", 20)
	add_child(_content)

	# 更新导航栏标题
	var title_lbl = _nav_bar.get_node_or_null("Title")
	if title_lbl:
		title_lbl.text = area["name"]

	var scroll = ScrollContainer.new()
	scroll.name = "NodeScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.anchor_left = 0.0; scroll.anchor_top = 0.0
	scroll.anchor_right = 1.0; scroll.anchor_bottom = 1.0
	scroll.offset_left = 20; scroll.offset_top = 10
	scroll.offset_right = -20; scroll.offset_bottom = -10
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)

	var inner = VBoxContainer.new()
	inner.name = "Inner"
	inner.add_theme_constant_override("separation", 18)
	scroll.add_child(inner)

	var complete_node: int = _ps.get_area_node_complete(area["id"])

	# 生成节点列表
	var nodes = _generate_nodes(area)

	var header = Label.new()
	header.text = "选择挑战节点"
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1.0))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(header)

	for i in range(nodes.size()):
		var node_data = nodes[i]
		var is_locked: bool = i > complete_node + 1
		var is_complete: bool = i <= complete_node
		var panel = _make_node_panel(area, i, node_data, is_locked, is_complete)
		inner.add_child(panel)
		_node_buttons.append(panel)

func _generate_nodes(area: Dictionary) -> Array[Dictionary]:
	var count: int = area["node_count"]
	var nodes: Array[Dictionary] = []
	for i in range(count):
		var node: Dictionary = {}
		if i == count - 1:
			node = {"type": NODE_BOSS, "name": "BOSS战", "desc": "区域首领"}
		elif i % 3 == 0 and i > 0:
			node = {"type": NODE_ELITE, "name": "精英战斗", "desc": "更高奖励"}
		elif i % 2 == 0:
			node = {"type": NODE_BATTLE, "name": "普通战斗", "desc": "推进进度"}
		else:
			node = {"type": NODE_EVENT, "name": "随机事件", "desc": "风险与机遇"}
		nodes.append(node)
	return nodes

func _make_node_panel(area: Dictionary, index: int, node_data: Dictionary, is_locked: bool, is_complete: bool) -> Panel:
	var panel = Panel.new()
	panel.name = "Node_%d" % index
	panel.custom_minimum_size = Vector2(0, 120)

	var ss = StyleBoxFlat.new()
	if is_locked:
		ss.bg_color = Color(0.08, 0.08, 0.12, 0.8)
		ss.border_color = Color(0.25, 0.25, 0.3, 0.5)
	elif is_complete:
		ss.bg_color = Color(0.06, 0.18, 0.06, 0.9)
		ss.border_color = Color(0.2, 0.6, 0.2, 0.7)
	else:
		ss.bg_color = Color(0.1, 0.12, 0.2, 0.95)
		ss.border_color = Color(0.5, 0.4, 0.1, 0.8)
	ss.border_width_left = 2
	ss.border_width_right = 2
	ss.border_width_top = 2
	ss.border_width_bottom = 2
	ss.corner_radius_top_left = 10
	ss.corner_radius_top_right = 10
	ss.corner_radius_bottom_left = 10
	ss.corner_radius_bottom_right = 10
	ss.content_margin_left = 20
	ss.content_margin_right = 20
	ss.content_margin_top = 14
	ss.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ss)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)

	# 节点图标
	var icon_lbl = Label.new()
	match node_data["type"]:
		NODE_BATTLE: icon_lbl.text = "⚔️"
		NODE_ELITE: icon_lbl.text = "💎"
		NODE_SHOP: icon_lbl.text = "🏪"
		NODE_EVENT: icon_lbl.text = "🎲"
		NODE_BOSS: icon_lbl.text = "👹"
	icon_lbl.add_theme_font_size_override("font_size", 40)
	hbox.add_child(icon_lbl)

	# 节点信息
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = node_data["name"]
	name_lbl.add_theme_font_size_override("font_size", 28)
	if is_locked:
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45, 1.0))
	elif is_complete:
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4, 1.0))
	else:
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = node_data["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 1.0))
	vbox.add_child(desc_lbl)

	var state_lbl = Label.new()
	if is_locked:
		state_lbl.text = "🔒 需先通关前一节点"
		state_lbl.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4, 1.0))
	elif is_complete:
		state_lbl.text = "✅ 已完成"
		state_lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3, 1.0))
	else:
		state_lbl.text = "▶️ 可挑战"
		state_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5, 1.0))
	state_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(state_lbl)

	# 进入按钮（空白撑开右侧）
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	if not is_locked:
		var enter_btn = Button.new()
		enter_btn.text = "挑战" if node_data["type"] != NODE_SHOP else "进入"
		enter_btn.add_theme_font_size_override("font_size", 24)
		enter_btn.pressed.connect(func(): _on_node_selected(area, index, node_data))
		hbox.add_child(enter_btn)

	return panel

func _on_node_selected(area: Dictionary, index: int, node_data: Dictionary):
	match node_data["type"]:
		NODE_BATTLE, NODE_ELITE, NODE_BOSS:
			_start_battle(area, index, node_data)
		NODE_EVENT:
			_trigger_event(area, index, node_data)
		NODE_SHOP:
			_open_temp_shop(area, index)

func _start_battle(area: Dictionary, index: int, node_data: Dictionary):
	_ps.current_area_index = area["id"]
	_ps.advance_area_node(area["id"], index)
	_ps.return_to_scene = "world_map_scene"
	_ps.save_data()
	# 同步到 ExploreManager（用于 battle_gui 判定掉落等级）
	var em = get_node_or_null("/root/ExploreManager")
	if em != null:
		em.selected_area_index = area["id"]
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")

func _trigger_event(area: Dictionary, index: int, node_data: Dictionary):
	# 随机事件：扣血/金币消耗/素材奖励
	var rng = RandomNumberGenerator.new()
	var roll = rng.randi() % 4

	var msg: String
	match roll:
		0:  # 扣金币
			var cost = rng.randi_range(10, 30)
			if _ps.gold >= cost:
				_ps.spend_gold(cost)
				msg = "遭遇盗贼！花费 %d 金" % cost
			else:
				msg = "金币不足，平安无事"
		1:  # 扣血（扣AP代指）
			var ap_cost = rng.randi_range(5, 15)
			if _ps.action_points >= ap_cost:
				_ps.spend_action_points(ap_cost)
				msg = "踩中陷阱！消耗 %d 体力" % ap_cost
			else:
				msg = "体力耗尽，平安无事"
		2:  # 奖励素材
			var mat_id = area["drops"][rng.randi() % area["drops"].size()]
			_ps.add_material(mat_id, 1)
			msg = "发现宝箱！获得 %s" % mat_id
		3:  # 奖励金币
			var reward = rng.randi_range(15, 40)
			_ps.add_gold(reward)
			msg = "完成委托！获得 %d 金" % reward

	_ps.advance_area_node(area["id"], index)
	_ps.save_data()
	_show_event_result(msg, area)

func _show_event_result(msg: String, area: Dictionary):
	var overlay = Panel.new()
	overlay.name = "EventOverlay"
	overlay.anchor_left = 0.0; overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0; overlay.anchor_bottom = 1.0
	overlay.z_index = 200

	var ov_ss = StyleBoxFlat.new()
	ov_ss.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.add_theme_stylebox_override("panel", ov_ss)
	add_child(overlay)

	var dialog = Panel.new()
	dialog.name = "EventDialog"
	dialog.anchor_left = 0.5; dialog.anchor_top = 0.5
	dialog.anchor_right = 0.5; dialog.anchor_bottom = 0.5
	dialog.offset_left = -360; dialog.offset_top = -180
	dialog.offset_right = 360; dialog.offset_bottom = 180
	var dlg_ss = StyleBoxFlat.new()
	dlg_ss.bg_color = Color(0.1, 0.12, 0.22, 0.98)
	dlg_ss.border_color = Color(0.8, 0.6, 0.2, 0.9)
	dlg_ss.border_width_left = 3; dlg_ss.border_width_right = 3
	dlg_ss.border_width_top = 3; dlg_ss.border_width_bottom = 3
	dlg_ss.corner_radius_top_left = 16
	dlg_ss.corner_radius_top_right = 16
	dlg_ss.corner_radius_bottom_left = 16
	dlg_ss.corner_radius_bottom_right = 16
	dialog.add_theme_stylebox_override("panel", dlg_ss)
	dialog.z_index = 201
	add_child(dialog)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.anchor_left = 0.5; vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5; vbox.anchor_bottom = 0.5
	vbox.offset_left = -300; vbox.offset_top = -140
	vbox.offset_right = 300; vbox.offset_bottom = 140
	dialog.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "🎲 随机事件"
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var msg_lbl = Label.new()
	msg_lbl.text = msg
	msg_lbl.add_theme_font_size_override("font_size", 26)
	msg_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9, 1.0))
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(msg_lbl)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	ok_btn.add_theme_font_size_override("font_size", 26)
	ok_btn.pressed.connect(func():
		overlay.queue_free()
		dialog.queue_free()
		_show_node_list(area)
	)
	vbox.add_child(ok_btn)

func _open_temp_shop(area: Dictionary, index: int):
	# 临时商店：购买当前区域素材
	var overlay = Panel.new()
	overlay.name = "ShopOverlay"
	overlay.anchor_left = 0.0; overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0; overlay.anchor_bottom = 1.0
	overlay.z_index = 200
	var ov_ss = StyleBoxFlat.new()
	ov_ss.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.add_theme_stylebox_override("panel", ov_ss)
	add_child(overlay)

	var dialog = Panel.new()
	dialog.name = "ShopDialog"
	dialog.anchor_left = 0.5; dialog.anchor_top = 0.5
	dialog.anchor_right = 0.5; dialog.anchor_bottom = 0.5
	dialog.offset_left = -400; dialog.offset_top = -320
	dialog.offset_right = 400; dialog.offset_bottom = 320
	var dlg_ss = StyleBoxFlat.new()
	dlg_ss.bg_color = Color(0.1, 0.12, 0.22, 0.98)
	dlg_ss.border_color = Color(0.6, 0.5, 0.2, 0.9)
	dlg_ss.border_width_left = 3; dlg_ss.border_width_right = 3
	dlg_ss.border_width_top = 3; dlg_ss.border_width_bottom = 3
	dlg_ss.corner_radius_top_left = 16; dlg_ss.corner_radius_top_right = 16
	dlg_ss.corner_radius_bottom_left = 16; dlg_ss.corner_radius_bottom_right = 16
	dialog.add_theme_stylebox_override("panel", dlg_ss)
	dialog.z_index = 201
	add_child(dialog)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.anchor_left = 0.5; vbox.anchor_top = 0.0
	vbox.anchor_right = 0.5; vbox.anchor_bottom = 1.0
	vbox.offset_left = -360; vbox.offset_top = 10
	vbox.offset_right = 360; vbox.offset_bottom = -10
	dialog.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "🏪 临时商店（当前区域掉落）"
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var gold_lbl = Label.new()
	gold_lbl.name = "GoldLbl"
	gold_lbl.text = "💰 %d 金" % _ps.gold
	gold_lbl.add_theme_font_size_override("font_size", 22)
	gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gold_lbl)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)

	var mat_prices = {
		"M01": 15, "M02": 15, "M03": 25, "M04": 35,
		"M05": 12, "M06": 25, "M07": 25, "M08": 12,
		"M09": 50, "M10": 80
	}
	var mat_names = {
		"M01": "木材碎片", "M02": "星辉石粉", "M03": "魔化树脂",
		"M04": "龙血墨囊", "M05": "灵光苔藓", "M06": "雷击木",
		"M07": "霜晶石", "M08": "火山灰", "M09": "幽魂丝",
		"M10": "时空砂"
	}

	for mat_id in area["drops"]:
		var price: int = mat_prices.get(mat_id, 20)
		var mat_panel = _make_shop_item(mat_id, mat_names.get(mat_id, mat_id), price, gold_lbl, overlay, dialog, area)
		grid.add_child(mat_panel)

	var close_btn = Button.new()
	close_btn.text = "关闭商店"
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(func():
		_ps.advance_area_node(area["id"], index)
		_ps.save_data()
		overlay.queue_free()
		dialog.queue_free()
		_show_node_list(area)
	)
	vbox.add_child(close_btn)

func _make_shop_item(mat_id: String, mat_name: String, price: int, gold_lbl: Label, overlay: Control, dialog: Control, area: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(320, 100)
	var ss = StyleBoxFlat.new()
	ss.bg_color = Color(0.08, 0.1, 0.18, 0.95)
	ss.border_color = Color(0.3, 0.3, 0.5, 0.6)
	ss.border_width_left = 1; ss.border_width_right = 1
	ss.border_width_top = 1; ss.border_width_bottom = 1
	ss.corner_radius_top_left = 8; ss.corner_radius_top_right = 8
	ss.corner_radius_bottom_left = 8; ss.corner_radius_bottom_right = 8
	ss.content_margin_left = 12; ss.content_margin_right = 12
	ss.content_margin_top = 8; ss.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", ss)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var name_lbl = Label.new()
	name_lbl.text = "%s ×1" % mat_name
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 1.0))
	hbox.add_child(name_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var buy_btn = Button.new()
	buy_btn.text = "%d金" % price
	buy_btn.add_theme_font_size_override("font_size", 22)
	buy_btn.pressed.connect(func():
		if _ps.spend_gold(price):
			_ps.add_material(mat_id, 1)
			gold_lbl.text = "💰 %d 金" % _ps.gold
	)
	hbox.add_child(buy_btn)

	return panel

func _on_back_pressed():
	if _content.name == "NodeList":
		_show_area_list()
		var title_lbl = _nav_bar.get_node_or_null("Title")
		if title_lbl:
			title_lbl.text = "🗺️ 冒险地图"
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_city_pressed():
	_ps.return_to_scene = "city_map_scene"
	_ps.save_data()
	get_tree().change_scene_to_file("res://scenes/world/city_map_scene.tscn")

func _input(event: InputEvent):
	pass

func _unhandled_input(event: InputEvent):
	pass
