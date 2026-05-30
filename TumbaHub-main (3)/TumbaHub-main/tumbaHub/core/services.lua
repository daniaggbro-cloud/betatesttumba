-- core/services.lua
-- Roblox services initialization

Mega.Services = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    TextChatService = game:GetService("TextChatService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    CoreGui = game:GetService("CoreGui"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    StarterGui = game:GetService("StarterGui"),
    CollectionService = game:GetService("CollectionService"),
    Debris = game:GetService("Debris"),
    TextService = game:GetService("TextService")
}

Mega.Services.LocalPlayer = Mega.Services.Players.LocalPlayer

