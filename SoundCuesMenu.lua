SoundCues = SoundCues or {}

local menuCurrentEffectId = nil

local function getTrackedEffectLists(tbl)
    local EffectIdList = {}
    local EffectNameList = {}
    for EffectId, effectSettings in pairs(tbl) do
        table.insert(EffectIdList, EffectId)
        table.insert(EffectNameList, effectSettings.name)
    end
    return EffectIdList, EffectNameList
end

local function noMenuCurrentEffectId()
    return menuCurrentEffectId == nil
end

local function getEffectValue(attribute)
    if menuCurrentEffectId == nil then return nil end
    return SoundCues.Settings.trackedEffects[menuCurrentEffectId][attribute]
end

local function setEffectValue(attribute, value)
    if menuCurrentEffectId == nil then return end
    SoundCues.Settings.trackedEffects[menuCurrentEffectId][attribute] = value
end

local function testSound(value)
    SoundCues.PlaySound(getEffectValue("sound"), getEffectValue("volume"))
end

function SoundCues.setUpMenu()
    local LAM2 = LibAddonMenu2
    local EffectIdList, EffectNameList = getTrackedEffectLists(SoundCues.Settings.trackedEffects)
    -- df("EffectNameList: %s, %s, %s", unpack(EffectNameList))

    local panelData = {
        type = "panel",
        name = "SoundCues",
        registerForRefresh = true,
        slashCommand = "/SoundCues",
    }
    local optionsData = {
        [1] = {
            type = "dropdown",
            name = "Effect",
            tooltip = "Tracked effect",
            choices = EffectNameList,
            choicesValues = EffectIdList,
            getFunc = function() return menuCurrentEffectId end,
            setFunc = function(value) menuCurrentEffectId = value end,
            scrollable = true,
            sort = "name-up",
            width = "half",
        },
        [2] = {
            type = "divider",
            width = "full",
        },
        [3] = {
            type = "checkbox",
            name = "Active",
            getFunc = function() return getEffectValue("active") end,
            setFunc = function(value) setEffectValue("active", value) end,
            tooltip = "Effect Tracking is active",
            width = "full",
            disabled = noMenuCurrentEffectId,
        },
        [4] = {
            type = "header",
            name = "Sound Effect",
            width = "full",
        },
        [5] = {
            type = "dropdown",
            name = "Sound Effect",
            tooltip = "Sound Effect to play",
            choices = SoundCuesData.soundList,
            scrollable = true,
            getFunc = function() return getEffectValue("sound") end,
            setFunc = function(value) setEffectValue("sound", value) end,
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        [6] = {
            type = "slider",
            name = "Volume",
            tooltip = "Volume of the Sound Effect",
            min = 1,
            max = 20,
            getFunc = function() return getEffectValue("volume") end,
            setFunc = function(value) setEffectValue("volume", value) end,
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        [7] = {
                type = "button",
                name = "Test",
                tooltip = "Test Sound Effect",
                func = testSound,
                width = "full",
                disabled = noMenuCurrentEffectId
        },
        [8] = {
            type = "divider",
            width = "full",
        },
    }

    LAM2:RegisterAddonPanel("SoundCuesOptions", panelData)
    LAM2:RegisterOptionControls("SoundCuesOptions", optionsData)
end