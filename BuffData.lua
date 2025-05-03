--[[
    SpBuffTracker Enhanced
    Buff data and mappings
    Version: 1.1.0
]]

local SpBT = SpBuffTrackerEnhanced

-- Default buffs to track
SpBT.trackedBuffs = {
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
}

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
}

-- Reverse map from buff names to textures (for missing buffs)
SpBT.buffNameToTextureMap = {}

-- Function to get buff name from texture
function SpBT:GetBuffNameFromTexture(texture)
    -- Check if this is a known texture in our mapping
    if self.buffTextureMap[texture] then
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
        -- Class buffs for testing
        "Power Word: Fortitude",
        "Prayer of Spirit",
        "Blessing of Kings",
        "Blessing of Wisdom",
        "Mark of the Wild",
        "Arcane Intellect",
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