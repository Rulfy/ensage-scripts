--[[		Config			]]
-- config can be found in Scripts\config\towerrange.txt

--[[		Code			]]
require("libs.ScriptConfig")

config = ScriptConfig.new()
config:SetParameter("OwnRange", true)
config:SetParameter("EnemyRange", true)
config:SetParameter("TowerRange", 850)
config:Load()

ownRange = config.OwnRange
enemyRange = config.EnemyRange
towerRange = config.TowerRange

effects = {}
function FetchTowers()
	effects = {}
	collectgarbage("collect")
	
	local player = entityList:GetMyPlayer()
	if not (ownRange and enemyRange) and (not player or player.team == LuaEntity.TEAM_NONE) then
		script:RegisterEvent(EVENT_TICK,WaitForMe)
		return
	end

	local towers = entityList:FindEntities({classId=CDOTA_BaseNPC_Tower,alive=true})
	print("TowerRange script found "..#towers.." towers")

	for _,v in ipairs(towers) do
		if (ownRange and enemyRange) or (ownRange and v.team == player.team) or (enemyRange and v.team ~= player.team) then
			local eff = Effect(v,"range_display")
			eff:SetVector( 1, Vector(towerRange,0,0) )
			table.insert(effects,eff)
		end
	end
end

-- If we only want to display enemy or allied towers, we need to wait until we're ingame
sleeptick = 0
function WaitForMe(tick)
	if sleeptick > tick or #effects > 0 then
		return
	end

	local player = entityList:GetMyPlayer()
	if player and player.team ~= LuaEntity.TEAM_NONE then
		FetchTowers()
		script:UnregisterEvent(WaitForMe)
	end

	sleeptick = tick + 250
end

if not ownRange and not enemyRange then
	print("No tower-range to display configured.")
	script:Disable()
	return
end

-- every time a new game has loaded update our tower effects
script:RegisterEvent(EVENT_LOAD,FetchTowers)

-- if we are already ingame, scan for towers alive
if client.connected and not client.loading then
	FetchTowers()
end