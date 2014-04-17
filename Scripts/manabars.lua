--[[		Code			]]
-- our text font must be small
myFont = drawMgr:CreateFont("manabarsFont","Arial",10,10) 
-- structure: LuaEntity.handle -> {DrawRect,DrawRect,DrawText
drawData = {}
-- we don't need to update that often
sleeptick = 0
function Tick( tick )
	-- check if we're currently ingame and the console is closed
	if sleeptick > tick or not client.connected or client.loading or client.console then
		return
	end
	-- 4 times a second should be enough
	sleeptick = tick + 250

	local me = entityList:GetMyHero() --if me is nil we're probably watching a game rather than playing
	local heroes = entityList:FindEntities({type=LuaEntity.TYPE_HERO,illusion=false})
	for i,v in ipairs(heroes) do
		if (not me or me.team ~= v.team) then
			-- check if hero already added to our list
			if drawData[v.handle] then
				local shouldDraw = false
				local entry = drawData[v.handle]
				-- check if visible and alive
				if v.alive and v.visible then 
					-- update our bar width and mana text
					local manaPercent = v.mana/v.maxMana
					entry[2].w = 100*manaPercent
					entry[3].text = string.format("%i/%i",math.floor(v.mana),math.floor(v.maxMana))
					shouldDraw = true
				end
				-- set draw objects visible/invisible
				for _,k in ipairs(entry) do
					k.visible = shouldDraw
				end
			else
				-- if we are joining a running game, the healthbar position might be still invalid :(
				if v.healthbarOffset ~= -1 then
				-- add a new hero with draw elements bound to his healthbar position
					local element = {}
				 	element[1] = drawMgr:CreateRect(-51,-22,100,8,0x0080FFFF,true); -- outline rect
				 	element[1].entity = v
				 	element[1].entityPosition = Vector(0,0,v.healthbarOffset)
				 	element[2] = drawMgr:CreateRect(-50,-21,0,6,0x00BFFFFF); -- filled bar
				 	element[2].entity = v
				 	element[2].entityPosition = Vector(0,0,v.healthbarOffset)
				 	element[3] = drawMgr:CreateText(-15,-24,0x0099CCFF,"",myFont); -- text will be set later :)
				 	element[3].entity = v
				 	element[3].entityPosition = Vector(0,0,v.healthbarOffset)
				 	-- save draw element with hero id
				 	drawData[v.handle] = element
				end
			end
		end
	end
end

-- just destroy all draw stuff and clean up
function GameClose()
	drawData = {}
	collectgarbage("collect")
end

-- a tick event is better for performance and we just set the entities to sync with
script:RegisterEvent(EVENT_TICK,Tick)
-- we want to reset all draw data while not playing a game
script:RegisterEvent(EVENT_CLOSE,GameClose)
