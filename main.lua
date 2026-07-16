-- main.lua - Полный рабочий порт Pocket Code

local db = {}
local state = {
    current_screen = "home",
    project_index = -1,
    actor_index = -1,
    modal_mode = "",
    modal_input = "",
    show_modal = false,
    is_running = false,
    picker_category = "",
    game_actors = {},
    scroll_offset = 0
}

local colors = {
    bg = {0.012, 0.165, 0.196},
    header = {0.0, 0.239, 0.298},
    accent = {0.243, 0.710, 0.820},
    fab = {1.0, 0.561, 0.0},
    brick_event = {0.953, 0.612, 0.071},
    brick_control = {0.902, 0.494, 0.133},
    brick_motion = {0.161, 0.502, 0.725},
    brick_looks = {0.486, 0.702, 0.259},
    text = {1, 1, 1},
    card_bg = {0.0, 0.302, 0.353}
}

local brick_colors = {
    event = colors.brick_event,
    control = colors.brick_control,
    motion = colors.brick_motion,
    looks = colors.brick_looks
}

local library = {
    event = {{id="ev_start", text="Start", cat="event", isHeader=true}},
    control = {
        {id="c_wait", text="Wait", val=1, cat="control"},
        {id="c_forever", text="Forever", cat="control"},
        {id="c_repeat", text="Repeat", val=5, cat="control"}
    },
    motion = {
        {id="m_x", text="Change X", val=30, cat="motion"},
        {id="m_y", text="Change Y", val=30, cat="motion"},
        {id="m_setx", text="Set X", val=0, cat="motion"},
        {id="m_sety", text="Set Y", val=0, cat="motion"},
        {id="m_rot", text="Rotate", val=15, cat="motion"}
    },
    looks = {
        {id="l_size", text="Size", val=10, cat="looks"},
        {id="l_setsize", text="Set Size", val=100, cat="looks"}
    }
}

local texts = {
    projects = "Проекты на устройстве",
    help = "Помощь",
    community = "Сообщество Catrobat",
    my_projects = "Мои проекты",
    objects = "Объекты",
    scripts = "Скрипты",
    categories = "Категории",
    blocks = "Блоки",
    event = "Событие",
    control = "Управление",
    motion = "Движение",
    looks = "Образы",
    start = "При старте",
    wait = "Ждать секунд",
    forever = "Вечно",
    rep = "Повторить",
    change_x = "Изменить X на",
    change_y = "Изменить Y на",
    set_x = "Установить X",
    set_y = "Установить Y",
    rotate = "Повернуть на",
    change_size = "Изменить размер на",
    set_size = "Установить размер %",
    end_loop = "Конец цикла",
    exit = "ВЫХОД",
    cancel = "ОТМЕНИТЬ",
    ok = "ОК",
    new_project = "Название новой программы",
    new_object = "Новый объект"
}

function getText(key)
    return texts[key] or key
end

function loadData()
    if love.filesystem.getInfo("pocket_code_data.lua") then
        local chunk = love.filesystem.load("pocket_code_data.lua")
        if chunk then
            local success, data = pcall(chunk)
            if success and data then
                db = data
            else
                db = getDefaultData()
            end
        else
            db = getDefaultData()
        end
    else
        db = getDefaultData()
        saveData()
    end
end

function getDefaultData()
    return {
        {name = "My Project", actors = {
            {name = "Cat", color = {1, 0.5, 0}, scripts = {}},
            {name = "Ball", color = {0.3, 0.6, 1}, scripts = {}}
        }}
    }
end

function saveData()
    local file = love.filesystem.newFile("pocket_code_data.lua")
    file:open("w")
    file:write("return " .. serialize(db))
    file:close()
end

function serialize(t)
    if type(t) == "table" then
        local str = "{"
        for k, v in pairs(t) do
            if type(k) == "string" then
                str = str .. "[\"" .. escapeString(k) .. "\"]="
            end
            str = str .. serialize(v) .. ","
        end
        return str .. "}"
    elseif type(t) == "string" then
        return "\"" .. escapeString(t) .. "\""
    elseif type(t) == "number" then
        return tostring(t)
    elseif type(t) == "boolean" then
        return tostring(t)
    else
        return "nil"
    end
