extends Control

# place_node.gd — 阶段4：构建能量节点小游戏
# 机制：
# • 节点数量 = 效果数量 × 2 + 2（基础节点），高能量卡更多节点
# • 每个节点有目标位置（圆圈标记）和角度要求
# • 点击目标位置放置节点
# • 节点初始角度为随机（不=目标），需滑动条调整对齐
# • 全部正确放置才能进入下一步
# place_node.gd
class NodeData:
	var target_pos: Vector2   # 目标位置（game_area局部坐标）
	var target_angle: float   # 目标角度（度，0=右，逆时针正）
	var placed_pos: Vector2   # 实际放置位置
	var placed_angle: float   # 实际角度（初始为随机，不是目标）
	var is_placed: bool = false
	var is_correct: bool = false

var _nodes: Array[NodeData] = []
var _current_node_idx: int = 0
var _total_nodes: int = 5   # 默认5个

# 难度相关
var _angle_tolerance: float = 8.0  # 随能量动态调整
var _pos_tolerance: float = 55.0    # 随能量动态调整

# 状态
var _score: float = 80.0
var _node_panels: Array[Control] = []
var _game_area: Control = null
var _selected_node_idx: int = -1   # 当前用滑动条选择的节点
var _angle_slider: HSlider = null  # 角度滑动条
var _game_drawer: Control = null  # GameDrawer 节点，自带 _draw()
var _slider_dragging: bool = false  # 防止 slider value 被重置

# UI引用
var _placed_lbl: Label
var _angle_lbl: Label
var _result_lbl: Label
var _finish_btn: Button
var _hint_lbl: Label

const BASE_ANGLE_TOLERANCE := 12.0  # 低能量容差
const TIGHT_ANGLE_TOLERANCE := 5.0   # 高能量容差
const BASE_POS_TOLERANCE := 60.0
const TIGHT_POS_TOLERANCE := 40.0

func _enter_tree():
	pass

func _ready():
	_build()
	# 从CraftManager获取效果数量和能量
	var effect_count := 1
	var card_energy := 3.0
	if CraftManager and CraftManager.current_card:
		effect_count = maxf(1.0, CraftManager.current_card.card_effects.size())
		card_energy = maxf(1.0, CraftManager.current_card.energy)

	# 根据能量计算节点数（高能量卡更多节点）
	_total_nodes = mini(effect_count * 2 + 2 + int(card_energy * 0.5), 12)

	# 根据能量计算容差（高能量卡更严格）
	var energy_ratio := clampf((card_energy - 1.0) / 9.0, 0.0, 1.0)  # 能量1~10映射到0~1
	_angle_tolerance = lerpf(BASE_ANGLE_TOLERANCE, TIGHT_ANGLE_TOLERANCE, energy_ratio)
	_pos_tolerance = lerpf(BASE_POS_TOLERANCE, TIGHT_POS_TOLERANCE, energy_ratio)

	_placed_lbl.text = "节点: 0/%d" % _total_nodes
	_hint_lbl.text = "点击圆圈放置节点\n放置后点击节点，使用滑动条调整角度\n能量: %.0f | 容差: ±%.0f°" % [card_energy, _angle_tolerance]
	# 监听游戏区尺寸变化，布局完成后自动生成节点
	_game_area.resized.connect(_on_game_area_resized)


