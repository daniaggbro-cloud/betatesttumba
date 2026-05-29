repeat task.wait() until game:IsLoaded()
if shared.tumbahub then shared.tumbahub:Uninject() end

local tumbahub
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and tumbahub then
		tumbahub:CreateNotification('TumbaHub', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local inputService = cloneref(game:GetService('UserInputService'))
local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))

if shared.maintumba then
	shared.maintumba = nil
	task.spawn(function()
		local body = httpService:JSONEncode({
			nonce = httpService:GenerateGUID(false),
			args = {
				invite = {code = 'tumbascript'},
				code = 'tumbascript'
			},
			cmd = 'INVITE_BROWSER'
		})

		for i = 1, 2 do
			task.spawn(function()
				request({
					Method = 'POST',
					Url = 'http://127.0.0.1:6463/rpc?v=1',
					Headers = {
						['Content-Type'] = 'application/json',
						Origin = 'https://discord.com'
					},
					Body = body
				})
			end)
		end
	end)
	playersService:Kick('Your script is outdated, Get new one at discord.gg/tumbascript')
	return
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/zxcbest957-pixel/TumbaV6/'..readfile('tumbascript/profiles/commit.txt')..'/'..select(1, path:gsub('tumbascript/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after tumbahub updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	tumbahub.Init = nil
	tumbahub:Load()
	task.spawn(function()
		repeat
			tumbahub:Save()
			task.wait(10)
		until not tumbahub.Loaded
	end)

	local teleportedServers
	tumbahub:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.TumbaHubIndependent) and tumbahub.AutoTeleport.Enabled then
			teleportedServers = true
			local data = shared.tumbadata or {Key = nil}
			local teleportScript = [[
				if shared.TumbaHubDeveloper then
					shared.tumbadata = {Key = '???'}
					print('yo', shared.tumbadata.Key)
					loadstring(readfile('tumbascript/init.lua'), 'init')()
				else
					loadstring(game:HttpGet('https://api.tumbascript.dev/script?key=???'), 'init')()
				end
			]]
			teleportScript = teleportScript:gsub('???', tostring(data.Key or 'none'))
			if shared.TumbaHubDeveloper then
				teleportScript = 'shared.TumbaHubDeveloper = true\n'..teleportScript
			end
			if shared.TumbaHubCustomProfile then
				teleportScript = 'shared.TumbaHubCustomProfile = "'..shared.TumbaHubCustomProfile..'"\n'..teleportScript
			end
			tumbahub:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not tumbahub.Categories then return end
	local data = shared.tumbadata or {}
	if tumbahub.Place ~= 6872274481 and not data.Closet then
		task.spawn(function()
			local body = httpService:JSONEncode({
				nonce = httpService:GenerateGUID(false),
				args = {
					invite = {code = 'tumbascript'},
					code = 'tumbascript'
				},
				cmd = 'INVITE_BROWSER'
			})

			for i = 1, 2 do
				task.spawn(function()
					request({
						Method = 'POST',
						Url = 'http://127.0.0.1:6463/rpc?v=1',
						Headers = {
							['Content-Type'] = 'application/json',
							Origin = 'https://discord.com'
						},
						Body = body
					})
				end)
			end
		end)
	end
	if tumbahub.Categories.Main.Options['GUI bind indicator'].Enabled then
		if getgenv().tumbarole == 'HWID mismatch' then
			tumbahub:CreateNotification('Cat', 'HWID mismatch, Please go to our server And press reset hwid on script panel', 60, 'alert')
			task.wait(0.5)
		else
			tumbahub:CreateNotification('Cat', 'Authenticated as '.. (getgenv().tumbaname or 'Guest').. ' with ('.. (getgenv().tumbarole or 'Free').. ')', 4, 'info')
			task.wait(4)
		end
		tumbahub:CreateNotification('Finished Loading', not inputService.KeyboardEnabled and tumbahub.TumbaHubButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(tumbahub.Keybind, ' + '):upper()..' to open GUI', 5)
	end
end

if not isfile('tumbascript/profiles/gui.txt') then
	writefile('tumbascript/profiles/gui.txt', 'new')
end
local gui = 'new'--readfile('tumbascript/profiles/gui.txt')

if not isfile('tumbascript/profiles/language.txt') then
	writefile('tumbascript/profiles/language.txt', 'English')
end
local langRaw = readfile('tumbascript/profiles/language.txt') or "English"
shared.TumbaLanguage = langRaw:gsub("\n", ""):gsub("\r", ""):gsub("^%s*(.-)%s*$", "%1")

if not isfolder('tumbascript/assets/'..gui) then
	makefolder('tumbascript/assets/'..gui)
end
tumbahub = loadstring(downloadFile('tumbascript/guis/'..gui..'.lua'), 'gui')()
shared.tumbahub = tumbahub
shared.vape = tumbahub -- Compatibility for obfuscated premium scripts
_G.tumbahub = tumbahub
getgenv().vape = tumbahub -- Compatibility

getgenv().canDebug = not table.find({'Xeno', 'Solara'}, ({identifyexecutor()})[1]) and debug.getconstant and debug.getproto and true or false
if not shared.TumbaHubIndependent then
	loadstring(downloadFile('tumbascript/games/universal.lua'), 'universal')()

	local found = false
	local callback = shared.TumbaHubDeveloper and readfile or downloadFile
	
	for i, v in httpService:JSONDecode(callback('tumbascript/profiles/supported.json')) do
		if found then break; end
		if game.GameId == v.gameid then
			for i2, v2 in v do
				if typeof(v2) == 'table' and table.find(v2.Ids, game.PlaceId) then
					found = true
					tumbahub.Place = v2.Place
					if not isfolder('tumbascript/games/'.. i) then
						makefolder('tumbascript/games/'.. i)
					end
					
					loadstring(callback('tumbascript/games/'.. i.. '/'.. i2.. '.luau'), tostring(game.PlaceId))(...)
					loadstring(callback('tumbascript/games/'.. i.. '/'.. 'premium'.. '.luau'), 'paid '.. tostring(game.PlaceId))(...)
					break
				end
			end
		end
	end

	if not found then
		local suc, res = pcall(function()
			return not shared.TumbaHubDeveloper and game:HttpGet('https://raw.githubusercontent.com/zxcbest957-pixel/TumbaV6/'..readfile('tumbascript/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true) or '404: Not Found'
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile('tumbascript/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
		end
	end
	
	finishLoading()
else
	tumbahub.Init = finishLoading
	return tumbahub
end