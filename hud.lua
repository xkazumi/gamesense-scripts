local globals_realtime = globals.realtime
local globals_curtime = globals.curtime
local globals_maxplayers = globals.maxplayers
local globals_tickcount = globals.tickcount
local globals_tickinterval = globals.tickinterval
local globals_mapname = globals.mapname
local frames = {}
local last_frame = globals_realtime()
local table_insert = table.insert

local client_set_event_callback = client.set_event_callback
local client_console_log = client.log
local client_console_cmd = client.exec
local client_userid_to_entindex = client.userid_to_entindex
local client_get_cvar = client.get_cvar
local client_draw_debug_text = client.draw_debug_text
local client_draw_hitboxes = client.draw_hitboxes
local client_random_int = client.random_int
local client_random_float = client.random_float
local client_draw_text = client.draw_text
local client_draw_rectangle = client.draw_rectangle
local client_draw_line = client.draw_line
local client_world_to_screen = client.world_to_screen
local client_is_local_player = client.is_local_player

local client_screensize = client.screen_size

local ui_new_checkbox = ui.new_checkbox
local ui_new_slider = ui.new_slider
local ui_new_button = ui.new_button
local ui_set = ui.set
local ui_get = ui.get

local entity_get_local_player = entity.get_local_player
local entity_get_all = entity.get_all
local entity_get_players = entity.get_players
local entity_get_classname = entity.get_classname
local entity_set_prop = entity.set_prop
local entity_get_prop = entity.get_prop
local entity_is_enemy = entity.is_enemy
local entity_get_player_name = entity.get_player_name

local to_number = tonumber
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove
local string_format = string.format

local function draw_container(ctx, x, y, w, h)
    local c = {10, 60, 40, 40, 40, 60, 20}
    for i = 0,6,1 do
        client_draw_rectangle(ctx, x+i, y+i, w-(i*2), h-(i*2), c[i+1], c[i+1], c[i+1], 255)
    end
end

local function get_ping(playerresource, player)
    return entity_get_prop(playerresource, string_format("%03d", player))
end

local function on_paint_hud(ctx)

    local realtime = globals_realtime()
    local frames_new = {}
    table_insert(frames, realtime)
 
    local fps = 0
    for i=1, #frames do
        frame = frames[i]
        if realtime - frame <= 1 then
            fps = fps + 1
            table_insert(frames_new, frame)
        end
    end
    frames = frames_new
	
    local scrsize_x, scrsize_y = client_screensize()
    local scrcenter_x, scrcenter_y = scrsize_x - (scrsize_x / 2), scrsize_y - (scrsize_y / 2)
    local local_player = entity_get_local_player() -- we use this multiple times, best to store it once instead of calling it multiple times

    local health, armor, teamnum = entity_get_prop(local_player, "m_iHealth"), entity_get_prop(local_player, "m_ArmorValue"), entity_get_prop(local_player, "m_iTeamNum")
    local teamnum_t, teamnum_ct = 2, 3
	
    local playerresource = entity_get_all("CCSPlayerResource")[1]
    local gamerulesproxy = entity_get_all("CCSGameRulesProxy")[1]
    local counterterrorist = entity_get_all("CCSTeam")[4]
    local terrorist = entity_get_all("CCSTeam")[3]
	
    local ctwins = entity_get_prop(counterterrorist,"m_scoreTotal")
    local twins = entity_get_prop(terrorist,"m_scoreTotal")
	
    local is_warmup = entity_get_prop(gamerulesproxy,"m_bWarmupPeriod")
    local roundtime = entity_get_prop(gamerulesproxy,"m_iRoundTime")
	local curtime = globals_curtime()
	local starttime = entity_get_prop(gamerulesproxy,"m_fRoundStartTime")
	
	local timeleft = (starttime + roundtime) - curtime
	local countdown = false
	if starttime > curtime then
		countdown = true
		timeleft = starttime - curtime
	end
	timeleft = timeleft + 1
	local timer = string.format("%.2d:%.2d", timeleft/60%60, timeleft%60)
	
    local ping = get_ping(playerresource, local_player)
    local fps_text = string_format("%d FPS", fps) 
    local ping_text = string_format("%d MS", ping)
    if armor > 1 and armor <= 100 then
        has_kevlar = true
    else
        has_kevlar = false
    end

    ----bottom left hp armor
    draw_container(ctx, -10, scrsize_y-45, 200, 55)

    if health >= 0 and health <= 100 then
        client_draw_text(ctx, 10, scrsize_y-33, 141, 162, 33, 255, "+", 0, health)
		if health == 100 then
        client_draw_text(ctx, 10 + 50, scrsize_y-22, 255, 255, 255, 255, "", 0, "HP")
		elseif health >= 10 and health <= 99 then
        client_draw_text(ctx, 10 + 35, scrsize_y-22, 255, 255, 255, 255, "", 0, "HP")
		elseif health >= 0 and health < 9 then 
        client_draw_text(ctx, 10 + 20, scrsize_y-22, 255, 255, 255, 255, "", 0, "HP")
		end
    end
    if armor >= 0 then
        client_draw_text(ctx, 100, scrsize_y-33, 52, 152, 219, 255, "+", 0, armor)
		if armor == 100 then
        client_draw_text(ctx, 10 + 50 + 90, scrsize_y-22, 255, 255, 255, 255, "", 0, "AP")
		elseif armor >= 10 and armor <= 99 then
        client_draw_text(ctx, 10 + 35 + 90, scrsize_y-22, 255, 255, 255, 255, "", 0, "AP")
		elseif armor >= 0 and armor < 9 then 
        client_draw_text(ctx, 10 + 20 + 90, scrsize_y-22, 255, 255, 255, 255, "", 0, "AP")
		end
    end
        
	if is_warmup == 0 then
		draw_container(ctx, scrsize_x / 2 - 150, scrsize_y-45, 300, 55)
		draw_container(ctx, scrsize_x / 2 - 50, scrsize_y-45, 100, 55)
        client_draw_text(ctx, scrsize_x / 2 - 100, scrsize_y-20, 255, 255, 255, 255, "c+", 0, ctwins)
        client_draw_text(ctx, scrsize_x / 2 + 100, scrsize_y-20, 255, 255, 255, 255, "c+", 0, twins)
		if countdown == true then
			client_draw_text(ctx, scrsize_x / 2, scrsize_y-20, 255, 0, 0, 255, "c+", 0, timer)
		end
		 if countdown == false then
			client_draw_text(ctx, scrsize_x / 2, scrsize_y-20, 255, 255, 255, 255, "c+", 0, timer)
		end
	end
		
		
end

client_set_event_callback("paint", on_paint_hud)
