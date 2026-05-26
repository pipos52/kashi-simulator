extends Control

# draw_line.gd — 阶段5：绘制能量回路
# 机制：
# • 所有已放置的节点显示为圆圈
# • 需按正确顺序用手指划线连接
# • 速度和压力影响评分
# • 连接错误时提示重连
# draw_line.gd
var _nodes: Array[Vector2] = []     # 节点世界坐标
var _node_count: int = 5               # 节点数量（从阶段4获取）
var _current_connection: int = 0       # 当前应连接第几条线
var _total_connections: int = 0        # 总连接数
var _nodes_generated: bool = false     # 防止重复生成

# 绘制状态
var _is_drawing: bool = false
var _drawn_lines: Array = []           # [{from, to, quality}]
var _game_area: Control                 # 游戏区域（实例变量）
var _game_drawer: Control               # 绘制层子节点
var _last_pos: Vector2 = Vector2.ZERO
var _last_time: float = 0.0
var _temp_line_end: Vector2 = Vector2.ZERO  # 正在画的线终点

# 难度相关
var _pos_tolerance: float = 60.0  # 像素容差（随能量动态调整）

# 评分
var _speed_score: float = 0.0
var _pressure_score: float = 0.0
var _connection_errors: int = 0

const OPTIMAL_SPEED := 150.0
const POS_TOLERANCE := 60.0

# UI引用
var _conn_lbl: Label
var _speed_lbl: Label
var _pressure_lbl: Label
var _result_lbl: Label
var _finish_btn: Button
var _hint_lbl: Label

func _enter_tree():
	pass

func _ready():
	_build()
	# 根据能量计算难度
	var card_energy := 3.0
	if CraftManager and CraftManager.current_card:
		card_energy = maxf(1.0, CraftManager.current_card.energy)

	var effect_count := 1
	if CraftManager and CraftManager.current_card:
		effect_count = maxf(1.0, CraftManager.current_card.card_effects.size())

	# 高能量卡：更多节点、更严格的容差
	var energy_ratio := clampf((card_energy - 1.0) / 9.0, 0.0, 1.0)
	_node_count = mini(effect_count * 2 + 2 + int(card_energy * 0.5), 12)
	_pos_tolerance = lerpf(60.0, 35.0, energy_ratio)  # 容差60→35
	_total_connections = _node_count
	_hint_lbl.text = "按顺序连接所有节点\n从节点1开始依次连接\n能量: %.0f | 容差: ±%.0fpx" % [card_energy, _pos_tolerance]
	_generate_nodes()


