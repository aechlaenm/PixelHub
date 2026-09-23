local repo = "https://raw.githubusercontent.com/aechlaenm/PixelHub/1d5520990e2c751d53ac7f6495afe200bd94a742/"
local environment = (getgenv and getgenv()) or shared or _G

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local function unloadPrevious()
	local unloaded = false
	if type(environment.PixelHubUnload) == "function" then
		unloaded = pcall(environment.PixelHubUnload)
	end

	local previous = environment.PixelHubLibrary or environment.library or environment.Library
	if not unloaded and type(previous) == "table" and type(previous.Unload) == "function" then
		for _, toggle in previous.Toggles or {} do
			if toggle.Value and type(toggle.SetValue) == "function" then
				pcall(toggle.SetValue, toggle, false)
			end
		end
		pcall(previous.Unload, previous)
	end

end
unloadPrevious()

local function loadModule(path)
	local url = repo .. path .. "?v=" .. tostring(os.time()) .. tostring(math.random(100000, 999999))
	local chunk, compileError = loadstring(game:HttpGet(url))
	assert(chunk, string.format("Failed to compile %s: %s", path, tostring(compileError)))

	local module = chunk()
	assert(type(module) == "table", path .. " did not return a table")
	return module
end

local Library = loadModule("library/ui/Library.luau")
assert(type(Library.CreateWindow) == "function", "Obsidian Library missing CreateWindow")
environment.Library = Library
environment.PixelHubLibrary = Library
environment.library = Library

local function unload()
	if not Library.Unloaded then
		for _, toggle in Library.Toggles do
			if toggle.Value then
				toggle:SetValue(false)
			end
		end
		Library:Unload()
	end

	for _, key in { "PixelHubLibrary", "Library", "library" } do
		if environment[key] == Library then
			environment[key] = nil
		end
	end
	if environment.PixelHubUnload == unload then
		environment.PixelHubUnload = nil
	end
end
environment.PixelHubUnload = unload

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

local controls = window:AddTab("Controls"):AddGroupbox({
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

local settings = window:AddTab("Settings")
SaveManager:BuildConfigSection(settings)
ThemeManager:ApplyToTab(settings)
settings:AddGroupbox({ Name = "PixelHub", Side = "Right" }):AddButton({
	Text = "Unload PixelHub",
	Func = unload,
})
SaveManager:LoadAutoloadConfig()
