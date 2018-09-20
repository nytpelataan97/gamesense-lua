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
local cp, currentWeapon = nil, nil
local curWeapon, wpn_info, bad_wpn = nil, {}, { -1, 0, 7, 8, 9, 11 }
local dv_wpn = { "hkp2000", "deagle", "revolver", "ssg08", "awp", "duals", "scar20" }
local to_sort = { "Pistols", "SMGs", "Rifles", "Shotguns", "Snipers", "Heavys" }

local lookup = {
	[32] = { ["name"] = "P2000", ["sname"] = "hkp2000", ["type"] = "pistol" },
	[61] = { ["name"] = "USP-S", ["sname"] = "usp_silencer", ["type"] = "pistol" },
	[4]  = { ["name"] = "Glock-18", ["sname"] = "glock", ["type"] = "pistol" },
	[2]  = { ["name"] = "Dual Beretas", ["sname"] = "duals", ["type"] = "pistol" },
	[36] = { ["name"] = "P250", ["sname"] = "p250", ["type"] = "pistol" },
    [3]  = { ["name"] = "Five-SeveN", ["sname"] = "fiveseven", ["type"] = "pistol" },
    [30] = { ["name"] = "Tec-9", ["sname"] = "tec9", ["type"] = "pistol" },
    [63] = { ["name"] = "CZ75-Auto", ["sname"] = "fn57", ["type"] = "pistol" },
    [1]  = { ["name"] = "Desert Eagle", ["sname"] = "deagle", ["type"] = "pistol" },
	[64] = { ["name"] = "R8-Revolver", ["sname"] = "revolver", ["type"] = "pistol" },
    [10] = { ["name"] = "FAMAS", ["sname"] = "famas", ["type"] = "rifle" },
    [16] = { ["name"] = "M4A4", ["sname"] = "m4a1", ["type"] = "rifle" },
    [60] = { ["name"] = "M4A1-S", ["sname"] = "m4a1_silencer", ["type"] = "rifle" },
    [8]  = { ["name"] = "AUG", ["sname"] = "aug", ["type"] = "rifle" },
    [13] = { ["name"] = "Galil AR", ["sname"] = "galilar", ["type"] = "rifle" },
    [7]  = { ["name"] = "AK-47", ["sname"] = "ak47", ["type"] = "rifle" },
    [39] = { ["name"] = "Sg553", ["sname"] = "sg553", ["type"] = "rifle" },
    [9]  = { ["name"] = "AWP", ["sname"] = "awp", ["type"] = "sniper" },
    [40] = { ["name"] = "Ssg08", ["sname"] = "ssg08", ["type"] = "sniper" },
    [38] = { ["name"] = "Autosniper", ["sname"] = "scar20", ["type"] = "sniper" },
    [35] = { ["name"] = "Nova", ["sname"] = "nova", ["type"] = "shotgun" },
    [25] = { ["name"] = "XM1014", ["sname"] = "xm1014", ["type"] = "shotgun" },
    [29] = { ["name"] = "Sawed-Off", ["sname"] = "sawedoff", ["type"] = "shotgun" },
    [27] = { ["name"] = "MAG-7", ["sname"] = "mag7", ["type"] = "shotgun" },
    [17] = { ["name"] = "MAC-10", ["sname"] = "mac10", ["type"] = "smg" },
    [24] = { ["name"] = "UMP-45", ["sname"] = "ump45", ["type"] = "smg" },
    [26] = { ["name"] = "PP-Bizon", ["sname"] = "bizon", ["type"] = "smg" },
    [34] = { ["name"] = "Mp9 / Mp7", ["sname"] = "mp9", ["type"] = "smg" },
    [19] = { ["name"] = "P90", ["sname"] = "p90", ["type"] = "smg" },
    [28] = { ["name"] = "Negev", ["sname"] = "negev", ["type"] = "heavy" },
    [14] = { ["name"] = "M249", ["sname"] = "m249", ["type"] = "heavy" }
}

