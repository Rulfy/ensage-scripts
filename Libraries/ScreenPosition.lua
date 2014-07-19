--[[
	### ScreenPosition created by Zynox ###

	Static functions:
		ScreenPosition.new(w,h,screenRatio): Creates a new position object with YOUR width and height.
			
	Object functions:
		ScreenPosition:GetPosition(x,y[,w[,h): This will transform the given x,y and optional width,heigth values for YOUR screen settings to the screen settings of the current client.
		
	Notes:
		Some UI positions completely change in dota depending on the screenRatio, 
		so if you want your drawings to connect to certain HUD elements, 
		you might need to check for the screen ratio yourself.
		The internal screenratio conversion doesn't work as expected yet!

	Example:
		require("libs.ScreenPosition")

		local sPos = ScreenPosition.new(1152, 648, 16/9) -- our screenSize.x, screenSize.y and screenRatio
		local x,y,w,h = sPos:GetPosition(317, 0, 38, 27) -- retrieve correct values for the client
		local rect = drawMgr:CreateRect(x, y, w, h, -1) -- draw a white rectangle above the first hero icon
 ]]

ScreenPosition = {}
ScreenPosition.__index = ScreenPosition

function ScreenPosition.new(w,h,ratio)
	local result = {}
	setmetatable(result,ScreenPosition)
	result.w = w
	result.h = h
	result.ratio = ratio
	return result
end

function ScreenPosition:GetPosition( x, y, w, h )
	local screenSize = client.screenSize
	local screenRatio = client.screenRatio
	local tx,ty = (x / self.w) / self.ratio, (y / self.h) / self.ratio
	if w and h then
		local tw,th = (w / self.w) / self.ratio, (h / self.h) / self.ratio
		return (tx*screenSize.x*screenRatio), (ty*screenSize.y*screenRatio), (tw*screenSize.x*screenRatio), (th*screenSize.y*screenRatio)
	elseif w then
		local tw = (w / self.w) / self.ratio
		return (tx*screenSize.x*screenRatio), (ty*screenSize.y*screenRatio), (tw*screenSize.x*screenRatio)
	else
		return (tx*screenSize.x*screenRatio), (ty*screenSize.y*screenRatio)
	end
end