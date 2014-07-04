--[[
	### EasyHUD created by Zynox ###

	Static functions:
		EasyHUD.new(x,y,w,h,[title,backgroundColor,textColor,minimizeButton,closeButton): Returns a new HUD object (constructor)
		EasyHUD.new(x,y,w,h,[title,minimizeButton,closeButton): Returns a new HUD object (constructor)
	
	Object functions:
		EasyHUD:IsClosed(): Returns true if the HUD is closed
		EasyHUD:IsMinimized(): Returns true if the HUD is minimized
		EasyHUD:IsChecked(id): Returns true if the given element is a checkbox and checked

		EasyHUD:Minimize([titlebarButtons): Minimizes/Restores the HUD depending on it's state
		EasyHUD:Open(): Opens the HUD
		EasyHUD:Close(): Closes the HUD

		EasyHUD:RemoveElement(id): Returns true if the element with the given id was found and removed
		EasyHUD:CreateText(x,y,text): Returns the id and a DrawText object
		EasyHUD:CreateTitleButton(color,text[,func): Returns the id, DrawRect, DrawRect (outline) and a DrawText object
		EasyHUD:CreateButton(x,y,w,h,color,text[,func): Returns the id, DrawRect, DrawRect (outline) and a DrawText object
		EasyHUD:EasyHUD:AddCheckbox(x,y,w,h,text[,func,initstate,colorTrue,colorFalse): Same as EasyHUD:CreateButton

	Notes:
		The function for a button/checkbox will always provide all button elements as parameters.
		So you'll receive buttonBackground (DrawRect), buttonFrame (DrawRect), buttonText (DrawText)[, checkboxState (boolean for checkboxes)

	Attributes (please don't change them):
		EasyHUD.titleSize: 			height of the title bar
		EasyHUD.textColor: 			default text color
		EasyHUD.backgroundColor: 	default background color
		EasyHUD.buttonColor:		default button color
		EasyHUD.checkboxTrue:		default checkbox color for checked
		EasyHUD.checkboxFalse:		default checkbox color for unchecked

	Example:
		require("libs.EasyHUD")

		function buttonClick(b1,b2,t)	
			b1.color = bit.lshift(math.random(0,0xFFFFFF),4) + 0xFF 
		end

		myHUD = EasyHUD.new(100,100,250,100,"My first HUD",true,true)
		myHUD:AddText(0,0,"Hello World")
		myHUD:AddButton(0,20,90,40, 0x60615FFF,"DON'T PRESS",buttonClick)
		myHUD:AddCheckbox(0,65,35,20,"I want to win.",nil,true)

	Changelog:
		* Fixed checkboxes being clickable while minimized
		* Fixed an error for buttons without callback functions.
		* Added checkboxes with a create and IsChecked function
 ]]


EasyHUD = {}
EasyHUD.__index = EasyHUD
EasyHUD.titleFont = drawMgr:CreateFont("easyHUDTitle","Arial",12,400)
EasyHUD.textFont = drawMgr:CreateFont("easyHUDText","Arial",14,400)
EasyHUD.titleSize = 14
EasyHUD.textColor = 0xFFFFFFFF
EasyHUD.backgroundColor = 0x969991A0
EasyHUD.buttonColor = 0x60615FFF
EasyHUD.checkboxTrue = 0x17E317FF
EasyHUD.checkboxFalse = 0xF23D30FF

EasyHUD.TYPE_TEXT = 1
EasyHUD.TYPE_BUTTON = 2
EasyHUD.TYPE_CHECKBOX = 3

-- find the last occurence of "find" and either clip till or from the found index 
function SubLast(input,find,till)
	local index,newindex = 1,1
	while newindex do
		index = newindex + 1
		newindex = string.find(input,find,index,true)
	end
	
	if till then
		return string.sub(input,1,index-2)
	else
		return string.sub(input,index)
	end
end

-- check if mouse coordinates are inside a rect
function IsInside(mx,my,x,y,w,h)
	return x <= mx and mx <= (x+w) and y <= my and my <= (y+h) 
end

-- Toggle the minimized state
function EasyHUD:Minimize(titlebar)
	self.minimized = not self.minimized

	local len = #self.elements
	for i = 1, len, 1 do
		local element = self.elements[i]
		-- toggle text
		if element[2] == self.TYPE_TEXT then
			element[3].visible = not self.minimized
		-- toggle none titlebar buttons
		elseif element[2] == self.TYPE_BUTTON and (titlebar or not element[5]) then
			for j = 1, 3, 1 do
				element[3][j].visible = not self.minimized
			end
		-- toggle checkboxes
		elseif element[2] == self.TYPE_CHECKBOX then
			for j = 1, 3, 1 do
				element[3][j].visible = not self.minimized
			end
		end
	end
	-- toggle content
	self.content.visible = not self.minimized
	self.contentOut.visible = not self.minimized
end

-- Close our HUD
function EasyHUD:Close()
	self.closed = true
	-- minimize first
	self.minimized = false
	self:Minimize(true)
	-- hide title bar and title text
	self.titlebar.visible, self.titlebarOut.visible, self.titletext.visible = false,false,false
end

-- Open our HUD
function EasyHUD:Open()
	self.closed = false
	-- minimize first
	self.minimized = true
	self:Minimize(true)
	-- hide title bar and title text
	self.titlebar.visible, self.titlebarOut.visible, self.titletext.visible = true,true,true
end

-- Check if the HUD is currently closed
function EasyHUD:IsClosed()
	return self.closed
end

-- Check if the HUD is currently minimized
function EasyHUD:IsMinimized()
	return self.minimized
end

-- Check if the element is a checkbox and actually checked
function EasyHUD:IsChecked(id)
	local e = self.elements[id]
	return e and e[2] == self.TYPE_CHECKBOX and e[5]
end

-- Creates a new HUD (constructor)
function EasyHUD.new(x,y,w,h,title,background,textcolor,minimize,close)
	local result = {}
	setmetatable(result,EasyHUD)

	if type(background) == "boolean" then
		minimize,close = background,textcolor
		background,textcolor = nil,nil
	end
	if not background then background = EasyHUD.backgroundColor end
	if not textcolor then textcolor = EasyHUD.textColor end

	local tsize = EasyHUD.titleSize
	result.x, result.y, result.w, result.h = x,y,w,h
	result.drag = false
	result.minimized, result.closed = false,false
	result.hasButton = false
	result.titleButtons = 0
	result.id = 0
	result.elements = {}
	result.titlebar = drawMgr:CreateRect(x,y,w,tsize,background)
	result.titlebarOut = drawMgr:CreateRect(x,y,w,tsize,0x000000FF, true)
	result.titletext = drawMgr:CreateText(x+2,y+2,textcolor,"",EasyHUD.titleFont)

	local caller = debug.getinfo(2).short_src
	caller = SubLast(caller,"\\")
	caller = SubLast(caller,".",true)
	local callerscript = _G[caller].script

	if not title then title = caller end
	result.titletext.text = title
	local titleSize = EasyHUD.titleFont:GetTextSize(title)
	result.titletext.x = x + w/2-titleSize.x/2
	result.titletext.y = y + tsize/2-titleSize.y/2

	result.content = drawMgr:CreateRect(x,y+tsize,w,h,background)
	result.contentOut = drawMgr:CreateRect(x,y+tsize,w,h,0x000000FF, true)
	
	callerscript:RegisterEvent(EVENT_TICK,result.Tick,result)
	callerscript:RegisterEvent(EVENT_KEY,result.Key,result)

	if close then
		result:AddTitleButton(EasyHUD.buttonColor,"x", function() result:Close() end)
	end

	if minimize then
		result:AddTitleButton(EasyHUD.buttonColor,"-", function() result:Minimize() end)
	end

	return result
end

-- Tick function for every HUD object (dragging)
function EasyHUD:Tick(tick)
	if not self.drag then
		return
	end
	local mouse = client.mouseScreenPosition

	local deltaX, deltaY = (mouse.x - self.dragX - self.x), (mouse.y - self.dragY - self.y)
	self.x = mouse.x - self.dragX
	self.y = mouse.y - self.dragY

	self.titlebar.x, self.titlebar.y = self.titlebar.x + deltaX, self.titlebar.y + deltaY
	self.titlebarOut.x, self.titlebarOut.y = self.titlebarOut.x + deltaX, self.titlebarOut.y + deltaY
	self.content.x, self.content.y = self.content.x + deltaX, self.content.y + deltaY
	self.contentOut.x, self.contentOut.y = self.contentOut.x + deltaX, self.contentOut.y + deltaY
	self.titletext.x, self.titletext.y = self.titletext.x + deltaX, self.titletext.y + deltaY

	local len = #self.elements
	for i = 1, len, 1 do
		local element = self.elements[i]
		if element[2] == self.TYPE_TEXT then
			element[3].x, element[3].y = element[3].x + deltaX, element[3].y + deltaY
		elseif element[2] == self.TYPE_BUTTON or element[2] == self.TYPE_CHECKBOX then
			for j = 1, 3, 1 do
				local e = element[3][j]
				e.x, e.y = e.x + deltaX, e.y + deltaY
			end
		end
	end
end

-- Key callback for pressing buttons and dragging the interface
function EasyHUD:Key(msg,code)
	if msg == LBUTTON_DOWN then
		if self.hasButton then
			local mouse = client.mouseScreenPosition
			local len = #self.elements
			for i = 1, len, 1 do
				local element = self.elements[i]
				-- check if minimized or if titlebar button
				if element[2] == self.TYPE_BUTTON and (element[5] or not self.minimized) then
					local b = element[3][1]
					if element[4] and IsInside(mouse.x,mouse.y,b.x,b.y,b.w,b.h) then
						element[4](b,element[3][2],element[3][3])
						return
					end
				elseif element[2] == self.TYPE_CHECKBOX and not self.minimized then
					local b = element[3][1]
					if IsInside(mouse.x,mouse.y,b.x,b.y,b.w,b.h) then
						element[5] = not element[5] -- toggle state
						if element[5] then
							b.color = element[6]
						else
							b.color = element[7]
						end
						if element[4] then
							element[4](b,element[3][2],element[3][3],element[5])
						end
						return
					end
				end
			end
		end
		if not self.drag then 
			local mouse = client.mouseScreenPosition
			if IsInside(mouse.x,mouse.y,self.x,self.y,self.w,self.titleSize) then
				self.drag = true 
				self.dragX, self.dragY = (mouse.x - self.x), (mouse.y - self.y)
				return true
			end
		end
	elseif msg == LBUTTON_UP then
		if self.drag then
			self.drag = false
			return true
		end
	end
end

-- Removes the element with the given id, returns true if the element was found and removed
function EasyHUD:RemoveElement(id)
	local len = #self.elements
	for i = 1, len, 1 do
		if self.elements[i][1] == id then
			table.remove(self.elements,i)
			return true
		end
	end
	return false
end

-- Adds a new text to the HUD
function EasyHUD:AddText(x,y,text)
	local textElement = drawMgr:CreateText(x+self.x+3, y+self.y+self.titleSize, self.textColor, text, self.textFont);
	table.insert(self.elements,{self.id,self.TYPE_TEXT,textElement})
	self.id = self.id + 1
	return (self.id-1),textElement
end

-- Adds a titlebar button
function EasyHUD:AddTitleButton(color,text,func)
	self.titleButtons = self.titleButtons + 1

	local w,h = 11,10
	local tx = self.x+self.w-(12*self.titleButtons)-1
	local ty = self.y+2

	local button = drawMgr:CreateRect(tx,ty,w,h,color)
	local buttonOut = drawMgr:CreateRect(tx,ty,w,h,0x000000FF, true)

	local buttonText = drawMgr:CreateText(tx, ty, self.textColor, text, self.titleFont);
	local textSize = self.titleFont:GetTextSize(text)
	buttonText.x = tx + w/2-textSize.x/2
	buttonText.y = ty + h/2-textSize.y/2

	self.hasButton = true
	table.insert(self.elements,{self.id,self.TYPE_BUTTON,{button,buttonOut,buttonText},func,true})
	self.id = self.id + 1
	return (self.id-1),button,buttonOut,buttonText
end

-- Adds a button
function EasyHUD:AddButton(x,y,w,h,color,text,func)
	local tx = x+self.x+3
	local ty = y+self.y+self.titleSize

	local button = drawMgr:CreateRect(tx,ty,w,h,color)
	local buttonOut = drawMgr:CreateRect(tx,ty,w,h,0x000000FF, true)

	local buttonText = drawMgr:CreateText(tx, ty, self.textColor, text, self.textFont);
	local textSize = self.textFont:GetTextSize(text)
	buttonText.x = tx + w/2-textSize.x/2
	buttonText.y = ty + h/2-textSize.y/2

	self.hasButton = true

	table.insert(self.elements,{self.id,self.TYPE_BUTTON,{button,buttonOut,buttonText},func})
	self.id = self.id + 1
	return (self.id-1),button,buttonOut,buttonText
end

-- Adds a checkbox
function EasyHUD:AddCheckbox(x,y,w,h,text,func,initstate, colorTrue, colorFalse)
	local tx = x+self.x+3
	local ty = y+self.y+self.titleSize

	if not colorTrue then colorTrue = self.checkboxTrue end
	if not colorFalse then colorFalse = self.checkboxFalse end

	local color
	if initstate then
		color = colorTrue
	else
		color = colorFalse
	end

	local button = drawMgr:CreateRect(tx,ty,w,h,color)
	local buttonOut = drawMgr:CreateRect(tx,ty,w,h,0x000000FF, true)

	local buttonText = drawMgr:CreateText(tx + w + 2, ty, self.textColor, text, self.titleFont);
	local textSize = self.titleFont:GetTextSize(text)
	buttonText.y = ty + h/2-textSize.y/2

	self.hasButton = true
	table.insert(self.elements,{self.id,self.TYPE_CHECKBOX,{button,buttonOut,buttonText},func,initstate,colorTrue,colorFalse})
	self.id = self.id + 1
	return (self.id-1),button,buttonOut,buttonText
end

