-- main.lua для Pocket Cat
-- Визуальный конструктор кода для Love2D (Русская версия)

function love.load()
    -- Настройки окна
    love.window.setTitle("Pocket Cat — Конструктор Love2D")
    love.window.setMode(1200, 800, {resizable=true, minwidth=800, minheight=600})
    
    -- Шрифты
    love.graphics.setDefaultFilter("nearest", "nearest")
    smallFont = love.graphics.newFont(14)
    mediumFont = love.graphics.newFont(18)
    largeFont = love.graphics.newFont(24)
    
    -- Состояние приложения
    state = {
        currentScreen = "projects",
        selectedProjectId = 1,
        selectedObjectId = nil,
        selectedCategory = nil,
        selectedBlockIndex = nil,
        draggingBlock = false,
        dragOffsetX = 0,
        dragOffsetY = 0,
        dragBlockIndex = nil
    }
    
    -- Данные проекта
    projects = {
        {
            id = 1,
            name = "Моя игра с котом",
            objects = {
                {
                    id = "cat",
                    name = "Кот (игрок)",
                    color = {1, 0.6, 0.2},
                    scripts = {
                        { type = "when_start", label = "При старте", x = 50, y = 50 },
                        { type = "set_position", label = "Установить позицию", x = 200, y = 300 },
                        { type = "move_right", label = "Движение вправо", value = 150 }
                    }
                },
                {
                    id = "mouse",
                    name = "Мышь (враг)",
                    color = {0.6, 0.6, 0.6},
                    scripts = {
                        { type = "when_start", label = "При старте", x = 50, y = 50 },
                        { type = "move_left", label = "Движение влево", value = 100 }
                    }
                }
            }
        },
        {
            id = 2,
            name = "Платформер",
            objects = {
                {
                    id = "hero",
                    name = "Герой",
                    color = {0.2, 0.8, 0.4},
                    scripts = {
                        { type = "when_start", label = "При старте", x = 50, y = 50 },
                        { type = "if_key_pressed", label = "Нажата клавиша", key = "space" },
                        { type = "set_position", label = "Установить позицию", x = 100, y = 400 }
                    }
                }
            }
        }
    }
    
    -- Шаблоны блоков
    blockTemplates = {
        event = {
            { type = "when_start", label = "При старте игры", category = "event" },
            { type = "when_update", label = "Каждый кадр (update)", category = "event" },
            { type = "on_click", label = "При клике на объект", category = "event" }
        },
        control = {
            { type = "if_key_pressed", label = "Если нажата клавиша", category = "control", key = "space" },
            { type = "if_key_pressed", label = "Если нажата клавиша", category = "control", key = "w" },
            { type = "if_key_pressed", label = "Если нажата клавиша", category = "control", key = "a" },
            { type = "if_key_pressed", label = "Если нажата клавиша", category = "control", key = "s" },
            { type = "if_key_pressed", label = "Если нажата клавиша", category = "control", key = "d" }
        },
        motion = {
            { type = "set_position", label = "Установить X, Y", category = "motion", x = 100, y = 100 },
            { type = "move_right", label = "Движение вправо", category = "motion", value = 150 },
            { type = "move_left", label = "Движение влево", category = "motion", value = 150 },
            { type = "move_up", label = "Движение вверх", category = "motion", value = 150 },
            { type = "move_down", label = "Движение вниз", category = "motion", value = 150 },
            { type = "jump", label = "Прыжок (сила)", category = "motion", value = 300 }
        },
        looks = {
            { type = "change_color", label = "Изменить цвет на красный", category = "looks", color = {1, 0, 0} },
            { type = "change_color", label = "Изменить цвет на зелёный", category = "looks", color = {0, 1, 0} },
            { type = "change_color", label = "Изменить цвет на синий", category = "looks", color = {0, 0, 1} },
            { type = "change_size", label = "Изменить размер", category = "looks", value = 1.5 }
        }
    }
    
    -- Сгенерированный Lua код
    generatedCode = ""
    generateLuaCode()
end

