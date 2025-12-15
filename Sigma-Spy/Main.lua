--// Base Configuration
local Configuration = {
	UseWorkspace = false, 
	NoActors = false,
	FolderName = "Sigma Spy",
	RepoUrl = [[http://c1.play2go.cloud:22023/raw/Sigma-Spy]],
	ParserUrl = [[http://c1.play2go.cloud:22023/raw/Roblox-parser/dist/Main.luau]],
    Directory = "Sigma Spy"
}

--// Load overwrites
local Parameters = {...}
local Overwrites = Parameters[1]
if typeof(Overwrites) == "table" then
	for Key, Value in Overwrites do
		Configuration[Key] = Value
	end
end

--// Service handler
local Services = setmetatable({}, {
	__index = function(self, Name: string): Instance
		local Service = game:GetService(Name)
		return cloneref(Service)
	end,
})

--// Files module
local Files = loadstring(game:HttpGet(`{Configuration.RepoUrl}/lib/Files.lua`))()
Files:PushConfig(Configuration)
Files:Init({
	Services = Services
})

local Folder = Files.FolderName
local Scripts = {
	--// User configurations
	Config = Files:GetModule(`{Folder}/Config`, "Config"),
	ReturnSpoofs = Files:GetModule(`{Folder}/Return spoofs`, "Return Spoofs"),
	Configuration = Configuration,
	Files = Files,

	--// Libraries
	Process = game:HttpGet(`{Configuration.RepoUrl}/lib/Process.lua`),
	Hook = game:HttpGet(`{Configuration.RepoUrl}/lib/Hook.lua`),
	Flags = game:HttpGet(`{Configuration.RepoUrl}/lib/Flags.lua`),
	Ui = game:HttpGet(`{Configuration.RepoUrl}/lib/Ui.lua`),
	Generation = game:HttpGet(`{Configuration.RepoUrl}/lib/Generation.lua`),
	Communication = game:HttpGet(`{Configuration.RepoUrl}/lib/Communication.lua`)
}

--// Services
local Players: Players = Services.Players

--// Dependencies
local Modules = Files:LoadLibraries(Scripts)
local Process = Modules.Process
local Hook = Modules.Hook
local Ui = Modules.Ui
local Generation = Modules.Generation
local Communication = Modules.Communication
local Config = Modules.Config

--// Use custom font (optional)
local FontContent = Files:GetAsset("ProggyClean.ttf", true)
local FontJsonFile = Files:CreateFont("ProggyClean", FontContent)
Ui:SetFontFile(FontJsonFile)

--// Load modules
Process:CheckConfig(Config)
Files:LoadModules(Modules, {
	Modules = Modules,
	Services = Services,
    Configuration = Configuration
})

--// ReGui Create window
local Window = Ui:CreateMainWindow()

--// Check if Sigma spy is supported
local Supported = Process:CheckIsSupported()
if not Supported then 
	Window:Close()
	return
end

--// Create communication channel
local ChannelId, Event = Communication:CreateChannel()
Communication:AddCommCallback("QueueLog", function(...)
	Ui:QueueLog(...)
end)
Communication:AddCommCallback("Print", function(...)
	Ui:ConsoleLog(...)
end)

--// Generation swaps
local LocalPlayer = Players.LocalPlayer
Generation:SetSwapsCallback(function(self)
	self:AddSwap(LocalPlayer, {
		String = "LocalPlayer",
	})
	self:AddSwap(LocalPlayer.Character, {
		String = "Character",
		NextParent = LocalPlayer
	})
end)

--// Create window content
Ui:CreateWindowContent(Window)

--// Begin the Log queue 
Ui:SetCommChannel(Event)
Ui:BeginLogService()

--// Load hooks
local ActorCode = Files:MakeActorScript(Scripts, ChannelId)
Hook:LoadHooks(ActorCode, ChannelId)

local EnablePatches = Ui:AskUser({
	Title = "Enable function patches?",
	Content = {
		"On some executors, function patches can prevent common detections that executor has",
		"By enabling this, it MAY trigger hook detections in some games, this is why you are asked.",
		"If it doesn't work, rejoin and press 'No'",
		"",
		"(This does not affect game functionality)"
	},
	Options = {"Yes", "No"}
}) == "Yes"

--// Detect Adonis
local function isAdonisDetected()
	local detected = false
	pcall(function()
		for _, inst in ipairs(game:GetDescendants()) do
			local name = inst.Name:lower()
			if name:find("adonis") or name:find("admin") then
				detected = true
				break
			end
		end
	end)
	if not detected then
		pcall(function()
			for _, inst in ipairs(getnilinstances()) do
				local name = inst.Name:lower()
				if name:find("adonis") or name:find("admin") then
					detected = true
					break
				end
			end
		end)
	end

	return detected
end

--// Ask user if detected
if isAdonisDetected() then
	local EnableProtection = Ui:AskUser({
		Title = "Adonis Detected",
		Content = {
			"Hey User, Adonis is detected.",
			"This game is running Adonis admin / anticheat.",
			"",
			"Would you like to enable protection?"
		},
		Options = {"Yes", "No"}
	}) == "Yes"

	if EnableProtection then
		pcall(function()
			local oldPrint = print
			print = function() end
			loadstring(game:HttpGet(
				"https://raw.githubusercontent.com/jodta/my-scripts/refs/heads/main/Other/AdonisBypass"
			))()
			print = oldPrint
		end)
		Ui:AskUser({
			Title = "Protection Status",
			Content = {
				"Protection completed."
			},
			Options = {"Okay"}
		})
	end
end

--// Begin hooks
Event:Fire("BeginHooks", {
	PatchFunctions = EnablePatches

})



