local Lighting = game:GetService("Lighting")

local TRACK_RADIUS    = 190
local TRACK_WIDTH     = 65
local SEGMENTS        = 48
local WALL_HEIGHT     = 6
local WALL_THICK      = 2
local NUM_CHECKPOINTS = 8
local TRACK_SURFACE_Y = 1

-- ─── Lighting ─────────────────────────────────────────────────────────────────
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("Sky") or v:IsA("Atmosphere") then v:Destroy() end
end
Lighting.Ambient        = Color3.fromRGB(85, 85, 105)
Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
Lighting.Brightness     = 2
Lighting.ClockTime      = 0
Lighting.GlobalShadows  = true
Lighting.FogEnd         = 6000

local sky           = Instance.new("Sky", Lighting)
sky.StarCount       = 10000
sky.MoonAngularSize = 0

-- ─── Remove baseplate ─────────────────────────────────────────────────────────
local bp = workspace:FindFirstChild("Baseplate")
if bp then bp:Destroy() end

-- ─── Moon terrain (outside track only) ───────────────────────────────────────
workspace.Terrain:FillBlock(
    CFrame.new(0, -25, 0),
    Vector3.new(1600, 50, 1600),
    Enum.Material.Rock
)
-- Clear a wide cylinder so no terrain can interfere with the track or cars
workspace.Terrain:FillCylinder(CFrame.new(0, 10, 0), 22, 260, Enum.Material.Air)

-- Rocky hills scattered around the explorable area outside the track
math.randomseed(7)
local function makeHill(x, z, radius, height)
    -- Three stacked cylinders: wide base → narrow peak
    workspace.Terrain:FillCylinder(CFrame.new(x, height * 0.25, z), height * 0.5,  radius,       Enum.Material.Rock)
    workspace.Terrain:FillCylinder(CFrame.new(x, height * 0.62, z), height * 0.45, radius * 0.55, Enum.Material.Rock)
    workspace.Terrain:FillCylinder(CFrame.new(x, height * 0.88, z), height * 0.25, radius * 0.25, Enum.Material.Rock)
end

for i = 1, 35 do
    local angle  = math.random() * math.pi * 2
    local dist   = math.random(290, 750)
    local radius = math.random(30, 110)
    local height = math.random(25, 90)
    makeHill(dist * math.cos(angle), dist * math.sin(angle), radius, height)
    if i % 8 == 0 then task.wait() end
end

-- Safety floor
local safetyFloor      = Instance.new("Part")
safetyFloor.Size       = Vector3.new(2000, 2, 2000)
safetyFloor.CFrame     = CFrame.new(0, -62, 0)
safetyFloor.Anchored   = true
safetyFloor.CanCollide = true
safetyFloor.Material   = Enum.Material.SmoothPlastic
safetyFloor.Color      = Color3.fromRGB(60, 55, 50)
safetyFloor.Parent     = workspace

-- ─── Earth sphere ─────────────────────────────────────────────────────────────
local earthPos = CFrame.new(400, 4500, -3800)

local earthCore        = Instance.new("Part")
earthCore.Shape        = Enum.PartType.Ball
earthCore.Size         = Vector3.new(1600, 1600, 1600)
earthCore.CFrame       = earthPos
earthCore.Anchored     = true
earthCore.CanCollide   = false
earthCore.CastShadow   = false
earthCore.Material     = Enum.Material.SmoothPlastic
earthCore.Color        = Color3.fromRGB(28, 88, 195)
earthCore.Parent       = workspace

for _, p in ipairs({
    { Vector3.new( 200,  300,  150), 580, Color3.fromRGB(60,  130, 60)  },
    { Vector3.new(-350, -100,  200), 420, Color3.fromRGB(55,  120, 55)  },
    { Vector3.new( 100, -300, -200), 340, Color3.fromRGB(160, 130, 80)  },
}) do
    local land       = Instance.new("Part")
    land.Shape       = Enum.PartType.Ball
    land.Size        = Vector3.new(p[2], p[2], p[2])
    land.CFrame      = CFrame.new(earthPos.Position + p[1])
    land.Anchored    = true
    land.CanCollide  = false
    land.CastShadow  = false
    land.Material    = Enum.Material.SmoothPlastic
    land.Color       = p[3]
    land.Parent      = workspace
