require("libraries/buildinghelper")

function Deploy( event )

	local caster = event.caster

	DeepPrintTable(caster:GetOwner())
	local conyard = BuildingHelper:PlaceBuilding(caster:GetOwner(), "npc_ra2_soviet_construction_yard", caster:GetAbsOrigin())
    local location = conyard:GetAbsOrigin()
    local grid = conyard:GetKeyValue("Grid")
    if grid and grid["Allowed"] then
        local size = grid["Allowed"]["Square"] or 0
        BuildingHelper:AddGridType(size, location, "ALLOWED")
        conyard:AddNewModifier(conyard, nil, "modifier_grid_allowed", {})
    end
    caster:Destroy()

end