local userid_to_entindex = client.userid_to_entindex
local get_player_name = entity.get_player_name
local get_local_player = entity.get_local_player
local is_enemy = entity.is_enemy
local console_cmd = client.exec
local ui_get = ui.get
local trashtalk = ui.new_checkbox("MISC", "Settings", "Trashtalk")

local Msg = {
	'Stop being a noob! Get good with www.EZfrags.co.uk',
	'If I was cheating, Id use www.EZfrags.co.uk',
	'You just got pwned by EZfrags, the #1 CS:GO cheat',
	'Visit www.EZfrags.co.uk for the finest public & private CS:GO cheats',
	'Think you could do better? Not without www.EZfrags.co.uk',
	'Im not using www.EZfrags.co.uk, you re just bad'
}

local function get_table_length(data)
  if type(data) ~= 'table' then
    return 0
  end
  local count = 0
  for _ in pairs(data) do
    count = count + 1
  end
  return count
end

local num_quotes = get_table_length(Msg)

local function on_player_death(e)
	if not ui_get(trashtalk) then
		return
	end
	local victim_userid, attacker_userid = e.userid, e.attacker
	if victim_userid == nil or attacker_userid == nil then
		return
	end

	local victim_entindex   = userid_to_entindex(victim_userid)
	local attacker_entindex = userid_to_entindex(attacker_userid)
	if attacker_entindex == get_local_player() and is_enemy(victim_entindex) then
		local commandbaim = 'say ' .. Msg[math.random(num_quotes)]
        console_cmd(commandbaim)
	end

end

client.set_event_callback("player_death", on_player_death)
