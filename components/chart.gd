extends Control
## Простой самодельный график (без плагинов).
## set_data(series, labels, is_lines):
##   series: [{ "name": String, "color": Color, "values": Array }]
##   labels: Array[String] — подпись для каждого столбца/точки

var series: Array = []
var labels: Array = []
var lines := false

var grid_color := Color(0.2, 0.24, 0.28, 1.0)
var text_color := Color("8b949e")
var font_size := 12


func set_data(s: Array, l: Array, is_lines := false) -> void:
	series = s
	labels = l
	lines = is_lines
	queue_redraw()


func _draw() -> void:
	if series.is_empty():
		return
	var n := 0
	for s in series:
		n = maxi(n, (s["values"] as Array).size())
	if n == 0:
		return
	var max_v := 1.0
	for s in series:
		for v in s["values"]:
			max_v = maxf(max_v, float(v))

	var pad_left := 6.0
	var pad_top := 22.0
	var pad_bottom := 26.0
	var area := Rect2(pad_left, pad_top, maxf(1.0, size.x - pad_left * 2.0), maxf(1.0, size.y - pad_top - pad_bottom))

	# сетка
	var steps := 4
	for g in range(steps + 1):
		var ratio := float(g) / float(steps)
		var y := area.position.y + area.size.y * ratio
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), grid_color, 1.0, true)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(pad_left, 14), "%d" % int(max_v), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	draw_string(font, Vector2(pad_left, size.y - 8), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

	if lines:
		for s in series:
			var vals: Array = s["values"]
			if vals.size() < 2:
				continue
			var pts := PackedVector2Array()
			for i in vals.size():
				var x := area.position.x + area.size.x * (i + 0.5) / n
				var y := area.end.y - area.size.y * (float(vals[i]) / max_v)
				pts.append(Vector2(x, y))
			draw_polyline(pts, s["color"], 2.5, true)
	else:
		var slot := area.size.x / n
		var bar_w := maxf(2.0, slot * 0.6 / series.size())
		for i in n:
			for si in series.size():
				var s: Dictionary = series[si]
				var v := clampf(float(s["values"][i]), 0.0, max_v)
				var bh := area.size.y * (v / max_v)
				var x := area.position.x + i * slot + slot * 0.2 + si * bar_w
				draw_rect(Rect2(x, area.end.y - bh, bar_w, bh), s["color"])

	# подписи по X
	var step := maxi(1, int(ceil(n / 7.0)))
	for i in n:
		if i % step != 0 and i != n - 1:
			continue
		if labels.size() > i:
			var x := area.position.x + area.size.x * (i + 0.5) / n
			var text := str(labels[i])
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
			draw_string(font, Vector2(clampf(x - w / 2.0, 0, size.x - w), size.y - 6), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
