extends Control

## Экран «Еда»: приём пищи, поиск по каталогу продуктов (БЖУ),
## фото → ИИ-распознавание (опционально), итоги дня.

@onready var back_btn: Button = %BackBtn
@onready var title_label: Label = %TitleLabel
@onready var content: VBoxContainer = %Content

const MEAL_TYPES := [
	{"key": "breakfast", "name_key": "meal_breakfast", "icon": "🍳"},
	{"key": "lunch", "name_key": "meal_lunch", "icon": "🍲"},
	{"key": "dinner", "name_key": "meal_dinner", "icon": "🍛"},
	{"key": "snack", "name_key": "meal_snack", "icon": "🍿"},
	{"key": "other", "name_key": "meal_other", "icon": "🥗"},
]

var _type_box: OptionButton
var _ai_status: Label
var _search_edit: LineEdit
var _search_box: VBoxContainer
var _pending_box: VBoxContainer
var _totals_label: Label
var _today_box: VBoxContainer

var _pending_items: Array = []
var _photo_path := ""


func _ready() -> void:
	$Bg.color = ThemeManager.bg
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	title_label.text = tr("menu_food")
	DataManager.data_changed.connect(_refresh_today)
	_build()


func _build() -> void:
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer_top)

	content.add_child(_build_add_card())
	content.add_child(_build_search_card())
	content.add_child(_build_today_card())

	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 16)
	content.add_child(spacer_bottom)

	_refresh_today()


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


# ---------------------------------------------------------------------------
# Карточка добавления приёма пищи
# ---------------------------------------------------------------------------

func _build_add_card() -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]

	vb.add_child(_title(tr("add_meal")))

	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 10)
	var tl := Label.new()
	tl.text = tr("meal_type")
	tl.custom_minimum_size = Vector2(150, 0)
	trow.add_child(tl)
	_type_box = OptionButton.new()
	_type_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for m in MEAL_TYPES:
		_type_box.add_item(tr(m["name_key"]))
	trow.add_child(_type_box)
	vb.add_child(trow)

	var phrow := HBoxContainer.new()
	phrow.add_theme_constant_override("separation", 10)
	var photo := Button.new()
	photo.text = tr("meal_photo")
	photo.custom_minimum_size = Vector2(150, 44)
	photo.pressed.connect(_open_photo_dialog)
	phrow.add_child(photo)
	_ai_status = Label.new()
	_ai_status.text = tr("meal_hint")
	_ai_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ai_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ai_status.add_theme_color_override("font_color", ThemeManager.text_secondary)
	phrow.add_child(_ai_status)
	vb.add_child(phrow)

	vb.add_child(_title(tr("meal_items")))
	_pending_box = VBoxContainer.new()
	_pending_box.add_theme_constant_override("separation", 8)
	vb.add_child(_pending_box)

	var save := Button.new()
	save.text = tr("save_meal")
	save.custom_minimum_size = Vector2(0, 48)
	save.pressed.connect(_on_save_meal)
	vb.add_child(save)

	_refresh_pending()
	return card


# ---------------------------------------------------------------------------
# Поиск по каталогу
# ---------------------------------------------------------------------------

func _build_search_card() -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]

	vb.add_child(_title(tr("meal_search")))
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = tr("meal_search_placeholder")
	_search_edit.text_changed.connect(func(_t: String) -> void: _refresh_search())
	vb.add_child(_search_edit)

	_search_box = VBoxContainer.new()
	_search_box.add_theme_constant_override("separation", 6)
	vb.add_child(_search_box)
	_refresh_search()
	return card


func _refresh_search() -> void:
	for c in _search_box.get_children():
		c.queue_free()
	var results := DataManager.search_foods(_search_edit.text, 8)
	for fd in results:
		var b := Button.new()
		b.text = _food_text(fd)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 42)
		b.pressed.connect(_add_catalog_item.bind(fd, 100))
		_search_box.add_child(b)


func _food_text(fd: Dictionary) -> String:
	var name := _localized_name(fd)
	return "%s   ·   %d ккал / 100 г" % [name, int(fd.get("kcal", 0))]


