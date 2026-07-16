-- main.lua - Исправленная версия

-- ============================================================
-- 1. ГЛОБАЛЬНЫЕ ДАННЫЕ И СОСТОЯНИЕ
-- ============================================================
local db = {} -- {name, actors: {name, color, scripts}}
local state = {
    current_screen = "home",
    project_index = -1,
    actor_index = -1,
    modal_mode = "",
    modal_input = "",
    show_modal = false,
    is_running = false,
    picker_category = "",
    game_actors = {}
}

local colors = {
    bg = {0.012, 0.165, 0.196},      -- #002a32
    header = {0.0, 0.239, 0.298},    -- #003d4c
    accent = {0.243, 0.710, 0.820},  -- #3eb5d1
    fab = {1.0, 0.561, 0.0},         -- #ff8f00
    brick_event = {0.953, 0.612, 0.071},   -- #f39c12
    brick_control = {0.902, 0.494, 0.133}, -- #e67e22
    brick_motion = {0.161, 0.502, 0.725},  -- #2980b9
    brick_looks = {0.486, 0.702, 0.259},   -- #7cb342
    text = {1, 1, 1},
    shadow = {0, 0, 0, 0.5}
}

local brick_colors = {
    event = colors.brick_event,
    control = colors.brick_control,
    motion = colors.brick_motion,
    looks = colors.brick_looks
}

-- Библиотека блоков
local library = {
    event = {
        {id="ev_start", text="При старте", cat="event", isHeader=true}
    },
    control = {
        {id="c_wait", text="Ждать секунд", val=1, cat="control"},
        {id="c_forever", text="Вечно", cat="control"},
        {id="c_repeat", text="Повторить", val=5, cat="control"}
    },
    motion = {
        {id="m_x", text="Изменить X на", val=30, cat="motion"},
        {id="m_y", text="Изменить Y на", val=30, cat="motion"},
        {id="m_setx", text="Установить X", val=0, cat="motion"},
        {id="m_sety", text="Установить Y", val=0, cat="motion"},
        {id="m_rot", text="Повернуть на", val=15, cat="motion"}
    },
    looks = {
        {id="l_size", text="Изменить размер на", val=10, cat="looks"},
        {id="l_setsize", text="Установить размер %", val=100, cat="looks"}
    }
}

-- ============================================================
-- 2. ЗАГРУЗКА И СОХРАНЕНИЕ
-- ============================================================
function loadData()
    if love.filesystem.getInfo("pocket_code_data.lua") then
        local data = love.filesystem.load("pocket_code_data.lua")()
        if data then db = data end
    else
        -- Данные по умолчанию для демонстрации
        db = {
            {name = "Мой первый проект", actors = {
                {name = "Кот", color = {1, 0.5, 0}, scripts = {}},
                {name = "Мяч", color = {0.3, 0.6, 1}, scripts = {}}
            }}
        }
        saveData()
    end
end

function saveData()
    local str = "return " .. serialize(db)
    love.filesystem.write("pocket_code_data.lua", str)
end

function serialize(t)
    if type(t) == "table" then
        local str = "{"
        for k, v in pairs(t) do
            if type(k) == "string" then str = str .. "[\"" .. k .. "\"]=" end
            str = str .. serialize(v) .. ","
        end
        return str .. "}"
    elseif type(t) == "string" then
        return "\"" .. t .. "\""
    elseif type(t) == "number" then
        return tostring(t)
    elseif type(t) == "boolean" then
        return tostring(t)
    else
        return "nil"
    end
end

-- ============================================================
-- 3. ОСНОВНЫЕ ФУНКЦИИ LOVE2D
-- ============================================================
function love.load()
    -- ИСПРАВЛЕНО: Правильная настройка окна
    love.window.setMode(800, 600, {
        resizable = true,
        vsync = true,
        minwidth = 400,
        minheight = 300
    })
    
    -- Устанавливаем заголовок отдельно
    love.window.setTitle("Pocket Code Hybrid Final")
    
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- ЗАГРУЗКА ШРИФТА SCHULEVETICA
    local font_path = "Schulevetica-Regular.otf"
    
    -- Проверяем существует ли файл шрифта
    if love.filesystem.getInfo(font_path) then
        -- Загружаем шрифт в разных размерах
        fonts = {
            normal = love.graphics.newFont(font_path, 14),
            big = love.graphics.newFont(font_path, 20),
            title = love.graphics.newFont(font_path, 18),
            header = love.graphics.newFont(font_path, 16),
            small = love.graphics.newFont(font_path, 12),
            large = love.graphics.newFont(font_path, 40)
        }
    else
        -- Если шрифт не найден, используем стандартный
        print("Предупреждение: Файл " .. font_path .. " не найден. Используется стандартный шрифт.")
        fonts = {
            normal = love.graphics.newFont(14),
            big = love.graphics.newFont(20),
            title = love.graphics.newFont(18),
            header = love.graphics.newFont(16),
            small = love.graphics.newFont(12),
            large = love.graphics.newFont(40)
        }
    end
    
    love.graphics.setFont(fonts.normal)
    
    loadData()
    state.current_screen = "home"
