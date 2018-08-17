local interface = {
	get = ui.get,
	set = ui.set,
	ref = ui.reference,
	callback = ui.set_callback,
	visible = ui.set_visible
}

local ent = {
	get_local = entity.get_local_player,
	get_pweapon = entity.get_player_weapon,
	get_classname = entity.get_classname
}

-- Functions

local Options = { "Off", "Delay shot", "Predict" }
local LC = interface.ref("RAGE", "Other", "Fake lag correction")

local isActive = ui.new_checkbox("RAGE", "Other", "Zeus bot correction")
local DisableLC = ui.new_combobox("RAGE", "Other", "Lag correction list", Options)

local function isVisible(this)
	interface.visible(DisableLC, interface.get(this))
end

local function on_run_command(e)
	if not interface.get(isActive) then 
		return
	end

	local weapon = ent.get_pweapon(ent.get_local())
	local weapon_name = ent.get_classname(weapon)

	if weapon_name ~= "CWeaponTaser" then
		interface.set(LC, interface.get(DisableLC))
	else
		interface.set(LC, "Off")
	end
end

interface.callback(isActive, isVisible)
client.set_event_callback("run_command", on_run_command)