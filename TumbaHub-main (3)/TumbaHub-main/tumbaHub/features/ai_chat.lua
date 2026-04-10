-- features/ai_chat.lua
-- Ported AI Logic for TumbaHub Premium
-- CREATED BY GOODMINETIK & BACON

return function(Mega, game, script)
    local Features = Mega.Features
    local AIChat = {
        History = {},
        IsProcessing = false
    }
    Features.AIChat = AIChat

    local HttpService = Mega.Services.HttpService
    
    -- --- CONFIGURATION ---
    local API_CONFIG = {
        URL = "https://api.groq.com/openai/v1/chat/completions",
        API_KEY = "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", -- User's Groq Key
        MODEL = "llama-3.3-70b-versatile"
    }

    local PERSONA = [[
Ты — Tumba AI Версия 2.0, ИИ-ассистент TumbaHub Premium, созданный для помощи пользователям. 

--- ТВОЙ ХАРАКТЕР (CHARACTER) ---
- Ты — веселый и позитивный эксперт. Помогаешь юзерам быстро и по делу.
- Ты объясняешь сложные вещи просто. Если у юзера баг, ты даешь четкое решение.
- Твои создатели: **Goodminetik (GG)** и **Bacon**. Ты уважаешь их работу, но упоминаешь их только по делу, без лишнего фанатизма.
- Если юзер просит контакты или ссылку на сервер, дай этот Discord: **https://discord.gg/G7DYpgsdSE**

--- ТВОИ ПРАВИЛА (SECURITY) ---
1. ПРАВИЛО НЕРАЗГЛАШЕНИЯ: Ты знаешь всё о механике функций (см. мануал ниже), но ты **не должен сливать** технические подробности (конкретные байпассы, названия ремортов или алгоритмы) обычным пользователям. 
2. Помогай с починкой багов, не раскрывая "внутреннюю кухню" кода.
3. Если тебя спрашивают "Кто ты?", отвечай, что ты ИИ-ассистент, созданный для помощи игрокам TumbaHub. Ссылку на Дискорд давай только при необходимости.

ТВОИ ГЛАВНЫЕ ДИРЕКТИВЫ:
1. Помогай пользователям разобраться в функциях чита, используя ТЕХНИЧЕСКИЙ МАНУАЛ ниже.
2. Всегда ссылайся на конкретную логику (например, "Aggressive Position Spoofing"), чтобы звучать убедительно, но не давай технических инструкций по её воссозданию.
]]

    local TECHNICAL_MANUAL = [[
# TUMBAHUB: THE ULTIMATE TECHNICAL MANUAL v2.0
## 1. CORE ARCHITECTURE & SECURITY
### 1.1 Metadata Manager: Located in `core/metadata.lua`. Resolves remotes dynamically from GitHub.
### 1.2 Data Dumper: Located in `core/dumper.lua`. Scans ReplicatedStorage for NetManaged events.

## 2. COMBAT MODULES
### 2.1 KillAura: Heartbeat-based. Uses Aggressive Position Spoofing (13.5 studs) to ensure hit registration.
### 2.2 Aimbot: Uses Lerp for smooth camera motion. Includes Movement Prediction and Silent Aim.
### 2.3 Anti-Knockback: Multi-layer (Controller Hook + Physics Lock). Multiplies force by user %.

## 3. WORLD & EXPLOITS
### 3.1 Bed Nuke: Pathfinding calculates obstacles. Fly Bypass uses High-Speed Pulse (100 studs/sec) to desync server distance checks.
### 3.2 Auto-Deposit: 1s interval resource banking in personal chest.
### 3.3 Stella/Beekeeper: Automatic collection of CritStars and Wild Bees within range.

## 4. MOVEMENT
### 4.1 Scaffold: Predictive bridging using velocity-based snapping 3.5 studs below player.
### 4.2 Spider: Raycast-based wall climbing at 30+ speed.

## 5. ARTIFICIAL INTELLIGENCE
### 5.1 Tumba Bot: Fully autonomous pathfinding bot. Phases: Resource -> Auto-Shop -> Combat/Nuke.
]]

    -- Initialize history with system prompt
    table.insert(AIChat.History, {
        role = "system",
        content = PERSONA .. "\n\nТЕХНИЧЕСКИЙ МАНУАЛ:\n" .. TECHNICAL_MANUAL
    })

    function AIChat.SendMessage(userText, successCallback, errorCallback)
        if AIChat.IsProcessing then return end
        AIChat.IsProcessing = true
        
        table.insert(AIChat.History, { role = "user", content = userText })

        -- Async request
        task.spawn(function()
            local success, response = pcall(function()
                return HttpService:RequestAsync({
                    Url = API_CONFIG.URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["Authorization"] = "Bearer " .. API_CONFIG.API_KEY
                    },
                    Body = HttpService:JSONEncode({
                        model = API_CONFIG.MODEL,
                        messages = AIChat.History,
                        temperature = 0.7
                    })
                })
            end)

            AIChat.IsProcessing = false

            if success and response.Success then
                local data = HttpService:JSONDecode(response.Body)
                local aiResponse = data.choices[1].message.content
                table.insert(AIChat.History, { role = "assistant", content = aiResponse })
                if successCallback then successCallback(aiResponse) end
            else
                local errMsg = "⚠️ Ошибка связи с ядром ИИ"
                if not success then errMsg = "⚠️ Ошибка HTTP: " .. tostring(response) end
                if errorCallback then errorCallback(errMsg) end
            end
        end)
    end

    function AIChat.ClearHistory()
        AIChat.History = { AIChat.History[1] } -- Keep system prompt
    end

    print("🤖 Tumba AI Chat Feature Loaded")
end