end

function love.update(dt)
    -- Обновление игры в режиме выполнения
    if state.is_running then
        updateGame(dt)
    end
end

function love.draw()
    love.graphics.clear(colors.bg)
    
    if state.current_screen == "home" then
        drawHome()
    elseif state.current_screen == "projects" then
        drawProjects()
    elseif state.current_screen == "actors" then
        drawActors()
    elseif state.current_screen == "editor" then
        drawEditor()
    elseif state.current_screen == "categories" then
        drawCategories()
    elseif state.current_screen == "picker" then
        drawPicker()
    elseif state.current_screen == "stage" then
        drawStage()
    end
    
    -- Модальное окно
    if state.show_modal then
        drawModal()
    end
end

function love.keypressed(key)
    if key == "escape" then
        if state.current_screen == "stage" then
            stopGame()
        elseif state.show_modal then
            closeModal()
        else
            love.event.quit()
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        handleClick(x, y)
    end
end

function love.resize(w, h)
    -- Обработка изменения размера окна
end

-- ============================================================
-- 4. ОБРАБОТЧИК КЛИКОВ
-- ============================================================
function handleClick(x, y)
    if state.show_modal then
        handleModalClick(x, y)
        return
    end
    
    if state.current_screen == "home" then
        handleHomeClick(x, y)
    elseif state.current_screen == "projects" then
        handleProjectsClick(x, y)
    elseif state.current_screen == "actors" then
        handleActorsClick(x, y)
    elseif state.current_screen == "editor" then
        handleEditorClick(x, y)
    elseif state.current_screen == "categories" then
        handleCategoriesClick(x, y)
    elseif state.current_screen == "picker" then
        handlePickerClick(x, y)
    elseif state.current_screen == "stage" then
        handleStageClick(x, y)
    end
end

-- ============================================================
-- 5. РИСОВАНИЕ ЭКРАНОВ
-- ============================================================

-- 5.1 ГЛАВНЫЙ ЭКРАН
function drawHome()
    -- Заголовок
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 60)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.title)
    love.graphics.print("Pocket Code", 20, 18)
    
    -- Баннер с карандашом
    love.graphics.setColor(colors.accent)
    love.graphics.rectangle("fill", 0, 60, love.graphics.getWidth(), 180)
    
    -- Иконка карандаша
    love.graphics.setColor(colors.text)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", love.graphics.getWidth()/2, 150, 35)
    love.graphics.line(love.graphics.getWidth()/2 - 12, 150 - 12, 
                       love.graphics.getWidth()/2 + 12, 150 + 12)
    love.graphics.setLineWidth(1)
    
    -- Пункты меню
    local items = {"Проекты на устройстве", "Помощь", "Сообщество Catrobat"}
    for i, item in ipairs(items) do
        local y = 260 + (i-1) * 70
        love.graphics.setColor({0.1, 0.2, 0.25, 0.3})
        love.graphics.rectangle("fill", 0, y, love.graphics.getWidth(), 69)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(item, 20, y + 22)
        
        -- Стрелка вправо
        love.graphics.setFont(fonts.big)
        love.graphics.print("›", love.graphics.getWidth() - 40, y + 18)
        love.graphics.setFont(fonts.normal)
    end
    
    -- FAB кнопка
    drawFAB()
end

function handleHomeClick(x, y)
    -- Проверка клика по пунктам меню
    if x >= 0 and x <= love.graphics.getWidth() then
        if y >= 260 and y <= 329 then
            state.current_screen = "projects"
        end
    end
    
    -- Проверка FAB
    checkFABClick(x, y)
end

