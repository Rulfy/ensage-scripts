--[[		Code			]]

myFont = drawMgr:CreateFont("manabarsFont","Arial",10,10)
drawData = {}
function Frame( tick )
	-- Check if we're currently ingame and the console is closed
	if not client.connected or client.loading or client.console then
		return
	end

	local me = entityList:GetMyHero() --if me is nil we're probably watching a game rather than playing
	local heroes = entityList:FindEntities({type=LuaEntity.TYPE_HERO,illusion=false})
	for i,v in ipairs(heroes) do
		local shouldDraw = false
		if v.alive and v.visible and (not me or me.team ~= v.team) then
			-- get on screen position and check if visible
			test = v.position
			test.z = test.z + v.healthbarOffset
			local onScreen, screenPosition = client:ScreenPosition(test)
			if onScreen then
				drawData[i][1].x = screenPosition.x-51
				drawData[i][1].y = screenPosition.y-22

				local manaPercent = v.mana/v.maxMana
				drawData[i][2].x = screenPosition.x-50
				drawData[i][2].y = screenPosition.y-21
				drawData[i][2].w = 100*manaPercent

				drawData[i][3].x = screenPosition.x-15
				drawData[i][3].y = screenPosition.y-24
				drawData[i][3].text = string.format("%i/%i",math.floor(v.mana),math.floor(v.maxMana))

				shouldDraw = true
			end
		end
		for _,k in ipairs(drawData[i]) do
			k.visible = shouldDraw
		end
	end
end

-- Hide all bars by default if the game is over
function GameClose()
	for _,v in ipairs(drawData) do
		for _,k in ipairs(v) do
			k.visible = false
		end
	end
end

-- register our draw objects
for i = 1, 10 do -- for observer we have 10 heroes (both teams)
 	local element = {}
 	element[1] = drawMgr:CreateRect(0,0,100,8,0x0080FFFF,true); -- outline rect
 	element[1].visible = false
 	element[2] = drawMgr:CreateRect(0,0,0,6,0x00BFFFFF); -- filled bar
 	element[2].visible = false
 	element[3] = drawMgr:CreateText(0,0,0x0099CCFF,"",myFont); -- text
 	element[3].visible = false
 	table.insert(drawData,element)
end

-- We need the FRAME event to sync drawings to the screen-entities
script:RegisterEvent(EVENT_FRAME,Frame)
script:RegisterEvent(EVENT_CLOSE,GameClose)