func _build():
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.1, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0; bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0; vbox.anchor_top = 0.0; vbox.anchor_right = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = 0; vbox.offset_top = 0; vbox.offset_right = 0; vbox.offset_bottom = 0
	add_child(vbox)

	vbox.add_child(_make_nav("🔬 能量节点"))
	vbox.add_child(HSeparator.new())

	# 说明
	_hint_lbl = Label.new()
	_hint_lbl.text = "点击圆圈标记放置节点\n放置后点击节点，使用滑动条调整角度"
	_hint_lbl.add_theme_font_size_override("font_size", 34)
	_hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hint_lbl)

	# 进度和角度
	var info_row = HBoxContainer.new()
	info_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.custom_minimum_size = Vector2(0, 55)
	vbox.add_child(info_row)

	_placed_lbl = Label.new()
	_placed_lbl.name = "PlacedLabel"
	_placed_lbl.text = "节点: 0/%d" % _total_nodes
	_placed_lbl.add_theme_font_size_override("font_size", 38)
	_placed_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	info_row.add_child(_placed_lbl)

	_angle_lbl = Label.new()
	_angle_lbl.name = "AngleLabel"
	_angle_lbl.text = ""
	_angle_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_angle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_angle_lbl.add_theme_font_size_override("font_size", 38)
	_angle_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
	info_row.add_child(_angle_lbl)

	var dev_lbl = Label.new()
	dev_lbl.text = "容差: ±%.0f°" % _angle_tolerance
	dev_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dev_lbl.add_theme_font_size_override("font_size", 32)
	dev_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	info_row.add_child(dev_lbl)

	# 游戏区域（专门绘制游戏内容）
	_game_area = Control.new()
	_game_area.name = "GameArea"
	_game_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_game_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_game_area)

	# 节点详情面板
	var detail_row = HBoxContainer.new()
	detail_row.name = "DetailRow"
	detail_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(detail_row)

	var detail_bg = PanelContainer.new()
	detail_bg.name = "DetailBG"
	detail_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dbs = StyleBoxFlat.new()
	dbs.bg_color = Color(0.1, 0.12, 0.2)
	dbs.corner_radius_top_left = 8; dbs.corner_radius_top_right = 8
	dbs.corner_radius_bottom_left = 8; dbs.corner_radius_bottom_right = 8
	detail_bg.add_theme_stylebox_override("panel", dbs)
	detail_row.add_child(detail_bg)

	var detail_inner = VBoxContainer.new()
	detail_inner.name = "DetailInner"
	detail_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_bg.add_child(detail_inner)

	var detail_lbl1 = Label.new()
	detail_lbl1.name = "DetailLabel1"
	detail_lbl1.text = "当前节点: —  目标角度: —°"
	detail_lbl1.add_theme_font_size_override("font_size", 34)
	detail_lbl1.add_theme_color_override("font_color", Color(0.65, 0.65, 0.8))
	detail_inner.add_child(detail_lbl1)

	# 角度滑动条
	var slider_container = HBoxContainer.new()
	slider_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_container.custom_minimum_size = Vector2(0, 50)
	detail_inner.add_child(slider_container)

	var slider_lbl = Label.new()
	slider_lbl.text = "角度:"
	slider_lbl.custom_minimum_size = Vector2(70, 0)
	slider_lbl.add_theme_font_size_override("font_size", 30)
	slider_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
	slider_container.add_child(slider_lbl)

	_angle_slider = HSlider.new()
	_angle_slider.name = "AngleSlider"
	_angle_slider.min_value = 0.0
	_angle_slider.max_value = 360.0
	_angle_slider.step = 1.0
	_angle_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_angle_slider.value_changed.connect(_on_slider_angle_changed)
	# 用 slider 内置信号追踪拖拽状态，替代自己维护 _slider_dragging
	_angle_slider.drag_started.connect(_on_slider_drag_started)
	_angle_slider.drag_ended.connect(_on_slider_drag_ended)
	slider_container.add_child(_angle_slider)

	var angle_val_lbl = Label.new()
	angle_val_lbl.name = "AngleValLbl"
	angle_val_lbl.text = "0°"
	angle_val_lbl.custom_minimum_size = Vector2(80, 0)
	angle_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	angle_val_lbl.add_theme_font_size_override("font_size", 30)
	angle_val_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	slider_container.add_child(angle_val_lbl)

	# 结果
	_result_lbl = Label.new()
	_result_lbl.name = "ResultLabel"
	_result_lbl.text = ""
	_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_lbl.add_theme_font_size_override("font_size", 52)
	_result_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	_result_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_result_lbl)

	vbox.add_child(HSeparator.new())

	# 底部按钮
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
	if not _game_area or _game_area.size.x <= 0 or _game_area.size.y <= 0:
		return

	var cx = _game_area.size.x * 0.5
	var cy = _game_area.size.y * 0.5
	var r = minf(_game_area.size.x, _game_area.size.y) * 0.32
	for i in range(_total_nodes):
		var nd := NodeData.new()
		var angle_rad := TAU * float(i) / float(_total_nodes) - PI * 0.5
		nd.target_pos = Vector2(cx + r * cos(angle_rad), cy + r * sin(angle_rad))
		var to_center := Vector2(cx, cy) - nd.target_pos
		nd.target_angle = rad_to_deg(to_center.angle()) + randf_range(-45.0, 45.0)
		nd.target_angle = fmod(nd.target_angle + 360.0, 360.0)
		# 关键：放置时初始角度=随机角度（不是目标角度），玩家必须手动旋转对齐
		nd.placed_angle = randf_range(0.0, 360.0)
		_nodes.append(nd)

	# 创建 GameDrawer 子节点（自带 _draw()，画布渲染在 UI 上方）
	if _game_drawer:
		_game_area.remove_child(_game_drawer)
		_game_drawer.queue_free()
	_game_drawer = GameDrawer.new()
	_game_drawer.name = "GameDrawer"
	_game_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_area.add_child(_game_drawer)
	_game_drawer.gui_input.connect(_on_game_area_input)

	# 通知绘制
	_notify_drawer()


