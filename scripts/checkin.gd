extends Control

## Экран «Чек-ин»: энергия, усталость, адекватность/настроение (1–10).

@onready var back_btn: Button = %BackBtn
@onready var title_label: Label = %TitleLabel
@onready var content: VBoxContainer = %Content

const FIELDS := [
	{"key": "energy", "label_key": "checkin_energy", "emojis": {"high": "⚡", "mid": "🔋", "low": "🪫"}},
	{"key": "fatigue", "label_key": "checkin_fatigue", "emojis": {"high": "🥱", "mid": "😪", "low": "🙂"}},
	{"key": "mood", "label_key": "checkin_mood", "emojis": {"high": "😃", "mid": "🙂", "low": "😐"}},
]

var _sliders: Dictionary = {}
var _values: Dictionary = {}


func _ready() -> void:
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_label.text = tr("menu_checkin")
	_build()
	_load_record()


func _build() -> void:
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer_top)

	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	content.add_child(card)

	vb.add_child(_title(tr("menu_checkin")))

	var hint := Label.new()
	hint.text = tr("checkin_hint")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("8b949e"))
	vb.add_child(hint)

	for f in FIELDS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var l := Label.new()
		l.text = tr(f["label_key"])
		l.custom_minimum_size = Vector2(180, 0)
		row.add_child(l)

		var slider := HSlider.new()
		slider.min_value = 1
		slider.max_value = 10
		slider.step = 1
		slider.value = 5
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)

		var val := Label.new()
		val.text = "5/10"
		val.custom_minimum_size = Vector2(64, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val)

		_sliders[f["key"]] = slider
		_values[f["key"]] = val

		slider.value_changed.connect(func(v: float) -> void: _update_label(f, v))

		vb.add_child(row)

	var save := Button.new()
	save.text = tr("save")
	save.custom_minimum_size = Vector2(0, 48)
	save.pressed.connect(_on_save)
	vb.add_child(save)

	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 16)
	content.add_child(spacer_bottom)


func _make_card() -> Array:
	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)
	card.add_child(margin)
	return [card, vb]


func _title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color("8b949e"))
	return l


func _update_label(f: Dictionary, v: float) -> void:
	var val := int(round(v))
	var emojis: Dictionary = f["emojis"]
	var emoji: String = emojis["mid"]
	if val >= 8:
		emoji = emojis["high"]
	elif val <= 3:
		emoji = emojis["low"]
	_values[f["key"]].text = "%s %d/10" % [emoji, val]


func _load_record() -> void:
	var rec := DataManager.find_by_date("checkins", TimeManager.today_str())
	if rec.is_empty():
		return
	for f in FIELDS:
		var key: String = f["key"]
		var v := int(rec.get(key, 5))
		_sliders[key].value = v
		_update_label(f, v)


func _on_save() -> void:
	var energy := int(round(_sliders["energy"].value))
	var fatigue := int(round(_sliders["fatigue"].value))
	var mood := int(round(_sliders["mood"].value))
	DataManager.set_checkin(energy, fatigue, mood)
