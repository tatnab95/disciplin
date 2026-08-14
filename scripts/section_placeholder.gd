extends Control

## Временная заглушка для разделов, которые ещё в разработке.

@export var title_key := ""


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("121417")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
	add_child(vb)

	var title := Label.new()
	title.text = tr(title_key)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("e6edf3"))
	vb.add_child(title)

	var soon := Label.new()
	soon.text = tr("coming_soon")
	soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soon.add_theme_color_override("font_color", Color("8b949e"))
	vb.add_child(soon)

	var back := Button.new()
	back.text = tr("back")
	back.custom_minimum_size = Vector2(200, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	vb.add_child(back)
