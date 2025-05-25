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
    for effectId, buffData in pairs(SoundCues.Settings.trackedEffects) do
        if effectId == abilityId and SoundCues.Settings.trackedEffects[effectId].active then
            if (changeType == EFFECT_RESULT_FADED) then
                SoundCues.activeBuffs[effectId] = nil
                if buffData.timeBeforeEnd == 0.0 then
                    SoundCues.PlaySound(buffData.sound, buffData.volume)
                end
            elseif (changeType == EFFECT_RESULT_GAINED) then
                if buffData.timeBeforeEnd ~= 0.0 then
                    SoundCues.activeBuffs[effectId] = {
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
    local noActiveBuffs = true
    for effectId, activeBuffData in pairs(SoundCues.activeBuffs) do
        noActiveBuffs = false
        local buffData = SoundCues.Settings.trackedEffects[effectId]
        if activeBuffData.endTime - buffData.timeBeforeEnd <= now and activeBuffData.count < buffData.sound_amount then
            SoundCues.PlaySound(buffData.sound, buffData.volume)
            activeBuffData.count = activeBuffData.count + 1
        end
    end
    if noActiveBuffs then
        EVENT_MANAGER:UnregisterForUpdate("SoundCuesRun")
    end
end

function SoundCues.Initialize()
    SoundCues.activeBuffs = {}
    SoundCues.Settings = ZO_SavedVars:New("SoundCuesSavedVariables", 2, nil, SoundCuesData.defaults) -- TODO reset back to 1
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
