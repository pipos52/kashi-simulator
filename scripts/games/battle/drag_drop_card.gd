extends Control
class_name DragDropCard

signal card_dropped(card: CardInstance, slot_index: int)
signal drag_started(card: CardInstance)
signal drag_ended()

var card: CardInstance
var slot_index: int = -1
var is_dragging: bool = false

var _drag_panel: PanelContainer = null
var _orig_panel: Control = null
var _drag_offset: Vector2 = Vector2.ZERO

func setup(p: Control, c: CardInstance, idx: int):
	_orig_panel = p
	card = c
	slot_index = idx

func _input(event: InputEvent):
	if not is_dragging:
		return

	if event is InputEventScreenDrag or (event is InputEventMouseMotion and not event is InputEventScreenTouch):
		_drag_panel.global_position = _get_drag_pos(event)

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var released = false
		if event is InputEventScreenTouch:
			released = not event.pressed
		elif event is InputEventMouseButton:
			released = not event.pressed and event.button_index == MOUSE_BUTTON_LEFT

		if released:
			_end_drag()

func _get_drag_pos(event) -> Vector2:
	if event is InputEventScreenDrag:
		return event.global_position - _drag_offset
	elif event is InputEventMouseMotion:
		return event.global_position - _drag_offset
	return _drag_panel.global_position

func _start_drag():
	is_dragging = true
	emit_signal("drag_started", card)

	_drag_panel = PanelContainer.new()
	_drag_panel.custom_minimum_size = _orig_panel.custom_minimum_size
	_drag_panel.add_theme_color_override("bg_color", Color(0.2, 0.2, 0.5, 0.95))
	_drag_panel.z_index = 1000

	var vbox = VBoxContainer.new()
	_drag_panel.add_child(vbox)

	var lbl = Label.new()
	lbl.text = card.card_data.name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(lbl)

	var en_lbl = Label.new()
	en_lbl.text = "EN %.0f" % card.card_data.energy
	en_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	en_lbl.add_theme_font_size_override("font_size", 28)
	en_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	vbox.add_child(en_lbl)

	var atk_lbl = Label.new()
	atk_lbl.text = "ATK %d" % card.card_data.attack
	atk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atk_lbl.add_theme_font_size_override("font_size", 28)
	atk_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	vbox.add_child(atk_lbl)

	var def_lbl = Label.new()
	def_lbl.text = "DEF %d" % card.card_data.health
	def_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_lbl.add_theme_font_size_override("font_size", 28)
	def_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	vbox.add_child(def_lbl)

	get_tree().root.add_child(_drag_panel)
	_orig_panel.modulate.a = 0.3

	# 计算拖拽偏移（手指在卡片中心的偏移）
	var gp = _orig_panel.global_position + _orig_panel.size * 0.5
	_drag_offset = _orig_panel.size * 0.5
	_drag_panel.global_position = gp - _drag_offset

func _end_drag():
	is_dragging = false
	_orig_panel.modulate.a = 1.0

	if _drag_panel:
		_drag_panel.queue_free()
		_drag_panel = null

	emit_signal("drag_ended")

func get_drop_slot_index() -> int:
	if not is_dragging or _drag_panel == null:
		return -1
	return slot_index
