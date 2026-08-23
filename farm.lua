local FarmSpeed = "27"
local MaxCollectLimit = 50000 
local ResetAccumulationInterval = 172800 

local DiscordLink = "https://discord.gg/fcKnCrbhq"
local YouTubeLink = "https://youtube.com/@AVOM-SCRIPT"

local KickMessage = "AVOM: Max Accumulate Coin (50k) Reached! Safe From Ban." 
local NaturalResetKickMessage = "AVOM: Natural Cycle Reset (2 Days Passed). Account Safe From Bot Detection!"
local CustomStatusText = "Auto Farm Coin: Safe AFK Mode" 

local StatusText_Idle = "Status: Idle"
local StatusText_Scanning = "Status: Scanning..."
local StatusText_Collecting = "Status: Collecting..."
local StatusText_Waiting = "Status: Waiting for Coins..."
local StatusText_Resetting = "Status: Bag Full! Resetting..."
local StatusText_MaxReached = "Status: Max Coin Limit Reached!"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local AutoFarmActive = false
local ParsedSpeed = tonumber(FarmSpeed) or 27
local IsAutoResetOn = true 

local currentTween = nil 
local collectedCoins = {} 
local IsBagFull = false 

local AFKSeconds = 0
local AFKMinutes = 0
local AFKHours = 0
local TotalAccumulatedCoins = 0
local ActiveFarmSeconds = 0 

local FolderName = "AVOM"
local FileName = "AVOM/Save-Coin.json"

local function LoadCoinData()
    if makefolder and not isfolder(FolderName) then
        pcall(function() makefolder(FolderName) end)
    end
    
    if readfile and isfile and isfile(FileName) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(FileName))
        end)
        if success and type(result) == "table" then
            TotalAccumulatedCoins = tonumber(result.TotalCoins) or 0
            ActiveFarmSeconds = tonumber(result.ActiveTime) or 0
        end
    end
end

local function SaveCoinData()
    if writefile then
        pcall(function()
            if not isfolder(FolderName) and makefolder then
                makefolder(FolderName)
            end
            local data = {
                TotalCoins = TotalAccumulatedCoins,
                ActiveTime = ActiveFarmSeconds
            }
            writefile(FileName, HttpService:JSONEncode(data))
        end)
    end
end

LoadCoinData()

local StatusLabel, StatusIndicator, ToggleButton, SpeedLabel, CoinCountLabel, AutoResetButton, TimerLabel

local function UpdateCoinLabel()
    if CoinCountLabel then
        CoinCountLabel.Text = "Collect Coin: " .. tostring(TotalAccumulatedCoins) .. " / " .. tostring(MaxCollectLimit)
    end
end

local function CheckMaxLimit()
    if TotalAccumulatedCoins >= MaxCollectLimit then
        AutoFarmActive = false
        if currentTween then currentTween:Cancel() end
        
        if StatusLabel and StatusIndicator and ToggleButton then
            StatusLabel.Text = StatusText_MaxReached
            StatusIndicator.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            ToggleButton.Text = "START FARMING"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 150)
        end
        
        task.wait(1)
        LocalPlayer:Kick(KickMessage)
    end
end

-- SINKRONISASI SERVER MM2 (CoinCollected & CoinsStarted)
local successRemotes, gameplayRemotes = pcall(function()
    return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay")
end)

local GetCoinRemote = nil
if successRemotes and gameplayRemotes then
    GetCoinRemote = gameplayRemotes:FindFirstChild("GetCoin")
    
    local coinCollectedEvent = gameplayRemotes:FindFirstChild("CoinCollected")
    if coinCollectedEvent then
        coinCollectedEvent.OnClientEvent:Connect(function(bagName, currentCount, maxCount)
            if currentCount >= maxCount then
                IsBagFull = true
                if StatusLabel and StatusIndicator then
                    StatusLabel.Text = StatusText_Resetting
                    StatusIndicator.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                end
                
                if currentTween then currentTween:Cancel() end
                task.wait(0.3)
                
                if IsAutoResetOn and Character and Character:FindFirstChild("Humanoid") then
                    Character.Humanoid.Health = 0
                end
            end
        end)
    end

    local coinsStartedRemote = gameplayRemotes:FindFirstChild("CoinsStarted")
    if coinsStartedRemote then
        coinsStartedRemote.OnClientEvent:Connect(function()
            IsBagFull = false
            collectedCoins = {}
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    collectedCoins = {}
    IsBagFull = false 
    UpdateCoinLabel()
    task.wait(1)
end)

