--[[
    SpBuffTracker Enhanced
    An improved buff tracking addon for WoW 1.12
    Inspired by https://github.com/Speegel/SpBuffTracker
    Compatible with Lua 5.0
    
    Version: 1.0.0
    Author: Enhanced version of Speegel's original
]]

-- Main addon table
-- Main addon table and globals
SpBuffTrackerEnhanced = {
    version = "1.0.0",
    buffs = {},
    frame = nil, -- We'll set this during initialization
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
        -- Aura
        ["Rejuvenation"] = true,
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

-- Scan all current buffs and list them
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
end-- Create a slash command to dump debug info
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
    
    -- Force a buff check and log everything
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: ----- BUFF API CHECK -----")
    
    -- Use pcall to ensure errors don't break the debug
    local success, errorMsg = pcall(function()
        -- Try direct buff check manually
        local buffCount = 0
        local i = 0
        local buffId = GetPlayerBuff(i, "HELPFUL")
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: GetPlayerBuff(0) = " .. tostring(buffId))
        
        if buffId < 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker: ERROR - GetPlayerBuff API is not returning any buffs!")
        else
            while buffId >= 0 and i < 32 do
                buffCount = buffCount + 1
                
                -- Try to get all information safely
                local buffTexture = "Unknown"
                local textureSuccess = pcall(function() 
                    buffTexture = GetPlayerBuffTexture(buffId) 
                end)
                
                local timeLeft = -1
                local timeSuccess = pcall(function() 
                    timeLeft = GetPlayerBuffTimeLeft(buffId) 
                end)
                
                -- Log what we found
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00SpBuffTracker: Buff[%d] = ID: %d, Texture: %s, Time: %.1f|r", 
                    i, buffId, tostring(buffTexture), timeLeft))
                
                -- Move to next buff
                i = i + 1
                buffId = GetPlayerBuff(i, "HELPFUL")
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: Found " .. buffCount .. " buffs total")
        end
    end)
    
    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker ERROR in debug: " .. tostring(errorMsg))
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
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker: ----- END DEBUG DUMP -----")
end-- Create a table to map buff textures to names for vanilla WoW
SpBT.buffTextureMap = {
    -- World buffs
    ["Interface\\Icons\\Spell_Shadow_Charm"] = "Rallying Cry of the Dragonslayer",
    ["Interface\\Icons\\Ability_Creature_Cursed_04"] = "Spirit of Zandalar",
    ["Interface\\Icons\\Spell_Holy_MagicalSentry"] = "Songflower Serenade",
    ["Interface\\Icons\\Spell_Nature_Regeneration"] = "Warchief's Blessing",
    ["Interface\\Icons\\Spell_Holy_FlashHeal"] = "Slip'kik's Savvy",
    ["Interface\\Icons\\Ability_Warrior_InnerRage"] = "Fengus' Ferocity",
    ["Interface\\Icons\\Ability_Warrior_OffensiveStance"] = "Mol'dar's Moxie",
    ["Interface\\Icons\\Spell_Holy_InnerFire"] = "Fire Festival Fortitude",
    ["Interface\\Icons\\Spell_Fire_Immolation"] = "Fire Festival Fury",
    
    -- Consumables
    ["Interface\\Icons\\INV_Potion_12"] = "Elixir of the Mongoose",
    ["Interface\\Icons\\INV_Potion_61"] = "Elixir of Giants",
    ["Interface\\Icons\\INV_Potion_09"] = "Elixir of Greater Agility",
    ["Interface\\Icons\\INV_Potion_10"] = "Elixir of Greater Intellect",
    ["Interface\\Icons\\INV_Potion_25"] = "Greater Arcane Elixir",
    ["Interface\\Icons\\INV_Potion_21"] = "Elixir of Greater Firepower",
    ["Interface\\Icons\\INV_Potion_41"] = "Flask of Supreme Power",
    ["Interface\\Icons\\INV_Potion_62"] = "Flask of the Titans",
    ["Interface\\Icons\\INV_Potion_97"] = "Flask of Distilled Wisdom",
    ["Interface\\Icons\\INV_Potion_45"] = "Mageblood Potion",
    ["Interface\\Icons\\INV_Misc_Food_19"] = "Blessed Sunfruit",
    ["Interface\\Icons\\INV_Misc_Food_63"] = "Smoked Desert Dumplings",
    ["Interface\\Icons\\INV_Misc_Fish_13"] = "Grilled Squid",
    ["Interface\\Icons\\INV_Drink_07"] = "Nightfin Soup",
    ["Interface\\Icons\\INV_Misc_Food_15"] = "Dire Maul Tribute",
    
    -- Class buffs
    ["Interface\\Icons\\Spell_Holy_WordFortitude"] = "Power Word: Fortitude",
    ["Interface\\Icons\\Spell_Holy_PrayerOfSpirit"] = "Prayer of Spirit",
    ["Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"] = "Blessing of Kings",
    ["Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom"] = "Blessing of Wisdom",
    ["Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation"] = "Blessing of Salvation",
    ["Interface\\Icons\\Spell_Magic_GreaterBlessingofLight"] = "Blessing of Light",
    ["Interface\\Icons\\Spell_Holy_GreaterBlessingofMight"] = "Blessing of Might",
    ["Interface\\Icons\\Spell_Magic_GreaterBlessingofSanctuary"] = "Blessing of Sanctuary",
    ["Interface\\Icons\\Spell_Nature_Regeneration"] = "Rejuvenation",
    ["Interface\\Icons\\Spell_Nature_ResistNature"] = "Mark of the Wild",
    ["Interface\\Icons\\Spell_Nature_Bloodlust"] = "Bloodlust",
    ["Interface\\Icons\\Spell_Shadow_DetectLesserInvisibility"] = "Arcane Intellect",
    
    -- Add more mappings as needed
}

