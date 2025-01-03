local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local OrionLib = loadstring(game:HttpGetAsync('https://raw.githubusercontent.com/Giangplay/Script/main/Orion_Library_PE_V2.lua'))()

OrionLib:MakeNotification({
	Name = "Dream Alt is realy gay.",
	Content = "CALA A BOCA-",
	Image = "rbxassetid://4483345998",
	Time = 5
})

OrionLib:MakeNotification({
	Name = "você está usando a versão grátis do spotify6",
	Content = "💀🥲",
	Image = "rbxassetid://4483345998",
	Time = 5
})

OrionLib:MakeNotification({
	Name = "DreamAlt: Scripters São ruins",
	Content = "Ele jogando com um segs depois de dizee isso:",
	Image = "rbxassetid://4483345998",
	Time = 5
})

local active = false
local squares = {}

local function ensureFolder()
    local msDoorsFolder = workspace:FindFirstChild("MsDoors")
    if not msDoorsFolder then
        msDoorsFolder = Instance.new("Folder")
        msDoorsFolder.Name = "MsDoors"
        msDoorsFolder.Parent = workspace
    end

    local partsFolder = msDoorsFolder:FindFirstChild("parts")
    if not partsFolder then
        partsFolder = Instance.new("Folder")
        partsFolder.Name = "parts"
        partsFolder.Parent = msDoorsFolder
    end

    return partsFolder
end

local function createParticles(square)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 50
    emitter.Speed = NumberRange.new(3, 5)
    emitter.Lifetime = NumberRange.new(1, 2)
    emitter.SpreadAngle = Vector2.new(-180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 162, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255))
    })
    emitter.Parent = square
    return emitter
end

local function createSquare(player, position)
    local partsFolder = ensureFolder()

    local square = Instance.new("Part")
    square.Name = "msdoors_part"
    square.Size = Vector3.new(5, 0.5, 5)
    square.Position = position
    square.Anchored = true
    square.CanCollide = true
    square.BrickColor = BrickColor.new("Bright blue")
    square.Material = Enum.Material.ForceField
    square.Transparency = 0.3
    square.Parent = partsFolder

    return square
end

local function updateTrail()
    for i = #squares, 1, -1 do
        local square = squares[i]
        if square and square.Parent then
            square.Transparency = square.Transparency + 0.01
            if square.Transparency >= 1 then
                square:Destroy()
                table.remove(squares, i)
            end
        end
    end
end

local function monitorPlayer()
    local player = game.Players.LocalPlayer
    local hrp = player.Character:WaitForChild("HumanoidRootPart")
    local lastSquare = nil
    local lastPosition = hrp.Position
    local isStanding = false
    local rotationSpeed = 50
    local colorIndex = 0
    local colors = {
        BrickColor.new("Bright blue"),
        BrickColor.new("Bright violet"),
        BrickColor.new("Really blue"),
        BrickColor.new("Cyan"),
        BrickColor.new("Royal purple")
    }

    RunService.Heartbeat:Connect(function()
        if not active then return end

        local currentPosition = hrp.Position
        isStanding = (currentPosition - lastPosition).Magnitude < 0.1
        lastPosition = currentPosition

        if not lastSquare or (currentPosition - lastSquare.Position).Magnitude > 5 then
            if lastSquare then
                table.insert(squares, lastSquare)
            end
            lastSquare = createSquare(player, Vector3.new(currentPosition.X, currentPosition.Y - 3, currentPosition.Z))
            createParticles(lastSquare)
        end

        if isStanding and lastSquare then
            lastSquare.CFrame = lastSquare.CFrame * CFrame.Angles(0, math.rad(rotationSpeed * 0.1), 0)
            
            colorIndex = (colorIndex + 1) % #colors
            lastSquare.BrickColor = colors[colorIndex + 1]
        end

        updateTrail()
    end)
end

local window = OrionLib:MakeWindow({Name = "Walkfly - BETA", HidePremium = false, SaveConfig = true, ConfigFolder = "OrionTest"})

window:MakeTab({
    Name = "DreamAlt is gay.",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
}):AddToggle({
    Name = "Walkfly",
    Default = false,
    Callback = function(value)
        active = value
        if value then
            monitorPlayer()
        end
    end
})

OrionLib:Init()
