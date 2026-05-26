# card_data.gd
# 卡牌数据类：存储完整卡牌的所有属性
class_name CardData
extends RefCounted

var name: String = "新卡牌"
var fields: Array[String] = []
var attack: int = 0
var health: int = 0
var speed: int = 0
var card_effects: Array = []
var energy: float = 0.0
var quality_grade: String = ""  # 成品品质等级（完美/标准/瑕疵/废品）
var created_at: String = ""

func get_preview_text() -> String:
	var field_prefix = ""
	if fields.size() > 0:
		field_prefix = fields[0] + "·"
	var attrs = "⚔️%d ❤️%d ⚡%d" % [attack, health, speed]
	return "%s%s" % [field_prefix, attrs]

func get_effects_description() -> String:
	if card_effects.size() == 0:
		return "(无效果)"
	var lines: Array[String] = []
	for i in range(card_effects.size()):
		var eff_data = card_effects[i]
		var eff = CardEffect.new()
		eff.load_from_dict(eff_data)
		var short = eff.get_short_description()
		lines.append("%d. %s" % [i + 1, short])
	return "\n".join(lines)

func get_full_effects_description() -> String:
	if card_effects.size() == 0:
		return "(无效果)"
	var lines: Array[String] = []
	for i in range(card_effects.size()):
		var eff_data = card_effects[i]
		var eff = CardEffect.new()
		eff.load_from_dict(eff_data)
		var full = eff.get_full_description()
		lines.append("%d. %s" % [i + 1, full])
	return "\n".join(lines)

func load_from_dict(d: Dictionary):
	name = d.get("name", "新卡牌")
	fields = []
	for f in d.get("fields", []):
		fields.append(str(f))
	attack = d.get("attack", 0)
	health = d.get("health", 0)
	speed = d.get("speed", 0)
	card_effects = []
	for e in d.get("effects", []):
		if e is Dictionary:
			card_effects.append(e)
	energy = d.get("energy", 0.0)
	quality_grade = d.get("quality_grade", "")
	created_at = d.get("created_at", "")

func to_dict() -> Dictionary:
	return {
		"name": name,
		"fields": fields,
		"attack": attack,
		"health": health,
		"speed": speed,
		"effects": card_effects,
		"energy": energy,
		"quality_grade": quality_grade,
		"created_at": created_at,
	}

static func load_from_file(file_path: String) -> CardData:
	var f = FileAccess.open(file_path, FileAccess.READ)
	if not f:
		return null
	var json_str = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return null
	var data = json.data as Dictionary
	if data.is_empty():
		return null
	var card = CardData.new()
	card.load_from_dict(data)
	return card
