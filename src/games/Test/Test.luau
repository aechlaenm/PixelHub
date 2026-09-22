local repo = "https://raw.githubusercontent.com/aechlaenm/PixelHub/main/"

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
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("PixelHub")
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("PixelHub")
SaveManager:SetSubFolder("Test")

local window = Library:CreateWindow({
	Title = "PixelHub UI Test",
	Footer = "PixelHub",
	Center = true,
	AutoShow = true,
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
