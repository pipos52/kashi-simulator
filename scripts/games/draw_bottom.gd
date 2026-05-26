extends Control

# draw_bottom.gd — 阶段3：制作基底小游戏
# 机制：
# • 屏幕上显示一条贝塞尔曲线的虚线路径
# • 玩家手指沿路径滑动
# • 速度过快→墨线过细 / 过慢→墨线堆积
# • 压力检测（大拇指/食指 vs 掌心）
# • 进度条显示完成度
# • 失误超过3次需重试
# • 评分基于准确度+速度+压力综合
# draw_bottom.gd
var _path_points: PackedVector2Array = []
var _path_length: float = 0.0
var _progress: float = 0.0   # 0.0~1.0 完成度
var _path_line: Line2D = null  # 虚线路径
var _draw_line: Line2D = null  # 用户画的线

# 滑动状态
var _is_drawing: bool = false
var _current_idx: int = 0    # 当前最接近的路径点索引
var _last_pos: Vector2 = Vector2.ZERO
var _last_time: float = 0.0

# 评分相关
var _speed_score: float = 0.0   # 速度评分 0~100
var _pressure_score: float = 0.0 # 压力评分 0~100
var _accuracy_score: float = 0.0 # 准确度 0~100
var _mistakes: int = 0
var _total_deviation: float = 0.0
var _deviation_count: int = 0

const MAX_MISTAKES := 3
const PATH_DEVIATION := 60.0   # 像素容差
const OPTIMAL_SPEED := 180.0   # 最佳速度 px/s

# UI引用
var _progress_lbl: Label
var _speed_lbl: Label
var _pressure_lbl: Label
var _mistakes_lbl: Label
var _status_lbl: Label
var _result_lbl: Label
var _hint_lbl: Label
var _finish_btn: Button

# 画线相关
var _drawn_segments: Array = []   # 已画好的线段 [{from, to, quality}]
var _current_line_start: Vector2 = Vector2.ZERO
var _game_area: Control = null    # 实例变量，供 _generate_path 和 _draw 使用

# 难度相关
var _path_deviation: float = 60.0  # 像素容差（随能量动态调整）
var _path_steps: int = 60          # 路径点数（随能量增加）

func _enter_tree():
	pass

func _build():
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.1, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0; bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0; vbox.anchor_top = 0.0; vbox.anchor_right = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = 0; vbox.offset_top = 0; vbox.offset_right = 0; vbox.offset_bottom = 0
	add_child(vbox)

	vbox.add_child(_make_nav("✒️ 制作基底"))
	vbox.add_child(HSeparator.new())

	# 说明文字
	_hint_lbl = Label.new()
	_hint_lbl.text = "沿金色虚线滑动手指\n速度过快过慢、偏离路径都会影响品质"
	_hint_lbl.add_theme_font_size_override("font_size", 34)
	_hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hint_lbl)

	# 状态栏
	var stat_row = HBoxContainer.new()
	stat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.custom_minimum_size = Vector2(0, 55)
	vbox.add_child(stat_row)

	_mistakes_lbl = Label.new()
	_mistakes_lbl.text = "失误: 0/%d" % MAX_MISTAKES
	_mistakes_lbl.add_theme_font_size_override("font_size", 36)
	_mistakes_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 0.2))
	stat_row.add_child(_mistakes_lbl)

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

	# 游戏区域（触摸）
	_game_area = Control.new()
	_game_area.name = "GameArea"
	_game_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_game_area.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截事件，让根节点 _gui_input 接收
	vbox.add_child(_game_area)

	# 虚线路径 Line2D（作为 _game_area 的子节点）
	_path_line = Line2D.new()
	_path_line.name = "PathLine"
	_path_line.width = 3.0
	_path_line.default_color = Color(1.0, 0.85, 0.2, 0.8)
	_path_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_path_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_path_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_game_area.add_child(_path_line)

	# 用户画的线 Line2D
	_draw_line = Line2D.new()
	_draw_line.name = "DrawLine"
	_draw_line.width = 6.0
	_draw_line.default_color = Color(0.3, 0.5, 1.0, 0.9)
	_draw_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_draw_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_draw_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_game_area.add_child(_draw_line)

	# 进度条
	var prog_row = HBoxContainer.new()
	prog_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_row.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(prog_row)

	var prog_lbl = Label.new()
	prog_lbl.text = "进度"
	prog_lbl.add_theme_font_size_override("font_size", 32)
	prog_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	prog_row.add_child(prog_lbl)

	var prog_bg = PanelContainer.new()
	prog_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pbs = StyleBoxFlat.new()
	pbs.bg_color = Color(0.12, 0.12, 0.22)
	pbs.corner_radius_top_left = 6; pbs.corner_radius_top_right = 6
	pbs.corner_radius_bottom_left = 6; pbs.corner_radius_bottom_right = 6
	prog_bg.add_theme_stylebox_override("panel", pbs)
	prog_row.add_child(prog_bg)

	var prog_inner = HBoxContainer.new()
	prog_inner.add_theme_constant_override("separation", 0)
	prog_bg.add_child(prog_inner)
	var prog_fill = PanelContainer.new()
	prog_fill.name = "ProgressFill"
	var pfs = StyleBoxFlat.new()
	pfs.bg_color = Color(0.2, 0.75, 0.3)
	pfs.corner_radius_top_left = 6; pfs.corner_radius_top_right = 6
	pfs.corner_radius_bottom_left = 6; pfs.corner_radius_bottom_right = 6
	prog_fill.add_theme_stylebox_override("panel", pfs)
	prog_inner.add_child(prog_fill)

	_progress_lbl = Label.new()
	_progress_lbl.name = "ProgressLabel"
	_progress_lbl.text = "0%"
	_progress_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress_lbl.add_theme_font_size_override("font_size", 36)
	_progress_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	prog_row.add_child(_progress_lbl)

	# 状态提示
	_status_lbl = Label.new()
	_status_lbl.name = "StatusLabel"
	_status_lbl.text = ""
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 42)
	_status_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_status_lbl)

	# 结果
	_result_lbl = Label.new()
	_result_lbl.name = "ResultLabel"
	_result_lbl.text = ""
	_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_lbl.add_theme_font_size_override("font_size", 56)
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


