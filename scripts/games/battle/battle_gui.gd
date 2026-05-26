extends Control

var battle
var _selected_card: CardInstance = null
var _selecting_attack: bool = false

# 拖拽状态
var _dragging_card: CardInstance = null
var _dragging_hand_idx: int = -1
var _drag_gui: Control = null
var _dragging_from_hand: bool = false
var _dragging_from_field: bool = false

# 点击状态（短按=查看详情，长拖=出牌/攻击）
const TAP_THRESHOLD: float = 20.0
var _tap_start_pos: Vector2 = Vector2.ZERO
var _tap_card: CardInstance = null  # {card, is_enemy, slot_idx}
var _tap_source: String = ""  # "hand" | "player_field" | "enemy_field"

# 节点引用（battle_scene.tscn 结构）
@onready var TopBar = $TopBar
@onready var SettingsBtn = $TopBar/HBox/SettingsBtn
@onready var TitleLbl = $TopBar/HBox/TitleLbl
@onready var SoundBtn = $TopBar/HBox/SoundBtn

@onready var EnemyArea = $EnemyArea
@onready var EHPLbl = $EnemyArea/EnemyStats/EHPLbl
@onready var EDeckLbl = $EnemyArea/EnemyStats/EDeckLbl
@onready var EGraveLbl = $EnemyArea/EnemyStats/EGraveLbl
@onready var EField = $EnemyArea/EField

@onready var LogArea = $LogArea
@onready var LogLbl = $LogArea/LogLbl

@onready var PlayerArea = $PlayerArea
@onready var PField = $PlayerArea/PField
@onready var PHPLbl = $PlayerArea/PlayerStats/PHPLbl
@onready var PDeckLbl = $PlayerArea/PlayerStats/PDeckLbl
@onready var PGraveLbl = $PlayerArea/PlayerStats/PGraveLbl

@onready var HandArea = $HandArea
@onready var HandBox = $HandArea/HandBox

@onready var BottomBar = $BottomBar
@onready var EndTurnBtn = $BottomBar/HBox/EndTurnBtn
@onready var EnergyLbl = $BottomBar/HBox/EnergyLbl

func _ready():
	battle = $BattleManager
	battle.battle_end.connect(_on_battle_end)
	battle.turn_changed.connect(_on_turn_changed)
	battle.log_message.connect(_on_log_message)
	battle.ui_update.connect(_refresh_ui)

	SettingsBtn.pressed.connect(_on_settings)
	SoundBtn.pressed.connect(_on_sound)
	EndTurnBtn.pressed.connect(_on_end_turn)

	# 加载真实卡组
	var em = get_node_or_null("/root/ExploreManager")
	var ps = get_node("/root/PlayerSave")

	# 玩家卡组
	var player_deck: Array[CardData] = []
	if ps.deck_cards.size() > 0:
		for card_name in ps.deck_cards:
			var files = ps.get_all_card_files()
			for f in files:
				if f.get_file().find(card_name) >= 0:
					var cd = CardData.load_from_file(f)
					if cd != null:
						player_deck.append(cd)
					break

	# 敌方卡组（按区域等级）
	var enemy_deck: Array[CardData] = []
	var area_level = 1
	if em != null and em.selected_area_index >= 0:
		var areas = [
		{"level": 1}, {"level": 1},
		{"level": 2}, {"level": 3}
		]
		if em.selected_area_index < areas.size():
			area_level = areas[em.selected_area_index].get("level", 1)
	enemy_deck = battle.create_enemy_deck(area_level)

	battle.start_battle(player_deck, enemy_deck)
	_refresh_ui()
	_adjust_layout()

# ─── 主刷新 ─────────────────────────────────
func _refresh_ui():
	if battle == null:
		return

	var ep = battle.enemy
	var pp = battle.player

	# 敌方状态
	EHPLbl.text = "HP: %d" % ep.health
	EDeckLbl.text = "牌堆: %d" % ep.deck.size()
	EGraveLbl.text = "墓地: %d" % ep.graveyard.size()

	# 我方状态
	PHPLbl.text = "HP: %d" % pp.health
	PDeckLbl.text = "牌堆: %d" % pp.deck.size()
	PGraveLbl.text = "墓地: %d" % pp.graveyard.size()

	# 能量
	EnergyLbl.text = "能量: %d/%d" % [pp.energy, pp.max_energy]

	# 回合标签
	if battle.current_turn == 0:
		TitleLbl.text = "[我方回合]"
		TitleLbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		EndTurnBtn.disabled = false
	else:
		TitleLbl.text = "[敌方回合]"
		TitleLbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		EndTurnBtn.disabled = true

	# 刷新场地
	_update_field(EField, ep.field, true)
	_update_field(PField, pp.field, false)
	# 刷新手牌
	_update_hand(pp.hand)

