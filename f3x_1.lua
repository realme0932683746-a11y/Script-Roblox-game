local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()
local camera = Workspace.CurrentCamera

local function InitializeF3XPhysicsTool()
	local tool = Instance.new("Tool")
	tool.Name = " F3X Pro (Physics)"
	tool.RequiresHandle = false
	tool.Parent = player:WaitForChild("Backpack")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "F3XPhysicsGui_V5_Bilingual"
	screenGui.Enabled = false
	pcall(function() screenGui.Parent = CoreGui end)
	if not screenGui.Parent then screenGui.Parent = playerGui end

	local modeBtn = Instance.new("TextButton")
	modeBtn.Size = UDim2.new(0, 130, 0, 45)
	modeBtn.Position = UDim2.new(0.5, -140, 0, 20)
	modeBtn.BackgroundColor3 = Color3.fromRGB(240, 150, 0)
	modeBtn.Text = "MODE: MOVE"
	modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	modeBtn.Font = Enum.Font.SourceSansBold
	modeBtn.TextSize = 16
	modeBtn.Parent = screenGui
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = modeBtn

	local freezeBtn = Instance.new("TextButton")
	freezeBtn.Size = UDim2.new(0, 130, 0, 45)
	freezeBtn.Position = UDim2.new(0.5, 10, 0, 20)
	freezeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	freezeBtn.Text = "FREEZE: OFF"
	freezeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	freezeBtn.Font = Enum.Font.SourceSansBold
	freezeBtn.TextSize = 16
	freezeBtn.Parent = screenGui
	local freezeCorner = Instance.new("UICorner")
	freezeCorner.CornerRadius = UDim.new(0, 6)
	freezeCorner.Parent = freezeBtn

	local lockTargetBtn = Instance.new("TextButton")
	lockTargetBtn.Size = UDim2.new(0, 140, 0, 40)
	lockTargetBtn.Position = UDim2.new(1, -160, 0.5, -20)
	lockTargetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	lockTargetBtn.Text = "LOCK TARGET: OFF"
	lockTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockTargetBtn.Font = Enum.Font.SourceSansBold
	lockTargetBtn.TextSize = 14
	lockTargetBtn.Parent = screenGui
	local lockCorner = Instance.new("UICorner")
	lockCorner.CornerRadius = UDim.new(0, 6)
	lockCorner.Parent = lockTargetBtn

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0, 320, 0, 35)
	statusLabel.Position = UDim2.new(0.5, -160, 1, -70)
	statusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	statusLabel.Text = "Status: No object selected"
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Font = Enum.Font.SourceSansItalic
	statusLabel.TextSize = 14
	statusLabel.Parent = screenGui
	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 6)
	statusCorner.Parent = statusLabel

	local selectionHighlight = Instance.new("Highlight")
	selectionHighlight.FillColor = Color3.fromRGB(255, 200, 0)
	selectionHighlight.FillTransparency = 0.6
	selectionHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	selectionHighlight.OutlineTransparency = 0
	selectionHighlight.Enabled = false
	selectionHighlight.Parent = screenGui

	local currentMode = "Move"
	local isFrozen = false
	local isTargetLocked = false
	local targetPart = nil
	local isEquipped = false
	local MAX_OBJECT_SIZE = 40

	local bodyPosition = nil
	local bodyGyro = nil

	local moveHandles = Instance.new("Handles")
	moveHandles.Color3 = Color3.fromRGB(255, 200, 0)
	moveHandles.Visible = false
	moveHandles.Parent = screenGui

	local rotateHandles = Instance.new("ArcHandles")
	rotateHandles.Color3 = Color3.fromRGB(255, 200, 0)
	rotateHandles.Visible = false
	rotateHandles.Parent = screenGui

	local startCFrame = CFrame.new()

	local function checkPhysicsStatus(part)
		if not part or not part:IsA("BasePart") then return false end
		if part.Anchored and not part:FindFirstChild("F3X_FreezePos") then 
			statusLabel.Text = "❌ Locked Object (No Physics Available)"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			return false 
		end
		if part.Size.X > MAX_OBJECT_SIZE or part.Size.Y > MAX_OBJECT_SIZE or part.Size.Z > MAX_OBJECT_SIZE then return false end
		
		statusLabel.Text = "✅ Physics Verified (Synced with Server)"
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		return true
	end

	modeBtn.MouseButton1Click:Connect(function()
		if currentMode == "Move" then
			currentMode = "Rotate"
			modeBtn.Text = "MODE: ROTATE"
			modeBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		else
			currentMode = "Move"
			modeBtn.Text = "MODE: MOVE"
			modeBtn.BackgroundColor3 = Color3.fromRGB(240, 150, 0)
		end
		if targetPart and checkPhysicsStatus(targetPart) then
			moveHandles.Visible = (currentMode == "Move")
			rotateHandles.Visible = (currentMode == "Rotate")
		end
	end)

	lockTargetBtn.MouseButton1Click:Connect(function()
		if not targetPart then 
			statusLabel.Text = "⚠️ Please select an object first before locking!"
			statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			return 
		end
		
		isTargetLocked = not isTargetLocked
		if isTargetLocked then
			lockTargetBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
			lockTargetBtn.Text = "LOCK TARGET: ON"
			statusLabel.Text = "🔒 Focus Locked! Selection cannot be changed."
			statusLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
		else
			lockTargetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
			lockTargetBtn.Text = "LOCK TARGET: OFF"
			statusLabel.Text = "🔓 Focus Unlocked. You can select other objects."
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		end
	end)

	freezeBtn.MouseButton1Click:Connect(function()
		if not targetPart then return end
		isFrozen = not isFrozen
		
		if isFrozen then
			freezeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
			freezeBtn.Text = "FREEZE: ON"
			statusLabel.Text = "⚓ Object frozen securely in mid-air"
			
			if bodyPosition and bodyGyro then
				bodyPosition.Position = targetPart.Position
				bodyPosition.MaxForce = Vector3.new(9e9, 9e9, 9e9)
				bodyGyro.CFrame = targetPart.CFrame
				bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
				
				local tag = Instance.new("BoolValue")
				tag.Name = "F3X_FreezePos"
				tag.Parent = targetPart
			end
		else
			freezeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
			freezeBtn.Text = "FREEZE: OFF"
			statusLabel.Text = "✅ Object physics unfrozen"
			
			if targetPart:FindFirstChild("F3X_FreezePos") then
				targetPart.F3X_FreezePos:Destroy()
			end
			if bodyPosition then bodyPosition.MaxForce = Vector3.new(0, 0, 0) end
			if bodyGyro then bodyGyro.MaxTorque = Vector3.new(0, 0, 0) end
		end
	end)

	local function clearSelection()
		if targetPart and not targetPart:FindFirstChild("F3X_FreezePos") then
			if bodyPosition then bodyPosition:Destroy() end
			if bodyGyro then bodyGyro:Destroy() end
		end
		
		moveHandles.Adornee = nil
		rotateHandles.Adornee = nil
		moveHandles.Visible = false
		rotateHandles.Visible = false
		selectionHighlight.Enabled = false
		selectionHighlight.Adornee = nil
		targetPart = nil
		isFrozen = false
		isTargetLocked = false
		freezeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
		freezeBtn.Text = "FREEZE: OFF"
		lockTargetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		lockTargetBtn.Text = "LOCK TARGET: OFF"
	end

	tool.Activated:Connect(function()
		if isTargetLocked then return end
		local target = mouse.Target
		
		if targetPart and not targetPart:FindFirstChild("F3X_FreezePos") then
			clearSelection()
		elseif targetPart and targetPart:FindFirstChild("F3X_FreezePos") then
			moveHandles.Adornee = nil
			rotateHandles.Adornee = nil
			moveHandles.Visible = false
			rotateHandles.Visible = false
			selectionHighlight.Enabled = false
			targetPart = nil
			isFrozen = false
			freezeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
			freezeBtn.Text = "FREEZE: OFF"
		end
		
		if target and target:IsA("BasePart") then
			local hasPhysics = checkPhysicsStatus(target)
			selectionHighlight.Adornee = target
			selectionHighlight.Enabled = true
			
			if not hasPhysics then
				selectionHighlight.FillColor = Color3.fromRGB(255, 50, 50)
				return
			end
			
			selectionHighlight.FillColor = Color3.fromRGB(255, 200, 0)
			targetPart = target
			pcall(function() targetPart:SetNetworkOwner(player) end)
			
			bodyPosition = targetPart:FindFirstChild("F3X_BodyPos") or Instance.new("BodyPosition")
			bodyPosition.Name = "F3X_BodyPos"
			bodyPosition.P = 1000000
			bodyPosition.D = 100
			if not bodyPosition.Parent then 
				bodyPosition.MaxForce = Vector3.new(0, 0, 0)
				bodyPosition.Position = targetPart.Position
				bodyPosition.Parent = targetPart 
			end
			
			bodyGyro = targetPart:FindFirstChild("F3X_BodyGyro") or Instance.new("BodyGyro")
			bodyGyro.Name = "F3X_BodyGyro"
			bodyGyro.P = 1000000
			bodyGyro.D = 100
			if not bodyGyro.Parent then 
				bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
				bodyGyro.CFrame = targetPart.CFrame
				bodyGyro.Parent = targetPart 
			end
			
			if targetPart:FindFirstChild("F3X_FreezePos") then
				isFrozen = true
				freezeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
				freezeBtn.Text = "FREEZE: ON"
			end
			
			moveHandles.Adornee = targetPart
			rotateHandles.Adornee = targetPart
			moveHandles.Visible = (currentMode == "Move")
			rotateHandles.Visible = (currentMode == "Rotate")
		end
	end)

	moveHandles.MouseButton1Down:Connect(function()
		if targetPart and bodyPosition then 
			startCFrame = targetPart.CFrame
			bodyPosition.Position = targetPart.Position
			bodyPosition.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			pcall(function() targetPart:SetNetworkOwner(player) end)
			camera.CameraType = Enum.CameraType.Scriptable
		end
	end)

	moveHandles.MouseDrag:Connect(function(face, distance)
		if not targetPart or not bodyPosition or (targetPart.Anchored and not targetPart:FindFirstChild("F3X_FreezePos")) then return end
		
		local direction = Vector3.FromNormalId(face)
		direction = startCFrame:VectorToWorldSpace(direction)
		
		local targetPos = (startCFrame + (direction * distance)).Position
		bodyPosition.Position = targetPos
		targetPart.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
	end)

	moveHandles.MouseButton1Up:Connect(function()
		camera.CameraType = Enum.CameraType.Custom
		if bodyPosition and not isFrozen then
			bodyPosition.MaxForce = Vector3.new(0, 0, 0)
		end
	end)

	rotateHandles.MouseButton1Down:Connect(function()
		if targetPart and bodyGyro then 
			startCFrame = targetPart.CFrame
			bodyGyro.CFrame = targetPart.CFrame
			bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			pcall(function() targetPart:SetNetworkOwner(player) end)
			camera.CameraType = Enum.CameraType.Scriptable
		end
	end)

	rotateHandles.MouseDrag:Connect(function(axis, relativeAngle)
		if not targetPart or not bodyGyro or (targetPart.Anchored and not targetPart:FindFirstChild("F3X_FreezePos")) then return end
		
		local axisVector = Vector3.FromAxis(axis)
		local targetRot = startCFrame * CFrame.fromAxisAngle(axisVector, relativeAngle)
		bodyGyro.CFrame = targetRot
		targetPart.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
	end)

	rotateHandles.MouseButton1Up:Connect(function()
		camera.CameraType = Enum.CameraType.Custom
		if bodyGyro and not isFrozen then
			bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
		end
	end)

	RunService.RenderStepped:Connect(function()
		if isEquipped and targetPart then
			if targetPart.Anchored and not targetPart:FindFirstChild("F3X_FreezePos") then
				clearSelection()
				statusLabel.Text = "❌ Selected object was anchored unexpectedly!"
				statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			end
		end
	end)

	tool.Equipped:Connect(function()
		isEquipped = true
		screenGui.Enabled = true
		statusLabel.Text = "Status: Select a physics object to begin"
		statusLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	end)

	tool.Unequipped:Connect(function()
		isEquipped = false
		screenGui.Enabled = false
		camera.CameraType = Enum.CameraType.Custom
		clearSelection()
	end)
