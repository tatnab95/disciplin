extends Control

const SECTIONS := [
	["dashboard", "menu_dashboard"],
	["habits", "menu_habits"],
	["planner", "menu_planner"],
	["sleep", "menu_sleep"],
	["checkin", "menu_checkin"],
	["food", "menu_food"],
	["sport", "menu_sport"],
	["stats", "menu_stats"],
	["settings", "menu_settings"],
]

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var grid: GridContainer = %Grid
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	title_label.text = tr("app_title")
	subtitle_label.text = tr("app_subtitle")
	version_label.text = tr("menu_version").format({"v": "0.2.0"})
	for s in SECTIONS:
		var btn := Button.new()
		btn.text = tr(s[1])
		btn.custom_minimum_size = Vector2(200, 60)
		btn.pressed.connect(_open.bind(s[0]))
		grid.add_child(btn)


func _open(section: String) -> void:
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % section)
