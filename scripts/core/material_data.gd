# material_data.gd
# 10种基础素材 + 5维属性系统
# 纤维强度/能量亲和/纯度/灵性/稳定性 (0~100)
class_name MaterialData
extends RefCounted

# ─────────────────────────────────────────
# 10种素材定义
# ─────────────────────────────────────────

const MATERIALS: Array[Dictionary] = [
	{
		"id": "M01", "name": "木材碎片",
		"rarity": 1, "rarity_name": "普通",
		"main_area": "火焰森林",
		"desc": "木质纤维，用于造纸基础材料",
		"fiber": 40, "affinity": 20, "purity": 30, "spirit": 10, "stability": 30
	},
	{
		"id": "M02", "name": "星辉石粉",
		"rarity": 1, "rarity_name": "普通",
		"main_area": "冰霜洞穴",
		"desc": "矿物粉末，增加墨线稳定性",
		"fiber": 10, "affinity": 60, "purity": 50, "spirit": 30, "stability": 70
	},
	{
		"id": "M03", "name": "魔化树脂",
		"rarity": 2, "rarity_name": "稀有",
		"main_area": "雷光高地",
		"desc": "魔法树脂，提升能量传导效率",
		"fiber": 25, "affinity": 80, "purity": 55, "spirit": 50, "stability": 45
	},
	{
		"id": "M04", "name": "龙血墨囊",
		"rarity": 2, "rarity_name": "稀有",
		"main_area": "神秘遗迹",
		"desc": "龙族血液，赋予墨线属性亲和",
		"fiber": 20, "affinity": 90, "purity": 60, "spirit": 80, "stability": 50
	},
	{
		"id": "M05", "name": "灵光苔藓",
		"rarity": 1, "rarity_name": "普通",
		"main_area": "所有区域",
		"desc": "附魔植物，提升节点亲和度",
		"fiber": 15, "affinity": 50, "purity": 35, "spirit": 45, "stability": 40
	},
	{
		"id": "M06", "name": "雷击木",
		"rarity": 2, "rarity_name": "稀有",
		"main_area": "雷光高地",
		"desc": "被雷电劈过的木材，自带雷属性",
		"fiber": 55, "affinity": 85, "purity": 40, "spirit": 35, "stability": 25
	},
	{
		"id": "M07", "name": "霜晶石",
		"rarity": 2, "rarity_name": "稀有",
		"main_area": "冰霜洞穴",
		"desc": "凝结冰霜矿晶，增加冷却效果",
		"fiber": 30, "affinity": 75, "purity": 65, "spirit": 40, "stability": 60
	},
	{
		"id": "M08", "name": "火山灰",
		"rarity": 1, "rarity_name": "普通",
		"main_area": "火焰森林",
		"desc": "火山喷发灰烬，增加热属性",
		"fiber": 35, "affinity": 65, "purity": 25, "spirit": 20, "stability": 55
	},
	{
		"id": "M09", "name": "幽魂丝",
		"rarity": 3, "rarity_name": "史诗",
		"main_area": "神秘遗迹",
		"desc": "幽灵蚕丝，增加能量回路柔性",
		"fiber": 15, "affinity": 95, "purity": 80, "spirit": 90, "stability": 35
	},
	{
		"id": "M10", "name": "时空砂",
		"rarity": 4, "rarity_name": "传说",
		"main_area": "稀有区域极低",
		"desc": "时间沙粒，微小概率触发额外效果",
		"fiber": 20, "affinity": 100, "purity": 95, "spirit": 100, "stability": 20
	}
]

# ─────────────────────────────────────────
# 素材查询
# ─────────────────────────────────────────

static func get_material(id: String) -> Dictionary:
	for m in MATERIALS:
		if m["id"] == id:
			return m
	return {}

