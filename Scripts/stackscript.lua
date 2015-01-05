--[[		Config			]]
-- pulls ancients with a ranged creep

--[[		Code			]]
require("libs.ScriptConfig")
require("libs.Utils")

config = ScriptConfig.new()
config:SetParameter("Hotkey", "O", config.TYPE_HOTKEY)
config:SetParameter("GUI-X", 5)
config:SetParameter("GUI-Y", 50)
config:Load()

hotkey = config.Hotkey
x,y = config["GUI-X"], config["GUI-Y"]

ownRange = config.OwnRange
enemyRange = config.EnemyRange
towerRange = config.TowerRange

-- game time seconds when start to stack (from wait point)
startTime_radiant = 47	
startTime_dire = 45
-- when to attack the ancient
attack_radiant = 51
attack_dire = 52

-- routes
stack_route_radiant = {
	Vector(-2514,-155,256), 	-- attackWait
	Vector(-4762,-2229,256), 	-- move1
	Vector(-2144,-544,256),		-- wait (must be last)
}  

stack_route_dire = {
	Vector(3458, -640, 127), 	-- attackWait
	Vector(2278, 338, 127), 	-- move1
	Vector(3808, -96, 256)		-- wait (must be last)
} 
 
activated = true -- toggle by hotkey if activated
creepHandle = nil -- current creep
font = drawMgr:CreateFont("stackfont","Arial",14,500) -- font for drawing
if string.byte("A") <= hotkey and hotkey <= string.byte("Z") then
	defaultText = "StackScript: select your ranged creep and press \""..string.char(hotkey).."\"." -- default text to display
else
	defaultText = "StackScript: select your ranged creep and press keycode \""..hotkey.."\"." -- default text to display
end
text = drawMgr:CreateText(x,y,-1,defaultText,font) -- text object to draw
route = nil -- currently active route
waitTime = nil -- currently active wait time
attackTime = nil
ordered = 0 -- state 0 = waiting and moving to attack spot
registered = false -- only register our callbacks once

function Key(msg,code)
	if msg ~= KEY_UP or client.chat or not client.connected or client.loading or code ~= hotkey then
		return
	end
	activated = not activated
	if not activated then
		text.text = defaultText
		return
	end
	-- check if we're ingame and already have a valid team
	local player = entityList:GetMyPlayer()
	if not player or player.team == LuaEntity.TEAM_NONE then
		activated = false
		return
	end
	-- check if the player has currently selected a controllable creep
	local selection = player.selection
	if #selection ~= 1 or 
		(selection[1].type ~= LuaEntity.TYPE_CREEP and selection[1].type ~= LuaEntity.TYPE_NPC) 
		or not selection[1].controllable or selection[1].attackType ~= LuaEntityNPC.ATTACK_RANGED then
		activated = false
		return
	end

	if player.team == LuaEntity.TEAM_DIRE then
		route = stack_route_dire
		waitTime = startTime_dire
		attackTime = attack_dire
	elseif player.team == LuaEntity.TEAM_RADIANT then
		route = stack_route_radiant
		waitTime = startTime_radiant
		attackTime = attack_radiant
	end
	-- maybe we're an observer only, so there's no valid route
	if not route or not waitTime or not attackTime then 
		activated = false
		return
	end
	creepHandle = selection[1].handle
	player:Move(route[#route])
	text.text = "StackScript: moving creep to wait location."
end

sleeptick = 0
function Tick(tick)
	if sleeptick > tick or not activated or not creepHandle or client.paused then
		return
	end
	sleeptick = tick + 250

	local player = entityList:GetMyPlayer()
	if not player then
		return
	end

	-- check if our creep is still existing and alive
	local creep = entityList:GetEntity(creepHandle)
	if not creep or not creep.alive then
		text.text = "StackScript: creep dead."
		activated = false
		creepHandle = nil
		return
	end
	-- do the stacking if not paused, correct timing and creep is already @waiting position
	if ordered == 0 and (client.gameTime % 60) >= waitTime and creep:GetDistance2D(route[#route]) <= 3 then
		text.text = "StackScript: waiting for attack order."
		creep:Move(route[1])
		ordered = 1
	-- attack creep
	elseif ordered == 1 and (client.gameTime % 60 >= attackTime) then
		local enemy = GetNearestPullCreep(creep)
		if not enemy then
			ordered = 0
			player:Move(route[#route])
			sleeptick = tick + 9*1000
			text.text = "StackScript: no enemy to pull here."
			return
		end
		text.text = "StackScript: pulling."
		creep:Attack(enemy)
		ordered = 2
		sleeptick = tick + 1650 -- wait till the attack starts
	elseif ordered == 2 then
		text.text = "StackScript: waiting for next pull."
		creep:Move(route[2],false)
		creep:Move(route[3],true)
		ordered = 0
	end
end

function GetNearestPullCreep(creep)
	local foundAncients = {}
	local ancients = entityList:GetEntities({visible=true,alive=true,type=LuaEntity.TYPE_CREEP})
	for _,v in ipairs(ancients) do
		if v.ancient and v.spawned then
			table.insert(foundAncients,v)
		end
	end
	-- get nearest one
	local bestDistance = nil
	local bestAncient = nil

	for _,v in ipairs(foundAncients) do
		local distance = creep:GetDistance2D(v)
		if not bestDistance or distance < bestDistance then
			bestAncient = v
			bestDistance = distance
		end
	end

	return bestAncient
end

-- reset all stuff after leaving a game
function Close()
	text.text = defaultText
	text.visible = false
	creepHandle = nil
	route = nil
	waitTime = nil
	activated = false
	ordered = false

	script:UnregisterEvent(Tick)
	script:UnregisterEvent(Key)
	registered = false
end

-- register our callbacks
function Load()
	if registered then return end

	script:RegisterEvent(EVENT_TICK,Tick)
	script:RegisterEvent(EVENT_KEY,Key)
	text.visible = true
	registered = true
end

-- Callbacks are only needed while ingame...
script:RegisterEvent(EVENT_CLOSE,Close)
script:RegisterEvent(EVENT_LOAD,Load)

-- load if already ingame
if client.connected and not client.loading then
	Load()
end
