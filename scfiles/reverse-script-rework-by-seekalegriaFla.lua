local function getHttpService()
    local success = pcall(function() 
        return game:GetService("HttpService") 
    end)
    
    if success then
        return game:GetService("HttpService")
    else
        return nil
    end
end

local function loadLibrary()
    local methods = {
        function() return game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/Revenant", true) end,
        function() 
            local http = getHttpService()
            if http then
                return http:GetAsync("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/Revenant", true)
            end
            return nil
        end,
        function() 
            if syn and syn.request then
                return syn.request({
                    Url = "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/Revenant",
                    Method = "GET"
                }).Body
            end
            return nil
        end,
        function() 
            if http and http.request then
                return http.request({
                    Url = "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/Revenant",
                    Method = "GET"
                }).Body
            end
            return nil
        end,
        function() 
            if request then
                return request({
                    Url = "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/Revenant",
                    Method = "GET"
                }).Body
            end
            return nil
        end,
        function() 
            if http_request then
                return http_request({
                    Url = "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/Revenant",
                    Method = "GET"
                }).Body
            end
            return nil
        end
    }
    
    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            return loadstring(result)()
        end
    end
    
    -- Fallback if no HTTP methods work
    return {
        DefaultColor = Color3.fromRGB(0, 255, 0),
        Notification = function(options) 
            local msg = Instance.new("Message", workspace)
            msg.Text = options.Text
            game:GetService("Debris"):AddItem(msg, options.Duration or 5)
        end
    }
end

local Library = loadLibrary()

Library.DefaultColor = Color3.fromRGB(0, 255, 0)

Library:Notification({
    Text = "Fornecido por Mscripts | https://dsc.gg/betterstar",
    Duration = 20
})

Library:Notification({
    Text = "Feito por SeekAlegriaFla e modificado por Rhyan57",
    Duration = 3
})

wait(2)

local TweenService = game:GetService("TweenService")
local msproject_Settings = {
    keybinds = {
        toggleFlashback = Enum.KeyCode.Q,
        resetFlashback = Enum.KeyCode.R,
        toggleMenu = Enum.KeyCode.M
    },
    ui = {
        transparency = 0,
        locked = false
    }
}

local flashbacklength = 60
local frameRate = 1 / 60

local name = pcall(function() return game:GetService("RbxAnalyticsService"):GetSessionId() end) and 
             game:GetService("RbxAnalyticsService"):GetSessionId() or 
             "flashback_" .. math.random(1000, 9999)
             
local frames, LP, RS = {}, game:GetService("Players").LocalPlayer, game:GetService("RunService")
local UIS = game:GetService("UserInputService")

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
        tick()
    })
end

function flashback:Revert(char, hrp, hum)
    if self.isReversing or #frames == 0 then return end
    self.isReversing = true

    while #frames > 0 and self.isReversing do
        local lastframe = table.remove(frames)
        hrp.CFrame = lastframe[1]
        hrp.Velocity = lastframe[2]
        
        local success = pcall(function()
            hum:ChangeState(lastframe[3])
        end)
        
        if not success then
            pcall(function()
                hum:SetStateEnabled(lastframe[3], true)
            end)
        end
        
        hum.PlatformStand = lastframe[4]

        local currenttool = char:FindFirstChildOfClass("Tool")
        if lastframe[5] then
            if not currenttool then
                hum:EquipTool(lastframe[5])
            end
        else
            hum:UnequipTools()
        end

        local currentTime = tick()
        local frameTime = lastframe[6]
        local delay = math.max(0, frameRate - (currentTime - frameTime))
        task.wait(delay)
    end

    self.isReversing = false
end

