
function Pounce( event )

	local ability = event.ability
	local speed = ability:GetLevelSpecialValueFor('pounce_speed', (ability:GetLevel() - 1))
	ability.speed = speed

end


function PounceMotion( event )

	local ability = event.ability
	local caster = event.caster
	local target = event.target

    local target_loc = GetGroundPosition(target:GetAbsOrigin(), target)
    local caster_loc = GetGroundPosition(caster:GetAbsOrigin(), caster)
    local direction = (target_loc - caster_loc):Normalized()

	if (target_loc - caster_loc):Length2D() > 100 then
        caster:SetAbsOrigin(caster:GetAbsOrigin() + direction * ability.speed)
    else
        caster:InterruptMotionControllers(false)
        ability:ApplyDataDrivenModifier(caster, target, 'modifier_pounce_kill', {})
        -- target:Kill(ability, caster)
    end

end