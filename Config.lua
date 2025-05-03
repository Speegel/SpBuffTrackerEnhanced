--[[
    SpBuffTracker Enhanced
    Configuration GUI and settings
    Version: 1.1.0
]]

local SpBT = SpBuffTrackerEnhanced

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
    
    addSectionTitle("Missing Buffs")
    addCheckbox("Show Missing Buffs", "showMissingBuffs")
    addSlider("Missing Buff Opacity", "missingBuffOpacity", 0.2, 1.0, 0.1)
    
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
    
    -- Create sorted list for display
    local buffNames = {}
    for buffName, isTracked in pairs(self.trackedBuffs) do
        if isTracked then
            table.insert(buffNames, buffName)
        end
    end
    table.sort(buffNames)
    
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
        local noBuffs = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        noBuffs:SetPoint("TOP", content, "TOP", 0, -30)
        noBuffs:SetText("No buffs are currently being tracked.\nAdd buffs using the box below or click 'Restore Default Buffs'.")
        noBuffs:SetJustifyH("CENTER")
    end
    
    -- Adjust content height
    content:SetHeight(math.max(math.abs(y), 200))
    
    -- Make sure content is visible
    content:Show()
end