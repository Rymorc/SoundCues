SoundCues = SoundCues or {}

local menuCurrentEffectId = nil
local newEffectId = nil

local function getTrackedEffectLists(tbl)
    local effectIdList = {}
    local effectNameList = {}
    for effectId, effectSettings in pairs(tbl) do
        if effectId ~= -1 then -- -1 stores the potion settings
            table.insert(effectIdList, effectId)
            table.insert(effectNameList, effectSettings.name)
        end
    end
    return effectIdList, effectNameList
end

local function getRepeatTypeOptions()
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
    return repeatTypeValues, repeatTypeLabels
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
            active = true,
            timeBeforeEffectEnd = 0,
            sound = "ABILITY_COMPANION_ULTIMATE_READY",
            volume = 1,
            soundRepeatType = "noRepeat",
        }
        menuCurrentEffectId = newEffectId
        reloadEffectDropdown()
    end
    newEffectId = nil
end

local function getEffectValue(effectId, attribute)
    if effectId == nil then return nil end
    return SoundCues.Settings.trackedEffects[effectId][attribute]
end

local function setEffectValue(effectId, attribute, value)
    if effectId == nil then return nil end
    SoundCues.Settings.trackedEffects[effectId][attribute] = value
end

local function setInDungeonOnly(effectId, value)
    if effectId == nil then return nil end
    if not value then
        setEffectValue(effectId, "vetOnly", false)
    end
    setEffectValue(effectId, "inDungeonOnly", value)
end

local function setRepeatType(effectId, value)
    if effectId == nil then return nil end
    local currentEffect = SoundCues.Settings.trackedEffects[effectId]
    if value ~= "RepeatAmount" then
        setEffectValue(effectId, "soundRepeatAmount", nil)
    elseif not currentEffect.soundRepeatAmount or currentEffect.soundRepeatAmount < 2 then
        setEffectValue(effectId, "soundRepeatAmount", 2)
    end
    if value ~= "noRepeat" and (not currentEffect.soundInterval or currentEffect.soundInterval == 0) then
        setEffectValue(effectId, "soundInterval", 1)
    end
    setEffectValue(effectId, "soundRepeatType", value)
end

local function testSound(effectId)
    SoundCues.PlaySound(getEffectValue(effectId, "sound"), getEffectValue(effectId, "volume"))
end

local function effectSettings()
    local EffectIdList, EffectNameList = getTrackedEffectLists(SoundCues.Settings.trackedEffects)

    local repeatTypeValues, repeatTypeLabels = getRepeatTypeOptions()

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
            getFunc = function() return getEffectValue(menuCurrentEffectId, "active") end,
            setFunc = function(value) setEffectValue(menuCurrentEffectId, "active", value) end,
            tooltip = "Effect Tracking can be disabled without having to delete it.",
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "checkbox",
            name = "In Combat",
            getFunc = function() return getEffectValue(menuCurrentEffectId, "inCombatOnly") end,
            setFunc = function(value) setEffectValue(menuCurrentEffectId, "inCombatOnly", value) end,
            tooltip = "Only play the sounds while in combat.",
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "checkbox",
            name = "In Instance",
            getFunc = function() return getEffectValue(menuCurrentEffectId, "inDungeonOnly") end,
            setFunc = function(value) setInDungeonOnly(menuCurrentEffectId, value) end,
            tooltip = "Only play the sounds in instanced zones: dungeons, arenas or trials.",
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "checkbox",
            name = "Veteran Only",
            getFunc = function() return getEffectValue(menuCurrentEffectId, "vetOnly") end,
            setFunc = function(value) setEffectValue(menuCurrentEffectId, "vetOnly", value) end,
            tooltip = "Only play the sounds in veteran instances",
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
            getFunc = function() return getEffectValue(menuCurrentEffectId, "timeBeforeEffectEnd") end,
            setFunc = function(value) setEffectValue(menuCurrentEffectId, "timeBeforeEffectEnd", value) end,
            width = "full",
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
            getFunc = function() return getEffectValue(menuCurrentEffectId, "sound") end,
            setFunc = function(value) setEffectValue(menuCurrentEffectId, "sound", value) end,
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "slider",
            name = "Volume",
            tooltip = "Volume of the Sound Effect",
            min = 1,
            max = 20,
            getFunc = function() return getEffectValue(menuCurrentEffectId, "volume") end,
            setFunc = function(value) setEffectValue(menuCurrentEffectId, "volume", value) end,
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "button",
            name = "Test",
            tooltip = "Test Sound Effect",
            func = function(value) testSound(menuCurrentEffectId) end,
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
            getFunc = function() return getEffectValue(menuCurrentEffectId, "soundRepeatType") end,
            setFunc = function(value) setRepeatType(menuCurrentEffectId, value) end,
            width = "half",
            disabled = noMenuCurrentEffectId,
        },
        {
            type = "slider",
            name = "Repeat Amount",
            tooltip = "The amount of times the sound will be played",
            min = 2,
            max = 20,
            getFunc = function() return getEffectValue(menuCurrentEffectId, "soundRepeatAmount") end,
            setFunc = function(value) setEffectValue(menuCurrentEffectId, "soundRepeatAmount", value) end,
            width = "half",
            disabled = function() return getEffectValue(menuCurrentEffectId, "soundRepeatType") ~= "RepeatAmount" end,
        },
        {
            type = "slider",
            name = "Repeat Interval",
            tooltip = "The time between the sound repitition to be played",
            min = 1,
            max = 10,
            getFunc = function() return getEffectValue(menuCurrentEffectId, "soundInterval") end,
            setFunc = function(value) setEffectValue(menuCurrentEffectId, "soundInterval", value) end,
            width = "half",
            disabled = function() return noMenuCurrentEffectId() or getEffectValue(menuCurrentEffectId, "soundRepeatType") == "noRepeat" end,
        },
    }
