extends Node

## Тема в стиле Material You / Android 16: светлая «стеклянная» основа,
## полупрозрачные карточки со скруглением и тенью, градиентный фон
## с цветными пятнами. Тёмная версия — тот же стиль, тёмные тона.

signal theme_changed

const ACCENT_COLORS := {
	"blue": Color(0.23, 0.51, 0.96),
	"green": Color(0.22, 0.69, 0.47),
	"gray": Color(0.44, 0.48, 0.56),
}

var dark := false
var accent_name := "blue"
var accent := Color(0.23, 0.51, 0.96)
var accent_soft := Color(0.23, 0.51, 0.96, 0.14)
var bg_top := Color(0.945, 0.958, 0.985)
var bg_bottom := Color(0.99, 0.965, 0.975)
var bg := Color(0.955, 0.962, 0.975)
var bg_soft := Color(1, 1, 1)
var card := Color(1, 1, 1, 0.55)
var card_border := Color(1, 1, 1, 0.75)
var border := Color(0.15, 0.18, 0.25, 0.06)
var input := Color(1, 1, 1, 0.7)
var text := Color("1d2126")
var text_secondary := Color(0.30, 0.35, 0.42, 0.9)
var danger := Color("e5484d")
var shadow := Color(0.4, 0.5, 0.65, 0.16)
var blob2 := Color(0.62, 0.45, 0.93, 0.12)
var blob3 := Color(0.99, 0.60, 0.40, 0.10)
var blob4 := Color(0.38, 0.80, 0.68, 0.12)


func _ready() -> void:
	_apply()


func apply() -> void:
	_apply()


func _apply() -> void:
	var theme_str: String = str(DataManager.get_setting("theme", "light"))
	dark = theme_str == "dark"
	accent_name = str(DataManager.get_setting("accent", "blue"))
	accent = ACCENT_COLORS.get(accent_name, ACCENT_COLORS["blue"])
	accent_soft = Color(accent, 0.14)
	if dark:
		bg_top = Color(0.055, 0.06, 0.085)
		bg_bottom = Color(0.075, 0.08, 0.12)
		bg = Color(0.06, 0.065, 0.095)
		bg_soft = Color(0.10, 0.11, 0.15)
		card = Color(1, 1, 1, 0.07)
		card_border = Color(1, 1, 1, 0.12)
		border = Color(1, 1, 1, 0.09)
		input = Color(1, 1, 1, 0.06)
		text = Color("eceef1")
		text_secondary = Color("a3abb5")
		danger = Color("f87171")
		shadow = Color(0, 0, 0, 0.45)
		accent_soft = Color(accent, 0.16)
		blob2 = Color(0.62, 0.45, 0.93, 0.10)
		blob3 = Color(0.99, 0.60, 0.40, 0.07)
		blob4 = Color(0.38, 0.80, 0.68, 0.08)
	else:
		bg_top = Color(0.945, 0.958, 0.985)
		bg_bottom = Color(0.99, 0.965, 0.975)
		bg = Color(0.955, 0.962, 0.975)
		bg_soft = Color(1, 1, 1)
		card = Color(1, 1, 1, 0.55)
		card_border = Color(1, 1, 1, 0.75)
		border = Color(0.15, 0.18, 0.25, 0.06)
		input = Color(1, 1, 1, 0.7)
		text = Color("1d2126")
		text_secondary = Color(0.30, 0.35, 0.42, 0.9)
		danger = Color("e5484d")
		shadow = Color(0.4, 0.5, 0.65, 0.16)
		accent_soft = Color(accent, 0.14)
		blob2 = Color(0.62, 0.45, 0.93, 0.12)
		blob3 = Color(0.99, 0.60, 0.40, 0.10)
		blob4 = Color(0.38, 0.80, 0.68, 0.12)
	RenderingServer.set_default_clear_color(bg)
	get_tree().root.theme = _build_theme()
	theme_changed.emit()


