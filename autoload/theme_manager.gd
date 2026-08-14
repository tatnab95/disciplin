extends Node

## Динамическая тема приложения.
## Тёмная/светлая основа + акцентный цвет (синий / зелёный / серый).
## Применяется ко всему дереву через root.theme и сигнал theme_changed.

signal theme_changed

const ACCENT_COLORS := {
	"blue": Color(0.23, 0.51, 0.96),
	"green": Color(0.2, 0.72, 0.46),
	"gray": Color(0.42, 0.47, 0.55),
}

var dark := true
var accent_name := "blue"
var accent := Color(0.23, 0.51, 0.96)
var accent_soft := Color(0.23, 0.51, 0.96, 0.15)
var bg := Color(0.043, 0.051, 0.071)
var bg_soft := Color(0.055, 0.065, 0.09)
var card := Color(1, 1, 1, 0.045)
var border := Color(1, 1, 1, 0.09)
var text := Color("e8ecf2")
var text_secondary := Color("9aa6b2")
var danger := Color("f87171")


func _ready() -> void:
	_apply()


func apply() -> void:
	_apply()


func _apply() -> void:
	var theme_str: String = str(DataManager.get_setting("theme", "dark"))
	dark = theme_str == "dark"
	accent_name = str(DataManager.get_setting("accent", "blue"))
	accent = ACCENT_COLORS.get(accent_name, ACCENT_COLORS["blue"])
	accent_soft = Color(accent, 0.15)
	if dark:
		bg = Color(0.043, 0.051, 0.071)
		bg_soft = Color(0.055, 0.065, 0.09)
		card = Color(1, 1, 1, 0.045)
		border = Color(1, 1, 1, 0.09)
		text = Color("e8ecf2")
		text_secondary = Color("9aa6b2")
	else:
		bg = Color(0.941, 0.953, 0.965)
		bg_soft = Color(0.98, 0.985, 0.99)
		card = Color(1, 1, 1, 0.6)
		border = Color(0, 0, 0, 0.07)
		text = Color("14181d")
		text_secondary = Color(0.12, 0.13, 0.15, 0.58)
	RenderingServer.set_default_clear_color(bg)
	get_tree().root.theme = _build_theme()
	theme_changed.emit()


func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 17

	# Цвета текста
	t.set_color("font_color", "Label", text)
	t.set_color("font_color", "Button", text)
	t.set_color("font_hover_color", "Button", text)
	t.set_color("font_pressed_color", "Button", text)
	t.set_color("font_focus_color", "Button", text)
	t.set_color("font_disabled_color", "Button", Color(text, 0.35))
	t.set_color("font_color", "LineEdit", text)
	t.set_color("font_placeholder_color", "LineEdit", Color(text, 0.4))
	t.set_color("caret_color", "LineEdit", accent)
	t.set_color("font_color", "OptionButton", text)
	t.set_color("font_hover_color", "OptionButton", text)
	t.set_color("font_color", "PopupMenu", text)
	t.set_color("font_hover_color", "PopupMenu", accent)
	t.set_color("title_color", "Window", text)

	# Панели/карточки
	t.set_stylebox("panel", "PanelContainer", _sb(card, border, 16, 0))
	t.set_stylebox("panel", "Panel", _sb(card, border, 16, 0))

	# Кнопки
	var btn_normal := _sb(Color(text, 0.05), Color(0, 0, 0, 0), 12, 12)
	var btn_hover := _sb(Color(text, 0.09), Color(0, 0, 0, 0), 12, 12)
	var btn_pressed := _sb(Color(text, 0.12), Color(0, 0, 0, 0), 12, 12)
	var btn_focus := _sb(Color(text, 0.06), accent, 12, 12)
	var btn_disabled := _sb(Color(text, 0.03), Color(0, 0, 0, 0), 12, 12)
	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("focus", "Button", btn_focus)
	t.set_stylebox("disabled", "Button", btn_disabled)
	for sb_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := btn_normal
		if sb_name == "hover":
			box = btn_hover
		elif sb_name == "pressed":
			box = btn_pressed
		elif sb_name == "focus":
			box = btn_focus
		elif sb_name == "disabled":
			box = btn_disabled
		t.set_stylebox(sb_name, "OptionButton", box)

	# Поле ввода
	t.set_stylebox("normal", "LineEdit", _sb(Color(text, 0.04), border, 10, 12))
	t.set_stylebox("focus", "LineEdit", _sb(Color(text, 0.04), accent, 10, 12))

	# Ползунки
	t.set_stylebox("slider", "Slider", _track_sb())
	t.set_stylebox("grabber_area", "Slider", _track_hl_sb())
	t.set_stylebox("grabber_area_highlight", "Slider", _track_hl_sb())
	t.set_stylebox("grabber", "Slider", _grabber_sb())
	t.set_stylebox("grabber_highlight", "Slider", _grabber_sb())

	# Прогресс-бары
	t.set_stylebox("background", "ProgressBar", _sb(Color(text, 0.08), Color(0, 0, 0, 0), 6, 0))
	t.set_stylebox("fill", "ProgressBar", _sb(accent, Color(0, 0, 0, 0), 6, 0))

	# Выпадающее меню
	t.set_stylebox("panel", "PopupMenu", _sb(bg_soft, border, 12, 8))
	t.set_stylebox("hover", "PopupMenu", _sb(accent_soft, Color(0, 0, 0, 0), 8, 8))
	t.set_stylebox("separator", "PopupMenu", _sb(border, Color(0, 0, 0, 0), 2, 0))

	# Скроллбар
	t.set_stylebox("grabber", "ScrollBar", _sb(Color(text, 0.22), Color(0, 0, 0, 0), 4, 2))
	t.set_stylebox("grabber_highlight", "ScrollBar", _sb(Color(text, 0.3), Color(0, 0, 0, 0), 4, 2))

	# Окна (диалоги)
	t.set_stylebox("panel", "Window", _sb(bg_soft, border, 18, 0))
	return t


func _sb(bg_color: Color, border_color: Color, radius: int, margins: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(1 if border_color.a > 0.0 else 0)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margins)
	return sb


func _track_sb() -> StyleBoxFlat:
	var sb := _sb(Color(text, 0.1), Color(0, 0, 0, 0), 6, 0)
	sb.set_content_margin(SIDE_TOP, 4)
	sb.set_content_margin(SIDE_BOTTOM, 4)
	return sb


func _track_hl_sb() -> StyleBoxFlat:
	var sb := _sb(accent_soft, Color(0, 0, 0, 0), 6, 0)
	sb.set_content_margin(SIDE_TOP, 4)
	sb.set_content_margin(SIDE_BOTTOM, 4)
	return sb


func _grabber_sb() -> StyleBoxFlat:
	return _sb(accent, Color(0, 0, 0, 0), 8, 8)