end

local clouds         = Instance.new("Part")
clouds.Shape         = Enum.PartType.Ball
clouds.Size          = Vector3.new(1680, 1680, 1680)
clouds.CFrame        = earthPos
clouds.Anchored      = true
clouds.CanCollide    = false
clouds.CastShadow    = false
clouds.Material      = Enum.Material.SmoothPlastic
clouds.Color         = Color3.fromRGB(242, 242, 248)
clouds.Transparency  = 0.62
clouds.Parent        = workspace

-- ─── Track helper ─────────────────────────────────────────────────────────────
local function makePart(parent, size, cf, color, material, transparency)
    local p        = Instance.new("Part")
    p.Size         = size
    p.CFrame       = cf
    p.Color        = color
    p.Material     = material or Enum.Material.SmoothPlastic
    p.Anchored     = true
    p.CanCollide   = (transparency or 0) < 0.9
    p.Transparency = transparency or 0
    p.Parent       = parent
    return p
end

-- ─── Track ────────────────────────────────────────────────────────────────────
local trackFolder = Instance.new("Folder", workspace)
trackFolder.Name  = "Track"
local segAngle    = (2 * math.pi) / SEGMENTS
local segLen      = 2 * math.pi * TRACK_RADIUS / SEGMENTS * 1.05

for i = 0, SEGMENTS - 1 do
    local a    = i * segAngle
    local cosA = math.cos(a)
    local sinA = math.sin(a)
    local rot  = CFrame.Angles(0, -(a + math.pi / 2), 0)

    makePart(trackFolder, Vector3.new(TRACK_WIDTH, 1, segLen),
        CFrame.new(TRACK_RADIUS * cosA, 0.5, TRACK_RADIUS * sinA) * rot,
        Color3.fromRGB(160, 155, 148))

    local ir = TRACK_RADIUS - TRACK_WIDTH / 2 - WALL_THICK / 2
    makePart(trackFolder, Vector3.new(WALL_THICK, WALL_HEIGHT, segLen),
        CFrame.new(ir * cosA, WALL_HEIGHT / 2, ir * sinA) * rot,
        Color3.fromRGB(200, 195, 188))

    local or_ = TRACK_RADIUS + TRACK_WIDTH / 2 + WALL_THICK / 2
    makePart(trackFolder, Vector3.new(WALL_THICK, WALL_HEIGHT, segLen),
        CFrame.new(or_ * cosA, WALL_HEIGHT / 2, or_ * sinA) * rot,
        Color3.fromRGB(200, 195, 188))
end

-- ─── Checkpoints ──────────────────────────────────────────────────────────────
local cpFolder = Instance.new("Folder", workspace)
cpFolder.Name  = "Checkpoints"

for i = 1, NUM_CHECKPOINTS do
    local a     = ((i - 1) / NUM_CHECKPOINTS) * 2 * math.pi
    local color = i == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(0, 162, 255)
    local gate  = makePart(cpFolder, Vector3.new(TRACK_WIDTH, WALL_HEIGHT, 3),
        CFrame.new(TRACK_RADIUS * math.cos(a), WALL_HEIGHT / 2, TRACK_RADIUS * math.sin(a))
        * CFrame.Angles(0, -(a + math.pi / 2), 0),
        color, Enum.Material.Neon, 0.5)
    gate.Name       = tostring(i)
    gate.CanCollide = false
end

-- ─── Moon Buggy ───────────────────────────────────────────────────────────────
-- Wheel radius = 1.5  →  wheel center Y = TRACK_SURFACE_Y + 1.5 = 2.5
-- Chassis offset from wheel center = +0.5 Y  →  chassis center Y = 3.0
local WHEEL_RADIUS   = 1.5
local CHASSIS_Y      = TRACK_SURFACE_Y + WHEEL_RADIUS + 0.2   -- small gap so physics settles

