extends Node

## Выбор фото с камеры или из галереи.
## На Android используется плагин GodotGetImage, на десктопе — FileDialog.

signal picked(path: String)
signal failed(message: String)

const PLUGIN_NAME := "GodotGetImage"

var _plugin = null
var _dialog: FileDialog


func _ready() -> void:
	if Engine.has_singleton(PLUGIN_NAME):
		_plugin = Engine.get_singleton(PLUGIN_NAME)
		if _plugin != null:
			_plugin.setOptions({"auto_rotate_image": true, "image_quality": 85})
			_plugin.connect("image_request_completed", _on_plugin_image)
			_plugin.connect("error", func(e: String) -> void: failed.emit(e))
			_plugin.connect("permission_not_granted_by_user", func(_p: String) -> void: failed.emit("permission"))


func is_camera_available() -> bool:
	return _plugin != null


func capture() -> void:
	if _plugin != null:
		_plugin.getCameraImage()
	else:
		_open_dialog()


func pick() -> void:
	if _plugin != null:
		_plugin.getGalleryImage()
	else:
		_open_dialog()


func _open_dialog() -> void:
	if _dialog == null:
		_dialog = FileDialog.new()
		_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Изображения"])
		_dialog.file_selected.connect(_on_dialog_selected)
		add_child(_dialog)
	_dialog.popup_centered()


func _on_dialog_selected(path: String) -> void:
	var stored := _store_photo(path)
	if stored.is_empty():
		failed.emit("photo_error")
		return
	picked.emit(stored)


func _on_plugin_image(result: Dictionary) -> void:
	var buffers: Array[PackedByteArray] = []
	for key in result:
		var v: Variant = result[key]
		if v is PackedByteArray and (v as PackedByteArray).size() > 0:
			buffers.append(v as PackedByteArray)
	if buffers.is_empty():
		failed.emit("photo_error")
		return
	var img := Image.new()
	if img.load_jpg_from_buffer(buffers[0]) != OK:
		failed.emit("photo_error")
		return
	var path := _save_image(img)
	if path.is_empty():
		failed.emit("photo_error")
		return
	picked.emit(path)


func _store_photo(src: String) -> String:
	var img: Image = Image.load_from_file(src)
	if img == null:
		return ""
	return _save_image(img)


func _save_image(img: Image) -> String:
	DirAccess.make_dir_recursive_absolute("user://photos")
	var dst := "user://photos/%d.jpg" % Time.get_unix_time_from_system()
	var f := FileAccess.open(dst, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_buffer(img.save_jpg_to_buffer(0.85))
	return dst