-- Function to get buff name from texture with better debugging
function SpBT:GetBuffNameFromTexture(texture)
    -- Log the texture we're trying to match
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFBBBBFFSpBuffTracker Debug: Looking up texture: %s|r", tostring(texture)))
    
    -- Check if this is a known texture in our mapping
    if self.buffTextureMap[texture] then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFBBBBFFSpBuffTracker Debug: Found matching name: %s|r", self.buffTextureMap[texture]))
        return self.buffTextureMap[texture]
    else
        -- Not in mapping, return a shortened version of the texture path
        local shortTexture = "Unknown"
        
        if texture and type(texture) == "string" then
            -- Try to extract icon name from path
            shortTexture = string.gsub(texture, "Interface\\Icons\\", "")
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF9900SpBuffTracker Warning: Texture not in mapping: %s (using %s)|r", texture, shortTexture))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: Invalid texture value!|r")
        end
        
        return shortTexture
    end
end-- Create a buff frame
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
                if buff and buff.duration and buff.duration > 0 and buff.timeLeft then
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
                SpBuffTrackerEnhanced.trackedBuffs[buff.name] = nil
                SpBT:SaveVariables()
                SpBT:UpdateAllBuffs()
            end
        end
    end)
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Buff frame %d created successfully|r", buffIndex))
    return frame
end-- Save variables to disk
function SpBT:SaveVariables()
    -- Make sure the DB exists
    if not SpBuffTrackerEnhancedDB then
        SpBuffTrackerEnhancedDB = {}
    end
    
    -- Copy options (excluding trackedBuffs)
    for k, v in pairs(self.options) do
        if k ~= "trackedBuffs" then
            SpBuffTrackerEnhancedDB[k] = v
        end
    end
    
    -- Make sure we're using the global trackedBuffs reference
    self.trackedBuffs = SpBuffTrackerEnhanced.trackedBuffs
    
    -- Create a fresh trackedBuffs table
    SpBuffTrackerEnhancedDB.trackedBuffs = {}
    
    -- Only copy buffs that are actually tracked (value is true)
    local count = 0
    if SpBuffTrackerEnhanced.trackedBuffs then
        for buffName, isTracked in pairs(SpBuffTrackerEnhanced.trackedBuffs) do
            if isTracked then
                SpBuffTrackerEnhancedDB.trackedBuffs[buffName] = true
                count = count + 1
            end
        end
    end
    
    -- Print debug for troubleshooting
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF77CCFFSpBuffTracker: Saved %d tracked buffs to database|r", count))
    
    -- Log each buff we're saving
    if count > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF77CCFFSpBuffTracker: Saved buffs:|r")
        for buffName, _ in pairs(SpBuffTrackerEnhancedDB.trackedBuffs) do
            DEFAULT_CHAT_FRAME:AddMessage("  - " .. buffName)
        end
    end
end

