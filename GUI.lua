--[[
    SpBuffTracker Enhanced
    GUI elements and frame creation
    Version: 1.1.0
]]

local SpBT = SpBuffTrackerEnhanced

-- Create the main frame
function SpBT:CreateMainFrame()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Creating main frame|r")
    
    -- Create a global reference to the frame first - using fixed standard naming
    local mainFrame = CreateFrame("Frame", "SpBuffTrackerEnhancedMainFrame", UIParent)
    
    -- Set up the frame - use minimal settings to avoid crashes
    mainFrame:SetWidth(300)  -- Wider to accommodate both active and missing buffs
    mainFrame:SetHeight(50)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    
    -- Create a simple background to make it visible
    local bg = mainFrame:CreateTexture("SpBuffTrackerEnhancedFrameBG", "BACKGROUND")
    bg:SetTexture(0, 0, 0, 0.5) -- Semi-transparent black
    bg:SetAllPoints(mainFrame)
    
    -- Create a title text to identify the frame
    local titleText = mainFrame:CreateFontString("SpBuffTrackerEnhancedFrameTitle", "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", mainFrame, "TOP", 0, -10)
    titleText:SetText("SpBuffTracker Enhanced")
    
    -- Create status text
    local statusText = mainFrame:CreateFontString("SpBuffTrackerEnhancedFrameStatus", "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 10)
    statusText:SetText("Active: 0 | Missing: 0")
    
    -- Keep movement functionality simple to avoid crashes
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    
    -- Simple dragging logic that should be stable
    mainFrame:SetScript("OnDragStart", function()
        -- No shift key requirement to reduce complexity
        mainFrame:StartMoving()
    end)
    
    mainFrame:SetScript("OnDragStop", function()
        mainFrame:StopMovingOrSizing()
        -- Save position after moving
        if SpBT.options and SpBT.options.position then
            local point, relativeTo, relativePoint, xOfs, yOfs = mainFrame:GetPoint()
            SpBT.options.position.point = point
            SpBT.options.position.relativePoint = relativePoint
            SpBT.options.position.x = xOfs
            SpBT.options.position.y = yOfs
            SpBT:SaveVariables()
        end
    end)
    
    -- Set up very basic event handling for now
    mainFrame:SetScript("OnEvent", function()
        if event == "PLAYER_AURAS_CHANGED" or (event == "UNIT_AURA" and arg1 == "player") then
            -- Just call UpdateAllBuffs, nothing else
            SpBT:UpdateAllBuffs()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Buff change detected|r")
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Force an update when the player enters the world
            SpBT:UpdateAllBuffs()
        end
    end)
    
    -- Register minimal events
    mainFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Set visibility
    mainFrame:Show()
    
    -- Store the frame reference in both global and local tables
    _G["SpBuffTrackerEnhancedMainFrame"] = mainFrame
    self.frame = mainFrame
    SpBuffTrackerEnhanced.frame = mainFrame
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Enhanced main frame created successfully|r")
    return mainFrame
end

-- Create a buff frame
function SpBT:CreateBuffFrame(buffIndex)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Creating buff frame %d|r", buffIndex))
    
    -- Make sure we have the main frame
    if not SpBuffTrackerEnhancedMainFrame then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: Main frame not found when creating buff frame!|r")
        return nil
    end
    
    local frame = CreateFrame("Button", "SpBuffTrackerEnhancedBuff"..buffIndex, SpBuffTrackerEnhancedMainFrame)
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
    
    -- Create missing indicator (red X overlay)
    frame.missingOverlay = frame:CreateTexture(frame:GetName().."MissingOverlay", "OVERLAY")
    frame.missingOverlay:SetWidth(self.options.buffSize)
    frame.missingOverlay:SetHeight(self.options.buffSize)
    frame.missingOverlay:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.missingOverlay:SetTexture("Interface\\CharacterFrame\\TempPortrait")
    frame.missingOverlay:SetTexCoord(0, 0.5, 0, 0.5) -- Just use a red/orange part of the texture
    frame.missingOverlay:SetBlendMode("ADD")
    frame.missingOverlay:SetAlpha(0.5)
    frame.missingOverlay:Hide() -- Hidden by default
    
    -- Create missing text indicator
    frame.missingText = frame:CreateFontString(frame:GetName().."MissingText", "OVERLAY")
    frame.missingText:SetFont(self.options.fontName, self.options.fontSize - 2, self.options.fontFlags)
    frame.missingText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.missingText:SetText("MISSING")
    frame.missingText:SetTextColor(1, 0, 0)
    frame.missingText:Hide() -- Hidden by default
    
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
            local buffIndex = this:GetID()
            
            -- Check if this is an active buff or missing buff
            if buffIndex <= table.getn(SpBT.buffs) then
                local buff = SpBT.buffs[buffIndex]
                if buff then
                    GameTooltip:AddLine(buff.name)
                    if buff and buff.duration and buff.duration > 0 and buff.timeLeft then
                        GameTooltip:AddLine("Time remaining: " .. SpBT:FormatTime(buff.timeLeft), 1, 1, 1)
                    end
                end
            else
                -- Calculate the missing buff index
                local missingIndex = buffIndex - table.getn(SpBT.buffs)
                local missingBuff = SpBT.missingBuffs[missingIndex]
                
                if missingBuff then
                    GameTooltip:AddLine(missingBuff.name)
                    GameTooltip:AddLine("Status: Missing", 1, 0, 0)
                end
            end
            
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Set up context menu
    frame:RegisterForClicks("RightButtonUp")
    frame:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            local buffIndex = this:GetID()
            
            -- Handle either active or missing buffs
            if buffIndex <= table.getn(SpBT.buffs) then
                local buff = SpBT.buffs[buffIndex]
                if buff then
                    SpBT.trackedBuffs[buff.name] = nil
                    SpBT:SaveVariables()
                    SpBT:UpdateAllBuffs()
                end
            else
                -- Calculate the missing buff index
                local missingIndex = buffIndex - table.getn(SpBT.buffs)
                local missingBuff = SpBT.missingBuffs[missingIndex]
                
                if missingBuff then
                    SpBT.trackedBuffs[missingBuff.name] = nil
                    SpBT:SaveVariables()
                    SpBT:UpdateAllBuffs()
                end
            end
        end
    end)
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Buff frame %d created successfully|r", buffIndex))
    return frame
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
        
        -- Set up simple fade animation using OnUpdate
        frame.fadeTime = 0
        frame.fadeState = 0 -- 0 = fadein, 1 = wait, 2 = fadeout
        frame.fadeTimer = 0
        frame.totalTime = 3.5 -- Total time to show the notification
        
        frame:SetScript("OnUpdate", function()
            local elapsed = arg1
            this.fadeTimer = this.fadeTimer + elapsed
            
            -- Fade in (0.3 seconds)
            if this.fadeState == 0 then
                local alpha = this.fadeTimer / 0.3
                if alpha >= 1.0 then
                    alpha = 1.0
                    this.fadeState = 1
                    this.fadeTimer = 0
                end
                this:SetAlpha(alpha)
            -- Wait (2.5 seconds)
            elseif this.fadeState == 1 then
                if this.fadeTimer >= 2.5 then
                    this.fadeState = 2
                    this.fadeTimer = 0
                end
            -- Fade out (0.7 seconds)
            elseif this.fadeState == 2 then
                local alpha = 1.0 - (this.fadeTimer / 0.7)
                if alpha <= 0 then
                    alpha = 0
                    this:Hide()
                    this.fadeState = 0
                    this.fadeTimer = 0
                end
                this:SetAlpha(alpha)
            end
        end)
        
        self.notificationFrame = frame
        
        -- Try to play a sound if the file exists
        local function PlaySoundSafely(path)
            if DEFAULT_CHAT_FRAME then -- We use this as a simple existence check to avoid errors
                PlaySoundFile(path)
            end
        end
        
        -- PlaySoundSafely("Interface\\AddOns\\SpBuffTrackerEnhanced\\sounds\\buff_gained.ogg")
    end
    
    -- Update notification
    self.notificationFrame.icon:SetTexture(buffIcon)
    self.notificationFrame.text:SetText(buffName)
    
    if duration > 0 then
        self.notificationFrame.duration:SetText("Duration: " .. self:FormatTime(duration))
    else
        self.notificationFrame.duration:SetText("Duration: Indefinite")
    end
    
    -- Reset and show
    self.notificationFrame.fadeState = 0
    self.notificationFrame.fadeTimer = 0
    self.notificationFrame:SetAlpha(0)
    self.notificationFrame:Show()
end

-- Start flash animation on a buff frame
function SpBT:StartFlashAnimation(frame)
    -- Simple flash implementation for Vanilla WoW
    if not frame.flashTimer then
        frame.flashTimer = 0
        frame.flashState = 1
        frame.isFlashing = true
        
        -- Use OnUpdate for animation instead of the Animation API
        frame:SetScript("OnUpdate", function()
            local elapsed = arg1
            this.flashTimer = this.flashTimer + elapsed
            
            if this.flashTimer > 0.5 then
                this.flashTimer = 0
                
                if this.flashState == 1 then
                    this:SetAlpha(0.4)
                    this.flashState = 0
                else
                    this:SetAlpha(1.0)
                    this.flashState = 1
                end
            end
        end)
    end
end

-- Stop flash animation on a buff frame
function SpBT:StopFlashAnimation(frame)
    if frame.isFlashing then
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(1.0)
        frame.isFlashing = false
        frame.flashTimer = nil
        frame.flashState = nil
    end
end