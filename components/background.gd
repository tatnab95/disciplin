extends Control
## Фон: мягкий вертикальный градиент + размытые цветные пятна
## (в духе обоев Android 16). Прозрачность достигается полупрозрачными
## карточками поверх этого фона.

var _gradient_tex: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeManager.theme_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var g := Gradient.new()
	g.set_color(0, ThemeManager.bg_top)
	g.set_color(1, ThemeManager.bg_bottom)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 128
	tex.height = 256
	_gradient_tex = tex
	queue_redraw()


func _draw() -> void:
	if _gradient_tex:
		draw_texture_rect(_gradient_tex, Rect2(Vector2.ZERO, size), false)
	var t := ThemeManager
	var w := maxf(size.x, 1.0)
	var h := maxf(size.y, 1.0)
	draw_circle(Vector2(w * 0.16, h * 0.12), w * 0.42, t.accent_soft)
	draw_circle(Vector2(w * 0.90, h * 0.28), w * 0.34, t.blob2)
	draw_circle(Vector2(w * 0.05, h * 0.78), w * 0.46, t.blob3)
	draw_circle(Vector2(w * 0.82, h * 0.95), w * 0.36, t.blob4)
