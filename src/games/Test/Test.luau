local repo = "https://raw.githubusercontent.com/aechlaenm/PixelHub/33793bfc7a4c8d99ed85468d11bcb0843831baa5/"
local environment = (getgenv and getgenv()) or shared or _G

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local httpFetch = (function()
	local candidates = {
		{ name = "request", kind = "request" },
		{ name = "http_request", kind = "request" },
		{ name = "syn", kind = "syn" },
		{ name = "fluxus", kind = "fluxus" },
	}
	local env = environment
	for _, c in ipairs(candidates) do
		local fn = env[c.name]
		if type(fn) == "function" then
			if c.kind == "request" then
				return function(url)
					local res = fn({ Url = url, Method = "GET" })
					if type(res) == "string" then return res end
					if type(res) == "table" and type(res.Body) == "string" then return res.Body end
					return nil
				end
			elseif c.kind == "syn" and type(fn.request) == "function" then
				return function(url)
					local res = fn.request({ Url = url, Method = "GET" })
					if type(res) == "string" then return res end
					if type(res) == "table" and type(res.Body) == "string" then return res.Body end
					return nil
				end
			elseif c.kind == "fluxus" and type(fn.request) == "function" then
				return function(url)
					local res = fn.request({ Url = url, Method = "GET" })
					if type(res) == "string" then return res end
					if type(res) == "table" and type(res.Body) == "string" then return res.Body end
					return nil
				end
			end
		end
	end
	local get = game.HttpGet
	return function(url)
		return get(game, url)
	end
end)()

local function unloadPrevious()
	local unloaded = false
	local state = environment.PixelHubState
	if type(state) == "table" and type(state.Unload) == "function" then
		unloaded = pcall(state.Unload)
	end

	if not unloaded and type(environment.PixelHubUnload) == "function" then
		unloaded = pcall(environment.PixelHubUnload)
	end

	local previous = environment.PixelHubLibrary
	if not unloaded and type(previous) == "table" and type(previous.Unload) == "function" then
		for _, toggle in previous.Toggles or {} do
			if toggle.Value and type(toggle.SetValue) == "function" then
				pcall(toggle.SetValue, toggle, false)
			end
		end
		pcall(previous.Unload, previous)
	end
	if type(previous) == "table" then
		for _, key in { "PixelHubLibrary", "Library", "library" } do
			if environment[key] == previous then
				environment[key] = nil
			end
		end
	end
end
unloadPrevious()

local function loadModule(path)
	local url = repo .. path .. "?v=" .. tostring(os.time()) .. math.random(100000, 999999)

	local ok, source = pcall(httpFetch, url)
	if not ok or type(source) ~= "string" then
		error(string.format("Fetch failed for %s: %s", path, tostring(source)))
	end

	if #source < 64 then
		error("Suspiciously short response for " .. path)
	end

	local head = source:sub(1, 64):lower()
	if head:find("<!doctype") or head:find("<html") or head:find("404: not found") then
		error("Non-Lua response for " .. path)
	end

	local chunk, compileError = loadstring(source)
	assert(chunk, string.format("Failed to compile %s: %s", path, tostring(compileError)))

	local module = chunk()
	assert(type(module) == "table", path .. " did not return a table")
	return module
end

local Library = loadModule("library/ui/Library.luau")
assert(type(Library.CreateWindow) == "function", "Obsidian Library missing CreateWindow")

local state
local function unload()
	if not Library.Unloaded then
		for _, toggle in Library.Toggles do
			if toggle.Value then
				toggle:SetValue(false)
			end
		end
		Library:Unload()
	end

	if environment.PixelHubState == state then
		environment.PixelHubState = nil
	end
end
state = { Unload = unload, Library = Library }
environment.PixelHubState = state

local ThemeManager = loadModule("library/ui/addons/ThemeManager.luau")
local SaveManager = loadModule("library/ui/addons/SaveManager.luau")

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("PixelHub")
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("PixelHub")
SaveManager:SetSubFolder("Test")

local gameName = game.Name
pcall(function()
	local product = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	if type(product.Name) == "string" then
		gameName = product.Name
	end
end)

local window = Library:CreateWindow({
	Title = "PixelHub",
	GameName = gameName,
	Version = "v" .. tostring(game.PlaceVersion),
	Footer = "PixelHub",
	Center = true,
	AutoShow = true,
	ShowCustomCursor = false,
})

local controls = window:AddTab({
	Name = "Controls",
	Icon = "sliders-horizontal",
	Category = "MAIN",
}):AddGroupbox({
	Side = "Left",
	Name = "Basic",
})

controls:AddButton({
	Text = "Button test",
	Func = function()
		print("Button works")
	end,
})

controls:AddToggle("ToggleTest", {
	Text = "Toggle test",
	Default = false,
	Callback = function(enabled)
		print("Toggle:", enabled)
	end,
})

local settings = window:AddTab({
	Name = "Settings",
	Icon = "settings",
	Category = "OTHER",
})
SaveManager:BuildConfigSection(settings)
ThemeManager:ApplyToTab(settings)
settings:AddGroupbox({ Name = "PixelHub", Side = "Right" }):AddButton({
	Text = "Unload PixelHub",
	Func = unload,
})
SaveManager:LoadAutoloadConfig()