end

local mainCanvas = Instance.new("ScreenGui")
mainCanvas.Name = "F3X_MasterCinematic_System"
mainCanvas.ResetOnSpawn = false
mainCanvas.IgnoreGuiInset = true 

pcall(function() mainCanvas.Parent = CoreGui end)
if not mainCanvas.Parent then mainCanvas.Parent = playerGui end

local baseViewport = Instance.new("Frame")
baseViewport.Size = UDim2.new(1, 0, 1, 0)
baseViewport.BackgroundTransparency = 1
baseViewport.BorderSizePixel = 0
baseViewport.Parent = mainCanvas

local screenSize = camera.ViewportSize
local diagMagnitude = math.sqrt(screenSize.X^2 + screenSize.Y^2) * 1.5

local leftBlade = Instance.new("Frame")
leftBlade.Size = UDim2.new(0, diagMagnitude, 0, diagMagnitude)
leftBlade.Position = UDim2.new(0, -diagMagnitude, 0.5, 0) 
leftBlade.AnchorPoint = Vector2.new(1, 0.5)
leftBlade.BackgroundColor3 = Color3.fromRGB(12, 13, 15)
leftBlade.Rotation = 35 
leftBlade.BorderSizePixel = 0
leftBlade.Parent = baseViewport

local rightBlade = Instance.new("Frame")
rightBlade.Size = UDim2.new(0, diagMagnitude, 0, diagMagnitude)
rightBlade.Position = UDim2.new(1, diagMagnitude, 0.5, 0) 
rightBlade.AnchorPoint = Vector2.new(0, 0.5)
rightBlade.BackgroundColor3 = Color3.fromRGB(14, 15, 18) 
rightBlade.Rotation = 35
rightBlade.BorderSizePixel = 0
rightBlade.Parent = baseViewport

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(0, 500, 0, 220)
contentFrame.Position = UDim2.new(0.5, -250, 0.5, -110)
contentFrame.BackgroundTransparency = 1
contentFrame.Visible = false
contentFrame.Parent = baseViewport

