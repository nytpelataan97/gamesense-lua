local interface = {
	get = ui.get,
	set = ui.set,
    visible = ui.set_visible,
    callback = ui.set_callback,
    multiselect = ui.new_multiselect,
	checkbox = ui.new_checkbox,
	slider = ui.new_slider,
	hotkey = ui.new_hotkey,
	combobox = ui.new_combobox,
}

local cl = {
	log = client.log,
	indicator = client.draw_indicator,
	circle_outline = client.draw_circle_outline,
	circle = client.draw_circle,
	eye_pos = client.eye_position,
	camera_angles = client.camera_angles
}

local ent = {
	get_local = entity.get_local_player,
	get_prop = entity.get_prop,
	get_all = entity.get_all,
	get_players = entity.get_players,
	uid_to_ent = client.userid_to_entindex,
	hitbox_pos = entity.hitbox_position
}

-- Variables
local curWeapon, wpn_info, bad_wpn = nil, {}, { -1, 0, 7, 8, 9, 11 }
local dv_wpn = { "hkp2000", "deagle", "ssg08", "awp", "elite", "scar20" }
local to_sort = { "Pistols", "SMGs", "Rifles", "Shotguns", "Snipers", "Heavys" }

local old_selection, old_hitchance, old_mindamage, old_hb, old_opt, old_bodyscale, old_pointscale, old_baim = nil, nil, nil, nil, nil, nil, nil, nil
local good_wpn = { "hkp2000", "p250", "elite", "deagle", "nova", "xm1014", "mag7", "mp9", "mp7", "ump45", "p90", "bizon", "famas", "m4a1", "aug", "awp", "ssg08", "scar20", "glock", "galilar", "ak47", "sg556", "g3sg1", "mac10", "tec9", "fiveseven" }

-- References
local existing_selection = ui.reference("RAGE", "Aimbot", "Target selection")
local existing_hc = ui.reference("RAGE", "Aimbot", "Minimum hit chance")
local existing_md = ui.reference("RAGE", "Aimbot", "Minimum damage")
local existing_hitbox = ui.reference("RAGE", "Aimbot", "Target hitbox")
local existing_multipoint = ui.reference("RAGE", "Aimbot", "Multi-point")
local existing_scale = ui.reference("RAGE", "Aimbot", "Stomach hitbox scale")
local existing_pscale = ui.reference("RAGE", "Aimbot", "Multi-point scale")
local existing_options = ui.reference("RAGE", "Other", "Accuracy boost options")
local existing_baimprefer = ui.reference("RAGE", "Other", "Prefer body aim")

-- Menu
local multicfg_active = interface.checkbox("RAGE", "Other", "Multi config")
local multicfg_bywpn = interface.checkbox("RAGE", "Other", "Sort by class")
local multicfg_divisor = interface.checkbox("RAGE", "Other", "Weapon divisor")
local multicfg_wpns = interface.multiselect("RAGE", "Other", "Active weapons", good_wpn)

-- Functions
local function m_vis(table, var)
	interface.visible(table.active, var)
	interface.visible(table.selection, var)
	interface.visible(table.hitbox, var)
	interface.visible(table.multipoint, var)
	interface.visible(table.accuracyboost, var)
	interface.visible(table.hitchance, var)
	interface.visible(table.minimumdamage, var)
	interface.visible(table.pointscale, var)
	interface.visible(table.bodyscale, var)
	interface.visible(table.baimprefer, var)
end

local function m_hook(table)
	interface.set(existing_selection, interface.get(table.selection)) -- Target Selection
	interface.set(existing_hc, interface.get(table.hitchance)) -- Hitchance
	interface.set(existing_md, interface.get(table.minimumdamage)) -- Minimum damage
	interface.set(existing_hitbox, interface.get(table.hitbox)) -- Target hitbox
	interface.set(existing_multipoint, interface.get(table.multipoint)) -- Multipoint
	interface.set(existing_options, interface.get(table.accuracyboost)) -- Accuracy Boost opts
	interface.set(existing_scale, interface.get(table.bodyscale)) -- Stomach hitbox scale
	interface.set(existing_pscale, interface.get(table.pointscale)) -- Point scale
	interface.set(existing_baimprefer, interface.get(table.baimprefer)) -- Prefer baim
end

