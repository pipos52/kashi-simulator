extends Node
class_name EffectExecutor

var battle  # BattleManager reference
var _counter_threshold_triggered: Dictionary = {}  # { "card_unique_id_counter_type": true }

# 原子纹路 → 事件字符串
static func get_trigger_event(trigger_id: String) -> String:
	match trigger_id:
		"TR01": return "active_use"
		"TR02": return "enter_field"
		"TR03": return "leave_field"
		"TR04": return "attack"
		"TR05": return "be_attacked"
		"TR06": return "destroy"
		"TR07": return "dead"
		"TR08": return "turn_start"
		"TR09": return "turn_end"
		"TR10": return "draw_card"
		"TR11": return "discard"
		"TR12": return "summon_success"
		"TR16": return "counter_changed"
		"TR17": return "counter_threshold"
		"TR18": return "enemy_effect_activated"
		_:
			return "unknown_" + trigger_id

# 执行单个动作
func execute_action(action_type: String, action_params: Dictionary, source: CardInstance, targets: Array[CardInstance]):
	# TR18：敌方发效果时触发（效果被实际执行时）
	_on_effect_activated(source, action_params)
	
	if targets.is_empty() and action_type != "A05" and action_type != "A07":
		return
	
	match action_type:
		"A01":  # 伤害
			var val = action_params.get("value", 0)
			for t in targets:
				if t != null and t.is_alive():
					var dead = t.take_damage(val)
					battle.emit_signal("log_message","%s 对 %s 造成 %d 点伤害" % [source.card_data.name, t.card_data.name, val])
					if dead:
						battle.destroy_card(t)
		
		"A02":  # 治疗
			var val = action_params.get("value", 0)
			for t in targets:
				if t != null:
					t.heal(val)
					battle.emit_signal("log_message","%s 恢复了 %s %d 点生命" % [source.card_data.name, t.card_data.name, val])
		
		"A03":  # 破坏
			for t in targets:
				if t != null:
					battle.emit_signal("log_message","%s 破坏了 %s" % [source.card_data.name, t.card_data.name])
					battle.destroy_card(t)
		
		"A04":  # 除外
			for t in targets:
				if t != null:
					battle.emit_signal("log_message","%s 除外了 %s" % [source.card_data.name, t.card_data.name])
					battle.exclude_card(t)
		
		"A05":  # 抽牌
			var val = action_params.get("value", 1)
			var side = battle.player if source.owner == 0 else battle.enemy
			for i in range(val):
				var drawn = side.draw_card()
				if drawn:
					var who = "玩家" if source.owner == 0 else "敌方"
					battle.emit_signal("log_message","%s 抽了 %s" % [who, drawn.card_data.name])
				else:
					var who2 = "玩家" if source.owner == 0 else "敌方"
					battle.emit_signal("log_message","%s 抽牌时牌堆为空" % who2)
			battle.update_ui()
		
		"A06":  # 弃牌
			var val = action_params.get("value", 1)
			var side = battle.player if source.owner == 0 else battle.enemy
			for i in range(mini(val, side.hand.size())):
				var card = side.hand[randi() % side.hand.size()]
				side.send_to_grave(card)
				battle.effect_executor.trigger_effects("discard", card)
			battle.emit_signal("log_message","%s 弃了 %d 张牌" % ["玩家" if source.owner == 0 else "敌方", val])
			battle.update_ui()
		
		"A07":  # 从手牌召唤（消耗能量）
			var target_data = action_params.get("card_data")
			if target_data:
				battle.emit_signal("log_message","%s 特殊召唤了 %s" % [source.card_data.name, target_data.name])
			battle.update_ui()
		
		"A08":  # 特殊召唤(夺取)
			for t in targets:
				if t == null or t.zone != "field":
					continue
				var enemy_side = battle.enemy if source.owner == 0 else battle.player
				var my_side = battle.player if source.owner == 0 else battle.enemy
				if my_side.field.size() >= 5:
					battle.emit_signal("log_message","己方场上已满，无法夺取 %s" % t.card_data.name)
					continue
				enemy_side.field.erase(t)
				t.owner = source.owner
				t.zone = "field"
				t.summon_sickness = false
				t.can_attack_this_turn = true
				my_side.field.append(t)
				battle.emit_signal("log_message","%s 夺取了 %s" % [source.card_data.name, t.card_data.name])
			battle.update_ui()
		
		"A09":  # 检索·字段 — 从目标区搜寻有指定字段的卡到手牌
			var field_name = action_params.get("field", "")
			if field_name == "":
				battle.emit_signal("log_message","检索失败：未指定字段名")
				return
			var target_type = action_params.get("target_type", "T11")
			var side = battle.player if source.owner == 0 else battle.enemy
			var pool: Array = []
			match target_type:
				"T11": pool = side.deck
				"T10": pool = side.graveyard
				"T14": pool = side.excluded
			var found: Array[CardInstance] = []
			for c in pool:
				if c.card_data.fields.has(field_name):
					found.append(c)
			if found.is_empty():
				battle.emit_signal("log_message","未在 %s 中找到含「%s」的卡" % [CardEffect._target_name(target_type), field_name])
			else:
				for c in found:
					pool.erase(c)
					c.zone = "hand"
					side.hand.append(c)
				battle.emit_signal("log_message","从 %s 检索到 %d 张「%s」卡" % [CardEffect._target_name(target_type), found.size(), field_name])
			battle.update_ui()
		
		
		"A11":  # 修改攻击力
			var val = action_params.get("value", 0)
			for t in targets:
				if t != null:
					t.modify_attack(val)
					battle.emit_signal("log_message","%s 的攻击力 %s %d" % [t.card_data.name, "+" if val > 0 else "", val])
		
		"A12":  # 修改生命值
			var val = action_params.get("value", 0)
			for t in targets:
				if t != null:
					t.modify_health(val)
					battle.emit_signal("log_message","%s 的生命值 %s %d" % [t.card_data.name, "+" if val > 0 else "", val])
		
		"A18":  # 无效化效果
			for t in targets:
				if t != null:
					t.modifiers["negated"] = true
					battle.emit_signal("log_message","%s 的效果被无效化" % t.card_data.name)

		"A17":  # 复制效果 — 复制目标的 effects 到自身
			for t in targets:
				if t == null:
					continue
				var copied = []
				for eff_data in t.card_data.card_effects:
					var copy = eff_data.duplicate(true)
					copied.append(copy)
				source.card_data.card_effects = copied
				battle.emit_signal("log_message","%s 复制了 %s 的效果" % [source.card_data.name, t.card_data.name])
			battle.update_ui()

		"A24":  # 添加指示物
			var counter_type = action_params.get("counter_type", "")
			var val = action_params.get("value", 1)
			for t in targets:
				if t != null and counter_type != "":
					var old = t.counters.get(counter_type, 0)
					t.counters[counter_type] = old + val
					battle.emit_signal("log_message","%s 给 %s 添加了 %d 个「%s」指示物" % [source.card_data.name, t.card_data.name, val, counter_type])
					battle.trigger_event("counter_changed", t, {"counter_type": counter_type, "old": old, "new": old + val, "source": source})
					_check_counter_threshold(t, counter_type, battle)

		"A25":  # 移除指示物
			var counter_type = action_params.get("counter_type", "")
			var val = action_params.get("value", 1)
			for t in targets:
				if t != null and counter_type != "":
					var old = t.counters.get(counter_type, 0)
					t.counters[counter_type] = maxi(0, old - val)
					battle.emit_signal("log_message","%s 从 %s 移除了 %d 个「%s」指示物" % [source.card_data.name, t.card_data.name, val, counter_type])
					battle.trigger_event("counter_changed", t, {"counter_type": counter_type, "old": old, "new": max(0, old - val), "source": source})
					_check_counter_threshold(t, counter_type, battle)

		"A26":  # 设定指示物
			var counter_type = action_params.get("counter_type", "")
			var val = action_params.get("value", 1)
			for t in targets:
				if t != null and counter_type != "":
					var old = t.counters.get(counter_type, 0)
					t.counters[counter_type] = val
					battle.emit_signal("log_message","%s 将 %s 的「%s」指示物设定为 %d" % [source.card_data.name, t.card_data.name, counter_type, val])
					battle.trigger_event("counter_changed", t, {"counter_type": counter_type, "old": old, "new": val, "source": source})
					_check_counter_threshold(t, counter_type, battle)

		_:
			battle.emit_signal("log_message","未知动作类型: %s" % action_type)

