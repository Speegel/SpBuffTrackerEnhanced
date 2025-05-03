--[[
    SpBuffTracker Enhanced
    Buff tracking functionality
    Version: 1.1.0
]]

local SpBT = SpBuffTrackerEnhanced

-- Update all player buffs with support for showing missing buffs
function SpBT:UpdateAllBuffs()
    -- Make sure we're using the global reference
    self.trackedBuffs = SpBuffTrackerEnhanced.trackedBuffs
    
    -- Clear current active and missing buffs
    for i = 1, table.getn(self.buffs) do
        self.buffs[i] = nil
    end
    
    for i = 1, table.getn(self.missingBuffs) do
        self.missingBuffs[i] = nil
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900SpBuffTracker: ---- CHECKING PLAYER BUFFS ----")
    
    -- Check if we have trackedBuffs
    if not self.trackedBuffs or type(self.trackedBuffs) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: trackedBuffs is missing or invalid!|r")
        return
    end
    
    -- Create a table to track which buffs we've found
    local foundBuffs = {}
    
    -- Track buffs using vanilla WoW API
    local buffCount = 0
    local activeBuffIndex = 1
    local i = 0
    local buffId = GetPlayerBuff(i, "HELPFUL")
    
    -- Check all player buffs using GetPlayerBuff API
    while buffId >= 0 do
        buffCount = buffCount + 1
        
        -- Try to get the buff texture
        local buffTexture = "Unknown"
        local errorInTexture = false
        
        -- Use pcall to catch any errors
        local success = pcall(function() 
            buffTexture = GetPlayerBuffTexture(buffId)
        end)
        
        if not success then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000SpBuffTracker Error: Failed to get texture for buff ID %d|r", buffId))
            errorInTexture = true
        end
        
        -- Try to get buff time left
        local timeLeft = 0
        local errorInTimeLeft = false
        
        -- Use pcall to catch any errors
        success = pcall(function() 
            timeLeft = GetPlayerBuffTimeLeft(buffId)
        end)
        
        if not success then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000SpBuffTracker Error: Failed to get time left for buff ID %d|r", buffId))
            errorInTimeLeft = true
        end
        
        -- If we got the texture successfully, try to identify the buff
        if not errorInTexture then
            -- Convert texture to buff name
            local buffName = self:GetBuffNameFromTexture(buffTexture)
            
            -- If this buff is being tracked
            if self.trackedBuffs[buffName] then
                -- Add to tracked buffs table
                self.buffs[activeBuffIndex] = {
                    name = buffName,
                    icon = buffTexture,
                    duration = timeLeft,
                    timeLeft = timeLeft,
                    index = i,
                    id = buffId
                }
                
                -- Mark this buff as found
                foundBuffs[buffName] = true
                
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Tracking buff '%s', time left: %.1f|r", buffName, timeLeft))
                activeBuffIndex = activeBuffIndex + 1
            end
        end
        
        -- Move to next buff
        i = i + 1
        buffId = GetPlayerBuff(i, "HELPFUL")
    end
    
    -- Now find any tracked buffs that are missing and add them to missingBuffs
    local missingBuffIndex = 1
    
    if self.options.showMissingBuffs then
        for buffName, isTracked in pairs(self.trackedBuffs) do
            if isTracked and not foundBuffs[buffName] then
                -- Get the texture for this buff
                local buffTexture = self:GetTextureFromBuffName(buffName)
                
                -- Add to missing buffs table
                self.missingBuffs[missingBuffIndex] = {
                    name = buffName,
                    icon = buffTexture,
                    duration = 0,
                    timeLeft = 0,
                    index = -1,
                    id = -1
                }
                
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF6666SpBuffTracker: Missing buff '%s'|r", buffName))
                missingBuffIndex = missingBuffIndex + 1
            end
        end
    end
    
    -- Update status counts
    local statusText = _G["SpBuffTrackerEnhancedFrameStatus"]
    if statusText then
        statusText:SetText(string.format("Active: %d | Missing: %d", activeBuffIndex - 1, missingBuffIndex - 1))
    end
    
    -- Update number of buffs found
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Found %d total buffs, tracking %d active, %d missing|r", 
        buffCount, activeBuffIndex - 1, missingBuffIndex - 1))
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900SpBuffTracker: ---- END OF BUFF CHECK ----")
    
    -- Update the layout
    self:LayoutBuffs()
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
                                -- Try to play a sound if the file exists
                                local function PlaySoundSafely(path)
                                    if DEFAULT_CHAT_FRAME then -- We use this as a simple existence check to avoid errors
                                        PlaySoundFile(path)
                                    end
                                end
                                
                                -- PlaySoundSafely("Interface\\AddOns\\SpBuffTrackerEnhanced\\sounds\\warning.ogg")
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

