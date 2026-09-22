local repo = "https://raw.githubusercontent.com/aechlaenm/PixelHub/main/"
local environment = (getgenv and getgenv()) or shared
local previousLibrary = environment.PixelHubLibrary or environment.Library

if type(previousLibrary) == "table"
	and type(previousLibrary.CreateWindow) == "function"
	and type(previousLibrary.Unload) == "function"
then
	for _, toggle in previousLibrary.Toggles or {} do
		if toggle.Value and type(toggle.SetValue) == "function" then
			toggle:SetValue(false)
		end
	end

	previousLibrary:Unload()
end

local function loadModule(path)
	local chunk, compileError = loadstring(game:HttpGet(repo .. path))
	assert(chunk, string.format("Failed to compile %s: %s", path, tostring(compileError)))

	local module = chunk()
	assert(type(module) == "table", path .. " did not return a table")
	return module
end

local Library = loadModule("library/ui/Library.luau")
local ThemeManager = loadModule("library/ui/addons/ThemeManager.luau")
local SaveManager = loadModule("library/ui/addons/SaveManager.luau")

assert(type(Library.CreateWindow) == "function", "Obsidian Library missing CreateWindow")
environment.Library = Library
environment.PixelHubLibrary = Library
Library:OnUnload(function()
	for _, toggle in Library.Toggles do
		if toggle.Value then
			toggle:SetValue(false)
		end
	end

	if environment.PixelHubLibrary == Library then
		environment.PixelHubLibrary = nil
	end
end)

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
	Title = gameName,
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
SaveManager:LoadAutoloadConfig()
