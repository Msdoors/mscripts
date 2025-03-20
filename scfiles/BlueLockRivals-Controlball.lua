-- Serviços do Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Variáveis do jogador e personagem
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

-- Criação de animação
local Animator = Humanoid:WaitForChild("Animator")
local Animation = Instance.new("Animation")
Animation.AnimationId = "rbxassetid://125865269944406"
local AnimationTrack = Animator:LoadAnimation(Animation)

-- Interface do usuário
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Botão de ASCEND
local AscendButton = Instance.new("TextButton")
AscendButton.Size = UDim2.new(0.15, 0, 0.08, 0)
AscendButton.Position = UDim2.new(0.1, 0, 0.2, 0)
AscendButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
AscendButton.Text = "ASCEND"
AscendButton.Parent = ScreenGui

-- Botão de CONTROL
local ControlButton = Instance.new("TextButton")
ControlButton.Size = UDim2.new(0.15, 0, 0.08, 0)
ControlButton.Position = UDim2.new(0.1, 0, 0.8, 0)
ControlButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ControlButton.Text = "CONTROL"
ControlButton.Parent = ScreenGui

-- Painel de controle de velocidade
local SpeedFrame = Instance.new("Frame")
SpeedFrame.Size = UDim2.new(0.3, 0, 0.2, 0)
SpeedFrame.Position = UDim2.new(0.35, 0, 0.6, 0)
SpeedFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
SpeedFrame.Visible = false
SpeedFrame.Parent = ScreenGui

-- Label de velocidade
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0.3, 0)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Speed: 70"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextScaled = true
SpeedLabel.Parent = SpeedFrame

-- Slider de velocidade
local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(0.9, 0, 0.4, 0)
SliderFrame.Position = UDim2.new(0.05, 0, 0.5, 0)
SliderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderFrame.Parent = SpeedFrame

-- Botão do slider
local SliderButton = Instance.new("Frame")
SliderButton.Size = UDim2.new(0.05, 0, 1, 0)
SliderButton.Position = UDim2.new(0.07, 0, 0, 0)
SliderButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
SliderButton.Parent = SliderFrame

-- Créditos
local CreditsLabel = Instance.new("TextLabel")
CreditsLabel.Size = UDim2.new(0.3, 0, 0.1, 0)
CreditsLabel.Position = UDim2.new(0.35, 0, 0.35, 0)
CreditsLabel.BackgroundTransparency = 1
CreditsLabel.Text = "Crackeado por BetterProject"
CreditsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CreditsLabel.TextScaled = true
CreditsLabel.Parent = ScreenGui
CreditsLabel.Visible = false

-- Variáveis de controle
local isAscending = false
local isControlling = false
local heightLevel = 35
local football
local orbitConnection
local ballVelocity
local movementSpeed = 2.5
local ballSpeed = 70

-- Função para encontrar a bola de futebol
local function findFootball()
    return workspace:FindFirstChild("Football")
end

-- Função para controlar a bola em órbita
local function orbitFootball()
    if not football or isControlling then
        return
    end
    
    local angle = 0
    
    -- Adicionar força à bola
    ballVelocity = Instance.new("BodyVelocity")
    ballVelocity.Velocity = Vector3.new(0, 25, 0)
    ballVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    ballVelocity.Parent = football
    
    -- Conectar ao heartbeat para controlar o movimento orbital
    orbitConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not isAscending or not football or not football.Parent or isControlling then
            if ballVelocity then
                ballVelocity:Destroy()
                ballVelocity = nil
            end
            if orbitConnection then
                orbitConnection:Disconnect()
                orbitConnection = nil
            end
            return
        end
        
        angle = angle + (85 * deltaTime)
        local xOffset = math.cos(angle) * 5
        local zOffset = math.sin(angle) * 5
        local targetPosition = Vector3.new(
            HumanoidRootPart.Position.X + xOffset,
            heightLevel + 12,
            HumanoidRootPart.Position.Z + zOffset
        )
        local direction = (targetPosition - football.Position).unit
        football.Velocity = direction * 85
    end)
