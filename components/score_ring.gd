extends Control
## Кольцо прогресса от 0 до 100.

var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 100.0)
		queue_redraw()

var fill_color := Color("4cc38a")
var track_color := Color("1b2127")
var text_color := Color("e6edf3")


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 8.0
	draw_circle(c, r, track_color)
	if value > 0.0:
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * value / 100.0, 64, fill_color, 8.0, true)
	var font := ThemeDB.fallback_font
	var font_size := 28
	var text := "%d" % int(round(value))
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	draw_string(font, Vector2(c.x - tw / 2.0, c.y + font_size * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
