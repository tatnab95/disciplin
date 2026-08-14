extends Control
## Тепловая карта привычек: последние 35 дней в сетке 5 недель x 7 дней.
## set_values() принимает массив из float 0..1 (самые старые дни первыми).

var values: Array = []
var _colors: Array = []


func _ready() -> void:
	ThemeManager.theme_changed.connect(_on_theme_changed)


func _on_theme_changed() -> void:
	_colors = []
	queue_redraw()


func set_values(v: Array) -> void:
	values = v
	_colors = []
	queue_redraw()


func _ensure_colors() -> void:
	if not _colors.is_empty():
		return
	var base := ThemeManager.accent
	for i in range(5):
		_colors.append(base.darkened(0.8 - i * 0.2))


func _draw() -> void:
	_ensure_colors()
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