func _build():
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.1, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0; bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0; vbox.anchor_top = 0.0; vbox.anchor_right = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = 0; vbox.offset_top = 0; vbox.offset_right = 0; vbox.offset_bottom = 0
	add_child(vbox)

	vbox.add_child(_make_nav("🔗 能量回路"))
	vbox.add_child(HSeparator.new())

	_hint_lbl = Label.new()
	_hint_lbl.text = "按顺序连接所有节点\n从节点1开始依次连接"
	_hint_lbl.add_theme_font_size_override("font_size", 34)
	_hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hint_lbl)

	var stat_row = HBoxContainer.new()
	stat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.custom_minimum_size = Vector2(0, 55)
	vbox.add_child(stat_row)

	_conn_lbl = Label.new()
	_conn_lbl.name = "ConnLabel"
	_conn_lbl.text = "连接: 0/%d" % _total_connections
	_conn_lbl.add_theme_font_size_override("font_size", 38)
	_conn_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	stat_row.add_child(_conn_lbl)

	_speed_lbl = Label.new()
	_speed_lbl.text = "速度: —"
	_speed_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_lbl.add_theme_font_size_override("font_size", 36)
	_speed_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	stat_row.add_child(_speed_lbl)

	_pressure_lbl = Label.new()
	_pressure_lbl.text = "压力: —"
	_pressure_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pressure_lbl.add_theme_font_size_override("font_size", 36)
	_pressure_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	stat_row.add_child(_pressure_lbl)

	# 游戏区域
	_game_area = Control.new()
	_game_area.name = "GameArea"
	_game_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_game_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_game_area)

	# GameDrawer 子节点：负责绘制（解决被 UI 遮挡问题）
	_game_drawer = GameDrawer.new()
	_game_drawer.name = "GameDrawer"
	_game_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_area.add_child(_game_drawer)
	_game_drawer.gui_input.connect(_on_game_drawer_input)

	# 能量流动条
	var flow_row = HBoxContainer.new()
	flow_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow_row.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(flow_row)

	var flow_lbl = Label.new()
	flow_lbl.text = "能量流动"
	flow_lbl.add_theme_font_size_override("font_size", 32)
	flow_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	flow_row.add_child(flow_lbl)

	var flow_bg = PanelContainer.new()
	flow_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fbs = StyleBoxFlat.new()
	fbs.bg_color = Color(0.1, 0.1, 0.2)
	fbs.corner_radius_top_left = 6; fbs.corner_radius_top_right = 6
	fbs.corner_radius_bottom_left = 6; fbs.corner_radius_bottom_right = 6
	flow_bg.add_theme_stylebox_override("panel", fbs)
	flow_row.add_child(flow_bg)

	var flow_fill = PanelContainer.new()
	flow_fill.name = "FlowFill"
	var ffs = StyleBoxFlat.new()
	ffs.bg_color = Color(0.2, 0.6, 0.85)
	ffs.corner_radius_top_left = 6; ffs.corner_radius_top_right = 6
	ffs.corner_radius_bottom_left = 6; ffs.corner_radius_bottom_right = 6
	flow_fill.add_theme_stylebox_override("panel", ffs)
	flow_bg.add_child(flow_fill)

	var flow_lbl2 = Label.new()
	flow_lbl2.name = "FlowLabel"
	flow_lbl2.text = "稳定"
	flow_lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow_lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	flow_lbl2.add_theme_font_size_override("font_size", 32)
	flow_lbl2.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	flow_row.add_child(flow_lbl2)

	_result_lbl = Label.new()
	_result_lbl.name = "ResultLabel"
	_result_lbl.text = ""
	_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_lbl.add_theme_font_size_override("font_size", 52)
	_result_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	_result_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_result_lbl)

	vbox.add_child(HSeparator.new())

	var bottom = HBoxContainer.new()
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(bottom)

	var retry_btn = Button.new()
	retry_btn.text = "🔄 重试"
	retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_btn.custom_minimum_size = Vector2(0, 70)
	retry_btn.add_theme_font_size_override("font_size", 34)
	retry_btn.pressed.connect(_on_retry)
	bottom.add_child(retry_btn)

	_finish_btn = Button.new()
	_finish_btn.text = "完成并继续 →"
	_finish_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_finish_btn.custom_minimum_size = Vector2(0, 70)
	_finish_btn.add_theme_font_size_override("font_size", 34)
	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.2, 0.5, 0.85)
	ns.corner_radius_top_left = 8; ns.corner_radius_top_right = 8
	ns.corner_radius_bottom_left = 8; ns.corner_radius_bottom_right = 8
	_finish_btn.add_theme_stylebox_override("normal", ns)
	_finish_btn.pressed.connect(_on_finish)
	_finish_btn.disabled = true
	bottom.add_child(_finish_btn)


func _generate_nodes():
	_nodes.clear()
	if not _game_area:
		return
	_nodes_generated = false
	if _game_area.resized.get_connections().is_empty():
		_game_area.resized.connect(_on_game_area_resized)
	# 立刻尝试生成——如果 size 够大直接完成
	_try_generate_now()


func _try_generate_now():
	if _nodes_generated:
		return
	_do_generate()
	if _nodes_generated:
		_notify_drawer()


func _on_game_area_resized():
	if _nodes_generated:
		return
	_do_generate()
	if _nodes_generated:
		_notify_drawer()


