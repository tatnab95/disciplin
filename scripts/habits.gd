extends Control

## Экран «Привычки»: чек-лист на сегодня, серии (streak) и тепловая карта.

const Heatmap := preload("res://components/heatmap.gd")

@onready var back_btn: Button = %BackBtn
@onready var title_label: Label = %TitleLabel
@onready var content: VBoxContainer = %Content

var _heatmap: Node
var _list_box: VBoxContainer


func _ready() -> void:
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_label.text = tr("menu_habits")
	DataManager.data_changed.connect(_refresh)
	_build()


func _build() -> void:
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer_top)
	content.add_child(_heatmap_card())
	content.add_child(_list_card())
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
	l.add_theme_color_override("font_color", Color("8b949e"))
	return l


func _heatmap_card() -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	vb.add_child(_title(tr("heatmap_title")))
	var heat := Heatmap.new()
	heat.custom_minimum_size = Vector2(82, 116)
	vb.add_child(heat)
	_heatmap = heat
	return card


func _list_card() -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	vb.add_child(_title(tr("menu_habits")))
	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 8)
	vb.add_child(_list_box)
	return card


func _refresh() -> void:
	var today := TimeManager.today_str()

	if _heatmap:
		var ratios: Array = []
		for i in range(35, 0, -1):
			var date := TimeManager.add_days(today, -i)
			var s := DataManager.day_summary(date)
			var r := 0.0
			if s.habits_total > 0:
				r = float(s.habits_done) / s.habits_total
			ratios.append(r)
		_heatmap.set_values(ratios)

	if _list_box:
		for c in _list_box.get_children():
			c.queue_free()
		for h in DataManager.get_habits():
			_list_box.add_child(_habit_row(h))
		var add_btn := Button.new()
		add_btn.text = tr("add_habit")
		add_btn.custom_minimum_size = Vector2(0, 48)
		add_btn.pressed.connect(_open_add_dialog)
		_list_box.add_child(add_btn)


func _habit_row(habit: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var id: String = habit.get("id", "")
	var today := TimeManager.today_str()

	var cb := CheckButton.new()
	cb.button_pressed = DataManager.is_habit_done(id, today)
	cb.toggled.connect(func(pressed: bool) -> void:
		DataManager.set_habit_done(id, today, pressed)
	)
	h.add_child(cb)

	var icon := Label.new()
	icon.text = str(habit.get("icon", "⭐"))
	icon.add_theme_font_size_override("font_size", 24)
	h.add_child(icon)

	var name := Label.new()
	name.text = tr(String(habit.get("name_key", "")))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(name)

	var streak := Label.new()
	streak.text = "🔥 %d" % DataManager.habit_streak(id)
	streak.add_theme_color_override("font_color", Color("d29922"))
	h.add_child(streak)

	return h


func _open_add_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = tr("add_habit")
	dialog.ok_button_text = tr("add")
	dialog.get_cancel_button().text = tr("cancel")

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var name_edit := LineEdit.new()
	name_edit.placeholder_text = tr("habit_name")
	box.add_child(name_edit)

	var icon_edit := LineEdit.new()
	icon_edit.placeholder_text = tr("habit_icon")
	icon_edit.max_length = 4
	box.add_child(icon_edit)

	dialog.add_child(box)
	add_child(dialog)

	dialog.confirmed.connect(func() -> void:
		var name := name_edit.text.strip_edges()
		var icon := icon_edit.text.strip_edges()
		if name.is_empty():
			return
		if icon.is_empty():
			icon = "⭐"
		DataManager.add_habit({"name_key": name, "icon": icon, "frequency": "daily"})
	)

	dialog.popup_centered(Vector2i(360, 0))
