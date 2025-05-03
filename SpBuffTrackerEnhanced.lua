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
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt missing on/off - Toggle showing missing buffs|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt opacity <0.2-1.0> - Set missing buff opacity|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt reset - Reset to defaults|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt timeformat <1/2/3> - Set time format|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt track <buffname> - Track a new buff|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt untrack <buffname> - Remove a tracked buff|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/spbt buffs - Open buff management panel|r")
        return
    end
    
    -- Debug info
    if args[1] == "debug" then
        self:DumpDebugInfo()
        return
    end
    
    -- Scan all player buffs
    if args[1] == "scan" then
        self:ScanAllBuffs()
        return
    end
    
    -- Force a manual update
    if args[1] == "update" then
        self:UpdateAllBuffs()
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
    
    -- Toggle missing buffs
    if args[1] == "missing" and args[2] then
        if args[2] == "on" then
            self.options.showMissingBuffs = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced: Missing buffs will be shown.|r")
        elseif args[2] == "off" then
            self.options.showMissingBuffs = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced: Missing buffs will be hidden.|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid option. Use 'on' or 'off'.|r")
            return
        end
        self:ApplySettings()
        self:SaveVariables()
        return
    end
    
    -- Set missing buff opacity
    if args[1] == "opacity" and args[2] then
        local opacity = tonumber(args[2])
        if opacity and opacity >= 0.2 and opacity <= 1.0 then
            self.options.missingBuffOpacity = opacity
            self:ApplySettings()
            self:SaveVariables()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced missing buff opacity set to " .. opacity .. ".|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Invalid opacity. Use a value between 0.2 and 1.0.|r")
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
        
        -- Initialize the addon
        SpBT:Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Force an update when player enters world
        if SpBT and SpBT.UpdateAllBuffs then
            SpBT:UpdateAllBuffs()
        end
    end
end)--[[
    SpBuffTracker Enhanced
    An improved buff tracking addon for WoW 1.12
    Inspired by https://github.com/Speegel/SpBuffTracker
    Compatible with Lua 5.0
    
    Version: 1.1.0
    Author: Enhanced version of Speegel's original
]]

-- Main addon table
-- Main addon table and globals
SpBuffTrackerEnhanced = {
    version = "1.1.0",
    buffs = {},
    missingBuffs = {}, -- New table to track buffs that are being tracked but missing
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
        showMissingBuffs = true, -- New option to toggle showing missing buffs
        missingBuffOpacity = 0.4, -- Opacity for missing buffs
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
end

-- Create a slash command to dump debug info
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

-- Create a table to map buff textures to names for vanilla WoW
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

-- Reverse map from buff names to textures (for missing buffs)
SpBT.buffNameToTextureMap = {}

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
end

-- Function to get texture from buff name (for missing buffs)
function SpBT:GetTextureFromBuffName(buffName)
    -- Use cached mapping if available
    if self.buffNameToTextureMap[buffName] then
        return self.buffNameToTextureMap[buffName]
    end
    
    -- Otherwise scan the texture map
    for texture, name in pairs(self.buffTextureMap) do
        if name == buffName then
            -- Cache the result for future lookups
            self.buffNameToTextureMap[buffName] = texture
            return texture
        end
    end
    
    -- If not found, return a default texture
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF9900SpBuffTracker Warning: No texture found for buff: %s|r", buffName))
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Create a buff frame - updated to handle missing buff display
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
    
    -- Initialize reverse map from buff names to textures
    self:InitializeBuffNameToTextureMap()
    
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

-- Initialize the buffNameToTextureMap
function SpBT:InitializeBuffNameToTextureMap()
    self.buffNameToTextureMap = {}
    
    -- Walk through the buffTextureMap and build the reverse mapping
    for texture, buffName in pairs(self.buffTextureMap) do
        self.buffNameToTextureMap[buffName] = texture
    end
    
    -- Debug output
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Created reverse buff name to texture map with %d entries|r", 
        self:CountTableEntries(self.buffNameToTextureMap)))
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
    
    -- Apply loaded settings
    self:ApplySettings()
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