func _do_generate():
	if not _game_area: return
	if _game_area.size.x <= 0 or _game_area.size.y <= 200:
		return
	_nodes.clear()
	_nodes_generated = true
	var cx = _game_area.size.x * 0.5
	var cy = _game_area.size.y * 0.5
	var r = minf(_game_area.size.x, _game_area.size.y) * 0.32

	var sides := _node_count
	if sides < 3: sides = 3
	for i in range(sides):
		var angle_rad := TAU * float(i) / float(sides) - PI * 0.5
		var radius: float = r * (1.0 if i % 2 == 0 else 0.85)
		var pos := Vector2(cx + radius * cos(angle_rad), cy + radius * sin(angle_rad))
		_nodes.append(pos)

	_total_connections = _nodes.size()


func _on_game_drawer_input(event: InputEvent):
	# event.position 已是 GameDrawer 的局部坐标 = _game_area 局部坐标
	if _finish_btn and not _finish_btn.disabled: return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_start_draw(st.position)
		else:
			_end_draw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _is_drawing:
			_update_draw(drag.position, drag.pressure)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_draw(mb.global_position - _game_drawer.get_global_position())
			else:
				_end_draw()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _is_drawing:
			_update_draw(mm.global_position - _game_drawer.get_global_position(), mm.pressure)


func _start_draw(local_pos: Vector2):
	_is_drawing = true
	if not _game_area: return

	_last_pos = local_pos
	_temp_line_end = local_pos
	_last_time = Time.get_ticks_msec() * 0.001

	# 检查是否从正确的节点开始
	var start_node_idx = _current_connection % _nodes.size()
	var start_node_pos = _nodes[start_node_idx]

	if local_pos.distance_to(start_node_pos) > _pos_tolerance:
		_hint_lbl.text = "⚠️ 请从节点%d开始" % (start_node_idx + 1)
		_hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
		_is_drawing = false
		return

	_hint_lbl.text = "沿路径滑动到节点%d" % ((start_node_idx + 1) % _nodes.size() + 1)
	_hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	_notify_drawer()


func _end_draw():
	_is_drawing = false
	_notify_drawer()


func _update_draw(local_pos: Vector2, pressure: float):
	if not _is_drawing: return
	if not _game_area: return

	var now := Time.get_ticks_msec() * 0.001
	var dt := now - _last_time
	var dist: float = local_pos.distance_to(_last_pos)
	var speed: float = dist / dt if dt > 0.0 else 0.0

	_temp_line_end = local_pos

	# 速度评分
	var speed_ratio: float = speed / OPTIMAL_SPEED if OPTIMAL_SPEED > 0 else 0.0
	var sp_score: float = 100.0 - absf(speed_ratio - 1.0) * 80.0 if (speed_ratio >= 0.3 and speed_ratio <= 2.0) else maxf(0.0, 50.0 - absf(speed_ratio - 1.0) * 100.0)
	sp_score = clampf(sp_score, 0.0, 100.0)
	_speed_score = lerpf(_speed_score, sp_score, 0.3) if _speed_score > 0 else sp_score

	var speed_text := "过慢 ↓"
	var speed_color := Color(0.7, 0.4, 0.1)
	if speed_ratio > 2.0:
		speed_text = "过快 ↑"; speed_color = Color(1.0, 0.3, 0.2)
	elif speed_ratio >= 0.3 and speed_ratio <= 2.0:
		speed_text = "适中 ✓"; speed_color = Color(0.3, 0.85, 0.3)
	_speed_lbl.text = "速度: " + speed_text
	_speed_lbl.add_theme_color_override("font_color", speed_color)

	# 压力评分
	var press_score := 100.0
	if pressure > 0.05:
		press_score = 100.0 - absf(pressure - 0.45) * 200.0
		press_score = maxf(0.0, press_score)
	_pressure_score = lerpf(_pressure_score, press_score, 0.3) if _pressure_score > 0 else press_score

	var press_text := "压力: —"
	var press_color := Color(0.6, 0.6, 0.7)
	if pressure > 0.05:
		if pressure < 0.25:
			press_text = "过轻 ↑"; press_color = Color(0.7, 0.5, 0.1)
		elif pressure > 0.75:
			press_text = "过重 ↓"; press_color = Color(1.0, 0.3, 0.2)
		else:
			press_text = "适中 ✓"; press_color = Color(0.3, 0.85, 0.3)
	_pressure_lbl.text = press_text
	_pressure_lbl.add_theme_color_override("font_color", press_color)

	# 检查是否到达下一个节点
	var target_node_idx := (_current_connection + 1) % _nodes.size()
	var target_node_pos := _nodes[target_node_idx]

	if local_pos.distance_to(target_node_pos) <= _pos_tolerance:
		_complete_connection(target_node_idx, sp_score, press_score)

	_last_pos = local_pos
	_last_time = now
	_notify_drawer()


