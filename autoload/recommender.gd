extends Node

## Офлайн-движок рекомендаций и дневной оценки (score).
## Правила опираются на day_summary() из DataManager.

signal updated

const MAX_RECS := 5


func refresh() -> void:
	updated.emit()


func get_recommendations() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var today := TimeManager.today_str()
	var s := DataManager.day_summary(today)
	var user_settings := DataManager.get_settings()
	var sleep_target: float = float(user_settings.get("sleep_target_hours", 8.0))
	var game_limit: int = int(user_settings.get("game_limit_minutes", 120))

	if not s.has_checkin:
		out.append(_rec(90, "rec_checkin", "checkin"))

	var hours_sum := 0.0
	var hours_cnt := 0
	for i in range(3):
		var ds := DataManager.day_summary(TimeManager.add_days(today, -i))
		if ds.has_sleep and ds.sleep_hours > 0:
			hours_sum += ds.sleep_hours
			hours_cnt += 1
	if hours_cnt > 0:
		var avg := hours_sum / hours_cnt
		if avg < sleep_target - 0.5:
			var deficit := int((sleep_target - avg) * 60)
			out.append(_rec(80, "rec_sleep_short", "sleep", {"v": tr("h_duration_min").format({"m": deficit})}))

	if s.has_checkin and s.fatigue >= 7:
		out.append(_rec(70, "rec_rest", "rest"))

	if s.game_min >= game_limit:
		out.append(_rec(75, "rec_too_much_game", "game", {"v": TimeManager.format_duration(s.game_min)}))

	var last_sport := -1
	for i in range(4):
		if DataManager.day_summary(TimeManager.add_days(today, -i)).sport_min > 0:
			last_sport = i
			break
	if s.sport_min == 0 and (last_sport == -1 or last_sport >= 2):
		out.append(_rec(65, "rec_sport", "sport", {"v": str(maxi(1, last_sport))}))

	if s.protein < 60.0:
		out.append(_rec(60, "rec_protein", "food", {"v": "%.0f" % s.protein}))

	if s.meal_count == 0:
		out.append(_rec(55, "rec_log_food", "food"))

	out.sort_custom(func(a, b): return a["priority"] > b["priority"])
	return out.slice(0, MAX_RECS)


func compute_today_score() -> Dictionary:
	var today := TimeManager.today_str()
	var s := DataManager.day_summary(today)
	var user_settings := DataManager.get_settings()
	var parts := {}
	var total := 0.0
	var weights := 0.0

	if s.habits_total > 0:
		var h: float = 100.0 * s.habits_done / s.habits_total
		parts["habits"] = h
		total += 25.0 * h / 100.0
		weights += 25.0

	if s.has_checkin:
		parts["checkin"] = 100.0
		total += 15.0
	else:
		parts["checkin"] = 0.0
	weights += 15.0

	if s.has_sleep:
		var ratio := clampf(s.sleep_hours / sleep_target_avg(user_settings), 0.0, 1.0)
		var sp := 100.0 * ratio
		parts["sleep"] = sp
		total += 20.0 * ratio
	else:
		parts["sleep"] = 0.0
	weights += 20.0

	if s.meal_count > 0:
		var fp := 60.0 + minf(40.0, 40.0 * s.protein / 80.0)
		parts["food"] = fp
		total += 20.0 * fp / 100.0
	else:
		parts["food"] = 0.0
	weights += 20.0

	if s.sport_min > 0:
		parts["sport"] = 100.0
		total += 20.0
	else:
		parts["sport"] = 0.0
	weights += 20.0

	var game_limit := float(user_settings.get("game_limit_minutes", 120))
	var game_ratio := clampf(float(s.game_min) / game_limit, 0.0, 2.0)
	var gs := 0.0
	if game_ratio <= 1.0:
		gs = 100.0 - 30.0 * game_ratio
	else:
		gs = 40.0
	parts["game"] = gs
	total += 15.0 * gs / 100.0
	weights += 15.0

	var score := 0
	if weights > 0:
		score = int(round(total / weights * 100.0))
	return {"total": clampi(score, 0, 100), "parts": parts}


func _rec(priority: int, text_key: String, category: String, args: Dictionary = {}) -> Dictionary:
	var text := tr(text_key)
	if not args.is_empty():
		text = text.format(args)
	return {"priority": priority, "text": text, "key": text_key, "category": category}


func sleep_target_avg(settings: Dictionary) -> float:
	return float(settings.get("sleep_target_hours", 8.0))