-- Функция для рисования закругленных прямоугольников
function roundedRect(mode, x, y, w, h, radius, segments)
    if radius > w/2 then radius = w/2 end
    if radius > h/2 then radius = h/2 end
    if radius < 0 then radius = 0 end
    if segments == nil then segments = 10 end
    
    love.graphics.push()
    love.graphics.translate(x + radius, y + radius)
    love.graphics.rectangle(mode, 0, 0, w - radius*2, h - radius*2)
    love.graphics.translate(w - radius*2, 0)
    love.graphics.arc(mode, 0, 0, radius, -math.pi/2, 0, segments)
    love.graphics.translate(0, h - radius*2)
    love.graphics.arc(mode, 0, 0, radius, 0, math.pi/2, segments)
    love.graphics.translate(-(w - radius*2), 0)
    love.graphics.arc(mode, 0, 0, radius, math.pi/2, math.pi, segments)
    love.graphics.translate(0, -(h - radius*2))
    love.graphics.arc(mode, 0, 0, radius, math.pi, 3*math.pi/2, segments)
    love.graphics.pop()
end

function love.update(dt)
end

function love.draw()
    love.graphics.setBackgroundColor(0.08, 0.12, 0.16)
    
    if state.currentScreen == "projects" then
        drawProjectsScreen()
    elseif state.currentScreen == "scene_editor" then
        drawSceneEditor()
    elseif state.currentScreen == "object_editor" then
        drawObjectEditor()
    elseif state.currentScreen == "categories" then
        drawCategoriesScreen()
    elseif state.currentScreen == "blocks_select" then
        drawBlocksSelect()
    end
    
    drawCodePanel()
end