-- Initialize addon - simplified for stability
function SpBT:Initialize()
    -- Debug info
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced: Initializing with simplified approach for stability|r")
    
    -- CRITICAL: Ensure we're using the global trackedBuffs reference
    if not SpBuffTrackerEnhanced.trackedBuffs then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: Global trackedBuffs is nil!|r")
        SpBuffTrackerEnhanced.trackedBuffs = {}
    end
    
    -- Assign the global reference to our local table
    self.trackedBuffs = SpBuffTrackerEnhanced.trackedBuffs
    
    -- Debug output for trackedBuffs
    local count = 0
    for buffName, _ in pairs(self.trackedBuffs) do
        count = count + 1
    end
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Initialized with %d tracked buffs|r", count))
    
    -- Create main frame - this is the most critical part
    self:CreateMainFrame()
    
    -- Only register a few essential events to avoid complexity
    if self.frame then
        self.frame:RegisterEvent("PLAYER_AURAS_CHANGED")
        self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: Cannot register events - frame is nil!|r")
    end
    
    -- Set up slash commands
    SLASH_SPBUFFTRACKER1 = "/spbt"
    SLASH_SPBUFFTRACKER2 = "/spbufftracker"
    SlashCmdList["SPBUFFTRACKER"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    -- Print startup message
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced v" .. self.version .. " loaded. Type /spbt for options.|r")
end

-- Load saved variables from disk
function SpBT:LoadVariables()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF77CCFFSpBuffTracker: Loading saved variables...|r")
    
    -- CRITICAL: Make sure we keep the reference to the global trackedBuffs
    DEFAULT_CHAT_FRAME:AddMessage("|cFF77CCFFSpBuffTracker: Preserving trackedBuffs reference...|r")
    
    -- Load options from saved variables
    if SpBuffTrackerEnhancedDB then
        for k, v in pairs(SpBuffTrackerEnhancedDB) do
            if k ~= "trackedBuffs" and self.options[k] ~= nil then
                self.options[k] = v
            end
        end
    else
        -- Initialize database if it doesn't exist
        SpBuffTrackerEnhancedDB = {}
        for k, v in pairs(self.options) do
            if k ~= "trackedBuffs" then
                SpBuffTrackerEnhancedDB[k] = v
            end
        end
    end
    
    -- Apply loaded settings
    self:ApplySettings()
    
    -- Let's dump the trackedBuffs to chat to debug
    DEFAULT_CHAT_FRAME:AddMessage("|cFF66FFFFSpBuffTracker Debug: Tracked buffs after loading:|r")
    for buffName, _ in pairs(self.trackedBuffs) do
        DEFAULT_CHAT_FRAME:AddMessage("  - " .. buffName)
    end
    SpBuffTrackerEnhancedDB.trackedBuffs = {}
        for buffName, isTracked in pairs(self.trackedBuffs) do
            SpBuffTrackerEnhancedDB.trackedBuffs[buffName] = isTracked
        end
    -- end
    
    -- Apply loaded settings
    self:ApplySettings()
end

-- Save variables to disk
function SpBT:SaveVariables()
    -- Make sure the DB exists
    if not SpBuffTrackerEnhancedDB then
        SpBuffTrackerEnhancedDB = {}
    end
    
    -- Copy options (excluding trackedBuffs)
    for k, v in pairs(self.options) do
        if k ~= "trackedBuffs" then
            SpBuffTrackerEnhancedDB[k] = v
        end
    end
    
    -- Make sure we're using the global trackedBuffs reference
    self.trackedBuffs = SpBuffTrackerEnhanced.trackedBuffs
    
    -- Create a fresh trackedBuffs table
    SpBuffTrackerEnhancedDB.trackedBuffs = {}
    
    -- Only copy buffs that are actually tracked (value is true)
    local count = 0
    if SpBuffTrackerEnhanced.trackedBuffs then
        for buffName, isTracked in pairs(SpBuffTrackerEnhanced.trackedBuffs) do
            if isTracked then
                SpBuffTrackerEnhancedDB.trackedBuffs[buffName] = true
                count = count + 1
            end
        end
    end
    
    -- Print debug for troubleshooting
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF77CCFFSpBuffTracker: Saved %d tracked buffs to database|r", count))
    
    -- Log each buff we're saving
    if count > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF77CCFFSpBuffTracker: Saved buffs:|r")
        for buffName, _ in pairs(SpBuffTrackerEnhancedDB.trackedBuffs) do
            DEFAULT_CHAT_FRAME:AddMessage("  - " .. buffName)
        end
    end
end

-- Count entries in a table (helper function)
function SpBT:CountTableEntries(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Apply current settings
function SpBT:ApplySettings()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Applying settings|r")
    
    -- Make sure we have the correct frame reference
    if not SpBuffTrackerEnhancedMainFrame then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: Cannot apply settings - global main frame is nil!|r")
        return
    end
    
    -- Update our local reference just to be safe
    self.frame = SpBuffTrackerEnhancedMainFrame
    
    -- Apply scale
    SpBuffTrackerEnhancedMainFrame:SetScale(self.options.scale)
    
    -- Apply position
    SpBuffTrackerEnhancedMainFrame:ClearAllPoints()
    
    -- Safety check for relativeTo
    local relativeTo = _G[self.options.position.relativeTo]
    if not relativeTo then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900SpBuffTracker Warning: Invalid relativeTo frame, using UIParent|r")
        relativeTo = UIParent
    end
    
    -- Set the position
    SpBuffTrackerEnhancedMainFrame:SetPoint(
        self.options.position.point,
        relativeTo,
        self.options.position.relativePoint,
        self.options.position.x,
        self.options.position.y
    )
    
    -- Apply visibility
    if self.options.enabled then
        SpBuffTrackerEnhancedMainFrame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Frame shown (enabled=true)|r")
    else
        SpBuffTrackerEnhancedMainFrame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Frame hidden (enabled=false)|r")
    end
    
    -- Refresh buff display
    self:UpdateAllBuffs()
    self:LayoutBuffs()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Settings applied successfully|r")
end

-- Create the main frame
function SpBT:CreateMainFrame()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Creating main frame|r")
    
    -- Create a global reference to the frame first - using fixed standard naming
    local mainFrame = CreateFrame("Frame", "SpBuffTrackerEnhancedFrame", UIParent)
    
    -- Set up the frame - use minimal settings to avoid crashes
    mainFrame:SetWidth(100)
    mainFrame:SetHeight(50)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    
    -- Create a simple background to make it visible
    local bg = mainFrame:CreateTexture("SpBuffTrackerEnhancedFrameBG", "BACKGROUND")
    bg:SetTexture(0, 0, 0, 0.5) -- Semi-transparent black
    bg:SetAllPoints(mainFrame)
    
    -- Create a title text to identify the frame
    local titleText = mainFrame:CreateFontString("SpBuffTrackerEnhancedFrameTitle", "OVERLAY", "GameFontNormal")
    titleText:SetPoint("CENTER", mainFrame, "CENTER", 0, 0)
    titleText:SetText("SpBuffTracker")
    
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
        -- Don't try to save position yet - just stop movement
    end)
    
    -- Set up very basic event handling for now
    mainFrame:SetScript("OnEvent", function()
        if event == "PLAYER_AURAS_CHANGED" or (event == "UNIT_AURA" and arg1 == "player") then
            -- Just call UpdateAllBuffs, nothing else
            SpBT:UpdateAllBuffs()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Buff change detected|r")
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
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Simple main frame created successfully|r")
    return mainFrame
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
                if buff and buff.duration and buff.duration > 0 and buff.timeLeft then
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

-- Update all player buffs - with better debugging for vanilla WoW 1.12 API
function SpBT:UpdateAllBuffs()
    -- Make sure we're using the global reference
    self.trackedBuffs = SpBuffTrackerEnhanced.trackedBuffs
    
    -- Clear current buffs
    for i = 1, table.getn(self.buffs) do
        self.buffs[i] = nil
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900SpBuffTracker: ---- CHECKING PLAYER BUFFS ----")
    
    -- Check if we have trackedBuffs
    if not self.trackedBuffs or type(self.trackedBuffs) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: trackedBuffs is missing or invalid!|r")
        return
    end
    
    -- DEBUG: Print all tracked buffs we're looking for
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9999FFSpBuffTracker Debug: Tracked buff names:|r")
    for buffName, _ in pairs(self.trackedBuffs) do
        DEFAULT_CHAT_FRAME:AddMessage("  - " .. buffName)
    end
    
    -- SUPER VERBOSE DEBUG LOGGING
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9999FFSpBuffTracker Debug: Starting buff scan using GetPlayerBuff API|r")
    
    -- Track buffs using vanilla WoW API with verbose logging
    local buffCount = 0
    local buffIndex = 1
    local i = 0
    local buffId = GetPlayerBuff(i, "HELPFUL")
    
    -- Log debug info about first buffId
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF9999FFSpBuffTracker Debug: First GetPlayerBuff returned ID: %d|r", buffId))
    
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
        
        -- Debug info for each buff
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF9999FFSpBuffTracker Debug: Found buff %d: ID=%d, Texture=%s, TimeLeft=%.1f|r", 
            buffCount, buffId, tostring(buffTexture), timeLeft))
        
        -- If we got the texture successfully, try to identify the buff
        if not errorInTexture then
            -- Convert texture to buff name
            local buffName = self:GetBuffNameFromTexture(buffTexture)
            
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF9999FFSpBuffTracker Debug:   Identified as: %s|r", buffName))
            
            -- If this buff is being tracked
            if self.trackedBuffs[buffName] then
                -- Add to tracked buffs table
                self.buffs[buffIndex] = {
                    name = buffName,
                    icon = buffTexture,
                    duration = timeLeft,
                    timeLeft = timeLeft,
                    index = i,
                    id = buffId
                }
                
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Tracking buff '%s', time left: %.1f|r", buffName, timeLeft))
                buffIndex = buffIndex + 1
            end
        end
        
        -- Move to next buff
        i = i + 1
        buffId = GetPlayerBuff(i, "HELPFUL")
    end
    
    -- Update number of buffs found
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Found %d total buffs, tracking %d|r", buffCount, buffIndex - 1))
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900SpBuffTracker: ---- END OF BUFF CHECK ----")
    
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