end

function escapeString(s)
    local result = ""
    for i = 1, #s do
        local c = s:sub(i, i)
        if c == "\\" then
            result = result .. "\\\\"
        elseif c == "\"" then
            result = result .. "\\\""
        elseif c == "\n" then
            result = result .. "\\n"
        elseif c == "\r" then
            result = result .. "\\r"
        elseif c == "\t" then
            result = result .. "\\t"
        else
            result = result .. c
        end
    end
    return result
end

function love.load()
    love.window.setMode(800, 600, {resizable = true, vsync = true, minwidth = 400, minheight = 300})
    love.window.setTitle("Pocket Code Hybrid Final")
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    local font_path = "Schulevetica-Regular.otf"
    if love.filesystem.getInfo(font_path) then
        fonts = {
            normal = love.graphics.newFont(font_path, 14),
            big = love.graphics.newFont(font_path, 20),
            title = love.graphics.newFont(font_path, 18),
            header = love.graphics.newFont(font_path, 16),
            small = love.graphics.newFont(font_path, 12),
            large = love.graphics.newFont(font_path, 40)
        }
    else
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
    love.mouse.setVisible(true)
end

function love.update(dt)
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
    if state.show_modal then
        drawModal()
    end
end

function love.wheelmoved(dx, dy)
    state.scroll_offset = state.scroll_offset - dy * 20
    if state.scroll_offset < 0 then
        state.scroll_offset = 0
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        handleClick(x, y)
    end
end

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

function drawHome()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", 0, 0, w, 60)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.title)
    love.graphics.print("Pocket Code", 20, 18)
    love.graphics.setColor(colors.accent)
    love.graphics.rectangle("fill", 0, 60, w, 180)
    love.graphics.setColor(colors.text)
    love.graphics.setLineWidth(4)
    local cx, cy = w/2, 150
    love.graphics.circle("line", cx, cy, 35)
    love.graphics.line(cx - 12, cy - 12, cx + 12, cy + 12)
    love.graphics.setLineWidth(1)
    local items = {"projects", "help", "community"}
    for i, key in ipairs(items) do
        local y = 260 + (i-1) * 70
        love.graphics.setColor({0.1, 0.2, 0.25, 0.3})
        love.graphics.rectangle("fill", 0, y, w, 69)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(getText(key), 20, y + 22)
        love.graphics.setFont(fonts.big)
        love.graphics.print(">", w - 40, y + 18)
        love.graphics.setFont(fonts.normal)
    end
    drawFAB()
end

function handleHomeClick(x, y)
    if x >= 0 and x <= love.graphics.getWidth() and y >= 260 and y <= 329 then
        state.current_screen = "projects"
    end
    checkFABClick(x, y)
end

function drawProjects()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    drawHeader(getText("my_projects"), true)
    local cards_per_row = 2
    local card_w = (w - 45) / cards_per_row
    local card_h = card_w
    for i, project in ipairs(db) do
        local col = (i-1) % cards_per_row
        local row = math.floor((i-1) / cards_per_row)
        local x = 15 + col * (card_w + 15)
        local y = 75 + row * (card_h + 15)
        love.graphics.setColor(colors.card_bg)
        love.graphics.rectangle("fill", x, y, card_w, card_h)
        love.graphics.setColor({1, 1, 1, 0.1})
        love.graphics.rectangle("line", x, y, card_w, card_h)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        local display_name = project.name or "Project"
        if #display_name > 15 then
            display_name = display_name:sub(1, 12) .. "..."
        end
        love.graphics.print(display_name, x + 10, y + card_h - 40)
        love.graphics.setColor({1, 0, 0, 0.5})
        love.graphics.circle("fill", x + card_w - 20, y + 20, 12)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.small)
        love.graphics.print("x", x + card_w - 25, y + 13)
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
        if x >= card_x and x <= card_x + card_w and y >= card_y and y <= card_y + card_h then
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
    checkFABClick(x, y)
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "home"
    end
end

