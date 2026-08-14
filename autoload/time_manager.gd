extends Node

## Утилиты времени: даты, минуты, расчёт сна, расписание.

func today_str() -> String:
	return Time.get_date_string_from_system()


func now_minutes() -> int:
	var d := Time.get_time_dict_from_system()
	return int(d["hour"]) * 60 + int(d["minute"])


func now_hhmm() -> String:
	var d := Time.get_time_dict_from_system()
	return "%02d:%02d" % [int(d["hour"]), int(d["minute"])]


func current_hour() -> int:
	var d := Time.get_time_dict_from_system()
	return int(d["hour"])


func time_to_minutes(hhmm: String) -> int:
	var parts := hhmm.split(":")
	if parts.size() < 2:
		return -1
	return int(parts[0]) * 60 + int(parts[1])


func minutes_to_time(m: int) -> String:
	m = maxi(0, m)
	return "%02d:%02d" % [m / 60, m % 60]


func sleep_hours(bedtime: String, wake: String) -> float:
	var bt := time_to_minutes(bedtime)
	var wk := time_to_minutes(wake)
	if bt < 0 or wk < 0:
		return 0.0
	var mins := wk - bt
	if mins <= 0:
		mins += 1440
	return mins / 60.0


func add_days(date_str: String, days: int) -> String:
	var p := date_str.split("-")
	if p.size() != 3:
		return date_str
	var d := Time.get_datetime_dict_from_datetime_string("%s 00:00:00" % date_str, false)
	var unix := Time.get_unix_time_from_datetime_dict(d)
	unix += days * 86400
	return Time.get_date_string_from_unix_time(unix)


func weekday_num(date_str: String) -> int:
	var p := date_str.split("-")
	if p.size() != 3:
		return 1
	var d := Time.get_datetime_dict_from_datetime_string("%s 00:00:00" % date_str, false)
	var unix := Time.get_unix_time_from_datetime_dict(d)
	var dt := Time.get_datetime_dict_from_unix_time(unix)
	return ((int(dt["weekday"]) + 6) % 7) + 1


func format_duration(total_minutes: int) -> String:
	var m := maxi(0, total_minutes)
	var h := m / 60
	var mm := m % 60
	if h > 0 and mm > 0:
		return "%d %s %d %s" % [h, tr("h_unit"), mm, tr("min_unit")]
	if h > 0:
		return "%d %s" % [h, tr("h_unit")]
	return "%d %s" % [mm, tr("min_unit")]


func format_date_short(date_str: String) -> String:
	var p := date_str.split("-")
	if p.size() != 3:
		return date_str
	var m := int(p[1])
	var month_names := tr("month_names").split(",")
	if m < 1 or m > 12 or month_names.size() < m:
		return date_str
	return "%d %s" % [int(p[2]), month_names[m - 1]]


## Возвращает текущий слот расписания: {"current": entry, "next": entry, "minutes": int}
func current_slot(schedule: Array) -> Dictionary:
	var now := now_minutes()
	var current := {}
	var next := {}
	var best := -1
	var sorted_items: Array = []
	for e in schedule:
		var t := time_to_minutes(str(e.get("time", "")))
		if t < 0:
			continue
		sorted_items.append({"time": t, "entry": e})
	sorted_items.sort_custom(func(a, b): return a["time"] < b["time"])
	for item in sorted_items:
		if item["time"] <= now:
			if item["time"] > best:
				best = item["time"]
				current = item["entry"]
		elif next.is_empty():
			next = item["entry"]
	return {"current": current, "next": next, "minutes": now}
