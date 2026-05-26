extends Node
signal battle_end(winner: int)  # 0=玩家胜利, 1=AI胜利
signal turn_changed(current_turn: int)
signal log_message(msg: String)
signal ui_update()

var player: BattleSide
var enemy: BattleSide
var current_turn: int = 0  # 0=玩家, 1=AI
var turn_phase: String = "main"  # "draw", "main", "battle", "end"
var is_running: bool = false
var effect_executor: EffectExecutor

var _test_deck_data: Array[CardData] = []  # 测试用卡组

func _init():
	effect_executor = EffectExecutor.new()
	effect_executor.battle = self
	player = BattleSide.new(0)
	enemy = BattleSide.new(1)
	player.battle = self
	enemy.battle = self

func _ready():
	battle_end.connect(_on_battle_end)

func _on_battle_end(winner: int):
	# 战斗胜利奖励在 battle_gui._on_battle_end 中处理
	# 探索模式下不再使用 explore_scene，统一由 ps.return_to_scene 决定返回目标
	pass

func _get_area_level(em: Node) -> int:
	var idx = em.selected_area_index as int
	var areas_raw = em.get("AREAS")
	var areas = areas_raw as Array if areas_raw is Array else []
	if idx >= 0 and idx < areas.size():
		var a = areas[idx] as Dictionary
		return a.get("level", 1) as int
	return 1

func start_battle(player_deck: Array[CardData] = [], enemy_deck: Array[CardData] = []):
	player.reset()
	enemy.reset()
	current_turn = 0
	turn_phase = "main"
	is_running = true
	
	# 初始化测试卡组
	if player_deck.is_empty():
		player_deck = _create_test_deck()
	if enemy_deck.is_empty():
		enemy_deck = _create_test_deck()
	
	player.setup_deck(player_deck)
	enemy.setup_deck(enemy_deck)
	
	# 初始抽牌（各3张）
	for i in range(3):
		player.draw_card()
		enemy.draw_card()
	
	# 玩家先手，跳过抽牌阶段
	player.start_turn()
	
	emit_signal("ui_update")
	emit_signal("log_message","战斗开始！")

func _create_test_deck() -> Array[CardData]:
	var cards: Array[CardData] = []
	# 测试用卡牌数据
	for i in range(5):
		var cd = CardData.new()
		cd.name = "火焰战士"
		cd.attack = 3 + (i % 3)
		cd.health = 4
		cd.speed = 2
		cd.energy = 2
		cards.append(cd)
	
	for i in range(3):
		var cd = CardData.new()
		cd.name = "冰霜法师"
		cd.attack = 2
		cd.health = 3
		cd.speed = 3
		cd.energy = 2
		cards.append(cd)
	
	for i in range(4):
		var cd = CardData.new()
		cd.name = "火焰冲击"
		cd.attack = 0
		cd.health = 0
		cd.speed = 1
		cd.energy = 1
		var effect = {
			"trigger": "TR01",
			"target": {"type": "T02"},
			"action": {"type": "A01", "value": 3},
			"constraints": ["CO01", "CO03"]
		}
		cd.card_effects.clear()
		var eff_dict = {
			"trigger": "TR01",
			"target": {"type": "T02"},
			"action": {"type": "A01", "value": 3},
			"constraints": ["CO01", "CO03"]
		}
		cd.card_effects.append(eff_dict)
		cards.append(cd)
	
	return cards