func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 16

	# Текст
	t.set_color("font_color", "Label", text)
	t.set_color("font_color", "Button", text)
	t.set_color("font_hover_color", "Button", text)
	t.set_color("font_pressed_color", "Button", accent)
	t.set_color("font_focus_color", "Button", text)
	t.set_color("font_disabled_color", "Button", Color(text, 0.35))
	t.set_color("font_color", "LineEdit", text)
	t.set_color("font_placeholder_color", "LineEdit", Color(text, 0.4))
	t.set_color("caret_color", "LineEdit", accent)
	t.set_color("font_color", "OptionButton", text)
	t.set_color("font_hover_color", "OptionButton", accent)
	t.set_color("font_color", "PopupMenu", text)
	t.set_color("font_hover_color", "PopupMenu", text)
	t.set_color("font_selected_color", "PopupMenu", text)
	t.set_color("title_color", "Window", text)

	# Карточки (стекло)
	var card_sb := _sb(card, card_border, 24, 0, 14)
	card_sb.shadow_offset = Vector2(0, 6)
	t.set_stylebox("panel", "PanelContainer", card_sb)
	t.set_stylebox("panel", "Panel", card_sb)

	# Кнопки
	t.set_stylebox("normal", "Button", _sb(Color(text, 0.06), Color(text, 0.04), 18, 12, 6))
	t.set_stylebox("hover", "Button", _sb(Color(text, 0.10), Color(text, 0.05), 18, 12, 6))
	t.set_stylebox("pressed", "Button", _sb(Color(text, 0.14), Color(text, 0.06), 18, 12, 4))
	t.set_stylebox("focus", "Button", _sb(Color(text, 0.06), accent, 18, 12, 6))
	t.set_stylebox("disabled", "Button", _sb(Color(text, 0.03), Color(0, 0, 0, 0), 18, 12, 0))
	t.set_stylebox("normal", "OptionButton", _sb(Color(text, 0.06), Color(text, 0.04), 18, 12, 6))
	t.set_stylebox("hover", "OptionButton", _sb(Color(text, 0.10), Color(text, 0.05), 18, 12, 6))
	t.set_stylebox("pressed", "OptionButton", _sb(Color(text, 0.14), Color(text, 0.06), 18, 12, 4))
	t.set_stylebox("focus", "OptionButton", _sb(Color(text, 0.06), accent, 18, 12, 6))
	t.set_stylebox("disabled", "OptionButton", _sb(Color(text, 0.03), Color(0, 0, 0, 0), 18, 12, 0))

	# Поля ввода
	t.set_stylebox("normal", "LineEdit", _sb(input, border, 14, 12, 2))
	t.set_stylebox("focus", "LineEdit", _sb(Color(input, 1.0), accent, 14, 12, 2))
	t.set_stylebox("read_only", "LineEdit", _sb(Color(input, 0.6), border, 14, 12, 0))

	# Ползунки
	t.set_stylebox("slider", "Slider", _track_sb())
	t.set_stylebox("grabber_area", "Slider", _track_hl_sb())
	t.set_stylebox("grabber_area_highlight", "Slider", _track_hl_sb())
	t.set_stylebox("grabber", "Slider", _grabber_sb())
	t.set_stylebox("grabber_highlight", "Slider", _grabber_sb())

	# Прогресс-бары
	t.set_stylebox("background", "ProgressBar", _bar_bg_sb())
	t.set_stylebox("fill", "ProgressBar", _bar_fill_sb())

	# Выпадающее меню
	t.set_stylebox("panel", "PopupMenu", _sb(Color(bg_soft, 0.96), border, 18, 8, 18))
	t.set_stylebox("hover", "PopupMenu", _sb(accent_soft, Color(0, 0, 0, 0), 12, 8, 0))
	t.set_stylebox("separator", "PopupMenu", _sb(border, Color(0, 0, 0, 0), 2, 0, 0))

	# Скроллбар
	t.set_stylebox("grabber", "ScrollBar", _sb(Color(text, 0.28), Color(0, 0, 0, 0), 5, 2, 0))
	t.set_stylebox("grabber_highlight", "ScrollBar", _sb(Color(text, 0.36), Color(0, 0, 0, 0), 5, 2, 0))

	# Окна и диалоги
	var win := _sb(Color(bg_soft, 0.98), border, 24, 0, 22)
	win.shadow_offset = Vector2(0, 10)
	t.set_stylebox("panel", "Window", win)
	return t


func _sb(bg_color: Color, border_color: Color, radius: int, margins: int, shadow_size: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(1 if border_color.a > 0.0 else 0)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margins)
	if shadow_size > 0:
		sb.shadow_color = shadow
		sb.shadow_size = shadow_size
		sb.shadow_offset = Vector2(0, 3)
	return sb


func _track_sb() -> StyleBoxFlat:
	var sb := _sb(Color(text, 0.14), Color(0, 0, 0, 0), 5, 0, 0)
	sb.set_content_margin(SIDE_TOP, 3)
	sb.set_content_margin(SIDE_BOTTOM, 3)
	return sb


func _track_hl_sb() -> StyleBoxFlat:
	var sb := _sb(Color(accent, 0.30), Color(0, 0, 0, 0), 5, 0, 0)
	sb.set_content_margin(SIDE_TOP, 3)
	sb.set_content_margin(SIDE_BOTTOM, 3)
	return sb


func _grabber_sb() -> StyleBoxFlat:
	return _sb(accent, Color(1, 1, 1, 0.5), 10, 10, 8)


func _bar_bg_sb() -> StyleBoxFlat:
	var sb := _sb(Color(text, 0.10), Color(0, 0, 0, 0), 8, 0, 0)
	sb.set_content_margin(SIDE_TOP, 3)
	sb.set_content_margin(SIDE_BOTTOM, 3)
	return sb


func _bar_fill_sb() -> StyleBoxFlat:
	var sb := _sb(accent, Color(1, 1, 1, 0.4), 8, 0, 4)
	sb.shadow_offset = Vector2(0, 1)
	return sb