-- Format time based on user preference
function SpBT:FormatTime(timeInSeconds)
    if timeInSeconds <= 0 then return "0" end
    
    -- Format: MM:SS
    if self.options.timeFormat == 1 then
        local minutes = math.floor(timeInSeconds / 60)
        local seconds = math.floor(timeInSeconds - (minutes * 60))
        return format("%02d:%02d", minutes, seconds)
    
    -- Format: M:SS
    elseif self.options.timeFormat == 2 then
        local minutes = math.floor(timeInSeconds / 60)
        local seconds = math.floor(timeInSeconds - (minutes * 60))
        return format("%d:%02d", minutes, seconds)
    
    -- Format: Seconds only
    else
        if timeInSeconds >= 60 then
            return format("%.0fm", timeInSeconds / 60)
        else
            return format("%.0f", timeInSeconds)
        end
    end
end

-- Layout buff frames - improved simple version with better debugging
function SpBT:LayoutBuffs()
    -- Get number of buffs
    local buffCount = 0
    if self.buffs then
        buffCount = table.getn(self.buffs)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Laying out %d buffs|r", buffCount))
    
    -- Safety check for main frame
    if not self.frame then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: No main frame available!|r")
        return
    end
    
    -- Don't try to layout if there are no buffs
    if buffCount == 0 then
        -- Update the main frame text to show status
        local title = _G["SpBuffTrackerEnhancedFrameTitle"]
        if title then
            title:SetText("SpBuffTracker - No Buffs")
        end
        
        -- Make sure the main frame is big enough to see
        self.frame:SetHeight(50)
        self.frame:SetWidth(160)
        return
    end
    
    -- Update the main frame text 
    local title = _G["SpBuffTrackerEnhancedFrameTitle"]
    if title then
        title:SetText("SpBuffTracker - " .. buffCount .. " Buffs")
    end
    
    -- Calculate required frame size
    local frameHeight = 20 + (buffCount * 20) -- Title + 20px per buff
    local frameWidth = 200 -- Fixed width
    
    -- Resize the main frame
    self.frame:SetHeight(frameHeight)
    self.frame:SetWidth(frameWidth)
    
    -- Debug buff contents
    DEFAULT_CHAT_FRAME:AddMessage("|cFF66CCFFSpBuffTracker: Buff content being laid out:|r")
    
    -- Create or update buff text lines
    for i = 1, buffCount do
        local buff = self.buffs[i]
        
        -- Debug info for each buff we're laying out
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker:   Buff %d: %s (%.1f sec)|r", 
            i, buff.name, buff.timeLeft))
        
        local textName = "SpBuffTrackerEnhancedBuffText" .. i
        
        -- Create or get text frame
        local textFrame = _G[textName]
        if not textFrame then
            textFrame = self.frame:CreateFontString(textName, "OVERLAY", "GameFontHighlight")
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Created text frame %d|r", i))
        end
        
        -- Position text
        textFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -(20 + (i-1) * 20))
        
        -- Format text with buff info
        local timeStr = "∞"
        if buff.timeLeft and buff.timeLeft > 0 then
            timeStr = self:FormatTime(buff.timeLeft)
        end
        
        -- Update text
        textFrame:SetText(string.format("%s: %s", buff.name, timeStr))
        textFrame:Show()
    end
    
    -- Hide any unused text frames
    for i = buffCount + 1, 32 do
        local textFrame = _G["SpBuffTrackerEnhancedBuffText" .. i]
        if textFrame then
            textFrame:Hide()
        end
    end
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
    content:SetWidth(scrollFrame:GetWidth())
    content:SetHeight(500) -- Height will adjust as needed
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
        -- SetObeyStepOnDrag doesn't exist in WoW 1.12, removed
        slider:SetValue(SpBT.options[key])
        
        getglobal(slider:GetName() .. "Low"):SetText(min)
        getglobal(slider:GetName() .. "High"):SetText(max)
        getglobal(slider:GetName() .. "Text"):SetText(slider:GetValue())
        
        slider:SetScript("OnValueChanged", function()
            local val = math.floor(this:GetValue() * 100) / 100 -- Round to 2 decimal places
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
        -- Debug
        DEFAULT_CHAT_FRAME:AddMessage("|cFFBBBBFFSpBuffTracker: Creating buff management panel|r")
        
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
        scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -40, 70)
        
        local content = CreateFrame("Frame", "SpBuffTrackerEnhancedBuffScrollContent", scroll)
        content:SetWidth(scroll:GetWidth())
        content:SetHeight(500) -- Will adjust dynamically
        scroll:SetScrollChild(content)
        
        -- Description text
        local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        desc:SetPoint("BOTTOM", panel, "BOTTOM", 0, 60)
        desc:SetText("Add a new buff to track:")
        
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
                -- Add to tracked buffs using the global reference
                DEFAULT_CHAT_FRAME:AddMessage("|cFF77FFAASpBuffTracker: Adding '" .. buffName .. "' to tracked buffs|r")
                
                -- Make sure we're using the global table
                SpBuffTrackerEnhanced.trackedBuffs[buffName] = true
                
                -- Update our local reference
                SpBT.trackedBuffs = SpBuffTrackerEnhanced.trackedBuffs
                
                -- Save changes
                SpBT:SaveVariables()
                
                -- Update display
                SpBT:UpdateAllBuffs()
                SpBT:UpdateBuffManagementPanel()
                
                -- Clear the input box
                addBuffBox:SetText("")
                addBuffBox:ClearFocus()
            end
        end)
        
        -- Reset defaults button
        local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        resetButton:SetPoint("BOTTOM", panel, "BOTTOM", 0, 38)
        resetButton:SetWidth(150)
        resetButton:SetHeight(22)
        resetButton:SetText("Restore Default Buffs")
        resetButton:SetScript("OnClick", function()
            -- Confirm with the user
            StaticPopupDialogs["SPBUFFTRACKER_RESTORE_DEFAULTS"] = {
                text = "Restore default buff list? This will remove any custom buffs you've added.",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900SpBuffTracker: User confirmed restore defaults|r")
                    SpBT:RestoreDefaultBuffs()
                    
                    -- Make sure the updates are reflected in the panel
                    SpBT:UpdateBuffManagementPanel()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("SPBUFFTRACKER_RESTORE_DEFAULTS")
        end)
        
        -- Handle Enter key in text box
        addBuffBox:SetScript("OnEnterPressed", function()
            addBuffButton:Click()
        end)
        
        -- Handle Escape key in text box
        addBuffBox:SetScript("OnEscapePressed", function()
            this:SetText("")
            this:ClearFocus()
        end)
        
        -- Current buff list label
        local listLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        listLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 25, -25)
        listLabel:SetText("Currently Tracked Buffs:")
        
        -- Store references
        panel.content = content
        self.buffPanel = panel
        
        -- Set up a script to run when the panel becomes visible
        panel:SetScript("OnShow", function()
            -- This ensures the buff list is fresh every time the panel is shown
            SpBT:UpdateBuffManagementPanel()
            DEFAULT_CHAT_FRAME:AddMessage("|cFFBBBBFFSpBuffTracker: Buff panel shown, updating content|r")
        end)
    end
    
    -- Update buff list
    self:UpdateBuffManagementPanel()
    
    -- Force a refresh to make absolutely sure we're showing the latest data
    SpBuffTrackerEnhanced.trackedBuffs = SpBuffTrackerEnhanced.trackedBuffs or {}
    self.trackedBuffs = SpBuffTrackerEnhanced.trackedBuffs
    
    -- Show panel
    self.buffPanel:Show()
