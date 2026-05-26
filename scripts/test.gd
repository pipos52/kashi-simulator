# test.gd — 阶段7：测试（显示结果）
extends Control

func _enter_tree():
	_build()

func _build():
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.anchor_left = 0.0; bg.anchor_top = 0.0; bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0; vbox.anchor_top = 0.0; vbox.anchor_right = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = 0; vbox.offset_top = 0; vbox.offset_right = 0; vbox.offset_bottom = 0
	add_child(vbox)

	vbox.add_child(_make_nav("🧪 测试结果"))
	vbox.add_child(HSeparator.new())

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)

	# 品质总评
	var q = CraftManager.calculate_final_quality()
	var grade = CraftManager.quality_grade()
	var grade_color = Color(0.3, 0.85, 0.3)
	if grade == "标准":   grade_color = Color(0.3, 0.7, 1.0)
	elif grade == "瑕疵": grade_color = Color(1.0, 0.7, 0.2)
	elif grade == "废品": grade_color = Color(1.0, 0.3, 0.3)

	var q_panel = PanelContainer.new()
	q_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var qs = StyleBoxFlat.new()
	qs.bg_color = Color(0.12, 0.14, 0.22)
	qs.border_width_left = 3; qs.border_width_right = 3
	qs.border_width_top = 3; qs.border_width_bottom = 3
	qs.border_color = grade_color
	qs.corner_radius_top_left = 12; qs.corner_radius_top_right = 12
	qs.corner_radius_bottom_left = 12; qs.corner_radius_bottom_right = 12
	qs.content_margin_left = 20; qs.content_margin_right = 20
	qs.content_margin_top = 20; qs.content_margin_bottom = 20
	q_panel.add_theme_stylebox_override("panel", qs)
	content.add_child(q_panel)

	var q_vbox = VBoxContainer.new()
	q_panel.add_child(q_vbox)

	var grade_lbl = Label.new()
	grade_lbl.text = "【%s】品质" % grade
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_lbl.add_theme_font_size_override("font_size", 64)
	grade_lbl.add_theme_color_override("font_color", grade_color)
	q_vbox.add_child(grade_lbl)

	var score_lbl = Label.new()
	score_lbl.text = "%.1f%%" % q
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_size_override("font_size", 96)
	score_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	q_vbox.add_child(score_lbl)

	# 各阶段得分
	var phases = [
		[CraftManager.Phase.DESIGN, "阶段1 设计", 0.30],
		[CraftManager.Phase.MATERIAL, "阶段2 材料", 0.20],
		[CraftManager.Phase.BOTTOM_DRAW, "阶段3 基底", 0.125],
		[CraftManager.Phase.NODE_PLACE, "阶段4 节点", 0.125],
		[CraftManager.Phase.LINE_DRAW, "阶段5 回路", 0.125],
		[CraftManager.Phase.ACTIVATE, "阶段6 封卡", 0.125]
	]
	for ph in phases:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(row)
		var lbl = Label.new()
		lbl.text = (ph[1] as String)
		lbl.add_theme_font_size_override("font_size", 34)
		lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
		row.add_child(lbl)
		var score = Label.new()
		score.text = "%.0f%%" % (CraftManager.phase_scores[ph[0]] as float)
		score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score.add_theme_font_size_override("font_size", 34)
		score.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		row.add_child(score)

	# 卡牌效果列表
	if CraftManager.current_card:
		var card = CraftManager.current_card
		var eff_title = Label.new()
		eff_title.text = "📋 卡牌效果"
		eff_title.add_theme_font_size_override("font_size", 40)
		eff_title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
		content.add_child(eff_title)

		var card_lbl = Label.new()
		card_lbl.text = card.get_effects_description()
		card_lbl.add_theme_font_size_override("font_size", 32)
		card_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.6))
		card_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(card_lbl)

	vbox.add_child(HSeparator.new())

	# 底部按钮
	var bottom = HBoxContainer.new()
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(bottom)

	var tweak_btn = Button.new()
	tweak_btn.text = "✏️ 微调"
	tweak_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tweak_btn.custom_minimum_size = Vector2(0, 70)
	tweak_btn.add_theme_font_size_override("font_size", 34)
	tweak_btn.pressed.connect(_on_tweak)
	bottom.add_child(tweak_btn)

	var save_btn = Button.new()
	save_btn.text = "💾 保存"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.custom_minimum_size = Vector2(0, 70)
	save_btn.add_theme_font_size_override("font_size", 34)
	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.2, 0.5, 0.85)
	ns.corner_radius_top_left = 8; ns.corner_radius_top_right = 8
	ns.corner_radius_bottom_left = 8; ns.corner_radius_bottom_right = 8
	save_btn.add_theme_stylebox_override("normal", ns)
	save_btn.pressed.connect(_on_save)
	bottom.add_child(save_btn)