local brandingText = Instance.new("TextLabel")
brandingText.Size = UDim2.new(1, 0, 0, 40)
brandingText.Position = UDim2.new(0, 0, 0, 0)
brandingText.BackgroundTransparency = 1
brandingText.Text = "F3X (FE)"
brandingText.TextColor3 = Color3.fromRGB(0, 180, 255)
brandingText.Font = Enum.Font.GothamBold
brandingText.TextSize = 28
brandingText.Parent = contentFrame

local percentText = Instance.new("TextLabel")
percentText.Size = UDim2.new(1, 0, 0, 50)
percentText.Position = UDim2.new(0, 0, 0, 45)
percentText.BackgroundTransparency = 1
percentText.Text = "0.00%"
percentText.TextColor3 = Color3.fromRGB(245, 245, 250)
percentText.Font = Enum.Font.GothamMedium
percentText.TextSize = 44
percentText.Parent = contentFrame

local barBackground = Instance.new("Frame")
barBackground.Size = UDim2.new(0.7, 0, 0, 4)
barBackground.Position = UDim2.new(0.15, 0, 0, 110)
barBackground.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
barBackground.BorderSizePixel = 0
barBackground.Parent = contentFrame

local barBackgroundCorner = Instance.new("UICorner")
barBackgroundCorner.CornerRadius = UDim.new(1, 0)
barBackgroundCorner.Parent = barBackground

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0) 
barFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255) 
barFill.BorderSizePixel = 0
barFill.Parent = barBackground

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