# ─── 布局自适应 ──────────────────────────────
func _adjust_layout():
	var screen_h = get_viewport_rect().size.y
	var bb_top = screen_h - 90  # BottomBar 上边缘

	if screen_h <= 1920:
		return  # 默认布局刚好

	var extra = screen_h - 1920
	# 按比例分配多余高度：敌方30%、日志15%、我方30%、手牌25%
	var e_extra = int(extra * 0.30)
	var l_extra = int(extra * 0.15)
	var p_extra = int(extra * 0.30)
	var h_extra = int(extra * 0.25)

	# 敌方区域
	$EnemyArea.offset_bottom += e_extra
	# 日志区域（整体下移+加高）
	$LogArea.offset_top = $EnemyArea.offset_bottom + 6
	$LogArea.offset_bottom = $LogArea.offset_top + 120 + l_extra
	# 我方区域
	$PlayerArea.offset_top = $LogArea.offset_bottom + 6
	$PlayerArea.offset_bottom = $PlayerArea.offset_top + 440 + p_extra
	# 手牌区域
	$HandArea.offset_top = $PlayerArea.offset_bottom + 6
	$HandArea.offset_bottom = bb_top - 6

# ─── 场地区 ─────────────────────────────────
func _update_field(grid: GridContainer, cards: Array[CardInstance], is_enemy: bool):
	var slots = grid.get_children()
	for i in range(4):
		if i < slots.size():
			_populate_slot(slots[i], cards[i] if i < cards.size() else null, is_enemy)

func _populate_slot(slot: PanelContainer, card: CardInstance, is_enemy: bool):
	var vbox = slot.get_node("VBox")
	for ch in vbox.get_children():
		ch.queue_free()

	if card == null:
		var lbl = Label.new()
		lbl.text = "-"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(lbl)
		return

	# 背景色
	var bg = Color(0.45, 0.12, 0.12) if is_enemy else Color(0.12, 0.25, 0.45)
	slot.add_theme_color_override("bg_color", bg)

	# VBox垂直居中内容
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# 卡名
	var name_lbl = Label.new()
	name_lbl.text = card.card_data.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.custom_minimum_size = Vector2(0, 36)
	name_lbl.text_overrun_behavior = 1
	vbox.add_child(name_lbl)

	# 能量
	var en_lbl = Label.new()
	en_lbl.text = "EN %.0f" % card.card_data.energy
	en_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	en_lbl.add_theme_font_size_override("font_size", 16)
	en_lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	vbox.add_child(en_lbl)

	# ATK
	var atk_lbl = Label.new()
	atk_lbl.text = "ATK %d" % card.card_data.attack
	atk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atk_lbl.add_theme_font_size_override("font_size", 20)
	atk_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	vbox.add_child(atk_lbl)

	# DEF
	var def_lbl = Label.new()
	def_lbl.text = "DEF %d" % card.card_data.health
	def_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_lbl.add_theme_font_size_override("font_size", 20)
	def_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	vbox.add_child(def_lbl)

	return


func _update_hand(cards: Array[CardInstance]):
	# 清空手牌区域
	for ch in HandBox.get_children():
		ch.queue_free()
	# 重新创建手牌
	for i in range(cards.size()):
		var card = cards[i]
		var panel = _make_hand_card(card, i)
		HandBox.add_child(panel)


func _make_hand_card(card: CardInstance, hand_idx: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(248, 347)
	panel.add_theme_color_override("bg_color", Color(0.12, 0.12, 0.38, 1.0))

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# 卡名
	var name_lbl = Label.new()
	name_lbl.text = card.card_data.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.custom_minimum_size = Vector2(0, 50)
	name_lbl.text_overrun_behavior = 1
	vbox.add_child(name_lbl)

	# 类型
	var type_txt = "卡牌"
	var type_lbl = Label.new()
	type_lbl.text = type_txt
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 20)
	type_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	vbox.add_child(type_lbl)

	# 能量
	var en_lbl = Label.new()
	en_lbl.text = "EN %.0f" % card.card_data.energy
	en_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	en_lbl.add_theme_font_size_override("font_size", 28)
	en_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	vbox.add_child(en_lbl)

	# ATK / DEF
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

	# 存储手牌索引到 metadata
	panel.set_meta("hand_idx", hand_idx)
	panel.set_meta("card", card)

	# 触摸进入/离开事件
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	return panel


