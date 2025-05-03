--[[
    SpBuffTracker Enhanced
    Layout and display functionality
    Version: 1.1.0
]]

local SpBT = SpBuffTrackerEnhanced

-- Layout buff frames with support for active and missing buffs
function SpBT:LayoutBuffs()
    -- Get number of active and missing buffs
    local activeBuffCount = 0
    local missingBuffCount = 0
    
    if self.buffs then
        activeBuffCount = table.getn(self.buffs)
    end
    
    if self.missingBuffs then
        missingBuffCount = table.getn(self.missingBuffs)
    end
    
    local totalCount = activeBuffCount + missingBuffCount
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF66CCFFSpBuffTracker: Laying out %d active buffs and %d missing buffs|r", 
        activeBuffCount, missingBuffCount))
    
    -- Safety check for main frame
    if not self.frame then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SpBuffTracker Error: No main frame available!|r")
        return
    end
    
    -- Don't try to layout if there are no buffs to show
    if totalCount == 0 then
        -- Update the main frame text to show status
        local title = _G["SpBuffTrackerEnhancedFrameTitle"]
        if title then
            title:SetText("SpBuffTracker Enhanced - No Buffs")
        end
        
        -- Make sure the main frame is big enough to see
        self.frame:SetHeight(50)
        self.frame:SetWidth(200)
        return
    end
    
    -- Calculate how many buffs to show per row
    local buffsPerRow = 8 -- Adjust as needed
    local rows = math.ceil(totalCount / buffsPerRow)
    
    -- Calculate required frame size
    local frameHeight = 60 + (rows * (self.options.buffSize + self.options.spacing + 20))
    local frameWidth = math.min(buffsPerRow, totalCount) * (self.options.buffSize + self.options.spacing) + 20
    
    -- Ensure minimum width
    frameWidth = math.max(frameWidth, 200)
    
    -- Resize the main frame
    self.frame:SetHeight(frameHeight)
    self.frame:SetWidth(frameWidth)
    
    -- Layout active buffs first
    for i = 1, activeBuffCount do
        local buff = self.buffs[i]
        
        -- Get or create buff frame
        local frameName = "SpBuffTrackerEnhancedBuff" .. i
        local buffFrame = _G[frameName]
        
        if not buffFrame then
            buffFrame = self:CreateBuffFrame(i)
        end
        
        -- Set frame ID for context menu and tooltips
        buffFrame:SetID(i)
        
        -- Calculate position (grid layout)
        local row = math.floor((i - 1) / buffsPerRow)
        local col = (i - 1) % buffsPerRow
        
        local xPos = col * (self.options.buffSize + self.options.spacing) + 10
        local yPos = -(row * (self.options.buffSize + self.options.spacing + 20) + 40)
        
        -- Position the buff frame
        buffFrame:ClearAllPoints()
        buffFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", xPos, yPos)
        
        -- Update buff info
        buffFrame.icon:SetTexture(buff.icon)
        buffFrame.name:SetText(buff.name)
        
        -- Show/hide elements based on options
        if self.options.showText then
            buffFrame.name:Show()
            -- Reset color for active buffs
            buffFrame.name:SetTextColor(1, 1, 1)
        else
            buffFrame.name:Hide()
        end
        
        if self.options.showTimerText and buff.duration > 0 then
            buffFrame.timer:SetText(self:FormatTime(buff.timeLeft))
            buffFrame.timer:Show()
        else
            buffFrame.timer:Hide()
        end
        
        if self.options.showBorder then
            buffFrame.border:Show()
            -- Reset color for active buffs
            buffFrame.border:SetVertexColor(1, 1, 1)
        else
            buffFrame.border:Hide()
        end
        
        -- Hide missing indicators for active buffs
        buffFrame.missingOverlay:Hide()
        buffFrame.missingText:Hide()
        
        -- Full opacity for active buffs
        buffFrame:SetAlpha(1.0)
        
        -- Show the buff frame
        buffFrame:Show()
    end
    
    -- Layout missing buffs after active buffs
    if self.options.showMissingBuffs then
        for i = 1, missingBuffCount do
            local buff = self.missingBuffs[i]
            local frameIndex = activeBuffCount + i
            
            -- Get or create buff frame
            local frameName = "SpBuffTrackerEnhancedBuff" .. frameIndex
            local buffFrame = _G[frameName]
            
            if not buffFrame then
                buffFrame = self:CreateBuffFrame(frameIndex)
            end
            
            -- Set frame ID for context menu and tooltips
            buffFrame:SetID(frameIndex)
            
            -- Calculate position (grid layout)
            local row = math.floor((frameIndex - 1) / buffsPerRow)
            local col = (frameIndex - 1) % buffsPerRow
            
            local xPos = col * (self.options.buffSize + self.options.spacing) + 10
            local yPos = -(row * (self.options.buffSize + self.options.spacing + 20) + 40)
            
            -- Position the buff frame
            buffFrame:ClearAllPoints()
            buffFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", xPos, yPos)
            
            -- Update buff info
            buffFrame.icon:SetTexture(buff.icon)
            buffFrame.name:SetText(buff.name)
            
            -- Show/hide elements based on options
            if self.options.showText then
                buffFrame.name:Show()
                -- Set red text color for missing buff names
                buffFrame.name:SetTextColor(1, 0.3, 0.3)
            else
                buffFrame.name:Hide()
            end
            
            -- Hide timer for missing buffs
            buffFrame.timer:Hide()
            
            if self.options.showBorder then
                buffFrame.border:Show()
                -- Set red border color for missing buffs
                buffFrame.border:SetVertexColor(1, 0.3, 0.3)
            else
                buffFrame.border:Hide()
            end
            
            -- Show missing indicators
            buffFrame.missingOverlay:Show()
            
            -- Show missing text based on buff size
            if self.options.buffSize >= 24 then
                buffFrame.missingText:Show()
            else
                buffFrame.missingText:Hide()
            end
            
            -- Reduced opacity for missing buffs
            buffFrame:SetAlpha(self.options.missingBuffOpacity)
            
            -- Show the buff frame
            buffFrame:Show()
        end
    end
    
    -- Hide any unused buff frames
    for i = totalCount + 1, 32 do
        local buffFrame = _G["SpBuffTrackerEnhancedBuff" .. i]
        if buffFrame then
            buffFrame:Hide()
        end
    end
    
    -- Update the main frame title and status text
    local title = _G["SpBuffTrackerEnhancedFrameTitle"]
    if title then
        title:SetText("SpBuffTracker Enhanced")
    end
    
    local statusText = _G["SpBuffTrackerEnhancedFrameStatus"]
    if statusText then
        statusText:SetText(string.format("Active: %d | Missing: %d", activeBuffCount, missingBuffCount))
    end
end