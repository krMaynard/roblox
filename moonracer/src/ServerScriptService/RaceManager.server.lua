local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.RaceConfig)

workspace.Gravity = Config.GRAVITY

-- RemoteEvents
local events = Instance.new("Folder")
events.Name  = "RaceEvents"
events.Parent = ReplicatedStorage

local UpdateHUD     = Instance.new("RemoteEvent", events)  UpdateHUD.Name     = "UpdateHUD"
local RaceFinished  = Instance.new("RemoteEvent", events)  RaceFinished.Name  = "RaceFinished"

-- State
local raceState  = "waiting"   -- waiting | countdown | racing
local playerData = {}          -- [player] = { laps, nextCheckpoint, startTime, finished }
local checkpoints = {}         -- [index] = BasePart, sourced from workspace.Checkpoints

local function loadCheckpoints()
    local folder = workspace:FindFirstChild("Checkpoints")
    if not folder then
        warn("RaceManager: no Checkpoints folder found in Workspace")
        return
    end
    for _, part in ipairs(folder:GetChildren()) do
        local i = tonumber(part.Name)
        if i then checkpoints[i] = part end
    end
end

local function hudPayload(data)
    return {
        laps             = data.laps,
        totalLaps        = Config.LAPS,
        nextCheckpoint   = data.nextCheckpoint,
        totalCheckpoints = #checkpoints,
    }
end

local function onCheckpointTouched(index, other)
    local character = other.Parent
    local player    = Players:GetPlayerFromCharacter(character)
    if not player then return end

    local data = playerData[player]
    if not data or data.finished or raceState ~= "racing" then return end
    if index ~= data.nextCheckpoint then return end

    data.nextCheckpoint += 1

    if data.nextCheckpoint > #checkpoints then
        data.nextCheckpoint = 1
        data.laps          += 1

        if data.laps >= Config.LAPS then
            data.finished = true
            RaceFinished:FireClient(player, { time = tick() - data.startTime })
            return
        end
    end

    UpdateHUD:FireClient(player, hudPayload(data))
end

local function startRace()
    raceState = "racing"
    local now = tick()
    for player, data in pairs(playerData) do
        data.startTime      = now
        data.laps           = 0
        data.nextCheckpoint = 1
        data.finished       = false
        UpdateHUD:FireClient(player, hudPayload(data))
    end
end

local function runCountdown()
    raceState = "countdown"
    for i = Config.COUNTDOWN_TIME, 1, -1 do
        for player in pairs(playerData) do
            UpdateHUD:FireClient(player, { countdown = i })
        end
        task.wait(1)
    end
    startRace()
end

Players.PlayerAdded:Connect(function(player)
    playerData[player] = { laps = 0, nextCheckpoint = 1, finished = false }
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if raceState == "racing" then
            UpdateHUD:FireClient(player, hudPayload(playerData[player]))
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player] = nil
end)

-- Wait for WorldSetup to finish before wiring checkpoints and starting
task.spawn(function()
    workspace:WaitForChild("WorldReady")
    loadCheckpoints()
    for i, part in pairs(checkpoints) do
        part.Touched:Connect(function(other) onCheckpointTouched(i, other) end)
    end
    if raceState == "waiting" then runCountdown() end
end)
