local interface = {
	get = ui.get,
	set = ui.set,
    ref = ui.reference
}

local ent = {
	get_local = entity.get_local_player,
	get_pweapon = entity.get_player_weapon,
	get_classname = entity.get_classname,
	get_prop = entity.get_prop
}

local cache = nil
local ref = interface.ref("RAGE", "Other", "Fake lag correction")
local isActive = ui.new_checkbox("RAGE", "Other", "Zeus bot correction")

local function notAlive(entity)
	return (entity == nil or ent.get_prop(entity, "m_lifeState") ~= 0)
end

local function on_run_command(c)
    if cache == nil then
        cache = interface.get(ref)
    end
	
	if not interface.get(isActive) or notAlive(ent.get_local()) then
		return
	end
	
	local weapon = ent.get_pweapon(ent.get_local())
	local weapon_name = ent.get_classname(weapon)

    if weapon_name ~= "CWeaponTaser" then
        if cache ~= nil then
            interface.set(ref, cache)
            cache = nil
        end
    else
		interface.set(ref, "Off")
    end
end

client.set_event_callback("run_command", on_run_command)