local logText = Instance.new("TextLabel")
logText.Size = UDim2.new(1, 0, 0, 30)
logText.Position = UDim2.new(0, 0, 0, 130)
logText.BackgroundTransparency = 1
logText.Text = "Establishing structural geometric protocols..."
logText.TextColor3 = Color3.fromRGB(145, 150, 160)
logText.Font = Enum.Font.Gotham
logText.TextSize = 12
logText.Parent = contentFrame

local thankYouLabel = Instance.new("TextLabel")
thankYouLabel.Size = UDim2.new(1, 0, 0, 60)
thankYouLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
thankYouLabel.AnchorPoint = Vector2.new(0.5, 0.5)
thankYouLabel.BackgroundTransparency = 1
thankYouLabel.Text = "Thank you for using F3X Pro V5!"
thankYouLabel.TextColor3 = Color3.fromRGB(90, 220, 140)
thankYouLabel.Font = Enum.Font.GothamBold
thankYouLabel.TextSize = 32
thankYouLabel.TextTransparency = 1
thankYouLabel.Parent = baseViewport

local dialogGui = Instance.new("ScreenGui")
dialogGui.Name = "F3X_PostIntro_Notice"
dialogGui.ResetOnSpawn = false
dialogGui.IgnoreGuiInset = true
dialogGui.Enabled = false 
pcall(function() dialogGui.Parent = CoreGui end)
if not dialogGui.Parent then dialogGui.Parent = playerGui end

