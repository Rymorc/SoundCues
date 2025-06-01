SoundCues = SoundCues or {}

local menuCurrentEffectId = nil
local newEffectId = nil

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

local function reloadEffectDropdown()
    local EffectIdList, EffectNameList = getTrackedEffectLists(SoundCues.Settings.trackedEffects)
    SOUND_CUES_EFFECT_DROPDOWN:UpdateChoices(EffectNameList, EffectIdList)
end

local function selectEffect(value)
    menuCurrentEffectId = value
    CREATE_DESCRIPTION.data.text = ""
end

local function deleteCurrentEffectTracking()
    if menuCurrentEffectId == nil then return end
    SoundCues.Settings.trackedEffects[menuCurrentEffectId] = nil
    reloadEffectDropdown()
    menuCurrentEffectId = nil
end

local function createNewEffectTracker()
    local abilityName = GetAbilityName(newEffectId)
    if newEffectId == nil or abilityName == nil or abilityName == "" then
        CREATE_DESCRIPTION.data.text = "|cff0000Could not find an effect with ID " .. tostring(newEffectId) .."|r"
    elseif SoundCues.Settings.trackedEffects[newEffectId] ~= nil then
        CREATE_DESCRIPTION.data.text = "|cff0000The effect " .. abilityName .. " (" .. tostring(newEffectId) .. ") is already being tracked|r"
    else
        CREATE_DESCRIPTION.data.text = ""
        SoundCues.Settings.trackedEffects[newEffectId] = {
            name = abilityName,
            sound = "ABILITY_COMPANION_ULTIMATE_READY",
            volume = 1,
            timeBeforeEffectEnd = 0,
            active = true,
        }
        menuCurrentEffectId = newEffectId
        reloadEffectDropdown()
    end
    newEffectId = nil
end

local function getEffectValue(attribute)
    if noMenuCurrentEffectId() then return nil end
    return SoundCues.Settings.trackedEffects[menuCurrentEffectId][attribute]
end

local function setEffectValue(attribute, value)
    if noMenuCurrentEffectId() then return end
    SoundCues.Settings.trackedEffects[menuCurrentEffectId][attribute] = value
end

local function setRepeatType(value)
    if noMenuCurrentEffectId() then return end
    local currentEffect = SoundCues.Settings.trackedEffects[menuCurrentEffectId]
    if value ~= "RepeatAmount" then
        setEffectValue("soundRepeatAmount", nil)
    elseif not currentEffect.soundRepeatAmount or currentEffect.soundRepeatAmount < 2 then
        setEffectValue("soundRepeatAmount", 2)
    end
    if value ~= "noRepeat" and (not currentEffect.soundInterval or currentEffect.soundInterval == 0) then
        setEffectValue("soundInterval", 1)
    end
    setEffectValue("soundRepeatType", value)
end

local function testSound(value)
    SoundCues.PlaySound(getEffectValue("sound"), getEffectValue("volume"))
end

local function effectSettings()
    local EffectIdList, EffectNameList = getTrackedEffectLists(SoundCues.Settings.trackedEffects)

    local repeatTypeValues = {
        "noRepeat",
        "RepeatAmount",
        "RepeatDown",
    }
    local repeatTypeLabels = {
        "No Repeat",
        "Repeat Amount",
        "Repeat While Effect Is Down",
    }

    return {
        {
            type = "header",
            name = "Effects",
            width = "full",
        },
        {
            type = "dropdown",
            name = "Effect",
            tooltip = "Tracked effect",
            choices = EffectNameList,
            choicesValues = EffectIdList,
            getFunc = function() return menuCurrentEffectId end,
            setFunc = selectEffect,
            scrollable = true,
            sort = "name-up",
            width = "half",
            reference = "SOUND_CUES_EFFECT_DROPDOWN",
        },
        {
            type = "button",
            name = "Delete",
            tooltip = "Delete Effect Tracking",
            func = deleteCurrentEffectTracking,
            width = "half",
            isDangerous = true,
            warning = "Are you sure you want to delete this tracker?",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "divider",
            width = "full",
        },
        {
            type = "editbox",
            name = "New Effect ID",
            tooltip = "The ID of the new effect that needs to be tracked",
            getFunc = function() return newEffectId end,
            setFunc = function(value) newEffectId = tonumber(value) end,
            isMultiline = false,
            textType = TEXT_TYPE_NUMERIC,
            width = "half",
            maxChars = 10,
            isExtraWide = false,
        },
        {
            type = "button",
            name = "Create",
            tooltip = "Create tracker for provided Effect ID",
            func = createNewEffectTracker,
            width = "half",
            disabled = function() return newEffectId == nil end
        },
        {
            type = "description",
            text = "",
            width = "full",
            reference = "CREATE_DESCRIPTION"
        },
        {
            type = "header",
            name = "Activiation",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Active",
            getFunc = function() return getEffectValue("active") end,
            setFunc = function(value) setEffectValue("active", value) end,
            tooltip = "Effect Tracking can be disabled without having to delete it.",
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "slider",
            name = "Time Before Effect End",
            tooltip = "The amount of time before the end of the effect to play the Sound, 0 means that the sound will play the moment the effect ends",
            min = 0.0,
            max = 5.0,
            step = 0.1,
            decimals = 1,
            getFunc = function() return getEffectValue("timeBeforeEffectEnd") end,
            setFunc = function(value) setEffectValue("timeBeforeEffectEnd", value) end,
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "header",
            name = "Sound Effect",
            width = "full",
        },
        {
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
        {
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
        {
            type = "button",
            name = "Test",
            tooltip = "Test Sound Effect",
            func = testSound,
            width = "full",
            disabled = noMenuCurrentEffectId
        },
        {
            type = "header",
            name = "Repetition",
            width = "full",
        },
        {
            type = "dropdown",
            name = "Sound Repeat Type",
            tooltip = "Sound Repeat Type",
            choices = repeatTypeLabels,
            choicesValues = repeatTypeValues,
            getFunc = function() return getEffectValue("soundRepeatType") end,
            setFunc = setRepeatType,
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "slider",
            name = "Repeat Amount",
            tooltip = "The amount of times the sound will be played",
            min = 2,
            max = 20,
            getFunc = function() return getEffectValue("soundRepeatAmount") end,
            setFunc = function(value) setEffectValue("soundRepeatAmount", value) end,
            width = "half",
            disabled = function() return getEffectValue("soundRepeatType") ~= "RepeatAmount" end,
        },
        {
            type = "slider",
            name = "Repeat Interval",
            tooltip = "The time between the sound repitition to be played",
            min = 1,
            max = 10,
            getFunc = function() return getEffectValue("soundInterval") end,
            setFunc = function(value) setEffectValue("soundInterval", value) end,
            width = "half",
            disabled = function() return noMenuCurrentEffectId() or getEffectValue("soundRepeatType") == "noRepeat" end,
        },
    }
end

local function potionSettings()
    return {}
end

function SoundCues.setUpMenu()
    local LAM2 = LibAddonMenu2
    local panelData = {
        type = "panel",
        name = "SoundCues",
        registerForRefresh = true,
        slashCommand = "/SoundCues",
    }
    local optionsData = {
        {
            type = "submenu",
            name = "Effect Settings",
            controls = effectSettings()
        },
        {
            type = "submenu",
            name = "Potion Settings",
            controls = potionSettings()
        }
    }

    LAM2:RegisterAddonPanel("SoundCuesOptions", panelData)
    LAM2:RegisterOptionControls("SoundCuesOptions", optionsData)
end