-- Services
local TweenService = game:GetService("TweenService")

-- Create main UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MscriptsUI"
ScreenGui.Parent = game:GetService("CoreGui")

-- Create loading frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "LoadingFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(43, 45, 49)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Add corner radius
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 16)
Corner.Parent = MainFrame

-- Add blur effect
local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = game:GetService("Lighting")

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "Mscripts"
Title.TextColor3 = Color3.fromRGB(88, 101, 242)
Title.TextSize = 24
Title.Parent = MainFrame

-- Description
local Description = Instance.new("TextLabel")
Description.Name = "Description"
Description.Size = UDim2.new(1, -40, 0, 40)
Description.Position = UDim2.new(0, 20, 0, 50)
Description.BackgroundTransparency = 1
Description.Font = Enum.Font.Gotham
Description.Text = "Obrigado por escolher a Mscripts!"
Description.TextColor3 = Color3.fromRGB(185, 187, 190)
Description.TextSize = 16
Description.TextWrapped = true
Description.Parent = MainFrame

-- Progress Bar Background
local ProgressBG = Instance.new("Frame")
ProgressBG.Name = "ProgressBG"
ProgressBG.Size = UDim2.new(1, -40, 0, 6)
ProgressBG.Position = UDim2.new(0, 20, 1, -20)
ProgressBG.BackgroundColor3 = Color3.fromRGB(26, 27, 30)
ProgressBG.BorderSizePixel = 0
ProgressBG.Parent = MainFrame

local ProgressBGCorner = Instance.new("UICorner")
ProgressBGCorner.CornerRadius = UDim.new(0, 3)
ProgressBGCorner.Parent = ProgressBG

-- Progress Bar
local ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressBG

local ProgressBarCorner = Instance.new("UICorner")
ProgressBarCorner.CornerRadius = UDim.new(0, 3)
ProgressBarCorner.Parent = ProgressBar

-- Status Label
local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -40, 0, 20)
Status.Position = UDim2.new(0, 20, 1, -45)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.Gotham
Status.Text = "Iniciando..."
Status.TextColor3 = Color3.fromRGB(185, 187, 190)
Status.TextSize = 14
Status.Parent = MainFrame

-- Watermark
local Watermark = Instance.new("TextLabel")
Watermark.Name = "Watermark"
Watermark.Size = UDim2.new(0, 100, 0, 30)
Watermark.Position = UDim2.new(0, 20, 1, -50)
Watermark.BackgroundTransparency = 1
Watermark.Font = Enum.Font.GothamBold
Watermark.Text = "Mscripts"
Watermark.TextColor3 = Color3.fromRGB(88, 101, 242)
Watermark.TextSize = 18
Watermark.TextTransparency = 1
Watermark.Parent = ScreenGui

-- Functions
local function updateStatus(text)
    Status.Text = text
end

local function updateProgress(progress)
    local tween = TweenService:Create(ProgressBar, TweenInfo.new(0.3), {
        Size = UDim2.new(progress, 0, 1, 0)
    })
    tween:Play()
    return tween
end

-- Loading sequence
local function startLoading()
    TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 20}):Play()
    
    spawn(function()
        updateStatus("Verificando script...")
        local tween1 = updateProgress(0.3)
        tween1.Completed:Wait()
        wait(0.5)
        
        updateStatus("Baixando recursos...")
        local tween2 = updateProgress(0.6)
        tween2.Completed:Wait()
        wait(0.5)
        
        updateStatus("Executando script...")
        local tween3 = updateProgress(0.9)
        tween3.Completed:Wait()
        
        local success, result = pcall(function()
        end)
        
        if success then
            updateStatus("Script executado com sucesso!")
            local tween4 = updateProgress(1)
            tween4.Completed:Wait()
            wait(1)
            
            local fadeOut = TweenService:Create(MainFrame, TweenInfo.new(0.5), {
                Position = UDim2.new(0.5, -150, -0.5, -75)
            })
            fadeOut:Play()
            TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 0}):Play()
            
            Watermark.TextTransparency = 0
            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 110))
            })
            gradient.Parent = Watermark
            
            spawn(function()
                while true do
                    local tween = TweenService:Create(gradient, TweenInfo.new(2), {
                        Offset = Vector2.new(1, 0)
                    })
                    tween:Play()
                    tween.Completed:Wait()
                    gradient.Offset = Vector2.new(-1, 0)
                end
            end)
        else
            updateStatus("Erro ao executar o script!")
            wait(2)
            ScreenGui:Destroy()
            Blur:Destroy()
        end
    end)
end

startLoading()