function drawActors()
    local project = db[state.project_index]
    drawHeader(project.name or "Objects", true)
    for i, actor in ipairs(project.actors) do
        local y = 75 + (i-1) * 70
        love.graphics.setColor({0.1, 0.2, 0.25, 0.3})
        love.graphics.rectangle("fill", 0, y, love.graphics.getWidth(), 69)
        love.graphics.setColor(actor.color or {1, 0, 0})
        love.graphics.rectangle("fill", 20, y + 22, 25, 25)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(actor.name or "Actor", 60, y + 28)
        love.graphics.setColor({1, 0, 0, 0.5})
        love.graphics.circle("fill", love.graphics.getWidth() - 30, y + 35, 12)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.small)
        love.graphics.print("x", love.graphics.getWidth() - 35, y + 28)
        love.graphics.setFont(fonts.normal)
    end
    drawFAB()
end

function handleActorsClick(x, y)
    local project = db[state.project_index]
    for i, actor in ipairs(project.actors) do
        local y_pos = 75 + (i-1) * 70
        if x >= 0 and x <= love.graphics.getWidth() and y >= y_pos and y <= y_pos + 69 then
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
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "projects"
    end
end

function drawEditor()
    local actor = db[state.project_index].actors[state.actor_index]
    drawHeader(actor.name or "Scripts", true)
    local y = 75 - state.scroll_offset
    for i, script in ipairs(actor.scripts or {}) do
        y = drawBrick(script, 0, y) + 5
        if y > love.graphics.getHeight() + 100 then
            break
        end
    end
    local h = love.graphics.getHeight()
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", 0, h - 70, love.graphics.getWidth(), 70)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.big)
    love.graphics.print("+", 30, h - 45)
    love.graphics.setColor(colors.accent)
    love.graphics.polygon("fill", 
        love.graphics.getWidth() - 60, h - 55,
        love.graphics.getWidth() - 60, h - 25,
        love.graphics.getWidth() - 30, h - 40
    )
    love.graphics.setFont(fonts.normal)
end

function drawBrick(script, x, y)
    local color = brick_colors[script.cat] or {0.5, 0.5, 0.5}
    
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x + 20, y, 46, 56)
    
    love.graphics.setColor({1, 1, 1, 0.3})
    love.graphics.line(x + 30, y + 18, x + 56, y + 18)
    love.graphics.line(x + 30, y + 28, x + 56, y + 28)
    love.graphics.line(x + 30, y + 38, x + 56, y + 38)
    
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x + 66, y, 200, 56)
    
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.normal)
    local display_text = script.text or "Block"
    if display_text == "Start" then
        display_text = getText("start")
    elseif display_text == "Wait" then
        display_text = getText("wait")
    elseif display_text == "Forever" then
        display_text = getText("forever")
    elseif display_text == "Repeat" then
        display_text = getText("rep")
    elseif display_text == "Change X" then
        display_text = getText("change_x")
    elseif display_text == "Change Y" then
        display_text = getText("change_y")
    elseif display_text == "Set X" then
        display_text = getText("set_x")
    elseif display_text == "Set Y" then
        display_text = getText("set_y")
    elseif display_text == "Rotate" then
        display_text = getText("rotate")
    elseif display_text == "Size" then
        display_text = getText("change_size")
    elseif display_text == "Set Size" then
        display_text = getText("set_size")
    end
    love.graphics.print(display_text, x + 75, y + 18)
    
    if script.val ~= nil then
        love.graphics.setColor(colors.text)
        love.graphics.rectangle("line", x + 190, y + 10, 45, 30)
        love.graphics.print(tostring(script.val), x + 200, y + 18)
    end
    
    love.graphics.setColor({1, 0, 0, 0.5})
    love.graphics.print("x", x + 250, y + 18)
    
    if script.id == "ev_start" or script.id == "c_forever" or script.id == "c_repeat" then
        local slot_y = y + 56
        love.graphics.setColor({1, 1, 1, 0.1})
        love.graphics.rectangle("fill", x + 40, slot_y, 20, 40)
        love.graphics.setColor({1, 1, 1, 0.2})
        love.graphics.line(x + 40, slot_y, x + 60, slot_y + 40)
        love.graphics.line(x + 60, slot_y, x + 40, slot_y + 40)
        
        if script.children then
            local child_y = slot_y
            for _, child in ipairs(script.children) do
                child_y = drawBrick(child, x + 40, child_y) + 5
            end
            if script.id ~= "ev_start" then
                love.graphics.setColor(color)
                love.graphics.rectangle("fill", x + 40, child_y + 5, 226, 48)
                love.graphics.setColor(colors.text)
                love.graphics.setFont(fonts.small)
                love.graphics.print(getText("end_loop"), x + 50, child_y + 20)
                love.graphics.setFont(fonts.normal)
                return child_y + 53
            end
        else
            if script.id ~= "ev_start" then
                love.graphics.setColor(color)
                love.graphics.rectangle("fill", x + 40, slot_y + 5, 226, 48)
                love.graphics.setColor(colors.text)
                love.graphics.setFont(fonts.small)
                love.graphics.print(getText("end_loop"), x + 50, slot_y + 20)
                love.graphics.setFont(fonts.normal)
                return slot_y + 53
            end
        end
        return slot_y + 40
    end
    
    return y + 56
