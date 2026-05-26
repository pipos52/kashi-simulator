extends Control
func _ready():
	_init_ad()
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 1.0)
	add_theme_stylebox_override("panel", bg)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0; vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = 0; vbox.offset_top = 0; vbox.offset_right = 0; vbox.offset_bottom = 0
	vbox.alignment = VBoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	# 标题
	var title = Label.new()
	title.text = "卡师模拟器"
	title.add_theme_font_size_override("font_size", 150)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0; title.anchor_top = 0.0
	title.anchor_right = 1.0; title.anchor_bottom = 0.0
	title.offset_bottom = 280
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = 0
	vbox.add_child(title)

	# 弹性间距
	var spacer1 = Control.new()
	spacer1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer1)

	# ── 进入工坊 ──
	var city_btn = Button.new()
	city_btn.text = "🏙️ 进入工坊"
	city_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	city_btn.add_theme_font_size_override("font_size", 56)
	var citybs = StyleBoxFlat.new()
	citybs.bg_color = Color(0.3, 0.25, 0.5)
	citybs.corner_radius_top_left = 10; citybs.corner_radius_top_right = 10
	citybs.corner_radius_bottom_left = 10; citybs.corner_radius_bottom_right = 10
	city_btn.add_theme_stylebox_override("normal", citybs)
	city_btn.pressed.connect(_on_enter_city)
	vbox.add_child(city_btn)

	# 间距
	var gap3 = Control.new()
	gap3.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(gap3)

	# ── 退出游戏 ──
	var quit_btn = Button.new()
	quit_btn.text = "🚪 退出游戏"
	quit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit_btn.add_theme_font_size_override("font_size", 56)
	var qbs = StyleBoxFlat.new()
	qbs.bg_color = Color(0.55, 0.15, 0.15)
	qbs.corner_radius_top_left = 10; qbs.corner_radius_top_right = 10
	qbs.corner_radius_bottom_left = 10; qbs.corner_radius_bottom_right = 10
	quit_btn.add_theme_stylebox_override("normal", qbs)
	quit_btn.pressed.connect(_on_quit_game)
	vbox.add_child(quit_btn)

	# 弹性间距
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	# 版本号
	var ver = Label.new()
	ver.text = "v1.0"
	ver.add_theme_font_size_override("font_size", 48)
	ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ver.size_flags_vertical = 0
	ver.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(ver)


func _on_enter_city():
	get_tree().change_scene_to_file("res://scenes/world/city_map_scene.tscn")

func _on_quit_game():
	get_tree().quit()

# ── 独立广告插件初始化（后台自动初始化 + 预加载） ──
func _init_ad():
	var plugin = Engine.get_singleton("DirichletAd")
	if plugin == null:
		print("[Ad] 插件未加载（仅限 Android 构建）")
		return
	plugin.connect("ad_ready", _on_ad_ready)
	plugin.connect("ad_error", _on_ad_error)
	# 初始化：只存参数，后台自动执行
	plugin.initialize(1102672, "wR8y1YqK98zG8xk72n2S6WaQs3li7Rgxd8DkJpkrFuZM4HtrHuc4GqV4H1IHSeaf")
	plugin.setTestSpaceId(16)
	print("[Ad] 独立广告插件已启动")

func _on_ad_ready():
	print("[Ad] 广告预加载完成！")
	ToastManager.show("✅ 广告已就绪")

func _on_ad_error(msg: String):
	print("[Ad] 广告错误: ", msg)
	ToastManager.show("❌ " + msg)
