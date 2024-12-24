SoundCues = {}

SoundCues.name = "SoundCues"

function SoundCues.Initialize()
    SoundCues.activeBuffs = {}

    EVENT_MANAGER:RegisterForEvent(SoundCues.name, EVENT_EFFECT_CHANGED, SoundCues.onEffectChanged)
end

function SoundCues.OnAddOnLoaded(event, addonName)
    if addonName == SoundCues.name then
        SoundCues.Initialize()
        EVENT_MANAGER:UnregisterForEvent(SoundCues.name, EVENT_ADD_ON_LOADED)
        EVENT_MANAGER:AddFilterForEvent(SoundCues.name, EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")
    end
end

function SoundCues.onEffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceUnitType)
    for effectId, buffData in pairs(SoundCuesData.buffs) do
        if (effectId == abilityId) then
            if (changeType == EFFECT_RESULT_FADED) then
                SoundCues.activeBuffs[effectId] = nil
                if buffData.timeBeforeEnd == 0.0 then
                    PlaySound(buffData.sound)
                end
            elseif (changeType == EFFECT_RESULT_GAINED) then
                if buffData.timeBeforeEnd ~= 0.0 then
                    SoundCues.activeBuffs[effectId] = {
                        endTime = endTime,
                        alerted = false,
                    }
                    EVENT_MANAGER:RegisterForUpdate("SoundCuesRun", 100, SoundCues.run)
                end
            end
        end
    end
end

function SoundCues.run()
    local now = GetGameTimeSeconds()
    local tableIsEmpty = true
    for effectId, activeBuffData in pairs(SoundCues.activeBuffs) do
        tableIsEmpty = false
        if activeBuffData.endTime - SoundCuesData.buffs[effectId].timeBeforeEnd <= now and not activeBuffData.alerted then
            PlaySound(SoundCuesData.buffs[effectId].sound)
            activeBuffData.alerted = true
        end
    end
    if tableIsEmpty then
        EVENT_MANAGER:UnregisterForUpdate("SoundCuesRun")
    end
end

EVENT_MANAGER:RegisterForEvent(SoundCues.name, EVENT_ADD_ON_LOADED, SoundCues.OnAddOnLoaded)