local function createGui()
    local existingGui = LP:FindFirstChild("PlayerGui"):FindFirstChild("FlashbackGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlashbackGui"
    screenGui.ResetOnSpawn = false
    
    -- Handle different property setters
    local success = pcall(function()
        screenGui.Parent = LP:WaitForChild("PlayerGui")
    end)
    
    if not success then
        -- Try alternative methods to set parent
        pcall(function()
            if syn and syn.protect_gui then
                syn.protect_gui(screenGui)
                screenGui.Parent = game:GetService("CoreGui")
            elseif gethui then
                screenGui.Parent = gethui()
            else
                screenGui.Parent = game:GetService("CoreGui")
            end
        end)
    end
    
    return screenGui
end

local screenGui = createGui()

local styles = {
    buttonSize = UDim2.new(0, 180, 0, 45),
    cornerRadius = UDim.new(0, 10),
    menuSize = UDim2.new(0, 320, 0, 450),
    defaultFont = Enum.Font.GothamBold,
    colors = {
        primary = Color3.fromRGB(45, 45, 45),
        secondary = Color3.fromRGB(35, 35, 35),
        accent = Color3.fromRGB(0, 170, 255),
        text = Color3.fromRGB(255, 255, 255)
    }
}

local function createStyledButton(name, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = styles.buttonSize
    button.Position = position
    button.BackgroundColor3 = styles.colors.primary
    button.Font = styles.defaultFont
    button.TextColor3 = styles.colors.text
    button.TextSize = 16
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = styles.cornerRadius
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = styles.colors.accent
    stroke.Thickness = 2
    stroke.Parent = button
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = styles.colors.accent}):Play()
        TweenService:Create(button, TweenInfo.new(0.3), {TextColor3 = styles.colors.primary}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = styles.colors.primary}):Play()
        TweenService:Create(button, TweenInfo.new(0.3), {TextColor3 = styles.colors.text}):Play()
    end)
    
    return button
end

local button = createStyledButton("ToggleButton", UDim2.new(0, 10, 0, 10))
button.Text = "Ativar"

local resetButton = createStyledButton("ResetButton", UDim2.new(0, 10, 0, 65))
resetButton.Text = "Redefinir"

local menuButton = createStyledButton("MenuButton", UDim2.new(0, 10, 0, 120))
menuButton.Text = "Menu"

button.Parent = screenGui
resetButton.Parent = screenGui
menuButton.Parent = screenGui

local menuFrame = Instance.new("Frame")
menuFrame.Name = "SettingsMenu"
menuFrame.Size = styles.menuSize
menuFrame.Position = UDim2.new(1, -330, 0, 10)
menuFrame.BackgroundColor3 = styles.colors.secondary
menuFrame.Visible = false
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = styles.cornerRadius
menuCorner.Parent = menuFrame

local menuTitle = Instance.new("TextLabel")
menuTitle.Text = "Configurações"
menuTitle.Size = UDim2.new(1, 0, 0, 50)
menuTitle.BackgroundColor3 = styles.colors.accent
menuTitle.TextColor3 = styles.colors.text
menuTitle.Font = styles.defaultFont
menuTitle.TextSize = 20
menuTitle.Parent = menuFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = styles.cornerRadius
titleCorner.Parent = menuTitle

local settingsContainer = Instance.new("Frame")
settingsContainer.Size = UDim2.new(1, -20, 1, -60)
settingsContainer.Position = UDim2.new(0, 10, 0, 50)
settingsContainer.BackgroundTransparency = 1
settingsContainer.Parent = menuFrame

