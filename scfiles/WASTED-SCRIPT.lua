local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CONFIG = {
    LYRICS_URL = "https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/Msdoors/lirycs.txt",
    MUSIC_URL = "https://github.com/Msdoors/Msdoors.gg/raw/refs/heads/main/Scripts/Msdoors/INIT_SOUND.mp3",
    IMAGE_URL = "https://raw.githubusercontent.com/RhyanXG7/host-de-imagens/refs/heads/BetterStar/imagens-Host/download.jpeg",
    FONT_URL = "https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&display=swap",
    VOLUME = 0.8,
    LYRICS_DURATION = 4.5,
    PARTICLE_COUNT = 80,
    MAX_VISIBLE_LYRICS = 3,
    MUSIC_TITLE = "WASTED (NIGHTCORE)",
    MUSIC_ARTIST = "JUICE WRLD, LilStoic",
    EQ_BARS = 20,
    EQ_ENABLED = true,
    PARTICLES_ENABLED = true
}

local isLoaded = false
local loadingProgress = 0
local fontLoaded = false

local function DownloadAsset(url, fileName, fileType)
    local success, data = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        writefile(fileName, data)
        return (getcustomasset or getsynasset)(fileName)
    end
    
    warn("Falha ao baixar: " .. url)
    return nil
end

local function LoadCustomFont()
    if not fontLoaded then
        local fontSuccess, fontData = pcall(function()
            return game:HttpGet("https://fonts.gstatic.com/s/orbitron/v25/yMJMMIlzdpvBhQQL_SC3X9yhF25-T1nyGy6BoWgz.woff2")
        end)
        
        if fontSuccess then
            writefile("orbitron_font.woff2", fontData)
            fontLoaded = true
        end
    end
end

local function ParseLyrics(url)
    local success, lyricsData = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and lyricsData then
        local parsedLyrics = {}
        for line in lyricsData:gmatch("[^\r\n]+") do
            if line:match("%S") then
                local timePattern = "%[(%d+):(%d+)%.(%d+)%](.+)"
                local minutes, seconds, centiseconds, text = line:match(timePattern)
                
                if minutes and seconds and centiseconds and text then
                    local totalTime = tonumber(minutes) * 60 + tonumber(seconds) + tonumber(centiseconds) / 100
                    local cleanText = text:gsub("^%s*(.-)%s*$", "%1")
                    if cleanText ~= "" then
                        table.insert(parsedLyrics, {
                            time = totalTime,
                            text = cleanText,
                            endTime = totalTime + CONFIG.LYRICS_DURATION
                        })
                    end
                end
            end
        end
        
        table.sort(parsedLyrics, function(a, b) return a.time < b.time end)
        return parsedLyrics
    end
    
    return {{time = 0, text = "♪ Música sem letras disponíveis ♪", endTime = 999}}
end

local function CreateProtectedGUI()
    for _, gui in pairs(CoreGui:GetChildren()) do
        if gui.Name == "UltimateMusicPlayer" then
            gui:Destroy()
        end
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UltimateMusicPlayer"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        screenGui.Parent = CoreGui
    end)
    
    if not screenGui.Parent then
        screenGui.Parent = player:WaitForChild("PlayerGui")
    end
    
    return screenGui
end

local function CreateLoadingScreen(parent)
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Name = "LoadingScreen"
    loadingFrame.Size = UDim2.new(1, 0, 1, 0)
    loadingFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    loadingFrame.BackgroundTransparency = 0.2
    loadingFrame.BorderSizePixel = 0
    loadingFrame.Parent = parent
    
    local loadingContainer = Instance.new("Frame")
    loadingContainer.Size = UDim2.new(0, 300, 0, 120)
    loadingContainer.Position = UDim2.new(0.5, -150, 0.5, -60)
    loadingContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    loadingContainer.BorderSizePixel = 0
    loadingContainer.Parent = loadingFrame
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 15)
    containerCorner.Parent = loadingContainer
    
    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingText"
    loadingText.Size = UDim2.new(1, -20, 0, 30)
    loadingText.Position = UDim2.new(0, 10, 0, 20)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "🎵 Carregando Player Musical..."
    loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadingText.TextScaled = true
    loadingText.Font = Enum.Font.JosefinSans
    loadingText.Parent = loadingContainer
    
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(0.9, 0, 0, 8)
    progressBg.Position = UDim2.new(0.05, 0, 0, 70)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = loadingContainer
    
    local progBgCorner = Instance.new("UICorner")
    progBgCorner.CornerRadius = UDim.new(0, 4)
    progBgCorner.Parent = progressBg
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local progFillCorner = Instance.new("UICorner")
    progFillCorner.CornerRadius = UDim.new(0, 4)
    progFillCorner.Parent = progressFill
    
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.Size = UDim2.new(1, 0, 0, 20)
    percentLabel.Position = UDim2.new(0, 0, 0, 90)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = "0%"
    percentLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
    percentLabel.TextScaled = true
    percentLabel.Font = Enum.Font.JosefinSans
    percentLabel.Parent = loadingContainer
    
    return loadingFrame, progressFill, loadingText, percentLabel
