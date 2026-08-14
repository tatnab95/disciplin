extends Control

## Экран «Настройки»: язык, ИИ-ключ, цели, экспорт/импорт/сброс.

@onready var back_btn: Button = %BackBtn
@onready var title_label: Label = %TitleLabel
@onready var content: VBoxContainer = %Content

var _lang_box: OptionButton
var _api_key_edit: LineEdit
var _base_url_edit: LineEdit
var _model_edit: LineEdit
var _sleep_target_spin: SpinBox
var _game_limit_spin: SpinBox
var _sport_sessions_spin: SpinBox
var _sport_minutes_spin: SpinBox
var _water_spin: SpinBox
var _theme_box: OptionButton
var _accent_box: OptionButton
var _status: Label


func _ready() -> void:
	$Bg.visible = false
	var bg := preload("res://components/background.gd").new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_label.text = tr("menu_settings")
	_build()


func _build() -> void:
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer_top)

	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]
	content.add_child(card)

	vb.add_child(_title(tr("settings_lang")))
	_lang_box = OptionButton.new()
	_lang_box.add_item("Русский")
	_lang_box.add_item("English")
	_lang_box.select(0 if str(DataManager.get_setting("lang", "ru")).begins_with("ru") else 1)
	_lang_box.item_selected.connect(func(idx: int) -> void:
		DataManager.set_lang("ru" if idx == 0 else "en")
	)
	vb.add_child(_lang_box)

	vb.add_child(_title(tr("settings_theme")))
	_theme_box = OptionButton.new()
	_theme_box.add_item(tr("theme_dark"))
	_theme_box.add_item(tr("theme_light"))
	_theme_box.select(0 if str(DataManager.get_setting("theme", "dark")) == "dark" else 1)
	_theme_box.item_selected.connect(_on_theme_selected)
	vb.add_child(_theme_box)

	vb.add_child(_title(tr("settings_accent")))
	_accent_box = OptionButton.new()
	_accent_box.add_item(tr("accent_blue"))
	_accent_box.add_item(tr("accent_green"))
	_accent_box.add_item(tr("accent_gray"))
	var acc_idx := ["blue", "green", "gray"].find(str(DataManager.get_setting("accent", "blue")))
	_accent_box.select(maxi(0, acc_idx))
	_accent_box.item_selected.connect(_on_accent_selected)
	vb.add_child(_accent_box)

	vb.add_child(_title(tr("settings_ai")))
	_api_key_edit = _secret_edit(tr("settings_api_key"), str(DataManager.get_setting("vision_api_key", "")))
	vb.add_child(_label_row(tr("settings_api_key"), _api_key_edit))
	_base_url_edit = _text_edit(tr("settings_base_url"), str(DataManager.get_setting("vision_base_url", "")))
	vb.add_child(_label_row(tr("settings_base_url"), _base_url_edit))
	_model_edit = _text_edit(tr("settings_model"), str(DataManager.get_setting("vision_model", "")))
	vb.add_child(_label_row(tr("settings_model"), _model_edit))

	vb.add_child(_title(tr("settings_goals")))
	_sleep_target_spin = _spin(4.0, 12.0, 0.5, float(DataManager.get_setting("sleep_target_hours", 8.0)))
	vb.add_child(_label_row(tr("settings_sleep_target"), _sleep_target_spin))
	_game_limit_spin = _spin(30.0, 720.0, 15.0, float(DataManager.get_setting("game_limit_minutes", 120)))
	vb.add_child(_label_row(tr("settings_game_limit"), _game_limit_spin))
	_sport_sessions_spin = _spin(1.0, 10.0, 1.0, float(DataManager.get_setting("sport_goal_sessions", 3)))
	vb.add_child(_label_row(tr("settings_sport_sessions"), _sport_sessions_spin))
	_sport_minutes_spin = _spin(30.0, 1200.0, 30.0, float(DataManager.get_setting("sport_goal_minutes", 240)))
	vb.add_child(_label_row(tr("settings_sport_minutes"), _sport_minutes_spin))
	_water_spin = _spin(500.0, 5000.0, 100.0, float(DataManager.get_setting("water_goal", 2000)))
	vb.add_child(_label_row(tr("settings_water"), _water_spin))

	var save := Button.new()
	save.text = tr("save")
	save.custom_minimum_size = Vector2(0, 48)
	save.pressed.connect(_on_save)
	vb.add_child(save)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", ThemeManager.text_secondary)
	vb.add_child(_status)

	var arr2 := _make_card()
	var card2: PanelContainer = arr2[0]
	var vb2: VBoxContainer = arr2[1]
	content.add_child(card2)

	vb2.add_child(_title(tr("settings_data")))
	var export_btn := Button.new()
	export_btn.text = tr("settings_export")
	export_btn.custom_minimum_size = Vector2(0, 44)
	export_btn.pressed.connect(_open_export)
	vb2.add_child(export_btn)

	var import_btn := Button.new()
	import_btn.text = tr("settings_import")
	import_btn.custom_minimum_size = Vector2(0, 44)
	import_btn.pressed.connect(_open_import)
	vb2.add_child(import_btn)

	var reset_btn := Button.new()
	reset_btn.text = tr("settings_reset")
	reset_btn.custom_minimum_size = Vector2(0, 44)
	reset_btn.pressed.connect(_confirm_reset)
	vb2.add_child(reset_btn)

	var arr3 := _make_card()
	var card3: PanelContainer = arr3[0]
	var vb3: VBoxContainer = arr3[1]
	content.add_child(card3)
	vb3.add_child(_title(tr("settings_about")))
	var about := Label.new()
	about.text = tr("about_text")
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.add_theme_color_override("font_color", ThemeManager.text_secondary)
	vb3.add_child(about)

	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 16)
	content.add_child(spacer_bottom)


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


