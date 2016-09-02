function BombTimer( event )
	local caster = event.caster
	local target = event.target
	local effect = ParticleManager:CreateParticle( "particles/units/heroes/hero_visage/visage_soul_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt( effect, 0, target, PATTACH_OVERHEAD_FOLLOW, "follow_overhead", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex( effect )
end