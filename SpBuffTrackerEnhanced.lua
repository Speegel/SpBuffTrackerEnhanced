--[[
    SpBuffTracker Enhanced
    An improved buff tracking addon for WoW 1.12
    Inspired by https://github.com/Speegel/SpBuffTracker
    Compatible with Lua 5.0
    
    Version: 1.0.0
    Author: Enhanced version of Speegel's original
]]

-- Main addon table
SpBuffTrackerEnhanced = {
    version = "1.0.0",
    buffs = {},
    frame = nil,
    options = {
        enabled = true,
        scale = 1.0,
        growUpward = false,
        showTooltips = true,
        showText = true,
        showIcon = true,
        showBorder = true,
        showTimerText = true,
        updateInterval = 0.1,
        enableWarnings = true,
        soundWarnings = true,
        flashWarning = true,
        warningThreshold = 30, -- seconds
        alertOnBuffGain = true,
        position = {
            x = 0,
            y = -200,
            point = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER"
        },
        buffSize = 32,
        spacing = 2,
        fontName = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
        fontFlags = "OUTLINE",
        timeFormat = 1, -- 1 = MM:SS, 2 = M:SS, 3 = Seconds only
    },
    -- Default buffs to track
    trackedBuffs = {
        -- World buffs
        ["Rallying Cry of the Dragonslayer"] = true,
        ["Spirit of Zandalar"] = true,
        ["Songflower Serenade"] = true,
        ["Warchief's Blessing"] = true,
        ["Slip'kik's Savvy"] = true,
        ["Fengus' Ferocity"] = true,
        ["Mol'dar's Moxie"] = true,
        ["Fire Festival Fortitude"] = true,
        ["Fire Festival Fury"] = true,
        -- Consumables
        ["Elixir of the Mongoose"] = true,
        ["Elixir of Giants"] = true,
        ["Elixir of Greater Agility"] = true,
        ["Elixir of Greater Intellect"] = true,
        ["Greater Arcane Elixir"] = true,
        ["Elixir of Greater Firepower"] = true,
        ["Flask of Supreme Power"] = true,
        ["Flask of the Titans"] = true,
        ["Flask of Distilled Wisdom"] = true,
        ["Mageblood Potion"] = true,
        ["Blessed Sunfruit"] = true,
        ["Smoked Desert Dumplings"] = true,
        ["Grilled Squid"] = true,
        ["Nightfin Soup"] = true,
        ["Dire Maul Tribute"] = true,
    },
}

local SpBT = SpBuffTrackerEnhanced
local _G = getfenv(0)

-- Initialize addon
function SpBT:Initialize()
    -- Create main frame
    self:CreateMainFrame()
    
    -- Register events
    self.frame:RegisterEvent("PLAYER_AURAS_CHANGED")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("UNIT_AURA")
    
    -- Set up slash commands
    SLASH_SPBUFFTRACKER1 = "/spbt"
    SLASH_SPBUFFTRACKER2 = "/spbufftracker"
    SlashCmdList["SPBUFFTRACKER"] = function(msg)
        self:HandleSlashCommand(msg)
    end

    -- Create timer for updates
    self.updateTimer = 0
    
    -- Load saved variables
    self:LoadVariables()
    
    -- Create options panel
    self:CreateOptionsPanel()
    
    -- Initial update
    self:UpdateAllBuffs()
    
    -- Print startup message
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced v" .. self.version .. " loaded. Type /spbt for options.|r")
end

-- Load saved variables from disk
function SpBT:LoadVariables()
    if SpBuffTrackerEnhancedDB then
        -- Merge saved options with defaults
        for k, v in pairs(SpBuffTrackerEnhancedDB) do
            if self.options[k] ~= nil then
                self.options[k] = v
            end
        end
        
        -- Load tracked buffs if saved
        if SpBuffTrackerEnhancedDB.trackedBuffs then
            self.trackedBuffs = SpBuffTrackerEnhancedDB.trackedBuffs
        end
    else
        -- Initialize database
        SpBuffTrackerEnhancedDB = self.options
        SpBuffTrackerEnhancedDB.trackedBuffs = self.trackedBuffs
    end
    
    -- Apply loaded settings
    self:ApplySettings()
end

-- Save variables to disk
function SpBT:SaveVariables()
    SpBuffTrackerEnhancedDB = self.options
    SpBuffTrackerEnhancedDB.trackedBuffs = self.trackedBuffs
end