local function AntiAFKAndTimer()
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            AFKSeconds = AFKSeconds + 1
            if AFKSeconds >= 60 then
                AFKSeconds = 0
                AFKMinutes = AFKMinutes + 1
                if AFKMinutes >= 60 then
                    AFKMinutes = 0
                    AFKHours = AFKHours + 1
                end
            end
            
            if TimerLabel then
                TimerLabel.Text = string.format("Time: %02dh %02dm %02ds", AFKHours, AFKMinutes, AFKSeconds)
            end
            
            if AutoFarmActive then
                ActiveFarmSeconds = ActiveFarmSeconds + 1
                if ActiveFarmSeconds >= ResetAccumulationInterval then
                    AutoFarmActive = false
                    if currentTween then currentTween:Cancel() end
                    TotalAccumulatedCoins = 0
                    ActiveFarmSeconds = 0
                    SaveCoinData()
                    task.wait(1)
                    LocalPlayer:Kick(NaturalResetKickMessage)
                    break
                end
            end
        end
    end)
end
task.spawn(AntiAFKAndTimer)

RunService.Stepped:Connect(function()
    if AutoFarmActive and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

local function GetNearestCoin()
    local nearestCoinPart = nil
    local shortestDistance = 500

    for _, mapFolder in ipairs(Workspace:GetChildren()) do
        if mapFolder:IsA("Folder") or mapFolder:IsA("Model") then
            local coinContainer = mapFolder:FindFirstChild("CoinContainer")
            if coinContainer then
                for _, coinObj in ipairs(coinContainer:GetChildren()) do
                    if coinObj.Name == "Coin_Server" and not collectedCoins[coinObj] then
                        local targetPart = coinObj:IsA("Model") and (coinObj.PrimaryPart or coinObj:FindFirstChildWhichIsA("BasePart")) or coinObj
                        if targetPart and targetPart:IsA("BasePart") then
                            if targetPart.Parent and targetPart.Position.Magnitude > 0 then
                                local distance = (HumanoidRootPart.Position - targetPart.Position).Magnitude
                                if distance < shortestDistance then
                                    shortestDistance = distance
                                    nearestCoinPart = targetPart
                                end
                            else
                                collectedCoins[coinObj] = true
                            end
                        end
                    end
                end
            end
        end
    end

    if not nearestCoinPart then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Coin_Server" and not collectedCoins[obj] then
                local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                if targetPart and targetPart:IsA("BasePart") then
                    if targetPart.Parent then
                        local distance = (HumanoidRootPart.Position - targetPart.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            nearestCoinPart = targetPart
                        end
                    else
                        collectedCoins[obj] = true
                    end
                end
            end
        end
    end

    return nearestCoinPart
end

task.spawn(function()
    while true do
        task.wait(0.1) 
        if AutoFarmActive and not IsBagFull then
            pcall(function()
                if not Character or not Character:FindFirstChild("HumanoidRootPart") then
                    local newChar = LocalPlayer.Character
                    if newChar then
                        Character = newChar
                        HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
                    end
                    return
                end

                local coin = GetNearestCoin()
                if coin and coin.Parent and AutoFarmActive then
                    collectedCoins[coin.Parent] = true
                    collectedCoins[coin] = true

                    if StatusLabel and StatusIndicator then
                        StatusLabel.Text = StatusText_Collecting
                        StatusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
                    end

                    if Character and Character:FindFirstChild("HumanoidRootPart") then
                        HumanoidRootPart = Character.HumanoidRootPart
                        local targetPos = coin.Position - Vector3.new(0, 3.5, 0)
                        local distance = (HumanoidRootPart.Position - targetPos).Magnitude
                        
                        local travelTime = distance / ParsedSpeed
                        if travelTime < 0.05 then travelTime = 0.05 end

                        currentTween = TweenService:Create(HumanoidRootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {Position = targetPos})
                        currentTween:Play()
                        
                        while currentTween.PlaybackState == Enum.PlaybackState.Playing do
                            if not AutoFarmActive or not coin.Parent or IsBagFull then 
                                currentTween:Cancel() 
                                break 
                            end
                            task.wait()
                        end
                        
                        if coin and coin.Parent and AutoFarmActive and not IsBagFull then
                            local collectTween = TweenService:Create(HumanoidRootPart, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {Position = coin.Position})
                            collectTween:Play()
                            collectTween.Completed:Wait()
                            
                            if GetCoinRemote then
                                pcall(function()
                                    GetCoinRemote:FireServer(coin.Parent)
                                end)
                            end
                            
                            TotalAccumulatedCoins = TotalAccumulatedCoins + 1
                            UpdateCoinLabel()
                            SaveCoinData()
                            CheckMaxLimit()
                            
                            local backTween = TweenService:Create(HumanoidRootPart, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {Position = targetPos})
                            backTween:Play()
                            backTween.Completed:Wait()
                        end
                    end
                else
                    if AutoFarmActive and StatusLabel then
                        StatusLabel.Text = StatusText_Waiting
                        StatusIndicator.BackgroundColor3 = Color3.fromRGB(0, 200, 255) 
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
end)

-- UI Setup (Judul dan Status dikembalikan ke versi original)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AVOM_Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local success, err = pcall(function()
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end)
if not success then
    ScreenGui.Parent = game:GetService("CoreGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 22, 30)
MainFrame.Position = UDim2.new(0.5, -110, 0.4, -127)
MainFrame.Size = UDim2.new(0, 220, 0, 254)
MainFrame.Draggable = true
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 38, 50)
TopBar.Size = UDim2.new(1, 0, 0, 28)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local FixCorner = Instance.new("Frame", TopBar)
FixCorner.BackgroundColor3 = Color3.fromRGB(25, 38, 50)
FixCorner.BorderSizePixel = 0
FixCorner.Position = UDim2.new(0, 0, 1, -5)
FixCorner.Size = UDim2.new(1, 0, 0, 5)

local Title = Instance.new("TextLabel", TopBar)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "⚡ AVOM | Auto Farm"
Title.TextColor3 = Color3.fromRGB(0, 240, 200)
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton", TopBar)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseButton.Position = UDim2.new(1, -22, 0, 4)
CloseButton.Size = UDim2.new(0, 18, 0, 18)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 13
local CloseCorner = Instance.new("UICorner", CloseButton)
CloseCorner.CornerRadius = UDim.new(1, 0)

CloseButton.MouseButton1Click:Connect(function()
    AutoFarmActive = false
    ScreenGui:Destroy()
end)

local ContentBox = Instance.new("Frame", MainFrame)
ContentBox.BackgroundColor3 = Color3.fromRGB(10, 16, 22)
ContentBox.Position = UDim2.new(0, 10, 0, 36)
ContentBox.Size = UDim2.new(1, -20, 1, -44)
Instance.new("UICorner", ContentBox).CornerRadius = UDim.new(0, 6)

StatusIndicator = Instance.new("Frame", ContentBox)
StatusIndicator.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
StatusIndicator.Position = UDim2.new(0, 10, 0, 8)
StatusIndicator.Size = UDim2.new(0, 8, 0, 8)
Instance.new("UICorner", StatusIndicator).CornerRadius = UDim.new(1, 0)

StatusLabel = Instance.new("TextLabel", ContentBox)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 24, 0, 2)
StatusLabel.Size = UDim2.new(1, -30, 0, 18)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.Text = StatusText_Idle
StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

SpeedLabel = Instance.new("TextLabel", ContentBox)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Position = UDim2.new(0, 10, 0, 21)
SpeedLabel.Size = UDim2.new(1, -20, 0, 18)
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.Text = "Speed: " .. tostring(ParsedSpeed)
SpeedLabel.TextColor3 = Color3.fromRGB(0, 255, 170)
SpeedLabel.TextSize = 11
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

CoinCountLabel = Instance.new("TextLabel", ContentBox)
CoinCountLabel.BackgroundTransparency = 1
CoinCountLabel.Position = UDim2.new(0, 10, 0, 39)
CoinCountLabel.Size = UDim2.new(1, -20, 0, 18)
CoinCountLabel.Font = Enum.Font.GothamBold
CoinCountLabel.Text = "Collect Coin: " .. tostring(TotalAccumulatedCoins) .. " / " .. tostring(MaxCollectLimit)
CoinCountLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
CoinCountLabel.TextSize = 11
CoinCountLabel.TextXAlignment = Enum.TextXAlignment.Left

TimerLabel = Instance.new("TextLabel", ContentBox)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Position = UDim2.new(0, 10, 0, 57)
TimerLabel.Size = UDim2.new(1, -20, 0, 18)
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.Text = "Time: 00h 00m 00s"
TimerLabel.TextColor3 = Color3.fromRGB(120, 220, 255)
TimerLabel.TextSize = 11
TimerLabel.TextXAlignment = Enum.TextXAlignment.Left

AutoResetButton = Instance.new("TextButton", ContentBox)
AutoResetButton.BackgroundColor3 = Color3.fromRGB(0, 160, 110)
AutoResetButton.Position = UDim2.new(0, 10, 0, 79)
AutoResetButton.Size = UDim2.new(1, -20, 0, 24)
AutoResetButton.Font = Enum.Font.GothamBold
AutoResetButton.Text = "Auto Reset: ON"
AutoResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoResetButton.TextSize = 11
Instance.new("UICorner", AutoResetButton).CornerRadius = UDim.new(0, 5)

AutoResetButton.MouseButton1Click:Connect(function()
    IsAutoResetOn = not IsAutoResetOn
    AutoResetButton.Text = IsAutoResetOn and "Auto Reset: ON" or "Auto Reset: OFF"
    AutoResetButton.BackgroundColor3 = IsAutoResetOn and Color3.fromRGB(0, 160, 110) or Color3.fromRGB(160, 60, 60)
end)

ToggleButton = Instance.new("TextButton", ContentBox)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 185, 130)
ToggleButton.Position = UDim2.new(0, 10, 0, 107)
ToggleButton.Size = UDim2.new(1, -20, 0, 26)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "START FARMING"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 11
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 5)