# ─── 拖拽系统 ─────────────────────────────────
func _input(event: InputEvent):
	if battle == null:
		return

	# 触摸按下：记录点击目标
	if event is InputEventScreenTouch and event.pressed:
		_tap_start_pos = event.position
		_tap_card = null
		_tap_source = ""

		# 1. 尝试手牌
		for i in range(HandBox.get_child_count()):
			var child = HandBox.get_child(i)
			if child is PanelContainer and child.get_global_rect().has_point(event.position):
				var card: CardInstance = child.get_meta("card")
				if card != null:
					_tap_card = card
					_tap_source = "hand"
				return

		# 2. 尝试我方场地（我方回合才可拖出攻击）
		if battle.current_turn == 0:
			var slots = PField.get_children()
			for i in range(slots.size()):
				if slots[i].get_global_rect().has_point(event.position):
					var field_cards = battle.player.field
					if i < field_cards.size() and field_cards[i] != null:
						_tap_card = field_cards[i]
						_tap_source = "player_field"
					return

		# 3. 尝试敌方场地（只能查看详情）
		var e_slots = EField.get_children()
		for i in range(e_slots.size()):
			if e_slots[i].get_global_rect().has_point(event.position):
				var enemy_cards = battle.enemy.field
				if i < enemy_cards.size() and enemy_cards[i] != null:
					_tap_card = enemy_cards[i]
					_tap_source = "enemy_field"
				return

	# 触摸拖拽：超过阈值才开始拖拽
	if event is InputEventScreenDrag and _tap_card != null:
		if _tap_card != null and _dragging_card == null:
			var dist = (event.position - _tap_start_pos).length()
			if dist > TAP_THRESHOLD:
				# 实际开始拖拽
				if _tap_source == "hand" and battle.current_turn == 0:
					var hand_idx = _find_hand_idx(_tap_card)
					var panel = HandBox.get_child(hand_idx) if hand_idx >= 0 else null
					if panel:
						_start_drag_from_hand(panel, _tap_card, hand_idx, _tap_start_pos)
				elif _tap_source == "player_field" and battle.current_turn == 0:
					var slot_idx = _find_field_slot(_tap_card, battle.player.field)
					var slot = PField.get_child(slot_idx) if slot_idx >= 0 else null
					if slot and _tap_card.can_attack_this_turn and not _tap_card.summon_sickness:
						_start_drag_from_field(slot, _tap_card, slot_idx, _tap_start_pos)
				# enemy_field 不可拖拽

		if _dragging_card != null:
			_update_drag(event.position)

	# 触摸释放：短按=查看详情，长按=放下
	if event is InputEventScreenTouch and not event.pressed and _tap_card != null:
		var dist = (event.position - _tap_start_pos).length()
		if dist <= TAP_THRESHOLD:
			# 短按 → 查看详情
			if _dragging_card != null:
				pass  # 已在拖拽中，复位
			else:
				var is_enemy = (_tap_source == "enemy_field")
				_show_card_detail(_tap_card, is_enemy)
		else:
			# 长拖 → 放下
			if _dragging_card != null:
				_end_drag(event.position)

		_tap_card = null
		_tap_source = ""

# ─── 辅助：找手牌索引 ────────────────────────
func _find_hand_idx(card: CardInstance) -> int:
	for i in range(HandBox.get_child_count()):
		var child = HandBox.get_child(i)
		if child.get_meta("card") == card:
			return i
	return -1

# ─── 辅助：找场地槽位 ────────────────────────
func _find_field_slot(card: CardInstance, field: Array) -> int:
	for i in range(field.size()):
		if field[i] == card:
			return i
	return -1

