local ui_get, ui_set = ui.get, ui.set
local g_Massive = { "Off", "On", "On + duck", "On + slide", "On + slide 2x", "On + minimal speed" }

local quick_stop 		= ui.reference("RAGE", "Other", "Quick stop")
local quick_stop_ext 	= ui.new_combobox("RAGE", "Other", "Quick stop extended", g_Massive)
local quick_stop_cache 	= "On"

client.set_event_callback("run_command", function(c)
	local g_pLocal = entity.get_local_player()
	local g_pWeapon = entity.get_player_weapon(g_pLocal)

	if g_pLocal and g_pWeapon and ui_get(quick_stop_ext) == g_Massive[6] then
		local m_flNextPrimaryAttack = entity.get_prop(g_pWeapon, "m_flNextPrimaryAttack")
		local m_nTickBase = entity.get_prop(g_pLocal, "m_nTickBase")
		local g_CanShoot = (m_flNextPrimaryAttack <= m_nTickBase * globals.tickinterval())

		if quick_stop_cache == "On" and not g_CanShoot then
			ui_set(quick_stop, "Off")
			quick_stop_cache = ui_get(quick_stop)
		elseif quick_stop_cache == "Off" and g_CanShoot then
			ui_set(quick_stop, "On")
			quick_stop_cache = ui_get(quick_stop)
		end
	end
end)

ui.set_callback(quick_stop_ext, function(z)
	local data = ui_get(z)
	ui_set(quick_stop, data == g_Massive[6] and "On" or data)
end)