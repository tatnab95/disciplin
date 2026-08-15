extends Node

## Распознавание еды по фото через OpenAI-совместимый vision API.
## Ключ вводит сам пользователь в настройках. Без ключа приложение
## работает в режиме ручного ввода еды.

const VISION_PROMPT := "Analyze the food in this photo. Return ONLY a JSON object, no markdown, no comments: {\"items\":[{\"name\":\"...\",\"category\":\"protein|veg|carbs|fruit|dairy|fat|sweets|drink|other\",\"grams\":150,\"calories\":250,\"protein\":20,\"fat\":8,\"carbs\":30}]}. Estimate portions and nutrition per serving. If no food is visible, return {\"items\":[]}."

const VALID_CATEGORIES := ["protein", "veg", "carbs", "fruit", "dairy", "fat", "sweets", "drink", "other"]

var _req: HTTPRequest
var _pending: Callable = Callable()


func _ready() -> void:
	_req = HTTPRequest.new()
	_req.timeout = 60
	add_child(_req)
	_req.request_completed.connect(_on_completed)


func is_configured() -> bool:
	var provider := str(DataManager.get_setting("vision_provider", "openai"))
	if provider == "ollama":
		return not str(DataManager.get_setting("vision_base_url", "")).strip_edges().is_empty()
	var k: String = str(DataManager.get_setting("vision_api_key", ""))
	return not k.strip_edges().is_empty()


func recognize_image(path: String, on_done: Callable) -> void:
	if not is_configured():
		on_done.call({"ok": false, "error": "no_api_key"})
		return
	var img := _prepare_image(path)
	if img == null:
		on_done.call({"ok": false, "error": "cant_read_image"})
		return
	_send_request(img, VISION_PROMPT, 700, 0.1, on_done)


func ask_vision(path: String, prompt: String, on_done: Callable) -> void:
	if not is_configured():
		on_done.call({"ok": false, "error": "no_api_key"})
		return
	var img := _prepare_image(path)
	if img == null:
		on_done.call({"ok": false, "error": "cant_read_image"})
		return
	_send_request(img, prompt, 500, 0.9, on_done)


func _prepare_image(path: String) -> Image:
	var img: Image = Image.load_from_file(path)
	if img == null:
		return null
	if img.get_width() > 1024 or img.get_height() > 1024:
		var scale := minf(1024.0 / img.get_width(), 1024.0 / img.get_height())
		var new_w := int(round(img.get_width() * scale))
		var new_h := int(round(img.get_height() * scale))
		img = img.duplicate()
		img.resize(new_w, new_h, Image.INTERPOLATE_LANCZOS)
	return img


func _send_request(img: Image, prompt: String, max_tokens: int, temperature: float, on_done: Callable) -> void:
	var b64 := Marshalls.raw_to_base64(img.save_jpg_to_buffer(0.85))
	var payload := {
		"model": str(DataManager.get_setting("vision_model", "gpt-4o-mini")),
		"max_tokens": max_tokens,
		"temperature": temperature,
		"messages": [
			{
				"role": "user",
				"content": [
					{"type": "text", "text": prompt},
					{"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,%s" % b64}},
				],
			}
		],
	}
	var base: String = str(DataManager.get_setting("vision_base_url", "https://api.openai.com/v1"))
	var url := "%s/chat/completions" % base.trim_suffix("/")
	var key: String = str(DataManager.get_setting("vision_api_key", ""))
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % key,
	]
	_pending = on_done
	var err := _req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		_finish({"ok": false, "error": "http_error"})


func _on_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_finish({"ok": false, "error": "network_error", "code": result})
		return
	if response_code != 200:
		_finish({"ok": false, "error": "http_%d" % response_code})
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		_finish({"ok": false, "error": "bad_response"})
		return
	var content := _extract_content(parsed)
	if content.is_empty():
		_finish({"ok": false, "error": "empty_content"})
		return
	_finish({"ok": true, "text": content, "items": _extract_items(content)})


func _extract_content(parsed: Dictionary) -> String:
	var choices = parsed.get("choices", [])
	if not (choices is Array) or choices.size() == 0:
		return ""
	var msg = choices[0].get("message", {})
	if not (msg is Dictionary):
		return ""
	return str(msg.get("content", ""))


func _extract_items(content: String) -> Array:
	var cleaned := content.strip_edges()
	if cleaned.begins_with("```"):
		var lines := cleaned.split("\n")
		lines.remove_at(0)
		if not lines.is_empty() and lines[-1].begins_with("```"):
			lines.remove_at(lines.size() - 1)
		cleaned = "\n".join(lines).strip_edges()
	var parsed: Variant = JSON.parse_string(cleaned)
	if not (parsed is Dictionary):
		var start := cleaned.find("{")
		var end := cleaned.rfind("}")
		if start >= 0 and end > start:
			parsed = JSON.parse_string(cleaned.substr(start, end - start + 1))
	var items: Array = []
	if parsed is Dictionary:
		var raw = parsed.get("items", [])
		if raw is Array:
			for it in raw:
				if it is Dictionary:
					items.append(_sanitize_item(it))
	return items


func _sanitize_item(it: Dictionary) -> Dictionary:
	var name: String = str(it.get("name", ""))
	var cat: String = str(it.get("category", "other")).to_lower()
	if not VALID_CATEGORIES.has(cat):
		cat = "other"
	return {
		"name": name,
		"category": cat,
		"grams": int(it.get("grams", 0)),
		"calories": int(it.get("calories", 0)),
		"protein": float(it.get("protein", 0.0)),
		"fat": float(it.get("fat", 0.0)),
		"carbs": float(it.get("carbs", 0.0)),
	}


func _finish(result: Dictionary) -> void:
	var cb := _pending
	_pending = Callable()
	if cb.is_valid():
		cb.call(result)