ToggleButton.MouseButton1Click:Connect(function()
    AutoFarmActive = not AutoFarmActive
    if AutoFarmActive then
        ToggleButton.Text = "STOP FARMING"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
        StatusLabel.Text = StatusText_Scanning
        StatusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
    else
        ToggleButton.Text = "START FARMING"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 185, 130)
        StatusLabel.Text = StatusText_Idle
        StatusIndicator.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        if currentTween then currentTween:Cancel() end
    end
end)

local DiscordButton = Instance.new("TextButton", ContentBox)
DiscordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
DiscordButton.Position = UDim2.new(0, 10, 0, 139)
DiscordButton.Size = UDim2.new(0.48, -5, 0, 22)
DiscordButton.Font = Enum.Font.GothamBold
DiscordButton.Text = "💬 Discord"
DiscordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DiscordButton.TextSize = 10
Instance.new("UICorner", DiscordButton).CornerRadius = UDim.new(0, 4)

DiscordButton.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(DiscordLink) end)
    DiscordButton.Text = "Copied Link!"
    task.wait(1.5)
    DiscordButton.Text = "💬 Discord"
end)

local YoutubeButton = Instance.new("TextButton", ContentBox)
YoutubeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
YoutubeButton.Position = UDim2.new(0.5, 5, 0, 139)
YoutubeButton.Size = UDim2.new(0.48, -5, 0, 22)
YoutubeButton.Font = Enum.Font.GothamBold
YoutubeButton.Text = "📺 YouTube"
YoutubeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
YoutubeButton.TextSize = 10
Instance.new("UICorner", YoutubeButton).CornerRadius = UDim.new(0, 4)