end

-- Update buff management panel content
function SpBT:UpdateBuffManagementPanel()
    if not self.buffPanel then return end
    
    local content = self.buffPanel.content
    
    -- Debug - show what we're working with
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00SpBuffTracker Debug: Updating buff management panel|r")
    
    -- Clear existing content
    content:SetHeight(500) -- Reset height
    local children = {content:GetChildren()}
    for _, child in pairs(children) do
        child:Hide()
    end
    
    -- Check if the global trackedBuffs exists and has entries
    if not self.trackedBuffs or type(self.trackedBuffs) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: trackedBuffs is missing or not a table!|r")
        return
    end
    
    -- Add buff entries
    local y = 0
    local count = 0
    
    -- Print debugging info
    DEFAULT_CHAT_FRAME:AddMessage("|cFFBBBBBBSpBuffTracker Debug: Raw entries in trackedBuffs:|r")
    for buffName, isTracked in pairs(self.trackedBuffs) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  '%s' = %s", buffName, tostring(isTracked)))
    end
    
    -- Create sorted list for display
    local buffNames = {}
    for buffName, isTracked in pairs(self.trackedBuffs) do
        if isTracked then
            table.insert(buffNames, buffName)
        end
    end
    table.sort(buffNames)
    
    -- Display debug info
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFBBBBBBSpBuffTracker Debug: Found %d buffs to display|r", table.getn(buffNames)))
    
    -- Create a frame for each tracked buff
    for i, buffName in ipairs(buffNames) do
        count = count + 1
        
        local frame = CreateFrame("Frame", "SpBuffTrackerEnhancedBuffEntry"..count, content)
        frame:SetWidth(content:GetWidth() - 20)
        frame:SetHeight(24)
        frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        
        -- Create background for hover effect
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(frame)
        bg:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
        bg:SetBlendMode("ADD")
        bg:SetAlpha(0)
        
        frame:SetScript("OnEnter", function() this.bg:SetAlpha(0.3) end)
        frame:SetScript("OnLeave", function() this.bg:SetAlpha(0) end)
        frame.bg = bg
        
        -- Buff name
        local name = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        name:SetPoint("LEFT", frame, "LEFT", 5, 0)
        name:SetText(buffName)
        name:SetWidth(frame:GetWidth() - 30)
        name:SetJustifyH("LEFT")
        
        -- Remove button
        local remove = CreateFrame("Button", "SpBuffTrackerEnhancedBuffEntryRemove"..count, frame)
        remove:SetWidth(16)
        remove:SetHeight(16)
        remove:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        remove:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
        remove:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
        remove:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        
        -- Store the current buff name directly in a local variable
        local currentBuffName = buffName
        remove:SetScript("OnClick", function()
            -- Note the exact buff name in the debug log
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9977SpBuffTracker: Removing buff: '" .. currentBuffName .. "'|r")
            
            -- Remove the buff
            SpBuffTrackerEnhanced.trackedBuffs[currentBuffName] = nil
            
            -- Save changes
            SpBT:SaveVariables()
            
            -- Update display
            SpBT:UpdateAllBuffs()
            SpBT:UpdateBuffManagementPanel()
        end)
        
        y = y - 24
    end
    
    -- If no buffs are being tracked, show a message
    if count == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9977SpBuffTracker Debug: No buffs to display, showing empty message|r")
        
        local noBuffs = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        noBuffs:SetPoint("TOP", content, "TOP", 0, -30)
        noBuffs:SetText("No buffs are currently being tracked.\nAdd buffs using the box below or click 'Restore Default Buffs'.")
        noBuffs:SetJustifyH("CENTER")
    end
    
    -- Adjust content height
    content:SetHeight(math.max(math.abs(y), 200))
    
    -- Make sure content is visible
    content:Show()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF77CCFFSpBuffTracker Debug: Created " .. count .. " buff entries in the panel|r")