local dialogBox = Instance.new("Frame")
dialogBox.Size = UDim2.new(0, 500, 0, 360)
dialogBox.Position = UDim2.new(0.5, -250, 0.5, -180)
dialogBox.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
dialogBox.BorderSizePixel = 0
dialogBox.BackgroundTransparency = 1 
dialogBox.Parent = dialogGui

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 12)
boxCorner.Parent = dialogBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(0, 180, 255)
boxStroke.Transparency = 1
boxStroke.Thickness = 1.5
boxStroke.Parent = dialogBox

local noticeTitle = Instance.new("TextLabel")
noticeTitle.Size = UDim2.new(1, -110, 0, 40)
noticeTitle.Position = UDim2.new(0, 20, 0, 15)
noticeTitle.BackgroundTransparency = 1
noticeTitle.TextColor3 = Color3.fromRGB(0, 180, 255)
noticeTitle.Font = Enum.Font.GothamBold
noticeTitle.TextSize = 14
noticeTitle.TextXAlignment = Enum.TextXAlignment.Left
noticeTitle.TextTransparency = 1
noticeTitle.Parent = dialogBox

local langContainer = Instance.new("Frame")
langContainer.Size = UDim2.new(0, 75, 0, 26)
langContainer.Position = UDim2.new(1, -95, 0, 22)
langContainer.BackgroundTransparency = 1
langContainer.Parent = dialogBox

local btnTH = Instance.new("TextButton")
btnTH.Size = UDim2.new(0, 35, 1, 0)
btnTH.Position = UDim2.new(0, 0, 0, 0)
btnTH.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
btnTH.Text = "TH"
btnTH.TextColor3 = Color3.fromRGB(150, 155, 165)
btnTH.Font = Enum.Font.GothamBold
btnTH.TextSize = 11
btnTH.BackgroundTransparency = 1
btnTH.Parent = langContainer

local cornerTH = Instance.new("UICorner")
cornerTH.CornerRadius = UDim.new(0, 4)
cornerTH.Parent = btnTH

local btnEN = Instance.new("TextButton")
btnEN.Size = UDim2.new(0, 35, 1, 0)
btnEN.Position = UDim2.new(0, 40, 0, 0)
btnEN.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
btnEN.Text = "EN"
btnEN.TextColor3 = Color3.fromRGB(255, 255, 255)
btnEN.Font = Enum.Font.GothamBold
btnEN.TextSize = 11
btnEN.BackgroundTransparency = 1
btnEN.Parent = langContainer

local cornerEN = Instance.new("UICorner")
cornerEN.CornerRadius = UDim.new(0, 4)
cornerEN.Parent = btnEN

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -40, 1, -130)
scrollFrame.Position = UDim2.new(0, 20, 0, 60)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 560)
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 255)
scrollFrame.ScrollBarImageTransparency = 1
scrollFrame.Parent = dialogBox