func _ready():
	_build()
	# 根据能量计算难度
	var card_energy := 3.0
	if CraftManager and CraftManager.current_card:
		card_energy = maxf(1.0, CraftManager.current_card.energy)

	# 高能量卡：路径更长（更多折点）、容差更小
	var energy_ratio := clampf((card_energy - 1.0) / 9.0, 0.0, 1.0)
	_path_deviation = lerpf(60.0, 30.0, energy_ratio)  # 容差60→30
	_path_steps = int(lerpf(60.0, 120.0, energy_ratio))  # 步数60→120

	_hint_lbl.text = "沿金色虚线滑动手指\n速度过快过慢、偏离路径都会影响品质\n能量: %.0f | 容差: ±%.0fpx" % [card_energy, _path_deviation]
	# 等待布局完成后再生成路径
	await get_tree().process_frame
	_generate_path()


func _generate_path():
	if not _game_area:
		return
	if _game_area.size.x <= 0 or _game_area.size.y <= 0:
		return
	# 以game_area中心为基准生成曲线（坐标是 game_area 的局部坐标）
	var cx = _game_area.size.x * 0.5
	var cy = _game_area.size.y * 0.5
	var w = _game_area.size.x * 0.65
	var h = _game_area.size.y * 0.55

	# 生成贝塞尔曲线控制点（S形）
	var p0 := Vector2(cx - w * 0.5, cy + h * 0.3)   # 左下
	var p1 := Vector2(cx - w * 0.2, cy - h * 0.4)   # 左上偏中
	var p2 := Vector2(cx + w * 0.2, cy - h * 0.4)   # 右中上
	var p3 := Vector2(cx + w * 0.5, cy + h * 0.3)    # 右下

	var steps := _path_steps
	_path_points.clear()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var mt := 1.0 - t
		var point := mt*mt*mt*p0 + 3*mt*mt*t*p1 + 3*mt*t*t*p2 + t*t*t*p3
		_path_points.append(point)

	# 计算路径总长
	_path_length = 0.0
	for i in range(1, _path_points.size()):
		_path_length += _path_points[i].distance_to(_path_points[i-1])

	# 用 Line2D 显示虚线路径
	if _path_line:
		_path_line.clear_points()
		for p in _path_points:
			_path_line.add_point(p)  # p 已经是 game_area 局部坐标

	# 用 Line2D 显示用户画的线（初始为空）
	if _draw_line:
		_draw_line.clear_points()

	_progress = 0.0
	_current_idx = 0


