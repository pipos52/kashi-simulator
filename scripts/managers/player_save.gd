extends Node

const SAVE_PATH = "user://player_save.json"

var gold: int = 100
var total_cards_made: int = 0
var commissions_completed: int = 0

# ── 大地图存档 ──
var world_position: Vector2i = Vector2i(0, 0)   # 轴向坐标 (q, r)
var world_map_seed: int = 0
var action_points: int = 999
var max_action_points: int = 999
var visited_cells: Array = []                    # 已探索的格子坐标 [[q,r], ...]
var current_city_name: String = ""               # 若在城市内
var current_city_grid_pos: Vector2i = Vector2i(-1, -1)  # 当前城市在世界地图的格子坐标

# ── 爬塔进度 ──
var current_area_index: int = -1                 # 当前所在区域（0-3），-1=未选
var area_progress: Dictionary = {}              # {area_id(int): completed_node(int)} 区域节点进度

# 素材库存 { "M01": 3, "M02": 1, ... }
var material_inventory: Dictionary = {}

# 已制作的卡纸 { "white_card_id": properties_dict }
var owned_white_cards: Array = []

# 已制作的墨线 { "ink_id": properties_dict }
var owned_inks: Array = []

var owned_card_paths: Array = []

# 牌组（20张卡牌名称列表）
var deck_cards: Array = []

# 战斗/活动结束后返回目标场景（""=默认main）
var return_to_scene: String = ""

# UI覆盖层（如背包）打开时记录返回场景
var last_scene: String = ""

# ── 卡牌选择流程（牌组界面 → 卡库界面）──
var card_sel_return_scene: String = ""   # 选完后返回哪个场景
var card_sel_pending_slot: int = -1       # 正在填充的牌组槽位
var card_sel_excluded: Array = []          # 需要屏蔽的卡名（已在其他槽）

# 音量设置
var music_volume: float = 0.7

func _ready():
	load_data()

func load_data():
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var json_str = f.get_as_text()
	f.close()
	if json_str.is_empty():
		return
	var data = JSON.parse_string(json_str)
	if data is Dictionary:
		# 基础字段
		gold = data.get("gold", 100)
		total_cards_made = data.get("total_cards_made", 0)
		commissions_completed = data.get("commissions_completed", 0)

		# 大地图字段
		var wp = data.get("world_position", null)
		if wp is Array and wp.size() >= 2:
			world_position = Vector2i(wp[0] as int, wp[1] as int)
		else:
			world_position = Vector2i(0, 0)
		world_map_seed = data.get("world_map_seed", 0)
		action_points = data.get("action_points", 20)
		max_action_points = data.get("max_action_points", 999)
		var saved_visited = data.get("visited_cells", [])
		if saved_visited is Array:
			visited_cells = saved_visited
		current_city_name = data.get("current_city_name", "")
		var saved_city_pos = data.get("current_city_grid_pos", null)
		if saved_city_pos is Array and saved_city_pos.size() >= 2:
			current_city_grid_pos = Vector2i(saved_city_pos[0] as int, saved_city_pos[1] as int)
		else:
			current_city_grid_pos = Vector2i(-1, -1)

	# 爬塔进度
		current_area_index = data.get("current_area_index", -1)
		var saved_progress = data.get("area_progress", null)
		if saved_progress is Dictionary:
			area_progress = saved_progress
		else:
			area_progress = {}

		var saved_mats = data.get("material_inventory", null)
		if saved_mats is Dictionary:
			material_inventory = saved_mats
		else:
			material_inventory = {}
		
		var saved_wc = data.get("owned_white_cards", [])
		if saved_wc is Array:
			owned_white_cards = saved_wc
		
		var saved_ink = data.get("owned_inks", [])
		if saved_ink is Array:
			owned_inks = saved_ink
		
		owned_card_paths = []
		var saved_paths = data.get("owned_card_paths", [])
		if saved_paths is Array:
			for p in saved_paths:
				if p is String:
					owned_card_paths.append(p)

		var saved_deck = data.get("deck_cards", [])
		if saved_deck is Array:
			# 兼容旧存档：[["card1"], ["card2"]] → ["card1", "card2"]
			if saved_deck.size() > 0 and saved_deck[0] is Array:
				var flat: Array = []
				for inner in saved_deck:
					if inner is Array:
						for name in inner:
							if name is String:
								flat.append(name)
					elif inner is String:
						flat.append(inner)
				deck_cards = flat
			else:
				deck_cards = saved_deck

		last_scene = data.get("last_scene", "")
		music_volume = data.get("music_volume", 0.7)