-- 5.2 СПИСОК ПРОЕКТОВ
function drawProjects()
    drawHeader("Мои проекты", true)
    
    local w = love.graphics.getWidth()
    local cards_per_row = 2
    local card_w = (w - 45) / cards_per_row
    local card_h = card_w
    
    for i, project in ipairs(db) do
        local col = (i-1) % cards_per_row
        local row = math.floor((i-1) / cards_per_row)
        local x = 15 + col * (card_w + 15)
        local y = 75 + row * (card_h + 15)
        
        love.graphics.setColor({0.0, 0.302, 0.353})
        love.graphics.rectangle("fill", x, y, card_w, card_h)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(project.name, x + 10, y + card_h - 40)
        
        -- Кнопка удаления
        love.graphics.setColor({1, 0, 0, 0.5})
        love.graphics.circle("fill", x + card_w - 20, y + 20, 12)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.small)
        love.graphics.print("✕", x + card_w - 25, y + 13)
        love.graphics.setFont(fonts.normal)
    end
    
    drawFAB()
end

function handleProjectsClick(x, y)
    local w = love.graphics.getWidth()
    local cards_per_row = 2
    local card_w = (w - 45) / cards_per_row
    local card_h = card_w
    
    for i, project in ipairs(db) do
        local col = (i-1) % cards_per_row
        local row = math.floor((i-1) / cards_per_row)
        local card_x = 15 + col * (card_w + 15)
        local card_y = 75 + row * (card_h + 15)
        
        if x >= card_x and x <= card_x + card_w and 
           y >= card_y and y <= card_y + card_h then
            -- Проверка кнопки удаления
            local del_x = card_x + card_w - 20
            local del_y = card_y + 20
            if math.sqrt((x - del_x)^2 + (y - del_y)^2) <= 12 then
                table.remove(db, i)
                saveData()
                return
            else
                state.project_index = i
                state.current_screen = "actors"
                return
            end
        end
    end
    
    -- Проверка FAB
    checkFABClick(x, y)
    
    -- Кнопка назад
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "home"
    end
end

-- 5.3 СПИСОК ОБЪЕКТОВ
function drawActors()
    local project = db[state.project_index]
    drawHeader(project.name, true)
    
    for i, actor in ipairs(project.actors) do
        local y = 75 + (i-1) * 70
        love.graphics.setColor({0.1, 0.2, 0.25, 0.3})
        love.graphics.rectangle("fill", 0, y, love.graphics.getWidth(), 69)
        
        -- Цветной квадратик
        love.graphics.setColor(actor.color)
        love.graphics.rectangle("fill", 20, y + 22, 25, 25)
        
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(actor.name, 60, y + 28)
        
        -- Кнопка удаления
        love.graphics.setColor({1, 0, 0, 0.5})
        love.graphics.circle("fill", love.graphics.getWidth() - 30, y + 35, 12)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.small)
        love.graphics.print("✕", love.graphics.getWidth() - 35, y + 28)
        love.graphics.setFont(fonts.normal)
    end
    
    drawFAB()
end

function handleActorsClick(x, y)
    local project = db[state.project_index]
    
    for i, actor in ipairs(project.actors) do
        local y_pos = 75 + (i-1) * 70
        if x >= 0 and x <= love.graphics.getWidth() and 
           y >= y_pos and y <= y_pos + 69 then
            -- Проверка кнопки удаления
            local del_x = love.graphics.getWidth() - 30
            if math.sqrt((x - del_x)^2 + (y - (y_pos + 35))^2) <= 12 then
                table.remove(project.actors, i)
                saveData()
                return
            else
                state.actor_index = i
                state.current_screen = "editor"
                return
            end
        end
    end
    
    checkFABClick(x, y)
    
    -- Кнопка назад
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "projects"
    end
end

-- 5.4 РЕДАКТОР
function drawEditor()
    local actor = db[state.project_index].actors[state.actor_index]
    drawHeader(actor.name, true)
    
    -- Рисуем блоки
    local y = 75
    for i, script in ipairs(actor.scripts) do
        y = drawBrick(script, 0, y) + 5
    end
    
    -- Нижняя панель
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 70, 
                           love.graphics.getWidth(), 70)
    
    -- Кнопки в нижней панели
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.big)
    love.graphics.print("+", 30, love.graphics.getHeight() - 45)
    
    -- Кнопка Play
    love.graphics.setColor(colors.accent)
    love.graphics.polygon("fill", 
        love.graphics.getWidth() - 60, love.graphics.getHeight() - 55,
        love.graphics.getWidth() - 60, love.graphics.getHeight() - 25,
        love.graphics.getWidth() - 30, love.graphics.getHeight() - 40
    )
    love.graphics.setFont(fonts.normal)
