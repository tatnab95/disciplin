extends Control

## Экран «Расписание»: слоты дня, подсветка текущего, добавление/редактирование.

@onready var back_btn: Button = %BackBtn
@onready var title_label: Label = %TitleLabel
@onready var content: VBoxContainer = %Content

var _list_box: VBoxContainer
var _editing_id := ""


func _ready() -> void:
	$Bg.color = ThemeManager.bg
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_label.text = tr("menu_planner")
	DataManager.data_changed.connect(_refresh)
	_build()


func _build() -> void:
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer_top)

	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	content.add_child(card)

	vb.add_child(_title(tr("menu_planner")))
	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 8)
	vb.add_child(_list_box)

	var add_btn := Button.new()
	add_btn.text = tr("schedule_add")
	add_btn.custom_minimum_size = Vector2(0, 48)
	add_btn.pressed.connect(_open_dialog.bind(""))
	vb.add_child(add_btn)

	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 16)
	content.add_child(spacer_bottom)

	_refresh()


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
	l.add_theme_color_override("font_color", ThemeManager.text_secondary)
	return l


func _refresh() -> void:
	for c in _list_box.get_children():
		c.queue_free()
	var slots: Array = DataManager.get_section("schedule")
	slots.sort_custom(func(a, b): return str(a["time"]) < str(b["time"]))
	if slots.is_empty():
		var l := Label.new()
		l.text = tr("no_data")
		l.add_theme_color_override("font_color", ThemeManager.text_secondary)
		_list_box.add_child(l)
		return
	var current_id := ""
	var cur: Dictionary = TimeManager.current_slot(slots)["current"]
	if not cur.is_empty():
		current_id = str(cur.get("id", ""))
	for slot in slots:
		_list_box.add_child(_slot_row(slot, str(slot.get("id", "")) == current_id))


func _slot_row(slot: Dictionary, is_current: bool) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var id: String = slot.get("id", "")

	var time := Label.new()
	time.text = str(slot.get("time", ""))
	time.custom_minimum_size = Vector2(60, 0)
	time.add_theme_font_size_override("font_size", 20)
	time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(time)

	var name := Label.new()
	name.text = tr(String(slot.get("name_key", "")))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_current:
		name.add_theme_color_override("font_color", ThemeManager.accent)
	h.add_child(name)

	if is_current:
		var badge := Label.new()
		badge.text = tr("schedule_now_badge")
		badge.add_theme_color_override("font_color", ThemeManager.accent)
		h.add_child(badge)

	var edit := Button.new()
	edit.text = "✎"
	edit.custom_minimum_size = Vector2(36, 36)
	edit.pressed.connect(_open_dialog.bind(id))
	h.add_child(edit)

	var del := Button.new()
	del.text = "✕"
	del.custom_minimum_size = Vector2(36, 36)
	del.pressed.connect(_delete_slot.bind(id))
	h.add_child(del)

	return h


func _delete_slot(id: String) -> void:
	DataManager.remove_record("schedule", id)


func _open_dialog(id: String) -> void:
	var rec := DataManager.get_record("schedule", id)
	_editing_id = id

	var dialog := ConfirmationDialog.new()
	dialog.title = tr("schedule_add") if id.is_empty() else tr("edit")
	dialog.ok_button_text = tr("save")
	dialog.get_cancel_button().text = tr("cancel")

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var time_edit := LineEdit.new()
	time_edit.placeholder_text = tr("time_placeholder")
	time_edit.max_length = 5
	time_edit.text = str(rec.get("time", ""))
	box.add_child(time_edit)

	var name_edit := LineEdit.new()
	name_edit.placeholder_text = tr("schedule_name")
	name_edit.text = tr(String(rec.get("name_key", "")))
	box.add_child(name_edit)

	var dur_spin := SpinBox.new()
	dur_spin.min_value = 0
	dur_spin.max_value = 600
	dur_spin.step = 5
	dur_spin.value = int(rec.get("duration_min", 30))
	dur_spin.suffix = " %s" % tr("min_unit")
	box.add_child(dur_spin)

	dialog.add_child(box)
	add_child(dialog)

	dialog.confirmed.connect(func() -> void:
		var time := time_edit.text.strip_edges()
		var name := name_edit.text.strip_edges()
		if not _valid_time(time) or name.is_empty():
			return
		var duration := int(dur_spin.value)
		if _editing_id.is_empty():
			DataManager.add_record("schedule", {"time": time, "name_key": name, "duration_min": duration})
		else:
			var r := DataManager.get_record("schedule", _editing_id)
			r["time"] = time
			r["name_key"] = name
			r["duration_min"] = duration
			DataManager.update_record("schedule", _editing_id, r)
		_editing_id = ""
	)

	dialog.popup_centered(Vector2i(360, 0))


func _valid_time(t: String) -> bool:
	if t.length() != 5 or t[2] != ":":
		return false
	var p := t.split(":")
	if p.size() != 2:
		return false
	var h := int(p[0])
	var m := int(p[1])
	return h >= 0 and h <= 23 and m >= 0 and m <= 59
