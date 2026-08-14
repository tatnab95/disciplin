extends Control

## Экран «Сон»: время отбоя/подъёма, качество, долг сна, средняя за неделю.

@onready var back_btn: Button = %BackBtn
@onready var title_label: Label = %TitleLabel
@onready var content: VBoxContainer = %Content

var _bed_edit: LineEdit
var _wake_edit: LineEdit
var _quality_slider: HSlider
var _quality_value: Label
var _summary_label: Label
var _week_label: Label


func _ready() -> void:
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_label.text = tr("menu_sleep")
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

	vb.add_child(_title(tr("menu_sleep")))

	_bed_edit = _time_edit()
	_wake_edit = _time_edit()
	vb.add_child(_label_row(tr("sleep_bedtime"), _bed_edit))
	vb.add_child(_label_row(tr("sleep_wake"), _wake_edit))

	var qrow := HBoxContainer.new()
	qrow.add_theme_constant_override("separation", 10)
	var ql := Label.new()
	ql.text = tr("sleep_quality")
	ql.custom_minimum_size = Vector2(120, 0)
	qrow.add_child(ql)
	_quality_slider = HSlider.new()
	_quality_slider.min_value = 1
	_quality_slider.max_value = 5
	_quality_slider.step = 1
	_quality_slider.value = 3
	_quality_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qrow.add_child(_quality_slider)
	_quality_value = Label.new()
	_quality_value.text = "3/5"
	qrow.add_child(_quality_value)
	_quality_slider.value_changed.connect(func(v: float) -> void:
		_quality_value.text = "%d/5" % int(v)
	)
	vb.add_child(qrow)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_color_override("font_color", Color("8b949e"))
	vb.add_child(_summary_label)

	var save := Button.new()
	save.text = tr("save")
	save.custom_minimum_size = Vector2(0, 48)
	save.pressed.connect(_on_save)
	vb.add_child(save)

	var arr2 := _make_card()
	var card2: PanelContainer = arr2[0]
	var vb2: VBoxContainer = arr2[1]
	content.add_child(card2)
	vb2.add_child(_title(tr("week_avg_title")))
	_week_label = Label.new()
	_week_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_week_label.add_theme_color_override("font_color", Color("8b949e"))
	vb2.add_child(_week_label)

	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 16)
	content.add_child(spacer_bottom)

	_update_summary()


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


func _label_row(text: String, control: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(120, 0)
	h.add_child(l)
	h.add_child(control)
	return h


func _time_edit() -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = tr("time_placeholder")
	e.max_length = 5
	e.custom_minimum_size = Vector2(90, 0)
	return e


func _load_record() -> void:
	var rec := DataManager.find_by_date("sleep", TimeManager.today_str())
	if rec.is_empty():
		return
	_bed_edit.text = str(rec.get("bedtime", ""))
	_wake_edit.text = str(rec.get("wake", ""))
	_quality_slider.value = int(rec.get("quality", 3))


func _on_save() -> void:
	var bt := _bed_edit.text.strip_edges()
	var wk := _wake_edit.text.strip_edges()
	if not (_valid_time(bt) and _valid_time(wk)):
		_summary_label.add_theme_color_override("font_color", Color("f87171"))
		_summary_label.text = tr("invalid_time")
		return
	DataManager.set_sleep(bt, wk, int(_quality_slider.value))
	_summary_label.remove_theme_color_override("font_color")
	_update_summary()


func _valid_time(t: String) -> bool:
	if t.length() != 5 or t[2] != ":":
		return false
	var p := t.split(":")
	if p.size() != 2:
		return false
	var h := int(p[0])
	var m := int(p[1])
	return h >= 0 and h <= 23 and m >= 0 and m <= 59


func _update_summary() -> void:
	var today := TimeManager.today_str()
	var s := DataManager.day_summary(today)
	var user_settings := DataManager.get_settings()
	var target := float(user_settings.get("sleep_target_hours", 8.0))

	if s.has_sleep and s.sleep_hours > 0:
		var lines := PackedStringArray()
		lines.append(tr("sleep_hours_label").format({"v": "%.1f" % s.sleep_hours}))
		var debt: float = target - s.sleep_hours
		if debt > 0.5:
			lines.append(tr("sleep_debt").format({"v": "%.1f" % debt}))
		else:
			lines.append(tr("sleep_ok"))
		_summary_label.remove_theme_color_override("font_color")
		_summary_label.text = "\n".join(lines)
	else:
		_summary_label.remove_theme_color_override("font_color")
		_summary_label.text = tr("sleep_hint")

	var sum := 0.0
	var cnt := 0
	for i in range(7):
		var ds := DataManager.day_summary(TimeManager.add_days(today, -i))
		if ds.has_sleep and ds.sleep_hours > 0:
			sum += ds.sleep_hours
			cnt += 1
	if cnt > 0:
		_week_label.text = tr("week_avg").format({"v": "%.1f" % (sum / cnt)})
	else:
		_week_label.text = tr("no_data")
