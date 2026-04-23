local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

local events       = ReplicatedStorage:WaitForChild("RaceEvents")
local UpdateHUD    = events:WaitForChild("UpdateHUD")
local RaceFinished = events:WaitForChild("RaceFinished")

-- Build HUD
local screen = Instance.new("ScreenGui")
screen.Name          = "RaceHUD"
screen.ResetOnSpawn  = false
screen.Parent        = playerGui

local panel = Instance.new("Frame", screen)
panel.Size                  = UDim2.new(0, 220, 0, 110)
panel.Position              = UDim2.new(1, -230, 0, 12)
panel.BackgroundColor3      = Color3.fromRGB(10, 10, 30)
panel.BackgroundTransparency = 0.35
panel.BorderSizePixel       = 0

local corner = Instance.new("UICorner", panel)
corner.CornerRadius = UDim.new(0, 10)

local function label(text, y, size)
    local l = Instance.new("TextLabel", panel)
    l.Size               = UDim2.new(1, -12, 0, size or 28)
    l.Position           = UDim2.new(0, 6, 0, y)
    l.BackgroundTransparency = 1
    l.TextColor3         = Color3.fromRGB(220, 240, 255)
    l.TextScaled         = true
    l.Font               = Enum.Font.GothamBold
    l.Text               = text
    return l
end

local lapLabel        = label("🌕  LAP 1 / 3",   6,  34)
local checkpointLabel = label("Checkpoint 1 / ?", 44, 22)
local statusLabel     = label("Waiting for race...", 70, 20)
local timerLabel      = label("",                   90, 18)

-- Live timer
local raceStartTick = nil
game:GetService("RunService").Heartbeat:Connect(function()
    if raceStartTick then
        timerLabel.Text = string.format("⏱  %.1fs", tick() - raceStartTick)
    end
end)

UpdateHUD.OnClientEvent:Connect(function(data)
    if data.countdown then
        lapLabel.Text        = "🌙  GET READY"
        checkpointLabel.Text = ""
        statusLabel.Text     = tostring(data.countdown) .. "..."
        timerLabel.Text      = ""
        raceStartTick        = nil
        return
    end

    if data.laps ~= nil then
        raceStartTick        = raceStartTick or tick()
        lapLabel.Text        = string.format("🌕  LAP %d / %d", data.laps + 1, data.totalLaps)
        checkpointLabel.Text = string.format("Checkpoint %d / %d", data.nextCheckpoint, data.totalCheckpoints)
        statusLabel.Text     = "🏁  RACING"
    end
end)

RaceFinished.OnClientEvent:Connect(function(data)
    raceStartTick        = nil
    lapLabel.Text        = "🏆  FINISHED!"
    checkpointLabel.Text = ""
    statusLabel.Text     = string.format("Time: %.2f s", data.time)
    timerLabel.Text      = ""
end)