func _localized_name(fd: Dictionary) -> String:
	if TranslationServer.get_locale().begins_with("ru"):
		return str(fd.get("name_ru", str(fd.get("name_en", ""))))
	return str(fd.get("name_en", ""))


func _add_catalog_item(fd: Dictionary, grams := 100) -> void:
	var scale := float(grams) / 100.0
	_pending_items.append({
		"name": _localized_name(fd),
		"category": str(fd.get("category", "other")),
		"grams": grams,
		"calories": int(round(float(fd.get("kcal", 0)) * scale)),
		"protein": float(fd.get("protein", 0.0)) * scale,
		"fat": float(fd.get("fat", 0.0)) * scale,
		"carbs": float(fd.get("carbs", 0.0)) * scale,
	})
	_refresh_pending()


# ---------------------------------------------------------------------------
# Фото → ИИ
# ---------------------------------------------------------------------------

func _open_photo_dialog() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Изображения"])
	fd.file_selected.connect(_on_photo_selected)
	add_child(fd)
	fd.popup_centered()


func _on_photo_selected(path: String) -> void:
	var stored := _copy_to_photos(path)
	if stored.is_empty():
		_ai_status.text = tr("photo_error")
		_ai_status.add_theme_color_override("font_color", ThemeManager.danger)
		return
	_photo_path = stored
	_ai_status.text = tr("ai_thinking")
	_ai_status.remove_theme_color_override("font_color")
	FoodRecognizer.recognize_image(stored, _on_ai_result)


