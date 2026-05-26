# backpack_gui.gd
# 背包界面 — 标签切换：素材/成品/卡牌
extends Control

signal material_selected(mat_type: String, mat_id: String)

var _current_tab: String = "material"  # "material" / "product" / "card"
var _content: VBoxContainer = null
var _scroll: ScrollContainer = null
var _items_container: VBoxContainer = null
var _select_mode: String = ""  # 非空时为选择模式（"paper"/"ink"/"core"/"aux"）

func _ready():
	_build()
	visible = true

func _build():
	# 全屏背景
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.12, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0
	bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	bg.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			if _select_mode.is_empty():
				_close()
	)
	add_child(bg)

	# 主面板
	var panel = PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.0; panel.anchor_bottom = 1.0
	panel.offset_left = -540; panel.offset_right = 540
	panel.offset_top = 0; panel.offset_bottom = 0
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.10, 0.16, 1.0)
	ps.border_width_left = 2; ps.border_width_right = 2
	ps.border_color = Color(0.4, 0.4, 0.6)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	# 标题栏
	var title_row = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(title_row)

	var back_btn = Button.new()
	back_btn.text = "←返回"
	back_btn.custom_minimum_size = Vector2(140, 80)
	var bbs = StyleBoxFlat.new()
	bbs.bg_color = Color(0.3, 0.25, 0.4, 1.0)
	bbs.corner_radius_top_left = 10; bbs.corner_radius_top_right = 10
	bbs.corner_radius_bottom_left = 10; bbs.corner_radius_bottom_right = 10
	back_btn.add_theme_stylebox_override("normal", bbs)
	back_btn.add_theme_font_size_override("font_size", 30)
	back_btn.pressed.connect(_close)
	title_row.add_child(back_btn)

	var title_lbl = Label.new()
	title_lbl.text = "🎒 背包"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 44)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title_row.add_child(title_lbl)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(140, 0)
	title_row.add_child(spacer)

	# 标签切换栏
	var tab_row = HBoxContainer.new()
	tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_row.custom_minimum_size = Vector2(0, 80)
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(tab_row)

	var tabs = [
		{"id": "material", "name": "📦 素材", "color": Color(0.4, 0.5, 0.7)},
		{"id": "product", "name": "✨ 成品", "color": Color(0.5, 0.7, 0.4)},
		{"id": "card", "name": "🃏 卡牌", "color": Color(0.7, 0.6, 0.3)}
	]
	for tab in tabs:
		var btn = Button.new()
		btn.set_meta("tab_id", tab["id"])
		btn.text = tab["name"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(250, 70)
		var tbs = StyleBoxFlat.new()
		tbs.bg_color = tab["color"]
		tbs.corner_radius_top_left = 10; tbs.corner_radius_top_right = 10
		tbs.corner_radius_bottom_left = 10; tbs.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("normal", tbs)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_tab_click.bind(tab["id"]))
		tab_row.add_child(btn)

	vbox.add_child(HSeparator.new())

	# 滚动区
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_items_container = VBoxContainer.new()
	_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_container.add_theme_constant_override("separation", 10)
	_scroll.add_child(_items_container)

	_load_items()

func _on_tab_click(tab_id: String):
	_current_tab = tab_id
	_refresh_items()

func _load_items():
	for ch in _items_container.get_children():
		ch.queue_free()

	# 选择模式：顶部显示"取消"按钮
	if not _select_mode.is_empty():
		var cancel_btn = Button.new()
		cancel_btn.text = "❌ 取消选择"
		cancel_btn.custom_minimum_size = Vector2(0, 70)
		cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cancel_btn.add_theme_font_size_override("font_size", 32)
		var cbs = StyleBoxFlat.new()
		cbs.bg_color = Color(0.3, 0.15, 0.15)
		cbs.corner_radius_top_left = 8
		cbs.corner_radius_top_right = 8
		cbs.corner_radius_bottom_left = 8
		cbs.corner_radius_bottom_right = 8
		cancel_btn.add_theme_stylebox_override("normal", cbs)
		cancel_btn.pressed.connect(func():
			_select_mode = ""
			visible = false
		)
		_items_container.add_child(cancel_btn)

	var ps = get_node("/root/PlayerSave")

	match _current_tab:
		"material":
			_load_materials(ps)
		"product":
			_load_products(ps)
		"card":
			_load_cards(ps)

func _refresh_items():
	_load_items()

# ── 打开背包并切换到指定材料选择模式 ──
func open(mat_type: String):
	_select_mode = mat_type
	# 卡纸/墨线在成品标签，能量核/辅材在素材标签
	if mat_type == "paper" or mat_type == "ink":
		_current_tab = "product"
	else:
		_current_tab = "material"
	visible = true
	_load_items()