func _notify_drawer():
	if _game_drawer:
		# 把 NodeData 导出为字典，传给 GameDrawer
		var dicts: Array = []
		for nd in _nodes:
			dicts.append({
				"target_pos": nd.target_pos,
				"target_angle": nd.target_angle,
				"placed_pos": nd.placed_pos,
				"placed_angle": nd.placed_angle,
				"is_placed": nd.is_placed,
				"is_correct": nd.is_correct
			})
		_game_drawer.set_nodes(dicts, _angle_tolerance)

func _game_drawer_draw():
	# 已迁移到 GameDrawer._draw()，此方法保留但不再被调用
	pass


func _on_game_area_input(event: InputEvent):
	# event.position 已经是 GameDrawer 的局部坐标
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			var touched_idx := _find_touched_placed_node(st.position)
			if touched_idx >= 0:
				# 点击了已放置的节点 → 选中它（显示滑动条）
				_select_node(touched_idx)
			else:
				# 点击空白或目标圆圈 → 尝试放置
				_deselect_node()
				_handle_tap(st.position)
		else:
			# touch up 时：如果点击的是已放置的节点（可能是误操作滑出节点范围），
			# 或者 slider 正在拖拽，都不清零 selected
			# 只有点击空白区域才清零
			var touched_idx := _find_touched_placed_node(st.position)
			if touched_idx < 0 and not _slider_dragging:
				_deselect_node()


func _find_touched_placed_node(local_pos: Vector2) -> int:
	if _nodes.is_empty(): return -1
	var best_idx := -1
	var best_dist := _pos_tolerance
	for i in range(_nodes.size()):
		var nd = _nodes[i] as NodeData
		if not nd.is_placed: continue
		var d: float = local_pos.distance_to(nd.placed_pos)
		if d < best_dist:
			best_dist = d
			best_idx = i
	return best_idx


func _select_node(idx: int):
	_selected_node_idx = idx
	_current_node_idx = idx
	_update_slider_for_selected()
	_update_detail_label()
	_notify_drawer()


func _deselect_node():
	_selected_node_idx = -1


func _on_slider_drag_started():
	_slider_dragging = true


func _on_slider_drag_ended(value_changed: bool):
	_slider_dragging = false


func _update_slider_for_selected():
	if not _angle_slider: return
	if _slider_dragging: return  # 拖拽时跳过，防止重置 slider 值
	if _selected_node_idx >= 0 and _selected_node_idx < _nodes.size():
		var nd: NodeData = _nodes[_selected_node_idx]
		_angle_slider.value = nd.placed_angle
		var val_lbl = get_node_or_null("VBox/DetailRow/DetailBG/DetailInner/AngleValLbl") as Label
		if val_lbl:
			val_lbl.text = "%.0f°" % nd.placed_angle


func _on_slider_angle_changed(val: float, from_drag: bool = false):
	# Godot 4: value_changed(bool dragging) — from_drag=true 表示正在拖拽
	# 兼容 Godot 3 风格调用（from_drag 省略时默认为 false）
	if from_drag:
		_slider_dragging = true
	if _selected_node_idx < 0 or _selected_node_idx >= _nodes.size():
		return
	var nd: NodeData = _nodes[_selected_node_idx]
	nd.placed_angle = fmod(val + 360.0, 360.0)

	# 更新滑动条旁边的数值显示
	var val_lbl = get_node_or_null("VBox/DetailRow/DetailBG/DetailInner/AngleValLbl") as Label
	if val_lbl:
		val_lbl.text = "%.0f°" % nd.placed_angle

	# 检查是否正确
	var dev: float = _angle_difference(nd.placed_angle, nd.target_angle)
	nd.is_correct = absf(dev) <= _angle_tolerance

	var dev_abs := absf(dev)
	var angle_color := Color(0.3, 0.85, 0.3)
	if dev_abs > _angle_tolerance * 2.0:
		angle_color = Color(1.0, 0.3, 0.3)
	elif dev_abs > _angle_tolerance:
		angle_color = Color(1.0, 0.7, 0.1)

	_angle_lbl.text = "偏差: %.0f°" % dev_abs
	_angle_lbl.add_theme_color_override("font_color", angle_color)

	# 更新 detail 标签（不走 _update_detail_label，避免递归设置 slider value）
	_update_detail_label_no_slider()
	_update_placed_label()
	_notify_drawer()

	# 检查是否全部正确
	_check_all_nodes()
	# 不在这里清零 _slider_dragging，由 drag_ended 信号处理


