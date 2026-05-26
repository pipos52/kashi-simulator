# card_effect.gd
# 效果数据类：存储单个效果的触发、条件、动作、目标、约束等信息
# 所有可带字段的组件（条件/目标/动作）统一使用 field 参数
class_name CardEffect
extends RefCounted

# ─────────────────────────────────────────
# 数据字段（全部嵌套，field 统一加在需要的位置）
# ─────────────────────────────────────────

var trigger: String = "TR02"          # 触发类型ID
var condition: Dictionary = {"type": "C01", "field": "", "value": 1, "counter_type": "", "op": ">="}  # 条件 + 字段 + 指示物
var action: Dictionary = {"type": "A01", "value": 1, "field": "", "counter_type": ""}  # 动作 + 数值 + 字段 + 指示物
var target: Dictionary = {"type": "T04", "field": ""}  # 目标 + 字段
var constraints: Array[String] = []   # 约束ID列表
var counter_type: String = ""         # 触发器指示物类型（TR16/TR17）
var threshold: int = 0               # 触发器阈值（TR17）

# ─────────────────────────────────────────
# 触发名称映射
# ─────────────────────────────────────────

static func _trigger_name(id: String) -> String:
	var m = {
		"TR01": "主动使用",
		"TR02": "入场",
		"TR03": "离场",
		"TR04": "攻击",
		"TR05": "被攻击",
		"TR06": "受伤",
		"TR07": "破坏",
		"TR08": "回合开始",
		"TR09": "回合结束",
		"TR10": "抽牌后",
		"TR11": "弃牌后",
		"TR12": "召唤成功",
		"TR13": "魔法发动",
		"TR14": "战斗开始",
		"TR15": "生命值变化",
		"TR16": "指示物变化时",
		"TR17": "指示物达到阈值",
		"TR18": "敌方发动效果"
	}
	return m.get(id, "???")


# ─────────────────────────────────────────
# 条件名称映射
# ─────────────────────────────────────────

static func _condition_name(id: String) -> String:
	var m = {
		"C01": "无条件",
		"C02": "生命值≥",
		"C03": "手牌数≥",
		"C04": "有字段",
		"C13": "指示物数量≥"
	}
	return m.get(id, "???")


# ─────────────────────────────────────────
# 动作名称映射
# ─────────────────────────────────────────

static func _action_name(id: String) -> String:
	var m = {
		"A01": "伤害",
		"A02": "恢复",
		"A03": "破坏",
		"A04": "除外",
		"A05": "抽牌",
		"A06": "弃牌",
		"A07": "召唤",
		"A08": "特殊召唤",
		"A09": "检索·字段",
		"A10": "洗回",
		"A11": "增减攻击",
		"A12": "增减生命上限",
		"A13": "增减速度",
		"A14": "赋予字段",
		"A15": "移除字段",
		"A16": "赋予种族",
		"A17": "复制效果",
		"A18": "无效化",
		"A24": "添加指示物",
		"A25": "移除指示物",
		"A26": "设定指示物"
	}
	return m.get(id, "???")


# ─────────────────────────────────────────
# 目标名称映射
# ─────────────────────────────────────────

static func _target_name(id: String) -> String:
	var m = {
		"T01": "自身",
		"T02": "敌方单体",
		"T03": "友方单体",
		"T04": "敌方全体",
		"T05": "友方全体",
		"T06": "随机敌方",
		"T07": "随机友方",
		"T08": "全场",
		"T09": "手牌",
		"T10": "墓地",
		"T11": "卡组",
		"T12": "指定位置",
		"T13": "场上指定字段",
		"T14": "除外区"
	}
	return m.get(id, "???")


# ─────────────────────────────────────────
# 约束名称映射
# ─────────────────────────────────────────

static func _constraint_name(id: String) -> String:
	var m = {
		"CO01": "一回合一次",
		"CO02": "一局一次",
		"CO03": "使用后破坏",
		"CO04": "使用后除外",
		"CO05": "消耗生命",
		"CO06": "弃手牌",
		"CO07": "消耗能量",
		"CO08": "仅己方回合",
		"CO09": "仅对方回合",
		"CO10": "需盖放",
		"CO11": "需满足条件",
		"CO12": "非永久",
		"CO13": "不可攻击",
		"CO14": "不可被攻击"
	}
	return m.get(id, "???")


# ─────────────────────────────────────────
# 动作是否有数值
# ─────────────────────────────────────────

static func action_has_value(id: String) -> bool:
	return id in ["A01", "A02", "A05", "A06", "A09", "A11", "A12", "A13", "A24", "A25", "A26"]


static func condition_has_field(id: String) -> bool:
	return id in ["C04", "C13"]


static func action_has_field(id: String) -> bool:
	return id in ["A09", "A14", "A15"]


static func target_has_field(id: String) -> bool:
	return id == "T13"


# ─────────────────────────────────────────
# 条件是否有指示物类型参数
# ─────────────────────────────────────────

static func condition_has_counter_type(id: String) -> bool:
	return id == "C13"


# ─────────────────────────────────────────
# 动作是否有指示物类型参数
# ─────────────────────────────────────────

static func action_has_counter_type(id: String) -> bool:
	return id in ["A24", "A25", "A26"]


# ─────────────────────────────────────────
# 触发器是否有指示物类型参数
# ─────────────────────────────────────────

static func trigger_has_counter_type(id: String) -> bool:
	return id in ["TR16", "TR17"]


# ─────────────────────────────────────────
# 触发器是否有阈值参数
# ─────────────────────────────────────────

static func trigger_has_threshold(id: String) -> bool:
	return id == "TR17"


