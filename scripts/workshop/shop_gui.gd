extends Control

var _shop_items: Array[Dictionary] = []
var _item_panels: Array[PanelContainer] = []
var _gold_label: Label = null

func _enter_tree():
	_build()

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
	
	var hint = Label.new()
	hint.text = "使用材料制作特殊卡牌"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_font_size_override("font_size", 32)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(hint)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	
	_shop_items = _get_shop_items()
	_item_panels.clear()
	
	for item in _shop_items:
		var panel = _make_item_panel(item)
		content.add_child(panel)
		_item_panels.append(panel)
	
	vbox.add_child(HSeparator.new())
	
	var back_btn = Button.new()
	back_btn.text = "返回主界面"
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.custom_minimum_size = Vector2(0, 80)
	back_btn.add_theme_font_size_override("font_size", 36)
	var nss = StyleBoxFlat.new()
	nss.bg_color = Color(0.2, 0.2, 0.3)
	nss.corner_radius_top_left = 8; nss.corner_radius_top_right = 8
	nss.corner_radius_bottom_left = 8; nss.corner_radius_bottom_right = 8
	back_btn.add_theme_stylebox_override("normal", nss)
	back_btn.pressed.connect(_on_back)
	vbox.add_child(back_btn)
	
	_refresh_gold()

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
	lbl.text = "商店"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	lbl.add_theme_font_size_override("font_size", 48)
	nav.add_child(lbl)
	
	_gold_label = Label.new()
	_gold_label.set_meta("is_gold", true)
	_gold_label.text = "100金"
	_gold_label.add_theme_font_size_override("font_size", 36)
	_gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	nav.add_child(_gold_label)
	
	return nav

func _get_shop_items() -> Array[Dictionary]:
	return [
		{
			"id": "SHOP05",
			"name": "刷新委托",
			"desc": "更换当前所有委托",
			"cost": 20,
			"type": "refresh_commission",
			"icon": "refresh"
		},
		{
			"id": "SHOP06",
			"name": "卡师指南",
			"desc": "解锁全部卡牌模板",
			"cost": 150,
			"type": "unlock_all",
			"icon": "book"
		}
	]

func _make_item_panel(item: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 0)
	
	var normal_s = StyleBoxFlat.new()
	normal_s.bg_color = Color(0.12, 0.14, 0.22)
	normal_s.border_width_left = 2; normal_s.border_width_right = 2
	normal_s.border_width_top = 2; normal_s.border_width_bottom = 2
	normal_s.border_color = Color(0.3, 0.3, 0.4)
	normal_s.corner_radius_top_left = 10; normal_s.corner_radius_top_right = 10
	normal_s.corner_radius_bottom_left = 10; normal_s.corner_radius_bottom_right = 10
	normal_s.content_margin_left = 16; normal_s.content_margin_right = 16
	normal_s.content_margin_top = 12; normal_s.content_margin_bottom = 12
	
	panel.add_theme_stylebox_override("panel", normal_s.duplicate())
	panel.set_meta("item_id", item["id"])
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)
	
	var icon_box = PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(90, 90)
	var icon_s = StyleBoxFlat.new()
	icon_s.bg_color = Color(0.15, 0.18, 0.28)
	icon_s.border_width_left = 2; icon_s.border_width_right = 2
	icon_s.border_width_top = 2; icon_s.border_width_bottom = 2
	icon_s.border_color = Color(0.3, 0.35, 0.5)
	icon_s.corner_radius_top_left = 8; icon_s.corner_radius_top_right = 8
	icon_s.corner_radius_bottom_left = 8; icon_s.corner_radius_bottom_right = 8
	icon_box.add_theme_stylebox_override("panel", icon_s)
	hbox.add_child(icon_box)
	
	var icon_lbl = Label.new()
	icon_lbl.text = _get_icon_text(item.get("icon", "item"))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 40)
	icon_box.add_child(icon_lbl)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = item["name"]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = item["desc"]
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 28)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_lbl)
	
	var buy_btn = Button.new()
	buy_btn.text = "%d金" % item["cost"]
	buy_btn.custom_minimum_size = Vector2(140, 65)
	buy_btn.add_theme_font_size_override("font_size", 32)
	var nss = StyleBoxFlat.new()
	nss.bg_color = Color(0.2, 0.5, 0.85)
	nss.corner_radius_top_left = 8; nss.corner_radius_top_right = 8
	nss.corner_radius_bottom_left = 8; nss.corner_radius_bottom_right = 8
	buy_btn.add_theme_stylebox_override("normal", nss)
	var pss = nss.duplicate()
	pss.bg_color = Color(0.15, 0.4, 0.7)
	buy_btn.add_theme_stylebox_override("pressed", pss)
	var dis_s = nss.duplicate()
	dis_s.bg_color = Color(0.15, 0.15, 0.2)
	buy_btn.add_theme_stylebox_override("disabled", dis_s)
	buy_btn.pressed.connect(_on_buy.bind(item))
	hbox.add_child(buy_btn)
	
	return panel

func _get_icon_text(icon_type: String) -> String:
	match icon_type:
		"paper": return "[P]"
		"ink": return "[I]"
		"core": return "[C]"
		"aux": return "[A]"
		"refresh": return "[R]"
		"book": return "[B]"
		_: return "[?]"

func _on_buy(item: Dictionary):
	var player = get_node("/root/PlayerSave")
	if player.gold < item["cost"]:
		ToastManager.show("金币不足")
		return
	
	if not player.spend_gold(item["cost"]):
		return
	
	var item_type = item["type"]
	
	if item_type == "refresh_commission":
		ToastManager.show("委托已刷新")
		ToastManager.show(item["name"] + " 购买成功")
	elif item_type == "unlock_all":
		ToastManager.show("已解锁全部模板")
	else:
		ToastManager.show(item["name"] + " 购买成功")
	
	_refresh_gold()

func _refresh_gold():
	if _gold_label != null:
		var player = get_node("/root/PlayerSave")
		_gold_label.text = "%d金" % player.gold

func _on_back():
	get_tree().change_scene_to_file("res://scenes/world/city_map_scene.tscn")
