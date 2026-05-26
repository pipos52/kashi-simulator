class_name CommissionData
extends RefCounted

var id: String
var title: String
var description: String
var reward_gold: int
var requirements: Dictionary

func _init(p_id: String, p_title: String, p_desc: String, p_reward: int, p_req: Dictionary):
	id = p_id
	title = p_title
	description = p_desc
	reward_gold = p_reward
	requirements = p_req

func get_type_requirement() -> String:
	return requirements.get("type", "")

func get_min_attack() -> int:
	return requirements.get("min_attack", 0)

func get_min_health() -> int:
	return requirements.get("min_health", 0)

func get_min_speed() -> int:
	return requirements.get("min_speed", 0)

func get_min_quality() -> float:
	return requirements.get("min_quality", 0.0)

func get_required_field() -> String:
	return requirements.get("field", "")

func get_effect_keywords() -> Array:
	return requirements.get("effect_keywords", [])

func check_card(card_data: Dictionary) -> Dictionary:
	var result = {
		"pass": true,
		"reason": ""
	}
	
	if card_data.is_empty():
		result["pass"] = false
		result["reason"] = "无卡牌数据"
		return result
	
	var req_type = get_type_requirement()
	if req_type != "" and card_data.get("card_type", "") != req_type:
		result["pass"] = false
		result["reason"] = "需要类型: %s，当前: %s" % [req_type, card_data.get("card_type", "")]
		return result
	
	var min_atk = get_min_attack()
	if min_atk > 0 and card_data.get("attack", 0) < min_atk:
		result["pass"] = false
		result["reason"] = "需要攻击>=%d，当前: %d" % [min_atk, card_data.get("attack", 0)]
		return result
	
	var min_hp = get_min_health()
	if min_hp > 0 and card_data.get("health", 0) < min_hp:
		result["pass"] = false
		result["reason"] = "需要生命>=%d，当前: %d" % [min_hp, card_data.get("health", 0)]
		return result
	
	var min_spd = get_min_speed()
	if min_spd > 0 and card_data.get("speed", 0) < min_spd:
		result["pass"] = false
		result["reason"] = "需要速度>=%d，当前: %d" % [min_spd, card_data.get("speed", 0)]
		return result
	
	var min_q = get_min_quality()
	if min_q > 0.0:
		var quality = card_data.get("quality_score", 0.0)
		if quality < min_q:
			result["pass"] = false
			result["reason"] = "需要品质>=%.0f，当前: %.0f" % [min_q, quality]
			return result
	
	var req_field = get_required_field()
	if req_field != "":
		var fields: Array = card_data.get("fields", [])
		if req_field not in fields:
			result["pass"] = false
			result["reason"] = "需要字段: %s" % req_field
			return result
	
	var keywords = get_effect_keywords()
	if keywords.size() > 0:
		var effects: Array = card_data.get("effects", [])
		var has_keyword = false
		for eff in effects:
			var eff_str = JSON.stringify(eff).to_lower()
			for kw in keywords:
				if kw.to_lower() in eff_str:
					has_keyword = true
					break
		if not has_keyword:
			result["pass"] = false
			result["reason"] = "需要包含效果关键词: %s" % " ".join(keywords)
			return result
	
	return result
