extends Control

## Экран «Спорт»: лог тренировок, недельная цель, история.

@onready var back_btn: Button = %BackBtn
@onready var title_label: Label = %TitleLabel
@onready var content: VBoxContainer = %Content

const TRAINING_TYPES := [
	{"key": "strength", "name_key": "train_strength", "icon": "🏋️"},
	{"key": "cardio", "name_key": "train_cardio", "icon": "🏃"},
	{"key": "flex", "name_key": "train_flex", "icon": "🧘"},
	{"key": "other", "name_key": "train_other", "icon": "🎾"},
]

var _type_box: OptionButton
var _duration_spin: SpinBox
var _note_edit: LineEdit
var _goal_label: Label
var _list_box: VBoxContainer


func _ready() -> void:
	$Bg.visible = false
	var bg := preload("res://components/background.gd").new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_label.text = tr("menu_sport")
	_build()


func _build() -> void:
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer_top)

	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	content.add_child(card)

	vb.add_child(_title(tr("menu_sport")))

	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 10)
	var tl := Label.new()
	tl.text = tr("sport_type")
	tl.custom_minimum_size = Vector2(150, 0)
	trow.add_child(tl)
	_type_box = OptionButton.new()
	_type_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for t in TRAINING_TYPES:
		_type_box.add_item(tr(t["name_key"]))
	trow.add_child(_type_box)
	vb.add_child(trow)

	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 10)
	var dl := Label.new()
	dl.text = tr("sport_duration")
	dl.custom_minimum_size = Vector2(150, 0)
	drow.add_child(dl)
	_duration_spin = SpinBox.new()
	_duration_spin.min_value = 5
	_duration_spin.max_value = 600
	_duration_spin.step = 5
	_duration_spin.value = 45
	_duration_spin.suffix = " %s" % tr("min_unit")
	_duration_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drow.add_child(_duration_spin)
	vb.add_child(drow)

	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 10)
	var nl := Label.new()
	nl.text = tr("sport_note")
	nl.custom_minimum_size = Vector2(150, 0)
	nrow.add_child(nl)
	_note_edit = LineEdit.new()
	_note_edit.placeholder_text = tr("sport_note_placeholder")
	_note_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nrow.add_child(_note_edit)
	vb.add_child(nrow)

	var save := Button.new()
	save.text = tr("save")
	save.custom_minimum_size = Vector2(0, 48)
	save.pressed.connect(_on_save)
	vb.add_child(save)

	var arr2 := _make_card()
	var card2: PanelContainer = arr2[0]
	var vb2: VBoxContainer = arr2[1]
	content.add_child(card2)
	vb2.add_child(_title(tr("sport_goal")))
	_goal_label = Label.new()
	_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_label.add_theme_color_override("font_color", ThemeManager.text_secondary)
	vb2.add_child(_goal_label)

	var arr3 := _make_card()
	var card3: PanelContainer = arr3[0]
	var vb3: VBoxContainer = arr3[1]
	content.add_child(card3)
	vb3.add_child(_title(tr("sport_history")))
	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 8)
	vb3.add_child(_list_box)

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


func _type_meta(key: String) -> Dictionary:
	for t in TRAINING_TYPES:
		if t["key"] == key:
			return t
	return TRAINING_TYPES[TRAINING_TYPES.size() - 1]


func _on_save() -> void:
	var idx := _type_box.selected
	var type_key: String = TRAINING_TYPES[idx]["key"]
	var duration := int(_duration_spin.value)
	var note := _note_edit.text.strip_edges()
	DataManager.add_training(type_key, duration, note)
	_note_edit.text = ""


func _refresh() -> void:
	var today := TimeManager.today_str()
	var week_start := TimeManager.add_days(today, -6)
	var sessions := 0
	var minutes := 0
	var trainings: Array = []
	for t in DataManager.get_section("trainings"):
		if str(t.get("date", "")) >= week_start:
			sessions += 1
			minutes += int(t.get("duration", 0))
			trainings.append(t)
	trainings.sort_custom(func(a, b): return str(a["date"]) > str(b["date"]))

	var user_settings := DataManager.get_settings()
	_goal_label.text = tr("sport_goal_text").format({
		"sessions": sessions,
		"target_sessions": int(user_settings.get("sport_goal_sessions", 3)),
		"minutes": minutes,
		"target_minutes": int(user_settings.get("sport_goal_minutes", 240)),
	})

	for c in _list_box.get_children():
		c.queue_free()
	if trainings.is_empty():
		var l := Label.new()
		l.text = tr("no_data")
		l.add_theme_color_override("font_color", ThemeManager.text_secondary)
		_list_box.add_child(l)
		return
	for t in trainings:
		_list_box.add_child(_training_row(t))


func _training_row(t: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var id: String = t.get("id", "")
	var meta := _type_meta(str(t.get("type", "other")))

	var icon := Label.new()
	icon.text = meta["icon"]
	icon.add_theme_font_size_override("font_size", 22)
	h.add_child(icon)

	var name := Label.new()
	name.text = tr(meta["name_key"])
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(name)

	var dur := Label.new()
	dur.text = "%d %s" % [int(t.get("duration", 0)), tr("min_unit")]
	dur.add_theme_color_override("font_color", ThemeManager.text_secondary)
	h.add_child(dur)

	var date := Label.new()
	date.text = TimeManager.format_date_short(str(t.get("date", "")))
	date.add_theme_color_override("font_color", ThemeManager.text_secondary)
	h.add_child(date)

	var del := Button.new()
	del.text = "✕"
	del.custom_minimum_size = Vector2(40, 36)
	del.pressed.connect(_delete_training.bind(id))
	h.add_child(del)

	return h


func _delete_training(id: String) -> void:
	DataManager.remove_record("trainings", id)