func _make_nav(title: String) -> HBoxContainer:
	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.size_flags_vertical = 0
	nav.custom_minimum_size = Vector2(0, 70)
	var back = Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(70, 70)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func(): CraftManager.goto_phase(CraftManager.Phase.ACTIVATE))
	nav.add_child(back)
	var lbl = Label.new()
	lbl.text = title
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	lbl.add_theme_font_size_override("font_size", 48)
	nav.add_child(lbl)
	var spacer = Control.new(); spacer.custom_minimum_size = Vector2(70, 0); nav.add_child(spacer)
	return nav

func _on_tweak():
	CraftManager.goto_phase(CraftManager.Phase.DESIGN)

func _on_save():
	# ── 应用材料对成品卡牌属性的影响 ──
	if CraftManager.current_card and not CraftManager.selected_materials.is_empty():
		var mats = CraftManager.selected_materials
		var quality_score = CraftManager.calculate_final_quality()

		# 1. 墨线效率（从玩家拥有的墨线中查找）
		var ink_props := {"efficiency": 0.3}  # 默认效率
		var ink_id = mats.get("ink", "INK00")
		if ink_id != "INK00" and ink_id != null:
			for ik in PlayerSave.owned_inks:
				if ik.get("id", "") == ink_id:
					ink_props["efficiency"] = ik.get("efficiency", 0.3)
					break

		# 2. 白卡能量上限（从预定义或玩家白卡中查找）
		var paper_id = mats.get("paper", "PG00")
		var energy_cap := 3.0
		var quality_cap := 0.5
		var paper_caps := {
			"PG01": {"energy_cap": 5.0, "quality_cap": 0.6},
			"PG02": {"energy_cap": 7.0, "quality_cap": 0.7},
			"PG03": {"energy_cap": 9.0, "quality_cap": 0.8}
		}
		if paper_caps.has(paper_id):
			energy_cap = paper_caps[paper_id]["energy_cap"]
			quality_cap = paper_caps[paper_id]["quality_cap"]
		else:
			# 尝试从玩家白卡中查找
			for wc in PlayerSave.owned_white_cards:
				if wc.get("id", "") == paper_id:
					energy_cap = wc.get("energy_cap", energy_cap)
					quality_cap = wc.get("quality_cap", quality_cap)
					break

		# 3. 成品卡牌最终属性计算
		var white_card := {
			"energy_cap": energy_cap,
			"quality_cap": quality_cap
		}
		var core_id = mats.get("core", "EC04")
		var final_props = MaterialData.calc_final_card_properties(
			white_card, ink_props, core_id, quality_score
		)

		# 4. 将计算结果写入 current_card
		CraftManager.current_card.energy = final_props["final_energy"]
		CraftManager.current_card.quality_grade = final_props["quality_grade"]

	# ── 保存卡牌 ──
	var ok = CraftManager.finish_and_save()
	if ok:
		var toast = Label.new()
		toast.text = "✅ 保存成功！"
		toast.z_index = 300
		toast.anchor_left = 0.5; toast.anchor_right = 0.5
		toast.anchor_top = 0.5; toast.anchor_bottom = 0.5
		toast.offset_left = -300; toast.offset_right = 300
		toast.offset_top = -40; toast.offset_bottom = 40
		toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		toast.add_theme_font_size_override("font_size", 40)
		toast.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		add_child(toast)
		await get_tree().create_timer(2.0).timeout
		if is_inside_tree():
			toast.queue_free()
		CraftManager.reset_crafting()
		if is_inside_tree():
			get_tree().change_scene_to_file("res://scenes/main.tscn")