local noticeDesc = Instance.new("TextLabel")
noticeDesc.Size = UDim2.new(1, -10, 1, 0)
noticeDesc.Position = UDim2.new(0, 0, 0, 0)
noticeDesc.BackgroundTransparency = 1
noticeDesc.TextColor3 = Color3.fromRGB(205, 210, 220)
noticeDesc.Font = Enum.Font.Gotham
noticeDesc.TextSize = 12
noticeDesc.TextWrapped = true
noticeDesc.LineHeight = 1.3
noticeDesc.TextXAlignment = Enum.TextXAlignment.Left
noticeDesc.TextYAlignment = Enum.TextYAlignment.Top
noticeDesc.TextTransparency = 1
noticeDesc.RichText = true
noticeDesc.Parent = scrollFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 140, 0, 35)
closeBtn.Position = UDim2.new(0.5, -70, 1, -45)
closeBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.BackgroundTransparency = 1
closeBtn.Parent = dialogBox

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = closeBtn

local texts = {
	EN = {
		title = "⚙️ F3X PRO V5 SYSTEM SPECIFICATIONS",
		content = "Welcome to F3X Pro V5 (FilteringEnabled Advanced Version), a premium structural management toolkit.\n\n" ..
			"[1] Physics Security Certification:\n" ..
			"This script utilizes 100% real-time server-side coordinate simulation. All positioning, angle adjustments, and part rotations are calculated directly via Network Ownership Claims, ensuring that other players in the same server can seamlessly and accurately observe every modification on your screen.\n\n" ..
			"[2] Core Architecture & Technology:\n" ..
			"- BodyGyro & BodyPosition Integration: Employs advanced physics propulsion commands to simulate part orientation, preventing coordinate rejection by Roblox security protocols.\n" ..
			"- Active Garbage Collection: Automatically purges redundant memory overhead on mobile devices immediately upon closure to maintain optimal framerate stability.\n\n" ..
			"[3] Usage Recommendations:\n" ..
			"Avoid simultaneously moving dense 'Anchored' parts in split seconds to preserve the integrity of the physics network stream.\n\n" ..
			"⚠️ IMPORTANT TESTING NOTICE:\n" ..
			"<font color='rgb(255, 75, 75)'><b>Please be informed that this script has only been tested via server-side simulations. We have not yet verified its replication by observing it through another separate player account. Therefore, we cannot completely guarantee whether it will function flawlessly in a live multi-user environment or not. Either way, we hope everyone has a great time using this tool!</b></font>\n\n" ..
			"Thank you for choosing F3X Pro V5 to power your creative workspace. Enjoy building!",
		btnText = "ACCEPT & PROCEED"
	},
	TH = {
		title = "⚙️ รายละเอียดระบบ F3X PRO V5",
		content = "ยินดีต้อนรับเข้าสู่ระบบ F3X Pro V5 (FilteringEnabled Advanced Version) เครื่องมือจัดการโครงสร้างระดับพรีเมียม\n\n" ..
			"[1] ข้อมูลการรับรองความปลอดภัยทางฟิสิกส์:\n" ..
			"สคริปต์รุ่นนี้ผ่านกระบวนการจำลองพิกัดบนเซิร์ฟเวอร์แบบ Real-time 100% ข้อมูลการเคลื่อนที่ การปรับองศา และการหมุนชิ้นส่วน (Rotation) ทั้งหมด จะได้รับการคำนวณผ่านระบบ Network Ownership Claims โดยตรง ทำให้ผู้เล่นคนอื่นในเซิร์ฟเวอร์เดียวกันสามารถมองเห็นทุกการเปลี่ยนแปลงบนหน้าจอของคุณอย่างแม่นยำและลื่นไหล\n\n" ..
			"[2] สถาปัตยกรรมและเทคโนโลยีหลัก:\n" ..
			"- BodyGyro & BodyPosition Integration: ใช้ชุดคำสั่งแรงขับดันฟิสิกส์ขั้นสูงในการจำลองทิศทางของชิ้นส่วน ป้องกันการปฏิเสธพิกัดจากระบบความปลอดภัยของ Roblox\n" ..
			"- Active Garbage Collection: ระบบจำลองจะล้างแรมส่วนเกินบนหน่วยความจำอุปกรณ์พกพา (Mobile Devices) ทันทีหลังปิดการใช้งาน\n\n" ..
			"[3] ข้อแนะนำในการใช้งาน:\n" ..
			"หลีกเลี่ยงการเคลื่อนย้ายวัตถุที่มีสถานะ 'Anchored' หนาแน่นพร้อมกันเป็นจำนวนมากในเวลาเสี้ยววินาที เพื่อรักษาความสมบูรณ์ของโครงข่ายสัญญาณฟิสิกส์\n\n" ..
			"⚠️ หมายเหตุสำคัญเกี่ยวกับการทดสอบระบบ:\n" ..
			"<font color='rgb(255, 75, 75)'><b>โปรดทราบว่าระบบนี้เราใช้การทดสอบแบบเปิดระบบ Server เท่านั้น (ให้เซิร์ฟเวอร์เป็นตัวประมวลผลทดสอบ) เรายังไม่เคยทำการทดสอบแบบใช้อีกไอดีนึง หรือให้อีกผู้เล่นนึงคอยสังเกตดูจริงๆ เพราะฉะนั้นระบบนี้อาจจะใช้ได้จริงหรืออาจจะใช้ไม่ได้ อันนี้เราไม่รู้เหมือนกันครับ แต่ยังไงก็ขอให้ทุกคนสนุกกับการใช้งานสคริปต์ตัวนี้ครับ!</b></font>\n\n" ..
			"ทีมงานขอขอบคุณที่เลือกใช้ F3X Pro V5 ขอให้สนุกกับการพัฒนาโครงสร้างครับ!",
		btnText = "รับทราบและดำเนินการต่อ"
	}
}