# ─────────────────────────────────────────
# 短描述（触发 + 条件 + 动作 + 目标）
# 输出示例："入场 有字段[湖北] 伤害 2 → 敌方全体"
# ─────────────────────────────────────────

func get_short_description() -> String:
	var t = _trigger_name(trigger)
	var c_type = condition.get("type", "C01")
	var c_field = condition.get("field", "")
	var c_str = ""
	if c_type == "C04" and c_field != "":
		c_str = " 有字段[%s]" % c_field
	elif c_type == "C02":
		c_str = " 生命≥%d" % int(condition.get("value", 1))
	elif c_type == "C03":
		c_str = " 手牌≥%d" % int(condition.get("value", 1))
	elif c_type == "C13":
		var ct = condition.get("counter_type", "")
		var op = condition.get("op", ">=")
		var cv = int(condition.get("value", 0))
		c_str = " 指示物「%s」%s%d" % [ct, op, cv]

	var a_type = action.get("type", "A01")
	var a = _action_name(a_type)
	var v = int(action.get("value", 0))
	var a_str = " " + a
	if action_has_value(a_type):
		a_str += " " + str(v)
	var a_field = action.get("field", "")
	if action_has_field(a_type) and a_field != "":
		a_str += "[%s]" % a_field
	var a_ctr = action.get("counter_type", "")
	if action_has_counter_type(a_type) and a_ctr != "":
		a_str = a + "[%s]" % a_ctr
		if action_has_value(a_type):
			a_str += " " + str(v)

	var tg_type = target.get("type", "T04")
	var tg = _target_name(tg_type)
	var tg_field = target.get("field", "")
	var tg_str = ""
	if target_has_field(tg_type) and tg_field != "":
		tg_str = "[%s]" % tg_field
	elif tg_type != "T01":
		tg_str = " → " + tg
	else:
		tg_str = " → " + tg

	return "%s%s %s %s" % [t, c_str, a_str, tg_str]


# ─────────────────────────────────────────
# 完整描述（包含所有信息）
# 输出格式："触发入场，条件有字段[湖北]，动作伤害(2)，目标敌方全体"
# ─────────────────────────────────────────

func get_full_description() -> String:
	var parts: Array[String] = []

	# 触发
	parts.append("触发" + _trigger_name(trigger))

	# 条件
	var c_type = condition.get("type", "C01")
	var c_field = condition.get("field", "")
	match c_type:
		"C01":
			parts.append("条件无条件")
		"C02":
			parts.append("条件生命≥%d" % int(condition.get("value", 1)))
		"C03":
			parts.append("条件手牌≥%d" % int(condition.get("value", 1)))
		"C04":
			if c_field != "":
				parts.append("条件有字段[%s]" % c_field)
			else:
				parts.append("条件有字段")
		"C13":
			var ct = condition.get("counter_type", "")
			var op = condition.get("op", ">=")
			var cv = int(condition.get("value", 0))
			if ct != "":
				parts.append("条件指示物「%s」%s%d" % [ct, op, cv])
			else:
				parts.append("条件指示物数量比较")

	# 动作+数值+字段
	var a_type = action.get("type", "A01")
	var a = _action_name(a_type)
	var v = int(action.get("value", 0))
	var a_field = action.get("field", "")
	var a_ctr = action.get("counter_type", "")
	if action_has_counter_type(a_type):
		if a_ctr != "":
			parts.append("动作%s[%s]" % [a, a_ctr])
			if action_has_value(a_type):
				parts[-1] += "(%d)" % v
		else:
			parts.append("动作%s" % a)
	elif action_has_value(a_type):
		parts.append("动作%s(%d)" % [a, v])
		if action_has_field(a_type) and a_field != "":
			parts.append("字段%s" % a_field)
	elif action_has_field(a_type) and a_field != "":
		parts.append("动作" + a)
		parts.append("字段%s" % a_field)
	else:
		parts.append("动作" + a)

	# 目标+字段
	var tg_type = target.get("type", "T04")
	var tg_field = target.get("field", "")
	if target_has_field(tg_type) and tg_field != "":
		parts.append("目标场上[%s]的卡" % tg_field)
	else:
		parts.append("目标" + _target_name(tg_type))

	# 约束
	if constraints.size() > 0:
		var cons_list: Array[String] = []
		for c in constraints:
			cons_list.append(_constraint_name(c))
		parts.append("约束：" + "、".join(cons_list))

	return "，".join(parts)


# ─────────────────────────────────────────
# 从 Dictionary 构造（用于 JSON 加载）
# ─────────────────────────────────────────

func load_from_dict(d: Dictionary):
	trigger = d.get("trigger", "TR02")

	var cd = d.get("condition", {})
	condition = {
		"type": cd.get("type", "C01"),
		"field": cd.get("field", ""),
		"value": cd.get("value", 1),
		"counter_type": cd.get("counter_type", ""),
		"op": cd.get("op", ">=")
	}

	var act = d.get("action", {})
	action = {
		"type": act.get("type", "A01"),
		"value": act.get("value", 1),
		"field": act.get("field", ""),
		"counter_type": act.get("counter_type", "")
	}

	var tgt = d.get("target", {})
	target = {
		"type": tgt.get("type", "T04"),
		"field": tgt.get("field", "")
	}

	# 触发器参数（TR16/TR17）
	counter_type = d.get("counter_type", "")
	threshold = int(d.get("threshold", 0))

	constraints = []
	for c in d.get("constraints", []):
		constraints.append(str(c))


# ─────────────────────────────────────────
# 导出为 Dictionary（用于 JSON 保存）
# ─────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"trigger": trigger,
		"counter_type": counter_type,
		"threshold": threshold,
		"condition": condition,
		"action": action,
		"target": target,
		"constraints": constraints
	}
