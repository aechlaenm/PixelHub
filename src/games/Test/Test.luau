local repo = "https://raw.githubusercontent.com/aechlaenm/PixelHub/main/"
local environment = (getgenv and getgenv()) or shared or _G

local function unloadPrevious()
	if type(environment.PixelHubUnload) == "function" then
		pcall(environment.PixelHubUnload)
	end

	local previous = environment.PixelHubLibrary or environment.Library
	if type(previous) == "table" and type(previous.Unload) == "function" then
		for _, toggle in previous.Toggles or {} do
			if toggle.Value and type(toggle.SetValue) == "function" then
				toggle:SetValue(false)
			end
		end
		pcall(previous.Unload, previous)
	end

	local roots = { game:GetService("CoreGui") }
	local playerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		table.insert(roots, playerGui)
	end
	if gethui then
		pcall(function()
			table.insert(roots, gethui())
		end)
	end

	for _, root in roots do
		pcall(function()
			for _, child in root:GetChildren() do
				if child:IsA("ScreenGui") and (child.Name == "Obsidian" or child.Name == "PixelHubObsidian") then
					child:Destroy()
				end
			end
		end)
	end

	game:GetService("UserInputService").MouseIconEnabled = true
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
if Library.ScreenGui then
	Library.ScreenGui.Name = "PixelHubObsidian"
end
environment.Library = Library
environment.PixelHubLibrary = Library

local function unload()
	if not Library.Unloaded then
		for _, toggle in Library.Toggles do
			if toggle.Value then
				toggle:SetValue(false)
			end
		end
		Library:Unload()
	end

	if environment.PixelHubLibrary == Library then
		environment.PixelHubLibrary = nil
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
	Title = "PIXEL HUB",
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
SaveManager:LoadAutoloadConfig()