end

-- Manter o personagem flutuando e permitir movimento
RunService.Heartbeat:Connect(function()
    if isAscending then
        if HumanoidRootPart.Position.Y < heightLevel then
            HumanoidRootPart.Velocity = Vector3.new(0, 25, 0)
        else
            HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            local moveDirection = Humanoid.MoveDirection
            if moveDirection.Magnitude > 0 then
                HumanoidRootPart.Position = HumanoidRootPart.Position + ((moveDirection * movementSpeed) / 10)
            end
        end
    end
end)

-- Função para controlar a bola diretamente
local function controlFootball()
    if not football then
        return
    end
    
    -- Desconectar o controle orbital se estiver ativo
    if orbitConnection then
        orbitConnection:Disconnect()
        orbitConnection = nil
    end
    
    if ballVelocity then
        ballVelocity:Destroy()
        ballVelocity = nil
    end
    
    -- Fazer a câmera seguir a bola
    Camera.CameraSubject = football
    
    -- Adicionar velocidade à bola baseada na direção da câmera
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1000000, 1000000, 1000000)
    bodyVelocity.Parent = football
    
    local controlConnection
    controlConnection = RunService.Heartbeat:Connect(function()
        if not isControlling or not football or not football.Parent then
            bodyVelocity:Destroy()
            Camera.CameraSubject = Character
            if controlConnection then
                controlConnection:Disconnect()
            end
            return
        end
        bodyVelocity.Velocity = Camera.CFrame.LookVector * ballSpeed
    end)
end

-- Evento de click no botão ASCEND
AscendButton.MouseButton1Click:Connect(function()
    if isAscending then
        -- Desativar ascensão
        isAscending = false
        AscendButton.Text = "ASCEND"
        AnimationTrack:Stop()
        
        if orbitConnection then
            orbitConnection:Disconnect()
            orbitConnection = nil
        end
        
        if ballVelocity then
            ballVelocity:Destroy()
            ballVelocity = nil
        end
    else
        -- Ativar ascensão
        isAscending = true
        AscendButton.Text = "STOP"
        AnimationTrack:Play()
        
        football = findFootball()
        if football then
            orbitFootball()
        end
    end
end)

-- Evento de click no botão CONTROL
ControlButton.MouseButton1Click:Connect(function()
    if not football then
        football = findFootball()
        if not football then
            warn("No Ball Found!")
            return
        end
    end
    
    isControlling = not isControlling
    ControlButton.BackgroundColor3 = isControlling and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    SpeedFrame.Visible = isControlling
    
    if isControlling then
        controlFootball()
    elseif isAscending then
        orbitFootball()
    end
end)

-- Controle do slider de velocidade
local isDraggingSlider = false

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = false
    end
end)

RunService.RenderStepped:Connect(function()
    if isDraggingSlider then
        local mouseX = UserInputService:GetMouseLocation().X
        local sliderStart = SliderFrame.AbsolutePosition.X
        local sliderEnd = sliderStart + SliderFrame.AbsoluteSize.X
        local percentage = (mouseX - sliderStart) / (sliderEnd - sliderStart)
        
        SliderButton.Position = UDim2.new(math.clamp(percentage, 0, 1) - 0.025, 0, 0, 0)
        ballSpeed = math.floor(10 + (percentage * 240))
        SpeedLabel.Text = "Speed: " .. tostring(ballSpeed)
    end
end)

-- Atalhos de teclado
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Y then
        AscendButton.MouseButton1Click:Fire()
    elseif input.KeyCode == Enum.KeyCode.U then
        ControlButton.MouseButton1Click:Fire()
    end
end)

-- Mostrar créditos brevemente
CreditsLabel.Visible = true
task.wait(4)
CreditsLabel.Visible = false