-- Scan all current buffs and list them (debug function)
function SpBT:ScanAllBuffs()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: ----- SCANNING ALL BUFFS -----")
    
    -- Try direct buff check manually
    local buffCount = 0
    local i = 0
    local buffId = GetPlayerBuff(i, "HELPFUL")
    
    if buffId < 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker: ERROR - No buffs found on player!|r")
    else
        -- List all buffs with textures
        while buffId >= 0 and i < 32 do
            buffCount = buffCount + 1
            
            -- Try to get all information safely
            local buffTexture = "Unknown"
            local textureSuccess, textureError = pcall(function() 
                buffTexture = GetPlayerBuffTexture(buffId) 
            end)
            
            if not textureSuccess then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000SpBuffTracker: Error getting texture: %s|r", tostring(textureError)))
            end
            
            local timeLeft = -1
            local timeSuccess, timeError = pcall(function() 
                timeLeft = GetPlayerBuffTimeLeft(buffId) 
            end)
            
            if not timeSuccess then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000SpBuffTracker: Error getting time: %s|r", tostring(timeError)))
            end
            
            -- Extract the icon name from the texture path
            local iconName = buffTexture
            if type(buffTexture) == "string" then
                iconName = string.gsub(buffTexture, "Interface\\Icons\\", "")
            end
            
            -- Log what we found with the icon name
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00SpBuffTracker: Buff[%d] ID=%d, Icon=%s, Time=%.1f|r", 
                i, buffId, iconName, timeLeft))
            
            -- Check if this matches any known buffs
            local matchedBuff = "Unknown"
            for texture, buffName in pairs(self.buffTextureMap) do
                if texture == buffTexture then
                    matchedBuff = buffName
                    break
                end
            end
            
            -- Log whether this is a known buff
            if matchedBuff ~= "Unknown" then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FFFF  Identified as: %s|r", matchedBuff))
            end
            
            -- Move to next buff
            i = i + 1
            buffId = GetPlayerBuff(i, "HELPFUL")
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00SpBuffTracker: Found %d total buffs|r", buffCount))
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: ----- END BUFF SCAN -----")
    
    return buffCount
end

-- Dump debug info about the addon state
function SpBT:DumpDebugInfo()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: ----- BEGIN DEBUG DUMP -----")
    
    -- Check addon state
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: Version: " .. self.version)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: Frame exists: " .. tostring(self.frame ~= nil))
    
    if self.frame then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: Frame name: " .. tostring(self.frame:GetName()))
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: Frame visible: " .. tostring(self.frame:IsVisible()))
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: Frame dimensions: " .. self.frame:GetWidth() .. "x" .. self.frame:GetHeight())
    end
    
    -- Check trackedBuffs table
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: ----- TRACKED BUFFS -----")
    
    local count = 0
    if self.trackedBuffs then
        for buffName, isTracked in pairs(self.trackedBuffs) do
            count = count + 1
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00SpBuffTracker: Tracking[%d]: %s = %s|r", 
                count, tostring(buffName), tostring(isTracked)))
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker ERROR: trackedBuffs table is nil!")
    end
    
    -- Check currently detected buffs
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: ----- CURRENT BUFFS -----")
    
    local buffCount = 0
    if self.buffs then
        buffCount = table.getn(self.buffs)
        for i = 1, buffCount do
            local buff = self.buffs[i]
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00SpBuffTracker: Current[%d]: %s (%.1f secs)|r", 
                i, buff.name, buff.timeLeft))
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker ERROR: buffs table is nil!")
    end
    
    -- Check missing buffs table
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: ----- MISSING BUFFS -----")
    
    local missingCount = 0
    if self.missingBuffs then
        missingCount = table.getn(self.missingBuffs)
        for i = 1, missingCount do
            local buff = self.missingBuffs[i]
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000SpBuffTracker: Missing[%d]: %s|r", i, buff.name))
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker ERROR: missingBuffs table is nil!")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: ----- END DEBUG DUMP -----")
end