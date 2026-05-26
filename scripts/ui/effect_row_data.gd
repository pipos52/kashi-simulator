# effect_row_data.gd
# EffectRow 的数据结构（纯数据类）
extends Resource

var trigger: String = "TR02"
var counter_type: String = ""
var threshold: int = 5
var condition: Dictionary = {"type": "C01", "field": "", "value": 1, "counter_type": "", "op": ">="}
var action: Dictionary = {"type": "A01", "value": 2, "field": "", "counter_type": ""}
var target: Dictionary = {"type": "T04", "field": ""}
var constraints: Array = []

func to_dict() -> Dictionary:
	return {
		"trigger": trigger,
		"counter_type": counter_type,
		"threshold": threshold,
		"condition": condition.duplicate(true),
		"action": action.duplicate(true),
		"target": target.duplicate(true),
		"constraints": constraints.duplicate()
	}

func from_dict(d: Dictionary):
	trigger = d.get("trigger", "TR02")
	counter_type = d.get("counter_type", "")
	threshold = d.get("threshold", 5)
	condition = d.get("condition", {"type": "C01", "field": "", "value": 1, "counter_type": "", "op": ">="})
	action = d.get("action", {"type": "A01", "value": 2, "field": "", "counter_type": ""})
	target = d.get("target", {"type": "T04", "field": ""})
	constraints = d.get("constraints", []).duplicate()
