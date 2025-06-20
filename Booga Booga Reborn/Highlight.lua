local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local resources = workspace:WaitForChild("Resources")

local Ore = {
	["Iron Node"] = Color3.fromRGB(160, 95, 53),
	["Gold Node"] = Color3.fromRGB(185, 130, 18),
	["Crystal Lode"] = Color3.fromRGB(176, 241, 244),
	["Coal Node"] = Color3.fromRGB(17, 17, 17),
	["Emerald Lode"] = Color3.fromRGB(91, 154, 76),
	["Meteor Rock"] = Color3.fromRGB(98, 37, 209),
	["Adurite Rich Rock"] = Color3.fromRGB(103, 0, 0),
	["Small Rock"] = Color3.fromRGB(105, 102, 92),
	["Stone Node"] = Color3.fromRGB(105, 102, 92)
}

local Meteor = {
	["Crystal Meteor Core"] = Color3.fromRGB(176, 241, 244),
	["Crystal Meteor Rock"] = Color3.fromRGB(176, 241, 244),
	["Meteor Core"] = Color3.fromRGB(98, 37, 209),
	["Meteor Rock"] = Color3.fromRGB(98, 37, 209)
}

local God = {
	["Sleeping God"] = Color3.fromRGB(31, 63, 31),
	["Miserable God"] = Color3.fromRGB(199, 212, 228),
	["Lonely God"] = Color3.fromRGB(75, 151, 75),
	["Furious God"] = Color3.fromRGB(252, 0, 6)
}

local OreSettings = {
	Enabled = true,
	Distance = false,
	MaxDistance = 500,
	["Iron Node"] = true,
	["Gold Node"] = true,
	["Crystal Lode"] = true,
	["Coal Node"] = true,
	["Emerald Lode"] = true,
	["Meteor Rock"] = true,
	["Adurite Rich Rock"] = true,
	["Small Rock"] = true,
	["Stone Node"] = true
}

local MeteorSettings = {
	Enabled = true,
	Distance = false,
	MaxDistance = 500,
	["Crystal Meteor Core"] = true,
	["Crystal Meteor Rock"] = true,
	["Meteor Core"] = true,
	["Meteor Rock"] = true
}

local GodSettings = {
	Enabled = true,
	Distance = false,
	MaxDistance = 500,
	["Sleeping God"] = true,
	["Miserable God"] = true,
	["Lonely God"] = true,
	["Furious God"] = true
}

local PlayersSettings = {
	Enabled = true,
	Distance = false,
	MaxDistance = 500
}

local trackedObjects = {}
local camera = workspace.CurrentCamera

local function getPlayerPosition()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position
end

local function getDistance(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function isLookingAt(obj)
	local cameraPosition = camera.CFrame.Position
	local cameraDirection = camera.CFrame.LookVector
	local objPosition = obj:GetPivot().Position
	local directionToObj = (objPosition - cameraPosition).Unit
	return cameraDirection:Dot(directionToObj) > 0.3
end

local function isInRange(obj, settings)
	if not settings.Distance then return true end
	local playerPos = getPlayerPosition()
	if not playerPos then return false end
	return getDistance(playerPos, obj:GetPivot().Position) <= settings.MaxDistance
end

local function applyChams(model, color)
	if trackedObjects[model] then return end
	trackedObjects[model] = true
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local box = Instance.new("BoxHandleAdornment")
			box.Adornee = part
			box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
			box.Color3 = color
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Transparency = 0.5
			box.Parent = part
		end
	end
end

local function applyPlayerChams(model, color)
	if trackedObjects[model] then return end
	trackedObjects[model] = true
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("MeshPart") or part.Name == "Head" then
			local box = Instance.new("BoxHandleAdornment")
			box.Adornee = part
			box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
			box.Color3 = color
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Transparency = 0.5
			box.Parent = part
		end
	end
end

local function removeChams(model)
	if not trackedObjects[model] then return end
	trackedObjects[model] = nil
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local box = part:FindFirstChild("BoxHandleAdornment")
			if box then
				box:Destroy()
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	for _, obj in pairs(resources:GetChildren()) do
		local shouldHighlight = false
		local color = nil
		
		if Ore[obj.Name] and OreSettings.Enabled and OreSettings[obj.Name] and isLookingAt(obj) and isInRange(obj, OreSettings) then
			shouldHighlight = true
			color = Ore[obj.Name]
		elseif God[obj.Name] and GodSettings.Enabled and GodSettings[obj.Name] and isLookingAt(obj) and isInRange(obj, GodSettings) then
			shouldHighlight = true
			color = God[obj.Name]
		end
		
		if shouldHighlight then
			applyChams(obj, color)
		else
			removeChams(obj)
		end
	end
	
	for _, obj in pairs(workspace:GetChildren()) do
		if Meteor[obj.Name] and MeteorSettings.Enabled and MeteorSettings[obj.Name] and isLookingAt(obj) and isInRange(obj, MeteorSettings) then
			applyChams(obj, Meteor[obj.Name])
		else
			removeChams(obj)
		end
	end
	
	for _, playerModel in pairs(workspace.Players:GetChildren()) do
		local targetPlayer = Players:FindFirstChild(playerModel.Name)
		if targetPlayer and targetPlayer ~= player and PlayersSettings.Enabled and isLookingAt(playerModel) and isInRange(playerModel, PlayersSettings) then
			applyPlayerChams(playerModel, targetPlayer.TeamColor.Color)
		else
			removeChams(playerModel)
		end
	end
end)