func _complete_connection(target_idx: int, sp_score: float, press_score: float):
	var quality := clampf((sp_score + press_score) * 0.01, 0.0, 1.0)
	var from_node_idx := _current_connection % _nodes.size()

	_drawn_lines.append({
		"from": _nodes[from_node_idx],
		"to": _nodes[target_idx],
		"quality": quality
	})

	_current_connection += 1
	_conn_lbl.text = "连接: %d/%d" % [_current_connection, _total_connections]

	# 能量流动更新
	var flow_progress := float(_current_connection) / float(_total_connections)
	var flow_fill = get_node_or_null("VBox/FlowRow/FlowBG/FlowFill") as PanelContainer
	if flow_fill:
		var fs = flow_fill.get_theme_stylebox("panel") as StyleBoxFlat
		if fs:
			fs.bg_color = Color(0.2, 0.6, 0.85)
		flow_fill.custom_minimum_size = Vector2(flow_progress * flow_fill.get_parent().size.x, 0)

	var flow_lbl = get_node_or_null("VBox/FlowRow/FlowLabel") as Label
	if flow_lbl:
		if _current_connection >= _total_connections:
			flow_lbl.text = "完成 ✓"
			flow_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
		else:
			flow_lbl.text = "稳定 ↑"
			flow_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))

	_hint_lbl.text = "已连接节点%d→%d" % [from_node_idx + 1, target_idx + 1]
	_hint_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))

	_notify_drawer()

	# 检查是否全部完成
	if _current_connection >= _total_connections:
		_is_drawing = false
		var final_score := _calc_score()
		_result_lbl.text = "✅ 回路完成！%.0f分" % final_score
		_result_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
		_finish_btn.disabled = false
		_hint_lbl.text = "🎉 所有节点已连接！"


func _calc_score() -> float:
	var sp := _speed_score if _speed_score > 0 else 80.0
	var pr := _pressure_score if _pressure_score > 0 else 80.0
	var total := sp * 0.5 + pr * 0.5 - float(_connection_errors) * 10.0
	return clampf(total, 0.0, 100.0)


func _notify_drawer():
	if _game_drawer:
		_game_drawer.set_line_data(_nodes, _drawn_lines, _current_connection, _is_drawing, _temp_line_end)


func _draw():
	pass  # 所有绘制已迁移到 GameDrawer


func _make_nav(title: String) -> HBoxContainer:
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.size_flags_vertical = 0
	nav.custom_minimum_size = Vector2(0, 70)
	var back = Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(70, 70)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func(): CraftManager.goto_phase(CraftManager.Phase.NODE_PLACE))
	nav.add_child(back)
	var lbl = Label.new()
	lbl.text = title
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	lbl.add_theme_font_size_override("font_size", 48)
	nav.add_child(lbl)
	var spacer = Control.new(); spacer.custom_minimum_size = Vector2(70, 0); nav.add_child(spacer)
	return nav


func _on_retry():
	_drawn_lines.clear()
	_current_connection = 0
	_connection_errors = 0
	_speed_score = 0.0
	_pressure_score = 0.0
	_is_drawing = false
	_temp_line_end = Vector2.ZERO
	_conn_lbl.text = "连接: 0/%d" % _total_connections
	_result_lbl.text = ""
	_finish_btn.disabled = true
	_hint_lbl.text = "按顺序连接所有节点\n从节点1开始依次连接"
	_hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	_speed_lbl.text = "速度: —"
	_pressure_lbl.text = "压力: —"
	_generate_nodes()


func _on_finish():
	var score := _calc_score()
	CraftManager.start_activate(score)
