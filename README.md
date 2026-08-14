# Disciplin

Бесплатное приложение самодисциплины на **Godot 4.7** (GDScript). Помогает следить за привычками, расписанием дня, сном, усталостью, балансом «игры vs спорт» и питанием — с фокусом на **спорт и еду**. Открытый код, MIT-лицензия, можно использовать бесплатно.

Free open-source self-discipline app made with **Godot 4.7** (GDScript). Tracks habits, daily schedule, sleep, fatigue, "gaming vs sport" balance and nutrition — with a focus on **sport and food**. MIT licensed, free for everyone.

---

## Возможности / Features

- 📋 **Привычки / Habits** — чек-лист с сериями (streak)
- 🗓 **Расписание дня / Daily planner** — слоты времени, показывает, что делать сейчас
- 😴 **Сон / Sleep** — время отбоя/подъёма, качество, долг сна
- ⚡ **Чек-ин / Check-in** — энергия, усталость, настроение (1–10)
- 🍔 **Еда / Food** — ручной ввод из каталога продуктов (БЖУ) или фото → ИИ-распознавание (API по желанию)
- 🏋️ **Спорт / Sport** — лог тренировок и недельные цели
- 🎮 **Таймеры / Timers** — сколько играешь/занимаешься/учишься/работаешь
- 🤖 **Рекомендации / Recommendations** — офлайн-движок: что сделать, когда высыпаться, тренироваться и есть белок
- 📊 **Статистика / Stats** — графики за 7/30 дней
- ⚙️ **Настройки / Settings** — язык, цели (сон, игры, спорт, вода), ИИ-ключ
- 🌍 **RU / EN** — локализация
- 💾 **Данные локально / Local data** — `user://data.json` + экспорт/импорт/сброс

## Установка / Install

1. Скачай [Godot 4.7](https://godotengine.org/) (стандартная сборка).
2. Открой проект: Godot → Import → выбери папку `disciplin`.
3. Нажми **F5** для запуска.

## ИИ-распознавание еды (опционально) / AI food recognition (optional)

Приложение работает полностью без ключей. Чтобы распознавать еду по фото:

1. Получи ключ у любого OpenAI-совместимого API (например [OpenAI](https://platform.openai.com/) или локальный Ollama/LM Studio endpoint).
2. В настройках приложения укажи: ключ, base URL (`https://api.openai.com/v1` по умолчанию) и модель.
3. Фото еды → распознанные продукты и оценка калорий/БЖУ сохраняются автоматически.

Ключ хранится только локально на устройстве и никуда не отправляется, кроме вашего API-провайдера.

## Сборка / Export

Пресеты: Windows, Linux, Android (в `export_presets.cfg`). Для Android установи Android Build Template в Godot-редакторе.

## Структура / Structure

```
autoload/    — DataManager (JSON), TimeManager, ActivityTracker, Recommender, FoodRecognizer
scenes/      — экраны (главное меню, дашборд, привычки, еда, спорт, …)
scripts/     — логика UI
data/        — каталог продуктов (БЖУ)
localization/— переводы (.po)
assets/      — тема
```

## Лицензия / License

[MIT](LICENSE) — делай что хочешь, используй бесплатно, форкай, контрибьють.

---

Made with ❤️ for people who want to get their life together. [Contributions welcome](https://github.com/tatnab95/disciplin).
