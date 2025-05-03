--[[
    SpBuffTracker Enhanced
    Utility functions
    Version: 1.1.0
]]

local SpBT = SpBuffTrackerEnhanced

-- Count entries in a table (helper function)
function SpBT:CountTableEntries(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
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