end

-- Restore default buffs
function SpBT:RestoreDefaultBuffs()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced: Restoring default tracked buffs...|r")
    
    -- Clear existing trackedBuffs
    SpBuffTrackerEnhanced.trackedBuffs = {}
    
    -- Add default buffs to global table
    local defaultBuffs = {
        -- World buffs
        "Rallying Cry of the Dragonslayer",
        "Spirit of Zandalar",
        "Songflower Serenade",
        "Warchief's Blessing",
        "Slip'kik's Savvy",
        "Fengus' Ferocity",
        "Mol'dar's Moxie",
        "Fire Festival Fortitude",
        "Fire Festival Fury",
        -- Consumables
        "Elixir of the Mongoose",
        "Elixir of Giants",
        "Elixir of Greater Agility",
        "Elixir of Greater Intellect",
        "Greater Arcane Elixir",
        "Elixir of Greater Firepower",
        "Flask of Supreme Power",
        "Flask of the Titans",
        "Flask of Distilled Wisdom",
        "Mageblood Potion",
        "Blessed Sunfruit",
        "Smoked Desert Dumplings",
        "Grilled Squid",
        "Nightfin Soup",
        "Dire Maul Tribute",
    }
    
    -- Add each buff individually and log it
    for _, buffName in ipairs(defaultBuffs) do
        DEFAULT_CHAT_FRAME:AddMessage("|cFF77FFAASpBuffTracker: Adding default buff: " .. buffName .. "|r")
        SpBuffTrackerEnhanced.trackedBuffs[buffName] = true
    end
    
    -- Update our local reference
    self.trackedBuffs = SpBuffTrackerEnhanced.trackedBuffs
    
    -- Save to DB
    self:SaveVariables()
    
    -- Update tracking
    self:UpdateAllBuffs()
