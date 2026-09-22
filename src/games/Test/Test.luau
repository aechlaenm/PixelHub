local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = require(ReplicatedStorage:WaitForChild("library"):WaitForChild("ui"):WaitForChild("Library"))

return function()
	local window = Library:win("Test", { title = "PixelHub UI Test" })
	local controls = window:tab("Controls"):group("Basic")

	controls:butt({
		text = "Button test",
		call = function()
			print("Button works")
		end,
	})

	controls:newtoggle({
		text = "Toggle test",
		call = function(enabled)
			print("Toggle:", enabled)
		end,
	})

	return window
end
