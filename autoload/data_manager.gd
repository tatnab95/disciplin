extends Node

## Центральное хранилище данных приложения.
## Все данные лежат в user://data.json (JSON, легко переносить и править).
## Фото еды сохраняются в user://photos/.

signal data_changed

const DATA_PATH := "user://data.json"
const PHOTO_DIR := "user://photos"
const DATA_VERSION := 1

const SECTIONS := ["habits", "schedule", "sleep", "checkins", "sessions", "meals", "trainings"]

var data: Dictionary = {}

var _foods: Array = []
var _foods_loaded := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(PHOTO_DIR)
	load_data()


func load_data() -> void:
	var parsed: Variant = null
	if FileAccess.file_exists(DATA_PATH):
		var f := FileAccess.open(DATA_PATH, FileAccess.READ)
		if f:
			parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed
	else:
		data = _default_data()
	_migrate()
	_ensure_structures()
	apply_language()
	save_data()
	data_changed.emit()


func save_data() -> void:
	var f := FileAccess.open(DATA_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
	data_changed.emit()


# ---------------------------------------------------------------------------
# Настройки и язык
# ---------------------------------------------------------------------------

func get_settings() -> Dictionary:
	return data.get("settings", {})


func get_setting(key: String, default: Variant = null) -> Variant:
	return get_settings().get(key, default)


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	if key == "lang":
		apply_language()
	save_data()


func set_lang(code: String) -> void:
	set_setting("lang", code)


func apply_language() -> void:
	var lang: String = str(get_setting("lang", "ru"))
	TranslationServer.set_locale(lang)


# ---------------------------------------------------------------------------
# Общие операции с записями
# ---------------------------------------------------------------------------

func today_str() -> String:
	return TimeManager.today_str()


func new_id() -> String:
	return "%d_%d" % [Time.get_unix_time_from_system(), randi()]


func get_section(section: String) -> Array:
	return data.get(section, [])


func add_record(section: String, record: Dictionary) -> Dictionary:
	if not record.has("id"):
		record["id"] = new_id()
	get_section(section).append(record)
	save_data()
	return record


func get_record(section: String, id: String) -> Dictionary:
	for r in get_section(section):
		if r.get("id", "") == id:
			return r
	return {}


func update_record(section: String, id: String, record: Dictionary) -> void:
	var arr := get_section(section)
	for i in arr.size():
		if arr[i].get("id", "") == id:
			arr[i] = record
			save_data()
			return


func remove_record(section: String, id: String) -> void:
	var arr := get_section(section)
	for i in arr.size():
		if arr[i].get("id", "") == id:
			arr.remove_at(i)
			save_data()
			return


func find_by_date(section: String, date: String) -> Dictionary:
	for r in get_section(section):
		if r.get("date", "") == date:
			return r
	return {}


# ---------------------------------------------------------------------------
# Привычки
# ---------------------------------------------------------------------------

func get_habits() -> Array:
	return get_section("habits")


func add_habit(habit: Dictionary) -> Dictionary:
	habit["history"] = {}
	habit["order"] = get_habits().size()
	return add_record("habits", habit)


func is_habit_done(habit_id: String, date: String) -> bool:
	var h := get_record("habits", habit_id)
	return bool(h.get("history", {}).get(date, false))


func set_habit_done(habit_id: String, date: String, done: bool) -> void:
	var h := get_record("habits", habit_id)
	if h.is_empty():
		return
	h["history"][date] = done
	update_record("habits", habit_id, h)


func habit_streak(habit_id: String) -> int:
	var h := get_record("habits", habit_id)
	if h.is_empty():
		return 0
	var hist: Dictionary = h.get("history", {})
	var streak := 0
	var date := today_str()
	if not bool(hist.get(date, false)):
		date = TimeManager.add_days(date, -1)
	while bool(hist.get(date, false)):
		streak += 1
		date = TimeManager.add_days(date, -1)
	return streak


func habit_done_dates(habit_id: String) -> Array:
	var h := get_record("habits", habit_id)
	if h.is_empty():
		return []
	var out: Array = []
	var hist: Dictionary = h.get("history", {})
	for date in hist:
		if bool(hist[date]):
			out.append(date)
	return out


# ---------------------------------------------------------------------------
# Сон и чек-ин
# ---------------------------------------------------------------------------

func set_sleep(bedtime: String, wake: String, quality: int) -> Dictionary:
	var date := today_str()
	var rec := find_by_date("sleep", date)
	if rec.is_empty():
		rec = {"id": new_id(), "date": date, "bedtime": bedtime, "wake": wake, "quality": quality}
		get_section("sleep").append(rec)
	else:
		rec["bedtime"] = bedtime
		rec["wake"] = wake
		rec["quality"] = quality
	save_data()
	return rec


func set_checkin(energy: int, fatigue: int, mood: int) -> Dictionary:
	var date := today_str()
	var rec := find_by_date("checkins", date)
	if rec.is_empty():
		rec = {"id": new_id(), "date": date, "energy": energy, "fatigue": fatigue, "mood": mood}
		get_section("checkins").append(rec)
	else:
		rec["energy"] = energy
		rec["fatigue"] = fatigue
		rec["mood"] = mood
	save_data()
	return rec


# ---------------------------------------------------------------------------
# Активности (сессии игр/спорта/учёбы)
# ---------------------------------------------------------------------------

func add_session(type: String, start: int, end: int) -> Dictionary:
	var date := today_str()
	var rec := {
		"id": new_id(),
		"date": date,
		"type": type,
		"start": start,
		"end": end,
		"duration": maxi(0, end - start),
	}
	get_section("sessions").append(rec)
	save_data()
	return rec


# ---------------------------------------------------------------------------
# Еда и спорт
# ---------------------------------------------------------------------------

func add_meal(meal_type: String, time_hhmm: String, items: Array, photo_path: String, ai_summary: String) -> Dictionary:
	var date := today_str()
	var rec := {
		"id": new_id(),
		"date": date,
		"type": meal_type,
		"time": time_hhmm,
		"note": "",
		"photo": photo_path,
		"ai_summary": ai_summary,
		"items": items,
	}
	get_section("meals").append(rec)
	save_data()
	return rec


func add_training(training_type: String, duration_min: int, note: String) -> Dictionary:
	var date := today_str()
	var rec := {
		"id": new_id(),
		"date": date,
		"type": training_type,
		"duration": duration_min,
		"note": note,
	}
	get_section("trainings").append(rec)
	save_data()
	return rec


# ---------------------------------------------------------------------------
# Сводка дня — один источник для дашборда, статистики и рекомендаций
# ---------------------------------------------------------------------------

func day_summary(date: String) -> Dictionary:
	var s := {
		"date": date,
		"has_sleep": false,
		"sleep_hours": 0.0,
		"bedtime": "",
		"wake": "",
		"quality": 0,
		"has_checkin": false,
		"energy": 0,
		"fatigue": 0,
		"mood": 0,
		"game_min": 0,
		"sport_min": 0,
		"study_min": 0,
		"work_min": 0,
		"rest_min": 0,
		"meal_count": 0,
		"calories": 0.0,
		"protein": 0.0,
		"carbs": 0.0,
		"fat": 0.0,
		"habits_done": 0,
		"habits_total": 0,
		"training_count": 0,
		"training_min": 0,
	}

	var sleep_rec := find_by_date("sleep", date)
	if not sleep_rec.is_empty():
		s["has_sleep"] = true
		s["bedtime"] = str(sleep_rec.get("bedtime", ""))
		s["wake"] = str(sleep_rec.get("wake", ""))
		s["quality"] = int(sleep_rec.get("quality", 0))
		s["sleep_hours"] = TimeManager.sleep_hours(s["bedtime"], s["wake"])

	var check_rec := find_by_date("checkins", date)
	if not check_rec.is_empty():
		s["has_checkin"] = true
		s["energy"] = int(check_rec.get("energy", 0))
		s["fatigue"] = int(check_rec.get("fatigue", 0))
		s["mood"] = int(check_rec.get("mood", 0))

	for sess in get_section("sessions"):
		if sess.get("date", "") != date:
			continue
		var type: String = str(sess.get("type", ""))
		var mins := int(sess.get("duration", 0)) / 60
		var key := "%s_min" % type
		if s.has(key):
			s[key] += mins

	for meal in get_section("meals"):
		if meal.get("date", "") != date:
			continue
		s["meal_count"] += 1
		for it in meal.get("items", []):
			if it is Dictionary:
				s["calories"] += float(it.get("calories", 0.0))
				s["protein"] += float(it.get("protein", 0.0))
				s["carbs"] += float(it.get("carbs", 0.0))
				s["fat"] += float(it.get("fat", 0.0))

	for h in get_section("habits"):
		s["habits_total"] += 1
		if is_habit_done(h.get("id", ""), date):
			s["habits_done"] += 1

	for t in get_section("trainings"):
		if t.get("date", "") != date:
			continue
		s["training_count"] += 1
		s["training_min"] += int(t.get("duration", 0))

	return s


# ---------------------------------------------------------------------------
# Экспорт / импорт
# ---------------------------------------------------------------------------

func export_to_path(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


func import_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return false
	data = parsed
	_ensure_structures()
	save_data()
	return true


# ---------------------------------------------------------------------------
# Каталог продуктов
# ---------------------------------------------------------------------------

func get_foods_db() -> Array:
	if not _foods_loaded:
		_foods_loaded = true
		var f := FileAccess.open("res://data/foods_db.json", FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Array:
				_foods = parsed
	return _foods


func search_foods(query: String, limit := 20) -> Array:
	var q := query.strip_edges().to_lower()
	if q.is_empty():
		return get_foods_db().slice(0, limit)
	var out: Array = []
	for fd in get_foods_db():
		var name_ru: String = str(fd.get("name_ru", "")).to_lower()
		var name_en: String = str(fd.get("name_en", "")).to_lower()
		if name_ru.contains(q) or name_en.contains(q):
			out.append(fd)
			if out.size() >= limit:
				break
	return out


# ---------------------------------------------------------------------------
# Внутреннее
# ---------------------------------------------------------------------------

func _default_data() -> Dictionary:
	return {
		"version": DATA_VERSION,
		"settings": {
			"lang": "ru",
			"vision_api_key": "",
			"vision_base_url": "https://api.openai.com/v1",
			"vision_model": "gpt-4o-mini",
			"sleep_target_hours": 8.0,
			"game_limit_minutes": 120,
			"sport_goal_minutes": 240,
			"sport_goal_sessions": 3,
			"water_goal": 2000,
		},
		"habits": [
			{"id": "h_water", "name_key": "habit_water", "icon": "💧", "frequency": "daily", "history": {}},
			{"id": "h_breakfast", "name_key": "habit_breakfast", "icon": "🍳", "frequency": "daily", "history": {}},
			{"id": "h_sport", "name_key": "habit_sport", "icon": "🏋️", "frequency": "daily", "history": {}},
			{"id": "h_books", "name_key": "habit_books", "icon": "📚", "frequency": "daily", "history": {}},
			{"id": "h_no_games_morning", "name_key": "habit_no_games_morning", "icon": "🚫", "frequency": "daily", "history": {}},
			{"id": "h_vitamins", "name_key": "habit_vitamins", "icon": "💊", "frequency": "daily", "history": {}},
		],
		"schedule": [
			{"id": "s1", "time": "08:00", "name_key": "schedule_wake", "duration_min": 15},
			{"id": "s2", "time": "08:15", "name_key": "schedule_breakfast", "duration_min": 25},
			{"id": "s3", "time": "09:00", "name_key": "schedule_work", "duration_min": 180},
			{"id": "s4", "time": "12:00", "name_key": "schedule_lunch", "duration_min": 40},
			{"id": "s5", "time": "13:00", "name_key": "schedule_work", "duration_min": 180},
			{"id": "s6", "time": "17:00", "name_key": "schedule_sport", "duration_min": 60},
			{"id": "s7", "time": "18:30", "name_key": "schedule_dinner", "duration_min": 40},
			{"id": "s8", "time": "21:00", "name_key": "schedule_rest", "duration_min": 90},
			{"id": "s9", "time": "22:30", "name_key": "schedule_sleep", "duration_min": 0},
		],
		"sleep": [],
		"checkins": [],
		"sessions": [],
		"meals": [],
		"trainings": [],
	}


func _migrate() -> void:
	data["version"] = DATA_VERSION


func _ensure_structures() -> void:
	if not data.has("settings") or not (data["settings"] is Dictionary):
		data["settings"] = {}
	for sec in SECTIONS:
		if not data.has(sec) or not (data[sec] is Array):
			data[sec] = []
	var s := data["settings"]
	if not s.has("lang"):
		s["lang"] = "ru"
	if not s.has("vision_api_key"):
		s["vision_api_key"] = ""
	if not s.has("vision_base_url"):
		s["vision_base_url"] = "https://api.openai.com/v1"
	if not s.has("vision_model"):
		s["vision_model"] = "gpt-4o-mini"
	if not s.has("sleep_target_hours"):
		s["sleep_target_hours"] = 8.0
	if not s.has("game_limit_minutes"):
		s["game_limit_minutes"] = 120
	if not s.has("sport_goal_minutes"):
		s["sport_goal_minutes"] = 240
	if not s.has("sport_goal_sessions"):
		s["sport_goal_sessions"] = 3
	if not s.has("water_goal"):
		s["water_goal"] = 2000