local function createToggleSwitch(text, position, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 40)
    container.Position = position
    container.BackgroundTransparency = 1
    container.Parent = settingsContainer
    
    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = styles.colors.text
    label.Font = styles.defaultFont
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 50, 0, 24)
    switch.Position = UDim2.new(1, -50, 0.5, -12)
    switch.BackgroundColor3 = styles.colors.primary
    switch.Text = ""
    switch.Parent = container
    
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 20, 0, 20)
    indicator.Position = UDim2.new(0, 2, 0.5, -10)
    indicator.BackgroundColor3 = styles.colors.text
    indicator.Parent = switch
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = indicator
    
    local toggled = false
    switch.MouseButton1Click:Connect(function()
        toggled = not toggled
        local targetPos = toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        local targetColor = toggled and styles.colors.accent or styles.colors.primary
        
        TweenService:Create(indicator, TweenInfo.new(0.3), {Position = targetPos}):Play()
        TweenService:Create(switch, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
        
        callback(toggled)
    end)
    
    return switch
end

local transparencySwitch = createToggleSwitch("Transparência dos Botões", UDim2.new(0, 0, 0, 20), function(toggled)
    local targetTransparency = toggled and 0.5 or 0
    msproject_Settings.ui.transparency = targetTransparency
    
    for _, obj in ipairs({button, resetButton, menuButton}) do
        TweenService:Create(obj, TweenInfo.new(0.3), {BackgroundTransparency = targetTransparency}):Play()
    end
end)

local lockSwitch = createToggleSwitch("Fixar Botões", UDim2.new(0, 0, 0, 70), function(toggled)
    msproject_Settings.ui.locked = toggled
    for _, obj in ipairs({button, resetButton, menuButton}) do
        obj.Draggable = not toggled
    end
end)

local function createKeybindRow(name, key, yPosition)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.Position = UDim2.new(0, 0, 0, yPosition)
    frame.BackgroundTransparency = 1
    frame.Parent = settingsContainer

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = styles.colors.text
    label.Font = styles.defaultFont
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Text = key.Name
    button.Size = UDim2.new(0.35, 0, 0.8, 0)
    button.Position = UDim2.new(0.65, 0, 0.1, 0)
    button.BackgroundColor3 = styles.colors.primary
    button.TextColor3 = styles.colors.text
    button.Font = styles.defaultFont
    button.TextSize = 14
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    return button
end

local toggleButton = createKeybindRow("Ativar/Desativar", msproject_Settings.keybinds.toggleFlashback, 120)
local resetBindButton = createKeybindRow("Redefinir", msproject_Settings.keybinds.resetFlashback, 170)
local menuBindButton = createKeybindRow("Menu", msproject_Settings.keybinds.toggleMenu, 220)

local function toggleMenu()
    local isMenuVisible = menuFrame.Visible
    
    if not isMenuVisible then
        menuFrame.Position = UDim2.new(1, -10, 0, 10)
        menuFrame.Visible = true
        
        TweenService:Create(menuFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -330, 0, 10)
        }):Play()
    else
        local tween = TweenService:Create(menuFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -10, 0, 10)
        })
        
        tween:Play()
        tween.Completed:Connect(function()
            menuFrame.Visible = false
        end)
    end
    
    menuButton.BackgroundColor3 = not isMenuVisible and 
        styles.colors.accent or 
        styles.colors.primary
end

local function updateKeybind(bindName, newKey)
    msproject_Settings.keybinds[bindName] = newKey
end

local function startKeybindListening(button, bindName)
    local oldText = button.Text
    button.Text = "Pressione uma tecla..."
    
    local connection
    connection = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            updateKeybind(bindName, input.KeyCode)
            button.Text = input.KeyCode.Name
            connection:Disconnect()
        end
    end)
end

toggleButton.MouseButton1Click:Connect(function()
    startKeybindListening(toggleButton, "toggleFlashback")
end)

resetBindButton.MouseButton1Click:Connect(function()
    startKeybindListening(resetBindButton, "resetFlashback")
end)

menuBindButton.MouseButton1Click:Connect(function()
    startKeybindListening(menuBindButton, "toggleMenu")
end)

local active = false

local function toggleFlashback()
    active = not active
    button.Text = active and "Desativar" or "Ativar"
    
    local targetColor = active and Color3.fromRGB(255, 50, 50) or styles.colors.primary
    TweenService:Create(button, TweenInfo.new(0.3), {
        BackgroundColor3 = targetColor
    }):Play()

    local char = LP.Character
    if not char then
        char = LP.CharacterAdded:Wait()
    end
    
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChildWhichIsA("Humanoid")

    if active then
        flashback:Revert(char, hrp, hum)
    else
        flashback.isReversing = false
    end
end