end

local function CreateLyricsDisplay(parent)
    local lyricsFrame = Instance.new("Frame")
    lyricsFrame.Name = "LyricsDisplay"
    lyricsFrame.Size = UDim2.new(1, 0, 1, 0)
    lyricsFrame.Position = UDim2.new(0, 0, 0, 0)
    lyricsFrame.BackgroundTransparency = 1
    lyricsFrame.Parent = parent
    
    return lyricsFrame
end

local function CreateEqualizer(parent)
    if not CONFIG.EQ_ENABLED then return nil, {} end
    
    local eqFrame = Instance.new("Frame")
    eqFrame.Name = "Equalizer"
    eqFrame.Size = UDim2.new(0, 40, 1, 0)
    eqFrame.Position = UDim2.new(1, -50, 0, 0)
    eqFrame.BackgroundTransparency = 1
    eqFrame.BorderSizePixel = 0
    eqFrame.Parent = parent
    
    local bars = {}
    local barHeight = workspace.CurrentCamera.ViewportSize.Y / CONFIG.EQ_BARS
    
    for i = 1, CONFIG.EQ_BARS do
        local bar = Instance.new("Frame")
        bar.Name = "Bar" .. i
        bar.Size = UDim2.new(0, 6, 0, 5)
        bar.Position = UDim2.new(0, 5, 0, (i-1) * barHeight + barHeight/2)
        bar.BackgroundColor3 = Color3.fromHSV((i-1) / CONFIG.EQ_BARS * 0.8, 1, 1)
        bar.BorderSizePixel = 0
        bar.Parent = eqFrame
        
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 3)
        barCorner.Parent = bar
        
        local glow = Instance.new("UIStroke")
        glow.Color = bar.BackgroundColor3
        glow.Thickness = 2
        glow.Transparency = 0.3
        glow.Parent = bar
        
        table.insert(bars, bar)
    end
    
    return eqFrame, bars
end