# 目标选择
func select_targets(target_spec: Dictionary, source: CardInstance) -> Array[CardInstance]:
	var target_type = target_spec.get("type", "T01")
	var results: Array[CardInstance] = []
	
	match target_type:
		"T01":  # 自己
			results = [source]
		"T02":  # 对方玩家（直接攻击）
			pass  # 返回空，由 battle 处理
		"T03":  # 己方单体
			var side = battle.player if source.owner == 0 else battle.enemy
			if not side.field.is_empty():
				results = [side.field[0]]
		"T04":  # 所有敌人
			var enemy_side = battle.enemy if source.owner == 0 else battle.player
			results = enemy_side.field.duplicate()
		"T05":  # 所有友方
			var friendly_side = battle.player if source.owner == 0 else battle.enemy
			results = friendly_side.field.duplicate()
		"T06":  # 随机敌人
			var enemy_side = battle.enemy if source.owner == 0 else battle.player
			if not enemy_side.field.is_empty():
				results = [enemy_side.field[randi() % enemy_side.field.size()]]
		"T07":  # 攻击力最低的敌人
			var enemy_side = battle.enemy if source.owner == 0 else battle.enemy
			if not enemy_side.field.is_empty():
				enemy_side.field.sort_custom(func(a, b): return a.current_attack < b.current_attack)
				results = [enemy_side.field[0]]
		"T08":  # 己方手牌
			var side = battle.player if source.owner == 0 else battle.enemy
			results = side.hand.duplicate()
		"T10":  # 墓地
			pass
		"T11":  # 卡组
			pass
		"T14":  # 除外区
			pass
		_:
			results = [source]
	
	return results

