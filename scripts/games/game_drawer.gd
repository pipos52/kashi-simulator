class_name GameDrawer
extends Control

# 绘制模式: "node" = place_node游戏, "line" = draw_line游戏
var _draw_mode: String = "node"
var _nodes_data: Array = []
var _drawn_lines: Array = []
var _current_connection: int = 0
var _is_drawing: bool = false
var _temp_line_end: Vector2 = Vector2.ZERO
var _angle_tolerance: float = 8.0  # 角度容忍度，由 place_node 传入

# ===== place_node 模式 =====
func set_nodes(nodes: Array, angle_tolerance: float = 8.0) -> void:
	_draw_mode = "node"
	_nodes_data = nodes
	_drawn_lines = []
	_angle_tolerance = angle_tolerance
	queue_redraw()

# ===== draw_line 模式 =====
func set_line_data(nodes: Array, drawn_lines: Array, current_conn: int, is_drawing: bool, temp_end: Vector2) -> void:
	_draw_mode = "line"
	_nodes_data = nodes
	_drawn_lines = drawn_lines
	_current_connection = current_conn
	_is_drawing = is_drawing
	_temp_line_end = temp_end
	queue_redraw()

func _draw():
	if _nodes_data.is_empty(): return

	if _draw_mode == "node":
		_draw_nodes()
	elif _draw_mode == "line":
		_draw_lines()

func _draw_nodes():
	var pos_tolerance := 55.0
	for i in range(_nodes_data.size()):
		var nd: Dictionary = _nodes_data[i]
		if not nd.get("is_placed", false):
			var target_pos: Vector2 = nd.get("target_pos", Vector2.ZERO)
			var target_angle: float = nd.get("target_angle", 0.0)
			for s in range(36):
				if s % 2 == 0: continue
				var a1 := TAU * float(s) / 36.0
				var a2 := TAU * float(s + 1) / 36.0
				draw_line(target_pos + Vector2(cos(a1), sin(a1)) * pos_tolerance,
						target_pos + Vector2(cos(a2), sin(a2)) * pos_tolerance,
						Color(1.0, 0.8, 0.1, 0.85), 3.0)
			var arrow_end := target_pos + Vector2(cos(deg_to_rad(target_angle)), sin(deg_to_rad(target_angle))) * pos_tolerance * 0.8
			draw_line(target_pos, arrow_end, Color(1.0, 0.8, 0.1, 0.9), 3.0)
			draw_string(ThemeDB.fallback_font, target_pos + Vector2(0, -pos_tolerance - 18), "%.0f°" % target_angle, HORIZONTAL_ALIGNMENT_CENTER, 60, 28, Color(1.0, 0.8, 0.1, 0.9))
			draw_circle(target_pos, 14.0, Color(1.0, 0.8, 0.1, 0.85))
			draw_string(ThemeDB.fallback_font, target_pos + Vector2(-6, 6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, 40, 24, Color(0.1, 0.05, 0.0))
		else:
			var placed_pos: Vector2 = nd.get("placed_pos", Vector2.ZERO)
			var placed_angle: float = nd.get("placed_angle", 0.0)
			var target_angle: float = nd.get("target_angle", 0.0)
			var dev := fmod(placed_angle - target_angle + 180.0, 360.0) - 180.0
			var is_correct := absf(dev) <= _angle_tolerance
			var node_color := Color(0.2, 0.85, 0.2) if is_correct else Color(1.0, 0.6, 0.1)
			var na := deg_to_rad(placed_angle - 90.0)
			for j in range(6):
				var a1 := na + TAU * float(j) / 6.0
				var a2 := na + TAU * float(j + 1) / 6.0
				draw_line(placed_pos + Vector2(cos(a1), sin(a1)) * 22.0, placed_pos + Vector2(cos(a2), sin(a2)) * 22.0, node_color, 3.0)
			draw_circle(placed_pos, 8.0, node_color.darkened(0.3))
			var arr_end := placed_pos + Vector2(cos(na + PI * 0.5), sin(na + PI * 0.5)) * 36.0
			draw_line(placed_pos, arr_end, node_color, 3.0)
			if is_correct:
				draw_string(ThemeDB.fallback_font, placed_pos + Vector2(-8, -26), "OK", HORIZONTAL_ALIGNMENT_LEFT, 40, 28, Color(0.3, 1.0, 0.3))

func _draw_lines():
	var node_count := _nodes_data.size()
	if node_count == 0: return

	# 绘制节点
	for i in range(node_count):
		var np: Vector2 = _nodes_data[i]
		var is_done := i < (_current_connection % (node_count + 1))
		var is_current := i == (_current_connection % node_count)
		var is_next := i == ((_current_connection + 1) % node_count)

		var node_color := Color(0.3, 0.3, 0.4)
		if is_done: node_color = Color(0.2, 0.75, 0.3)
		elif is_current: node_color = Color(0.85, 0.7, 0.1)
		elif is_next: node_color = Color(0.3, 0.6, 0.9)

		draw_circle(np, 28.0, node_color.darkened(0.4))
		draw_arc(np, 28.0, 0.0, TAU, 32, node_color, 3.0)
		draw_circle(np, 18.0, node_color.darkened(0.2))

		var num_text := str(i + 1)
		var txt_color := Color(1.0, 1.0, 1.0, 0.9) if is_current or is_next else Color(0.7, 0.7, 0.7, 0.8)
		draw_string(ThemeDB.fallback_font, np + Vector2(-6, 6), num_text, HORIZONTAL_ALIGNMENT_LEFT, 40, 26, txt_color)

	# 绘制已完成的连接
	for line in _drawn_lines:
		var q: float = line.get("quality", 0.8)
		var col := Color(0.3, 0.5 + q * 0.5, 1.0, 0.9)
		draw_line(line["from"], line["to"], col, 8.0, true)

	# 绘制当前正在画的线
	if _is_drawing and node_count > 0:
		var from_node_idx := _current_connection % node_count
		var from_pos: Vector2 = _nodes_data[from_node_idx]
		draw_line(from_pos, _temp_line_end, Color(1.0, 0.85, 0.2, 0.7), 6.0, true)

		# 目标节点高亮
		var target_idx := (_current_connection + 1) % node_count
		draw_arc(_nodes_data[target_idx], 32.0, 0.0, TAU, 32, Color(0.3, 0.8, 1.0), 4.0)

		# 触摸点指示
		draw_circle(_temp_line_end, 18.0, Color(1.0, 0.85, 0.2, 0.8))