local function resetFlashback()
    frames = {}
    flashback.isReversing = false
    active = false
    button.Text = "Ativar"
    
    TweenService:Create(button, TweenInfo.new(0.3), {
        BackgroundColor3 = styles.colors.primary
    }):Play()
    
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flash.BackgroundTransparency = 0.8
    flash.Parent = resetButton
    
    local flashCorner = Instance.new("UICorner")
    flashCorner.CornerRadius = styles.cornerRadius
    flashCorner.Parent = flash
    
    TweenService:Create(flash, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    }):Play()
    
    game:GetService("Debris"):AddItem(flash, 0.5)
end

button.MouseButton1Click:Connect(toggleFlashback)
resetButton.MouseButton1Click:Connect(resetFlashback)
menuButton.MouseButton1Click:Connect(toggleMenu)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == msproject_Settings.keybinds.toggleFlashback then
        toggleFlashback()
    elseif input.KeyCode == msproject_Settings.keybinds.resetFlashback then
        resetFlashback()
    elseif input.KeyCode == msproject_Settings.keybinds.toggleMenu then
        toggleMenu()
    end
end)

local function step()
    local char = LP.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    
    if not hrp or not hum then return end
    
    if not flashback.isReversing then
        flashback:Advance(char, hrp, hum, true)
    end
end

LP.CharacterAdded:Connect(function()
    frames = {}
    flashback.isReversing = false
    active = false
    button.Text = "Ativar"
    button.BackgroundColor3 = styles.colors.primary
end)

local bindSuccess = pcall(function()
    RS:BindToRenderStep(name, 1, step)
end)

if not bindSuccess then
    local steppedConnection
    steppedConnection = RS.Stepped:Connect(function()
        step()
    end)
end

local function createNotification(text, duration)
    duration = duration or 2
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 250, 0, 60)
    notification.Position = UDim2.new(0.5, -125, 0, -70)
    notification.BackgroundColor3 = styles.colors.primary
    notification.Parent = screenGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = styles.cornerRadius
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Text = text
    notifText.Size = UDim2.new(1, -20, 1, 0)
    notifText.Position = UDim2.new(0, 10, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.TextColor3 = styles.colors.text
    notifText.Font = styles.defaultFont
    notifText.TextSize = 14
    notifText.TextWrapped = true
    notifText.Parent = notification
    
    TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -125, 0, 20)
    }):Play()
    
    task.delay(duration, function()
        local fadeOut = TweenService:Create(notification, TweenInfo.new(0.5), {
            Position = UDim2.new(0.5, -125, 0, -70),
            BackgroundTransparency = 1
        })
        
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

local function addActionNotifications()
    local notifConn1 = button.MouseButton1Click:Connect(function()
        createNotification(active and "Flashback Ativado" or "Flashback Desativado")
    end)
    
    local notifConn2 = resetButton.MouseButton1Click:Connect(function()
        createNotification("Flashback Redefinido")
    end)
end

addActionNotifications()

local function createTooltip(parent, text)
    local tooltip = Instance.new("TextLabel")
    tooltip.Size = UDim2.new(0, 200, 0, 30)
    tooltip.BackgroundColor3 = styles.colors.secondary
    tooltip.TextColor3 = styles.colors.text
    tooltip.Font = styles.defaultFont
    tooltip.TextSize = 14
    tooltip.Text = text
    tooltip.Visible = false
    tooltip.Parent = screenGui
    
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 6)
    tooltipCorner.Parent = tooltip
    
    parent.MouseEnter:Connect(function()
        tooltip.Position = UDim2.new(0, parent.AbsolutePosition.X + parent.AbsoluteSize.X + 10, 0, parent.AbsolutePosition.Y)
        tooltip.Visible = true
    end)
    
    parent.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
end

createTooltip(button, "Ativar/Desativar o Flashback")
createTooltip(resetButton, "Redefinir o estado do Flashback")
createTooltip(menuButton, "Abrir menu de configurações")

local successful = "Script de Flashback carregado com sucesso!"
Library:Notification({
    Text = successful,
    Duration = 3
})
