extends Control
## Простой самодельный график (без плагинов).
## set_data(series, labels, is_lines):
##   series: [{ "name": String, "color": Color, "values": Array }]
##   labels: подписи под точками/столбцами (необязательно)
##   is_lines: true — ломаные, false — столбцы

var series: Array = []
var labels: Array = []
var is_lines := false


func _ready() -> void:
	ThemeManager.theme_changed.connect(queue_redraw)


func set_data(s, l := [], lines := false) -> void:
	series = s
	labels = l
	is_lines = lines
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 11
	var grid_color: Color = ThemeManager.border
	var text_color: Color = ThemeManager.text_secondary
	var padding := 10
	var legend_h := 0
	if series.size() > 1:
		legend_h = 20
	var area := Rect2(padding, padding, size.x - padding * 2.0, size.y - padding * 2.0 - legend_h)
	var n := 0
	var max_v := 1.0
	for s in series:
		var vals: Array = s["values"]
		n = maxi(n, vals.size())
		for v in vals:
			max_v = maxf(max_v, float(v))
	if n == 0:
		return
	for i in range(4):
		var y := area.position.y + area.size.y * i / 3.0
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(grid_color, 0.5), 1.0)
	if not labels.is_empty():
		for i in labels.size():
			var text := str(labels[i])
			var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
			var x := area.position.x + area.size.x * (i + 0.5) / n
			draw_string(font, Vector2(x - tw / 2.0, area.end.y + font_size + 4.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
	if is_lines:
		for s in series:
			var vals: Array = s["values"]
			if vals.size() < 2:
				continue
			var pts := PackedVector2Array()
			for i in vals.size():
				var x := area.position.x + area.size.x * (i + 0.5) / n
				var y := area.end.y - area.size.y * (float(vals[i]) / max_v)
				pts.push_back(Vector2(x, y))
			draw_polyline(pts, s["color"], 2.0, true)
	else:
		for s in series:
			var vals: Array = s["values"]
			for i in n:
				var v := clampf(float(vals[i]) if i < vals.size() else 0.0, 0.0, max_v)
				var h := maxf(1.0, area.size.y * (v / max_v))
				var bw := area.size.x / n * 0.6
				var x := area.position.x + area.size.x * i / n + (area.size.x / n - bw) / 2.0
				draw_rect(Rect2(x, area.end.y - h, bw, h), s["color"])
	if series.size() > 1:
		var legend_y := size.y - legend_h / 2.0 - 2.0
		var x := padding
		for s in series:
			var tw := font.get_string_size(str(s["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_rect(Rect2(x, legend_y - 8, 10, 10), s["color"])
			draw_string(font, Vector2(x + 14, legend_y + font_size * 0.35), str(s["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
			x += 14 + tw + 14