func _copy_to_photos(src: String) -> String:
	var img: Image = Image.load_from_file(src)
	if img == null:
		return ""
	var dst := "user://photos/%d.jpg" % Time.get_unix_time_from_system()
	var f := FileAccess.open(dst, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_buffer(img.save_jpg_to_buffer(0.85))
	return dst


func _on_ai_result(result: Dictionary) -> void:
	if not result.get("ok", false):
		_ai_status.add_theme_color_override("font_color", ThemeManager.danger)
		_ai_status.text = tr("ai_error_unknown")
		var err := str(result.get("error", ""))
		if err == "no_api_key":
			_ai_status.text = tr("ai_no_key")
		elif err == "network_error":
			_ai_status.text = tr("ai_network")
		return
	var items: Array = result.get("items", [])
	if items.is_empty():
		_ai_status.text = tr("ai_no_food")
		return
	_pending_items = items
	_ai_status.remove_theme_color_override("font_color")
	_ai_status.text = tr("ai_done").format({"n": items.size()})
	_refresh_pending()


# ---------------------------------------------------------------------------
# Продyкты в приёме пищи
# ---------------------------------------------------------------------------

func _refresh_pending() -> void:
	if _pending_box == null:
		return
	for c in _pending_box.get_children():
		c.queue_free()
	if _pending_items.is_empty():
		var l := Label.new()
		l.text = tr("meal_empty")
		l.add_theme_color_override("font_color", ThemeManager.text_secondary)
		_pending_box.add_child(l)
		return
	for item in _pending_items:
		_pending_box.add_child(_pending_row(item))


func _pending_row(item: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)

	var name := Label.new()
	name.text = str(item.get("name", "?"))
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(name)

	var grams := SpinBox.new()
	grams.min_value = 1
	grams.max_value = 2000
	grams.step = 5
	grams.value = int(item.get("grams", 100))
	grams.custom_minimum_size = Vector2(100, 0)
	grams.value_changed.connect(func(v: float) -> void: _update_item_grams(item, int(v)))
	h.add_child(grams)

	var kcal := Label.new()
	kcal.text = "%d ккал" % int(item.get("calories", 0))
	kcal.custom_minimum_size = Vector2(72, 0)
	kcal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kcal.add_theme_color_override("font_color", ThemeManager.text_secondary)
	h.add_child(kcal)

	var del := Button.new()
	del.text = "✕"
	del.custom_minimum_size = Vector2(36, 36)
	del.pressed.connect(_remove_item.bind(item))
	h.add_child(del)

	return h


func _update_item_grams(item: Dictionary, new_grams: int) -> void:
	var old := int(item.get("grams", 100))
	if old <= 0:
		old = 100
	var scale := float(new_grams) / float(old)
	item["grams"] = new_grams
	item["calories"] = int(round(float(item.get("calories", 0)) * scale))
	item["protein"] = float(item.get("protein", 0.0)) * scale
	item["fat"] = float(item.get("fat", 0.0)) * scale
	item["carbs"] = float(item.get("carbs", 0.0)) * scale


func _remove_item(item: Dictionary) -> void:
	_pending_items.erase(item)
	_refresh_pending()


func _on_save_meal() -> void:
	if _pending_items.is_empty():
		_ai_status.text = tr("meal_empty")
		return
	var idx := _type_box.selected
	var meal_type: String = MEAL_TYPES[idx]["key"]
	var time := TimeManager.now_hhmm()
	DataManager.add_meal(meal_type, time, _pending_items, _photo_path, "")
	_pending_items = []
	_photo_path = ""
	_ai_status.text = tr("meal_saved")
	_refresh_pending()


# ---------------------------------------------------------------------------
# Итоги дня
# ---------------------------------------------------------------------------

func _build_today_card() -> PanelContainer:
	var arr := _make_card()
	var card: PanelContainer = arr[0]
	var vb: VBoxContainer = arr[1]

	vb.add_child(_title(tr("today_meals")))
	_totals_label = Label.new()
	_totals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_totals_label.add_theme_color_override("font_color", ThemeManager.text_secondary)
	vb.add_child(_totals_label)
	_today_box = VBoxContainer.new()
	_today_box.add_theme_constant_override("separation", 8)
	vb.add_child(_today_box)
	return card


func _refresh_today() -> void:
	if _today_box == null:
		return
	var today := TimeManager.today_str()
	var s := DataManager.day_summary(today)
	_totals_label.text = tr("meal_totals").format({
		"kcal": int(s.calories),
		"protein": "%.0f" % s.protein,
		"fat": "%.0f" % s.fat,
		"carbs": "%.0f" % s.carbs,
	})

	for c in _today_box.get_children():
		c.queue_free()
	var meals: Array = []
	for m in DataManager.get_section("meals"):
		if m.get("date", "") == today:
			meals.append(m)
	meals.sort_custom(func(a, b): return str(a["time"]) < str(b["time"]))
	if meals.is_empty():
		var l := Label.new()
		l.text = tr("no_data")
		l.add_theme_color_override("font_color", ThemeManager.text_secondary)
		_today_box.add_child(l)
		return
	for m in meals:
		_today_box.add_child(_today_row(m))


func _meal_meta(key: String) -> Dictionary:
	for m in MEAL_TYPES:
		if m["key"] == key:
			return m
	return MEAL_TYPES[MEAL_TYPES.size() - 1]


func _today_row(meal: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var id: String = meal.get("id", "")
	var meta := _meal_meta(str(meal.get("type", "other")))

	var icon := Label.new()
	icon.text = meta["icon"]
	icon.add_theme_font_size_override("font_size", 20)
	h.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line1 := Label.new()
	line1.text = "%s · %s" % [tr(meta["name_key"]), str(meal.get("time", ""))]
	info.add_child(line1)
	var item_names := PackedStringArray()
	var meal_kcal := 0
	for it in meal.get("items", []):
		if it is Dictionary:
			item_names.append(str(it.get("name", "")))
			meal_kcal += int(it.get("calories", 0))
	var line2 := Label.new()
	line2.text = ", ".join(item_names)
	line2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line2.add_theme_color_override("font_color", ThemeManager.text_secondary)
	info.add_child(line2)
	h.add_child(info)

	var kcal := Label.new()
	kcal.text = "%d" % meal_kcal
	kcal.custom_minimum_size = Vector2(56, 0)
	kcal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(kcal)

	var del := Button.new()
	del.text = "✕"
	del.custom_minimum_size = Vector2(36, 36)
	del.pressed.connect(_delete_meal.bind(id))
	h.add_child(del)

	return h


func _delete_meal(id: String) -> void:
	DataManager.remove_record("meals", id)
