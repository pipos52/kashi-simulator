extends Control

# activate.gd — 阶段6：封卡（呼吸节奏小游戏）
# 机制：
# • 能量脉冲游标左右振荡
# • 在游标到达中央区域时点击屏幕
# • 共N次脉冲（随能量增加）
# • 完美=在中央±窗口范围内 / 失误=偏差过大
# • 风险值累积，>100%封卡失败
# • 能量越高：速度越快、窗口越窄、脉冲越多
# activate.gd

var _total_pulses: int = 8           # 总脉冲数（随能量变化）
var _perfect_window: float = 0.10     # 完美窗口（随能量收紧）
var _good_window: float = 0.20        # 良好窗口
var _risk_per_miss: float = 15.0      # 每次失误风险增量
var _pulse_speed: float = 1.2         # 振荡速度（随能量加快）

var _pulse_count: int = 0
var _perfect_hits: int = 0
var _risk: float = 0.0
var _phase: float = 0.0        # 0~1 振荡相位
var _is_running: bool = false
var _can_tap: bool = true      # 防连击
var _failed: bool = false

# 游标条（放在canvas layer绘制）
var _bar_rect: Rect2          # 能量条区域
var _cursor_x: float = 0.0     # 游标x位置（0~1）
var _perfect_zone_left: float  # 完美区域左边界
var _perfect_zone_right: float # 完美区域右边界
var _good_zone_left: float
var _good_zone_right: float

# UI引用
var _pulse_lbl: Label
var _perfect_lbl: Label
var _risk_lbl: Label
var _status_lbl: Label
var _result_lbl: Label
var _finish_btn: Button
var _retry_btn: Button
var _pulse_bar: ColorRect       # 游标条背景

var _touch_start_y: float = -1.0  # 记录触摸起始y（用于判定上下滑动）
var _ready_complete: bool = false  # VBox布局完成后才绘制
var _game_container: Control = null  # 直接引用GameContainer

func _enter_tree():
	pass

func _ready():
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.1, 0.0)  # 透明背景
	bg.anchor_left = 0.0; bg.anchor_top = 0.0; bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0; vbox.anchor_top = 0.0; vbox.anchor_right = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = 0; vbox.offset_top = 0; vbox.offset_right = 0; vbox.offset_bottom = 0
	add_child(vbox)

	vbox.add_child(_make_nav("🌬️ 封卡"))
	vbox.add_child(HSeparator.new())

	# 说明
	var hint = Label.new()
	hint.text = "能量脉冲到达中央时按住屏幕\n%d次脉冲，完美次数决定品质" % _total_pulses
	hint.add_theme_font_size_override("font_size", 34)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

	# 脉冲计数
	_pulse_lbl = Label.new()
	_pulse_lbl.name = "PulseLabel"
	_pulse_lbl.text = "脉冲: 0/%d" % _total_pulses
	_pulse_lbl.add_theme_font_size_override("font_size", 42)
	_pulse_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	vbox.add_child(_pulse_lbl)

	# 游戏区域（占据中间大部分空间）
	var game_container = Control.new()
	game_container.name = "GameContainer"
	game_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_container.gui_input.connect(_on_game_input)
	vbox.add_child(game_container)
	_game_container = game_container

	# 根据能量计算难度参数
	var card_energy := 3.0
	if CraftManager and CraftManager.current_card:
		card_energy = maxf(1.0, CraftManager.current_card.energy)

	var energy_ratio := clampf((card_energy - 1.0) / 9.0, 0.0, 1.0)
	_total_pulses = int(lerpf(8.0, 14.0, energy_ratio))  # 8~14次脉冲
	_perfect_window = lerpf(0.12, 0.05, energy_ratio)    # 窗口12%~5%
	_risk_per_miss = lerpf(12.0, 20.0, energy_ratio)    # 风险12~20
	_pulse_speed = lerpf(1.0, 2.0, energy_ratio)        # 速度1~2

	_pulse_lbl.text = "脉冲: 0/%d" % _total_pulses
	var status_row = HBoxContainer.new()
	status_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(status_row)

	_perfect_lbl = Label.new()
	_perfect_lbl.name = "PerfectLabel"
	_perfect_lbl.text = "完美: 0"
	_perfect_lbl.add_theme_font_size_override("font_size", 38)
	_perfect_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	status_row.add_child(_perfect_lbl)

	_status_lbl = Label.new()
	_status_lbl.name = "StatusLabel"
	_status_lbl.text = ""
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 38)
	_status_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	status_row.add_child(_status_lbl)

	_risk_lbl = Label.new()
	_risk_lbl.name = "RiskLabel"
	_risk_lbl.text = "风险: 0%"
	_risk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_risk_lbl.add_theme_font_size_override("font_size", 38)
	_risk_lbl.add_theme_color_override("font_color", Color(0.85, 0.4, 0.2))
	status_row.add_child(_risk_lbl)

	# 结果文字
	_result_lbl = Label.new()
	_result_lbl.name = "ResultLabel"
	_result_lbl.text = ""
	_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_lbl.add_theme_font_size_override("font_size", 64)
	_result_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	_result_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_result_lbl)

	vbox.add_child(HSeparator.new())

	# 底部按钮
	var bottom = HBoxContainer.new()
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(bottom)

	_retry_btn = Button.new()
	_retry_btn.text = "🔄 重试"
	_retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_retry_btn.custom_minimum_size = Vector2(0, 70)
	_retry_btn.add_theme_font_size_override("font_size", 34)
	_retry_btn.pressed.connect(_on_retry)
	bottom.add_child(_retry_btn)

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

	# 等待布局完成后再启动脉冲（避免 _draw 在 GameContainer 尺寸确定前被触发）
	_ready_complete = true
	_start.call_deferred()


