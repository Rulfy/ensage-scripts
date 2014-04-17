--[[		Code			]]
sleeptick = 0
creepData = {}
myFont = drawMgr:CreateFont("campInfo","Arial",14,400)
function Tick(tick)
	if sleeptick > tick then
		return
	end
	-- updating creeps once a second should be enough here
	sleeptick = tick + 1000
	-- reset creep data
	creepData = {}
	-- get all creeps
	local creeps = entityList:GetEntities({alive=true,type=LuaEntity.TYPE_CREEP})
	for _,v in ipairs(creeps) do
		-- check for unspawned creeps and only include neutrals (no lane creeps)
		if not v.spawned and not creepData[v.handle] and v.name and string.sub(v.name, 1, 17) == "npc_dota_neutral_" then
			local name = string.sub(v.name,18)
			-- identify our creep
			if name == "alpha_wolf" then
				name = "Wolf"
			elseif name == "black_dragon" then
				name = "Dragon"
			elseif name == "big_thunder_lizard" then
				name = "Lizard"
			elseif name == "centaur_khan" then
				name = "Centaur"
			elseif name == "dark_troll_warlord" then
				name = "Troll"
			elseif name == "enraged_wildkin" then
				name = "Wildkin"
			elseif name == "forest_troll_high_priest" then
				name = "Priest"
			elseif name == "ghost" then
				name = "Ghost"
			elseif name == "granite_golem" then
				name = "Golem"
			elseif name == "gnoll_assassin" then
				name = "Gnoll"
			elseif name == "harpy_storm" then
				name = "Harpy"
			elseif name == "mud_golem" then
				name = "Golem"
			elseif name == "ogre_magi" then
				name = "Ogre"
			elseif name == "polar_furbolg_ursa_warrior" then
				name = "Ursa"
			elseif name == "satyr_hellcaller" then
				name = "Red Satyr"
			elseif name == "satyr_soulstealer" then
				name = "Blue Satyr"
			elseif name == "kobold_taskmaster" then
				name = "Taskmaster"
			else
				-- ignore other creeps
				name = nil
				--name = name .. " N"
			end

			if name then
				-- create new text
				local newText = drawMgr:CreateText(0,0,-1,name,myFont);
				-- bind to entity position
				newText.entity = v
				creepData[v.handle] = newText
			end
		end
	end
end

-- just destroy all draw stuff and clean up
function GameClose()
	drawData = {}
	collectgarbage("collect")
end

-- update our draw data in the tick event
script:RegisterEvent(EVENT_TICK,Tick)
-- we want to reset all draw data while not playing a game
script:RegisterEvent(EVENT_CLOSE,GameClose)

