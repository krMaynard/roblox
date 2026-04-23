local RunService = game:GetService("RunService")

workspace:WaitForChild("WorldReady")

local buggies = {}

local function setupBuggy(model)
    local seat    = model:FindFirstChildOfClass("VehicleSeat")
    local chassis = model:FindFirstChild("Chassis")
    if not seat or not chassis then return end

    local bv          = Instance.new("BodyVelocity", chassis)
    bv.MaxForce       = Vector3.new(0, 0, 0)   -- disabled until occupied
    bv.P              = 3e4
    bv.Velocity       = Vector3.new(0, 0, 0)

    local bav         = Instance.new("BodyAngularVelocity", chassis)
    bav.MaxTorque     = Vector3.new(0, 0, 0)
    bav.P             = 3e4
    bav.AngularVelocity = Vector3.new(0, 0, 0)

    table.insert(buggies, { seat = seat, chassis = chassis, bv = bv, bav = bav })
end

for _, v in ipairs(workspace:GetChildren()) do
    if v.Name == "MoonBuggy" then setupBuggy(v) end
end
workspace.ChildAdded:Connect(function(v)
    if v.Name == "MoonBuggy" then setupBuggy(v) end
end)

RunService.Heartbeat:Connect(function()
    for _, b in ipairs(buggies) do
        if b.seat.Occupant then
            local look     = b.chassis.CFrame.LookVector
            b.bv.MaxForce  = Vector3.new(4e4, 0, 4e4)
            b.bv.Velocity  = look * b.seat.Throttle * b.seat.MaxSpeed
            b.bav.MaxTorque     = Vector3.new(0, 4e4, 0)
            b.bav.AngularVelocity = Vector3.new(0, -b.seat.Steer * 1.8, 0)
        else
            b.bv.MaxForce       = Vector3.new(0, 0, 0)
            b.bav.MaxTorque     = Vector3.new(0, 0, 0)
        end
    end
end)