function drawProjectsScreen()
    love.graphics.setColor(0.15, 0.2, 0.25)
    love.graphics.rectangle("fill", 0, 0, 750, 800)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(largeFont)
    love.graphics.print("Pocket Cat", 20, 20)
    
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Выберите проект:", 20, 70)
    
    local y = 110
    for i, project in ipairs(projects) do
        local hover = love.mouse.getX() > 20 and love.mouse.getX() < 730 and 
                     love.mouse.getY() > y and love.mouse.getY() < y + 60
        
        if hover then
            love.graphics.setColor(0.25, 0.35, 0.45)
        else
            love.graphics.setColor(0.12, 0.18, 0.25)
        end
        roundedRect("fill", 20, y, 710, 60, 8)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(mediumFont)
        love.graphics.print(project.name, 40, y + 15)
        
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.setFont(smallFont)
        love.graphics.print("Объектов: " .. #project.objects, 650, y + 20)
        
        y = y + 80
    end
end

function drawSceneEditor()
    love.graphics.setColor(0.15, 0.2, 0.25)
    love.graphics.rectangle("fill", 0, 0, 750, 800)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(largeFont)
    love.graphics.print("Объекты сцены", 20, 20)
    
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Нажмите на объект для редактирования", 20, 70)
    
    local project = getCurrentProject()
    local y = 110
    
    for i, obj in ipairs(project.objects) do
        local hover = love.mouse.getX() > 20 and love.mouse.getX() < 730 and 
                     love.mouse.getY() > y and love.mouse.getY() < y + 60
        
        if hover then
            love.graphics.setColor(0.25, 0.35, 0.45)
        else
            love.graphics.setColor(0.12, 0.18, 0.25)
        end
        roundedRect("fill", 20, y, 710, 60, 8)
        
        love.graphics.setColor(obj.color[1], obj.color[2], obj.color[3])
        love.graphics.rectangle("fill", 40, y + 10, 40, 40)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(mediumFont)
        love.graphics.print(obj.name, 100, y + 15)
        
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.setFont(smallFont)
        love.graphics.print("Скриптов: " .. #obj.scripts, 650, y + 20)
        
        y = y + 80
    end
    
    love.graphics.setColor(0.2, 0.4, 0.6)
    roundedRect("fill", 20, 750, 150, 40, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mediumFont)
    love.graphics.print("Новый объект", 35, 760)
end

function drawObjectEditor()
    local project = getCurrentProject()
    local obj = getCurrentObject()
    
    love.graphics.setColor(0.15, 0.2, 0.25)
    love.graphics.rectangle("fill", 0, 0, 750, 800)
    
    love.graphics.setColor(obj.color[1], obj.color[2], obj.color[3])
    love.graphics.rectangle("fill", 20, 15, 40, 40)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(largeFont)
    love.graphics.print(obj.name, 75, 20)
    
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Скрипты объекта (блоки)", 20, 70)
    
    local y = 110
    if #obj.scripts == 0 then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.setFont(mediumFont)
        love.graphics.print("Нет скриптов. Нажмите Добавить", 40, 150)
    else
        for i, script in ipairs(obj.scripts) do
            drawScriptBlock(script, i, y)
            y = y + 75
        end
    end
    
    love.graphics.setColor(0.9, 0.6, 0.1)
    roundedRect("fill", 20, 750, 150, 40, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mediumFont)
    love.graphics.print("Добавить блок", 35, 760)
end

function drawScriptBlock(script, index, y)
    local category = getBlockCategory(script.type)
    local colors = {
        event = {0.9, 0.3, 0.1},
        control = {0.98, 0.75, 0.1},
        motion = {0.12, 0.53, 0.9},
        looks = {0.26, 0.63, 0.28}
    }
    local color = colors[category] or {0.5, 0.5, 0.5}
    
    love.graphics.setColor(color[1], color[2], color[3], 0.3)
    roundedRect("fill", 20, y, 710, 65, 8)
    
    love.graphics.setColor(color[1], color[2], color[3])
    love.graphics.rectangle("fill", 20, y, 6, 65)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print(script.label, 40, y + 8)
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setFont(smallFont)
    local info = ""
    if script.x and script.y then
        info = "X: " .. script.x .. " Y: " .. script.y
    elseif script.value then
        info = "Значение: " .. script.value
    elseif script.key then
        local keyNames = {space = "Пробел", w = "W", a = "A", s = "S", d = "D"}
        info = "Клавиша: " .. (keyNames[script.key] or script.key)
    end
    love.graphics.print(info, 40, y + 32)
    
    love.graphics.setColor(0.8, 0.2, 0.2)
    roundedRect("fill", 700, y + 10, 25, 25, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print("X", 708, y + 12)
end

function drawCategoriesScreen()
    love.graphics.setColor(0.15, 0.2, 0.25)
    love.graphics.rectangle("fill", 0, 0, 750, 800)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(largeFont)
    love.graphics.print("Категории блоков", 20, 20)
    
    local categories = {
        {id = "event", label = "События", color = {0.9, 0.3, 0.1}},
        {id = "control", label = "Управление", color = {0.98, 0.75, 0.1}},
        {id = "motion", label = "Движение", color = {0.12, 0.53, 0.9}},
        {id = "looks", label = "Внешний вид", color = {0.26, 0.63, 0.28}}
    }
    
    local y = 80
    for _, cat in ipairs(categories) do
        local hover = love.mouse.getX() > 20 and love.mouse.getX() < 730 and 
                     love.mouse.getY() > y and love.mouse.getY() < y + 70
        
        love.graphics.setColor(cat.color[1], cat.color[2], cat.color[3], hover and 0.3 or 0.15)
        roundedRect("fill", 20, y, 710, 70, 10)
        
        love.graphics.setColor(cat.color[1], cat.color[2], cat.color[3])
        love.graphics.setFont(mediumFont)
        love.graphics.print(cat.label, 40, y + 22)
        
        y = y + 90
    end
end

function drawBlocksSelect()
    love.graphics.setColor(0.15, 0.2, 0.25)
    love.graphics.rectangle("fill", 0, 0, 750, 800)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(largeFont)
    love.graphics.print("Выберите блок", 20, 20)
    
    local blocks = blockTemplates[state.selectedCategory] or {}
    local y = 80
    
    for i, block in ipairs(blocks) do
        local hover = love.mouse.getX() > 20 and love.mouse.getX() < 730 and 
                     love.mouse.getY() > y and love.mouse.getY() < y + 55
        
        love.graphics.setColor(0.2, 0.3, 0.4, hover and 1 or 0.5)
        roundedRect("fill", 20, y, 710, 55, 8)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(mediumFont)
        love.graphics.print(block.label, 40, y + 14)
        
        y = y + 75
    end
end

function drawCodePanel()
    love.graphics.setColor(0.06, 0.08, 0.1)
    love.graphics.rectangle("fill", 760, 0, 440, 800)
    
    love.graphics.setColor(0.15, 0.2, 0.25)
    love.graphics.rectangle("fill", 760, 0, 440, 50)
    
    love.graphics.setColor(0.4, 0.8, 0.4)
    love.graphics.setFont(mediumFont)
    love.graphics.print("main.lua", 780, 12)
    
    love.graphics.setColor(0.2, 0.5, 0.2)
    roundedRect("fill", 1050, 10, 130, 30, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print("Сохранить", 1065, 16)
    
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(smallFont)
    
    local lines = {}
    for line in string.gmatch(generatedCode, "[^\n]+") do
        table.insert(lines, line)
    end
    
    local y = 70
    for i, line in ipairs(lines) do
        if y > 800 then break end
        if string.sub(line, 1, 2) == "--" then
            love.graphics.setColor(0.4, 0.6, 0.4)
        elseif string.find(line, "function") then
            love.graphics.setColor(0.8, 0.5, 1)
        elseif string.find(line, "if") or string.find(line, "then") then
            love.graphics.setColor(0.8, 0.6, 0.4)
        elseif string.find(line, "love.") then
            love.graphics.setColor(0.4, 0.7, 0.9)
        else
            love.graphics.setColor(0.85, 0.85, 0.85)
        end
        love.graphics.print(line, 780, y)
        y = y + 20
    end
end

function generateLuaCode()
    local project = getCurrentProject()
    local obj = getCurrentObject()
    
    if not obj then
        generatedCode = "-- Выберите объект для генерации кода"
        return
    end
    
    local codeLines = {}
    table.insert(codeLines, "-- Сгенерированный код для " .. obj.name)
    table.insert(codeLines, "-- Pocket Cat конструктор")
    table.insert(codeLines, "")
    table.insert(codeLines, "local " .. obj.id .. " = {")
    table.insert(codeLines, "    x = 0,")
    table.insert(codeLines, "    y = 0,")
    table.insert(codeLines, "    width = 50,")
    table.insert(codeLines, "    height = 50,")
    table.insert(codeLines, "    speedX = 0,")
    table.insert(codeLines, "    speedY = 0")
    table.insert(codeLines, "}")
    table.insert(codeLines, "")
    
    local drawColor = "love.graphics.setColor(1, 0.6, 0.2)"
    local initX, initY = 100, 100
    local moveRight, moveLeft, moveUp, moveDown = 0, 0, 0, 0
    local jumpPower = 0
    local keyActions = {}
    local sizeMultiplier = 1
    
    for _, script in ipairs(obj.scripts) do
        if script.type == "when_start" then
        elseif script.type == "when_update" then
        elseif script.type == "set_position" then
            initX = script.x or 100
            initY = script.y or 100
        elseif script.type == "move_right" then
            moveRight = script.value or 150
        elseif script.type == "move_left" then
            moveLeft = script.value or 150
        elseif script.type == "move_up" then
            moveUp = script.value or 150
        elseif script.type == "move_down" then
            moveDown = script.value or 150
        elseif script.type == "jump" then
            jumpPower = script.value or 300
        elseif script.type == "if_key_pressed" then
            table.insert(keyActions, script.key)
        elseif script.type == "change_color" and script.color then
            drawColor = string.format("love.graphics.setColor(%.1f, %.1f, %.1f)", script.color[1], script.color[2], script.color[3])
        elseif script.type == "change_size" then
            sizeMultiplier = script.value or 1.5
        end
    end
    
    table.insert(codeLines, "function love.load()")
    table.insert(codeLines, "    " .. obj.id .. ".x = " .. initX)
    table.insert(codeLines, "    " .. obj.id .. ".y = " .. initY)
    table.insert(codeLines, "    love.window.setTitle('Pocket Cat - " .. project.name .. "')")
    table.insert(codeLines, "end")
    table.insert(codeLines, "")
    
    table.insert(codeLines, "function love.update(dt)")
    if moveRight > 0 then
        table.insert(codeLines, "    " .. obj.id .. ".x = " .. obj.id .. ".x + " .. moveRight .. " * dt")
    end
    if moveLeft > 0 then
        table.insert(codeLines, "    " .. obj.id .. ".x = " .. obj.id .. ".x - " .. moveLeft .. " * dt")
    end
    if moveUp > 0 then
        table.insert(codeLines, "    " .. obj.id .. ".y = " .. obj.id .. ".y - " .. moveUp .. " * dt")
    end
    if moveDown > 0 then
        table.insert(codeLines, "    " .. obj.id .. ".y = " .. obj.id .. ".y + " .. moveDown .. " * dt")
    end
    
    for _, key in ipairs(keyActions) do
        table.insert(codeLines, "    if love.keyboard.isDown('" .. key .. "') then")
        if key == "space" then
            table.insert(codeLines, "        " .. obj.id .. ".y = " .. obj.id .. ".y - " .. (jumpPower > 0 and jumpPower or 300) .. " * dt")
        else
            table.insert(codeLines, "        -- Действие для клавиши " .. key)
        end
        table.insert(codeLines, "    end")
    end
    
    table.insert(codeLines, "end")
    table.insert(codeLines, "")
    
    table.insert(codeLines, "function love.draw()")
    table.insert(codeLines, "    " .. drawColor)
    local size = 50 * sizeMultiplier
    table.insert(codeLines, "    love.graphics.rectangle('fill', " .. obj.id .. ".x, " .. obj.id .. ".y, " .. size .. ", " .. size .. ")")
    table.insert(codeLines, "    love.graphics.setColor(1, 1, 1)")
    table.insert(codeLines, "    love.graphics.print('" .. obj.name .. "', " .. obj.id .. ".x - 10, " .. obj.id .. ".y - 30)")
    table.insert(codeLines, "end")
    
    generatedCode = table.concat(codeLines, "\n")
end

function getCurrentProject()
    for i, p in ipairs(projects) do
        if p.id == state.selectedProjectId then
            return p
        end
    end
    return projects[1]
end

function getCurrentObject()
    local project = getCurrentProject()
    for i, obj in ipairs(project.objects) do
        if obj.id == state.selectedObjectId then
            return obj
        end
    end
    return project.objects[1]
end

function getBlockCategory(type)
    for cat, blocks in pairs(blockTemplates) do
        for _, b in ipairs(blocks) do
            if b.type == type then
                return cat
            end
        end
    end
    return "motion"
end

function love.mousepressed(x, y, button)
    if x > 760 then 
        if x > 1050 and x < 1180 and y > 10 and y < 40 then
            love.system.openURL("data:text/plain;charset=utf-8," .. love.util.encodeURI(generatedCode))
        end
        return 
    end
    
    if state.currentScreen == "projects" then
        local yPos = 110
        for i, project in ipairs(projects) do
            if x > 20 and x < 730 and y > yPos and y < yPos + 60 then
                state.selectedProjectId = project.id
                state.currentScreen = "scene_editor"
                generateLuaCode()
                return
            end
            yPos = yPos + 80
        end
    elseif state.currentScreen == "scene_editor" then
        local yPos = 110
        local project = getCurrentProject()
        for i, obj in ipairs(project.objects) do
            if x > 20 and x < 730 and y > yPos and y < yPos + 60 then
                state.selectedObjectId = obj.id
                state.currentScreen = "object_editor"
                generateLuaCode()
                return
            end
            yPos = yPos + 80
        end
        if x > 20 and x < 170 and y > 750 and y < 790 then
            local project = getCurrentProject()
            table.insert(project.objects, {
                id = "obj" .. (#project.objects + 1),
                name = "Объект " .. (#project.objects + 1),
                color = {math.random(), math.random(), math.random()},
                scripts = {}
            })
            generateLuaCode()
        end
    elseif state.currentScreen == "object_editor" then
        local obj = getCurrentObject()
        local yPos = 110
        
        for i, script in ipairs(obj.scripts) do
            if x > 700 and x < 725 and y > yPos + 10 and y < yPos + 35 then
                table.remove(obj.scripts, i)
                generateLuaCode()
                return
            end
            yPos = yPos + 75
        end
        
        if x > 20 and x < 170 and y > 750 and y < 790 then
            state.currentScreen = "categories"
        end
    elseif state.currentScreen == "categories" then
        local yPos = 80
        local categories = {"event", "control", "motion", "looks"}
        for i, cat in ipairs(categories) do
            if x > 20 and x < 730 and y > yPos and y < yPos + 70 then
                state.selectedCategory = cat
                state.currentScreen = "blocks_select"
                return
            end
            yPos = yPos + 90
        end
    elseif state.currentScreen == "blocks_select" then
        local blocks = blockTemplates[state.selectedCategory] or {}
        local yPos = 80
        for i, block in ipairs(blocks) do
            if x > 20 and x < 730 and y > yPos and y < yPos + 55 then
                local obj = getCurrentObject()
                local newBlock = {}
                for k, v in pairs(block) do
                    newBlock[k] = v
                end
                table.insert(obj.scripts, newBlock)
                state.currentScreen = "object_editor"
                generateLuaCode()
                return
            end
            yPos = yPos + 75
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if state.currentScreen == "object_editor" or 
           state.currentScreen == "categories" or 
           state.currentScreen == "blocks_select" then
            state.currentScreen = "scene_editor"
        elseif state.currentScreen == "scene_editor" then
            state.currentScreen = "projects"
        end
    end
end

function love.mousemoved(x, y, dx, dy)
end

function love.resize(w, h)
    love.graphics.setDefaultFilter("nearest", "nearest")
end