-- Apply current settings
function SpBT:ApplySettings()
    self.frame:SetScale(self.options.scale)
    self.frame:ClearAllPoints()
    self.frame:SetPoint(
        self.options.position.point,
        self.options.position.relativeTo,
        self.options.position.relativePoint,
        self.options.position.x,
        self.options.position.y
    )
    
    -- Refresh buff display
    self:UpdateAllBuffs()
    self:LayoutBuffs()
end

-- Create the main frame
function SpBT:CreateMainFrame()
    self.frame = CreateFrame("Frame", "SpBuffTrackerEnhancedFrame", UIParent)
    self.frame:SetWidth(40)
    self.frame:SetHeight(40)
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function()
        if IsShiftKeyDown() then
            this:StartMoving()
        end
    end)
    self.frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local point, relativeTo, relativePoint, x, y = this:GetPoint()
        SpBT.options.position.point = point
        SpBT.options.position.relativeTo = relativeTo:GetName()
        SpBT.options.position.relativePoint = relativePoint
        SpBT.options.position.x = x
        SpBT.options.position.y = y
        SpBT:SaveVariables()
    end)
    
    -- Set up event handling
    self.frame:SetScript("OnEvent", function()
        if event == "PLAYER_AURAS_CHANGED" or event == "UNIT_AURA" and arg1 == "player" then
            SpBT:UpdateAllBuffs()
        elseif event == "PLAYER_ENTERING_WORLD" then
            SpBT:UpdateAllBuffs()
        end
    end)
    
    -- Set up update handling
    self.frame:SetScript("OnUpdate", function()
        SpBT.updateTimer = SpBT.updateTimer + arg1
        if SpBT.updateTimer >= SpBT.options.updateInterval then
            SpBT:UpdateBuffTimers()
            SpBT.updateTimer = 0
        end
    end)
    
    -- Create tooltip for main frame
    self.frame:SetScript("OnEnter", function()
        if SpBT.options.showTooltips then
            GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
            GameTooltip:AddLine("SpBuffTracker Enhanced")
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Shift+Click and drag to move", 0, 1, 0)
            GameTooltip:AddLine("Type /spbt for options", 0, 1, 0)
            GameTooltip:Show()
        end
    end)
    self.frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Create a buff frame
function SpBT:CreateBuffFrame(buffIndex)
    local frame = CreateFrame("Button", "SpBuffTrackerEnhancedBuff"..buffIndex, self.frame)
    frame:SetWidth(self.options.buffSize)
    frame:SetHeight(self.options.buffSize)
    
    -- Create icon texture
    frame.icon = frame:CreateTexture(frame:GetName().."Icon", "ARTWORK")
    frame.icon:SetAllPoints(frame)
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Trim edges
    
    -- Create border texture
    frame.border = frame:CreateTexture(frame:GetName().."Border", "OVERLAY")
    frame.border:SetWidth(self.options.buffSize + 2)
    frame.border:SetHeight(self.options.buffSize + 2)
    frame.border:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
    
    -- Create cooldown model
    frame.cooldown = CreateFrame("Model", frame:GetName().."Cooldown", frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame)
    frame.cooldown:SetFrameLevel(frame:GetFrameLevel())
    
    -- Create timer text
    frame.timer = frame:CreateFontString(frame:GetName().."Timer", "OVERLAY")
    frame.timer:SetFont(self.options.fontName, self.options.fontSize, self.options.fontFlags)
    frame.timer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
    
    -- Create name text
    frame.name = frame:CreateFontString(frame:GetName().."Name", "OVERLAY")
    frame.name:SetFont(self.options.fontName, self.options.fontSize - 2, self.options.fontFlags)
    frame.name:SetPoint("TOP", frame, "BOTTOM", 0, -1)
    
    -- Set up tooltip
    frame:SetScript("OnEnter", function()
        if SpBT.options.showTooltips then
            GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
            local buff = SpBT.buffs[this:GetID()]
            if buff then
                GameTooltip:AddLine(buff.name)
                if buff.duration > 0 then
                    GameTooltip:AddLine("Time remaining: " .. SpBT:FormatTime(buff.timeLeft), 1, 1, 1)
                end
                GameTooltip:Show()
            end
        end
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Set up context menu
    frame:RegisterForClicks("RightButtonUp")
    frame:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            local buff = SpBT.buffs[this:GetID()]
            if buff then
                SpBT.trackedBuffs[buff.name] = nil
                SpBT:SaveVariables()
                SpBT:UpdateAllBuffs()
            end
        end
    end)
    
    return frame
end