local function createBuggy(xPos, zPos, bodyColor)
    local model       = Instance.new("Model", workspace)
    model.Name        = "MoonBuggy"

    -- Chassis
    local chassis     = Instance.new("Part")
    chassis.Name      = "Chassis"
    chassis.Size      = Vector3.new(6, 1.5, 12)
    chassis.CFrame    = CFrame.new(xPos, CHASSIS_Y, zPos)
    chassis.Color     = bodyColor
    chassis.Material  = Enum.Material.SmoothPlastic
    chassis.CustomPhysicalProperties = PhysicalProperties.new(
        0.9,   -- density — heavy enough to stay grounded
        0.3,   -- friction
        0.0,   -- elasticity
        0, 0
    )
    chassis.Parent    = model

    -- VehicleSeat
    local seat        = Instance.new("VehicleSeat")
    seat.Size         = Vector3.new(3, 0.5, 3)
    seat.CFrame       = chassis.CFrame * CFrame.new(0, 1.0, 0.5)
    seat.MaxSpeed     = 80
    seat.Torque       = 20
    seat.TurnSpeed    = 1.5
    seat.Color        = bodyColor
    seat.Material     = Enum.Material.SmoothPlastic
    seat.Parent       = model
    local sw          = Instance.new("WeldConstraint", chassis)
    sw.Part0, sw.Part1 = chassis, seat

    -- Roll bar (purely visual)
    local bar         = Instance.new("Part")
    bar.Size          = Vector3.new(5.5, 0.4, 0.4)
    bar.CFrame        = chassis.CFrame * CFrame.new(0, 2.2, -1)
    bar.Color         = Color3.fromRGB(200, 200, 200)
    bar.Material      = Enum.Material.Metal
    bar.Parent        = model
    local bw          = Instance.new("WeldConstraint", chassis)
    bw.Part0, bw.Part1 = chassis, bar

    -- Wheels: welded so chassis is one rigid body (drive handled by BuggyDrive script)
    local wheelOffsets = {
        Vector3.new(-3.5, -0.8,  4.5),
        Vector3.new( 3.5, -0.8,  4.5),
        Vector3.new(-3.5, -0.8, -4.5),
        Vector3.new( 3.5, -0.8, -4.5),
    }

    for _, offset in ipairs(wheelOffsets) do
        local wheel       = Instance.new("Part")
        wheel.Shape       = Enum.PartType.Cylinder
        wheel.Size        = Vector3.new(1.4, WHEEL_RADIUS * 2, WHEEL_RADIUS * 2)
        wheel.CFrame      = chassis.CFrame * CFrame.new(offset)
        wheel.Color       = Color3.fromRGB(25, 25, 25)
        wheel.Material    = Enum.Material.SmoothPlastic
        wheel.CanCollide  = false
        wheel.Parent      = model
        local ww          = Instance.new("WeldConstraint", chassis)
        ww.Part0, ww.Part1 = chassis, wheel
    end

    model.PrimaryPart = chassis
    return model
end

createBuggy(TRACK_RADIUS, -8,  Color3.fromRGB(210, 60, 40))   -- red
createBuggy(TRACK_RADIUS,  8,  Color3.fromRGB(40, 100, 210))  -- blue

-- Player spawn points beside each buggy
for _, z in ipairs({ -8, 8 }) do
    local spawn      = Instance.new("SpawnLocation", workspace)
    spawn.Size       = Vector3.new(4, 1, 4)
    spawn.CFrame     = CFrame.new(TRACK_RADIUS + 9, TRACK_SURFACE_Y + 0.5, z)
    spawn.Anchored   = true
    spawn.Neutral    = true
end

-- ─── Signal ready ─────────────────────────────────────────────────────────────
local ready       = Instance.new("BoolValue", workspace)
ready.Name        = "WorldReady"
ready.Value       = true
