-- features/environment_visuals.lua
Mega.Features.EnvironmentVisuals = {}

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local connections = Mega.Objects.Connections

local originalFogEnd = Lighting.FogEnd
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalGlobalShadows = Lighting.GlobalShadows

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
                Lighting.FogEnd = 100000
            end
            if vStates.FullBright then
                Lighting.Brightness = 2
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            end
            if vStates.NightMode then
                Lighting.ClockTime = 22
            end
            if vStates.RemoveShadows then
                Lighting.GlobalShadows = false
            end
        end)
    end
end

-- Call initially
Mega.Features.EnvironmentVisuals.Update()