# ── 素材ID → Emoji 图标 ──
func _material_icon(mat_id: String) -> String:
	var icons = {
		"M01": "🪵",  # 木材碎片
		"M02": "💎",  # 星辉石粉
		"M03": "🧴",  # 魔化树脂
		"M04": "🩸",  # 龙血墨囊
		"M05": "🌿",  # 灵光苔藓
		"M06": "⚡",  # 雷击木
		"M07": "🧊",  # 霜晶石
		"M08": "🌋",  # 火山灰
		"M09": "👻",  # 幽魂丝
		"M10": "⚗️",  # 灵泉水
	}
	return icons.get(mat_id, "📦")

func _load_materials(ps: Node):
	var has_any = false
	for mat in MaterialData.MATERIALS:
		var mat_id = mat["id"]
		var count = ps.get_material_count(mat_id) if ps else 0
		if count <= 0:
			continue  # 数量为0不显示
		var icon = _material_icon(mat_id)
		if not _select_mode.is_empty():
			# 选择模式：创建可点击行
			_add_selectable_item(mat_id, "%s %s" % [icon, mat["name"]], "%s（库存:%d）" % [mat["desc"], count])
		else:
			_add_item_row(mat_id, "%s %s" % [icon, mat["name"]], "%s（库存:%d）" % [mat["desc"], count], count)
		has_any = true

	if not has_any:
		_add_empty_hint("暂无素材\n在野外采集资源吧！")

func _load_products(ps: Node):
	var has_any = false

	# 白卡（造纸产物）— 选择"paper"时显示
	if _select_mode.is_empty() or _select_mode == "paper":
		# 不使用卡纸选项
		if _select_mode == "paper":
			_add_selectable_item("PG00", "📄 不使用卡纸", "默认白卡，能量上限3.0")
		if ps.owned_white_cards.size() > 0:
			var section_lbl = Label.new()
			section_lbl.text = "─── 🃏 白卡（造纸产物）───"
			section_lbl.add_theme_font_size_override("font_size", 26)
			section_lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3))
			_items_container.add_child(section_lbl)

			for wc in ps.owned_white_cards:
				var name = wc.get("name", "白卡")
				var quality = wc.get("quality", 0)
				var grade = wc.get("grade", "标准")
				var mat_id = wc.get("id", name)
				if not _select_mode.is_empty():
					_add_selectable_item(mat_id, "📄 %s" % name, "品质:%s %.2f" % [grade, quality])
				else:
					_add_item_row(mat_id, "📄 %s" % name, "品质:%s %.2f" % [grade, quality], 1)
				has_any = true

	# 墨线（制墨产物）— 选择"ink"时显示
	if _select_mode.is_empty() or _select_mode == "ink":
		# 不使用墨线选项
		if _select_mode == "ink":
			_add_selectable_item("INK00", "🖌️ 不使用墨线", "默认墨线，品质无加成")
		if ps.owned_inks.size() > 0:
			var section_lbl2 = Label.new()
			section_lbl2.text = "─── 🖌️ 墨线（制墨产物）───"
			section_lbl2.add_theme_font_size_override("font_size", 26)
			section_lbl2.add_theme_color_override("font_color", Color(0.3, 0.6, 0.8))
			_items_container.add_child(section_lbl2)

			for ik in ps.owned_inks:
				var name = ik.get("name", "墨线")
				var quality = ik.get("quality", 0)
				var grade = ik.get("grade", "标准")
				var mat_id = ik.get("id", name)
				if not _select_mode.is_empty():
					_add_selectable_item(mat_id, "🖌️ %s" % name, "品质:%s %.2f" % [grade, quality])
				else:
					_add_item_row(mat_id, "🖌️ %s" % name, "品质:%s %.2f" % [grade, quality], 1)
				has_any = true

	# 能量核 — 选择"core"时显示
	if _select_mode.is_empty() or _select_mode == "core":
		var cores_def = [
			{"id": "EC01", "name": "火属能量核", "desc": "火属性强化"},
			{"id": "EC02", "name": "水属能量核", "desc": "水属性强化"},
			{"id": "EC03", "name": "风属能量核", "desc": "风属性强化"},
			{"id": "EC04", "name": "混沌能量核", "desc": "无属性（免费）"}
		]
		var has_cores = false
		for ec in cores_def:
			var count = ps.get_material_count(ec["id"]) if ps else 0
			if ec["id"] == "EC04":
				count = 1  # EC04无消耗
			if count > 0:
				if not has_cores:
					var section_lbl3 = Label.new()
					section_lbl3.text = "─── 💎 能量核 ───"
					section_lbl3.add_theme_font_size_override("font_size", 26)
					section_lbl3.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
					_items_container.add_child(section_lbl3)
					has_cores = true
				if not _select_mode.is_empty():
					_add_selectable_item(ec["id"], "💎 %s" % ec["name"], "%s（库存:%d）" % [ec["desc"], count])
				else:
					_add_item_row(ec["id"], "💎 %s" % ec["name"], "%s（库存:%d）" % [ec["desc"], count], count)
				has_any = true

	if not has_any:
		_add_empty_hint("暂无成品，请先去工坊制作")

