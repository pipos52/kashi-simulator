class_name CommissionGenerator
extends RefCounted

const TEMPLATES: Array[Dictionary] = [
	{
		"id": "CM01",
		"title": "新手任务：火系怪兽",
		"desc": "制作一张火系怪兽卡，攻击不低于5",
		"reward": 30,
		"req": {"type": "怪兽", "field": "火", "min_attack": 5}
	},
	{
		"id": "CM02",
		"title": "治疗系法术",
		"desc": "制作一张具有恢复效果的水系魔法卡",
		"reward": 40,
		"req": {"type": "魔法", "field": "水", "effect_keywords": ["恢复", "治疗"]}
	},
	{
		"id": "CM03",
		"title": "雷系快攻",
		"desc": "制作一张速度不低于8的雷系怪兽",
		"reward": 35,
		"req": {"type": "怪兽", "field": "雷", "min_speed": 8}
	},
	{
		"id": "CM04",
		"title": "高攻压制",
		"desc": "制作一张攻击不低于12的怪兽卡",
		"reward": 50,
		"req": {"type": "怪兽", "min_attack": 12}
	},
	{
		"id": "CM05",
		"title": "高品质检测",
		"desc": "制作一张品质评分不低于80的卡牌",
		"reward": 60,
		"req": {"min_quality": 80.0}
	},
	{
		"id": "CM06",
		"title": "土系守护",
		"desc": "制作一张土系生命怪兽，生命不低于10",
		"reward": 45,
		"req": {"type": "怪兽", "field": "土", "min_health": 10}
	},
	{
		"id": "CM07",
		"title": "控制型陷阱",
		"desc": "制作一张具有特殊效果的陷阱卡",
		"reward": 55,
		"req": {"type": "陷阱", "effect_keywords": ["破坏", "除外"]}
	},
	{
		"id": "CM08",
		"title": "疾风剑豪",
		"desc": "制作一张风系高速度怪兽，速度不低于10",
		"reward": 65,
		"req": {"type": "怪兽", "field": "风", "min_speed": 10}
	},
	{
		"id": "CM09",
		"title": "神圣支援",
		"desc": "制作一张光系魔法卡，效果包含恢复",
		"reward": 50,
		"req": {"type": "魔法", "field": "光", "effect_keywords": ["恢复"]}
	},
	{
		"id": "CM10",
		"title": "究极力量",
		"desc": "制作一张攻击15+生命10+的高速怪兽",
		"reward": 100,
		"req": {"type": "怪兽", "min_attack": 15, "min_health": 10, "min_speed": 6}
	},
	{
		"id": "CM11",
		"title": "暗影刺客",
		"desc": "制作一张闇系速度型刺客怪兽",
		"reward": 70,
		"req": {"type": "怪兽", "field": "闇", "min_speed": 9}
	},
	{
		"id": "CM12",
		"title": "全知者",
		"desc": "制作一张无字段高质量卡牌",
		"reward": 80,
		"req": {"min_quality": 75.0}
	}
]

static func generate_commissions(count: int = 3) -> Array[CommissionData]:
	var pool = TEMPLATES.duplicate()
	var result: Array[CommissionData] = []
	var used_indices: Array[int] = []
	
	for i in range(count):
		if pool.size() == 0:
			break
		var idx = randi() % pool.size()
		var tmpl = pool[idx]
		pool.remove_at(idx)
		
		var cd = CommissionData.new(
			tmpl["id"],
			tmpl["title"],
			tmpl["desc"],
			tmpl["reward"],
			tmpl["req"]
		)
		result.append(cd)
	
	return result

static func refresh_commissions(existing: Array[CommissionData], count: int = 3) -> Array[CommissionData]:
	var new_commissions: Array[CommissionData] = []
	for c in existing:
		new_commissions.append(c)
	
	while new_commissions.size() < count:
		var all_ids: Array[String] = []
		for c in new_commissions:
			all_ids.append(c.id)
		
		var pool: Array[Dictionary] = []
		for tmpl in TEMPLATES:
			if tmpl["id"] not in all_ids:
				pool.append(tmpl)
		
		if pool.is_empty():
			break
		
		var idx = randi() % pool.size()
		var tmpl = pool[idx]
		var cd = CommissionData.new(
			tmpl["id"],
			tmpl["title"],
			tmpl["desc"],
			tmpl["reward"],
			tmpl["req"]
		)
		new_commissions.append(cd)
	
	return new_commissions