end

function drawBrick(script, x, y)
    local color = brick_colors[script.cat] or {0.5, 0.5, 0.5}
    local is_header = script.isHeader or false
    
    -- Ручка
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x + 20, y, 46, 56)
    
    -- Линии на ручке
    love.graphics.setColor({1, 1, 1, 0.3})
    love.graphics.line(x + 30, y + 18, x + 56, y + 18)
    love.graphics.line(x + 30, y + 28, x + 56, y + 28)
    love.graphics.line(x + 30, y + 38, x + 56, y + 38)
    
    -- Тело
    love.graphics.setColor(color)
    if is_header then
        -- Заголовок с закруглением
        love.graphics.rectangle("fill", x + 66, y, 200, 56)
    else
        love.graphics.rectangle("fill", x + 66, y, 200, 56)
    end
    
    -- Текст
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.normal)
    love.graphics.print(script.text, x + 75, y + 18)
    
    -- Значение если есть
    if script.val then
        love.graphics.print(tostring(script.val), x + 200, y + 18)
    end
    
    -- Кнопка удаления
    love.graphics.setColor({1, 0, 0, 0.5})
    love.graphics.print("✕", x + 250, y + 18)
    
    -- Слот для вложенных блоков
    if script.id == "ev_start" or script.id == "c_forever" or script.id == "c_repeat" then
        local slot_y = y + 56
        love.graphics.setColor({1, 1, 1, 0.1})
        love.graphics.rectangle("fill", x + 40, slot_y, 20, 40)
        
        -- Рекурсивно рисуем вложенные блоки
        if script.children then
            local child_y = slot_y
            for _, child in ipairs(script.children) do
                child_y = drawBrick(child, x + 40, child_y) + 5
            end
        end
        
        -- Футер для циклов
        if script.id ~= "ev_start" then
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", x + 40, child_y + 5, 226, 48)
            love.graphics.setColor(colors.text)
            love.graphics.setFont(fonts.small)
            love.graphics.print("Конец цикла", x + 50, child_y + 20)
            love.graphics.setFont(fonts.normal)
            return child_y + 53
        end
        
        return slot_y + 40
    end
    
    return y + 56
end

function handleEditorClick(x, y)
    -- Проверка кнопки "+"
    if x >= 10 and x <= 50 and y >= love.graphics.getHeight() - 60 and 
       y <= love.graphics.getHeight() - 20 then
        state.current_screen = "categories"
        return
    end
    
    -- Проверка кнопки Play
    if x >= love.graphics.getWidth() - 70 and x <= love.graphics.getWidth() - 20 and
       y >= love.graphics.getHeight() - 60 and y <= love.graphics.getHeight() - 20 then
        playGame()
        return
    end
    
    -- Кнопка назад
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "actors"
    end
end

-- 5.5 КАТЕГОРИИ
function drawCategories()
    drawHeader("Категории", true)
    
    local categories = {
        {name = "Событие", color = colors.brick_event, cat = "event"},
        {name = "Управление", color = colors.brick_control, cat = "control"},
        {name = "Движение", color = colors.brick_motion, cat = "motion"},
        {name = "Образы", color = colors.brick_looks, cat = "looks"}
    }
    
    for i, cat in ipairs(categories) do
        local y = 75 + (i-1) * 80
        love.graphics.setColor(cat.color)
        love.graphics.rectangle("fill", 0, y, love.graphics.getWidth(), 79)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(cat.name, 20, y + 28)
        love.graphics.setFont(fonts.big)
        love.graphics.print("›", love.graphics.getWidth() - 40, y + 24)
        love.graphics.setFont(fonts.normal)
    end
end

function handleCategoriesClick(x, y)
    local categories = {"event", "control", "motion", "looks"}
    for i, cat in ipairs(categories) do
        local y_pos = 75 + (i-1) * 80
        if x >= 0 and x <= love.graphics.getWidth() and 
           y >= y_pos and y <= y_pos + 79 then
            state.picker_category = cat
            state.current_screen = "picker"
            return
        end
    end
    
    -- Кнопка назад
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "editor"
    end
end

-- 5.6 ВЫБОР БЛОКА
function drawPicker()
    drawHeader(state.picker_category:upper(), true)
    
    local blocks = library[state.picker_category] or {}
    local y = 75
    
    for i, block in ipairs(blocks) do
        local color = brick_colors[block.cat]
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", 20, y, 250, 56)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(block.text, 35, y + 18)
        y = y + 66
    end