func create_enemy_deck(area_level: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	var rng = RandomNumberGenerator.new()
	var base_atk = 2 + area_level * 2
	var base_hp = 3 + area_level * 2
	var base_energy = 1 + int(area_level / 2)
	var names = ["火焰战士", "冰霜法师", "雷光刺客", "暗影猎手", "神圣骑士", "混沌魔将"]
	for i in range(8):
		var cd = CardData.new()
		cd.name = names[rng.randi() % names.size()]
		cd.attack = base_atk + rng.randi() % 3
		cd.health = base_hp + rng.randi() % 3
		cd.speed = 2 + rng.randi() % 3
		cd.energy = base_energy + rng.randi() % 2
		cards.append(cd)
	for i in range(4):
		var cd = CardData.new()
		cd.name = "元素冲击"
		cd.attack = 0
		cd.health = 0
		cd.speed = 1
		cd.energy = base_energy - 1
		cd.card_effects.clear()
		cd.card_effects.append({
			"trigger": "TR01",
			"target": {"type": "T02"},
			"action": {"type": "A01", "value": base_atk + area_level},
			"constraints": ["CO01", "CO03"]
		})
		cards.append(cd)
	return cards

func end_turn():
	turn_phase = "end"
	# TR09「回合结束」：当前结束方触发自己场上的 TR09
	var ending_side = player if current_turn == 0 else enemy
	effect_executor.trigger_side_turn_end(ending_side)
	
	current_turn = 1 - current_turn
	turn_phase = "draw"
	
	if current_turn == 0:
		player.start_turn()
		player.draw_card()
	else:
		enemy.start_turn()
		enemy.draw_card()
		emit_signal("turn_changed", current_turn)
		# AI回合
		process_ai_turn()
	
	# 触发「回合开始」效果（TR08）：仅当前回合方的场上卡触发
	var current_side = player if current_turn == 0 else enemy
	effect_executor.trigger_side_turn_start(current_side)
	
	emit_signal("ui_update")

func use_card(card: CardInstance, target: CardInstance = null, slot_index: int = -1):
	if card == null or card.zone != "hand":
		return
	
	var side = player if card.owner == 0 else enemy
	
	# 检查能量
	if side.energy < card.card_data.energy:
		emit_signal("log_message","能量不足！")
		return
	
	# 检查约束
	for eff_data in card.card_data.card_effects:
		for c in eff_data.get("constraints", []):
			if c in ["CO01", "CO02"] and card.used_constraints.has(c):
				emit_signal("log_message","%s 的效果本回合已使用" % card.card_data.name)
				return
	
	side.energy -= card.card_data.energy
	
	# ── TR01「主动使用」触发 ──
	effect_executor.trigger_effects("active_use", card)
	
	# 所有卡牌统一召唤上场
	side.summon_to_field(card, slot_index)
	var who = "玩家" if card.owner == 0 else "敌方"
	emit_signal("log_message","%s 召唤了 %s" % [who, card.card_data.name])
	
	# 触发入场效果
	effect_executor.trigger_effects("enter_field", card)
	# 触发召唤成功（TR12，紧接入场之后）
	effect_executor.trigger_effects("summon_success", card)
	
	# 若有 CO03（使用后破坏）→ 立即送墓
	if card.has_constraint("CO03"):
		side.send_to_grave(card)
		emit_signal("log_message","%s 被破坏了（使用后破坏）" % card.card_data.name)

	# 若有 CO04（使用后除外）→ 立即除外
	if card.has_constraint("CO04"):
		exclude_card(card)
		emit_signal("log_message","%s 被除外了" % card.card_data.name)

	emit_signal("ui_update")


func attack(attacker: CardInstance, defender: CardInstance):
	if attacker == null or defender == null:
		return
	if not attacker.can_attack_this_turn:
		emit_signal("log_message","%s 本回合已攻击过" % attacker.card_data.name)
		return
	
	# 检查 CO13（不可攻击）
	if attacker.has_constraint("CO13"):
		emit_signal("log_message","%s 无法进行攻击" % attacker.card_data.name)
		return
	
	# 检查 CO14（不可被攻击）
	if defender.has_constraint("CO14"):
		emit_signal("log_message","%s 不可被攻击" % defender.card_data.name)
		return
	
	attacker.can_attack_this_turn = false
	
	# 互相伤害
	var dead_d = defender.take_damage(attacker.current_attack)
	var dead_a = attacker.take_damage(defender.current_attack)
	
	# TR06「受伤」：在伤害判定后立即触发
	effect_executor.trigger_effects("destroy", defender)
	effect_executor.trigger_effects("destroy", attacker)
	effect_executor.trigger_effects("attack", attacker)
	effect_executor.trigger_effects("be_attacked", defender)
	
	emit_signal("log_message","%s 攻击 %s，双方受到 %d 点伤害" % [attacker.card_data.name, defender.card_data.name, attacker.current_attack])
	
	if dead_d:
		destroy_card(defender)
	if dead_a:
		destroy_card(attacker)
	
	emit_signal("ui_update")


func direct_attack(attacker: CardInstance):
	if attacker == null or not attacker.can_attack_this_turn:
		return
	
	# 检查 CO13（不可攻击）
	if attacker.has_constraint("CO13"):
		emit_signal("log_message","%s 无法进行攻击" % attacker.card_data.name)
		return
	
	attacker.can_attack_this_turn = false
	var enemy_side = enemy if attacker.owner == 0 else player
	var dead = enemy_side.take_damage(attacker.current_attack)
	
	emit_signal("log_message","%s 直接攻击了敌方，造成 %d 点伤害" % [attacker.card_data.name, attacker.current_attack])
	effect_executor.trigger_effects("attack", attacker)
	
	if dead:
		finish_battle(attacker.owner)
	
	emit_signal("ui_update")

func destroy_card(card: CardInstance):
	var side = player if card.owner == 0 else enemy
	side.send_to_grave(card)
	effect_executor.trigger_effects("leave_field", card)
	effect_executor.trigger_effects("destroy", card)
	emit_signal("log_message","%s 被破坏了" % card.card_data.name)

func exclude_card(card: CardInstance):
	var side = player if card.owner == 0 else enemy
	for arr in [side.hand, side.field, side.active_effects]:
		if arr.has(card):
			arr.erase(card)
			break
	card.zone = "excluded"
	side.excluded.append(card)
	effect_executor.trigger_effects("leave_field", card)

func get_all_cards() -> Array[CardInstance]:
	var all: Array[CardInstance] = []
	all.append_array(player.field)
	all.append_array(enemy.field)
	all.append_array(player.active_effects)
	all.append_array(enemy.active_effects)
	return all

func get_enemy_side(for_owner: int) -> BattleSide:
	return enemy if for_owner == 0 else player

func process_ai_turn():
	emit_signal("log_message","敌方回合...")
	
	var side = enemy
	var playable: Array[CardInstance] = []
	
	for card in side.hand:
		if side.energy >= card.card_data.energy:
			playable.append(card)
	
	# 按能量从高到低使用
	playable.sort_custom(func(a, b): return a.card_data.energy > b.card_data.energy)
	
	for card in playable:
		if side.energy >= card.card_data.energy:
			use_card(card)
			await get_tree().create_timer(0.8).timeout
	
	# 攻击
	for card in side.field:
		if card.can_attack_this_turn:
			if not player.field.is_empty():
				# 攻击玩家场上的怪兽（攻击力最低的）
				var targets = player.field.filter(func(c): return c != null)
				targets.sort_custom(func(a, b): return a.current_attack < b.current_attack)
				if targets.size() > 0:
					attack(card, targets[0])
			else:
				# 玩家场上无怪兽，直接攻击玩家
				direct_attack(card)
			await get_tree().create_timer(0.6).timeout
	
	await get_tree().create_timer(0.5).timeout
	end_turn()

func finish_battle(winner: int):
	is_running = false
	emit_signal("battle_end", winner)
	emit_signal("log_message", "%s 获得了胜利！" % ["玩家" if winner == 0 else "敌方"])

func update_ui():
	emit_signal("ui_update")

func trigger_event(event_name: String, source: CardInstance = null, context: Dictionary = {}):
	effect_executor.trigger_effects(event_name, source, context)
