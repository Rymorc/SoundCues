SoundCues = SoundCues or {}

SoundCues.name = "SoundCues"
SoundCues.version = "1.0.1"
SoundCues.author = "@Rymorc"
SoundCues.Settings = {}
SoundCues.activeEffects = {}
SoundCues.repeatEffects = {}

function SoundCues.PlaySound(sound, volume)
	if volume < 1 or volume > 20 then volume = 1 end
	for i = 1, volume do -- looping a sound increases its volume
		PlaySound(SOUNDS[sound])
	end
end

function SoundCues.RepeatSound()
    d("RepeatSound")
    if not next(SoundCues.repeatEffects) then
        EVENT_MANAGER:UnregisterForUpdate("SoundCuesRepeatSound")
        return
    end
    local effectIdsToUnregister = {}
    for effectId, repeatEffectData in pairs(SoundCues.repeatEffects) do
        local effectData = SoundCues.Settings.trackedEffects[effectId]
        if not effectData.soundInterval or effectData.soundInterval == 0 then
            table.insert(effectIdsToUnregister, effectId)
        end
        repeatEffectData.timer = repeatEffectData.timer + 1
        if repeatEffectData.timer == effectData.soundInterval then
            SoundCues.PlaySound(effectData.sound, effectData.volume)
            repeatEffectData.timer = 0
            repeatEffectData.playedCount = repeatEffectData.playedCount + 1
            if repeatEffectData.playedCount >= (effectData.soundRepeatAmount or 20) then -- Cap repetition at 20 even for repeat while down, because if you don't recast it within 20 sound plays why even track it
                table.insert(effectIdsToUnregister, effectId)
            end
        end
    end
    for _, effectId in ipairs(effectIdsToUnregister) do
        SoundCues.repeatEffects[effectId] = nil
    end
end


function SoundCues.RunPlaySound(effectId, effectData)
    SoundCues.PlaySound(effectData.sound, effectData.volume)
    if effectData.soundRepeatType ~= "noRepeat" then
        SoundCues.repeatEffects[effectId] = {
            playedCount = 1,
            timer = 0,
        }
        EVENT_MANAGER:RegisterForUpdate("SoundCuesRepeatSound", 1000, SoundCues.RepeatSound)
    end
end

function SoundCues.onEffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceUnitType)
    for effectId, effectData in pairs(SoundCues.Settings.trackedEffects) do
        if effectId == abilityId and SoundCues.Settings.trackedEffects[effectId].active then
            if (changeType == EFFECT_RESULT_FADED) then
                SoundCues.activeEffects[effectId] = nil
                if effectData.timeBeforeEffectEnd == 0.0 then
                    SoundCues.RunPlaySound(effectId, effectData)
                end
            elseif (changeType == EFFECT_RESULT_GAINED) then
                SoundCues.repeatEffects[effectId] = nil -- Stop sound repeat if effect is active again
                if effectData.timeBeforeEffectEnd ~= 0.0 then
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
        local effectData = SoundCues.Settings.trackedEffects[effectId]
        if activeEffectData.endTime - effectData.timeBeforeEffectEnd <= now then
            SoundCues.RunPlaySound(effectId, effectData)
            table.insert(effectIdsToUnregister, effectId)
        end
    end
    for _, effectId in ipairs(effectIdsToUnregister) do
        SoundCues.activeEffects[effectId] = nil
    end
end

function SoundCues.Initialize()
    SoundCues.Settings = ZO_SavedVars:New("SoundCuesSavedVariables", 3, nil, SoundCuesData.defaults) -- TODO reset back to 1
    SoundCues.setUpMenu()
    EVENT_MANAGER:RegisterForEvent(SoundCues.name, EVENT_EFFECT_CHANGED, SoundCues.onEffectChanged)
end

function SoundCues.OnAddOnLoaded(event, addonName)
    if addonName ~= SoundCues.name then return end
    EVENT_MANAGER:UnregisterForEvent(SoundCues.name, EVENT_ADD_ON_LOADED)
    SoundCues.Initialize()
    EVENT_MANAGER:AddFilterForEvent(SoundCues.name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player") -- Only track player events
end

EVENT_MANAGER:RegisterForEvent(SoundCues.name, EVENT_ADD_ON_LOADED, SoundCues.OnAddOnLoaded)
