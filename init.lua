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

local downloader = Instance.new('TextLabel')
downloader.Size = UDim2.new(1, 0, 0, 40)
downloader.BackgroundTransparency = 1
downloader.TextStrokeTransparency = 0
downloader.TextSize = 20
downloader.TextColor3 = Color3.new(1, 1, 1)
downloader.Font = Enum.Font.Arial
downloader.Text = ''
downloader.Parent = Instance.new('ScreenGui', gethui and gethui() or game:GetService('CoreGui'))

-- ── Parallel download helper ──────────────────────────────────
-- Downloads multiple files simultaneously using task.spawn.
-- Returns only after ALL downloads finish (or error).
local pendingDownloads = {}

local function addWatermark(content)
	return '--This watermark is used to delete the file if its cached, remove it to make the file persist after tumbahub updates.\n' .. content
end

local function fetchAndWrite(path)
	-- Skip if already cached
	if isfile(path) then return end

	local commitPath = 'tumbascript/profiles/commit.txt'
	local commit = isfile(commitPath) and readfile(commitPath) or 'main'
	local url = 'https://raw.githubusercontent.com/zxcbest957-pixel/TumbaV6/' .. commit .. '/' .. path:gsub('tumbascript/', '')

	local suc, res = pcall(function()
		return game:HttpGet(url, true)
	end)
	if not suc or res == '404: Not Found' then
		return -- silently skip; downloadFile will catch it later if needed
	end
	if path:find('.lua') then
		res = addWatermark(res)
	end
	writefile(path, res)
end

local function prefetchAll(paths)
	-- Fire all downloads in parallel
	local threads = {}
	for _, path in paths do
		if not isfile(path) then
			local t = task.spawn(function()
				pcall(fetchAndWrite, path)
			end)
			table.insert(threads, t)
		end
	end
	-- Wait for all to finish (poll until all threads are dead)
	local deadline = tick() + 12 -- max 12 seconds
	repeat
		task.wait()
		local allDone = true
		for _, t in threads do
			if coroutine.status(t) ~= 'dead' then
				allDone = false
				break
			end
		end
		if allDone then break end
	until tick() > deadline
end
-- ─────────────────────────────────────────────────────────────

local function downloadFile(path, func)
	if not isfile(path) then
		downloader.Text = 'Downloading '.. path
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/zxcbest957-pixel/TumbaV6/'..readfile('tumbascript/profiles/commit.txt')..'/'..select(1, path:gsub('tumbascript/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = addWatermark(res)
		end
		writefile(path, res)
		downloader.Text = ''
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

for _, folder in {'tumbascript', 'tumbascript/games', 'tumbascript/profiles', 'tumbascript/assets', 'tumbascript/libraries', 'tumbascript/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.TumbaHubDeveloper then
	-- ── Fast commit check via GitHub API (tiny JSON, not full HTML page) ──
	local commit = 'main'
	task.spawn(function()
		local suc, res = pcall(function()
			return game:HttpGet('https://api.github.com/repos/zxcbest957-pixel/TumbaV6/git/refs/heads/main', true)
		end)
		if suc and res then
			local sha = res:match('"sha":"([a-f0-9]+)"')
			if sha and #sha == 40 then
				commit = sha
			end
		end
	end)

	-- Wait max 2.5 seconds for the API response (usually ~0.3s)
	local t0 = tick()
	repeat task.wait(0.05) until commit ~= 'main' or tick() - t0 > 2.5

	local cached = isfile('tumbascript/profiles/commit.txt') and readfile('tumbascript/profiles/commit.txt') or ''
	if commit ~= cached then
		if cached ~= '' then
			shared.updated = cached
		end
		wipeFolder('tumbascript')
		wipeFolder('tumbascript/games')
		wipeFolder('tumbascript/guis')
		wipeFolder('tumbascript/libraries')
	end
	writefile('tumbascript/profiles/commit.txt', commit)
end

-- ── Pre-fetch all known files IN PARALLEL before main.lua needs them ──
-- This converts 5 sequential requests → 5 simultaneous requests
local gui = (isfile('tumbascript/profiles/gui.txt') and readfile('tumbascript/profiles/gui.txt') or 'new'):gsub('\n',''):gsub('\r',''):gsub('^%s*(.-)%s*$','%1')
if gui ~= 'new' and gui ~= 'old' and gui ~= 'rise' then gui = 'new' end

downloader.Text = 'TumbaHub: loading...'
prefetchAll({
	'tumbascript/main.lua',
	'tumbascript/guis/' .. gui .. '.lua',
	'tumbascript/games/universal.lua',
	'tumbascript/profiles/supported.json',
})
downloader.Text = ''

return loadstring(downloadFile('tumbascript/main.lua'), 'main')()