local function recreateTable(l)
	local r = {}
	for k, _ in pairs(l) do r[#r+1] = l[k].name end

	return r
end

-- References
local existing_selection = ui.reference("RAGE", "Aimbot", "Target selection")
local existing_avoidl = ui.reference("RAGE", "Aimbot", "Avoid limbs if moving")
local existing_avoidh = ui.reference("RAGE", "Aimbot", "Avoid head if jumping")
local existing_hc = ui.reference("RAGE", "Aimbot", "Minimum hit chance")
local existing_md = ui.reference("RAGE", "Aimbot", "Minimum damage")
local existing_hitbox = ui.reference("RAGE", "Aimbot", "Target hitbox")
local existing_multipoint = ui.reference("RAGE", "Aimbot", "Multi-point")
local existing_scale = ui.reference("RAGE", "Aimbot", "Stomach hitbox scale")
local existing_pscale = ui.reference("RAGE", "Aimbot", "Multi-point scale")
local existing_acboost = ui.reference("RAGE", "Other", "Accuracy boost")
local existing_options = ui.reference("RAGE", "Other", "Accuracy boost options")
local existing_lc = ui.reference("RAGE", "Other", "Fake lag correction")
local existing_baimprefer = ui.reference("RAGE", "Other", "Prefer body aim")

-- Menu
local multicfg_active = interface.checkbox("RAGE", "Other", "Multi config")
local multicfg_bywpn = interface.checkbox("RAGE", "Other", "Sort by class")
local multicfg_divisor = interface.checkbox("RAGE", "Other", "Weapon divisor")
local multicfg_wpns = interface.multiselect("RAGE", "Other", "Active weapons", recreateTable(lookup))

-- Functions

function TableConcat(t1,t2)
    for i=1,#t2 do t1[#t1+1] = t2[i] end
    return t1
end

local function m_vis(table, var)
	for k, _ in pairs(table) do 
		interface.visible(table[k], var)
	end
end

local function hookWeapons()
	foo = {}
	tbl = recreateTable(lookup)

	TableConcat(foo, tbl)
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
      	if tostring(k) == tostring(val) then return true end
      end
   end

   return false
end

local function m_hook(table, isActive)
	if isActive then
		interface.set(existing_selection, interface.get(table.selection)) -- Target Selection
		interface.set(existing_avoidl, interface.get(table.avoidl)) -- Avoid limbs
		interface.set(existing_avoidh, interface.get(table.avoidh)) -- Avoid head
		interface.set(existing_hc, interface.get(table.hitchance)) -- Hitchance
		interface.set(existing_md, interface.get(table.minimumdamage)) -- Minimum damage
		interface.set(existing_hitbox, interface.get(table.hitbox)) -- Target hitbox
		interface.set(existing_multipoint, interface.get(table.multipoint)) -- Multipoint
		interface.set(existing_acboost, interface.get(table.acboost)) -- Accuracy Boost
		interface.set(existing_options, interface.get(table.accuracyboost)) -- Accuracy Boost opts
		interface.set(existing_scale, interface.get(table.bodyscale)) -- Stomach hitbox scale
		interface.set(existing_pscale, interface.get(table.pointscale)) -- Point scale
		interface.set(existing_lc, interface.get(table.lc)) -- Fake lag correction
		interface.set(existing_baimprefer, interface.get(table.baimprefer)) -- Prefer baim
	end
end

local function m_weapon(wpn)
	wpn_info[wpn] = {
		active = interface.checkbox("RAGE", "Other", wpn .. ": " .. "Active"),
		avoidl = interface.checkbox("RAGE", "Other", wpn .. ": " .. "Avoid limbs if moving"),
		avoidh = interface.checkbox("RAGE", "Other", wpn .. ": " .. "Avoid head if jumping"),
		selection = interface.combobox("RAGE", "Other", wpn .. ": " .. "Target selection", "Cycle", "Cycle (2x)", "Near crosshair", "Highest damage", "Lowest ping", "Best K/D ratio", "Best hit chance"),
		hitbox = interface.multiselect("RAGE", "Other", wpn .. ": " .. "Target hitbox", "Head", "Chest", "Stomach", "Arms", "Legs", "Feet"),
		multipoint = interface.multiselect("RAGE", "Other", wpn .. ": " .. "Multi-point", "Head", "Chest", "Stomach", "Arms", "Legs", "Feet"),
		acboost = interface.combobox("RAGE", "Other", wpn .. ": " .. "Accuracy boost", "Off", "Low", "Medium", "High", "Maximum"),
		accuracyboost = interface.multiselect("RAGE", "Other", wpn .. ": " .. "Accuracy boost options", "Refine shot", "Extended backtrack"),
		hitchance = interface.slider("RAGE", "Other", wpn .. ": " .. "Minimum hit chance", 0, 100, 50, true, "%"),
		minimumdamage = interface.slider("RAGE", "Other", wpn .. ": " .. "Minimum damage", 0, 126, 10, true),
		pointscale = interface.slider("RAGE", "Other", wpn .. ": " .. "Multi-point scale", 1, 100, 55, true, "%"),
		bodyscale = interface.slider("RAGE", "Other", wpn .. ": " .. "Stomach hitbox scale", 1, 100, 100, true, "%"),
		lc = interface.combobox("RAGE", "Other", wpn .. ": " .. "Fake lag correction",  "Off", "Delay shot", "Predict"),
		baimprefer = interface.combobox("RAGE", "Other", wpn .. ": " .. "Prefer body aim",  "Off", "Always on", "Fake angles", "Aggressive", "High inaccuracy")
	}

	interface.set(wpn_info[wpn].hitbox, "Head")
end

local function paste()
  	if	interface.get(multicfg_active) and 
  		cp ~= nil and m_valid2(lookup, currentWeapon) then

  		local wpn = wpn_info[cp]
		interface.set(wpn.selection, interface.get(existing_selection))
		interface.set(wpn.avoidl, interface.get(existing_avoidl))
		interface.set(wpn.avoidh, interface.get(existing_avoidh))
		interface.set(wpn.hitchance, interface.get(existing_hc))
		interface.set(wpn.minimumdamage, interface.get(existing_md))
		interface.set(wpn.hitbox, interface.get(existing_hitbox))
		interface.set(wpn.multipoint, interface.get(existing_multipoint))
		interface.set(wpn.acboost, interface.get(existing_acboost))
		interface.set(wpn.accuracyboost, interface.get(existing_options))
		interface.set(wpn.bodyscale, interface.get(existing_scale))
		interface.set(wpn.pointscale, interface.get(existing_pscale))
		interface.set(wpn.lc, interface.get(existing_lc))
		interface.set(wpn.baimprefer, interface.get(existing_baimprefer))
	end
end

local multicfg_paste = ui.new_button("RAGE", "Other", "Paste vars", paste)

local function notAlive(entity)
	return (entity == nil or ent.get_prop(entity, "m_lifeState") ~= 0)
end

local function run_cmd(e)
	if not interface.get(multicfg_active) or notAlive(ent.get_local()) then
		return
	end

	local wpn_id = ent.get_prop(ent.get_local(), "m_hActiveWeapon")
  	local item_di = ent.get_prop(wpn_id, "m_iItemDefinitionIndex")

  	if item_di == 11 then item_di = 38 --[[ G3SG to Scar20 ]] end
  	if item_di == 33 then item_di = 34 --[[ Mp7 to Mp9 ]] end

  	if currentWeapon ~= item_di then
  		currentWeapon = item_di

  		if m_valid2(lookup, currentWeapon) then

  			local lc = lookup[currentWeapon]
  			local wpn = lc.name

			if interface.get(multicfg_bywpn) then
				if lc.type == "pistol" then wpn = "Pistols"
				elseif lc.type == "smg" then wpn = "SMGs"
				elseif lc.type == "rifle" then wpn = "Rifles"
				elseif lc.type == "shotgun" then wpn = "Shotguns"
				elseif lc.type == "sniper" then wpn = "Snipers"
				elseif lc.type == "heavy" then wpn = "Heavys" end

				if interface.get(multicfg_divisor) and m_valid(dv_wpn, lc.sname) then
					wpn = lc.name
				end
			end

			-- Actions
			if not m_valid(bad_wpn, lc.type) and (m_valid(interface.get(multicfg_wpns), lc.name) or interface.get(multicfg_bywpn)) then

				if curWeapon ~= nil then 
					m_vis(wpn_info[curWeapon], false)
				end

				m_vis(wpn_info[wpn], true)
				m_hook(wpn_info[wpn], interface.get(wpn_info[wpn].active))

				cp = wpn
				curWeapon = wpn

			elseif curWeapon ~= nil then 
				m_vis(wpn_info[curWeapon], false)
			end
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
client.set_event_callback("run_command", run_cmd)