-- Update all player buffs
function SpBT:UpdateAllBuffs()
    -- Store old buffs for comparison
    local oldBuffs = {}
    for k, v in pairs(self.buffs) do
        oldBuffs[v.name] = true
    end
    
    -- Clear current buffs
    for i = 1, table.getn(self.buffs) do
        local buffFrame = _G["SpBuffTrackerEnhancedBuff"..i]
        if buffFrame and buffFrame.isFlashing then
            self:StopFlashAnimation(buffFrame)
        end
        self.buffs[i] = nil
    end
    
    -- Check all player buffs
    local buffIndex = 1
    for i = 1, 32 do
        local buffName, buffRank, buffIcon, buffCount, buffType, buffDuration, buffEnd, buffCaster = UnitBuff("player", i)
        if not buffName then break end
        
        -- If this buff is being tracked
        if self.trackedBuffs[buffName] then
            -- Calculate remaining time
            local timeLeft = 0
            if buffEnd then
                timeLeft = buffEnd - GetTime()
            end
            
            -- Add to tracked buffs table
            self.buffs[buffIndex] = {
                name = buffName,
                icon = buffIcon,
                duration = buffDuration or 0,
                timeLeft = timeLeft,
                index = i
            }
            
            -- Show notification when a new buff is gained
            if self.options.alertOnBuffGain and not oldBuffs[buffName] then
                self:ShowBuffNotification(buffName, buffIcon, timeLeft)
            end
            
            buffIndex = buffIndex + 1
        end
    end
    
    -- Update the layout
    self:LayoutBuffs()
end

-- Show a notification when a new buff is gained
function SpBT:ShowBuffNotification(buffName, buffIcon, duration)
    if not self.notificationFrame then
        -- Create notification frame
        local frame = CreateFrame("Frame", "SpBuffTrackerEnhancedNotification", UIParent)
        frame:SetWidth(250)
        frame:SetHeight(50)
        frame:SetPoint("TOP", UIParent, "TOP", 0, -100)
        frame:SetFrameStrata("HIGH")
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:Hide()
        
        -- Create icon
        frame.icon = frame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetWidth(32)
        frame.icon:SetHeight(32)
        frame.icon:SetPoint("LEFT", frame, "LEFT", 15, 0)
        frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Trim edges
        
        -- Create border for icon
        frame.border = frame:CreateTexture(nil, "OVERLAY")
        frame.border:SetWidth(34)
        frame.border:SetHeight(34)
        frame.border:SetPoint("CENTER", frame.icon, "CENTER", 0, 0)
        frame.border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
        
        -- Create text
        frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 10, 5)
        frame.text:SetJustifyH("LEFT")
        
        -- Create duration text
        frame.duration = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.duration:SetPoint("TOPLEFT", frame.text, "BOTTOMLEFT", 0, -2)
        frame.duration:SetJustifyH("LEFT")
        
        -- Create fade animation
        frame.fadeGroup = frame:CreateAnimationGroup()
        
        local fadeIn = frame.fadeGroup:CreateAnimation("Alpha")
        fadeIn:SetDuration(0.3)
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetOrder(1)
        
        local wait = frame.fadeGroup:CreateAnimation("Alpha")
        wait:SetDuration(2.5)
        wait:SetFromAlpha(1)
        wait:SetToAlpha(1)
        wait:SetOrder(2)
        
        local fadeOut = frame.fadeGroup:CreateAnimation("Alpha")
        fadeOut:SetDuration(0.7)
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetOrder(3)
        
        frame.fadeGroup:SetScript("OnFinished", function()
            this:GetParent():Hide()
        end)
        
        self.notificationFrame = frame
        
        -- Play a sound when showing
        -- PlaySoundFile("Interface\\AddOns\\SpBuffTrackerEnhanced\\sounds\\buff_gained.ogg")
    end
    
    -- Update notification
    self.notificationFrame.icon:SetTexture(buffIcon)
    self.notificationFrame.text:SetText(buffName)
    
    if duration > 0 then
        self.notificationFrame.duration:SetText("Duration: " .. self:FormatTime(duration))
    else
        self.notificationFrame.duration:SetText("Duration: Indefinite")
    end
    
    -- Show and start animation
    self.notificationFrame:Show()
    self.notificationFrame.fadeGroup:Play()
end

