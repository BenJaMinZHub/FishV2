local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer

local function moveFishingUI()
    local fishingUI = plr.PlayerGui:FindFirstChild("HUD") and plr.PlayerGui.HUD:FindFirstChild("Fishing")
    if fishingUI then
        fishingUI.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
end

RunService.RenderStepped:Connect(function()
    moveFishingUI()
end)


-----------------------------
-- CONFIG
-----------------------------
getgenv().FishingEnabled = true -- สถานะสคริปต์ตกปลา
getgenv().AutoOpenChestEnabled = true -- เปิดกล่องอัตโนมัติ

local player = game:GetService("Players").LocalPlayer
local ChestPath = player.Inventory
local ChestNames = {
    "Common Chest",
    "Halloween Chest",
    "Legendary Chest",
    "Mythical Chest",
    "Rare Chest"
}

local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local FishButton = nil
local isFishing = false

-----------------------------
-- FUNCTION: หยุดสคริปต์ตกปลา
-----------------------------
local function StopFishing()
    getgenv().FishingEnabled = false
end

-----------------------------
-- FUNCTION: เริ่มสคริปต์ตกปลา
-----------------------------
local function StartFishing()
    getgenv().FishingEnabled = true
end

-----------------------------
-- FUNCTION: กดปุ่ม Enter
-----------------------------
local function PressEnter()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
end

-----------------------------
-- FUNCTION: กดปุ่ม Down
-----------------------------
local function PressDown()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Down, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Down, false, game)
end

-----------------------------
-- FUNCTION: ตรวจสอบว่ามีกล่อง ≥500
-----------------------------
local function Has500()
    for _, chestName in ipairs(ChestNames) do
        local chest = ChestPath:FindFirstChild(chestName)
        if chest and chest.Value >= 500 then
            return chestName
        end
    end
    return nil
end

-----------------------------
-- FUNCTION: เปิดกล่อง
-----------------------------
local function OpenChest(chestName)
    local btn = player.PlayerGui.Button.Storage_Frame.Material_Frame:FindFirstChild(chestName)
    if not btn then return end

    GuiService.SelectedObject = btn
    PressEnter()
    task.wait(0.2)

    local confirm = player.PlayerGui.Button:FindFirstChild("Confirm")
    if confirm then
        local event = confirm:FindFirstChild("Event")
        if event and ChestPath:FindFirstChild(chestName) then
            event:FireServer(ChestPath[chestName].Value)
        end
        local accept = confirm:FindFirstChild("Accept")
        if accept then
            local acceptBtn = accept:FindFirstChild("Button")
            if acceptBtn then
                GuiService.SelectedObject = acceptBtn
                PressEnter()
            end
        end
    end
end

-----------------------------
-- FISHING SCRIPT (AUTO)
-----------------------------
player.PlayerGui.HUD.DescendantAdded:Connect(function(v)
    if not getgenv().FishingEnabled then return end
    if v.Name == "Button" and v.Parent.Name == "Fishing" then
        FishButton = v
        if isFishing then return end
        isFishing = true

        GuiService.SelectedObject = FishButton
        for i = 1, 20 do
            if not getgenv().FishingEnabled then break end
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end

        isFishing = false
    end
end)

-----------------------------
-- AUTO OPEN CHEST SYSTEM
-- ลำดับ: ตกปลา → เปิดกล่อง → ปิด UI → รอ 1 วิ → กด Down 1 ครั้ง → รอ 3 วิ → กด Enter → กลับไปตกปลา
-----------------------------
task.spawn(function()
    while getgenv().AutoOpenChestEnabled do
        task.wait(1)
        local chestReady = Has500()
        if chestReady then
            -- 1. หยุดสคริปต์ตกปลา
            StopFishing()
            task.wait(0.3)

            -- 2. เปิด Storage UI
            local storage = player.PlayerGui.Button:FindFirstChild("Storage_Frame")
            if storage then storage.Visible = true end
            task.wait(0.3)

            -- 3. เปิดจนลดลงต่ำกว่า 500
            while ChestPath[chestReady].Value >= 500 do
                OpenChest(chestReady)
                task.wait(0.5)
            end

            -- 4. ปิด Storage UI
            if storage then storage.Visible = false end

            -- 5. รอ 1 วิ
            task.wait(0.5)

            -- 6. กดปุ่ม Down 1 ครั้ง
            PressDown()

            -- 7. รอ 3 วิ
            task.wait(0.5)

            -- 8. กด Enter 1 ครั้ง
            PressEnter()

            -- 9. กลับไปตกปลา
            StartFishing()
        end
    end
end)

