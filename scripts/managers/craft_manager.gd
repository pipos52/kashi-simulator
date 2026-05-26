# craft_manager.gd (autoload)
# 全局 crafting 流程管理器
# 管理7个阶段的流程跳转、数据传递、品质计算
# 使用方法：在任意脚本中调用 CraftManager.xxx()
extends Node

# ─────────────────────────────────────────
# 当前阶段
# ─────────────────────────────────────────
enum Phase {
	DESIGN      = 1,  # 阶段1：设计构思
	MATERIAL    = 2,  # 阶段2：材料准备
	BOTTOM_DRAW = 3,  # 阶段3：制作基底
	NODE_PLACE  = 4,  # 阶段4：构建能量节点
	LINE_DRAW   = 5,  # 阶段5：绘制能量回路
	ACTIVATE    = 6,  # 阶段6：封卡
	TEST        = 7   # 阶段7：测试
}

var current_phase: Phase = Phase.DESIGN

# ─────────────────────────────────────────
# 各阶段数据
# ─────────────────────────────────────────

var current_card: CardData = null  # 阶段1产出的卡牌数据
var selected_materials: Dictionary = {}  # 阶段2选择的材料
var phase_scores: Dictionary = {
	Phase.DESIGN:      0.0,
	Phase.MATERIAL:    0.0,
	Phase.BOTTOM_DRAW: 0.0,
	Phase.NODE_PLACE:  0.0,
	Phase.LINE_DRAW:   0.0,
	Phase.ACTIVATE:    0.0
}

# ─────────────────────────────────────────
# 计算最终品质
# ─────────────────────────────────────────

func calculate_final_quality() -> float:
	var q := 0.0
	q += phase_scores[Phase.DESIGN]      * 0.30
	q += phase_scores[Phase.MATERIAL]    * 0.20
	q += phase_scores[Phase.BOTTOM_DRAW] * 0.125
	q += phase_scores[Phase.NODE_PLACE]  * 0.125
	q += phase_scores[Phase.LINE_DRAW]  * 0.125
	q += phase_scores[Phase.ACTIVATE]     * 0.125
	return mini(100.0, q)  # 上限100


func quality_grade() -> String:
	var q = calculate_final_quality()
	if q >= 90:   return "完美"
	elif q >= 70: return "标准"
	elif q >= 50: return "瑕疵"
	else:         return "废品"


# ─────────────────────────────────────────
# 阶段导航
# ─────────────────────────────────────────

func goto_phase(phase: Phase):
	current_phase = phase
	match phase:
		Phase.DESIGN:
			get_tree().change_scene_to_file("res://scenes/crafter/crafter.tscn")
		Phase.MATERIAL:
			get_tree().change_scene_to_file("res://scenes/crafter/material.tscn")
		Phase.BOTTOM_DRAW:
			get_tree().change_scene_to_file("res://scenes/games/draw_bottom.tscn")
		Phase.NODE_PLACE:
			get_tree().change_scene_to_file("res://scenes/games/place_node.tscn")
		Phase.LINE_DRAW:
			get_tree().change_scene_to_file("res://scenes/games/draw_line.tscn")
		Phase.ACTIVATE:
			get_tree().change_scene_to_file("res://scenes/games/activate.tscn")
		Phase.TEST:
			get_tree().change_scene_to_file("res://scenes/crafter/test.tscn")


# ─────────────────────────────────────────
# 阶段1 → 2：设计完成，进入材料选择
# ─────────────────────────────────────────

func start_material():
	phase_scores[Phase.DESIGN] = _calc_design_score(current_card) if current_card else 80.0
	goto_phase(Phase.MATERIAL)


func set_card(card: CardData):
	current_card = card


func start_material_selection(card_data: CardData):
	current_card = card_data
	phase_scores[Phase.DESIGN] = _calc_design_score(card_data)
	goto_phase(Phase.MATERIAL)


func _calc_design_score(card: CardData) -> float:
	var score := 80.0
	if card.fields.size() > 0: score += 5.0
	if card.card_effects.size() > 0: score += 5.0
	if card.attack + card.health + card.speed > 0: score += 5.0
	if card.energy <= 15.0: score += 5.0
	return minf(100.0, score)


# ─────────────────────────────────────────
# 阶段2 → 3：材料完成，进入制作基底
# ─────────────────────────────────────────

func start_bottom_draw(materials: Dictionary):
	selected_materials = materials
	# 材料选择阶段评分 = 基于材料组合
	phase_scores[Phase.MATERIAL] = _calc_material_score(materials)
	goto_phase(Phase.BOTTOM_DRAW)


func _calc_material_score(mats: Dictionary) -> float:
	var score := 80.0
	var ink = mats.get("ink", "INK01")
	if ink == "INK02": score += 5.0
	elif ink == "INK03": score += 10.0
	if "AU01" in mats.get("aux", []): score += 5.0
	if "AU02" in mats.get("aux", []): score += 10.0
	return minf(100.0, score)


# ─────────────────────────────────────────
# 阶段3 → 4
# ─────────────────────────────────────────

func start_node_place(score: float):
	phase_scores[Phase.BOTTOM_DRAW] = score
	goto_phase(Phase.NODE_PLACE)


# ─────────────────────────────────────────
# 阶段4 → 5
# ─────────────────────────────────────────

func start_line_draw(score: float):
	phase_scores[Phase.NODE_PLACE] = score
	goto_phase(Phase.LINE_DRAW)


# ─────────────────────────────────────────
# 阶段5 → 6
# ─────────────────────────────────────────

func start_activate(score: float):
	phase_scores[Phase.LINE_DRAW] = score
	goto_phase(Phase.ACTIVATE)


# ─────────────────────────────────────────
# 阶段6 → 7
# ─────────────────────────────────────────

func start_test(score: float):
	phase_scores[Phase.ACTIVATE] = score
	goto_phase(Phase.TEST)


# ─────────────────────────────────────────
# 阶段7：保存或返回修改
# ─────────────────────────────────────────

func finish_and_save() -> bool:
	if not current_card:
		return false
	# 保存到 user://cards/
	var trimmed = current_card.name.replace("/", "_").replace("\\", "_").replace(".", "_")
	var timestamp = int(Time.get_unix_time_from_system())
	var path = "user://cards/" + trimmed + "_" + str(timestamp) + ".json"

	var dir = DirAccess.open("user://")
	if not dir:
		return false
	if not dir.dir_exists("cards"):
		dir.make_dir("cards")

	# 注入最终品质（quality_grade 已由 test.gd 通过材料计算写入 current_card）
	var final_data = current_card.to_dict()
	final_data["quality_score"] = calculate_final_quality()
	# 优先使用 current_card 中已计算的材料加成品质，否则fallback
	final_data["quality_grade"] = current_card.quality_grade if current_card.quality_grade != "" else quality_grade()
	final_data["materials"] = selected_materials

	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(final_data, "\t"))
		f.close()
		return true
	return false


func reset_crafting():
	current_card = null
	selected_materials = {}
	phase_scores = {
		Phase.DESIGN:      0.0,
		Phase.MATERIAL:    0.0,
		Phase.BOTTOM_DRAW: 0.0,
		Phase.NODE_PLACE:  0.0,
		Phase.LINE_DRAW:   0.0,
		Phase.ACTIVATE:    0.0
	}
	current_phase = Phase.DESIGN
	goto_phase(Phase.DESIGN)
