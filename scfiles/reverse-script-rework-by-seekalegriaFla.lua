-- Configurações do Flashback
local flashbacklength = 60 -- Quanto tempo o flashback deve ser armazenado em segundos
local frameRate = 1 / 60 -- Tempo entre quadros (60 FPS padrão)

local name = game:GetService("RbxAnalyticsService"):GetSessionId()
local frames, LP, RS = {}, game:GetService("Players").LocalPlayer, game:GetService("RunService")

pcall(RS.UnbindFromRenderStep, RS, name)

local flashback = {lastinput = false, canrevert = true, isReversing = false}

function flashback:Advance(char, hrp, hum, allowinput)
    if #frames > flashbacklength * 60 then
        table.remove(frames, 1)
    end

    if allowinput and not self.canrevert then
        self.canrevert = true
    end

    if self.lastinput then
        hum.PlatformStand = false
        self.lastinput = false
    end

    table.insert(frames, {
        hrp.CFrame,
        hrp.Velocity,
        hum:GetState(),
        hum.PlatformStand,
        char:FindFirstChildOfClass("Tool"),
        tick() -- Armazena o tempo de captura
    })
end

function flashback:Revert(char, hrp, hum)
    if self.isReversing or #frames == 0 then return end
    self.isReversing = true

    while #frames > 0 and self.isReversing do
        local lastframe = table.remove(frames)
        hrp.CFrame = lastframe[1]
        hrp.Velocity = lastframe[2]
        hum:ChangeState(lastframe[3])
        hum.PlatformStand = lastframe[4]

        local currenttool = char:FindFirstChildOfClass("Tool")
        if lastframe[5] then
            if not currenttool then
                hum:EquipTool(lastframe[5])
            end
        else
            hum:UnequipTools()
        end

        -- Sincronizar com o tempo do jogo
        local currentTime = tick()
        local frameTime = lastframe[6]
        local delay = math.max(0, frameRate - (currentTime - frameTime))
        task.wait(delay) -- Aguarda o tempo necessário para manter o ritmo
    end

    self.isReversing = false
end

-- Criação da interface
local screenGui = Instance.new("ScreenGui", LP:WaitForChild("PlayerGui"))
local button = Instance.new("TextButton", screenGui)
local resetButton = Instance.new("TextButton", screenGui)

-- Configuração do botão "Ativar/Desativar"
button.Text = "Ativar"
button.Font = Enum.Font.Oswald
button.Size = UDim2.new(0, 150, 0, 40)
button.Position = UDim2.new(0, 10, 0, 10) -- Canto superior esquerdo
button.BackgroundColor3 = Color3.new(0, 1, 0)
button.Draggable = true

-- Configuração do botão "Redefinir"
resetButton.Text = "Redefinir"
resetButton.Font = Enum.Font.Oswald
resetButton.Size = UDim2.new(0, 150, 0, 40)
resetButton.Position = UDim2.new(0, 10, 0, 60) -- Logo abaixo do botão "Ativar/Desativar"
resetButton.BackgroundColor3 = Color3.new(1, 1, 0)
resetButton.Draggable = true

-- Variável de controle
local active = false

-- Lógica do botão "Ativar/Desativar"
button.MouseButton1Click:Connect(function()
    active = not active
    button.Text = active and "Desativar" or "Ativar"
    button.BackgroundColor3 = active and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChildWhichIsA("Humanoid")

    if active then
        -- Inicia o flashback
        flashback:Revert(char, hrp, hum)
    else
        -- Para o flashback
        flashback.isReversing = false
    end
end)

-- Lógica do botão "Redefinir"
resetButton.MouseButton1Click:Connect(function()
    frames = {} -- Limpa os quadros armazenados
    flashback.isReversing = false -- Para qualquer reversão em andamento
    active = false -- Reseta o estado do botão "Ativar/Desativar"
    button.Text = "Ativar"
    button.BackgroundColor3 = Color3.new(0, 1, 0)
end)

-- Função que roda a cada frame
local function step()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not flashback.isReversing then
        flashback:Advance(char, hrp, hum, true)
    end
end

-- Vincula a função ao render step
RS:BindToRenderStep(name, 1, step)