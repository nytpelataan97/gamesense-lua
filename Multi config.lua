local bit = require "bit"

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
local cache = {}
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

local reference = {
	{ "RAGE", "Aimbot", "Target hitbox", ["options"] = { 
			["type"] = "multiselect",
			["select"] = { "Head", "Chest", "Stomach", "Arms", "Legs", "Feet" },
			["bydefault"] = "Head"
		}
	},
	{ "RAGE", "Aimbot", "Target selection", ["options"] = { 
			["type"] = "combobox",
			["select"] = { "Cycle", "Cycle (2x)", "Near crosshair", "Highest damage", "Lowest ping", "Best K/D ratio", "Best hit chance" }
		}
	},
	{ "RAGE", "Aimbot", "Avoid limbs if moving", ["options"] = { ["type"] = "checkbox" }},
	{ "RAGE", "Aimbot", "Avoid head if jumping", ["options"] = { ["type"] = "checkbox" }},
	{ "RAGE", "Aimbot", "Dynamic multi-point", ["options"] = {  ["type"] = "checkbox" }},
	{ "RAGE", "Aimbot", "Minimum hit chance", ["options"] = { 
			["type"] = "slider",
			["min"] = 0,
			["max"] = 100,
			["default"] = 50,
			["sh"] = true,
			["symbol"] = "%"
		}
	},
	{ "RAGE", "Aimbot", "Minimum damage", ["options"] = { 
			["type"] = "slider",
			["min"] = 0,
			["max"] = 126,
			["default"] = 10,
			["sh"] = true,
			["symbol"] = ""
		}
	},
	{ "RAGE", "Aimbot", "Stomach hitbox scale", ["options"] = { 
			["type"] = "slider",
			["min"] = 1,
			["max"] = 100,
			["default"] = 100,
			["sh"] = true,
			["symbol"] = "%"
		}
	},
	{ "RAGE", "Aimbot", "Multi-point", ["options"] = { 
			["type"] = "multiselect",
			["select"] = { "Head", "Chest", "Stomach", "Arms", "Legs", "Feet" },
			["bydefault"] = nil
		}
	},
	{ "RAGE", "Aimbot", "Multi-point scale", ["options"] = { 
			["type"] = "slider",
			["min"] = 1,
			["max"] = 100,
			["default"] = 55,
			["sh"] = true,
			["symbol"] = "%"
		}
	},
	{ "RAGE", "Other", "Accuracy boost", ["options"] = { 
			["type"] = "combobox",
			["select"] = { "Off", "Low", "Medium", "High", "Maximum" }
		}
	},
	{ "RAGE", "Other", "Accuracy boost options", ["options"] = { 
			["type"] = "multiselect",
			["select"] = { "Refine shot", "Extended backtrack" },
			["bydefault"] = nil
		}
	},
	{ "RAGE", "Other", "Prefer body aim", ["options"] = { 
			["type"] = "combobox",
			["select"] = { "Off", "Always on", "Fake angles", "Aggressive", "High inaccuracy" }
		}
	},
}

-- Functions

local function m_GetArgByReferenre(ref_id)
	for k, _ in pairs(reference) do 

		if reference[k][3] == ref_id then
			return reference[k]
		end

	end

	return nil
end

local function m_CreateReference(e)
	for num, _ in pairs(reference) do

		local rf = reference[num]
		e[rf[3]] = ui.reference(rf[1], rf[2], rf[3])

	end
end

local function recreateTable(l, id)
	local r = {}
	for k, _ in pairs(l) do

		if id ~= nil then
			r[#r+1] = l[k][id]
		else
			r[#r+1] = l[k]
		end

	end

	return r
end

-- Menu
local multicfg_active = interface.checkbox("RAGE", "Other", "Multi config")
local multicfg_bywpn = interface.checkbox("RAGE", "Other", "Sort by class")
local multicfg_divisor = interface.checkbox("RAGE", "Other", "Weapon divisor")
local multicfg_wpns = interface.multiselect("RAGE", "Other", "Active weapons", recreateTable(lookup, "name"))

-- Functions

function TableConcat(t1,t2)
    for i=1, #t2 do 
    	t1[#t1+1] = t2[i]
    end

    return t1
end

local function m_vis(table, var)
	for k, _ in pairs(table) do 
		interface.visible(table[k], var)
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
		for k, _ in pairs(reference) do 
			local n = reference[k]
			interface.set(cache[n[3]], interface.get(table[n[3]]))
		end
	end
end

local function m_weapon(wpn)
	c = { active = interface.checkbox("RAGE", "Other", wpn .. ": " .. "Active") }

	for k, _ in pairs(reference) do 
		local g = {}
		local refered = reference[k]
		local l_name = refered[3]
		local l_options = refered.options

		if l_options.type == "checkbox" then
			c[l_name] = interface.checkbox("RAGE", "Other", wpn .. ": " .. l_name)

		elseif l_options.type == "slider" then
			c[l_name] = interface.slider("RAGE", "Other", wpn .. ": " .. l_name, l_options.min, l_options.max, l_options.default, l_options.sh, l_options.symbol)

		elseif l_options.type == "combobox" then
			c[l_name] = interface.combobox("RAGE", "Other", wpn .. ": " .. l_name, l_options.select)

		elseif l_options.type == "multiselect" then
			c[l_name] = interface.multiselect("RAGE", "Other", wpn .. ": " .. l_name, l_options.select)
			if l_options.bydefault then

				interface.set(c[l_name], l_options.bydefault)
				
			end
		end
	end

	wpn_info[wpn] = c
end

local function paste()
  	if	interface.get(multicfg_active) and 
  		cp ~= nil and m_valid2(lookup, currentWeapon) then
  		local wpn = wpn_info[cp]

		for k, _ in pairs(reference) do 
			local n = reference[k]
			interface.set(wpn[n[3]], interface.get(cache[n[3]]))
		end
	end
end

local function m_HookWpns()
	foo = {}
	tbl = recreateTable(lookup, "name")

	TableConcat(foo, tbl)
	TableConcat(foo, to_sort)

	for k, v in pairs(foo) do
		m_weapon(foo[k])
		m_vis(wpn_info[foo[k]], false)
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
  	local m_iItemDefinitionIndex = ent.get_prop(wpn_id, "m_iItemDefinitionIndex")
  	local item_di = bit.band(m_iItemDefinitionIndex, 0xFFFF)

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
m_CreateReference(cache)
m_HookWpns()

Visible()
ui.set_callback(multicfg_active, Visible)
ui.set_callback(multicfg_bywpn, Visible)
client.set_event_callback("run_command", run_cmd)