extends Control

## Экран «Статистика»: графики сна, энергии/настроения, игр vs спорта и калорий.

const Chart := preload("res://components/chart.gd")

const RANGES := [7, 30]

@onready var back_btn: Button = %BackBtn
@onready var title_label: Label = %TitleLabel
@onready var content: VBoxContainer = %Content

var _range := 7
var _charts_box: VBoxContainer


func _ready() -> void:
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_label.text = tr("menu_stats")
	_build()


func _build() -> void:
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer_top)

	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	content.add_child(card)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	for r in RANGES:
		var b := Button.new()
		b.text = tr("days_%d" % r)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.button_pressed = r == _range
		b.pressed.connect(_set_range.bind(r))
		hbox.add_child(b)
	vb.add_child(hbox)

	_charts_box = VBoxContainer.new()
	_charts_box.add_theme_constant_override("separation", 12)
	content.add_child(_charts_box)

	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 16)
	content.add_child(spacer_bottom)

	_build_charts()


func _make_card() -> Array:
	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)
	card.add_child(margin)
	return [card, vb]


func _title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color("8b949e"))
	return l


func _set_range(r: int) -> void:
	if r == _range:
		return
	_range = r
	for c in _charts_box.get_children():
		c.queue_free()
	_build_charts()


func _days() -> Array:
	var today := TimeManager.today_str()
	var out := []
	for i in range(_range - 1, -1, -1):
		out.append(TimeManager.add_days(today, -i))
	return out


func _build_charts() -> void:
	var days := _days()
	var labels: Array = []
	for d in days:
		var parts := d.split("-")
		labels.append(str(int(parts[2])))

	# Сон
	var sleep_values: Array = []
	var sleep_sum := 0.0
	for d in days:
		var h := DataManager.day_summary(d).sleep_hours
		sleep_values.append(h)
		sleep_sum += h
	_charts_box.add_child(_chart_card(
		tr("chart_sleep"),
		[{"name": tr("chart_sleep"), "color": Color("a371f7"), "values": sleep_values}],
		labels,
		false,
		tr("week_avg").format({"v": "%.1f" % (sleep_sum / days.size())})
	))

	# Энергия и настроение
	var energy_values: Array = []
	var mood_values: Array = []
	for d in days:
		var s := DataManager.day_summary(d)
		energy_values.append(float(s.energy) if s.has_checkin else 0.0)
		mood_values.append(float(s.mood) if s.has_checkin else 0.0)
	_charts_box.add_child(_chart_card(
		tr("chart_mood"),
		[
			{"name": tr("chart_energy"), "color": Color("58a6ff"), "values": energy_values},
			{"name": tr("chart_mood_label"), "color": Color("f778ba"), "values": mood_values},
		],
		labels,
		true,
		""
	))

	# Игры vs спорт
	var game_values: Array = []
	var sport_values: Array = []
	for d in days:
		var s := DataManager.day_summary(d)
		game_values.append(float(s.game_min))
		sport_values.append(float(s.sport_min))
	_charts_box.add_child(_chart_card(
		tr("chart_activity"),
		[
			{"name": tr("chart_game"), "color": Color("f778ba"), "values": game_values},
			{"name": tr("chart_sport"), "color": Color("4cc38a"), "values": sport_values},
		],
		labels,
		false,
		""
	))

	# Калории
	var kcal_values: Array = []
	for d in days:
		kcal_values.append(DataManager.day_summary(d).calories)
	_charts_box.add_child(_chart_card(
		tr("chart_calories"),
		[{"name": tr("chart_calories"), "color": Color("e3b341"), "values": kcal_values}],
		labels,
		false,
		""
	))


func _chart_card(title: String, series: Array, labels: Array, lines: bool, subtitle: String) -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(_title(title))
	if not subtitle.is_empty():
		var sub := Label.new()
		sub.text = subtitle
		sub.add_theme_color_override("font_color", Color("8b949e"))
		head.add_child(sub)
	vb.add_child(head)
	var chart := Chart.new()
	chart.custom_minimum_size = Vector2(0, 160)
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(chart)
	chart.set_data(series, labels, lines)
	return card
