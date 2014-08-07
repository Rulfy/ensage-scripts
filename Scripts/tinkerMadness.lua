--[[		Config			]]

-- NO CONFIG IN HERE
-- LOAD THIS SCRIPT ONCE AND CHECK "Scripts\config\tinkerMadness.txt" for config options then

--hotkey = "F" --hotkey
--x,y = 5,70 -- gui position
--minimumCombo = {"item_blink", "item_sheepstick"} -- items you need to use the combo, may replace/add "item_dagon"

--[[		Code			]]
require("libs.Utils")
require("libs.TargetFind")
require("libs.ScriptConfig")

config = ScriptConfig.new()
config:SetParameter("GUI x Position", 5)
config:SetParameter("GUI y Position", 70)
config:SetParameter("Hotkey", "F", config.TYPE_HOTKEY)
config:SetParameter("MinimumCombo", "item_blink, item_sheepstick",config.TYPE_STRING_ARRAY)
config:Load()

minimumCombo = config.MinimumCombo
x,y = config:GetParameter("GUI x Position"), config:GetParameter("GUI y Position")
hotkey = config.Hotkey

sleeptick = 0
targetHandle = nil
activated = false
myFont = drawMgr:CreateFont("tinkerCombo","Arial",14,400)
statusText = drawMgr:CreateText(x,y,-1,"Awaiting combo items.",myFont);
targetText = drawMgr:CreateText(x,y+15,-1,"",myFont);
statusText.visible = false
targetText.visible = false

castQueue = {} -- {wait,ability[,target]}

