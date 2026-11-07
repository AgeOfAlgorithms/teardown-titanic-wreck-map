#version 2
-- The Titanic wreck map's own script. A map carries no gameplay of its own (the user, 2026-11-03): the diving, the
-- harpoon, the air stations and the spear racks are the global mod Underwater Exploration's (../dive, which this map
-- needs enabled). This script only sets it up through Dive's registry API (../dive/mods/dive/API.md); the air stations
-- (bodies tagged airfill=<seconds spent>) and the racks (spearrack) are tags in main.xml (tools/make_level.py).

-- The pause menu's "Change weather" (sunny, sunset, night, rainy / snowy night) for the host, as the game's sandbox
-- maps have it: the game's own weather.lua, wired up the way its sandbox.lua does (the user, 2026-11-06)
#include "script/weather.lua"

HARPOON_SPEARS = 6   -- every diver carries the harpoon (Dive's), this many spears

function server.init()
	-- drowning takes a while once the tank is empty, so a diver who runs out still has a moment to reach a station
	SetFloat("dive.drown.time", 8)
	-- a bigger tank on this map: 2 minutes (the user asked for twice Dive's old 60 s; Dive's default is now 45)
	SetFloat("dive.air.time", 120)
	-- the wreck lies 30-60 m down, where Dive's normal darkening leaves only the flashlight: half as strong here
	SetFloat("dive.look", 0.5, true)
	-- the pause menu's Spawn button, for the host only (the user's call): the game shows it when the level turns
	-- the spawn menu on (its sandbox maps do it in sandbox.lua, which this map doesn't run: that script also brings
	-- its own respawns). Not synced (no third argument), so only the host's registry has it and joiners get no button.
	SetBool("level.spawn", true)
	armed = {}
end

function server.tick(dt)
	-- the harpoon for every diver: when a player joins and again after each respawn (health back above 0). The table
	-- is rebuilt every tick, so a player who leaves and joins again is armed again.
	local now = {}
	for _, p in ipairs(GetAllPlayers()) do
		local alive = GetPlayerHealth(p) > 0
		if alive and not armed[p] then SetInt("dive.give.harpoon." .. p, HARPOON_SPEARS) end
		now[p] = alive
	end
	armed = now
end

-- the weather the host picked (the sky, the sun, fog and light: the water keeps its own colour and fog)
function server.setWeather(env)
	setWeather(env)
end

function client.init()
	initWeather()
end

function client.tick(dt)
	if IsPlayerHost() then tickWeather() end
end

function client.draw(dt)
	if IsPlayerHost() then
		drawWeather(function(weather) ServerCall("server.setWeather", weather) end)
	end
end