func _start():
	_pulse_count = 0
	_perfect_hits = 0
	_risk = 0.0
	_phase = 0.0
	_is_running = true
	_failed = false
	_can_tap = true
	queue_redraw()  # 立即绘制第一帧
	_update_labels()
	_finish_btn.disabled = true
	_result_lbl.text = ""


func _process(delta: float):
	if not _is_running:
		return

	# 振荡：0→1→0 往复
	_phase += delta * _pulse_speed
	var raw := fmod(_phase, 1.0)
	# 0→0.5: 前进(0→1), 0.5→1: 后退(1→0)
	_cursor_x = raw if raw <= 0.5 else (1.0 - (raw - 0.5) * 2.0)

	queue_redraw()  # 持续重绘游标

	# 每完成一个完整来回算一次脉冲（phase累计2.0为1个来回）
	var new_count := int(_phase / 1.0)
	if new_count > _pulse_count and new_count <= _total_pulses:
		_pulse_count = new_count
		# 每次到达左端时记录一次（phase每到1.0就经过一次中央）
		_can_tap = true
		_update_labels()
		if _pulse_count >= _total_pulses:
			_end_game()


func _input(event: InputEvent):
	# Android: InputEventScreenTouch goes to gui_input on game_container
	# PC: InputEventMouseButton goes to _input directly
	if not _is_running or _failed: return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_on_tap()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT: return
		if mb.pressed:
			_on_tap()


func _on_game_input(event: InputEvent):
	# 游戏容器接收触摸事件，Android 上触摸事件首先到达这里
	# _input() 也接收一份（冒泡），两者互不影响
	pass


func _on_tap():
	if not _can_tap or _pulse_count >= _total_pulses: return
	_can_tap = false

	# 判定位置
	var deviation := absf(_cursor_x - 0.5)  # 0=中心，0.5=边缘
	var is_perfect := deviation <= _perfect_window
	var is_good := deviation <= _good_window

	if is_perfect:
		_perfect_hits += 1
		_status_lbl.text = "✨ 完美!"
		_status_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		_risk = maxf(0.0, _risk - 5.0)  # 完美降风险
	elif is_good:
		_status_lbl.text = "✓ 良好"
		_status_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
		# 良好不增不减
	else:
		_risk += _risk_per_miss
		_status_lbl.text = "✗ 失误!"
		_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		if _risk >= 100.0:
			_fail()

	_update_labels()
	# 震动反馈
	_do_vibrate(30 if is_perfect else 10)


func _fail():
	_failed = true
	_is_running = false
	_result_lbl.text = "💥 封卡失败！\n风险超额"
	_result_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_status_lbl.text = "风险: %.0f%% 💀" % _risk
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_finish_btn.disabled = false