func _load_cards(ps: Node):
	# 从 user://cards/ 读取已保存的卡牌文件，显示名称列表
	var has_any = false

	var dir = DirAccess.open("user://")
	if not dir or not dir.dir_exists("cards"):
		_add_empty_hint("暂无卡牌")
		return

	dir = DirAccess.open("user://cards/")
	if not dir:
		_add_empty_hint("暂无卡牌")
		return

	var files = dir.get_files()
	var card_files: Array[String] = []
	for f in files:
		if f.ends_with(".json"):
			card_files.append(f)

	if card_files.size() == 0:
		_add_empty_hint("暂无卡牌\n去制卡师公会制作卡牌")
		return

	card_files.sort()
	card_files.reverse()

	var section_lbl = Label.new()
	section_lbl.text = "─── 🃏 图鉴（%d张）───" % card_files.size()
	section_lbl.add_theme_font_size_override("font_size", 26)
	section_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	_items_container.add_child(section_lbl)
	has_any = true

	for fname in card_files:
		var path = "user://cards/" + fname
		var data = _load_card_file(path)
		if not data.is_empty():
			var name = data.get("name", "未知卡牌")
			var quality = data.get("quality", 0.0)
			var card_type = data.get("card_type", "怪兽")
			var type_icon = "⚔️"
			if card_type == "魔法":
				type_icon = "✨"
			elif card_type == "陷阱":
				type_icon = "⚡"
			_add_item_row(fname.replace(".json", ""), "%s %s" % [type_icon, name], "品质:%.2f" % quality, 1)
			has_any = true

	if not has_any:
		_add_empty_hint("暂无卡牌\n去制卡师公会制作卡牌")

func _load_card_file(path: String) -> Dictionary:
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var json_str = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(json_str) == OK:
		return json.data as Dictionary
	return {}

func _add_item_row(id: String, name: String, desc: String, count: int):
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 90)

	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.12, 0.14, 0.22)
	ns.border_width_left = 2; ns.border_width_right = 2
	ns.border_width_top = 2; ns.border_width_bottom = 2
	ns.border_color = Color(0.3, 0.3, 0.4)
	ns.corner_radius_top_left = 10; ns.corner_radius_top_right = 10
	ns.corner_radius_bottom_left = 10; ns.corner_radius_bottom_right = 10
	ns.content_margin_left = 16; ns.content_margin_right = 16
	ns.content_margin_top = 8; ns.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", ns)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hbox)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_lbl = Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", 34)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	info.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 26)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	info.add_child(desc_lbl)

	if count > 0:
		var cnt_lbl = Label.new()
		cnt_lbl.text = "×%d" % count
		cnt_lbl.add_theme_font_size_override("font_size", 32)
		cnt_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
		hbox.add_child(cnt_lbl)

	_items_container.add_child(row)

# ── 可选择的材料行（点击后触发 material_selected 信号） ──
func _add_selectable_item(mat_id: String, name: String, desc: String):
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 90)

	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.12, 0.22, 0.14)  # 绿色背景表示可选
	ns.border_width_left = 2; ns.border_width_right = 2
	ns.border_width_top = 2; ns.border_width_bottom = 2
	ns.border_color = Color(0.3, 0.6, 0.4)
	ns.corner_radius_top_left = 10; ns.corner_radius_top_right = 10
	ns.corner_radius_bottom_left = 10; ns.corner_radius_bottom_right = 10
	ns.content_margin_left = 16; ns.content_margin_right = 16
	ns.content_margin_top = 8; ns.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", ns)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hbox)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_lbl = Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", 34)
	name_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	info.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 26)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	info.add_child(desc_lbl)

	var select_lbl = Label.new()
	select_lbl.text = "✅ 点击选择"
	select_lbl.add_theme_font_size_override("font_size", 28)
	select_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	hbox.add_child(select_lbl)

	# 点击事件
	row.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			material_selected.emit(_select_mode, mat_id)
			_close()
	)

	_items_container.add_child(row)

func _add_empty_hint(msg: String):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_items_container.add_child(lbl)

func _close():
	if not _select_mode.is_empty():
		# 选择模式：只隐藏背包，不切换场景
		_select_mode = ""
		visible = false
		return
	var ps = get_node("/root/PlayerSave")
	var return_scene = ps.last_scene
	print("[DEBUG] backpack close, last_scene=", return_scene, " (empty=main)")
	if return_scene.is_empty():
		return_scene = "res://scenes/main.tscn"
	get_tree().change_scene_to_file(return_scene)
