extends Control

var _ready_done := false

# 卡牌数据
var card_name := "新卡牌"
var fields: Array[String] = []
var attack := 0
var health := 0
var speed := 0
var effects: Array[Dictionary] = []

# UI引用
var name_input: LineEdit
var fields_container: VBoxContainer
var effects_container: VBoxContainer
var energy_bar: Control
var export_btn: Button
var bottom_btn_row: HBoxContainer
var scroll: ScrollContainer
var vbox: VBoxContainer


func _enter_tree():
	_build()


func _build():
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0; bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	add_child(bg)

	# === 主VBox - 全屏布局 ===
	var root_vbox = VBoxContainer.new()
	root_vbox.anchor_left = 0.0; root_vbox.anchor_top = 0.0; root_vbox.anchor_right = 1.0; root_vbox.anchor_bottom = 1.0
	root_vbox.offset_left = 0; root_vbox.offset_top = 0; root_vbox.offset_right = 0; root_vbox.offset_bottom = 0
	add_child(root_vbox)

	# === 导航栏（固定顶部）===
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.size_flags_vertical = 0
	nav.custom_minimum_size = Vector2(0, 70)
	root_vbox.add_child(nav)

	var back = Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(70, 70)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	nav.add_child(back)

	var nav_title = Label.new()
	nav_title.text = "制卡师工坊"
	nav_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nav_title.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	nav_title.add_theme_font_size_override("font_size", 48)
	nav.add_child(nav_title)

	root_vbox.add_child(HSeparator.new())

	# === 滚动区域（填满中间）===
	scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# === 卡名 ===
	var name_row = HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(name_row)
	
	var name_icon = Label.new()
	name_icon.text = "📝"
	name_icon.custom_minimum_size = Vector2(60, 0)
	name_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_icon.add_theme_font_size_override("font_size", 40)
	name_row.add_child(name_icon)
	
	name_input = LineEdit.new()
	name_input.text = card_name
	name_input.placeholder_text = "输入卡牌名称"
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.custom_minimum_size = Vector2(0, 60)
	name_input.add_theme_font_size_override("font_size", 40)
	name_input.text_changed.connect(func(_t): _update())
	name_row.add_child(name_input)
	
	vbox.add_child(_vsp(12))
	
	# === 字段 ===
	var f_header = HBoxContainer.new()
	f_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(f_header)
	
	var f_title = Label.new()
	f_title.text = "🏷️ 字段"
	f_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f_title.add_theme_font_size_override("font_size", 48)
	f_header.add_child(f_title)
	
	var f_add = Button.new()
	f_add.text = "+"
	f_add.custom_minimum_size = Vector2(60, 60)
	f_add.add_theme_font_size_override("font_size", 40)
	f_add.pressed.connect(_add_field)
	f_header.add_child(f_add)
	
	fields_container = VBoxContainer.new()
	fields_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(fields_container)
	
	vbox.add_child(_vsp(12))
	
	# === 基础属性 ===
	var a_title = Label.new()
	a_title.text = "📊 基础属性"
	a_title.add_theme_color_override("font_color", Color(0.7, 0.7, 1, 1))
	a_title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(a_title)
	
	# 属性行：攻击 ➖ 0 ➕
	vbox.add_child(_stat_row("攻击", func(): return attack, func(v): attack = v))
	vbox.add_child(_stat_row("生命", func(): return health, func(v): health = v))
	vbox.add_child(_stat_row("速度", func(): return speed, func(v): speed = v))
	
	vbox.add_child(_vsp(12))

	# === 效果 ===
	var e_header = HBoxContainer.new()
	e_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(e_header)
	
	var e_title = Label.new()
	e_title.text = "⚡ 效果"
	e_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e_title.add_theme_color_override("font_color", Color(0.7, 0.7, 1, 1))
	e_title.add_theme_font_size_override("font_size", 48)
	e_header.add_child(e_title)
	
	var e_add = Button.new()
	e_add.text = "+ 添加"
	e_add.custom_minimum_size = Vector2(0, 60)
	e_add.add_theme_font_size_override("font_size", 32)
	e_add.pressed.connect(_add_effect)
	e_header.add_child(e_add)
	
	effects_container = VBoxContainer.new()
	effects_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effects_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(effects_container)
	
	vbox.add_child(_vsp(12))

	# === 能量 ===
	energy_bar = load("res://scripts/energy_bar.gd").new()
	energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(energy_bar)

	vbox.add_child(_vsp(12))

	# === 底部按钮 ===
	root_vbox.add_child(HSeparator.new())

	bottom_btn_row = HBoxContainer.new()
	bottom_btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_btn_row.size_flags_vertical = 0
	bottom_btn_row.custom_minimum_size = Vector2(0, 80)
	root_vbox.add_child(bottom_btn_row)

	var sv = _make_btn("💾 保存", _on_save)
	var next_btn = _make_btn("下一步 →", _on_next_phase)
	export_btn = _make_btn("📤 导出", _on_export)
	bottom_btn_row.add_child(sv); bottom_btn_row.add_child(next_btn); bottom_btn_row.add_child(export_btn)

	# === 版本号（固定最底部）===
	root_vbox.add_child(HSeparator.new())
	var ver = Label.new()
	ver.text = "v1.0 | 制卡器"
	ver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ver.size_flags_vertical = 0
	ver.custom_minimum_size = Vector2(0, 50)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 36)
	root_vbox.add_child(ver)

	_ready_done = true
	_update()


