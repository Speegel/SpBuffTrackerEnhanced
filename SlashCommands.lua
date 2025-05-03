--[[
    SpBuffTracker Enhanced
    Slash commands handling
    Version: 1.1.0
]]

local SpBT = SpBuffTrackerEnhanced

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