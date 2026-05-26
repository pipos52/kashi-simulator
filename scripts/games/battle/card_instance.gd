extends Resource
class_name CardInstance

var card_data: CardData
var owner: int  # 0=玩家, 1=AI
var zone: String  # "hand", "field", "graveyard", "excluded", "deck"
var current_attack: int
var current_health: int
var current_speed: int
var max_health: int
var summon_sickness: bool = true   # 召唤失调（回合内不能攻击）
var can_attack_this_turn: bool = false
var used_constraints: Dictionary   # 记录已使用次数，如 {"CO01": 1}
var modifiers: Dictionary          # 临时 buff/debuff
var counters: Dictionary = {}      # 指示物：{"能量": 3, "充能": 1}
var unique_id: int = 0             # 唯一实例ID

static var _id_counter: int = 0

func _init(data: CardData = null):
	if data:
		card_data = data
		current_attack = data.attack
		current_health = data.health
		current_speed = data.speed
		max_health = data.health
		summon_sickness = true
		can_attack_this_turn = false
		used_constraints = {}
		modifiers = {}
		counters = {}
		unique_id = _id_counter
		_id_counter += 1

func take_damage(amount: int) -> bool:
	current_health -= amount
	if current_health <= 0:
		return true  # 死亡
	return false

func heal(amount: int):
	current_health = mini(current_health + amount, max_health)

func modify_attack(delta: int):
	current_attack = maxi(0, current_attack + delta)

func modify_health(delta: int):
	max_health += delta
	current_health += delta

func is_alive() -> bool:
	return current_health > 0

func can_summon() -> bool:
	return summon_sickness == false and zone == "hand"

func refresh_turn():
	summon_sickness = false
	can_attack_this_turn = true
	used_constraints.clear()  # 每回合重置 per-turn 约束（CO01等）

func has_constraint(constraint_id: String) -> bool:
	if card_data == null:
		return false
	for eff_data in card_data.card_effects:
		for c in eff_data.get("constraints", []):
			if c == constraint_id:
				return true
	return false