-- Update buff timers
function SpBT:UpdateBuffTimers()
    local currentTime = GetTime()
    local needsRefresh = false
    
    for i, buff in ipairs(self.buffs) do
        if buff.duration > 0 then
            -- Update time left
            local previousTime = buff.timeLeft
            buff.timeLeft = buff.timeLeft - self.options.updateInterval
            
            -- Update timer text if shown
            if self.options.showTimerText then
                local buffFrame = _G["SpBuffTrackerEnhancedBuff"..i]
                if buffFrame then
                    buffFrame.timer:SetText(self:FormatTime(buff.timeLeft))
                    
                    -- Warning colors for low time
                    if self.options.enableWarnings and buff.timeLeft <= self.options.warningThreshold then
                        -- Red text when below threshold
                        buffFrame.timer:SetTextColor(1, 0, 0)
                        
                        -- Flash animation when time is running out
                        if self.options.flashWarning and buff.timeLeft <= 10 and not buffFrame.isFlashing then
                            self:StartFlashAnimation(buffFrame)
                            buffFrame.isFlashing = true
                        end
                        
                        -- Sound warning when crossing thresholds
                        if self.options.soundWarnings then
                            -- Play warning sound at 30, 10, and 5 seconds
                            if (previousTime > 30 and buff.timeLeft <= 30) or
                               (previousTime > 10 and buff.timeLeft <= 10) or
                               (previousTime > 5 and buff.timeLeft <= 5) then
                                -- PlaySoundFile("Interface\\AddOns\\SpBuffTrackerEnhanced\\sounds\\warning.ogg")
                            end
                        end
                    else
                        -- Normal color
                        buffFrame.timer:SetTextColor(1, 1, 1)
                    end
                end
            end
            
            -- Check if buff has expired
            if buff.timeLeft <= 0 then
                needsRefresh = true
                break
            end
        end
    end
    
    -- If a buff has expired, do a full refresh
    if needsRefresh then
        self:UpdateAllBuffs()
    end
end

-- Start flash animation on a buff frame
function SpBT:StartFlashAnimation(frame)
    if not frame.flashGroup then
        frame.flashGroup = frame:CreateAnimationGroup()
        frame.flashGroup:SetLooping("REPEAT")
        
        local fadeOut = frame.flashGroup:CreateAnimation("Alpha")
        fadeOut:SetDuration(0.5)
        fadeOut:SetFromAlpha(1.0)
        fadeOut:SetToAlpha(0.3)
        fadeOut:SetOrder(1)
        
        local fadeIn = frame.flashGroup:CreateAnimation("Alpha")
        fadeIn:SetDuration(0.5)
        fadeIn:SetFromAlpha(0.3)
        fadeIn:SetToAlpha(1.0)
        fadeIn:SetOrder(2)
    end
    
    frame.flashGroup:Play()
end

-- Stop flash animation on a buff frame
function SpBT:StopFlashAnimation(frame)
    if frame.flashGroup then
        frame.flashGroup:Stop()
        frame.isFlashing = false
    end
end

-- Format time based on user preference
function SpBT:FormatTime(timeInSeconds)
    if timeInSeconds <= 0 then return "0" end
    
    -- Format: MM:SS
    if self.options.timeFormat == 1 then
        local minutes = math.floor(timeInSeconds / 60)
        local seconds = math.floor(timeInSeconds % 60)
        return string.format("%02d:%02d", minutes, seconds)
    
    -- Format: M:SS
    elseif self.options.timeFormat == 2 then
        local minutes = math.floor(timeInSeconds / 60)
        local seconds = math.floor(timeInSeconds % 60)
        return string.format("%d:%02d", minutes, seconds)
    
    -- Format: Seconds only
    else
        if timeInSeconds >= 60 then
            return string.format("%.0fm", timeInSeconds / 60)
        else
            return string.format("%.0f", timeInSeconds)
        end
    end
end