func _draw():
	if not _game_area: return
	var area_pos = _game_area.global_position - global_position

	# 绘制目标路径（虚线）
	if _path_points.size() > 1:
		var dash_len := 16.0
		var gap_len := 8.0
		var dash_on := true
		var i := 1
		while i < _path_points.size():
			var pa = _path_points[i-1] + area_pos
			var pb = _path_points[i] + area_pos
			var seg_len = pa.distance_to(pb)
			var dx: float = (pb.x - pa.x) / seg_len if seg_len > 0 else 0.0
			var dy: float = (pb.y - pa.y) / seg_len if seg_len > 0 else 0.0
			var start := 0.0
			while start < seg_len:
				var use := dash_len if dash_on else gap_len
				var end := minf(start + use, seg_len)
				if dash_on:
					var a := Vector2(pa.x + dx*start, pa.y + dy*start)
					var b := Vector2(pa.x + dx*end, pa.y + dy*end)
					draw_line(a, b, Color(1.0, 0.85, 0.2, 0.8), 4.0, true)
				start = end
				dash_on = not dash_on
			i += 1

	# 绘制已画好的线段（墨线）
	for seg in _drawn_segments:
		var q = seg.get("quality", 1.0) as float
		var col := Color(0.3, 0.5 * q, 1.0 * q, 0.9)
		draw_line(seg["from"] + area_pos, seg["to"] + area_pos, col, 6.0, true)

	# 绘制当前触摸位置
	if _is_drawing:
		var touch_p = _last_pos - _game_area.global_position + area_pos
		# 速度指示圈
		var speed_ok := _speed_score >= 70
		var circle_color := Color(0.3, 1.0, 0.3) if speed_ok else Color(1.0, 0.4, 0.2)
		draw_circle(touch_p, 20.0, circle_color.darkened(0.3))
		draw_arc(touch_p, 24.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.6), 2.0)


func _gui_input(event: InputEvent):
	# 游戏结束后（按钮 enabled）才拦截输入
	if _finish_btn and not _finish_btn.disabled:
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_start_draw(st.position)
		else:
			_end_draw()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _is_drawing:
			_update_draw(sd.position, sd.pressure if sd.pressure > 0 else 0.5)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_draw(mb.global_position)
			else:
				_end_draw()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _is_drawing:
			_update_draw(mm.global_position, mm.pressure)

func _unhandled_input(event: InputEvent):
	if _finish_btn and _finish_btn.disabled:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_start_draw(st.position)
		else:
			_end_draw()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _is_drawing:
			_update_draw(sd.position, sd.pressure if sd.pressure > 0 else 0.5)


func _start_draw(global_pos: Vector2):
	_is_drawing = true
	_last_pos = global_pos - _game_area.global_position  # 存 game_area 局部坐标
	_last_time = Time.get_ticks_msec() * 0.001
	# 清空上一轮的线
	if _draw_line:
		_draw_line.clear_points()
		_draw_line.add_point(_last_pos)


func _end_draw():
	_is_drawing = false