local function CreateModernUI(parent)
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(0, 450, 0, 200)
    mainContainer.Position = UDim2.new(0, 30, 1, -240)
    mainContainer.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
    mainContainer.BackgroundTransparency = 0.05
    mainContainer.BorderSizePixel = 0
    mainContainer.Parent = parent
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = mainContainer
    
    local glowEffect = Instance.new("UIStroke")
    glowEffect.Color = Color3.fromRGB(120, 0, 255)
    glowEffect.Thickness = 3
    glowEffect.Transparency = 0.3
    glowEffect.Parent = mainContainer
    
    local gradientBg = Instance.new("UIGradient")
    gradientBg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 45)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 25, 55))
    }
    gradientBg.Rotation = 135
    gradientBg.Parent = mainContainer
    
    local albumArt = Instance.new("ImageLabel")
    albumArt.Name = "AlbumArt"
    albumArt.Size = UDim2.new(0, 140, 0, 140)
    albumArt.Position = UDim2.new(0, 20, 0.5, -70)
    albumArt.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    albumArt.BorderSizePixel = 0
    albumArt.ScaleType = Enum.ScaleType.Crop
    albumArt.Parent = mainContainer
    
    local artCorner = Instance.new("UICorner")
    artCorner.CornerRadius = UDim.new(0, 15)
    artCorner.Parent = albumArt
    
    local artGlow = Instance.new("UIStroke")
    artGlow.Color = Color3.fromRGB(255, 100, 200)
    artGlow.Thickness = 3
    artGlow.Transparency = 0.4
    artGlow.Parent = albumArt
    
    local infoContainer = Instance.new("Frame")
    infoContainer.Name = "InfoContainer"
    infoContainer.Size = UDim2.new(0, 270, 0, 140)
    infoContainer.Position = UDim2.new(0, 170, 0.5, -70)
    infoContainer.BackgroundTransparency = 1
    infoContainer.Parent = mainContainer
    
    local songTitle = Instance.new("TextLabel")
    songTitle.Name = "SongTitle"
    songTitle.Size = UDim2.new(1, 0, 0, 35)
    songTitle.Position = UDim2.new(0, 0, 0, 10)
    songTitle.BackgroundTransparency = 1
    songTitle.Text = CONFIG.MUSIC_TITLE
    songTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    songTitle.TextScaled = true
    songTitle.Font = Enum.Font.JosefinSans
    songTitle.TextXAlignment = Enum.TextXAlignment.Left
    songTitle.Parent = infoContainer
    
    local artistLabel = Instance.new("TextLabel")
    artistLabel.Name = "ArtistLabel"
    artistLabel.Size = UDim2.new(1, 0, 0, 25)
    artistLabel.Position = UDim2.new(0, 0, 0, 50)
    artistLabel.BackgroundTransparency = 1
    artistLabel.Text = "🎤 " .. CONFIG.MUSIC_ARTIST
    artistLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
    artistLabel.TextScaled = true
    artistLabel.Font = Enum.Font.JosefinSans
    artistLabel.TextXAlignment = Enum.TextXAlignment.Left
    artistLabel.Parent = infoContainer
    
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBackground"
    progressBg.Size = UDim2.new(0.75, 0, 0, 8)
    progressBg.Position = UDim2.new(0, 0, 0, 85)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = infoContainer
    
    local progBgCorner = Instance.new("UICorner")
    progBgCorner.CornerRadius = UDim.new(0, 4)
    progBgCorner.Parent = progressBg
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local progGradient = Instance.new("UIGradient")
    progGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255))
    }
    progGradient.Parent = progressBar
    
    local progCorner = Instance.new("UICorner")
    progCorner.CornerRadius = UDim.new(0, 4)
    progCorner.Parent = progressBar
    
    local timeDisplay = Instance.new("TextLabel")
    timeDisplay.Name = "TimeDisplay"
    timeDisplay.Size = UDim2.new(0.25, 0, 0, 25)
    timeDisplay.Position = UDim2.new(0.75, 5, 0, 75)
    timeDisplay.BackgroundTransparency = 1
    timeDisplay.Text = "00:00"
    timeDisplay.TextColor3 = Color3.fromRGB(150, 150, 180)
    timeDisplay.TextScaled = true
    timeDisplay.Font = Enum.Font.JosefinSans
    timeDisplay.TextXAlignment = Enum.TextXAlignment.Right
    timeDisplay.Parent = infoContainer
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.new(1, 0, 0, 30)
    controlsFrame.Position = UDim2.new(0, 0, 0, 105)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = infoContainer
    
    local playBtn = Instance.new("TextButton")
    playBtn.Name = "PlayButton"
    playBtn.Size = UDim2.new(0, 40, 0, 30)
    playBtn.Position = UDim2.new(0, 0, 0, 0)
    playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
    playBtn.Text = "▶"
    playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.TextScaled = true
    playBtn.Font = Enum.Font.JosefinSans
    playBtn.BorderSizePixel = 0
    playBtn.Parent = controlsFrame
    
    local playCorner = Instance.new("UICorner")
    playCorner.CornerRadius = UDim.new(0, 8)
    playCorner.Parent = playBtn
    
    local stopBtn = Instance.new("TextButton")
    stopBtn.Name = "StopButton"
    stopBtn.Size = UDim2.new(0, 35, 0, 30)
    stopBtn.Position = UDim2.new(0, 50, 0, 0)
    stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    stopBtn.Text = "■"
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.TextScaled = true
    stopBtn.Font = Enum.Font.JosefinSans
    stopBtn.BorderSizePixel = 0
    stopBtn.Parent = controlsFrame
    
    local stopCorner = Instance.new("UICorner")
    stopCorner.CornerRadius = UDim.new(0, 8)
    stopCorner.Parent = stopBtn
    
    local hideBtn = Instance.new("TextButton")
    hideBtn.Name = "HideButton"
    hideBtn.Size = UDim2.new(0, 35, 0, 30)
    hideBtn.Position = UDim2.new(0, 95, 0, 0)
    hideBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 140)
    hideBtn.Text = "−"
    hideBtn.TextColor3 = Color3.new(1, 1, 1)
    hideBtn.TextScaled = true
    hideBtn.Font = Enum.Font.JosefinSans
    hideBtn.BorderSizePixel = 0
    hideBtn.Parent = controlsFrame
    
    local hideCorner = Instance.new("UICorner")
    hideCorner.CornerRadius = UDim.new(0, 8)
    hideCorner.Parent = hideBtn
    
    local eqToggleBtn = Instance.new("TextButton")
    eqToggleBtn.Name = "EQToggleButton"
    eqToggleBtn.Size = UDim2.new(0, 35, 0, 30)
    eqToggleBtn.Position = UDim2.new(0, 140, 0, 0)
    eqToggleBtn.BackgroundColor3 = CONFIG.EQ_ENABLED and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(80, 80, 80)
    eqToggleBtn.Text = "♫"
    eqToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    eqToggleBtn.TextScaled = true
    eqToggleBtn.Font = Enum.Font.JosefinSans
    eqToggleBtn.BorderSizePixel = 0
    eqToggleBtn.Parent = controlsFrame
    
    local eqToggleCorner = Instance.new("UICorner")
    eqToggleCorner.CornerRadius = UDim.new(0, 8)
    eqToggleCorner.Parent = eqToggleBtn
    
    local particleToggleBtn = Instance.new("TextButton")
    particleToggleBtn.Name = "ParticleToggleButton"
    particleToggleBtn.Size = UDim2.new(0, 35, 0, 30)
    particleToggleBtn.Position = UDim2.new(0, 185, 0, 0)
    particleToggleBtn.BackgroundColor3 = CONFIG.PARTICLES_ENABLED and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(80, 80, 80)
    particleToggleBtn.Text = "✦"
    particleToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    particleToggleBtn.TextScaled = true
    particleToggleBtn.Font = Enum.Font.JosefinSans
    particleToggleBtn.BorderSizePixel = 0
    particleToggleBtn.Parent = controlsFrame
    
    local particleToggleCorner = Instance.new("UICorner")
    particleToggleCorner.CornerRadius = UDim.new(0, 8)
    particleToggleCorner.Parent = particleToggleBtn
    
    return mainContainer, albumArt, songTitle, artistLabel, progressBar, timeDisplay, playBtn, stopBtn, hideBtn, eqToggleBtn, particleToggleBtn