end

function handlePickerClick(x, y)
    local blocks = library[state.picker_category] or {}
    local y_pos = 75
    
    for i, block in ipairs(blocks) do
        if x >= 20 and x <= 270 and y >= y_pos and y <= y_pos + 56 then
            -- Добавляем блок в скрипты
            local actor = db[state.project_index].actors[state.actor_index]
            local new_block = {id=block.id, text=block.text, cat=block.cat}
            if block.val then new_block.val = block.val end
            if block.isHeader then new_block.isHeader = true end
            if block.id == "ev_start" or block.id == "c_forever" or block.id == "c_repeat" then
                new_block.children = {}
            end
            table.insert(actor.scripts, new_block)
            saveData()
            state.current_screen = "editor"
            return
        end
        y_pos = y_pos + 66
    end
    
    -- Кнопка назад
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "categories"
    end
end

-- 5.7 СЦЕНА
function drawStage()
    love.graphics.setColor({0, 0, 0})
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Рисуем спрайты
    for _, actor in ipairs(state.game_actors) do
        love.graphics.setColor(actor.color)
        love.graphics.rectangle("fill", actor.x - 35, actor.y - 35, 70, 70)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(actor.name, actor.x - 20, actor.y - 5)
    end
    
    -- Кнопка выхода
    love.graphics.setColor({1, 0, 0, 0.8})
    love.graphics.rectangle("fill", love.graphics.getWidth() - 100, 10, 90, 40)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.normal)
    love.graphics.print("ВЫХОД", love.graphics.getWidth() - 85, 22)
end

function handleStageClick(x, y)
    if x >= love.graphics.getWidth() - 100 and x <= love.graphics.getWidth() - 10 and
       y >= 10 and y <= 50 then
        stopGame()
    end
end

-- ============================================================
-- 6. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

function drawHeader(title, show_back)
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 60)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.title)
    
    if show_back then
        love.graphics.print("←", 20, 15)
    end
    
    love.graphics.print(title, show_back and 60 or 20, 18)
end

function drawFAB()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    love.graphics.setColor(colors.fab)
    love.graphics.circle("fill", w - 45, h - 45, 35)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.large)
    love.graphics.print("+", w - 57, h - 58)
    love.graphics.setFont(fonts.normal)
end

function checkFABClick(x, y)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local cx, cy = w - 45, h - 45
    if math.sqrt((x - cx)^2 + (y - cy)^2) <= 35 then
        openModal("project")
    end
end

-- 6.1 МОДАЛЬНОЕ ОКНО
function openModal(mode)
    state.modal_mode = mode
    state.show_modal = true
    state.modal_input = ""
end

function closeModal()
    state.show_modal = false
    state.modal_input = ""
end

function drawModal()
    love.graphics.setColor({0, 0, 0, 0.8})
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setColor({0.259, 0.259, 0.259})
    love.graphics.rectangle("fill", 50, 150, love.graphics.getWidth() - 100, 200)
    
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.title)
    local title = state.modal_mode == "project" and "Название новой программы" or "Новый объект"
    love.graphics.print(title, 70, 180)
    
    -- Поле ввода
    love.graphics.setColor(colors.accent)
    love.graphics.line(70, 270, love.graphics.getWidth() - 70, 270)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.normal)
    love.graphics.print(state.modal_input, 70, 240)
    
    -- Кнопки
    love.graphics.setFont(fonts.normal)
    love.graphics.print("ОТМЕНИТЬ", love.graphics.getWidth() - 180, 310)
    love.graphics.print("ОК", love.graphics.getWidth() - 80, 310)
end