static func get_materials_by_area(area_name: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for m in MATERIALS:
		if m["main_area"] == area_name or m["main_area"] == "所有区域":
			result.append(m)
	return result

static func get_materials_by_rarity(min_rarity: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for m in MATERIALS:
		if m["rarity"] >= min_rarity:
			result.append(m)
	return result

# ─────────────────────────────────────────
# 探险掉落计算
# area_level: 1=火焰/冰霜, 2=雷光, 3=神秘遗迹
# ─────────────────────────────────────────

static func generate_explore_drops(area_level: int) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	var roll = randf()
	
	if area_level == 1:
		# 火焰/冰霜：普通素材为主，低概率稀有
		if roll < 0.5:
			drops.append({"id": "M01", "count": 1})
		elif roll < 0.8:
			drops.append({"id": "M05", "count": 1})
		elif roll < 0.92:
			drops.append({"id": "M08", "count": 1})
		elif roll < 0.98:
			drops.append({"id": "M06", "count": 1})
		elif roll < 1.0:
			drops.append({"id": "M07", "count": 1})
	elif area_level == 2:
		# 雷光高地：稀有较多
		if roll < 0.2:
			drops.append({"id": "M05", "count": 1})
		elif roll < 0.4:
			drops.append({"id": "M01", "count": 1})
		elif roll < 0.65:
			drops.append({"id": "M03", "count": 1})
		elif roll < 0.82:
			drops.append({"id": "M06", "count": 1})
		elif roll < 0.92:
			drops.append({"id": "M08", "count": 1})
		elif roll < 0.98:
			drops.append({"id": "M04", "count": 1})
		else:
			drops.append({"id": "M09", "count": 1})
	elif area_level == 3:
		# 神秘遗迹：史诗/传说概率
		if roll < 0.15:
			drops.append({"id": "M05", "count": 1})
		elif roll < 0.3:
			drops.append({"id": "M04", "count": 1})
		elif roll < 0.5:
			drops.append({"id": "M03", "count": 1})
		elif roll < 0.7:
			drops.append({"id": "M09", "count": 1})
		elif roll < 0.88:
			drops.append({"id": "M07", "count": 1})
		elif roll < 0.96:
			drops.append({"id": "M02", "count": 1})
		else:
			drops.append({"id": "M10", "count": 1})
	
	# 额外掉落（20%概率）
	if randf() < 0.2:
		var bonus = get_random_bonus_material(area_level)
		if bonus != "":
			drops.append({"id": bonus, "count": 1})
	
	return drops

static func get_random_bonus_material(area_level: int) -> String:
	var r = randf()
	if area_level == 3 and r < 0.1:
		return "M10"
	elif area_level >= 2 and r < 0.3:
		return "M09"
	elif area_level >= 1 and r < 0.5:
		var extra: Array[String] = ["M03", "M04", "M06", "M07"]
		return extra[randi() % extra.size()]
	return "M05"

# ─────────────────────────────────────────
# 造纸配方校验
# ─────────────────────────────────────────

static func validate_paper_recipe(materials: Array[String]) -> Dictionary:
	# 材料数量检查
	var count = materials.size()
	if count < 2 or count > 4:
		return {"valid": false, "reason": "白卡需要2-4个素材"}
	
	# 检查纯度
	for mid in materials:
		var m = get_material(mid)
		if m.is_empty():
			return {"valid": false, "reason": "未知素材: " + mid}
		if m["purity"] < 30 and count == 2:
			return {"valid": false, "reason": "普通白卡需要纯度>=30的素材"}
	
	# 检查稀有度
	var max_rarity = 0
	for mid in materials:
		var m = get_material(mid)
		max_rarity = maxi(max_rarity, m["rarity"])
	
	var grade = ""
	if count == 2:
		grade = "普通白卡"
	elif count == 3:
		if max_rarity >= 2:
			grade = "精良白卡"
		else:
			return {"valid": false, "reason": "精良白卡需要至少1个稀有素材"}
	elif count == 4:
		if max_rarity >= 3:
			grade = "精良白卡"
		elif max_rarity >= 2:
			grade = "精良白卡"
		else:
			return {"valid": false, "reason": "史诗白卡需要传说素材，精良白卡需要稀有素材"}
	
	return {"valid": true, "grade": grade}

# ─────────────────────────────────────────
# 造纸属性计算（公式来自内置逻辑v1）
# ─────────────────────────────────────────

static func calc_paper_properties(materials: Array[String]) -> Dictionary:
	var count = materials.size()
	var fiber_sum := 0.0
	var affinity_sum := 0.0
	var purity_sum := 0.0
	var spirit_sum := 0.0
	var stability_sum := 0.0
	var rare_count := 0
	
	for mid in materials:
		var m = get_material(mid)
		fiber_sum += m["fiber"]
		affinity_sum += m["affinity"]
		purity_sum += m["purity"]
		spirit_sum += m["spirit"]
		stability_sum += m["stability"]
		if m["rarity"] >= 2:
			rare_count += 1
	
	var N = float(count)
	var rare_mult = 1.0 + 0.05 * float(rare_count)
	
	var fiber_avg = fiber_sum / N * rare_mult
	var purity_avg = purity_sum / N * rare_mult
	var spirit_avg = spirit_sum / N * rare_mult
	var stability_avg = stability_sum / N
	
	# 基础能量上限 = (纤维×0.5 + 亲和×0.3 + 稳定×0.2) / 10
	var energy_cap = (fiber_avg * 0.5 + affinity_sum / N * 0.3 + stability_avg * 0.2) / 10.0
	# 品质上限系数 = (纯度×0.6 + 灵性×0.4) / 100
	var quality_cap = (purity_avg * 0.6 + spirit_avg * 0.4) / 100.0
	# 韧性 = (纤维×0.7 + 稳定×0.3) / 50
	var toughness = (fiber_avg * 0.7 + stability_avg * 0.3) / 50.0
	# 属性亲和（取亲和最高的属性）
	var affinity_type = _get_affinity_type(materials)
	
	return {
		"energy_cap": roundi(energy_cap * 10) / 10.0,
		"quality_cap": roundi(quality_cap * 100) / 100.0,
		"toughness": roundi(toughness * 100) / 100.0,
		"affinity_type": affinity_type,
		"grade": _calc_paper_grade(count, quality_cap)
	}

static func _get_affinity_type(materials: Array[String]) -> String:
	var max_aff := 0
	var best_type := "无"
	# 简单地根据素材分布决定亲和属性
	# 实际游戏中可以更复杂
	var type_map := {
		"M01": "木", "M06": "雷", "M08": "火",
		"M02": "水", "M07": "冰",
		"M03": "雷", "M05": "灵",
		"M04": "龙", "M09": "魂", "M10": "时空"
	}
	for mid in materials:
		var m = get_material(mid)
		if m["affinity"] > max_aff:
			max_aff = m["affinity"]
			best_type = type_map.get(mid, "无")
	return best_type

static func _calc_paper_grade(count: int, quality_cap: float) -> String:
	if count == 2:
		return "普通白卡"
	elif count == 3:
		return "精良白卡"
	else:
		return "史诗白卡"

# ─────────────────────────────────────────
# 制墨配方校验
# ─────────────────────────────────────────

static func validate_ink_recipe(materials: Array[String]) -> Dictionary:
	var count = materials.size()
	if count < 1 or count > 3:
		return {"valid": false, "reason": "墨线需要1-3个素材"}
	
	for mid in materials:
		var m = get_material(mid)
		if m.is_empty():
			return {"valid": false, "reason": "未知素材: " + mid}
		if m["purity"] < 20 and count == 1:
			return {"valid": false, "reason": "普通墨线需要纯度>=20的素材"}
	
	var max_rarity = 0
	for mid in materials:
		var m = get_material(mid)
		max_rarity = maxi(max_rarity, m["rarity"])
	
	if count == 1:
		return {"valid": true, "grade": "普通墨线"}
	elif count == 2:
		if max_rarity >= 2:
			return {"valid": true, "grade": "精良墨线"}
		else:
			return {"valid": false, "reason": "精良墨线需要至少1个稀有素材"}
	elif count == 3:
		if max_rarity >= 3:
			return {"valid": true, "grade": "星液墨线"}
		elif max_rarity >= 2:
			return {"valid": true, "grade": "精良墨线"}
		else:
			return {"valid": false, "reason": "星液墨线需要史诗/传说素材"}
	
	return {"valid": true, "grade": "普通墨线"}

# ─────────────────────────────────────────
# 制墨属性计算
# ─────────────────────────────────────────

static func calc_ink_properties(materials: Array[String]) -> Dictionary:
	var count = materials.size()
	var affinity_sum := 0.0
	var purity_sum := 0.0
	var spirit_sum := 0.0
	var stability_sum := 0.0
	var rare_count := 0
	
	for mid in materials:
		var m = get_material(mid)
		affinity_sum += m["affinity"]
		purity_sum += m["purity"]
		spirit_sum += m["spirit"]
		stability_sum += m["stability"]
		if m["rarity"] >= 2:
			rare_count += 1
	
	var N = float(count)
	var rare_ratio = float(rare_count) / N
	
	# 传导率 = (亲和×0.5 + 灵性×0.5) × (1 + 0.1×稀有比例)
	var conductivity = (affinity_sum / N * 0.5 + spirit_sum / N * 0.5) * (1.0 + 0.1 * rare_ratio)
	# 稳定性 = (纯度×0.4 + 稳定×0.6) × (1 - 0.05×稀有比例)
	var stability = (purity_sum / N * 0.4 + stability_sum / N * 0.6) * (1.0 - 0.05 * rare_ratio)
	# 传导效率
	var efficiency = conductivity / 100.0
	# 绘制难度
	var draw_difficulty = 100.0 - stability
	
	return {
		"conductivity": roundi(conductivity * 100) / 100.0,
		"stability": roundi(stability * 100) / 100.0,
		"efficiency": roundi(efficiency * 1000) / 1000.0,
		"draw_difficulty": roundi(draw_difficulty),
		"grade": _calc_ink_grade(count, rare_ratio)
	}

static func _calc_ink_grade(count: int, rare_ratio: float) -> String:
	if count == 1:
		return "普通墨线"
	elif count == 2:
		return "精良墨线"
	else:
		if rare_ratio >= 0.34:
			return "星液墨线"
		return "精良墨线"

# ─────────────────────────────────────────
# 成品卡牌最终属性计算
# ─────────────────────────────────────────

static func calc_final_card_properties(
	white_card: Dictionary,
	ink: Dictionary,
	energy_core_id: String,
	quality_score: float
) -> Dictionary:
	# 白卡基础能量上限
	var base_energy = white_card.get("energy_cap", 3.0)
	# 墨线传导效率
	var ink_eff = ink.get("efficiency", 0.3)
	# 能量核加成
	var core_bonus = 0.0
	var core_map := {
		"EC01": {"stat": "attack", "bonus": 3},
		"EC02": {"stat": "health", "bonus": 5},
		"EC03": {"stat": "speed", "bonus": 3},
		"EC04": {"stat": "none", "bonus": 0}
	}
	if core_map.has(energy_core_id):
		core_bonus = core_map[energy_core_id]["bonus"]
	
	# 最终能量上限
	var final_energy = base_energy * (1.0 + ink_eff * 0.2) * (1.0 + core_bonus * 0.1)
	
	# 有效品质分 = 小游戏总分 × (0.5 + 0.5 × 白卡品质上限系数)
	var quality_cap = white_card.get("quality_cap", 0.5)
	var effective_quality = quality_score * (0.5 + 0.5 * quality_cap)
	
	# 品质等级
	var grade := ""
	if effective_quality >= 90:
		grade = "完美"
	elif effective_quality >= 70:
		grade = "标准"
	elif effective_quality >= 50:
		grade = "瑕疵"
	else:
		grade = "废品"
	
	return {
		"final_energy": roundi(final_energy * 10) / 10.0,
		"effective_quality": roundi(effective_quality * 10) / 10.0,
		"quality_grade": grade
	}

static func get_aux_materials() -> Array[Dictionary]:
	return [
		{"id": "AU01", "name": "灵墨滴", "desc": "灵性+10，小游戏额外+5%品质", "cost": 15},
		{"id": "AU02", "name": "星辉粉", "desc": "纯度+15，小游戏额外+10%品质", "cost": 25},
		{"id": "AU03", "name": "无", "desc": "不使用辅材", "cost": 0}
	]


# 以下为兼容 crafter 阶段2 的接口（保留原有逻辑）
# ══════════════════════════════════════════════════════

static func get_paper_grades() -> Array[Dictionary]:
	return [
		{"id": "PG01", "name": "普通白卡", "desc": "基础能量上限3.0，品质+10%", "cost": 10},
		{"id": "PG02", "name": "精良白卡", "desc": "能量上限5.0，品质+25%", "cost": 30},
		{"id": "PG03", "name": "高级白卡", "desc": "能量上限7.0，品质+40%", "cost": 60}
	]

static func get_ink_types() -> Array[Dictionary]:
	return [
		{"id": "INK01", "name": "普通墨线", "desc": "传导效率30%，稳定性60%", "cost": 5},
		{"id": "INK02", "name": "精良墨线", "desc": "传导效率50%，稳定性80%", "cost": 15},
		{"id": "INK03", "name": "星液墨线", "desc": "传导效率80%，稳定性100%", "cost": 40}
	]

static func get_energy_cores() -> Array[Dictionary]:
	return [
		{"id": "EC01", "name": "火核", "desc": "攻击+3，火属性亲和", "cost": 20},
		{"id": "EC02", "name": "水核", "desc": "生命+5，水属性亲和", "cost": 20},
		{"id": "EC03", "name": "风核", "desc": "速度+3，风属性亲和", "cost": 20},
		{"id": "EC04", "name": "中立核", "desc": "无属性加成，无消耗", "cost": 0}
	]