end

local lyricEffects = {
    "typewriter", "fade", "scale", "bounce", "spin", "glow", "wave", "slide"
}

local function GetRandomPosition()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local margin = 100
    
    local x = math.random(margin, viewportSize.X - margin - 400) / viewportSize.X
    local y = math.random(margin, viewportSize.Y - margin - 80) / viewportSize.Y
    
    return UDim2.new(x, 0, y, 0)
end

local function CreateLyricElement(text, container, intensity, isActive)
    local lyricContainer = Instance.new("Frame")
    lyricContainer.Name = "LyricContainer_" .. tostring(math.random(1000, 9999))
    lyricContainer.Size = UDim2.new(0, 400, 0, 80)
    lyricContainer.Position = GetRandomPosition()
    lyricContainer.BackgroundTransparency = 1
    lyricContainer.Parent = container
    
    local lyric = Instance.new("TextLabel")
    lyric.Name = "Lyric"
    lyric.Size = UDim2.new(1, 0, 1, 0)
    lyric.BackgroundTransparency = 1
    lyric.Text = text
    lyric.TextScaled = true
    lyric.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.GothamBold
    lyric.TextStrokeTransparency = 0.1
    lyric.TextStrokeColor3 = Color3.new(0, 0, 0)
    lyric.Parent = lyricContainer
    
    local underline = Instance.new("Frame")
    underline.Name = "Underline"
    underline.Size = UDim2.new(0, 0, 0, 4)
    underline.Position = UDim2.new(0, 0, 0.85, 0)
    underline.BorderSizePixel = 0
    underline.Parent = lyricContainer
    
    local underCorner = Instance.new("UICorner")
    underCorner.CornerRadius = UDim.new(0, 2)
    underCorner.Parent = underline
    
    local hue = (tick() * 0.3 + math.random()) % 1
    local mainColor = Color3.fromHSV(hue, 0.9, intensity)
    lyric.TextColor3 = mainColor
    underline.BackgroundColor3 = mainColor
    
    local glow = Instance.new("UIStroke")
    glow.Color = Color3.fromHSV(hue, 1, intensity)
    glow.Thickness = math.floor(intensity * 6)
    glow.Transparency = 0.3
    glow.Parent = lyric
    
    local effect = lyricEffects[math.random(1, #lyricEffects)]
    
    if effect == "typewriter" then
        lyric.Text = ""
        local fullText = text
        spawn(function()
            for i = 1, #fullText do
                lyric.Text = fullText:sub(1, i)
                wait(0.03)
            end
        end)
    elseif effect == "fade" then
        lyric.TextTransparency = 1
        local fadeTween = TweenService:Create(lyric,
            TweenInfo.new(1, Enum.EasingStyle.Quad),
            {TextTransparency = 0}
        )
        fadeTween:Play()
    elseif effect == "scale" then
        lyricContainer.Size = UDim2.new(0, 0, 0, 80)
        local scaleTween = TweenService:Create(lyricContainer,
            TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 400, 0, 80)}
        )
        scaleTween:Play()
    elseif effect == "bounce" then
        local bounceTween = TweenService:Create(lyricContainer,
            TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
            {Position = lyricContainer.Position}
        )
        bounceTween:Play()
    elseif effect == "spin" then
        lyric.Rotation = -180
        local spinTween = TweenService:Create(lyric,
            TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Rotation = 0}
        )
        spinTween:Play()
    elseif effect == "glow" then
        glow.Thickness = 0
        local glowTween = TweenService:Create(glow,
            TweenInfo.new(1.2, Enum.EasingStyle.Quad),
            {Thickness = intensity * 8}
        )
        glowTween:Play()
    elseif effect == "wave" then
        spawn(function()
            for i = 1, 10 do
                lyric.Position = UDim2.new(0, math.sin(i * 0.5) * 5, 0, 0)
                wait(0.1)
            end
            lyric.Position = UDim2.new(0, 0, 0, 0)
        end)
    elseif effect == "slide" then
        local originalPos = lyricContainer.Position
        lyricContainer.Position = UDim2.new(-0.5, 0, originalPos.Y.Scale, originalPos.Y.Offset)
        local slideTween = TweenService:Create(lyricContainer,
            TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = originalPos}
        )
        slideTween:Play()
    end
    
    if isActive then
        local underlineTween = TweenService:Create(underline,
            TweenInfo.new(1.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 0, 4)}
        )
        underlineTween:Play()
    end
    
    return lyricContainer, lyric, underline