func _update_draw(global_pos: Vector2, pressure: float):
	if not _is_drawing: return
	if not _game_area: return

	# 转为 game_area 局部坐标
	var local_pos = global_pos - _game_area.global_position
	var now := Time.get_ticks_msec() * 0.001

	var dt := now - _last_time
	var dist: float = local_pos.distance_to(_last_pos)
	var speed: float = dist / dt if dt > 0 else 0.0

	# 用 Line2D 画线
	if _draw_line:
		_draw_line.add_point(local_pos)

	# 找最近的路径点
	var nearest_idx := _find_nearest_path_point(local_pos)
	var deviation: float = local_pos.distance_to(_path_points[nearest_idx])

	# 准确度判定
	var is_good: bool = deviation <= _path_deviation * 0.5
	var is_ok: bool = deviation <= _path_deviation
	var is_bad: bool = deviation > _path_deviation

	if is_bad and _progress > 0.01:
		_mistakes += 1
		_status_lbl.text = "✗ 偏离路径!"
		_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		if _mistakes >= MAX_MISTAKES:
			_fail()
			return
	else:
		_status_lbl.text = ""

	# 速度评分（最佳速度 OPTIMAL_SPEED px/s）
	var speed_ratio: float = speed / OPTIMAL_SPEED if OPTIMAL_SPEED > 0 else 0.0
	var sp_score := 0.0
	if speed_ratio >= 0.5 and speed_ratio <= 1.5:
		sp_score = 100.0 - absf(speed_ratio - 1.0) * 60.0
	else:
		sp_score = maxf(0.0, 50.0 - absf(speed_ratio - 1.0) * 80.0)
	_speed_score = lerpf(_speed_score, sp_score, 0.3) if _speed_score > 0 else sp_score

	var speed_text := "过慢 ↓"
	var speed_color := Color(0.7, 0.4, 0.1)
	if speed_ratio > 1.5:
		speed_text = "过快 ↑"; speed_color = Color(1.0, 0.3, 0.2)
	elif speed_ratio >= 0.5 and speed_ratio <= 1.5:
		speed_text = "适中 ✓"; speed_color = Color(0.3, 0.85, 0.3)
	_speed_lbl.text = "速度: " + speed_text
	_speed_lbl.add_theme_color_override("font_color", speed_color)

	# 压力评分
	var press_score := 100.0
	if pressure > 0.0:
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

	# 更新路径进度
	if nearest_idx > _current_idx:
		var added_dist := 0.0
		for k in range(_current_idx + 1, nearest_idx + 1):
			added_dist += _path_points[k].distance_to(_path_points[k-1])
		_progress += added_dist / _path_length
		_current_idx = nearest_idx
		_progress = clampf(_progress, 0.0, 1.0)
		_update_progress_bar()

	# 质量评分
	var quality := clampf((sp_score + press_score) * 0.01, 0.0, 1.0)
	if is_good: quality = 1.0
	_drawn_segments.append({
		"from": _last_pos,
		"to": global_pos,
		"quality": quality
	})

	_last_pos = local_pos  # 存局部坐标
	_last_time = now


func _update_progress_bar():
	_progress_lbl.text = "%.0f%%" % (_progress * 100.0)
	# 同步更新进度条宽度
	var prog_inner = get_node_or_null("VBox/ProgressRow/ProgBg/ProgInner")
	if prog_inner:
		var max_w = 300.0  # 假设最大宽度
		prog_inner.custom_minimum_size.x = _progress * max_w


# 完成检测
	if _progress >= 0.98:
		_complete()


func _find_nearest_path_point(local_pos: Vector2) -> int:
	var best := 0
	var best_dist := INF
	for i in range(_path_points.size()):
		var d = local_pos.distance_to(_path_points[i])
		if d < best_dist:
			best_dist = d
			best = i
	return best


func _fail():
	_is_drawing = false
	_status_lbl.text = "💥 失误过多！"
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_result_lbl.text = "制作失败，请重试"
	_result_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))


func _complete():
	_is_drawing = false
	var final_score := _calc_score()
	_result_lbl.text = "✅ 基底完成！ %.0f分" % final_score
	_result_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	_finish_btn.disabled = false
	_hint_lbl.text = "🎉 基底绘制完成！"


func _calc_score() -> float:
	var acc := 100.0 - float(_mistakes) * 15.0
	var sp := _speed_score if _speed_score > 0 else 80.0
	var pr := _pressure_score if _pressure_score > 0 else 80.0
	var total := (acc * 0.4 + sp * 0.3 + pr * 0.3)
	return clampf(total, 0.0, 100.0)


func _make_nav(title: String) -> HBoxContainer:
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.size_flags_vertical = 0
	nav.custom_minimum_size = Vector2(0, 70)
	var back = Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(70, 70)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func(): CraftManager.goto_phase(CraftManager.Phase.MATERIAL))
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
	_drawn_segments.clear()
	_progress = 0.0
	_mistakes = 0
	_speed_score = 0.0
	_pressure_score = 0.0
	_accuracy_score = 0.0
	_current_idx = 0
	_is_drawing = false
	_status_lbl.text = ""
	_result_lbl.text = ""
	_finish_btn.disabled = true
	_hint_lbl.text = "沿金色虚线滑动手指\n速度过快过慢、偏离路径都会影响品质"
	_mistakes_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 0.2))
	_mistakes_lbl.text = "失误: 0/%d" % MAX_MISTAKES
	_speed_lbl.text = "速度: —"
	_pressure_lbl.text = "压力: —"
	_progress_lbl.text = "0%"
	_generate_path()
	queue_redraw()


func _on_finish():
	var score := _calc_score()
	CraftManager.start_node_place(score)
