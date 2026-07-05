-- features/raven_antifog.lua

Mega.Features.RavenAntiFog = {}
local connections = Mega.Objects.Connections

function Mega.Features.RavenAntiFog.SetEnabled(state)
    if state then
        if not connections.RavenAntiFog then
            connections.RavenAntiFog = game:GetService("RunService").RenderStepped:Connect(function()
                -- 1. Сбрасываем FogEnd, если он слишком близко
                if game.Lighting.FogEnd < 500 then
                    game.Lighting.FogEnd = 100000
                end
                
                -- 2. Отключаем RavenDepthOfField (размытие ворона)
                local dof = game.Lighting:FindFirstChild("RavenDepthOfField")
                if dof and dof:IsA("DepthOfFieldEffect") and dof.Enabled then
                    dof.Enabled = false
                end
                
                -- 3. Сбрасываем Atmosphere (густой туман ворона)
                local atmo = game.Lighting:FindFirstChildWhichIsA("Atmosphere")
                if atmo and atmo.Density > 0.3 then
                    -- Возвращаем к дефолтным значениям Bedwars
                    atmo.Density = 0.26
                    atmo.Color = Color3.fromRGB(198, 198, 198) -- ~0.776
                    atmo.Decay = Color3.fromRGB(104, 112, 124) -- ~0.407
                end
                
                -- 4. Сбрасываем ColorCorrection, если он делает экран чёрным
                for _, effect in ipairs(game.Lighting:GetChildren()) do
                    if effect:IsA("ColorCorrectionEffect") then
                        if effect.Brightness < 0 or effect.TintColor == Color3.new(0,0,0) then
                            effect.Brightness = 0
                            effect.TintColor = Color3.new(1,1,1)
                        end
                    end
                end
            end)
        end
    else
        if connections.RavenAntiFog then
            connections.RavenAntiFog:Disconnect()
            connections.RavenAntiFog = nil
        end
    end
end

if Mega.States.RavenESP and Mega.States.RavenESP.RemoveFog then
    Mega.Features.RavenAntiFog.SetEnabled(true)
end
