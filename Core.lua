--[[
    SpBuffTracker Enhanced
    Core functionality and initialization
    Version: 1.1.0
]]

-- Main addon table and globals
SpBuffTrackerEnhanced = {
    version = "1.1.0",
    buffs = {},
    missingBuffs = {}, -- Table to track buffs that are being tracked but missing
    frame = nil, -- Will be set during initialization
    options = {
        enabled = true,
        scale = 1.0,
        growUpward = false,
        showTooltips = true,
        showText = true,
        showIcon = true,
        showBorder = true,
        showTimerText = true,
        showMissingBuffs = true, -- Option to toggle showing missing buffs
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
    }
}

local SpBT = SpBuffTrackerEnhanced
local _G = getfenv(0)

-- Initialize addon 
function SpBT:Initialize()
    -- Debug info
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced: Initializing v" .. self.version .. "|r")
    
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
    
    -- Create main frame
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
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SpBuffTracker Enhanced v" .. self.version .. " loaded. Type /spbt for help.|r")
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
end)