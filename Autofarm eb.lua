-- Flood's Hub - Combined ATM Farm & Auto Punch Script
-- If _G.MENUENABLED then return end

local Players    = game:GetService("Players")
local RepStore   = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-------------------------------------------------------------------
-- ATM FARM VARIABLES & FUNCTIONS
-------------------------------------------------------------------
local currentStatus
local lastGuessList = {}

-- Utility: Check if a laptop is already equipped on the character
local function isLaptopEquipped()
    local plr = Players.LocalPlayer
    if not plr.Character then return false end
    for _, tool in ipairs(plr.Character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:find("Illegal Laptop") then
            return true
        end
    end
    return false
end

-- Utility: Rename all laptops in the Backpack in numerical order
local function renameLaptopsInBackpack()
    local plr = Players.LocalPlayer
    local list = {}
    for _, item in ipairs(plr.Backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name:find("Illegal Laptop") then
            list[#list+1] = item
        end
    end
    table.sort(list, function(a,b) return a:GetDebugId() < b:GetDebugId() end)
    for i, l in ipairs(list) do
        l.Name = "Illegal Laptop "..i
    end
end

-- Equip & activate the next laptop in numeric order
function equipnactivate()
    local plr = Players.LocalPlayer
    while isLaptopEquipped() do wait(1) end

    renameLaptopsInBackpack()
    _G.currentLaptopNumber = _G.currentLaptopNumber or 1

    local name   = "Illegal Laptop ".._G.currentLaptopNumber
    local laptop = plr.Backpack:FindFirstChild(name) or plr.Character:FindFirstChild(name)
    if not laptop then
        for _, item in ipairs(plr.Backpack:GetChildren()) do
            local n = tonumber(item.Name:match("Illegal Laptop (%d+)"))
            if item:IsA("Tool") and n and n > _G.currentLaptopNumber then
                _G.currentLaptopNumber, laptop = n, item
                break
            end
        end
        if not laptop then
            currentStatus = "No laptops left."
            warn(currentStatus)
            return nil
        end
    end

    laptop.Parent = plr.Character
    wait(0.1)
    local menuLaptop = plr.Character:FindFirstChild(laptop.Name)
    if not menuLaptop then
        currentStatus = "Equip failed."
        warn(currentStatus)
        return nil
    end

    local hs = RepStore:WaitForChild("Events"):WaitForChild("HouseService")
    hs:FireServer("ATMMETHODopenmenu", menuLaptop)
    wait(2)
    hs:FireServer("ATMMETHODbegin", "begin")
    return laptop
end

-- Scan the UI to decide which word to solve
function scananddecide()
    local plr = Players.LocalPlayer
    local ui  = plr.PlayerGui.HudDisplay.ATMData.Hack.ScrollingFrame["2.2000000000000006"]
    task.wait(2)
    local raw = ui.Text:sub(56)

    local function sortStr(s)
        local t = {}
        for i = 1, #s do t[i] = s:sub(i,i) end
        table.sort(t)
        return table.concat(t)
    end

    local words = {"invalidate","possible","renowned","mystical","tropical","general","east"}
    for _, w in ipairs(words) do
        if sortStr(raw) == sortStr(w) then
            currentStatus = "Unscrambled: " .. w
            print(currentStatus)
            return w
        end
    end

    print("Not found")
    return nil
end

-- solve(): single guess per 0.3s via HouseService.ATMMETHODguess
function solve(word)
    if not word then return end

    local lists = {
        east =     {"east","seat","set","sea","sat","eat","ate","tea","eats"},
        general =  {"general","enlarge","angler","enrage","angel","green","range","large","anger","eagle",
                    "genre","agree","glare","angle","learn","real","earn","ear","near","regal","glee","lean",
                    "rage","lane","gene","gear","age","ran","nag","gel","rag","leg","lag"},
        mystical = {"mystical","mystic","claims","claim","calm","clam","slimy","scam","cams","clay","clays",
                    "macs","mics","city","mat","cam","mic","icy","mac","act","acts","aims","aim","cat","may",
                    "slam","misc","mits","mist","slim","slit","stay","cats","mit","lit","list","mail","last",
                    "salt","tail","cast","mats"},
        tropical = {"tropical","ratio","lap","plea","tire","tale","tear","tea","trap","trip","tie","tip",
                    "capital","capitol","clipart","part","caltrop","apricot","optical","tropic","tailor",
                    "air","portal","patrol","captor","cart","topic","optic","clap","clip","crap","crop",
                    "pact","rap","colt","cap","cat","lip","liar","tail","pal","lit","pit","lot","coral",
                    "pat","pic","cop","car"},
        renowned = {"renowned","downer","wonder","enrage","renown","redone","drown","endow","owned","newer",
                    "owner","deer","redo","oder","rode","den","doe","now","renew","ender","drone","down",
                    "drew","owed","word","worn","were","wore","done","need","nerd","neon","new","own","won",
                    "don","owe","end","woe","row","wed","nod","red","rod"},
        possible = {"possible","oil","spoils","slopes","possie","blips","plebs","bless","bliss","boils",
                    "lisp","poles","slips","slope","poses","isles","loses","silos","silo","spoil","soles",
                    "sips","lies","bios","sol","lie","boss","sob","blip","pleb","bops","boil","lips",
                    "slip","pole","pile","bop","bio","ops","pie","loss"},
        invalidate={"invalidate","validate","vailant","invalid","detail","dental","denial","vineal","detain",
                    "alien","delta","dealt","alive","livid","naive","ideal","indent","avian","vital","data",
                    "deal","anti","evil","deli","laid","line","idea","lied","lane","tend","indie","tile",
                    "end","alt","die","ant","tie","tin","den","deviant","invited","valaint","aviated",
                    "vandal","advent","divine","invade","invite","native","anvil","devil","lived","naval",
                    "valid","vent","diva","lint","date","late","live","land","van","eat","ate","aid",
                    "lid","lad","dive","let","net","nat","lie","via"},
    }

    local guessList = lists[word] or {}
    lastGuessList     = guessList
    if #guessList == 0 then return end

    local hs = RepStore:WaitForChild("Events"):WaitForChild("HouseService")
    for _, g in ipairs(guessList) do
        if not _G.EnabledATMFARM then break end
        hs:FireServer("ATMMETHODguess", g)
        task.wait(0.2)  -- Shortened from 0.3 to 0.2
        print("Guessed:", g)
    end

    if _G.EnabledATMFARM then
        for _ = 1, 3 do
            hs:FireServer("ATMMETHODguess", "yooo")
            task.wait(0.3)  -- Shortened from 0.5 to 0.3
        end
    end
end

-- ATM Main loop
local atmIsRunning = false
function atmMainloop()
    if not _G.MAINLOOPENABLED or atmIsRunning then return end
    atmIsRunning         = true
    _G.EnabledATMFARM = true

    local laptop = equipnactivate()
    if not laptop then
        _G.EnabledATMFARM = false
        atmIsRunning         = false
        return
    end

    local unequipped, timeoutExpired = false, false
    local unequipConn

    unequipConn = laptop.Unequipped:Connect(function()
        if unequipped then return end
        unequipped     = true
        currentStatus  = "Laptop unequipped... gathering debug."
        print(currentStatus)

        -- DEBUG: inspect the ScrollingFrame for each guess
        local frame = Players.LocalPlayer.PlayerGui.HudDisplay.ATMData.Hack.ScrollingFrame
        print("=== Guess Results ===")
        for _, g in ipairs(lastGuessList) do
            local found = false
            for _, child in ipairs(frame:GetDescendants()) do
                if (child:IsA("TextLabel") or child:IsA("TextBox"))
                   and child.Text:lower():find(g:lower()) then
                    found = true
                    break
                end
            end
            if found then
                print("✓ " .. g)
            else
                print("✗ " .. g .. " not found")
            end
        end
        print("=====================")

        -- cleanup and next loop
        _G.EnabledATMFARM = false
        unequipConn:Disconnect()
        atmIsRunning         = false
        task.wait(4)
        atmMainloop()
    end)

    -- safety timeout
    task.delay(40, function()
        if not unequipped then
            timeoutExpired  = true
            currentStatus   = "Timeout reached."
            _G.EnabledATMFARM = false
            atmIsRunning         = false
            atmMainloop()
        end
    end)

    -- start the hack
    wait(7)
    if unequipped or timeoutExpired then return end

    local w = scananddecide()
    if unequipped or timeoutExpired then return end
    solve(w)
end

-------------------------------------------------------------------
-- AUTO PUNCH FUNCTIONS
-------------------------------------------------------------------

-- Punch‑minigame solver
local function mathdo()
    local player      = Players.LocalPlayer
    local base        = player.PlayerGui:WaitForChild("HudDisplay")
                                   :WaitForChild("ATM")
                                   :WaitForChild("PunchMinigame")
    local firstNumber = tonumber(base:WaitForChild("FirstNumb").Text)
    local secondNumber= tonumber(base:WaitForChild("SecondNumb").Text)
    local lastNumber  = tonumber(base:WaitForChild("FinalResult").Text)

    if not (firstNumber and secondNumber and lastNumber) then
        warn("PunchMinigame: invalid numbers")
        return
    end

    local operation
    if      firstNumber + secondNumber == lastNumber then operation = "Add"
    elseif  firstNumber - secondNumber == lastNumber then operation = "Subtract"
    elseif  firstNumber * secondNumber == lastNumber then operation = "Multiply"
    elseif  secondNumber ~= 0 and firstNumber/secondNumber == lastNumber then operation = "Divide"
    else
        warn("PunchMinigame: no valid operation")
        return
    end

    local opButton = base:FindFirstChild(operation)
    if not opButton then
        warn("PunchMinigame: button not found:", operation)
        return
    end

    for _, conn in ipairs(getconnections(opButton.MouseButton1Click)) do
        conn:Fire()
    end
end

-- Auto Punch main loop
local function punchMainloop()
    while _G.AUTOPUNCHENABLED do
        -- Request the punch minigame
        local hs = RepStore:WaitForChild("Events"):WaitForChild("HouseService")
        hs:FireServer("ATMHudGiver", workspace.GameMap.AtmMachines.ATMMachine.ATM)
        wait(1)
        hs:FireServer("ATMMETHODmathbegin", true)
        wait(0.5)

        -- Attempt punch 6 times
        for i = 1, 6 do
            if not _G.AUTOPUNCHENABLED then return end
            mathdo()
            wait(0.3)  -- Shortened from 0.5 to 0.3
        end
        -- Loop again automatically if still enabled
    end
end

-------------------------------------------------------------------
-- GUI SETUP
-------------------------------------------------------------------

local plrGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- AUTO PUNCH GUI (Top)
local punchScreenGui = Instance.new("ScreenGui")
punchScreenGui.Name   = "PunchUI"
punchScreenGui.Parent = plrGui

local punchFrame = Instance.new("Frame")
punchFrame.Name             = "PunchFrame"
punchFrame.Size             = UDim2.new(0, 200, 0, 100)
punchFrame.Position         = UDim2.new(0.192, 0, 0.1, 0) -- Top position
punchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
punchFrame.BorderSizePixel  = 0
punchFrame.Active           = true
punchFrame.Draggable        = true
punchFrame.Style            = Enum.FrameStyle.DropShadow
punchFrame.Parent           = punchScreenGui

local punchTitle = Instance.new("TextLabel", punchFrame)
punchTitle.Name                 = "Title"
punchTitle.Size                 = UDim2.new(1, 0, 0, 30)
punchTitle.Position             = UDim2.new(0, 0, 0, 0)
punchTitle.BackgroundTransparency = 1
punchTitle.Font                 = Enum.Font.SourceSansBold
punchTitle.Text                 = "Flood's Hub - Auto Punch"
punchTitle.TextColor3           = Color3.fromRGB(255, 255, 255)
punchTitle.TextScaled           = true

local punchBtn = Instance.new("TextButton", punchFrame)
punchBtn.Name                 = "ToggleButton"
punchBtn.Size                 = UDim2.new(1, -20, 0, 40)
punchBtn.Position             = UDim2.new(0, 10, 1, -50)
punchBtn.Font                 = Enum.Font.SourceSans
punchBtn.TextScaled           = true
punchBtn.TextWrapped          = true
punchBtn.BorderSizePixel      = 0
punchBtn.BackgroundColor3     = Color3.fromRGB(118, 255, 108)
punchBtn.Text                 = "Enable"

local punchBtnCorner = Instance.new("UICorner", punchBtn)

-- ATM FARM GUI (Bottom)
local atmUI = Instance.new("ScreenGui")
atmUI.Name            = "atmUI V1"
atmUI.ResetOnSpawn    = false
atmUI.Parent          = plrGui

local atmFrame = Instance.new("Frame", atmUI)
atmFrame.BackgroundColor3   = Color3.fromRGB(30, 30, 30)
atmFrame.BorderSizePixel    = 0
atmFrame.Position           = UDim2.new(0.192, 0, 0.284, 0) -- Original position
atmFrame.Size               = UDim2.new(0, 263, 0, 387)
atmFrame.Style              = Enum.FrameStyle.DropShadow

local statHeading = Instance.new("TextLabel", atmFrame)
statHeading.BackgroundTransparency = 1
statHeading.Position               = UDim2.new(0.05, 0, 0.047, 0)
statHeading.Size                   = UDim2.new(0, 200, 0, 50)
statHeading.Font                   = Enum.Font.SourceSans
statHeading.Text                   = "Flood's Hub - ATM:"
statHeading.TextColor3             = Color3.new(1, 1, 1)
statHeading.TextScaled             = true

local statLetter = Instance.new("TextLabel", statHeading)
statLetter.BackgroundTransparency  = 1
statLetter.Position                = UDim2.new(0.448, 0, 0, 0)
statLetter.Size                    = UDim2.new(0, 200, 0, 50)
statLetter.Font                    = Enum.Font.SourceSans
statLetter.Text                    = "OFF"
statLetter.TextColor3              = Color3.fromRGB(255, 61, 61)
statLetter.TextScaled              = true

local statLetter2 = Instance.new("TextLabel", atmFrame)
statLetter2.BackgroundTransparency = 1
statLetter2.Position               = UDim2.new(0.106, 0, 0.6, 0)
statLetter2.Size                   = UDim2.new(0, 200, 0, 50)
statLetter2.Font                   = Enum.Font.SourceSans
statLetter2.Text                   = "Waiting..."
statLetter2.TextColor3             = Color3.new(1, 1, 1)
statLetter2.TextScaled             = true

coroutine.wrap(function()
    while true do
        statLetter2.Text = currentStatus or "Waiting..."
        wait(0.2)
    end
end)()

local atmBtn = Instance.new("TextButton", atmFrame)
atmBtn.BackgroundColor3 = Color3.fromRGB(118, 255, 108)
atmBtn.Position          = UDim2.new(0.127, 0, 0.328, 0)
atmBtn.Size              = UDim2.new(0, 200, 0, 50)
atmBtn.Font              = Enum.Font.SourceSans
atmBtn.Text              = "Toggle ATM"
atmBtn.TextColor3        = Color3.new(0, 0, 0)
atmBtn.TextScaled        = true
atmBtn.TextWrapped       = true
Instance.new("UICorner", atmBtn)

-------------------------------------------------------------------
-- GUI EVENT HANDLERS
-------------------------------------------------------------------

-- Auto Punch Toggle
_G.AUTOPUNCHENABLED = false
punchBtn.MouseButton1Click:Connect(function()
    _G.AUTOPUNCHENABLED = not _G.AUTOPUNCHENABLED
    if _G.AUTOPUNCHENABLED then
        punchBtn.Text             = "Disable"
        punchBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        -- Start the loop
        spawn(punchMainloop)
    else
        punchBtn.Text             = "Enable"
        punchBtn.BackgroundColor3 = Color3.fromRGB(118, 255, 108)
        -- punchMainloop will exit on its next check
    end
end)

-- ATM Farm Toggle
atmBtn.MouseButton1Click:Connect(function()
    _G.MAINLOOPENABLED = not _G.MAINLOOPENABLED
    statLetter.Text    = _G.MAINLOOPENABLED and "ON" or "OFF"
    statLetter.TextColor3 = _G.MAINLOOPENABLED
        and Color3.fromRGB(61, 255, 71)
        or Color3.fromRGB(255, 61, 61)
    if _G.MAINLOOPENABLED then atmMainloop() end
end)

-------------------------------------------------------------------
-- KEYBIND FUNCTIONALITY (LeftAlt for manual math solving)
-------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.LeftAlt then
        local player = Players.LocalPlayer
        local base = player.PlayerGui:WaitForChild("HudDisplay"):WaitForChild("ATM"):WaitForChild("PunchMinigame")
        local firstNumber = tonumber(base:WaitForChild("FirstNumb").Text)
        local secondNumber = tonumber(base:WaitForChild("SecondNumb").Text)
        local lastNumber = tonumber(base:WaitForChild("FinalResult").Text)

        if not (firstNumber and secondNumber and lastNumber) then
            warn("Error: One of the numbers is nil or not a valid number.")
            return
        end

        local operation

        if firstNumber + secondNumber == lastNumber then
            operation = "Add"
        elseif firstNumber - secondNumber == lastNumber then
            operation = "Subtract"
        elseif firstNumber * secondNumber == lastNumber then
            operation = "Multiply"
        elseif secondNumber ~= 0 and firstNumber / secondNumber == lastNumber then
            operation = "Divide"
        else
            warn("No valid operation found")
            return
        end

        print("Operation:", operation)

        local opButton = base:FindFirstChild(operation)
        if opButton then
            for i, v in next, getconnections(opButton.MouseButton1Click) do
                v:Fire()
            end
        else
            warn("Operation button not found")
        end
    end
end)

-------------------------------------------------------------------
-- AUTO-START ATM FARM IF ENABLED
-------------------------------------------------------------------

if _G.MAINLOOPENABLED then
    atmMainloop()
end