func _start_drag_from_hand(panel: Control, card: CardInstance, hand_idx: int, touch_pos: Vector2):
	_dragging_card = card
	_dragging_hand_idx = hand_idx
	_dragging_from_hand = true
	_dragging_from_field = false

	# 创建半透明拖拽副本
	_drag_gui = PanelContainer.new()
	_drag_gui.custom_minimum_size = panel.custom_minimum_size
	_drag_gui.add_theme_color_override("bg_color", Color(0.3, 0.3, 0.8, 0.9))
	_drag_gui.z_index = 1000
	get_tree().root.add_child(_drag_gui)

	# 复制卡片内容到拖拽副本
	var vbox = VBoxContainer.new()
	_drag_gui.add_child(vbox)
	var lbl = Label.new()
	lbl.text = card.card_data.name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(lbl)
	var en = Label.new()
	en.text = "EN %.0f" % card.card_data.energy
	en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	en.add_theme_font_size_override("font_size", 28)
	en.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	vbox.add_child(en)
	var atk = Label.new()
	atk.text = "ATK %d" % card.card_data.attack
	atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atk.add_theme_font_size_override("font_size", 28)
	atk.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	vbox.add_child(atk)
	var def = Label.new()
	def.text = "DEF %d" % card.card_data.health
	def.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def.add_theme_font_size_override("font_size", 28)
	def.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	vbox.add_child(def)

	# 原卡变淡
	panel.modulate.a = 0.3

	# 设置初始位置（touch_pos 是相对于屏幕的）
	_update_drag(touch_pos)

func _update_drag(global_pos: Vector2):
	if _drag_gui == null:
		return
	_drag_gui.global_position = global_pos - _drag_gui.size * 0.5

# ─── 从场地拖出攻击 ─────────────────────────────
var _drag_from_slot: int = -1

func _start_drag_from_field(slot: Control, card: CardInstance, slot_idx: int, touch_pos: Vector2):
	_dragging_card = card
	_dragging_hand_idx = -1
	_dragging_from_hand = false
	_dragging_from_field = true
	_drag_from_slot = slot_idx

	# 创建攻击拖拽副本（红色调）
	_drag_gui = PanelContainer.new()
	_drag_gui.custom_minimum_size = slot.custom_minimum_size
	_drag_gui.add_theme_color_override("bg_color", Color(0.8, 0.15, 0.15, 0.9))
	_drag_gui.z_index = 1000
	get_tree().root.add_child(_drag_gui)

	var vbox = VBoxContainer.new()
	_drag_gui.add_child(vbox)
	var lbl = Label.new()
	lbl.text = "[ATTACK]"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lbl)
	var atk = Label.new()
	atk.text = "ATK %d" % card.current_attack
	atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atk.add_theme_font_size_override("font_size", 28)
	atk.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	vbox.add_child(atk)
	var def = Label.new()
	def.text = "DEF %d" % card.current_health
	def.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def.add_theme_font_size_override("font_size", 28)
	def.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	vbox.add_child(def)

	# 原卡变淡
	slot.modulate.a = 0.3
	_update_drag(touch_pos)

func _end_drag(global_pos: Vector2):
	if _drag_gui:
		_drag_gui.queue_free()
	_drag_gui = null

	# 恢复手牌透明度
	for child in HandBox.get_children():
		child.modulate.a = 1.0
	# 恢复场地透明度
	var pslots = PField.get_children()
	for slot in pslots:
		slot.modulate.a = 1.0

	if _dragging_card == null:
		return

	if _dragging_from_hand:
		_end_drag_from_hand(global_pos)
	elif _dragging_from_field:
		_end_drag_from_field(global_pos)

	_dragging_card = null
	_dragging_from_hand = false
	_dragging_from_field = false
	_drag_from_slot = -1

func _end_drag_from_hand(global_pos: Vector2):
	var dropped_on_slot = _get_slot_at_pos(global_pos)

	if dropped_on_slot >= 0:
		var field_cards = battle.player.field
		var slot_occupied = false
		if dropped_on_slot < field_cards.size():
			slot_occupied = field_cards[dropped_on_slot] != null
		if slot_occupied:
			return

		if battle.player.field.size() < 5:
			battle.use_card(_dragging_card, null, dropped_on_slot)
		else:
			battle.emit_signal("log_message", "[场上已满]")
	else:
		if battle.player.field.size() < 5:
			battle.use_card(_dragging_card, null, -1)
		else:
			battle.emit_signal("log_message", "[场上已满]")

func _end_drag_from_field(global_pos: Vector2):
	var enemy_slot = _get_enemy_slot_at_pos(global_pos)

	if enemy_slot >= 0:
		# 拖到敌方怪兽，发动攻击
		var enemy_cards = battle.enemy.field
		if enemy_slot < enemy_cards.size() and enemy_cards[enemy_slot] != null:
			battle.attack(_dragging_card, enemy_cards[enemy_slot])
	elif battle.enemy.field.is_empty():
		# 敌方无怪兽，直接攻击
		battle.direct_attack(_dragging_card)

