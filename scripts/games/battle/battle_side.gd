class_name BattleSide
extends RefCounted

var owner_id: int          # 0=玩家, 1=AI
var health: int = 20
var max_health: int = 20
var energy: int = 0
var max_energy: int = 10
var deck: Array[CardInstance]
var hand: Array[CardInstance]
var field: Array[CardInstance]  # 最多5个
var graveyard: Array[CardInstance]
var excluded: Array[CardInstance]
var active_effects: Array[CardInstance]  # 永续魔法/陷阱/光环
var battle  # BattleManager reference (由 BattleManager.setup_deck 注入)

func _init(pid: int):
	owner_id = pid

func reset():
	health = 20
	max_health = 20
	energy = 0
	max_energy = 10
	deck.clear()
	hand.clear()
	field.clear()
	graveyard.clear()
	excluded.clear()
	active_effects.clear()

func setup_deck(cards: Array[CardData]):
	deck.clear()
	for data in cards:
		var inst = CardInstance.new(data)
		inst.owner = owner_id
		inst.zone = "deck"
		deck.append(inst)
	# 洗牌
	deck.shuffle()

func draw_card() -> CardInstance:
	if deck.is_empty():
		return null
	var card = deck.pop_front()
	card.zone = "hand"
	hand.append(card)
	# 触发「抽牌后」效果（TR10）
	battle.effect_executor.trigger_effects("draw_card", card)
	return card

func summon_to_field(card: CardInstance, slot_index: int = -1) -> bool:
	if field.size() >= 5:
		return false
	if card.zone != "hand":
		return false
	hand.erase(card)
	card.zone = "field"
	card.summon_sickness = true
	card.can_attack_this_turn = false
	# 指定槽位
	if slot_index >= 0 and slot_index < 5 and (field.size() <= slot_index or field[slot_index] == null):
		while field.size() < slot_index:
			field.append(null)
		if field.size() == slot_index:
			field.append(card)
		else:
			field[slot_index] = card
	else:
		field.append(card)
	return true

func send_to_grave(card: CardInstance):
	for arr in [hand, field, active_effects]:
		if arr.has(card):
			arr.erase(card)
			break
	card.zone = "graveyard"
	graveyard.append(card)

func get_field_count() -> int:
	return field.size()

func take_damage(amount: int) -> bool:
	health -= amount
	return health <= 0

func is_alive() -> bool:
	return health > 0

func start_turn():
	# 能量恢复
	energy = mini(energy + 3, max_energy)
	# 重置场上怪兽的攻击状态
	for card in field:
		if card != null:
			card.refresh_turn()

func get_card_by_id(uid: int) -> CardInstance:
	for arr in [hand, field, graveyard, excluded]:
		for c in arr:
			if c.unique_id == uid:
				return c
	return null