-- Layout buff frames
function SpBT:LayoutBuffs()
    local buffCount = table.getn(self.buffs)
    
    -- Create buff frames as needed
    for i = 1, buffCount do
        local buffFrame = _G["SpBuffTrackerEnhancedBuff"..i]
        if not buffFrame then
            buffFrame = self:CreateBuffFrame(i)
        end
        
        -- Set ID for reference
        buffFrame:SetID(i)
        
        -- Update appearance
        local buff = self.buffs[i]
        buffFrame.icon:SetTexture(buff.icon)
        
        -- Show/hide border
        if self.options.showBorder then
            buffFrame.border:Show()
        else
            buffFrame.border:Hide()
        end
        
        -- Update cooldown
        if buff.duration > 0 then
            CooldownFrame_SetTimer(buffFrame.cooldown, GetTime() - (buff.duration - buff.timeLeft), buff.duration, 1)
        else
            buffFrame.cooldown:Hide()
        end
        
        -- Update timer text
        if self.options.showTimerText and buff.duration > 0 then
            buffFrame.timer:SetText(self:FormatTime(buff.timeLeft))
            buffFrame.timer:Show()
        else
            buffFrame.timer:Hide()
        end
        
        -- Update name text
        if self.options.showText then
            local shortName = string.gsub(buff.name, "Elixir of ", "")
            shortName = string.gsub(shortName, "Flask of ", "")
            buffFrame.name:SetText(shortName)
            buffFrame.name:Show()
        else
            buffFrame.name:Hide()
        end
        
        -- Position the buff frame
        buffFrame:ClearAllPoints()
        if i == 1 then
            if self.options.growUpward then
                buffFrame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
            else
                buffFrame:SetPoint("TOP", self.frame, "TOP", 0, 0)
            end
        else
            local prevFrame = _G["SpBuffTrackerEnhancedBuff"..(i-1)]
            if self.options.growUpward then
                buffFrame:SetPoint("BOTTOM", prevFrame, "TOP", 0, self.options.spacing)
            else
                buffFrame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -self.options.spacing)
            end
        end
        
        -- Show the frame
        buffFrame:Show()
    end
    
    -- Hide unused buff frames
    for i = buffCount + 1, 32 do
        local buffFrame = _G["SpBuffTrackerEnhancedBuff"..i]
        if buffFrame then
            buffFrame:Hide()
        end
    end
    
    -- Resize main frame
    local totalHeight = buffCount * (self.options.buffSize + self.options.spacing)
    self.frame:SetHeight(totalHeight)
end

