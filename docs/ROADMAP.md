# Roadmap

Где проект сейчас и что дальше. Когда появятся GitHub Issues и milestones,
крупные пункты переедут туда, а здесь останутся ссылки.

## Запуск проекта

- [x] **1. Идея и границы** — `docs/VISION.md`. В 0.1.0 ядро и один модуль:
  Health bar above tooltip.
- [x] **2. Каркас репозитория** — папка аддона, `CHANGELOG.md`, `README.md`,
  `docs/DEVELOPMENT.md`, `.gitattributes`, `.editorconfig`.
  - [x] Файлы каркаса.
  - [x] Подключить аддон к Retail и Forever через junction, как в ret_ImmersiveScreen,
    и проверить, что `/rettl` печатает версию.
  - [x] Сверить `## Interface` в `.toc` с `/dump select(4, GetBuildInfo())`.
    Retail: 120105, Forever: 16001 — оба совпадают.
- [ ] **3. Бэклог в GitHub Issues** — метки `bug`, `feature`, `idea`,
  `needs-ingame-test`; milestone `v0.1.0`; задачи из VISION.md.
  Первая задача с меткой `needs-ingame-test`:
  - проверить Enemy player names in reaction color на игроках другой фракции:
    без PvP-флага и с ним, в своей зоне и на поле боя; имя краснеет сразу,
    как только игрока становится можно атаковать.

  Отложено: нужен GitHub CLI (`gh`), он пока не установлен.
- [x] **4. Архитектура ядра** — реестр модулей и твиков, окно с группами модулей
  и рабочей областью, кнопки отката, SavedVariables с версией схемы и миграциями,
  состояние «ждёт /reload». Описание — `docs/ARCHITECTURE.md`.
  - [x] Код ядра.
  - [x] Проверка в игре (Retail).
- [ ] **5. Первый модуль целиком** — код, проверка в игре, тег, релиз.
  Дальше по той же схеме: один модуль — одна ветка и PR — запись в CHANGELOG.
  - [x] Код модуля Tooltips с твиком Health bar above tooltip.
  - [x] Проверка в игре (Retail).
  - [x] Код модуля Nameplates с твиком Enemy player names in red и тест в Debug.
  - [x] Проверка теста Debug в игре (Retail). Проверка в PvP — задача выше.
  - [x] Код: имена в цвете реакции вместо красного.
  - [x] Проверка теста Debug с цветом реакции в игре (Forever).
  - [x] Код модуля Unit Frames с твиком Player names in class color.
  - [x] Проверка Unit Frames в игре (Forever), вместе с дочерними твиками.
  - [ ] Решить, попадёт ли модуль Debug в релиз.
  - [ ] Тег и релиз.

## Инструменты (по мере надобности)

- [ ] Lua 5.1, luacheck, StyLua, GitHub CLI (`gh`).
- [ ] VS Code: расширения Lua (sumneko) и WoW API (Ketho).
- [ ] GitHub Actions: luacheck на каждый push; BigWigs packager для CurseForge.
- [ ] Лицензия — до публикации на CurseForge.

## Версия 0.1.0

Состав и критерии готовности — в `docs/VISION.md`.
