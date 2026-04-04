-- core/settings.lua
-- Contains all default settings, states, and database structures.

Mega.VERSION = "5.0.1" -- Refactored version
Mega.BUILD_DATE = "2024.03.02"
Mega.DEVELOPER = "I.S.-1"
Mega.SPECIAL_THANKS = "N.User-1"

Mega.Settings = {
    Menu = {
        Width = 950,
        Height = 550,
        BackgroundColor = Color3.fromRGB(20, 20, 30),      -- Dark Purple/Blue
        TitleBarColor = Color3.fromRGB(30, 30, 45),        -- Darker Purple
        AccentColor = Color3.fromRGB(200, 70, 255),       -- Vibrant Magenta
        SecondaryColor = Color3.fromRGB(0, 255, 255),     -- Bright Cyan
        TextColor = Color3.fromRGB(255, 255, 255),
        Transparency = 0.1,
        CornerRadius = 12,
        AnimationSpeed = 0.25
    },
    System = {
        AntiAFK = true,
        AutoSave = true,
        PerformanceMode = false,
        DebugMode = false,
        Logging = true,
        ShowStatusIndicator = true
    },
    StatusIndicator = {
        RainbowMode = true,
        Scale = 14
    }
}

Mega.States = {
    ESP = {
        Enabled = false,
        Boxes = true,
        Names = true,
        Distance = true,
        Health = true,
        Tracers = true,
        ShowTeam = false,
        MaxDistance = 1000,
        TeamColor = Color3.fromRGB(0, 255, 0),
        EnemyColor = Color3.fromRGB(255, 0, 0),
        NeutralColor = Color3.fromRGB(255, 255, 0)
    },
    KitESP = {
        Enabled = false,
        BoxColor = Color3.fromRGB(255, 165, 0),
        TextColor = Color3.fromRGB(255, 255, 255),
        MaxDistance = 500,
        Filters = {
            Iron = true,
            Bee = true,
            Thorns = true,
            Mushrooms = true,
            Sorcerer = true
        }
    },
    AimAssist = {
        Enabled = false,
        Active = false,
        Key = "R",
        FOV = 120,
        Smoothness = 0.4,
        Range = 100,
        Prediction = true,
        SilentAim = false,
        TargetPart = "Head",
        ShowFOV = true,
        FOVColor = Color3.fromRGB(0, 180, 255)
    },
    Visuals = {
        NoFog = false,
        FullBright = false,
        Chams = false,
        NightMode = false,
        RemoveShadows = false
    },
    Player = {
        Fly = false,
        FlyMode = "Velocity",
        FlySpeed = 24,
        Speed = false,
        SpeedValue = 100,
        GodMode = false,
        InfiniteJump = false,
        NoClip = false,
        AntiKnockback = false,
        KnockbackStrength = 50,
        FastBreak = false,
        BreakSpeed = 3,
        LongJump = false,
        LongJumpPower = 50,
        HighJump = false,
        HighJumpPower = 50,
        Sprint = false,
        NoFall = false,
        AntiVoid = {
            Enabled = false,
            YLevel = 29,
            ESP = false,
            ESPTransparency = 0.5
        },
        FollowTarget = nil,
        SpinBot = false,
        SpinSpeed = 10,
        Spider = false,
        SpiderSpeed = 30,
        SpiderMode = "Velocity",
        Scaffold = {
            Enabled = false,
            GridSize = 3,
            Delay = 0.05,
            YOffset = -3.5,
            Predict = 0.15
        }
    },
    Bot = {
        Enabled = false,
        TargetBeds = true,
        TargetPlayers = true,
        Pathfinding = true,
        AutoKillaura = true,
        AutoScaffold = true,
        AutoBedNuke = true,
        AutoAntiVoid = true,
        AutoSpider = true
    },
    Combat = {
        TriggerBot = false,
        AutoShoot = false,
        RapidFire = false,
        NoRecoil = false,
        NoSpread = false,
        Killaura = {
            Enabled = false,
            Range = 25,
            Delay = 0
        }
    },
    Misc = {
        FameSpam = false,
        AutoFarm = false,
        CollectItems = false,
        FamesMom = false,
        AntiStun = false,
        AutoKit = {
            Enabled = false,
            KitName = "yuzi",
            Cooldown = 2,
        },
        ChestSteal = {
            Enabled = false,
            Range = 25
        },
        AutoDeposit = {
            Enabled = false,
            Range = 25,
            Resources = {
                ["iron"] = true,
                ["diamond"] = true,
                ["emerald"] = true,
                ["gold"] = true,
                ["void_crystal"] = true,
                ["wood"] = false,
                ["stone"] = false
            }
        },
        Adetunde = {
            Enabled = false,
            Range = 100000,
            Duration = 5,
            Keybind = "None"
        },
        Lani = {
            Enabled = false,
            Keybind = "X",
            Target = nil
        }
    },
    Beekeeper = {
        Enabled = false,
        ShowIcons = true,
        ShowHighlight = true,
        ShowHiveLevels = false,
        AutoCatch = false
    },
    Fisherman = {
        Enabled = false
    },
    Noelle = {
        Enabled = false,
        SaveBinds = false,
        Binds = {}
    },
    Cletus = {
        Enabled = false,
        Range = 20,
        AutoHarvest = false,
        ESP = false,
        ESPTransparency = 0.75
    },
    Eldertree = {
        Enabled = false,
        Range = 30,
        ESP = false,
        AutoCollect = false
    },
    StarCollector = {
        Enabled = false,
        Range = 60,
        ESP = false,
        AutoCollect = false
    },
    Metal = {
        Enabled = false,
        ESP = true,
        AutoCollect = false,
        AutoCollectLegit = false,
        Range = 25
    },
    Taliah = {
        Enabled = false,
        ESP = false,
        ESPTransparency = 0.2,
        AutoCollect = false,
        AutoCollectLegit = false,
        CollectRadius = 5
    },
    Keybinds = {
        Menu = "RightShift",
        AimAssist = "R",
        Killaura = "None",
        Scaffold = "None"
    }
}

Mega.Database = {
    Stats = {
        Kills = 0,
        Deaths = 0,
        Headshots = 0,
        PlayTime = 0
    }
}