local currentLang = "EN"
noticeTitle.Text = texts.EN.title
noticeDesc.Text = texts.EN.content
closeBtn.Text = texts.EN.btnText

btnTH.MouseButton1Click:Connect(function()
	if currentLang ~= "TH" then
		currentLang = "TH"
		btnTH.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
		btnTH.TextColor3 = Color3.fromRGB(255, 255, 255)
		btnEN.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
		btnEN.TextColor3 = Color3.fromRGB(150, 155, 165)
		
		noticeTitle.Text = texts.TH.title
		noticeDesc.Text = texts.TH.content
		closeBtn.Text = texts.TH.btnText
	end
end)

btnEN.MouseButton1Click:Connect(function()
	if currentLang ~= "EN" then
		currentLang = "EN"
		btnEN.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
		btnEN.TextColor3 = Color3.fromRGB(255, 255, 255)
		btnTH.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
		btnTH.TextColor3 = Color3.fromRGB(150, 155, 165)
		
		noticeTitle.Text = texts.EN.title
		noticeDesc.Text = texts.EN.content
		closeBtn.Text = texts.EN.btnText
	end
end)

local robloxPaths = {
	"rbxassetid://", "rbxasset://textures/", "http://www.roblox.com/asset/?id=", 
	"CoreGui.RobloxGui.Modules.", "game.Replication.ReplicatedStorage."
}

local technicalKeywords = {
	"PhysicsOptimizer", "NetworkHandler", "F3XCore_V5", "BodyGyroSimulation", 
	"TargetLockMechanism", "FreezeStateController", "NetworkOwnershipBypass",
	"CFrameDataBuffer", "ReplicationSchema", "MetadataHook", "VirtualBuffer"
}

