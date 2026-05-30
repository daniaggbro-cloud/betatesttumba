--!nocheck
shared.tumbadata = ... or {}
shared.tumbadata.Key = script_key
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local tweenService = cloneref and cloneref(game:GetService('TweenService')) or game:GetService('TweenService')

-- ============================================================
--  TUMBA HUB — Premium Install / Load Screen
-- ============================================================
local ScreenGui = Instance.new('ScreenGui')
ScreenGui.Name = 'TumbaInstaller'
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = gethui and gethui() or game:GetService('CoreGui')

-- Dark overlay
local Overlay = Instance.new('Frame')
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.BackgroundColor3 = Color3.fromRGB(6, 7, 10)
Overlay.BackgroundTransparency = 0.25
Overlay.BorderSizePixel = 0
Overlay.Parent = ScreenGui

-- Center card
local Card = Instance.new('Frame')
Card.Size = UDim2.fromOffset(400, 220)
Card.Position = UDim2.fromScale(0.5, 0.5)
Card.AnchorPoint = Vector2.new(0.5, 0.5)
Card.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
Card.BorderSizePixel = 0
Card.Parent = ScreenGui

local CardCorner = Instance.new('UICorner')
CardCorner.CornerRadius = UDim.new(0, 14)
CardCorner.Parent = Card

local CardStroke = Instance.new('UIStroke')
CardStroke.Color = Color3.fromRGB(40, 44, 56)
CardStroke.Thickness = 1.2
CardStroke.Parent = Card

-- Accent top bar (blue line)
local AccentBar = Instance.new('Frame')
AccentBar.Size = UDim2.new(1, 0, 0, 3)
AccentBar.BackgroundColor3 = Color3.fromRGB(12, 163, 232)
AccentBar.BorderSizePixel = 0
AccentBar.Parent = Card

local AccentCorner = Instance.new('UICorner')
AccentCorner.CornerRadius = UDim.new(0, 14)
AccentCorner.Parent = AccentBar

-- Logo / title: "VAPE RISE"
local Title = Instance.new('TextLabel')
Title.Size = UDim2.new(1, -24, 0, 36)
Title.Position = UDim2.fromOffset(24, 18)
Title.BackgroundTransparency = 1
Title.Text = 'VAPE  <font color="#0ca3e8">RISE</font>'
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Card

local SubTitle = Instance.new('TextLabel')
SubTitle.Size = UDim2.new(1, -24, 0, 20)
SubTitle.Position = UDim2.fromOffset(24, 50)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = 'TumbaHub v6  |  Installing...'
SubTitle.TextColor3 = Color3.fromRGB(120, 130, 150)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 12
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Card

-- File currently downloading
local FileLabel = Instance.new('TextLabel')
FileLabel.Size = UDim2.new(1, -24, 0, 18)
FileLabel.Position = UDim2.fromOffset(24, 110)
FileLabel.BackgroundTransparency = 1
FileLabel.Text = 'Preparing...'
FileLabel.TextColor3 = Color3.fromRGB(80, 90, 110)
FileLabel.Font = Enum.Font.Gotham
FileLabel.TextSize = 11
FileLabel.TextXAlignment = Enum.TextXAlignment.Left
FileLabel.TextTruncate = Enum.TextTruncate.AtEnd
FileLabel.Parent = Card

-- Progress bar track
local BarTrack = Instance.new('Frame')
BarTrack.Size = UDim2.new(1, -48, 0, 4)
BarTrack.Position = UDim2.fromOffset(24, 136)
BarTrack.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
BarTrack.BorderSizePixel = 0
BarTrack.ClipsDescendants = true
BarTrack.Parent = Card

local BarCorner = Instance.new('UICorner')
BarCorner.CornerRadius = UDim.new(1, 0)
BarCorner.Parent = BarTrack

local BarFill = Instance.new('Frame')
BarFill.Size = UDim2.fromScale(0, 1)
BarFill.BackgroundColor3 = Color3.fromRGB(12, 163, 232)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarTrack

local BarFillCorner = Instance.new('UICorner')
BarFillCorner.CornerRadius = UDim.new(1, 0)
BarFillCorner.Parent = BarFill