YoutubeButton.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(YouTubeLink) end)
    YoutubeButton.Text = "Copied Link!"
    task.wait(1.5)
    YoutubeButton.Text = "📺 YouTube"
end)

local CustomStatusLabel = Instance.new("TextLabel", ContentBox)
CustomStatusLabel.BackgroundTransparency = 1
CustomStatusLabel.Position = UDim2.new(0, 10, 0, 167)
CustomStatusLabel.Size = UDim2.new(1, -20, 0, 14)
CustomStatusLabel.Font = Enum.Font.GothamBold
CustomStatusLabel.Text = CustomStatusText
CustomStatusLabel.TextColor3 = Color3.fromRGB(150, 170, 190)
CustomStatusLabel.TextSize = 9
CustomStatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local Watermark = Instance.new("TextLabel", ScreenGui)
Watermark.Name = "Watermark"
Watermark.Size = UDim2.new(0, 200, 0, 40)
Watermark.Position = UDim2.new(0.5, -100, 1, -50)
Watermark.BackgroundTransparency = 1
Watermark.Text = "AVOM"
Watermark.TextColor3 = Color3.fromRGB(0, 240, 200)
Watermark.TextTransparency = 0.5
Watermark.Font = Enum.Font.GothamBold
Watermark.TextSize = 20
Watermark.Active = false