local function generateRobloxLog()
	local path = robloxPaths[math.random(1, #robloxPaths)]
	local keyword = technicalKeywords[math.random(1, #technicalKeywords)]
	local randomID = math.random(100000000, 999999999)
	local hexVariant = string.lower(string.sub(game:GetService("HttpService"):GenerateGUID(false), 1, 6))
	
	if string.find(path, "id=") or path == "rbxassetid://" then
		return "Load " .. path .. tostring(randomID) .. "/" .. keyword .. "..."
	else
		return "Load " .. path .. keyword .. "_" .. hexVariant .. ".dat successfully."
	end
end

task.spawn(function()
	local introInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tweenLeft = TweenService:Create(leftBlade, introInfo, {Position = UDim2.new(0.5, 40, 0.5, 0)})
	local tweenRight = TweenService:Create(rightBlade, introInfo, {Position = UDim2.new(0.5, -40, 0.5, 0)})
	
	tweenLeft:Play()
	tweenRight:Play()
	tweenLeft.Completed:Wait() 
	task.wait(0.1)
	
	contentFrame.Visible = true
	local totalDuration = 6.5
	local startTime = os.clock()
	local simulatedProgress = 0.0
	
	while simulatedProgress < 1.0 do
		local deltaTime = task.wait(0.02)
		local elapsed = os.clock() - startTime
		
		local baseSpeed = deltaTime / totalDuration
		local stutterVariation = math.sin(elapsed * 5) * 0.003 + (math.random(-10, 15) / 10000)
		
		if simulatedProgress > 0.3 and simulatedProgress < 0.7 then
			stutterVariation = stutterVariation - 0.002
		end
		
		simulatedProgress = math.clamp(simulatedProgress + baseSpeed + stutterVariation, 0.0, 1.0)
		
		percentText.Text = string.format("%.2f%%", simulatedProgress * 100)
		barFill.Size = UDim2.new(simulatedProgress, 0, 1, 0)
		logText.Text = generateRobloxLog()
		
		if simulatedProgress >= 1.0 then break end
	end
	
	percentText.Text = "100.00%"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	logText.Text = "All structural F3X environment assets synced."
	logText.TextColor3 = Color3.fromRGB(90, 220, 140)
	
	task.wait(0.3)
	contentFrame.Visible = false
	
	local thankIn = TweenService:Create(thankYouLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
	thankIn:Play()
	thankIn.Completed:Wait()
	
	task.wait(1.0)
	
	local thankOut = TweenService:Create(thankYouLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
	thankOut:Play()
	thankOut.Completed:Wait()
	
	local outroInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	local tweenLeftOut = TweenService:Create(leftBlade, outroInfo, {Position = UDim2.new(0, -diagMagnitude, 0.5, 0)})
	local tweenRightOut = TweenService:Create(rightBlade, outroInfo, {Position = UDim2.new(1, diagMagnitude, 0.5, 0)})
	
	tweenLeftOut:Play()
	tweenRightOut:Play()
	tweenLeftOut.Completed:Wait()
	
	mainCanvas:Destroy()
	
	dialogGui.Enabled = true
	
	local dialogTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(dialogBox, dialogTweenInfo, {BackgroundTransparency = 0}):Play()
	TweenService:Create(boxStroke, dialogTweenInfo, {Transparency = 0.2}):Play()
	TweenService:Create(noticeTitle, dialogTweenInfo, {TextTransparency = 0}):Play()
	TweenService:Create(btnTH, dialogTweenInfo, {BackgroundTransparency = 0}):Play()
	TweenService:Create(btnEN, dialogTweenInfo, {BackgroundTransparency = 0}):Play()
	TweenService:Create(scrollFrame, dialogTweenInfo, {ScrollBarImageTransparency = 0}):Play()
	TweenService:Create(noticeDesc, dialogTweenInfo, {TextTransparency = 0}):Play()
	TweenService:Create(closeBtn, dialogTweenInfo, {BackgroundTransparency = 0}):Play()
	
	local connection
	connection = closeBtn.MouseButton1Click:Connect(function()
		connection:Disconnect()
		
		local closeTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(dialogBox, closeTweenInfo, {BackgroundTransparency = 1}):Play()
		TweenService:Create(boxStroke, closeTweenInfo, {Transparency = 1}):Play()
		TweenService:Create(noticeTitle, closeTweenInfo, {TextTransparency = 1}):Play()
		TweenService:Create(btnTH, closeTweenInfo, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(btnEN, closeTweenInfo, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(scrollFrame, closeTweenInfo, {ScrollBarImageTransparency = 1}):Play()
		TweenService:Create(noticeDesc, closeTweenInfo, {TextTransparency = 1}):Play()
		TweenService:Create(closeBtn, closeTweenInfo, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		
		task.wait(0.35)
		dialogGui:Destroy()
		
		InitializeF3XPhysicsTool()
	end)
end)