function ComboTick( tick )
	-- only check for a hook while playing the game
	if tick < sleeptick or not IsIngame() or client.console or client.paused then
		return
	end

	-- 8 times a second should be enough
	sleeptick = tick + 125

	-- check if hotkey was pressed twice to deselect the target
	if not targetHandle then
		targetText.visible = false
		statusText.text = "Combo ready."
		script:UnregisterEvent(ComboTick)
		return
	end

	local me = entityList:GetMyHero()
	local player = entityList:GetMyPlayer()
	if not me or not player then
		return
	end

	local target = entityList:GetEntity(targetHandle)
	-- check if we still got a valid target
	if not target or not target.visible or not target.alive or not me.alive 
		or target:IsUnitState(LuaEntityNPC.STATE_MAGIC_IMMUNE) then
			targetHandle = nil
			targetText.visible = false
			statusText.text = "Combo ready."
			script:UnregisterEvent(ComboTick)
			return
	end
	-- grab abilities
	local abilities = me.abilities
	local Q = abilities[1]
	local W = abilities[2]
	local R = abilities[4]
	-- return if we're casting our ult
	if R.channelTime > 0 then
		return
	end
	-- cast things in our queue
	for i=1,#castQueue,1 do
		local v = castQueue[1]
		table.remove(castQueue,1)

		local ability = v[2]
		-- invalid ability workaround...
		if type(ability) == "string" then
			ability = me:FindItem(ability)
		end
		if ability and me:SafeCastAbility(ability,v[3],false) then
			sleeptick = tick + v[1]
			return
		end
	end
	-- grab needed items
	local blink = me:FindItem("item_blink")
	local sheep = nil
	-- we dont need a sheepstick against tide
	if target.classId ~= CDOTA_Unit_Hero_Tidehunter then
		sheep = me:FindItem("item_sheepstick")
	end
	local ethereal = me:FindItem("item_ethereal_blade")
	local dagon = me:FindDagon()
	local soulring = me:FindItem("item_soul_ring")

	if (not sheep or sheep.cd > 0) and ((sheep and R.level < 3) or Q.cd > 0 or (dagon and dagon.cd > 0) or (ethereal and ethereal.cd > 0)) then
		table.insert(castQueue,{1000+math.ceil(R:FindCastPoint()*1000),R})
		return
	end
	-- calc the minimum cast range we need
	if Q.level > 0 then minRange = Q.castRange end
	if dagon then minRange = math.min(minRange,dagon.castRange) end
	if ethereal then minRange = math.min(minRange,ethereal.castRange) end

	local distance = me:GetDistance2D(target)
	-- check if target is too far away
	local blinkRange = blink:GetSpecialData("blink_range")
	if blinkRange + minRange < distance then
		statusText.text = string.format("Target is too far away (%i vs %i).",distance,blinkRange)
		return
	end
	local casted = false
	-- fire rockets
	if W.level > 0 and W.state == LuaEntityAbility.STATE_READY then
		table.insert(castQueue,{100,W})
	end
	-- check if we need to blink to the target
	if minRange < distance then
		statusText.text = "Need to blink."
		if blink.cd > 0 then
			table.insert(castQueue,{1000+math.ceil(R:FindCastPoint()*1000),R})
			return
		end
		-- calc the blink target position
		local tpos = target.position - me.position
		tpos = tpos / tpos.length
		tpos = tpos * (distance-minRange*0.5)
		tpos = me.position + tpos
		table.insert(castQueue,{100,blink,tpos})
	end
	-- soul ring
	table.insert(castQueue,{100,soulring})
	-- now the rest of our combo: tp -> [W -> [blink] -> sheep -> ethereal -> dagon -> Q -> R
	local linkens = target:IsLinkensProtected()
	if linkens and dagon then
		table.insert(castQueue,{500,dagon,target})
	end
	if sheep then
		table.insert(castQueue,{100,sheep,target})
	end
	if ethereal then 
		table.insert(castQueue,{100,"item_ethereal_blade",target})
	end
	if dagon and not linkens then 
		table.insert(castQueue,{100,dagon,target})
	end
	if Q.level > 0 and (not sheep or R.level == 3) and Q.state == LuaEntityAbility.STATE_READY then 
		table.insert(castQueue,{math.ceil(Q:FindCastPoint()*1000),Q,target})
	end
end

function Key( msg, code )
	if msg ~= KEY_UP or not IsIngame() or client.chat then
		return
	end
	-- only our configured hotkey is interesting
	if code == hotkey then
		-- get our target to destroy
		local target = targetFind:GetClosestToMouse(500)
		if not target or target:IsUnitState(LuaEntityNPC.STATE_MAGIC_IMMUNE) then
			targetHandle = nil
			return
		end
		targetText.text = "Killing " .. client:Localize(target.name)
		targetText.visible = true
		targetHandle = target.handle
		-- we got a valid target, now let's beat him up!
		script:RegisterEvent(EVENT_TICK,ComboTick)
	end
end

-- Minimal combo = Ult + Blink + Sheep (so we usually got enough mana and can reset spells and stuff)
function HasCombo()
	local me = entityList:GetMyHero()

	if me.abilities[4].level == 0 then
		return false
	end

	for _,v in ipairs(minimumCombo) do
		if v == "item_dagon" then
			if not me:FindDagon() then
				return false
			end
		else
			if not me:FindItem(v) then
				return false
			end
		end
	end
	return true
end

-- Check if we picked tinker and the minimal combo is available
combosleep = 0
comboCallback = true
function ComboChecker(tick)
	if tick < combosleep or not IsIngame() or client.console then
		return
	end
	combosleep = tick + 500
	local me = entityList:GetMyHero()
	if not me then
		return
	end

	-- check if we're playing the correct hero
	if me.classId ~= CDOTA_Unit_Hero_Tinker then
		targetText.visible = false
		statusText.visible = false
		script:Disable()
		return
	end
	-- check if our (at least minimal) combo is ready
	activated = HasCombo()
	if activated then
		statusText.text = "Combo ready."		
		-- keys may be used now
		script:RegisterEvent(EVENT_KEY,Key)
		-- our combo is ready, we don't need this callback anymore
		comboCallback = false
		script:UnregisterEvent(ComboChecker)
	end
end

-- Register our ComboChecker in a new game if not done yet
function Load()
	-- reset text
	targetText.visible = false
	statusText.visible = true
	statusText.text = "Awaiting combo items."
	-- reset combo found
	activated = false
	if not comboCallback then
		-- activated callbacks
		comboCallback = true
		script:UnregisterEvent(Key)
		script:RegisterEvent(EVENT_TICK,ComboChecker)
	end
end

-- if we're already ingame, the text may be visible
if IsIngame() then
	statusText.visible = true
end

script:RegisterEvent(EVENT_TICK,ComboChecker)
script:RegisterEvent(EVENT_LOAD,Load)