func _vsp(h: int) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _stat_row(text: String, getter: Callable, setter: Callable) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 70)
	
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(100, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	row.add_child(label)
	
	var minus = Button.new()
	minus.text = "➖"
	minus.custom_minimum_size = Vector2(70, 70)
	minus.add_theme_font_size_override("font_size", 32)
	row.add_child(minus)
	
	var val_label = Label.new()
	val_label.text = "0"
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_label.custom_minimum_size = Vector2(70, 0)
	val_label.add_theme_font_size_override("font_size", 44)
	row.add_child(val_label)
	
	var plus = Button.new()
	plus.text = "➕"
	plus.custom_minimum_size = Vector2(70, 70)
	plus.add_theme_font_size_override("font_size", 32)
	row.add_child(plus)
	
	var filler = Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(filler)
	
	minus.pressed.connect(func():
		setter.call(maxi(0, getter.call() - 1))
		val_label.text = str(getter.call())
		_update()
	)
	plus.pressed.connect(func():
		setter.call(mini(99, getter.call() + 1))
		val_label.text = str(getter.call())
		_update()
	)
	
	return row


func _make_btn(text: String, cb: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 70)
	btn.add_theme_font_size_override("font_size", 34)
	btn.pressed.connect(cb)
	return btn


# === 字段 ===

func _add_field():
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var input = LineEdit.new()
	input.text = "新字段"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size = Vector2(0, 60)
	input.add_theme_font_size_override("font_size", 34)
	input.text_changed.connect(func(_t): _update())
	row.add_child(input)
	
	var del = Button.new()
	del.text = "✕"
	del.custom_minimum_size = Vector2(60, 60)
	del.add_theme_font_size_override("font_size", 30)
	del.pressed.connect(func():
		row.queue_free()
		_update()
	)
	row.add_child(del)
	
	fields_container.add_child(row)


# === 效果 ===

func _add_effect():
	var row = load("res://scripts/effect_row.gd").new()
	row.set_index(effects_container.get_child_count())
	row.removed.connect(_on_effect_removed)
	row.copied.connect(_on_effect_copied.bind(row))
	row.data_changed.connect(_on_effects_changed)
	effects_container.add_child(row)
	_on_effects_changed()
	_scroll_to_bottom()

func _on_effect_removed():
	_reindex_effects()
	_on_effects_changed()

func _on_effect_copied(source_row):
	var new_row = load("res://scripts/effect_row.gd").new()
	new_row.load_from_data(source_row.get_effect_data(), effects_container.get_child_count())
	new_row.removed.connect(_on_effect_removed)
	new_row.copied.connect(_on_effect_copied.bind(new_row))
	new_row.data_changed.connect(_on_effects_changed)
	var idx = source_row.get_index()
	effects_container.add_child(new_row)
	if idx + 1 < effects_container.get_child_count() - 1:
		effects_container.move_child(new_row, idx + 1)
	_reindex_effects()
	_on_effects_changed()

func _reindex_effects():
	for i in range(effects_container.get_child_count()):
		var child = effects_container.get_child(i)
		if "set_index" in child:
			child.set_index(i)

func _scroll_to_bottom():
	if scroll:
		await get_tree().process_frame
		await get_tree().process_frame
		scroll.scroll_vertical = 99999

func _on_effects_changed():
	_calc_energy()


# === 更新 ===

func _update():
	if not _ready_done: return
	_calc_energy()


func _calc_energy():
	var total := 0.0
	total += attack * 1.0
	total += health * 0.5
	total += speed * 1.0
	if fields_container.get_child_count() > 0:
		total += 2.0 + (fields_container.get_child_count() - 1) * 1.0

	for i in range(effects_container.get_child_count()):
		var child = effects_container.get_child(i)
		if child.has_method("get_effect_data"):
			var eff = child.get_effect_data()
			total += _calc_effect_energy(eff)

	if energy_bar and energy_bar.has_method("set_energy"):
		energy_bar.set_energy(total)
	export_btn.disabled = total > 15.0


func _calc_effect_energy(eff: Dictionary) -> float:
	var e := 0.0
	var trigger_energy = {
		"TR01": 0, "TR02": 0, "TR03": 0, "TR04": 0, "TR05": 0,
		"TR06": 1, "TR07": 1, "TR08": 1, "TR09": 1, "TR10": 1,
		"TR11": 1, "TR12": 0, "TR13": 2, "TR14": 1, "TR15": 1
	}
	e += trigger_energy.get(eff.get("trigger", "TR01"), 0)

	var tgt_type = eff.get("target", {}).get("type", "T01")
	var target_energy = {
		"T01": 0, "T02": 0, "T03": 0, "T04": 2, "T05": 2,
		"T06": 1, "T07": 1, "T08": 3, "T09": 1, "T10": 1,
		"T11": 2, "T12": 1
	}
	e += target_energy.get(tgt_type, 0)

	var act = eff.get("action", {})
	var act_type = act.get("type", "A01")
	var act_val = act.get("value", 1)
	var action_energy = {
		"A01": 1, "A02": 1, "A03": 3, "A04": 4, "A05": 2
	}
	e += action_energy.get(act_type, 1) * act_val

	for c in eff.get("constraints", []):
		var ret = {
			"CO01": -1.0, "CO02": -2.0, "CO03": -3.0, "CO04": -4.0,
			"CO05": -2.0, "CO06": -3.0, "CO07": -3.0,
			"CO08": -1.0, "CO09": -1.0, "CO10": -2.0, "CO11": -2.0,
			"CO12": -2.0, "CO13": -2.0
		}
		e += ret.get(c, 0.0)

	return e


# === 保存 ===

func _on_save():
	# 校验1：卡名不能为空
	var trimmed_name = name_input.text.strip_edges()
	if trimmed_name == "" or trimmed_name == "新卡牌":
		ToastManager.show("❌ 卡牌名不能为空！", true)
		return

	# 收集数据
	var card_data = _collect_card_data()

	# 确保持存目录存在
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("cards"):
		dir.make_dir("cards")

	# 生成文件名
	var timestamp = Time.get_unix_time_from_system()
	var safe_name = trimmed_name.replace("/", "_").replace("\\", "_").replace(".", "_")
	var filename = "user://cards/" + safe_name + "_" + str(timestamp) + ".json"

	# 保存
	var json_str = JSON.stringify(card_data, "	")
	var f = FileAccess.open(filename, FileAccess.WRITE)
	if f:
		f.store_string(json_str)
		f.close()
		var short_name = filename.get_file()
		ToastManager.show("✅ 保存成功：" + short_name, false)
	else:
		ToastManager.show("❌ 保存失败：" + str(FileAccess.get_open_error()), true)


func _collect_card_data() -> Dictionary:
	var field_list: Array[String] = []
	for i in range(fields_container.get_child_count()):
		var child = fields_container.get_child(i)
		if child is HBoxContainer:
			var le: LineEdit = child.get_child(0)
			if le and le.text.strip_edges() != "":
				field_list.append(le.text.strip_edges())

	var effect_list: Array[Dictionary] = []
	for i in range(effects_container.get_child_count()):
		var child = effects_container.get_child(i)
		if child.has_method("get_effect_data"):
			effect_list.append(child.get_effect_data())

	var energy := 0.0
	energy += attack * 1.0
	energy += health * 0.5
	energy += speed * 1.0
	if field_list.size() > 0:
		energy += 2.0 + (field_list.size() - 1) * 1.0
	for eff in effect_list:
		energy += _calc_effect_energy(eff)

	return {
		"name": name_input.text.strip_edges(),
		"fields": field_list,
		"attack": attack,
		"health": health,
		"speed": speed,
		"effects": effect_list,
		"energy": energy,
		"created_at": Time.get_datetime_string_from_system()
	}


# 加载卡牌数据到界面（从卡册调用）
func load_card_data(data: Dictionary):
	# 清空现有效果
	for child in effects_container.get_children():
		child.queue_free()

	# 加载基本属性
	name_input.text = data.get("name", "新卡牌")
	card_name = data.get("name", "新卡牌")
	attack = data.get("attack", 0)
	health = data.get("health", 0)
	speed = data.get("speed", 0)

	# 加载字段
	for i in range(fields_container.get_child_count()):
		fields_container.get_child(0).queue_free()
	for f in data.get("fields", []):
		_add_field()
		var row = fields_container.get_child(fields_container.get_child_count() - 1)
		var le: LineEdit = row.get_child(0)
		le.text = f

	# 加载效果
	for eff_data in data.get("effects", []):
		var row = load("res://scripts/effect_row.gd").new()
		row.load_from_data(eff_data, effects_container.get_child_count())
		row.removed.connect(_on_effect_removed)
		row.copied.connect(_on_effect_copied.bind(row))
		row.data_changed.connect(_on_effects_changed)
		effects_container.add_child(row)

	_update()


# === 测试 & 导出 ===

func _on_test():
	ToastManager.show("🎮 测试功能开发中...", false)


func _on_next_phase():
	# 校验1：卡名不能为空
	var trimmed_name = name_input.text.strip_edges()
	if trimmed_name == "" or trimmed_name == "新卡牌":
		ToastManager.show("❌ 请先输入卡牌名！", true)
		return

	# 校验2：至少有一个属性或效果（不能是纯空白卡）
	var has_stat = (attack > 0 or health > 0 or speed > 0)
	var has_effect = (effects_container.get_child_count() > 0)
	if not has_stat and not has_effect:
		ToastManager.show("❌ 请至少设置属性或添加效果！", true)
		return

	# 收集卡牌数据
	var data = _collect_card_data()
	# 创建CardData并传给CraftManager
	var card = CardData.new()
	card.load_from_dict(data)
	CraftManager.set_card(card)
	# 进入材料选择阶段
	CraftManager.start_material()


func _on_export():
	ToastManager.show("📤 导出功能开发中...", false)