local function m_weapon(wpn)
	wpn_info[wpn] = {
		active = interface.checkbox("RAGE", "Other", "[" .. wpn .. "] " .. "Active"),
		selection = interface.combobox("RAGE", "Other", "[" .. wpn .. "] " .. "Target selection", "Cycle", "Cycle (2x)", "Near crosshair", "Highest damage", "Lowest ping", "Best K/D ratio", "Best hit chance"),
		hitbox = interface.multiselect("RAGE", "Other", "[" .. wpn .. "] " .. "Target hitbox", "Head", "Chest", "Stomach", "Arms", "Legs", "Feet"),
		multipoint = interface.multiselect("RAGE", "Other", "[" .. wpn .. "] " .. "Multi-point", "Head", "Chest", "Stomach", "Arms", "Legs", "Feet"),
		accuracyboost = interface.multiselect("RAGE", "Other", "[" .. wpn .. "] " .. "Accuracy boost options", "Refine shot", "Extended backtrack"),
		hitchance = interface.slider("RAGE", "Other", "[" .. wpn .. "] " .. "Minimum hit chance", 0, 100, 50, true, "%"),
		minimumdamage = interface.slider("RAGE", "Other", "[" .. wpn .. "] " .. "Minimum damage", 0, 126, 10, true),
		pointscale = interface.slider("RAGE", "Other", "[" .. wpn .. "] " .. "Multi-point scale", 1, 100, 55, true, "%"),
		bodyscale = interface.slider("RAGE", "Other", "[" .. wpn .. "] " .. "Stomach hitbox scale", 1, 100, 100, true, "%"),
		baimprefer = interface.combobox("RAGE", "Other", "[" .. wpn .. "] " .. "Prefer body aim",  "Off", "Always on", "Fake angles", "Aggressive", "High inaccuracy")
	}

	interface.set(wpn_info[wpn].hitbox, "Head")
end

-- Functions
function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end

    return t1
end

local function hookWeapons()
	foo = {}
	TableConcat(foo, good_wpn)
	TableConcat(foo, to_sort)

	for k, v in pairs(foo) do
		m_weapon(foo[k])
		m_vis(wpn_info[foo[k]], false)
	end
end


local function m_valid(table, val)
   for i=1,#table do
      if table[i] == val then return true end
   end

   return false
end

function m_valid2(o, val)
   if type(o) == 'table' then
      for k,v in pairs(o) do
      	if tostring(k) == val then return true end
      end
   end

   return false
end

local function notAlive(entity)
	return (entity == nil or ent.get_prop(entity, "m_lifeState") ~= 0)
end

local function on_item_equip(e)
	if e.userid == nil or not interface.get(multicfg_active) or notAlive(ent.get_local()) then 
		return
	end

	if ent.uid_to_ent(e.userid) == ent.get_local() then

		local wpn, wpn_type = e.item, e.weptype

		if interface.get(multicfg_bywpn) then
			if wpn_type == 1 then		wpn = "Pistols"
			elseif wpn_type == 2 then	wpn = "SMGs"
			elseif wpn_type == 3 then	wpn = "Rifles"
			elseif wpn_type == 4 then	wpn = "Shotguns"
			elseif wpn_type == 5 then	wpn = "Snipers"
			elseif wpn_type == 6 then	wpn = "Heavys" end

			if interface.get(multicfg_divisor) and m_valid(dv_wpn, e.item) then
				wpn = e.item
			end
		end

		if not m_valid(bad_wpn, e.weptype) and (m_valid(interface.get(multicfg_wpns), e.item) or interface.get(multicfg_bywpn)) then
			if curWeapon ~= nil then 
				m_vis(wpn_info[curWeapon], false)
			end

			m_vis(wpn_info[wpn], true)
			if interface.get(wpn_info[wpn].active) then 
				m_hook(wpn_info[wpn])
			end

			curWeapon = wpn
		elseif curWeapon ~= nil then 
			m_vis(wpn_info[curWeapon], false)
		end
	end
end

local function Visible()
	local active = interface.get(multicfg_active)
	local bywpn = interface.get(multicfg_bywpn)
	local wpns = interface.get(multicfg_wpns)

	interface.visible(multicfg_bywpn, active)
	interface.visible(multicfg_wpns, active and not bywpn)

	interface.visible(multicfg_divisor, bywpn)

	if curWeapon ~= nil then 
		m_vis(wpn_info[curWeapon], active)
	end
end

-- hk
hookWeapons()

Visible()
ui.set_callback(multicfg_active, Visible)
ui.set_callback(multicfg_bywpn, Visible)
client.set_event_callback("item_equip", on_item_equip)