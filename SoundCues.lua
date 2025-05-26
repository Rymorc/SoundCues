SoundCues = SoundCues or {}

SoundCues.name = "SoundCues"
SoundCues.version = "1.0.1"
SoundCues.author = "@Rymorc"
SoundCues.Settings = {}

function SoundCues.PlaySound(sound, volume)
	if volume < 1 or volume > 20 then volume = 1 end
	for i = 1, volume do -- looping a sound increases its volume
		PlaySound(SOUNDS[sound])
	end
end

function SoundCues.onEffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceUnitType)
    for effectId, effectData in pairs(SoundCues.Settings.trackedEffects) do
        if effectId == abilityId and SoundCues.Settings.trackedEffects[effectId].active then
            if (changeType == EFFECT_RESULT_FADED) then
                SoundCues.activeEffects[effectId] = nil
                if effectData.timeBeforeEffectEnd == 0.0 then
                    SoundCues.PlaySound(effectData.sound, effectData.volume)
                end
            elseif (changeType == EFFECT_RESULT_GAINED) then
                if effectData.timeBeforeEffectEnd ~= 0.0 then
                    SoundCues.activeEffects[effectId] = {
                        endTime = endTime,
                        count = 0,
                    }
                    EVENT_MANAGER:RegisterForUpdate("SoundCuesRun", 100, SoundCues.run)
                end
            end
        end
    end
end

function SoundCues.run()
    local now = GetGameTimeSeconds()
    local noActiveEffects = true
    for effectId, activeEffectData in pairs(SoundCues.activeEffects) do
        noActiveEffects = false
        local effectData = SoundCues.Settings.trackedEffects[effectId]
        if activeEffectData.endTime - effectData.timeBeforeEffectEnd <= now and activeEffectData.count < (effectData.soundRepeatAmount or 1) then
            SoundCues.PlaySound(effectData.sound, effectData.volume)
            activeEffectData.count = activeEffectData.count + 1
        end
    end
    if noActiveEffects then
        EVENT_MANAGER:UnregisterForUpdate("SoundCuesRun")
    end
end

function SoundCues.Initialize()
    SoundCues.activeEffects = {}
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