function handleModalClick(x, y)
    -- Поле ввода
    if x >= 70 and x <= love.graphics.getWidth() - 70 and y >= 240 and y <= 270 then
        -- В Love2D для простоты используем клавиатуру
        return
    end
    
    -- Кнопка ОК
    if x >= love.graphics.getWidth() - 100 and x <= love.graphics.getWidth() - 50 and
       y >= 300 and y <= 340 then
        if #state.modal_input > 0 then
            if state.modal_mode == "project" then
                table.insert(db, {name = state.modal_input, actors = {}})
                state.current_screen = "projects"
            elseif state.modal_mode == "actor" then
                local colors_list = {
                    {1, 0.5, 0}, {0.3, 0.6, 1}, {0.8, 0.2, 0.8},
                    {0, 0.8, 0.2}, {1, 0, 0.5}, {0.5, 0.8, 0}
                }
                table.insert(db[state.project_index].actors, {
                    name = state.modal_input,
                    color = colors_list[math.random(#colors_list)],
                    scripts = {}
                })
                state.current_screen = "actors"
            end
            saveData()
            closeModal()
        end
    end
    
    -- Кнопка ОТМЕНИТЬ
    if x >= love.graphics.getWidth() - 200 and x <= love.graphics.getWidth() - 120 and
       y >= 300 and y <= 340 then
        closeModal()
    end
end

function love.textinput(text)
    if state.show_modal then
        state.modal_input = state.modal_input .. text
    end
end

function love.keypressed(key)
    if state.show_modal then
        if key == "backspace" then
            state.modal_input = state.modal_input:sub(1, -2)
        elseif key == "return" or key == "kpenter" then
            -- Эмулируем нажатие ОК
            if #state.modal_input > 0 then
                if state.modal_mode == "project" then
                    table.insert(db, {name = state.modal_input, actors = {}})
                    state.current_screen = "projects"
                elseif state.modal_mode == "actor" then
                    local colors_list = {
                        {1, 0.5, 0}, {0.3, 0.6, 1}, {0.8, 0.2, 0.8},
                        {0, 0.8, 0.2}, {1, 0, 0.5}, {0.5, 0.8, 0}
                    }
                    table.insert(db[state.project_index].actors, {
                        name = state.modal_input,
                        color = colors_list[math.random(#colors_list)],
                        scripts = {}
                    })
                    state.current_screen = "actors"
                end
                saveData()
                closeModal()
            end
        end
    end
    
    if key == "escape" then
        if state.current_screen == "stage" then
            stopGame()
        elseif state.show_modal then
            closeModal()
        else
            love.event.quit()
        end
    end
end

-- ============================================================
-- 7. ИГРОВОЙ ДВИЖОК
-- ============================================================
function playGame()
    state.is_running = true
    state.current_screen = "stage"
    state.game_actors = {}
    
    local project = db[state.project_index]
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    for _, actor in ipairs(project.actors) do
        table.insert(state.game_actors, {
            name = actor.name,
            color = actor.color,
            scripts = actor.scripts,
            x = w/2 + math.random(-100, 100),
            y = h/2 + math.random(-100, 100),
            s = 1,
            r = 0,
            el = nil -- В Love2D просто рисуем напрямую
        })
    end
    
    -- Запускаем выполнение скриптов
    for _, actor in ipairs(state.game_actors) do
        runCode(actor, actor.scripts)
    end
end

function stopGame()
    state.is_running = false
    state.current_screen = "editor"
end

function updateGame(dt)
    -- Обновление состояния игры (если нужно)
end

function runCode(actor, scripts)
    for i, script in ipairs(scripts) do
        if not state.is_running then return end
        
        -- Выполнение команд
        if script.id == "m_x" then
            actor.x = actor.x + (script.val or 30)
        elseif script.id == "m_y" then
            actor.y = actor.y - (script.val or 30)
        elseif script.id == "m_rot" then
            actor.r = actor.r + (script.val or 15)
        elseif script.id == "m_setx" then
            actor.x = love.graphics.getWidth()/2 + (script.val or 0)
        elseif script.id == "m_sety" then
            actor.y = love.graphics.getHeight()/2 - (script.val or 0)
        elseif script.id == "l_size" then
            actor.s = actor.s + (script.val or 10)/100
        elseif script.id == "l_setsize" then
            actor.s = (script.val or 100)/100
        elseif script.id == "c_wait" then
            local wait_time = (script.val or 1)
            local timer = 0
            while timer < wait_time do
                if not state.is_running then return end
                love.timer.sleep(0.016)
                timer = timer + 0.016
            end
        elseif script.id == "ev_start" then
            if script.children then
                runCode(actor, script.children)
            end
        elseif script.id == "c_forever" then
            while state.is_running do
                if script.children then
                    runCode(actor, script.children)
                end
                love.timer.sleep(0.016)
            end
        elseif script.id == "c_repeat" then
            for n = 1, (script.val or 5) do
                if not state.is_running then return end
                if script.children then
                    runCode(actor, script.children)
                end
                love.timer.sleep(0.01)
            end
        end
    end
end

-- ============================================================
-- 8. ЗАПУСК ПРИЛОЖЕНИЯ
-- ============================================================
-- Приложение автоматически запускается через love.load()