func _label_row(text: String, control: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(190, 0)
	h.add_child(l)
	h.add_child(control)
	return h


func _text_edit(_placeholder: String, value: String) -> LineEdit:
	var e := LineEdit.new()
	e.text = value
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return e


func _secret_edit(_placeholder: String, value: String) -> LineEdit:
	var e := _text_edit(_placeholder, value)
	e.secret = true
	return e


func _spin(min_v: float, max_v: float, step: float, value: float) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


func _on_theme_selected(idx: int) -> void:
	DataManager.set_setting("theme", "dark" if idx == 0 else "light")
	ThemeManager.apply()
	_rebuild.call_deferred()


func _on_accent_selected(idx: int) -> void:
	DataManager.set_setting("accent", ["blue", "green", "gray"][idx])
	ThemeManager.apply()
	_rebuild.call_deferred()


func _rebuild() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.free()
	_build()


func _on_save() -> void:
	DataManager.set_setting("vision_api_key", _api_key_edit.text.strip_edges())
	DataManager.set_setting("vision_base_url", _base_url_edit.text.strip_edges())
	DataManager.set_setting("vision_model", _model_edit.text.strip_edges())
	DataManager.set_setting("sleep_target_hours", _sleep_target_spin.value)
	DataManager.set_setting("game_limit_minutes", int(_game_limit_spin.value))
	DataManager.set_setting("sport_goal_sessions", int(_sport_sessions_spin.value))
	DataManager.set_setting("sport_goal_minutes", int(_sport_minutes_spin.value))
	DataManager.set_setting("water_goal", int(_water_spin.value))
	_status.text = tr("settings_saved")


func _open_export() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = PackedStringArray(["*.json ; JSON"])
	fd.current_file = "disciplin_backup.json"
	fd.file_selected.connect(func(path: String) -> void:
		_status.text = tr("settings_exported").format({"path": path}) if DataManager.export_to_path(path) else tr("settings_error")
	)
	add_child(fd)
	fd.popup_centered()


func _open_import() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = PackedStringArray(["*.json ; JSON"])
	fd.file_selected.connect(func(path: String) -> void:
		_status.text = tr("settings_imported") if DataManager.import_from_path(path) else tr("settings_error")
	)
	add_child(fd)
	fd.popup_centered()


func _confirm_reset() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = tr("settings_reset_confirm")
	dlg.ok_button_text = tr("yes")
	dlg.get_cancel_button().text = tr("no")
	dlg.confirmed.connect(func() -> void:
		DataManager.reset_data()
		_status.text = tr("settings_reset_done")
	)
	add_child(dlg)
	dlg.popup_centered()