end

local function CreateParticleSystem(parent)
    if not CONFIG.PARTICLES_ENABLED then return {}, nil end
    
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleSystem"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.Parent = parent
    
    local particles = {}
    
    for i = 1, CONFIG.PARTICLE_COUNT do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = Color3.fromHSV(math.random(), 0.8, 0.9)
        particle.BorderSizePixel = 0
        particle.BackgroundTransparency = math.random(0.3, 0.8)
        particle.Parent = particleContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        table.insert(particles, {
            frame = particle,
            velX = (math.random() - 0.5) * 0.002,
            velY = (math.random() - 0.5) * 0.002,
            life = math.random(150, 400),
            maxLife = math.random(150, 400)
        })
    end
    
    return particles, particleContainer
end

local function UpdateProgress(progressFill, loadingText, percentLabel, progress, text)
    loadingProgress = progress
    local tween = TweenService:Create(progressFill,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad),
        {Size = UDim2.new(progress, 0, 1, 0)}
    )
    tween:Play()
    
    loadingText.Text = text
    percentLabel.Text = math.floor(progress * 100) .. "%"
end

local function CreateMusicPlayer()
    local gui = CreateProtectedGUI()
    local loadingScreen, progressFill, loadingText, percentLabel = CreateLoadingScreen(gui)
    
    spawn(function()
        UpdateProgress(progressFill, loadingText, percentLabel, 0.1, "🎵 Inicializando componentes...")
        wait(0.5)
        
        UpdateProgress(progressFill, loadingText, percentLabel, 0.2, "🔤 Carregando fonte externa...")
        LoadCustomFont()
        wait(0.2)
        
        UpdateProgress(progressFill, loadingText, percentLabel, 0.4, "📥 Baixando letras...")
        local lyrics = ParseLyrics(CONFIG.LYRICS_URL)
        wait(0.3)
        
        UpdateProgress(progressFill, loadingText, percentLabel, 0.7, "🎨 Baixando capa do álbum...")
        local imageId = DownloadAsset(CONFIG.IMAGE_URL, "album_cover.jpg", "image")
        wait(0.3)
        
        UpdateProgress(progressFill, loadingText, percentLabel, 0.9, "🎶 Preparando áudio...")
        local soundId = DownloadAsset(CONFIG.MUSIC_URL, "main_song.mp3", "audio")
        wait(0.3)
        
        UpdateProgress(progressFill, loadingText, percentLabel, 1.0, "✅ Carregamento concluído!")
        wait(0.5)
        
        local fadeOut = TweenService:Create(loadingScreen,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad),
            {BackgroundTransparency = 1}
        )
        fadeOut:Play()
        
        fadeOut.Completed:Connect(function()
            loadingScreen:Destroy()
            isLoaded = true
            
            local lyricsDisplay = CreateLyricsDisplay(gui)
            local uiContainer, albumArt, songTitle, artistLabel, progressBar, timeDisplay, playBtn, stopBtn, hideBtn, eqToggleBtn, particleToggleBtn = CreateModernUI(gui)
            local eqFrame, eqBars = CreateEqualizer(gui)
            local particles, particleContainer = CreateParticleSystem(gui)
            
            local currentSound = nil
            local isPlaying = false
            local isHidden = false
            local activeLyrics = {}
            local connections = {}
            local cleanupTasks = {}
            local eqEnabled = CONFIG.EQ_ENABLED
            local particlesEnabled = CONFIG.PARTICLES_ENABLED
            
            if imageId then
                albumArt.Image = imageId
            end
            
            local function FormatTime(seconds)
                local mins = math.floor(seconds / 60)
                local secs = math.floor(seconds % 60)
                return string.format("%02d:%02d", mins, secs)
            end
            
            local function CleanupLyrics()
                for _, lyricData in ipairs(activeLyrics) do
                    if lyricData.container and lyricData.container.Parent then
                        lyricData.container:Destroy()
                    end
                end
                activeLyrics = {}
                
                for _, task in ipairs(cleanupTasks) do
                    if task then task:Disconnect() end
                end
                cleanupTasks = {}
            end
            
            local function UpdateEqualizer(volume)
                if not eqEnabled or not eqFrame.Visible then return end
                
                for i, bar in ipairs(eqBars) do
                    local height = math.random(5, 45) * (volume + 0.3)
                    local colorHue = (i-1) / CONFIG.EQ_BARS * 0.8
                    
                    local tween = TweenService:Create(bar,
                        TweenInfo.new(0.08, Enum.EasingStyle.Quad),
                        {
                            Size = UDim2.new(0, 6, 0, height),
                            BackgroundColor3 = Color3.fromHSV(colorHue, 1, 0.7 + volume * 0.3)
                        }
                    )
                    tween:Play()
                end
            end
            
            local function UpdateParticles()
                if not particlesEnabled or not particleContainer.Visible then return end
                
                for i, particle in ipairs(particles) do
                    if particle.frame.Parent then
                        local pos = particle.frame.Position
                        local newX = pos.X.Scale + particle.velX
                        local newY = pos.Y.Scale + particle.velY
                        
                        if newX > 1 then newX = 0 elseif newX < 0 then newX = 1 end
                        if newY > 1 then newY = 0 elseif newY < 0 then newY = 1 end
                        
                        particle.frame.Position = UDim2.new(newX, 0, newY, 0)
                        particle.life = particle.life - 1
                        
                        local alpha = particle.life / particle.maxLife
                        particle.frame.BackgroundTransparency = 1 - (alpha * 0.6)
                        
                        if particle.life <= 0 then
                            particle.frame.BackgroundColor3 = Color3.fromHSV(math.random(), 0.8, 0.9)
                            particle.life = particle.maxLife
                        end
                    end
                end
            end
            
            local function UpdateLyrics()
                if not isPlaying or not currentSound then return end
                
                local currentTime = currentSound.TimePosition
                local duration = currentSound.TimeLength or 1
                
                timeDisplay.Text = FormatTime(currentTime)
                
                local progress = math.min(currentTime / duration, 1)
                progressBar.Size = UDim2.new(progress, 0, 1, 0)
                
                local audioVolume = (currentSound.Volume or 0) + math.random() * 0.2
                UpdateEqualizer(audioVolume)
                
                local newActiveLyrics = {}
                local displayCount = 0
                
                for _, lyricData in ipairs(lyrics) do
                    if currentTime >= lyricData.time and currentTime <= lyricData.endTime then
                        displayCount = displayCount + 1
                        if displayCount <= CONFIG.MAX_VISIBLE_LYRICS then
                            local intensity = displayCount == 1 and 1 or 0.6
                            local isActive = displayCount == 1
                            
                            local existingLyric = nil
                            for _, existing in ipairs(activeLyrics) do
                                if existing.text == lyricData.text then
                                    existingLyric = existing
                                    break
                                end
                            end
                            
                            if not existingLyric then
                                local container, lyric, underline = CreateLyricElement(lyricData.text, lyricsDisplay, intensity, isActive)
                                table.insert(newActiveLyrics, {
                                    container = container,
                                    lyric = lyric,
                                    underline = underline,
                                    text = lyricData.text,
                                    endTime = lyricData.endTime,
                                    isActive = isActive,
                                    created = tick()
                                })
                            else
                                table.insert(newActiveLyrics, existingLyric)
                            end
                        end
                    end
                end
                
                for _, oldLyric in ipairs(activeLyrics) do
                    local stillActive = false
                    for _, newLyric in ipairs(newActiveLyrics) do
                        if oldLyric.text == newLyric.text then
                            stillActive = true
                            break
                        end
                    end
                    
                    if not stillActive and oldLyric.container.Parent then
                        local fadeOut = TweenService:Create(oldLyric.container,
                            TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                            {
                                Position = UDim2.new(-0.8, 0, oldLyric.container.Position.Y.Scale, 0),
                                Size = UDim2.new(0, 0, 0, 80)
                            }
                        )
                        
                        local transparencyTween = TweenService:Create(oldLyric.lyric,
                            TweenInfo.new(0.8, Enum.EasingStyle.Quad),
                            {TextTransparency = 1}
                        )
                        
                        fadeOut:Play()
                        transparencyTween:Play()
                        
                        local cleanup = fadeOut.Completed:Connect(function()
                            if oldLyric.container.Parent then
                                oldLyric.container:Destroy()
                            end
                        end)
                        table.insert(cleanupTasks, cleanup)
                    end
                end
                
                activeLyrics = newActiveLyrics
            end
            
            local function PlayMusic()
                if currentSound and currentSound.IsPlaying then
                    return
                end
                
                if soundId then
                    if currentSound then
                        currentSound:Destroy()
                    end
                    
                    currentSound = Instance.new("Sound")
                    currentSound.SoundId = soundId
                    currentSound.Volume = CONFIG.VOLUME
                    currentSound.Parent = workspace
                    
                    currentSound:Play()
                    isPlaying = true
                    
                    playBtn.Text = "⏸"
                    playBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
                    
                    currentSound.Ended:Connect(function()
                        isPlaying = false
                        playBtn.Text = "▶"
                        playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
                        progressBar.Size = UDim2.new(0, 0, 1, 0)
                        timeDisplay.Text = "00:00"
                        CleanupLyrics()
                        
                        if eqEnabled then
                            for _, bar in ipairs(eqBars) do
                                local resetTween = TweenService:Create(bar,
                                    TweenInfo.new(0.5, Enum.EasingStyle.Quad),
                                    {Size = UDim2.new(0, 6, 0, 5)}
                                )
                                resetTween:Play()
                            end
                        end
                    end)
                end
            end
            
            local function StopMusic()
                if currentSound then
                    currentSound:Stop()
                    currentSound:Destroy()
                    currentSound = nil
                end
                isPlaying = false
                playBtn.Text = "▶"
                playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
                progressBar.Size = UDim2.new(0, 0, 1, 0)
                timeDisplay.Text = "00:00"
                CleanupLyrics()
                
                if eqEnabled then
                    for _, bar in ipairs(eqBars) do
                        local resetTween = TweenService:Create(bar,
                            TweenInfo.new(0.5, Enum.EasingStyle.Quad),
                            {Size = UDim2.new(0, 6, 0, 5)}
                        )
                        resetTween:Play()
                    end
                end
            end
            
            local function ToggleUI()
                isHidden = not isHidden
                local mainTargetPos = isHidden and UDim2.new(0, 30, 1, 50) or UDim2.new(0, 30, 1, -240)
                local targetText = isHidden and "+" or "−"
                
                hideBtn.Text = targetText
                
                local mainTween = TweenService:Create(uiContainer,
                    TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {Position = mainTargetPos}
                )
                mainTween:Play()
                
                if eqEnabled then
                    local eqTargetPos = isHidden and UDim2.new(1, -50, 0, workspace.CurrentCamera.ViewportSize.Y + 50) or UDim2.new(1, -50, 0, 0)
                    local eqTween = TweenService:Create(eqFrame,
                        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                        {Position = eqTargetPos}
                    )
                    eqTween:Play()
                end
                
                if isHidden then
                    local restoreBtn = Instance.new("TextButton")
                    restoreBtn.Name = "RestoreButton"
                    restoreBtn.Size = UDim2.new(0, 40, 0, 30)
                    restoreBtn.Position = UDim2.new(0, 30, 1, -40)
                    restoreBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 140)
                    restoreBtn.Text = "+"
                    restoreBtn.TextColor3 = Color3.new(1, 1, 1)
                    restoreBtn.TextScaled = true
                    restoreBtn.Font = Enum.Font.JosefinSans
                    restoreBtn.BorderSizePixel = 0
                    restoreBtn.Parent = gui
                    
                    local restoreCorner = Instance.new("UICorner")
                    restoreCorner.CornerRadius = UDim.new(0, 8)
                    restoreCorner.Parent = restoreBtn
                    
                    restoreBtn.MouseButton1Click:Connect(function()
                        ToggleUI()
                        restoreBtn:Destroy()
                    end)
                end
            end
            
            local function ToggleEqualizer()
                eqEnabled = not eqEnabled
                CONFIG.EQ_ENABLED = eqEnabled
                eqFrame.Visible = eqEnabled
                
                eqToggleBtn.BackgroundColor3 = eqEnabled and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(80, 80, 80)
                
                if not eqEnabled then
                    for _, bar in ipairs(eqBars) do
                        local resetTween = TweenService:Create(bar,
                            TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                            {Size = UDim2.new(0, 6, 0, 5)}
                        )
                        resetTween:Play()
                    end
                end
            end
            
            local function ToggleParticles()
                particlesEnabled = not particlesEnabled
                CONFIG.PARTICLES_ENABLED = particlesEnabled
                particleContainer.Visible = particlesEnabled
                
                particleToggleBtn.BackgroundColor3 = particlesEnabled and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(80, 80, 80)
            end
            
            playBtn.MouseButton1Click:Connect(function()
                if currentSound and currentSound.IsPlaying then
                    currentSound:Pause()
                    isPlaying = false
                    playBtn.Text = "▶"
                    playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
                elseif currentSound and not currentSound.IsPlaying then
                    currentSound:Resume()
                    isPlaying = true
                    playBtn.Text = "⏸"
                    playBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
                else
                    PlayMusic()
                end
            end)
            
            stopBtn.MouseButton1Click:Connect(StopMusic)
            hideBtn.MouseButton1Click:Connect(ToggleUI)
            eqToggleBtn.MouseButton1Click:Connect(ToggleEqualizer)
            particleToggleBtn.MouseButton1Click:Connect(ToggleParticles)
            
            connections.particles = RunService.Heartbeat:Connect(UpdateParticles)
            connections.lyrics = RunService.Heartbeat:Connect(UpdateLyrics)
            
            local glowTween = TweenService:Create(glowEffect,
                TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {Color = Color3.fromRGB(255, 100, 200)}
            )
            glowTween:Play()
            
            local artTween = TweenService:Create(artGlow,
                TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {Color = Color3.fromRGB(100, 255, 200)}
            )
            artTween:Play()
            
            if eqEnabled then
                eqFrame.Visible = true
            else
                eqFrame.Visible = false
            end
            
            if particlesEnabled then
                particleContainer.Visible = true
            else
                particleContainer.Visible = false
            end
            
            gui.AncestryChanged:Connect(function()
                if not gui.Parent then
                    CleanupLyrics()
                    for _, connection in pairs(connections) do
                        if connection then connection:Disconnect() end
                    end
                    if currentSound then
                        currentSound:Destroy()
                    end
                end
            end)
        end)
    end)
end

CreateMusicPlayer()