--[[		Config			]]
-- config can be found in Scripts\config\stackscript.txt

--[[		Code			]]
require("libs.ScriptConfig")

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


startTime = 49                         -- game time seconds when start to stack (from wait point)
stack_route_radiant = {Vector(-2991,198,256), Vector(-7264,-6752,270), Vector(-2144,-480,256)}  -- triangle route for radiant ( 1:pull point, 2: fountain, 3: wait point )
stack_route_dire = {Vector(4447,-1950,127), Vector(6975,6742,256), Vector(5083,-1433,127)}      -- triangle route for dire  1:pull point, 2: fountain, 3: wait point )
 
activated = true -- toggle by hotkey if activated
creepHandle = nil -- current creep
font = drawMgr:CreateFont("stackfont","Arial",14,500) -- font for drawing
if string.byte("A") <= hotkey and hotkey <= string.byte("Z") then
	defaultText = "StackScript: select your creep and press \""..string.char(hotkey).."\"." -- default text to display
else
	defaultText = "StackScript: select your creep and press keycode \""..hotkey.."\"." -- default text to display
end
text = drawMgr:CreateText(x,y,-1,defaultText,font) -- text object to draw
route = nil -- currently active route
ordered = false -- only order once
registered = false -- only register our callbacks once


function Key(msg,code)
	if msg ~= KEY_UP or client.chat or not client.connected or client.loading then
		return
	end

	if code == hotkey then
		activated = not activated
		if activated then

			-- check if we're ingame and already have a valid team
			local player = entityList:GetMyPlayer()
			if not player or player.team == LuaEntity.TEAM_NONE then
				activated = false
				return
			end

			-- check if the player has currently selected a controllable creep
			local selection = player.selection
			if #selection ~= 1 or (selection[1].type ~= LuaEntity.TYPE_CREEP and selection[1].type ~= LuaEntity.TYPE_NPC) or not selection[1].controllable then
				activated = false
				return
			end

			if player.team == LuaEntity.TEAM_DIRE then
				route = stack_route_dire
			elseif player.team == LuaEntity.TEAM_RADIANT then
				route = stack_route_radiant
			end

			-- maybe we're an observer only, so there's no valid route
			if not route then 
				activated = false
				return
			end

			creepHandle = selection[1].handle
			player:Move(route[3])
			text.text = "StackScript: moving creep to pull location."
		else
			text.text = defaultText
		end
	end
end

sleeptick = 0
function Tick(tick)
	if sleeptick > tick or not activated or not creepHandle then
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
	if not ordered and (client.gameTime % 60 >= startTime) and not client.paused and isPosEqual(creep.position,route[3],2) then
		text.text = "StackScript: stack ordered."
		ordered = true

		local selection = player.selection
		-- select our pull creep
		player:Select(creep)
		-- move the triangle route
		player:Move(route[1],false)
		player:Move(route[2],true)
		player:Move(route[3],true)
		-- reselect our former selection
		player:Select(selection[1])
		for i = 2, #selection, 1 do
			player:SelectAdd(selection[i])
		end
	elseif ordered and (client.gameTime % 60 < startTime) then
		ordered = false
		text.text = "StackScript: waiting."
	end
end

-- check if creep is already @ wait position
function isPosEqual(v1, v2, d)
	return (v1-v2).length <= d
end

-- reset all stuff after leaving a game
function Close()
	text.text = defaultText
	text.visible = false
	creepHandle = nil
	route = nil
	activated = false
	ordered = false

	script:UnregisterEvent(EVENT_TICK)
	script:UnregisterEvent(EVENT_KEY)
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