# 检查条件是否满足
func check_condition(condition: Dictionary, source: CardInstance, target: CardInstance = null) -> bool:
	if condition.is_empty():
		return true
	
	var cond_type = condition.get("type", "")
	
	match cond_type:
		"health_above":
			var threshold = condition.get("value", 0)
			if target != null:
				return target.current_health >= threshold
		"health_below":
			var threshold = condition.get("value", 0)
			if target != null:
				return target.current_health <= threshold
		"own_health_below":
			var threshold = condition.get("value", 0)
			var side = battle.player if source.owner == 0 else battle.enemy
			return side.health <= threshold
		"C13":  # 指示物数量比较
			var counter_type = condition.get("counter_type", "")
			var op = condition.get("op", ">=")
			var threshold = int(condition.get("value", 0))
			if counter_type == "":
				return false
			var current = target.counters.get(counter_type, 0) if target != null else source.counters.get(counter_type, 0)
			match op:
				">=": return current >= threshold
				"<=": return current <= threshold
				">":  return current > threshold
				"<":  return current < threshold
				"==": return current == threshold
			return false

	return true  # 无条件默认通过

# 触发效果
func trigger_effects(event_name: String, source: CardInstance = null, context: Dictionary = {}):
	if source == null or source.card_data == null:
		return

	# ── 1. 入场卡自身触发 TR02（入场 = 自己入场自己触发）──
	if event_name == "enter_field" and source.card_data.card_effects != null:
		for effect in source.card_data.card_effects:
			if effect.get("trigger", "") == "TR02":
				if check_constraints(effect.get("constraints", []), source):
					battle.emit_signal("log_message", "⚡ %s 入场效果触发！" % source.card_data.name)
					var tgt = select_targets(effect.get("target", {}), source)
					execute_action(effect.get("action", {}).get("type", ""), effect.get("action", {}), source, tgt)

	# ── 2. 其他卡监听 enter_field 的效果（TR02/TR12 等）──
	for card in battle.get_all_cards():
		if card == null or card.card_data == null:
			continue
		if card == source:
			continue
		if card.card_data.card_effects == null:
			continue
		for effect in card.card_data.card_effects:
			var trig = effect.get("trigger", "")
			if EffectExecutor.get_trigger_event(trig) != event_name:
				continue
			# TR16/TR17 需要检查 counter_type 是否匹配
			if trig in ["TR16", "TR17"]:
				var trig_counter_type = effect.get("counter_type", "")
				var ctx_counter_type = context.get("counter_type", "")
				if trig_counter_type != "" and ctx_counter_type != "" and trig_counter_type != ctx_counter_type:
					continue
				# TR17 额外检查阈值是否达到（在 _check_counter_threshold 里处理，这里仅过滤 counter_type）
			# 检查约束
			if check_constraints(effect.get("constraints", []), card):
				battle.emit_signal("log_message", "⚡ %s 的效果触发！" % card.card_data.name)
				var targets = select_targets(effect.get("target", {}), card)
				execute_action(effect.get("action", {}).get("type", ""), effect.get("action", {}), card, targets)

