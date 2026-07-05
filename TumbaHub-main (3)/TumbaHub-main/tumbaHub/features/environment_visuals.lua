-- features/environment_visuals.lua
Mega.Features.EnvironmentVisuals = {}

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local connections = Mega.Objects.Connections

local originalFogEnd = Lighting.FogEnd
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalClockTime = Lighting.ClockTime
local originalGlobalShadows = Lighting.GlobalShadows

local wasNoFog = false
local wasFullBright = false
local wasNightMode = false
local wasRemoveShadows = false

if not Mega.States.Visuals then
    Mega.States.Visuals = {
        NoFog = false,
        FullBright = false,
        NightMode = false,
        RemoveShadows = false,
        GorillaMode = false
    }
end
local vStates = Mega.States.Visuals

function Mega.Features.EnvironmentVisuals.Update()
    if not connections.EnvVisualsLoop then
        connections.EnvVisualsLoop = RunService.RenderStepped:Connect(function()
            if vStates.NoFog then
                if not wasNoFog then originalFogEnd = Lighting.FogEnd; wasNoFog = true end
                Lighting.FogEnd = 100000
            else
                if wasNoFog then Lighting.FogEnd = originalFogEnd; wasNoFog = false end
                originalFogEnd = Lighting.FogEnd
            end
            
            if vStates.FullBright then
                if not wasFullBright then
                    originalBrightness = Lighting.Brightness
                    originalAmbient = Lighting.Ambient
                    originalOutdoorAmbient = Lighting.OutdoorAmbient
                    wasFullBright = true
                end
                Lighting.Brightness = 2
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            else
                if wasFullBright then
                    Lighting.Brightness = originalBrightness
                    Lighting.Ambient = originalAmbient
                    Lighting.OutdoorAmbient = originalOutdoorAmbient
                    wasFullBright = false
                end
                originalBrightness = Lighting.Brightness
                originalAmbient = Lighting.Ambient
                originalOutdoorAmbient = Lighting.OutdoorAmbient
            end
            
            if vStates.NightMode then
                if not wasNightMode then originalClockTime = Lighting.ClockTime; wasNightMode = true end
                Lighting.ClockTime = 22
            else
                if wasNightMode then Lighting.ClockTime = originalClockTime; wasNightMode = false end
                originalClockTime = Lighting.ClockTime
            end
            
            if vStates.RemoveShadows then
                if not wasRemoveShadows then originalGlobalShadows = Lighting.GlobalShadows; wasRemoveShadows = true end
                Lighting.GlobalShadows = false
            else
                if wasRemoveShadows then Lighting.GlobalShadows = originalGlobalShadows; wasRemoveShadows = false end
                originalGlobalShadows = Lighting.GlobalShadows
            end
        end)
    end
end

-- Call initially
Mega.Features.EnvironmentVisuals.Update()
