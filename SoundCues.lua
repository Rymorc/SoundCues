SoundCues = SoundCues or {}

SoundCues.name = "SoundCues"
SoundCues.version = "1.0.1"
SoundCues.author = "@Rymorc"
SoundCues.Settings = {}
SoundCues.activeEffects = {}
SoundCues.repeatEffects = {}
SoundCues.potionAlerted = true -- initialize as alerted to avoid the sound playing when loading in

function SoundCues.PlaySound(sound, volume)
	if volume < 1 or volume > 20 then volume = 1 end
	for i = 1, volume do -- looping a sound increases its volume
		PlaySound(SOUNDS[sound])
	end
end

local function soundConditions(effectSettings)
    return (
        not IsUnitDead("player") and
        (not effectSettings.inCombatOnly or IsUnitInCombat("player")) and
        (not effectSettings.inDungeonOnly or IsUnitInDungeon("player")) and
        (not effectSettings.vetOnly or GetCurrentZoneDungeonDifficulty() == DUNGEON_DIFFICULTY_VETERAN)
    )
end

function SoundCues.RepeatSound()
    if not next(SoundCues.repeatEffects) then
        EVENT_MANAGER:UnregisterForUpdate(SoundCues.name .. "RepeatSound")
        return
    end
    local effectIdsToUnregister = {}
    for effectId, repeatEffectData in pairs(SoundCues.repeatEffects) do
        local effectSettings = SoundCues.Settings.trackedEffects[effectId]
        if not effectSettings.soundInterval or effectSettings.soundInterval == 0 or not soundConditions(effectSettings) then
            table.insert(effectIdsToUnregister, effectId)
        end
        repeatEffectData.timer = repeatEffectData.timer + 1
        if repeatEffectData.timer == effectSettings.soundInterval then
            SoundCues.PlaySound(effectSettings.sound, effectSettings.volume)
            repeatEffectData.timer = 0
            repeatEffectData.playedCount = repeatEffectData.playedCount + 1
            if repeatEffectData.playedCount >= (effectSettings.soundRepeatAmount or 20) then -- Cap repetition at 20 even for repeat while down, because if you don't recast it within 20 sound plays why even track it
                table.insert(effectIdsToUnregister, effectId)
            end
        end
    end
    for _, effectId in ipairs(effectIdsToUnregister) do
        SoundCues.repeatEffects[effectId] = nil
    end
end


function SoundCues.RunPlaySound(effectId, effectSettings)
    if not soundConditions(effectSettings) then
        return
    end
    SoundCues.PlaySound(effectSettings.sound, effectSettings.volume)
    if effectSettings.soundRepeatType ~= "noRepeat" then
        SoundCues.repeatEffects[effectId] = {
            playedCount = 1,
            timer = 0,
        }
        EVENT_MANAGER:RegisterForUpdate(SoundCues.name .. "RepeatSound", 1000, SoundCues.RepeatSound)
    end
end

function SoundCues.onEffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceUnitType)
    for effectId, effectSettings in pairs(SoundCues.Settings.trackedEffects) do
        if effectId == abilityId and SoundCues.Settings.trackedEffects[effectId].active then
            if (changeType == EFFECT_RESULT_FADED) then
                SoundCues.activeEffects[effectId] = nil
                if effectSettings.timeBeforeEffectEnd == 0.0 then
                    SoundCues.RunPlaySound(effectId, effectSettings)
                end
            elseif (changeType == EFFECT_RESULT_GAINED) then
                SoundCues.repeatEffects[effectId] = nil -- Stop sound repeat if effect is active again
                if effectSettings.timeBeforeEffectEnd ~= 0.0 then
                    SoundCues.activeEffects[effectId] = { endTime = endTime }
                    EVENT_MANAGER:RegisterForUpdate("SoundCuesRun", 100, SoundCues.run)
                end
            end
        end
    end
end