end

local function potionSettings()
    local repeatTypeValues, repeatTypeLabels = getRepeatTypeOptions()

    return {
        {
            type = "header",
            name = "Activiation",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Active",
            getFunc = function() return getEffectValue(-1, "active") end,
            setFunc = function(value)
                setEffectValue(-1, "active", value)
                SoundCues.setUpPotionTracker()
            end,
            tooltip = "Disable Potion Tracking",
            width = "half",
        },
        {
            type = "checkbox",
            name = "In Combat",
            getFunc = function() return getEffectValue(-1, "inCombatOnly") end,
            setFunc = function(value)
                setEffectValue(-1, "inCombatOnly", value)
                SoundCues.setUpPotionTracker()
                SoundCues.trackOnCombatStateChange()
            end,
            tooltip = "Only play the sounds while in combat.",
            width = "half",
        },
        {
            type = "checkbox",
            name = "In Group Instance",
            getFunc = function() return getEffectValue(-1, "inDungeonOnly") end,
            setFunc = function(value)
                setInDungeonOnly(-1, value)
                SoundCues.setUpPotionTracker()
                SoundCues.trackOnZoneChange()
            end,
            tooltip = "Only play the sounds in group instance zones: dungeons, arenas or trials.",
            width = "half",
        },
        {
            type = "checkbox",
            name = "Veteran Only",
            getFunc = function() return getEffectValue(-1, "vetOnly") end,
            setFunc = function(value)
                setEffectValue(-1, "vetOnly", value)
                SoundCues.setUpPotionTracker()
            end,
            tooltip = "Only play the sounds in veteran instances",
            width = "half",
            disabled = function() return not getEffectValue(-1, "inDungeonOnly") end ,
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
            getFunc = function() return getEffectValue(-1, "sound") end,
            setFunc = function(value) setEffectValue(-1, "sound", value) end,
            width = "half",
        },
        {
            type = "slider",
            name = "Volume",
            tooltip = "Volume of the Sound Effect",
            min = 1,
            max = 20,
            getFunc = function() return getEffectValue(-1, "volume") end,
            setFunc = function(value) setEffectValue(-1, "volume", value) end,
            width = "half",
        },
        {
            type = "button",
            name = "Test",
            tooltip = "Test Sound Effect",
            func = function(value) testSound(-1) end,
            width = "full",
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
            getFunc = function() return getEffectValue(-1, "soundRepeatType") end,
            setFunc = function(value) setRepeatType(-1, value) end,
            width = "half",
        },
        {
            type = "slider",
            name = "Repeat Amount",
            tooltip = "The amount of times the sound will be played",
            min = 2,
            max = 20,
            getFunc = function() return getEffectValue(-1, "soundRepeatAmount") end,
            setFunc = function(value) setEffectValue(-1, "soundRepeatAmount", value) end,
            width = "half",
            disabled = function() return getEffectValue(-1, "soundRepeatType") ~= "RepeatAmount" end,
        },
        {
            type = "slider",
            name = "Repeat Interval",
            tooltip = "The time between the sound repitition to be played",
            min = 1,
            max = 10,
            getFunc = function() return getEffectValue(-1, "soundInterval") end,
            setFunc = function(value) setEffectValue(-1, "soundInterval", value) end,
            width = "half",
            disabled = function() return getEffectValue(-1, "soundRepeatType") == "noRepeat" end,
        },
    }
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