local ent = {
    ute = client.userid_to_entindex,
	get_local = entity.get_local_player,
	get_prop = entity.get_prop,
    get_all = entity.get_all
}

local cl = {
    ui_get = ui.get,
    checkbox = ui.new_checkbox,
    get_cvar = client.get_cvar,
    set_cvar = client.set_cvar
}

local sky = {
    "sky051",
    "sky_venice",
    "vertigoblue_hdr",
    "sky_cs15_daylight03_hdr",
    "cs_baggage_skybox_",
    "vertigo",
    "otherworld",
    "amethyst",
    "grimmnight",
    "clear_night_sky"
}

local isChecked = cl.checkbox("Visuals", "Effects", "Override sky") 

local function setMath(int, max, declspec)
	local int = (int > max and max or int)

	local tmp = max / int;
	local i = (declspec / tmp)
    i = (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))
    
    if i < 1 then i = 1 end
    return i
end

local function changeSky()
    if not cl.ui_get(isChecked) then return end

    local gameinfo = ent.get_all("CCSGameRulesProxy")
    if gameinfo and #gameinfo > 0 then
        local roundsplayed = ent.get_prop(gameinfo[1], "m_totalRoundsPlayed")
        local maxrounds = cl.get_cvar("mp_maxrounds")

        local curSky = setMath(roundsplayed, tonumber(maxrounds), table.getn(sky))
        cl.set_cvar("sv_skyname", sky[curSky])
    end
end

local function on_player_spawn(e)
    if ent.ute(e.userid) == ent.get_local() then
        changeSky()
    end
end

changeSky() -- Quick change
client.set_event_callback("player_spawn", on_player_spawn)