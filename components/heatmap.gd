extends Control
## Тепловая карта привычек: последние 35 дней в сетке 5 недель x 7 дней.
## set_values() принимает массив из float 0..1 (самые старые дни первыми).

var values: Array = []

var _colors := [
	Color("1b2127"),
	Color("223d31"),
	Color("2c5a43"),
	Color("3f7d5a"),
	Color("4cc38a"),
]


func set_values(v: Array) -> void:
	values = v
	queue_redraw()


func _draw() -> void:
	var cols := 5
	var rows := 7
	var cell := 14.0
	var gap := 3.0
	for i in values.size():
		var col := i / rows
		var row := i % rows
		var pos := Vector2(col * (cell + gap), row * (cell + gap))
		var ratio := clampf(values[i], 0.0, 1.0)
		var color: Color = _colors[0]
		if ratio > 0.0:
			color = _colors[clampi(int(ceil(ratio * 4.0)), 0, 4)]
		draw_rect(Rect2(pos, Vector2(cell, cell)), color)
