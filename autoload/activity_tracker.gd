extends Node

## Таймеры активностей: игры / спорт / учёба / работа / отдых.
## Старт/стоп в приложении; при остановке сессия сохраняется в DataManager.

signal timer_started(type: String)
signal timer_stopped(type: String, duration: int)

const ACTIVITY_TYPES := ["game", "sport", "study", "work", "rest"]

var _started: Dictionary = {}


func is_running(type: String) -> bool:
	return _started.has(type)


func running_seconds(type: String) -> int:
	if not _started.has(type):
		return 0
	return int(Time.get_unix_time_from_system()) - int(_started[type])


func start(type: String) -> void:
	if _started.has(type):
		return
	_started[type] = int(Time.get_unix_time_from_system())
	timer_started.emit(type)


func stop(type: String) -> int:
	if not _started.has(type):
		return 0
	var start: int = _started[type]
	var now := int(Time.get_unix_time_from_system())
	_started.erase(type)
	DataManager.add_session(type, start, now)
	timer_stopped.emit(type, now - start)
	return now - start


func toggle(type: String) -> int:
	if is_running(type):
		return stop(type)
	start(type)
	return 0


func stop_all() -> Dictionary:
	var stopped := {}
	for t in _started.keys():
		stopped[t] = stop(t)
	return stopped