-- Create GUI options panel
function SpBT:CreateOptionsPanel()
    -- Main frame
    local panel = CreateFrame("Frame", "SpBuffTrackerEnhancedOptions")
    panel.name = "SpBuffTracker Enhanced"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("SpBuffTracker Enhanced v" .. self.version)
    
    -- Instructions
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure addon settings below or use /spbt commands")
    
    -- Create a scrollable content frame
    local scrollFrame = CreateFrame("ScrollFrame", "SpBuffTrackerEnhancedOptionsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 8)
    
    local content = CreateFrame("Frame", "SpBuffTrackerEnhancedOptionsScrollContent", scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 500) -- Height will adjust as needed
    scrollFrame:SetScrollChild(content)
    
    local y = 0
    local spacing = 25 -- Spacing between option rows
    
    -- Create section title function
    local function addSectionTitle(text)
        local section = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        section:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        section:SetText(text)
        y = y - 20
    end
    
    -- Create checkbox function
    local function addCheckbox(label, key)
        local checkbox = CreateFrame("CheckButton", "SpBuffTrackerEnhancedOptions_" .. key, content, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        getglobal(checkbox:GetName() .. "Text"):SetText(label)
        
        checkbox:SetChecked(SpBT.options[key])
        checkbox:SetScript("OnClick", function()
            SpBT.options[key] = this:GetChecked()
            SpBT:ApplySettings()
            SpBT:SaveVariables()
        end)
        
        y = y - spacing
        return checkbox
    end
    
    -- Create slider function
    local function addSlider(label, key, min, max, step)
        local name = "SpBuffTrackerEnhancedOptions_" .. key
        
        local text = content:CreateFontString(name .. "Label", "ARTWORK", "GameFontNormal")
        text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        text:SetText(label)
        
        local slider = CreateFrame("Slider", name, content, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -4)
        slider:SetWidth(200)
        slider:SetHeight(16)
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(SpBT.options[key])
        
        getglobal(slider:GetName() .. "Low"):SetText(min)
        getglobal(slider:GetName() .. "High"):SetText(max)
        getglobal(slider:GetName() .. "Text"):SetText(slider:GetValue())
        
        slider:SetScript("OnValueChanged", function()
            local val = floor(this:GetValue() * 100 + 0.5) / 100 -- Round to 2 decimal places
            getglobal(this:GetName() .. "Text"):SetText(val)
            SpBT.options[key] = val
            SpBT:ApplySettings()
            SpBT:SaveVariables()
        end)
        
        y = y - (spacing + 15)
        return slider
    end
    
    -- Create dropdown function
    local function addDropdown(label, key, options)
        local name = "SpBuffTrackerEnhancedOptions_" .. key
        
        local text = content:CreateFontString(name .. "Label", "ARTWORK", "GameFontNormal")
        text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        text:SetText(label)
        y = y - 16
        
        local dropdown = CreateFrame("Frame", name, content, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -15, y)
        
        UIDropDownMenu_SetWidth(120, dropdown)
        
        UIDropDownMenu_Initialize(dropdown, function()
            local info = {}
            for k, v in pairs(options) do
                info = {
                    text = v,
                    value = k,
                    func = function()
                        UIDropDownMenu_SetSelectedValue(dropdown, this.value)
                        SpBT.options[key] = this.value
                        SpBT:ApplySettings()
                        SpBT:SaveVariables()
                    end
                }
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        UIDropDownMenu_SetSelectedValue(dropdown, SpBT.options[key])
        UIDropDownMenu_JustifyText("LEFT", dropdown)
        
        y = y - spacing
        return dropdown
    end
    
    -- Create button function
    local function addButton(label, callback)
        local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        button:SetText(label)
        button:SetWidth(120)
        button:SetHeight(22)
        button:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        button:SetScript("OnClick", callback)
        
        y = y - spacing
        return button
    end
    
    -- Add option sections
    addSectionTitle("General Options")
    addCheckbox("Enabled", "enabled")
    addSlider("Scale", "scale", 0.5, 2.0, 0.1)
    addDropdown("Growth Direction", "growUpward", {[false] = "Downward", [true] = "Upward"})
    
    addSectionTitle("Visual Options")
    addSlider("Buff Size", "buffSize", 16, 64, 2)
    addSlider("Spacing", "spacing", 0, 10, 1)
    addCheckbox("Show Buff Names", "showText")
    addCheckbox("Show Timers", "showTimerText")
    addCheckbox("Show Borders", "showBorder")
    addCheckbox("Show Tooltips", "showTooltips")
    
    addSectionTitle("Warning Options")
    addCheckbox("Enable Warnings", "enableWarnings")
    addCheckbox("Sound Warnings", "soundWarnings")
    addCheckbox("Flash Warning Animation", "flashWarning")
    addSlider("Warning Threshold (seconds)", "warningThreshold", 5, 60, 5)
    addCheckbox("Alert on Buff Gain", "alertOnBuffGain")
    
    addSectionTitle("Time Format")
    local timeFormatOptions = {
        [1] = "MM:SS (01:23)",
        [2] = "M:SS (1:23)",
        [3] = "Seconds only (83s)"
    }
    addDropdown("Timer Format", "timeFormat", timeFormatOptions)
    
    addSectionTitle("Buff Management")
    addButton("Manage Tracked Buffs", function()
        SpBT:CreateBuffManagementPanel()
    end)
    
    addButton("Reset to Defaults", function()
        StaticPopupDialogs["SPBUFFTRACKER_RESET"] = {
            text = "Reset SpBuffTracker Enhanced to defaults?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                SpBuffTrackerEnhancedDB = nil
                ReloadUI()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("SPBUFFTRACKER_RESET")
    end)
    
    -- Adjust scrollframe content height
    content:SetHeight(math.abs(y) + 20)
    
    -- Add panel to interface options
    InterfaceOptions_AddCategory(panel)
    
    return panel
end

-- Create buff management panel
function SpBT:CreateBuffManagementPanel()
    if self.buffPanel and self.buffPanel:IsVisible() then
        self.buffPanel:Hide()
        return
    end
    
    -- Create or show panel
    if not self.buffPanel then
        local panel = CreateFrame("Frame", "SpBuffTrackerEnhancedBuffPanel", UIParent)
        panel:SetWidth(300)
        panel:SetHeight(400)
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        panel:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        panel:EnableMouse(true)
        panel:SetMovable(true)
        panel:RegisterForDrag("LeftButton")
        panel:SetScript("OnDragStart", function() this:StartMoving() end)
        panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
        
        -- Title
        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        title:SetPoint("TOP", panel, "TOP", 0, -15)
        title:SetText("Manage Tracked Buffs")
        
        -- Close button
        local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)
        
        -- Create scrollframe for buff list
        local scroll = CreateFrame("ScrollFrame", "SpBuffTrackerEnhancedBuffScroll", panel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -40)
        scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -40, 40)
        
        local content = CreateFrame("Frame", "SpBuffTrackerEnhancedBuffScrollContent", scroll)
        content:SetWidth(scroll:GetWidth())
        content:SetHeight(500) -- Will adjust dynamically
        scroll:SetScrollChild(content)
        
        -- Add buff button
        local addBuffBox = CreateFrame("EditBox", "SpBuffTrackerEnhancedAddBuffBox", panel, "InputBoxTemplate")
        addBuffBox:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 25, 15)
        addBuffBox:SetWidth(180)
        addBuffBox:SetHeight(20)
        addBuffBox:SetAutoFocus(false)
        
        local addBuffButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        addBuffButton:SetPoint("LEFT", addBuffBox, "RIGHT", 5, 0)
        addBuffButton:SetWidth(60)
        addBuffButton:SetHeight(22)
        addBuffButton:SetText("Add")
        addBuffButton:SetScript("OnClick", function()
            local buffName = addBuffBox:GetText()
            if buffName and buffName ~= "" then
                SpBT.trackedBuffs[buffName] = true
                SpBT:SaveVariables()
                SpBT:UpdateAllBuffs()
                SpBT:UpdateBuffManagementPanel()
                addBuffBox:SetText("")
            end
        end)
        
        -- Store references
        panel.content = content
        self.buffPanel = panel
    end
    
    -- Update buff list
    self:UpdateBuffManagementPanel()
    
    -- Show panel
    self.buffPanel:Show()
end

-- Update buff management panel content
function SpBT:UpdateBuffManagementPanel()
    if not self.buffPanel then return end
    
    local content = self.buffPanel.content
    
    -- Clear existing content
    local children = {content:GetChildren()}
    for _, child in pairs(children) do
        child:Hide()
    end
    
    -- Add buff entries
    local y = 0
    local count = 0
    
    for buffName in pairs(self.trackedBuffs) do
        count = count + 1
        
        local frame = CreateFrame("Frame", "SpBuffTrackerEnhancedBuffEntry"..count, content)
        frame:SetWidth(content:GetWidth() - 20)
        frame:SetHeight(24)
        frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        
        -- Buff name
        local name = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        name:SetPoint("LEFT", frame, "LEFT", 5, 0)
        name:SetText(buffName)
        name:SetWidth(frame:GetWidth() - 30)
        name:SetJustifyH("LEFT")
        
        -- Remove button
        local remove = CreateFrame("Button", nil, frame)
        remove:SetWidth(16)
        remove:SetHeight(16)
        remove:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        remove:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
        remove:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
        remove:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        remove:SetScript("OnClick", function()
            SpBT.trackedBuffs[buffName] = nil
            SpBT:SaveVariables()
            SpBT:UpdateAllBuffs()
            SpBT:UpdateBuffManagementPanel()
        end)
        
        y = y - 24
    end
    
    -- Adjust content height
    content:SetHeight(math.max(math.abs(y), 200))
end

-- Handle slash commands
function SpBT:HandleSlashCommand(msg)
    msg = string.lower(msg)
    local args = {}
    for arg in string.gfind(msg, "%S+") do
        table.insert(args, arg)
    end
    
    -- Help / no command
    if not args[1] or args[1] == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00SpBuffTracker Enhanced Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt - Show this help|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt config - Open configuration panel|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt toggle - Toggle addon on/off|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt scale <value> - Set scale (0.5-2.0)|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt grow <up/down> - Set growth direction|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt size <value> - Set buff size (16-64)|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt spacing <value> - Set spacing (0-10)|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt text <show/hide> - Toggle buff names|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt timer <show/hide> - Toggle timers|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt border <show/hide> - Toggle borders|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt tooltip <show/hide> - Toggle tooltips|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt timeformat <1/2/3> - Set time format|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt track <buffname> - Track a new buff|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt untrack <buffname> - Remove a tracked buff|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt buffs - Open buff management panel|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt reset - Reset to defaults|r")
        return
    end
    
    -- Open config
    if args[1] == "config" then
        InterfaceOptionsFrame_OpenToCategory("SpBuffTracker Enhanced")
        return
    end
    
    -- Open buff management
    if args[1] == "buffs" then
        self:CreateBuffManagementPanel()
        return
    end
    
    -- Toggle addon
    if args[1] == "toggle" then
        self.options.enabled = not self.options.enabled
        if self.options.enabled then
            self.frame:Show()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced enabled.|r")
        else
            self.frame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Enhanced disabled.|r")
        end
        self:SaveVariables()
        return
    end
    
    -- Set scale
    if args[1] == "scale" and args[2] then
        local scale = tonumber(args[2])
        if scale and scale >= 0.5 and scale <= 2.0 then
            self.options.scale = scale
            self:ApplySettings()
            self:SaveVariables()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced scale set to " .. scale .. ".|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid scale. Use a value between 0.5 and 2.0.|r")
        end
        return
    end
    
    -- Set growth direction
    if args[1] == "grow" and args[2] then
        if args[2] == "up" then
            self.options.growUpward = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced will grow upward.|r")
        elseif args[2] == "down" then
            self.options.growUpward = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced will grow downward.|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid direction. Use 'up' or 'down'.|r")
            return
        end
        self:ApplySettings()
        self:SaveVariables()
        return
    end
    
    -- Set buff size
    if args[1] == "size" and args[2] then
        local size = tonumber(args[2])
        if size and size >= 16 and size <= 64 then
            self.options.buffSize = size
            self:ApplySettings()
            self:SaveVariables()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced buff size set to " .. size .. ".|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid size. Use a value between 16 and 64.|r")
        end
        return
    end
    
    -- Set spacing
    if args[1] == "spacing" and args[2] then
        local spacing = tonumber(args[2])
        if spacing and spacing >= 0 and spacing <= 10 then
            self.options.spacing = spacing
            self:ApplySettings()
            self:SaveVariables()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced spacing set to " .. spacing .. ".|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid spacing. Use a value between 0 and 10.|r")
        end
        return
    end
    
    -- Toggle buff text
    if args[1] == "text" and args[2] then
        if args[2] == "show" then
            self.options.showText = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced buff names enabled.|r")
        elseif args[2] == "hide" then
            self.options.showText = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced buff names disabled.|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid option. Use 'show' or 'hide'.|r")
            return
        end
        self:ApplySettings()
        self:SaveVariables()
        return
    end
    
    -- Toggle timer text
    if args[1] == "timer" and args[2] then
        if args[2] == "show" then
            self.options.showTimerText = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced timers enabled.|r")
        elseif args[2] == "hide" then
            self.options.showTimerText = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced timers disabled.|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid option. Use 'show' or 'hide'.|r")
            return
        end
        self:ApplySettings()
        self:SaveVariables()
        return
    end
    
    -- Toggle borders
    if args[1] == "border" and args[2] then
        if args[2] == "show" then
            self.options.showBorder = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced borders enabled.|r")
        elseif args[2] == "hide" then
            self.options.showBorder = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced borders disabled.|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid option. Use 'show' or 'hide'.|r")
            return
        end
        self:ApplySettings()
        self:SaveVariables()
        return
    end
    
    -- Toggle tooltips
    if args[1] == "tooltip" and args[2] then
        if args[2] == "show" then
            self.options.showTooltips = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced tooltips enabled.|r")
        elseif args[2] == "hide" then
            self.options.showTooltips = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced tooltips disabled.|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid option. Use 'show' or 'hide'.|r")
            return
        end
        self:ApplySettings()
        self:SaveVariables()
        return
    end
    
    -- Set time format
    if args[1] == "timeformat" and args[2] then
        local format = tonumber(args[2])
        if format and format >= 1 and format <= 3 then
            self.options.timeFormat = format
            self:ApplySettings()
            self:SaveVariables()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced time format set to " .. format .. ".|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid format. Use 1 (MM:SS), 2 (M:SS), or 3 (Seconds).|r")
        end
        return
    end
    
    -- Track a new buff
    if args[1] == "track" and args[2] then
        -- Combine remaining args for buff name
        local buffName = ""
        for i = 2, table.getn(args) do
            if i > 2 then
                buffName = buffName .. " "
            end
            buffName = buffName .. args[i]
        end
        
        -- Add to tracked buffs
        self.trackedBuffs[buffName] = true
        self:SaveVariables()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced now tracking: " .. buffName .. ".|r")
        self:UpdateAllBuffs()
        return
    end
    
    -- Untrack a buff
    if args[1] == "untrack" and args[2] then
        -- Combine remaining args for buff name
        local buffName = ""
        for i = 2, table.getn(args) do
            if i > 2 then
                buffName = buffName .. " "
            end
            buffName = buffName .. args[i]
        end
        
        -- Remove from tracked buffs
        if self.trackedBuffs[buffName] then
            self.trackedBuffs[buffName] = nil
            self:SaveVariables()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced no longer tracking: " .. buffName .. ".|r")
            self:UpdateAllBuffs()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Buff not found in tracked buffs: " .. buffName .. ".|r")
        end
        return
    end
    
    -- Reset to defaults
    if args[1] == "reset" then
        -- Confirm with player
        StaticPopupDialogs["SPBUFFTRACKER_RESET"] = {
            text = "Reset SpBuffTracker Enhanced to defaults?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                -- Reset options
                SpBuffTrackerEnhancedDB = nil
                ReloadUI()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("SPBUFFTRACKER_RESET")
        return
    end
    
    -- Unknown command
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Unknown SpBuffTracker Enhanced command. Type /spbt for help.|r")
end

-- Initialize when addon is loaded
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "SpBuffTrackerEnhanced" then
        SpBT:Initialize()
    end
end)