func _handle_tap(local_pos: Vector2):
	for i in range(_nodes.size()):
		var nd: NodeData = _nodes[i]
		if nd.is_placed: continue
		var dist: float = local_pos.distance_to(nd.target_pos)
		if dist <= _pos_tolerance:
			_place_node(i, local_pos)
			return
	_set_hint("💡 点击金色圆圈标记放置节点")


func _place_node(idx: int, pos: Vector2):
	var nd = _nodes[idx] as NodeData
	nd.placed_pos = pos
	# 放置后角度保持随机初始角度（不是目标角度！）
	# is_correct 初始为 false，玩家必须滑动调整
	nd.is_placed = true
	_update_detail_label()
	_update_placed_label()
	_notify_drawer()
	# 立即选中该节点，显示滑动条
	_select_node(idx)

	# 检查是否全部完成
	var all_placed := true
	var all_correct := true
	for n in _nodes:
		if not (n as NodeData).is_placed:
			all_placed = false
		#else:  # 不要在这里提前检查 correct，因为可能还需要旋转
	if all_placed:
		_check_all_nodes()


func _angle_difference(a: float, b: float) -> float:
	var diff := fmod(a - b + 180.0, 360.0) - 180.0
	return diff


func _check_all_nodes():
	var correct_count := 0
	for n in _nodes:
		if (n as NodeData).is_correct:
			correct_count += 1
	var score := float(correct_count) / float(_nodes.size()) * 100.0

	if correct_count == _nodes.size():
		_result_lbl.text = "✅ 全部正确！%.0f分" % score
		_result_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
		_finish_btn.disabled = false
		_score = score
	else:
		_result_lbl.text = "⚠️ %d个角度偏差，需调整" % (_nodes.size() - correct_count)
		_result_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1))
		_score = score * 0.5


func _update_detail_label():
	var nd = _nodes[_current_node_idx] as NodeData
	var detail1 = get_node_or_null("VBox/DetailRow/DetailBG/DetailInner/DetailLabel1") as Label
	if detail1:
		var dev: float = _angle_difference(nd.placed_angle, nd.target_angle)
		detail1.text = "节点: %d/%d  目标: %.0f°  实际: %.0f°  偏差: %.0f°" % [
			_current_node_idx + 1, _total_nodes, nd.target_angle, nd.placed_angle, absf(dev)]
	# 同步滑动条值（当前选中节点）
	_update_slider_for_selected()


func _update_detail_label_no_slider():
	var nd = _nodes[_current_node_idx] as NodeData
	var detail1 = get_node_or_null("VBox/DetailRow/DetailBG/DetailInner/DetailLabel1") as Label
	if detail1:
		var dev: float = _angle_difference(nd.placed_angle, nd.target_angle)
		detail1.text = "节点: %d/%d  目标: %.0f°  实际: %.0f°  偏差: %.0f°" % [
			_current_node_idx + 1, _total_nodes, nd.target_angle, nd.placed_angle, absf(dev)]


func _update_placed_label():
	var placed := 0
	var correct := 0
	for n in _nodes:
		if (n as NodeData).is_placed: placed += 1
		if (n as NodeData).is_correct: correct += 1
	_placed_lbl.text = "节点: %d/%d (正确:%d)" % [placed, _total_nodes, correct]


func _set_hint(text: String):
	_hint_lbl.text = text


func _on_game_area_resized():
	# 布局完成后，游戏区有实际尺寸时生成节点
	if _nodes.is_empty() and _game_area and _game_area.size.x > 0:
		_generate_nodes()
		_notify_drawer()

func _make_nav(title: String) -> HBoxContainer:
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.size_flags_vertical = 0
	nav.custom_minimum_size = Vector2(0, 70)
	var back = Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(70, 70)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func(): CraftManager.goto_phase(CraftManager.Phase.BOTTOM_DRAW))
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
	_selected_node_idx = -1
	_generate_nodes()
	_current_node_idx = 0
	_score = 80.0
	_result_lbl.text = ""
	_finish_btn.disabled = true
	_update_placed_label()
	_update_detail_label()
	_hint_lbl.text = "点击圆圈标记放置节点\n放置后点击节点，使用滑动条调整角度"
	_notify_drawer()


func _on_finish():
	CraftManager.start_line_draw(_score)
