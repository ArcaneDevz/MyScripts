local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Aimbot = {}

Aimbot.Settings = {
	Enabled = false,
	TeamCheck = false,
	WallCheck = false,
	AliveCheck = false,
	Smoothness = 50,
	AimPart = "Head",
	Hotkey1 = Enum.UserInputType.MouseButton2,
	Hotkey2 = Enum.KeyCode.E,
	Aimbot.Fov = {
		Enabled = false,
		ShowFov = false,
		Transparency = 1,
		Thickness = 1,
		NumSides = 60,
		Radius = 100,
		Color = Color3.fromRGB(255, 255, 255),
		TargetColor = Color3.fromRGB(255, 0, 0)
	}
}

local connection
local currentTarget
local fovCircle

local function createFovCircle()
	if fovCircle then
		fovCircle:Remove()
	end
	fovCircle = Drawing.new("Circle")
	fovCircle.Visible = Settings.Fov.ShowFov
	fovCircle.Transparency = Settings.Fov.Transparency
	fovCircle.Thickness = Settings.Fov.Thickness
	fovCircle.NumSides = Settings.Fov.NumSides
	fovCircle.Radius = Settings.Fov.Radius
	fovCircle.Filled = false
	fovCircle.Color = Settings.Fov.Color
end

local function updateFovCircle()
	if fovCircle then
		fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		fovCircle.Visible = Settings.Fov.ShowFov
		fovCircle.Transparency = Settings.Fov.Transparency
		fovCircle.Thickness = Settings.Fov.Thickness
		fovCircle.NumSides = Settings.Fov.NumSides
		fovCircle.Radius = Settings.Fov.Radius
		fovCircle.Color = currentTarget and Settings.Fov.TargetColor or Settings.Fov.Color
	end
end

local function isInFov(screenPos)
	if not Settings.Fov.Enabled then
		return true
	end
	local centerX = Camera.ViewportSize.X / 2
	local centerY = Camera.ViewportSize.Y / 2
	local distance = math.sqrt((centerX - screenPos.X)^2 + (centerY - screenPos.Y)^2)
	return distance <= Settings.Fov.Radius
end

local function notBehindWall(target)
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then
		return false
	end
	local ray = Ray.new(LocalPlayer.Character.Head.Position, (target.Position - LocalPlayer.Character.Head.Position).Unit * 300)
	local part, position = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
	if part then
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			humanoid = part.Parent.Parent:FindFirstChildOfClass("Humanoid")
		end
		if humanoid and target and humanoid.Parent == target.Parent then
			return true
		end
	end
	return false
end

local function getTargetPart(character)
	if Settings.AimPart == "Head" then
		return character:FindFirstChild("Head")
	elseif Settings.AimPart == "HumanoidRootPart" then
		return character:FindFirstChild("HumanoidRootPart")
	elseif Settings.AimPart == "Random" then
		local parts = {}
		if character:FindFirstChild("Head") then
			table.insert(parts, character.Head)
		end
		if character:FindFirstChild("HumanoidRootPart") then
			table.insert(parts, character.HumanoidRootPart)
		end
		return parts[math.random(1, #parts)]
	elseif Settings.AimPart == "Closest" then
		local head = character:FindFirstChild("Head")
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local closestPart = nil
		local closestDistance = math.huge
		
		if head then
			local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
			if onScreen then
				local distance = math.sqrt((Mouse.X - screenPos.X)^2 + (Mouse.Y - screenPos.Y)^2)
				if distance < closestDistance then
					closestDistance = distance
					closestPart = head
				end
			end
		end
		
		if hrp then
			local screenPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
			if onScreen then
				local distance = math.sqrt((Mouse.X - screenPos.X)^2 + (Mouse.Y - screenPos.Y)^2)
				if distance < closestDistance then
					closestDistance = distance
					closestPart = hrp
				end
			end
		end
		
		return closestPart
	end
end

createFovCircle()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	local hotkey1 = Settings.Hotkey1 or Enum.UserInputType.MouseButton2
	local hotkey2 = Settings.Hotkey2 or Enum.KeyCode.E
	
	local isHotkey1 = input.UserInputType == hotkey1
	local isHotkey2 = input.KeyCode == hotkey2
	
	if isHotkey1 or isHotkey2 then
		if connection then return end
		connection = RunService.Heartbeat:Connect(function()
			updateFovCircle()
			
			if not Settings.Enabled then
				return
			end
			
			if currentTarget and currentTarget.Parent and currentTarget.Parent:FindFirstChild("Humanoid") then
				local humanoid = currentTarget.Parent.Humanoid
				if Settings.AliveCheck and humanoid.Health <= 0 then
					currentTarget = nil
				else
					local screenPos, onScreen = Camera:WorldToScreenPoint(currentTarget.Position)
					if onScreen and isInFov(screenPos) and (not Settings.WallCheck or notBehindWall(currentTarget)) then
						local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, currentTarget.Position)
						if Settings.Smoothness == 0 then
							Camera.CFrame = targetCFrame
						else
							local alpha = 1 - (Settings.Smoothness / 100)
							Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
						end
						return
					end
				end
			end
			
			currentTarget = nil
			local closestDistance = math.huge
			
			for _, player in pairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
					local humanoid = player.Character.Humanoid
					if Settings.AliveCheck and humanoid.Health <= 0 then
						continue
					end
					if Settings.TeamCheck and player.TeamColor == LocalPlayer.TeamColor then
						continue
					end
					
					local targetPart = getTargetPart(player.Character)
					if targetPart then
						local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
						if onScreen and isInFov(screenPos) and (not Settings.WallCheck or notBehindWall(targetPart)) then
							local centerX = Camera.ViewportSize.X / 2
							local centerY = Camera.ViewportSize.Y / 2
							local distance = math.sqrt((centerX - screenPos.X)^2 + (centerY - screenPos.Y)^2)
							if distance < closestDistance then
								closestDistance = distance
								currentTarget = targetPart
							end
						end
					end
				end
			end
			
			if currentTarget then
				local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, currentTarget.Position)
				if Settings.Smoothness == 0 then
					Camera.CFrame = targetCFrame
				else
					local alpha = 1 - (Settings.Smoothness / 100)
					Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
				end
			end
		end)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	local hotkey1 = Settings.Hotkey1 or Enum.UserInputType.MouseButton2
	local hotkey2 = Settings.Hotkey2 or Enum.KeyCode.E
	
	local isHotkey1 = input.UserInputType == hotkey1
	local isHotkey2 = input.KeyCode == hotkey2
	
	if (isHotkey1 or isHotkey2) and connection then
		connection:Disconnect()
		connection = nil
		currentTarget = nil
		if fovCircle then
			fovCircle.Visible = false
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not connection then
		updateFovCircle()
	end
end)

return Aimbot