# 敌方发效果时触发（TR18「敌方发动效果」）
# 当敌方卡牌的效果动作被执行时，持有 TR18 的己方卡牌生效
# card: 发动效果的敌方卡牌，effect_data: 效果数据
func _on_effect_activated(card: CardInstance, effect_data: Dictionary = {}) -> void:
	if card == null or card.card_data == null:
		return
	if card.owner != 1:  # 仅敌方（owner==1）发动效果时触发
		return

	for tr18_card in battle.get_all_cards():
		if tr18_card == null or tr18_card.card_data == null:
			continue
		if tr18_card == card:  # 跳过自身（施放方不触发自己的 TR18）
			continue
		if tr18_card.card_data.card_effects == null:
			continue
		for tr18_eff in tr18_card.card_data.card_effects:
			if tr18_eff.get("trigger", "") != "TR18":
				continue
			if check_constraints(tr18_eff.get("constraints", []), tr18_card):
				var tgts = select_targets(tr18_eff.get("target", {}), tr18_card)
				execute_action(tr18_eff.get("action", {}).get("type", ""), tr18_eff.get("action", {}), tr18_card, tgts)

func check_constraints(constraints: Array, card: CardInstance) -> bool:
	for c in constraints:
		match c:
			"CO01":  # 一回合一次
				if card.used_constraints.has("CO01"):
					return false
			"CO02":  # 场上才能用
				if card.zone != "field":
					return false
			"CO03":  # 手牌才能用
				if card.zone != "hand":
					return false
	# 记录已用
	for c in constraints:
		if not card.used_constraints.has(c):
			card.used_constraints[c] = 1
			break
	return true

# 检查指示物是否达到阈值（TR17）
func _check_counter_threshold(card: CardInstance, counter_type: String, battle) -> void:
	var key = str(card.unique_id) + "_" + counter_type
	# 遍历所有卡牌的 TR17 效果
	for source_card in battle.get_all_cards():
		if source_card == null or source_card.card_data == null:
			continue
		if source_card.card_data.card_effects == null:
			continue
		for effect in source_card.card_data.card_effects:
			var trig = effect.get("trigger", "")
			if trig == "TR17":
				var trig_counter_type = effect.get("counter_type", "")
				var threshold = int(effect.get("threshold", 0))
				if trig_counter_type == counter_type:
					var trig_key = str(card.unique_id) + "_" + counter_type + "_" + str(threshold)
					var current = card.counters.get(counter_type, 0)
					# 首次达到或超过阈值时触发（未触发过才触发）
					if current >= threshold and not _counter_threshold_triggered.has(trig_key):
						_counter_threshold_triggered[trig_key] = true
						var targets = select_targets(effect.get("target", {}), source_card)
						execute_action(effect.get("action", {}).get("type", ""), effect.get("action", {}), source_card, targets)
						battle.emit_signal("log_message", "「%s」的「%s」指示物达到 %d，触发 %s" % [card.card_data.name, counter_type, threshold, source_card.card_data.name])

# ─── 回合阶段触发 ──────────────────────────────
# 专门处理 TR08「回合开始」：仅指定方的场上卡触发自己的 TR08
func trigger_side_turn_start(side: BattleSide):
	for card in side.field:
		if card == null or card.card_data == null:
			continue
		if card.card_data.card_effects == null:
			continue
		for effect in card.card_data.card_effects:
			if effect.get("trigger", "") != "TR08":
				continue
			if check_constraints(effect.get("constraints", []), card):
				var targets = select_targets(effect.get("target", {}), card)
				execute_action(effect.get("action", {}).get("type", ""), effect.get("action", {}), card, targets)

# 专门处理 TR09「回合结束」：仅指定方的场上卡触发自己的 TR09
func trigger_side_turn_end(side: BattleSide):
	for card in side.field:
		if card == null or card.card_data == null:
			continue
		if card.card_data.card_effects == null:
			continue
		for effect in card.card_data.card_effects:
			if effect.get("trigger", "") != "TR09":
				continue
			if check_constraints(effect.get("constraints", []), card):
				var targets = select_targets(effect.get("target", {}), card)
				execute_action(effect.get("action", {}).get("type", ""), effect.get("action", {}), card, targets)