end

function handleEditorClick(x, y)
    local h = love.graphics.getHeight()
    local w = love.graphics.getWidth()
    if x >= 10 and x <= 50 and y >= h - 60 and y <= h - 20 then
        state.current_screen = "categories"
        return
    end
    if x >= w - 70 and x <= w - 20 and y >= h - 60 and y <= h - 20 then
        playGame()
        return
    end
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "actors"
    end
end

function drawCategories()
    drawHeader(getText("categories"), true)
    local categories = {
        {name = "event", color = colors.brick_event},
        {name = "control", color = colors.brick_control},
        {name = "motion", color = colors.brick_motion},
        {name = "looks", color = colors.brick_looks}
    }
    for i, cat in ipairs(categories) do
        local y = 75 + (i-1) * 80
        love.graphics.setColor(cat.color)
        love.graphics.rectangle("fill", 0, y, love.graphics.getWidth(), 79)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(getText(cat.name), 20, y + 28)
        love.graphics.setFont(fonts.big)
        love.graphics.print(">", love.graphics.getWidth() - 40, y + 24)
        love.graphics.setFont(fonts.normal)
    end
end

function handleCategoriesClick(x, y)
    local categories = {"event", "control", "motion", "looks"}
    for i, cat in ipairs(categories) do
        local y_pos = 75 + (i-1) * 80
        if x >= 0 and x <= love.graphics.getWidth() and y >= y_pos and y <= y_pos + 79 then
            state.picker_category = cat
            state.current_screen = "picker"
            return
        end
    end
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "editor"
    end
end

function drawPicker()
    drawHeader(getText("blocks"), true)
    local blocks = library[state.picker_category] or {}
    local y = 75
    for i, block in ipairs(blocks) do
        local color = brick_colors[block.cat]
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", 20, y, 250, 56)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        local display_text = block.text
        if display_text == "Start" then
            display_text = getText("start")
        elseif display_text == "Wait" then
            display_text = getText("wait")
        elseif display_text == "Forever" then
            display_text = getText("forever")
        elseif display_text == "Repeat" then
            display_text = getText("rep")
        elseif display_text == "Change X" then
            display_text = getText("change_x")
        elseif display_text == "Change Y" then
            display_text = getText("change_y")
        elseif display_text == "Set X" then
            display_text = getText("set_x")
        elseif display_text == "Set Y" then
            display_text = getText("set_y")
        elseif display_text == "Rotate" then
            display_text = getText("rotate")
        elseif display_text == "Size" then
            display_text = getText("change_size")
        elseif display_text == "Set Size" then
            display_text = getText("set_size")
        end
        love.graphics.print(display_text, 35, y + 18)
        y = y + 66
    end
end

function handlePickerClick(x, y)
    local blocks = library[state.picker_category] or {}
    local y_pos = 75
    for i, block in ipairs(blocks) do
        if x >= 20 and x <= 270 and y >= y_pos and y <= y_pos + 56 then
            local actor = db[state.project_index].actors[state.actor_index]
            local new_block = {id=block.id, text=block.text, cat=block.cat}
            if block.val then
                new_block.val = block.val
            end
            if block.isHeader then
                new_block.isHeader = true
            end
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
    if x >= 10 and x <= 50 and y >= 10 and y <= 50 then
        state.current_screen = "categories"
    end
