-- v1.1.1
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function getHighlightColor(player)
	return player.Team and player.Team.TeamColor.Color or Color3.new(1, 1, 1)
end

local function setupCharacter(player, character)
	if player == LocalPlayer or character:GetAttribute("ESP_Active") then
		return
	end

	character:SetAttribute("ESP_Active", true)

	local head = character:WaitForChild("Head", 15) or character:FindFirstChild("Head")
	local humanoid = character:WaitForChild("Humanoid", 15) or character:FindFirstChildOfClass("Humanoid")

	if not head or not humanoid then
		character:SetAttribute("ESP_Active", nil)
		return
	end

	local highlight = character:FindFirstChild("ESPHighlight")

	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.OutlineColor = Color3.new(1, 1, 1)
		highlight.Adornee = character
		highlight.Parent = character
	end

	highlight.FillColor = getHighlightColor(player)

	local espGui = character:FindFirstChild("ESPGui")

	if not espGui then
		espGui = Instance.new("BillboardGui")
		espGui.Name = "ESPGui"
		espGui.Size = UDim2.fromOffset(200, 50)
		espGui.StudsOffset = Vector3.new(0, 3, 0)
		espGui.AlwaysOnTop = true
		espGui.Adornee = head
		espGui.Parent = character

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.new()
		label.TextSize = 14
		label.Font = Enum.Font.SourceSansBold
		label.Parent = espGui
	end

	local label = espGui:FindFirstChildOfClass("TextLabel")
	label.TextColor3 = getHighlightColor(player)

	local renderConnection
	local teamConnection

	renderConnection = RunService.RenderStepped:Connect(function()
		if not character.Parent or not espGui.Parent then
			renderConnection:Disconnect()
			if teamConnection then
				teamConnection:Disconnect()
			end
			return
		end

		local localHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")

		if localHead then
			local distance = math.round((localHead.Position - head.Position).Magnitude)
			label.Text = string.format("%s [%d HP]\n(%dm)", player.Name, math.round(humanoid.Health), distance)
		else
			label.Text = string.format("%s [%d HP]", player.Name, math.round(humanoid.Health))
		end
	end)

	teamConnection = player:GetPropertyChangedSignal("Team"):Connect(function()
		if not highlight.Parent then
			teamConnection:Disconnect()
			return
		end

		local color = getHighlightColor(player)
		highlight.FillColor = color
		label.TextColor3 = color
	end)

	humanoid.Died:Once(function()
		renderConnection:Disconnect()
		teamConnection:Disconnect()
	end)
end

local function setupPlayer(player)
	if player == LocalPlayer then
		return
	end

	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		task.spawn(setupCharacter, player, character)
	end)
end

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
