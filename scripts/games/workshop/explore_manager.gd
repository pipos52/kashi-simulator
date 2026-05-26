extends Node

# 当前选择的区域 index: 0-3
var selected_area_index: int = -1

# 探险区域定义
const AREAS: Array[Dictionary] = [
	{"name": "火焰森林", "level": 1, "desc": "火系素材采集地"},
	{"name": "冰霜洞穴", "level": 1, "desc": "水系素材采集地"},
	{"name": "雷光高地", "level": 2, "desc": "雷系素材采集地"},
	{"name": "神秘遗迹", "level": 3, "desc": "稀有素材采集地"}
]

# 战斗结果和掉落
var last_drops: Array[Dictionary] = []
var last_battle_won: bool = false

func reset():
	selected_area_index = -1
	last_drops = []
	last_battle_won = false

func get_current_area() -> Dictionary:
	if selected_area_index >= 0 and selected_area_index < AREAS.size():
		return AREAS[selected_area_index]
	return {}

func set_area_drops(drops: Array[Dictionary]):
	last_drops = drops

func get_area_level() -> int:
	var area = get_current_area()
	return area.get("level", 1)