function SoundCues.run()
    if not next(SoundCues.activeEffects) then
        EVENT_MANAGER:UnregisterForUpdate("SoundCuesRun")
        return
    end
    local effectIdsToUnregister = {}
    local now = GetGameTimeSeconds()
    for effectId, activeEffectData in pairs(SoundCues.activeEffects) do
        local effectSettings = SoundCues.Settings.trackedEffects[effectId]
        if activeEffectData.endTime - effectSettings.timeBeforeEffectEnd <= now then
            SoundCues.RunPlaySound(effectId, effectSettings)
            table.insert(effectIdsToUnregister, effectId)
        end
    end
    for _, effectId in ipairs(effectIdsToUnregister) do
        SoundCues.activeEffects[effectId] = nil
    end
end

function SoundCues.trackPotionCooldown()
    local potionSettings = SoundCues.Settings.trackedEffects[-1]
    if not soundConditions(potionSettings) then return end
    local itemLink = GetSlotItemLink(GetCurrentQuickslot(), HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
    local itemType = GetItemLinkItemType(itemLink)
    if itemType ~= ITEMTYPE_POTION then return end
    local remain, _, global, _ = GetSlotCooldownInfo(GetCurrentQuickslot(), HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
    if remain > 0 and not global then
        SoundCues.repeatEffects[-1] = nil -- Stop sound repeat if potion is on cooldown again
        SoundCues.potionAlerted = false
    elseif not SoundCues.potionAlerted then
        SoundCues.RunPlaySound(-1, potionSettings)
        SoundCues.potionAlerted = true
    end
end

function SoundCues.setUpPotionTracker()
    local potionSettings = SoundCues.Settings.trackedEffects[-1]
    if (
        potionSettings.active and
        (not potionSettings.inCombatOnly or IsUnitInCombat("player")) and
        (not potionSettings.inDungeonOnly or IsUnitInDungeon("player")) and
        (not potionSettings.vetOnly or GetCurrentZoneDungeonDifficulty() == DUNGEON_DIFFICULTY_VETERAN)
    ) then
        EVENT_MANAGER:RegisterForUpdate(SoundCues.name .. "TRACK_POTION_COOLDOWN", 200, SoundCues.trackPotionCooldown)
    else
        EVENT_MANAGER:UnregisterForUpdate(SoundCues.name .. "TRACK_POTION_COOLDOWN")
     end
end

function SoundCues.onZoneChange()
    SoundCues.setUpPotionTracker()
end

function SoundCues.trackOnZoneChange()
    if SoundCues.Settings.trackedEffects[-1].inDungeonOnly then
        EVENT_MANAGER:RegisterForEvent(SoundCues.name .. "ZONE_CHANGE", EVENT_ZONE_CHANGED, SoundCues.onZoneChange)
    else
        EVENT_MANAGER:UnregisterForEvent(SoundCues.name .. "ZONE_CHANGE", EVENT_ZONE_CHANGED)
    end
end

function SoundCues.onCombatStateChange()
    SoundCues.setUpPotionTracker()
end

function SoundCues.trackOnCombatStateChange()
    if SoundCues.Settings.trackedEffects[-1].inCombatOnly then
        EVENT_MANAGER:RegisterForEvent(SoundCues.name .. "COMBAT_STATE", EVENT_PLAYER_COMBAT_STATE, SoundCues.onCombatStateChange)
    else
        EVENT_MANAGER:UnregisterForEvent(SoundCues.name .. "COMBAT_STATE", EVENT_PLAYER_COMBAT_STATE)
    end
end

function SoundCues.Initialize()
    SoundCues.Settings = ZO_SavedVars:New("SoundCuesSavedVariables", 1, nil, SoundCuesData.defaults)
    SoundCues.setUpMenu()
    EVENT_MANAGER:RegisterForEvent(SoundCues.name .. "EFFECT_CHANGED", EVENT_EFFECT_CHANGED, SoundCues.onEffectChanged)
    SoundCues.setUpPotionTracker()
    SoundCues.trackOnZoneChange()
end

function SoundCues.OnAddOnLoaded(event, addonName)
    if addonName ~= SoundCues.name then return end
    EVENT_MANAGER:UnregisterForEvent(SoundCues.name, EVENT_ADD_ON_LOADED)
    SoundCues.Initialize()
    EVENT_MANAGER:AddFilterForEvent(SoundCues.name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player") -- Only track player events
end

EVENT_MANAGER:RegisterForEvent(SoundCues.name, EVENT_ADD_ON_LOADED, SoundCues.OnAddOnLoaded)
