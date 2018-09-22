local set_prop = entity.set_prop
local get_prop = entity.get_prop
local ui_get, ui_set = ui.get, ui.set
local get_local = entity.get_local_player

local function tbl(l)
	local r = {}
	for k, _ in pairs(l) do r[#r+1] = k end

	return r
end

local combo = { ["First scope"] = 45, ["Second scope"] = 90 }
local override_fov = ui.reference("MISC", "Miscellaneous", "Override FOV")
local instant_scope = ui.reference("Visuals", "Effects", "Instant scope")

local nozoom_toggle = ui.new_checkbox("VISUALS", "Effects", "No zoom")
local nozoom_onfirst = ui.new_checkbox("VISUALS", "Effects", "Disable zoom on first scope")
local nozoom_combo = ui.new_combobox("VISUALS", "Effects", "Scope level", tbl(combo))

local function getFov(f, level)
	if ui_get(nozoom_onfirst) and level == 2 then
		f = combo[ui_get(nozoom_combo)]
	end

	return (f == 0 and 90 or f)
end

local function on_paint(c)
	local g_pLocalPlayer 	= get_local()
	local g_pWeapon			= get_prop(g_pLocalPlayer, "m_hActiveWeapon")
	local g_pFov			= get_prop(g_pLocalPlayer, "m_iFOV")
	local g_pZoomLvl 		= get_prop(g_pWeapon, "m_zoomLevel")

	if ui_get(nozoom_toggle) then
		ui_set(instant_scope, true)
		set_prop(g_pLocalPlayer, "m_iDefaultFOV", getFov(g_pFov, g_pZoomLvl))
	end
end

local function m_visible()
	local active = ui_get(nozoom_toggle)

	ui.set_visible(nozoom_onfirst, active)
	ui.set_visible(nozoom_combo, active and ui_get(nozoom_onfirst))
end

m_visible()
ui.set_callback(nozoom_toggle, m_visible)
ui.set_callback(nozoom_onfirst, m_visible)
client.set_event_callback("paint", on_paint)