end

function drawStage()
    love.graphics.setColor({0, 0, 0})
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    for _, actor in ipairs(state.game_actors) do
        love.graphics.setColor(actor.color)
        love.graphics.rectangle("fill", actor.x - 35, actor.y - 35, 70, 70)
        love.graphics.setColor(colors.text)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(actor.name, actor.x - 20, actor.y - 5)
    end
    love.graphics.setColor({1, 0, 0, 0.8})
    love.graphics.rectangle("fill", love.graphics.getWidth() - 100, 10, 90, 40)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.normal)
    love.graphics.print(getText("exit"), love.graphics.getWidth() - 85, 22)
end

function handleStageClick(x, y)
    if x >= love.graphics.getWidth() - 100 and x <= love.graphics.getWidth() - 10 and y >= 10 and y <= 50 then
        stopGame()
    end
end

function drawHeader(title, show_back)
    local w = love.graphics.getWidth()
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", 0, 0, w, 60)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.title)
    if show_back then
        love.graphics.print("<", 20, 15)
    end
    love.graphics.print(title, show_back and 60 or 20, 18)
end

function drawFAB()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(colors.fab)
    love.graphics.circle("fill", w - 45, h - 45, 35)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.large)
    love.graphics.print("+", w - 57, h - 58)
    love.graphics.setFont(fonts.normal)
end

function checkFABClick(x, y)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local cx, cy = w - 45, h - 45
    if math.sqrt((x - cx)^2 + (y - cy)^2) <= 35 then
        openModal("project")
    end
end

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
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor({0, 0, 0, 0.8})
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor({0.259, 0.259, 0.259})
    love.graphics.rectangle("fill", w/2 - 200, 150, 400, 220)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.normal)
    local title = state.modal_mode == "project" and getText("new_project") or getText("new_object")
    love.graphics.print(title, w/2 - 180, 180)
    love.graphics.setColor(colors.accent)
    love.graphics.line(w/2 - 180, 280, w/2 + 180, 280)
    love.graphics.setColor(colors.text)
    love.graphics.setFont(fonts.normal)
    love.graphics.print(state.modal_input, w/2 - 170, 250)
    love.graphics.setFont(fonts.normal)
    love.graphics.print(getText("cancel"), w/2 + 100, 320)
    love.graphics.print(getText("ok"), w/2 + 200, 320)
end

function handleModalClick(x, y)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    if x >= w/2 + 140 and x <= w/2 + 200 and y >= 310 and y <= 350 then
        if #state.modal_input > 0 then
            if state.modal_mode == "project" then
                table.insert(db, {name = state.modal_input, actors = {}})
                state.current_screen = "projects"
            elseif state.modal_mode == "actor" then
                local colors_list = {{1,0.5,0},{0.3,0.6,1},{0.8,0.2,0.8},{0,0.8,0.2},{1,0,0.5},{0.5,0.8,0}}
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
    if x >= w/2 + 20 and x <= w/2 + 120 and y >= 310 and y <= 350 then
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
            if #state.modal_input > 0 then
                if state.modal_mode == "project" then
                    table.insert(db, {name = state.modal_input, actors = {}})
                    state.current_screen = "projects"
                elseif state.modal_mode == "actor" then
                    local colors_list = {{1,0.5,0},{0.3,0.6,1},{0.8,0.2,0.8},{0,0.8,0.2},{1,0,0.5},{0.5,0.8,0}}
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
        end
    end
end

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
            r = 0
        })
    end
    for _, actor in ipairs(state.game_actors) do
        runCode(actor, actor.scripts)
    end
end

function stopGame()
    state.is_running = false
    state.current_screen = "editor"
end

function updateGame(dt)
    -- Обновление
end

function runCode(actor, scripts)
    for i, script in ipairs(scripts) do
        if not state.is_running then
            return
        end
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
                if not state.is_running then
                    return
                end
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
                if not state.is_running then
                    return
                end
                if script.children then
                    runCode(actor, script.children)
                end
                love.timer.sleep(0.01)
            end
        end
    end
end
