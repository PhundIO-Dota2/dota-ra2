require("libraries/buildinghelper")

function Deploy( event )

    local building = "npc_ra2_soviet_construction_yard"
	local caster = event.caster
	local conyard = BuildingHelper:PlaceBuilding(caster:GetOwner(), building, caster:GetAbsOrigin())
    local location = conyard:GetAbsOrigin()
    local grid = conyard:GetKeyValue("Grid")
    if grid and grid["Allowed"] then
        local size = grid["Allowed"]["Square"] or 0
        BuildingHelper:AddGridType(size, location, "ALLOWED")
        conyard:AddNewModifier(conyard, nil, "modifier_grid_allowed", {})
    end
    local player = caster:GetPlayerOwner()
    player:OnBuildingPlaced(building)
    caster:Destroy()

end