func save_data():
	var data = {
		"gold": gold,
		"total_cards_made": total_cards_made,
		"commissions_completed": commissions_completed,
		"world_position": [world_position.x, world_position.y],
		"world_map_seed": world_map_seed,
		"action_points": action_points,
		"max_action_points": max_action_points,
		"visited_cells": visited_cells,
		"current_city_name": current_city_name,
		"current_city_grid_pos": [current_city_grid_pos.x, current_city_grid_pos.y],
		"current_area_index": current_area_index,
		"area_progress": area_progress,
		"material_inventory": material_inventory,
		"owned_white_cards": owned_white_cards,
		"owned_inks": owned_inks,
		"owned_card_paths": owned_card_paths,
		"deck_cards": deck_cards,
		"last_scene": last_scene,
		"music_volume": music_volume
	}
	var json_str = JSON.stringify(data)
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(json_str)
		f.close()

func add_gold(amount: int):
	gold += amount
	save_data()

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	save_data()
	return true

# ─────────────────────────────────────────
# 素材管理
# ─────────────────────────────────────────

func add_material(material_id: String, count: int = 1):
	var cur = material_inventory.get(material_id, 0)
	material_inventory[material_id] = cur + count
	save_data()

func get_material_count(material_id: String) -> int:
	return material_inventory.get(material_id, 0)

func has_materials(requirements: Array[String]) -> bool:
	for mid in requirements:
		if get_material_count(mid) <= 0:
			return false
	return true

func consume_materials(requirements: Array[String]) -> bool:
	# 检查是否足够
	for mid in requirements:
		if get_material_count(mid) < 1:
			return false
	# 消耗
	for mid in requirements:
		material_inventory[mid] = material_inventory[mid] - 1
		if material_inventory[mid] <= 0:
			material_inventory.erase(mid)
	save_data()
	return true

# ─────────────────────────────────────────
# 白卡管理
# ─────────────────────────────────────────

func add_white_card(props: Dictionary):
	owned_white_cards.append(props)
	save_data()

func get_white_card_count() -> int:
	return owned_white_cards.size()

# ─────────────────────────────────────────
# 墨线管理
# ─────────────────────────────────────────

func add_ink(props: Dictionary):
	owned_inks.append(props)
	save_data()

func get_ink_count() -> int:
	return owned_inks.size()

# ─────────────────────────────────────────
# 卡牌文件管理
# ─────────────────────────────────────────

func add_card_path(path: String):
	if path not in owned_card_paths:
		owned_card_paths.append(path)
		save_data()

func remove_card_path(path: String):
	if path in owned_card_paths:
		owned_card_paths.erase(path)
		save_data()

func get_all_card_files() -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open("user://")
	if dir and dir.dir_exists("cards"):
		dir = DirAccess.open("user://cards/")
		if dir:
			for f in dir.get_files():
				if f.ends_with(".json"):
					files.append("user://cards/" + f)
	return files

# ─────────────────────────────────────────
# 探险掉落（一次性获得多个素材）
# ─────────────────────────────────────────

func add_explore_drops(drops: Array[Dictionary]):
	for drop in drops:
		var mid = drop.get("id", "")
		var cnt = drop.get("count", 1)
		if mid != "":
			add_material(mid, cnt)
	save_data()

# ─────────────────────────────────────────
# 大地图游戏数据重置
# ─────────────────────────────────────────

func reset_game_data():
	gold = 100
	action_points = 999
	max_action_points = 999
	world_map_seed = randi() % 99999
	world_position = Vector2i(0, 0)
	visited_cells.clear()
	current_city_name = ""
	current_area_index = -1
	area_progress.clear()
	save_data()

# ── 爬塔进度 helpers ──
func get_area_node_complete(area_id: int) -> int:
	return area_progress.get(area_id, -1)

func advance_area_node(area_id: int, node: int):
	var cur = area_progress.get(area_id, -1)
	if node > cur:
		area_progress[area_id] = node
		save_data()

func spend_action_points(cost: int) -> bool:
	if action_points < cost:
		return false
	action_points -= cost
	save_data()
	return true

func restore_action_points(amount: int):
	action_points = mini(action_points + amount, max_action_points)
	save_data()

func mark_cell_visited(q: int, r: int):
	var key = "%d,%d" % [q, r]
	if key not in visited_cells:
		visited_cells.append(key)
		save_data()

func is_cell_visited(q: int, r: int) -> bool:
	return ("%d,%d" % [q, r]) in visited_cells
