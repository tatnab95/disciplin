extends Control

## Дашборд «Сегодня»: score дня, рекомендации, текущий слот расписания,
## таймеры активностей и прогресс дня.

const ScoreRing := preload("res://components/score_ring.gd")

const ACTIVITIES := {
	"game": {"icon": "🎮", "name_key": "activity_game"},
	"sport": {"icon": "🏋️", "name_key": "activity_sport"},
	"study": {"icon": "📚", "name_key": "activity_study"},
	"work": {"icon": "💼", "name_key": "activity_work"},
	"rest": {"icon": "☕", "name_key": "activity_rest"},
}

const REC_STYLE := {
	"checkin": {"icon": "⚡", "color": Color("58a6ff")},
	"sleep": {"icon": "😴", "color": Color("a371f7")},
	"rest": {"icon": "☕", "color": Color("d29922")},
	"game": {"icon": "🎮", "color": Color("f778ba")},
	"sport": {"icon": "🏋️", "color": Color("4cc38a")},
	"food": {"icon": "🍎", "color": Color("e3b341")},
}

@onready var date_label: Label = %DateLabel
@onready var menu_btn: Button = %MenuBtn
@onready var content: VBoxContainer = %Content

var _score_ring: Node
var _score_total_label: Label
var _parts_label: Label
var _rec_box: VBoxContainer
var _schedule_label: Label
var _progress_box: VBoxContainer
var _timer_buttons: Dictionary = {}


func _ready() -> void:
	$Bg.visible = false
	var bg := preload("res://components/background.gd").new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)
	DataManager.data_changed.connect(_refresh)
	menu_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_build_all()


func _process(_delta: float) -> void:
	for type in _timer_buttons:
		if ActivityTracker.is_running(type):
			var b: Button = _timer_buttons[type]
			b.text = _timer_text(type)


func _build_all() -> void:
	content.add_child(_hero_card())
	content.add_child(_timers_card())
	content.add_child(_progress_card())
	content.add_child(_focus_card())
	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 16)
	content.add_child(spacer_bottom)
	_refresh()


func _make_card() -> Array:
	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)
	card.add_child(margin)
	return [card, vb]


func _title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", ThemeManager.text_secondary)
	return l


func _hero_card() -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	content.add_child(card)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)

	var ring := ScoreRing.new()
	ring.custom_minimum_size = Vector2(88, 88)
	hbox.add_child(ring)
	_score_ring = ring

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var caption := Label.new()
	caption.text = tr("score")
	caption.add_theme_color_override("font_color", ThemeManager.text_secondary)
	col.add_child(caption)

	_score_total_label = Label.new()
	_score_total_label.add_theme_font_size_override("font_size", 30)
	col.add_child(_score_total_label)

	_parts_label = Label.new()
	_parts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_parts_label.add_theme_color_override("font_color", ThemeManager.text_secondary)
	col.add_child(_parts_label)

	hbox.add_child(col)
	vb.add_child(hbox)
	return card


func _timers_card() -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	content.add_child(card)

	vb.add_child(_title(tr("activity_timers")))
	var grid := GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation", 8)
	for type in ACTIVITIES:
		var meta: Dictionary = ACTIVITIES[type]
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 56)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = _timer_text(type)
		b.pressed.connect(_on_timer_pressed.bind(type))
		grid.add_child(b)
		_timer_buttons[type] = b
	vb.add_child(grid)
	return card


func _progress_card() -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	content.add_child(card)
	vb.add_child(_title(tr("today_progress")))
	_progress_box = VBoxContainer.new()
	_progress_box.add_theme_constant_override("separation", 8)
	vb.add_child(_progress_box)
	return card


func _focus_card() -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	content.add_child(card)
	vb.add_child(_title(tr("now_doing")))
	_schedule_label = Label.new()
	_schedule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_schedule_label)
	_rec_box = VBoxContainer.new()
	_rec_box.add_theme_constant_override("separation", 8)
	vb.add_child(_rec_box)
	return card