-- Percentage text
local PctLabel = Instance.new('TextLabel')
PctLabel.Size = UDim2.fromOffset(60, 18)
PctLabel.Position = UDim2.new(1, -84, 0, 103)
PctLabel.BackgroundTransparency = 1
PctLabel.Text = '0%'
PctLabel.TextColor3 = Color3.fromRGB(12, 163, 232)
PctLabel.Font = Enum.Font.GothamBold
PctLabel.TextSize = 12
PctLabel.TextXAlignment = Enum.TextXAlignment.Right
PctLabel.Parent = Card

-- Status description
local StatusLabel = Instance.new('TextLabel')
StatusLabel.Size = UDim2.new(1, -24, 0, 18)
StatusLabel.Position = UDim2.fromOffset(24, 155)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = 'Checking GitHub...'
StatusLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Card

-- Discord invite
local DiscordTag = Instance.new('TextLabel')
DiscordTag.Size = UDim2.new(1, -24, 0, 18)
DiscordTag.Position = UDim2.fromOffset(24, 186)
DiscordTag.BackgroundTransparency = 1
DiscordTag.Text = 'discord.gg/Jd4R5nzpHt'
DiscordTag.TextColor3 = Color3.fromRGB(12, 163, 232)
DiscordTag.Font = Enum.Font.Gotham
DiscordTag.TextSize = 11
DiscordTag.TextXAlignment = Enum.TextXAlignment.Left
DiscordTag.Parent = Card

-- Entry animation (slide up + fade in)
Card.Position = UDim2.new(0.5, 0, 0.5, 30)
Card.GroupTransparency = 1
tweenService:Create(Card, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
	Position = UDim2.fromScale(0.5, 0.5),
	GroupTransparency = 0
}):Play()

local loadedFiles = 0

local function setProgress(pct, status, file)
	pct = math.clamp(pct, 0, 100)
	tweenService:Create(BarFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(pct / 100, 1)
	}):Play()
	PctLabel.Text = math.round(pct) .. '%'
	if status then StatusLabel.Text = status end
	if file then
		FileLabel.Text = 'Downloading: ' .. file:gsub('tumbascript/', '')
	end
end

local function downloadFile(path, func)
	if not isfile(path) then
		setProgress(math.min(90, 10 + loadedFiles * 8), 'Downloading files from GitHub...', path)
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/zxcbest957-pixel/TumbaV6/' .. readfile('tumbascript/profiles/commit.txt') .. '/' .. select(1, path:gsub('tumbascript/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			StatusLabel.Text = 'Error: ' .. tostring(res):sub(1, 50)
			StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after tumbahub updates.\n' .. res
		end
		writefile(path, res)
		loadedFiles += 1
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('init') then continue end
		if file:find('profile') then continue end
		if isfile(file) then
			delfile(file)
		elseif isfolder(file) then
			wipeFolder(file)
		end
	end
end

setProgress(5, 'Creating folders...')
for _, folder in {'tumbascript', 'tumbascript/games', 'tumbascript/profiles', 'tumbascript/assets', 'tumbascript/libraries', 'tumbascript/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

setProgress(10, 'Checking for updates on GitHub...')
if not shared.TumbaHubDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/zxcbest957-pixel/TumbaV6')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'

	local isNew = false
	if commit == 'main' or (isfile('tumbascript/profiles/commit.txt') and readfile('tumbascript/profiles/commit.txt') or '') ~= commit then
		isNew = true
		if commit ~= 'main' and isfile('tumbascript/profiles/commit.txt') then
			shared.updated = readfile('tumbascript/profiles/commit.txt')
		end
		setProgress(15, 'New version found! Clearing cache...')
		wipeFolder('tumbascript')
		wipeFolder('tumbascript/games')
		wipeFolder('tumbascript/guis')
		wipeFolder('tumbascript/libraries')
	end

	writefile('tumbascript/profiles/commit.txt', commit)

	local shortHash = commit ~= 'main' and commit:sub(1, 7) or 'dev'
	SubTitle.Text = 'TumbaHub v6  |  ' .. (isNew and 'Installing' or 'Loading') .. '  #' .. shortHash
end

setProgress(92, 'Starting script engine...')
task.wait(0.1)
setProgress(100, 'Done!  Welcome to TumbaHub')
task.wait(0.35)

-- Fade out animation
tweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
	Position = UDim2.new(0.5, 0, 0.5, -20),
	GroupTransparency = 1
}):Play()
tweenService:Create(Overlay, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
	BackgroundTransparency = 1
}):Play()
task.wait(0.45)
ScreenGui:Destroy()

return loadstring(downloadFile('tumbascript/main.lua'), 'main')()