func _get_slot_at_pos(screen_pos: Vector2) -> int:
	var slots = PField.get_children()
	for i in range(slots.size()):
		if slots[i].get_global_rect().has_point(screen_pos):
			return i
	return -1

func _get_enemy_slot_at_pos(screen_pos: Vector2) -> int:
	var slots = EField.get_children()
	for i in range(slots.size()):
		if slots[i].get_global_rect().has_point(screen_pos):
			return i
	return -1

func _on_card_selected(card: CardInstance):
	if _selecting_attack and _selected_card != null:
		battle.attack(_selected_card, card)
		_selecting_attack = false
		_selected_card = null
	elif card.can_attack_this_turn and battle.current_turn == 0:
		if battle.enemy.field.is_empty():
			battle.direct_attack(card)
		else:
			_selecting_attack = true
			_selected_card = card
			battle.emit_signal("log_message", "[选择攻击目标]")

func _on_end_turn():
	if battle.current_turn == 0:
		battle.end_turn()

func _on_turn_changed(turn: int):
	_selecting_attack = false
	_selected_card = null

func _on_battle_end(winner: int):
	var msg = "【玩家胜利】" if winner == 0 else "【敌方胜利】"
	LogLbl.append_text("\n" + msg)
	if winner == 0:
		# 胜利掉落
		var ps = get_node_or_null("/root/PlayerSave")
		var em = get_node_or_null("/root/ExploreManager")
		if ps != null and em != null and em.selected_area_index >= 0:
			var areas = [{"level":1},{"level":1},{"level":2},{"level":3}]
			var lvl = 1
			if em.selected_area_index < areas.size():
				lvl = areas[em.selected_area_index].get("level", 1)
			var drops = MaterialData.generate_explore_drops(lvl)
			ps.add_explore_drops(drops)
			var drop_names = []
			for d in drops:
				drop_names.append("%s ×%d" % [d.get("id", "?"), d.get("count", 1)])
			if drop_names.size() > 0:
				msg += "\n获得: " + ", ".join(drop_names)
	await get_tree().create_timer(1.5).timeout
	var d = ConfirmationDialog.new()
	d.dialog_text = msg + "\n是否返回？"
	d.ok_button_text = "确定"
	d.cancel_button_text = "留在战场"
	d.confirmed.connect(_return_to_main)
	add_child(d)
	d.popup_centered()

func _return_to_main():
	queue_free()
	var ps = get_node_or_null("/root/PlayerSave")
	var dest = "res://scenes/main.tscn"
	if ps != null:
		if ps.return_to_scene == "city_map_scene":
			dest = "res://scenes/world/city_map_scene.tscn"
		elif ps.return_to_scene == "world_map_scene":
			dest = "res://scenes/world/world_map_scene.tscn"
		elif ps.return_to_scene.begins_with("res://"):
			dest = ps.return_to_scene
		ps.return_to_scene = ""
		ps.save_data()
	get_tree().change_scene_to_file(dest)

func _on_log_message(msg: String):
	LogLbl.append_text("\n" + msg)

func _on_settings():
	pass

func _on_sound():
	pass