end

-- Handle slash commands
function SpBT:HandleSlashCommand(msg)
    msg = string.lower(msg or "")
    local args = {}
    for arg in string.gfind(msg, "%S+") do
        table.insert(args, arg)
    end
    
    -- Help / no command
    if not args[1] or args[1] == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00SpBuffTracker Enhanced Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt - Show this help|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt show - Show the addon frame|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt hide - Hide the addon frame|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt update - Force update buff tracking|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt debug - Show detailed debug information|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt scan - Scan and list all player buffs|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt reset - Reset to defaults|r")
    --     return
    -- end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt timeformat <1/2/3> - Set time format|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt track <buffname> - Track a new buff|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt untrack <buffname> - Remove a tracked buff|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt buffs - Open buff management panel|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt show - Show the addon frame|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt hide - Hide the addon frame|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt reset - Reset to defaults|r")
        return
    end
    
    -- Show frame
    if args[1] == "show" then
        if self.frame then
            self.frame:Show()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced frame shown.|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: Frame is nil!|r")
        end
        return
    end
    
    -- Hide frame
    if args[1] == "hide" then
        if self.frame then
            self.frame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Enhanced frame hidden.|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: Frame is nil!|r")
        end
        return
    end
    
    -- Open config
    if args[1] == "config" then
        -- Check if interface options panel exists (only in TBC+)
        if InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory("SpBuffTracker Enhanced")
        else
            -- For vanilla, create a standalone config window
            self:CreateBuffManagementPanel()
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00SpBuffTracker Enhanced: Use /spbt buffs for configuration in vanilla WoW.|r")
        end
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
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00SpBuffTracker: Toggle command received - enabled = " .. tostring(self.options.enabled) .. "|r")
        
        if self.options.enabled then
            if self.frame then
                self.frame:Show()
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced enabled - frame shown.|r")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: Frame is nil!|r")
            end
        else
            if self.frame then
                self.frame:Hide()
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Enhanced disabled - frame hidden.|r")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: Frame is nil!|r")
            end
        end
        
        -- Save the enabled setting
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
local loadingFrame = CreateFrame("Frame")
loadingFrame:RegisterEvent("ADDON_LOADED")
loadingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadingFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "SpBuffTrackerEnhanced" then
        -- Print debug message
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced: Addon loading...|r")
        
        -- FORCE SET DEFAULT TRACKED BUFFS REGARDLESS OF SAVED VARIABLES
        -- Let's fix this once and for all
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900SpBuffTracker Enhanced: FORCING default tracked buffs...|r")
        SpBuffTrackerEnhanced.trackedBuffs = {
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
            -- Class buffs for testing
            ["Power Word: Fortitude"] = true,
            ["Prayer of Spirit"] = true,
            ["Blessing of Kings"] = true,
            ["Blessing of Wisdom"] = true,
            ["Mark of the Wild"] = true,
            ["Arcane Intellect"] = true,
        }
        
        -- Directly create/update the saved variable to match
        if not SpBuffTrackerEnhancedDB then
            SpBuffTrackerEnhancedDB = {}
        end
        SpBuffTrackerEnhancedDB.trackedBuffs = {}
        for buffName, _ in pairs(SpBuffTrackerEnhanced.trackedBuffs) do
            SpBuffTrackerEnhancedDB.trackedBuffs[buffName] = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFFAA66FFSpBuffTracker: Added default buff: " .. buffName .. "|r")
        end
        
        -- Count how many tracked buffs we have
        local count = 0
        for _ in pairs(SpBuffTrackerEnhanced.trackedBuffs) do
            count = count + 1
        end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00SpBuffTracker Enhanced: Set %d tracked buffs|r", count))
        
        -- Initialize the addon
        SpBT:Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Force an update when player enters world
        if SpBT and SpBT.UpdateAllBuffs then
            SpBT:UpdateAllBuffs()
        end
--     end
-- end)
-- end)end
--         end)
        
        -- Add info about the main frame status
        -- debugFrame:SetScript("OnUpdate", function()
        --     local status = "Unknown"
        --     local color = "|cFFFFFFFF"
            
        --     if SpBuffTrackerEnhancedMainFrame then
        --         if SpBuffTrackerEnhancedMainFrame:IsVisible() then
        --             status = "Visible"
        --             color = "|cFF00FF00"
        --         else
        --             status = "Hidden"
        --             color = "|cFFFF0000"
        --         end
        --     else
        --         status = "Not Found"
        --         color = "|cFFFF00FF"
        --     end
            
        --     text:SetText("SpBuffTracker Debug\nClick to toggle main frame\nStatus: " .. color .. status .. "|r")
        -- end)
        
        -- -- Show the debug frame
        -- debugFrame:Show()
    end
end)