func _end_game():
	_is_running = false
	var score := float(_perfect_hits) / float(_total_pulses) * 100.0
	var grade := _calc_grade(_perfect_hits)
	var grade_color := Color(0.3, 0.85, 0.3)
	if grade == "标准":   grade_color = Color(0.3, 0.7, 1.0)
	elif grade == "瑕疵": grade_color = Color(1.0, 0.7, 0.2)
	elif grade == "废品": grade_color = Color(1.0, 0.3, 0.3)

	_result_lbl.text = "【%s】%d/%d完美\n风险: %.0f%%" % [grade, _perfect_hits, _total_pulses, _risk]
	_result_lbl.add_theme_color_override("font_color", grade_color)
	_finish_btn.disabled = false


func _calc_grade(perfects: int) -> String:
	if perfects >= _total_pulses: return "完美"
	elif perfects >= int(_total_pulses * 0.75): return "标准"
	elif perfects >= int(_total_pulses * 0.5): return "瑕疵"
	else: return "废品"


func _update_labels():
	_pulse_lbl.text = "脉冲: %d/%d" % [_pulse_count, _total_pulses]
	_perfect_lbl.text = "完美: %d" % _perfect_hits
	_risk_lbl.text = "风险: %.0f%%" % mini(_risk, 100.0)
	if _risk >= 80.0:
		_risk_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	elif _risk >= 50.0:
		_risk_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	else:
		_risk_lbl.add_theme_color_override("font_color", Color(0.85, 0.4, 0.2))


func _do_vibrate(ms: int):
	# Android震动
	if DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld(ms)


func _draw():
	if not _ready_complete:
		return
	if not _game_container:
		return

	var container_pos = _game_container.global_position - global_position
	var w: float = _game_container.size.x * 0.85
	var h: float = 80.0
	var left: float = container_pos.x + (_game_container.size.x - w) * 0.5
	var top: float = container_pos.y + _game_container.size.y * 0.35

	# 外框
	draw_rect(Rect2(left - 4, top - 4, w + 8, h + 8), Color(0.25, 0.25, 0.35), true)

	# 背景条（深色）
	draw_rect(Rect2(left, top, w, h), Color(0.08, 0.08, 0.15), true)

	# 完美区域（绿色）
	var perfect_w = w * _perfect_window
	var perfect_cx = left + w * 0.5
	draw_rect(Rect2(perfect_cx - perfect_w * 0.5, top, perfect_w, h), Color(0.1, 0.6, 0.15, 0.6), true)

	# 良好区域（蓝色）
	var good_w = w * _good_window
	draw_rect(Rect2(perfect_cx - good_w * 0.5, top, good_w, h), Color(0.1, 0.3, 0.6, 0.3), true)

	# 游标（竖线）
	var cursor_px = left + _cursor_x * w
	var cursor_color := Color(1.0, 0.9, 0.2, 1.0)
	if _is_running:
		# 根据是否在完美区域变色
		var dev := absf(_cursor_x - 0.5)
		if dev <= _perfect_window:
			cursor_color = Color(0.3, 1.0, 0.3)
		elif dev <= _good_window:
			cursor_color = Color(0.3, 0.7, 1.0)
		else:
			cursor_color = Color(1.0, 0.3, 0.3)
	draw_line(Vector2(cursor_px, top - 10), Vector2(cursor_px, top + h + 10), cursor_color, 6.0)

	# 中心标记线
	draw_line(Vector2(perfect_cx, top - 10), Vector2(perfect_cx, top + h + 10), Color(1.0, 1.0, 1.0, 0.5), 2.0)

	# 游标头部三角形
	var tri_points = [Vector2(cursor_px - 10, top - 16), Vector2(cursor_px + 10, top - 16), Vector2(cursor_px, top - 2)]
	draw_colored_polygon(tri_points, cursor_color)

	# 脉冲进度（顶部小条）
	var prog_w = w * (_phase / float(_total_pulses))
	draw_rect(Rect2(left, top + h + 16, w, 12), Color(0.12, 0.12, 0.2), true)
	draw_rect(Rect2(left, top + h + 16, prog_w, 12), Color(0.2, 0.7, 0.85), true)


func _make_nav(title: String) -> HBoxContainer:
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.size_flags_vertical = 0
	nav.custom_minimum_size = Vector2(0, 70)
	var back = Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(70, 70)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func(): CraftManager.goto_phase(CraftManager.Phase.LINE_DRAW))
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
	_start()


func _on_finish():
	# 计算得分：完美次数×12.5，失误但未失败
	var score := float(_perfect_hits) / float(_total_pulses) * 100.0
	if _failed: score = 20.0  # 失败只有20分
	CraftManager.start_test(score)