# ─── 卡牌详情弹窗 ──────────────────────────────
func _show_card_detail(card: CardInstance, is_enemy: bool):
	var cd = card.card_data
	if cd == null:
		return

	# 遮罩
	var overlay = ColorRect.new()
	overlay.z_index = 200
	overlay.anchor_left = 0.0; overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0; overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	add_child(overlay)

	# 点击遮罩关闭
	overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			overlay.queue_free()
	)

	# 弹窗本体（竖版卡牌比例）
	var dialog = PanelContainer.new()
	dialog.z_index = 201
	dialog.anchor_left = 0.5; dialog.anchor_right = 0.5
	dialog.anchor_top = 0.5; dialog.anchor_bottom = 0.5
	dialog.offset_left = -400; dialog.offset_right = 400
	dialog.offset_top = -550; dialog.offset_bottom = 550
	var ds = StyleBoxFlat.new()
	ds.bg_color = Color(0.08, 0.09, 0.16, 0.98)
	ds.border_width_left = 2; ds.border_width_right = 2
	ds.border_width_top = 2; ds.border_width_bottom = 2
	ds.border_color = Color(0.5, 0.5, 0.65) if not is_enemy else Color(0.65, 0.3, 0.3)
	ds.corner_radius_top_left = 14; ds.corner_radius_top_right = 14
	ds.corner_radius_bottom_left = 14; ds.corner_radius_bottom_right = 14
	ds.content_margin_left = 20; ds.content_margin_right = 20
	ds.content_margin_top = 16; ds.content_margin_bottom = 16
	dialog.add_theme_stylebox_override("panel", ds)
	overlay.add_child(dialog)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog.add_child(vbox)

	# 标题栏
	var title_row = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_row)

	# 所属标签
	var owner_lbl = Label.new()
	owner_lbl.text = "[敌方] " if is_enemy else "[我方] "
	owner_lbl.add_theme_font_size_override("font_size", 24)
	owner_lbl.add_theme_color_override("font_color", Color(0.65, 0.3, 0.3) if is_enemy else Color(0.3, 0.65, 0.3))
	title_row.add_child(owner_lbl)

	var title_lbl = Label.new()
	title_lbl.text = cd.name
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title_lbl)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(60, 60)
	close_btn.add_theme_font_size_override("font_size", 36)
	close_btn.pressed.connect(func(): overlay.queue_free())
	title_row.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# 详情滚动区
	var detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(detail_scroll)

	var detail_vbox = VBoxContainer.new()
	detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(detail_vbox)

	# 字段
	var fields_arr: Array = cd.fields
	_add_detail_row(detail_vbox, "🏷️ 字段", "无" if fields_arr.size() == 0 else " ".join(fields_arr))

	# 当前状态（实时变化）
	_add_detail_row(detail_vbox, "⚔️ 当前攻击", "%d" % card.current_attack)
	_add_detail_row(detail_vbox, "❤️ 当前生命", "%d / %d" % [card.current_health, card.max_health])
	_add_detail_row(detail_vbox, "⚡ 速度", "%d" % card.current_speed)

	# 基础属性
	_add_detail_row(detail_vbox, "📊 原始攻击", "%d" % cd.attack)
	_add_detail_row(detail_vbox, "📊 原始生命", "%d" % cd.health)
	_add_detail_row(detail_vbox, "📊 原始速度", "%d" % cd.speed)

	# 能量
	_add_detail_row(detail_vbox, "💎 能量", "%.1f" % cd.energy)

	# 状态标签
	var status_parts: Array = []
	if card.summon_sickness:
		status_parts.append("⚠️失调")
	if card.can_attack_this_turn and not card.summon_sickness:
		status_parts.append("✅可攻击")
	if card.counters.size() > 0:
		var counters_str = ", ".join(card.counters.keys())
		status_parts.append("🔮%s" % counters_str)
	if status_parts.size() > 0:
		_add_detail_row(detail_vbox, "🏷️ 状态", " | ".join(status_parts))

	# 效果列表
	var effects_arr: Array = cd.card_effects
	if effects_arr.size() > 0:
		var eff_title = Label.new()
		eff_title.text = "─── 效果 ───"
		eff_title.add_theme_font_size_override("font_size", 36)
		eff_title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
		detail_vbox.add_child(eff_title)

		for i in range(effects_arr.size()):
			var eff_data = effects_arr[i]
			if eff_data is Dictionary:
				var eff = CardEffect.new()
				eff.load_from_dict(eff_data)
				var eff_lbl = Label.new()
				eff_lbl.text = "%d. %s" % [i + 1, eff.get_full_description()]
				eff_lbl.add_theme_font_size_override("font_size", 30)
				eff_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.55))
				eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				eff_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				detail_vbox.add_child(eff_lbl)
	else:
		var no_eff = Label.new()
		no_eff.text = "(无效果)"
		no_eff.add_theme_font_size_override("font_size", 30)
		no_eff.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		detail_vbox.add_child(no_eff)

	vbox.add_child(HSeparator.new())

	# 提示
	var hint_lbl = Label.new()
	hint_lbl.text = "点击外部或 ✕ 关闭"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 26)
	hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(hint_lbl)

# ─── 详情行工具 ──────────────────────────────
func _add_detail_row(parent: VBoxContainer, label_text: String, value_text: String):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	row.add_child(lbl)

	var val = Label.new()
	val.text = value_text
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 32)
	val.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	row.add_child(val)