func _refresh() -> void:
	var today := TimeManager.today_str()
	date_label.text = "%s · %s" % [tr("today"), TimeManager.format_date_short(today)]

	var res := Recommender.compute_today_score()
	var total: int = res["total"]
	var parts: Dictionary = res["parts"]
	_score_ring.set("value", float(total))
	_score_total_label.text = "%d / 100" % total
	var lines := PackedStringArray()
	if parts.has("sleep"):
		lines.append("😴 %d" % int(parts["sleep"]))
	if parts.has("checkin"):
		lines.append("⚡ %d" % int(parts["checkin"]))
	if parts.has("food"):
		lines.append("🍎 %d" % int(parts["food"]))
	if parts.has("sport"):
		lines.append("🏋️ %d" % int(parts["sport"]))
	if parts.has("game"):
		lines.append("🎮 %d" % int(parts["game"]))
	if parts.has("habits"):
		lines.append("✅ %d" % int(parts["habits"]))
	if not lines.is_empty():
		_parts_label.text = " · ".join(lines)
	else:
		_parts_label.text = tr("no_recommendations")

	var slot := TimeManager.current_slot(DataManager.get_section("schedule"))
	var cur: Dictionary = slot["current"]
	var nxt: Dictionary = slot["next"]
	if not cur.is_empty():
		_schedule_label.text = "%s — %s" % [tr(String(cur.get("name_key", ""))), cur.get("time", "")]
		_schedule_label.add_theme_color_override("font_color", ThemeManager.accent)
		if not nxt.is_empty():
			_schedule_label.text += "\n%s — %s" % [tr(String(nxt.get("name_key", ""))), nxt.get("time", "")]
	else:
		_schedule_label.text = tr("free_time")
		_schedule_label.add_theme_color_override("font_color", ThemeManager.text_secondary)

	for c in _rec_box.get_children():
		c.queue_free()
	var recs := Recommender.get_recommendations()
	if recs.is_empty():
		var l := Label.new()
		l.text = tr("no_recommendations")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_color_override("font_color", ThemeManager.accent)
		_rec_box.add_child(l)
	else:
		for rec in recs:
			_rec_box.add_child(_rec_row(rec))

	_update_progress(today)
	for type in _timer_buttons:
		_update_timer_button(type)


func _rec_row(rec: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var style: Dictionary = REC_STYLE.get(rec["category"], REC_STYLE["checkin"])
	var icon := Label.new()
	icon.text = style["icon"]
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", style["color"])
	h.add_child(icon)
	var l := Label.new()
	l.text = str(rec["text"])
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h


func _update_progress(today: String) -> void:
	for c in _progress_box.get_children():
		c.queue_free()
	var s := DataManager.day_summary(today)
	var user_settings := DataManager.get_settings()
	var target_hours := float(user_settings.get("sleep_target_hours", 8.0))
	var game_limit := int(user_settings.get("game_limit_minutes", 120))
	_add_progress_row(tr("progress_sleep"), s.sleep_hours, target_hours, "%.1f %s" % [s.sleep_hours, tr("h_unit")])
	_add_progress_row(tr("progress_game"), float(s.game_min), float(game_limit), "%d %s" % [s.game_min, tr("min_unit")])
	_add_progress_row(tr("progress_sport"), float(s.sport_min), 60.0, "%d %s" % [s.sport_min, tr("min_unit")])
	_add_progress_row(tr("progress_food"), s.protein, 80.0, "%.0f г" % s.protein)
	if s.habits_total > 0:
		_add_progress_row(tr("progress_habits"), float(s.habits_done), float(s.habits_total), "%d / %d" % [s.habits_done, s.habits_total])


func _add_progress_row(title: String, value: float, max_v: float, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(110, 0)
	row.add_child(l)

	var bar := ProgressBar.new()
	bar.max_value = maxi(1, int(max_v))
	bar.value = clampf(value, 0.0, max_v)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	row.add_child(bar)

	var v := Label.new()
	v.text = text
	v.add_theme_color_override("font_color", ThemeManager.text_secondary)
	row.add_child(v)
	_progress_box.add_child(row)


func _timer_text(type: String) -> String:
	var meta: Dictionary = ACTIVITIES[type]
	var secs := ActivityTracker.running_seconds(type)
	return "%s %s\n%s" % [meta["icon"], tr(meta["name_key"]), _fmt_secs(secs)]


func _fmt_secs(secs: int) -> String:
	if secs <= 0:
		return "--:--"
	var h := secs / 3600
	var m := secs % 3600 / 60
	var s := secs % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s]
	return "%02d:%02d" % [m, s]


func _on_timer_pressed(type: String) -> void:
	ActivityTracker.toggle(type)
	_update_timer_button(type)


func _update_timer_button(type: String) -> void:
	if not _timer_buttons.has(type):
		return
	var b: Button = _timer_buttons[type]
	b.text = _timer_text(type)
	if ActivityTracker.is_running(type):
		b.add_theme_color_override("font_color", ThemeManager.accent)
	else:
		b.remove_theme_color_override("font_color")
