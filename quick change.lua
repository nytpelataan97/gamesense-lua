local globals_realtime = globals.realtime
local userid_to_entindex = client.userid_to_entindex
local get_local_player = entity.get_local_player
local console_cmd = client.exec

local release_at = nil

local function on_item_equip(e)
	local userid, canzoom, item = e.userid, e.canzoom, e.item
	if userid == nil then
		return
	end
	local entindex = userid_to_entindex(userid)

	if entindex == get_local_player() then
		if item == "scar20" or item == "sg556" then
			console_cmd("-attack2; -lookatweapon; +attack2; +lookatweapon")
			release_at = globals_realtime()+0.1
		else
			if release_at ~= nil then
				console_cmd("-attack2; -lookatweapon")
				release_at = nil
			end
		end
	end
end

local function on_paint(ctx)
	if release_at ~= nil and release_at < globals_realtime() then
		release_at = nil
		console_cmd("-attack2; -lookatweapon; +lookatweapon; -lookatweapon")
	end
end

client.set_event_callback("paint", on_paint)
client.set_event_callback("item_equip", on_item_equip)