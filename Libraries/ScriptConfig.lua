--[[
	### ScriptConfig created by Zynox ###

	Static functions:
		ScriptConfig.new([filename]): Creates a new config file. If no filename is given it will use the name of the script.
			
	Object functions:
		ScriptConfig:SetParameter(parameter,defaultValue[,type): Adds a parameter to the config value. If you specify no type, then it will try to use the type of the defaultValue.
		ScriptConfig:SetParameters(table): Allows to add multiple parameters with the the form { {p1,dV1,t1}, {p2,dV2,t2}, ... }.
		ScriptConfig:Load(): Returns true if the config has been loaded and false if the config didn't exist but has been created.
		ScriptConfig:CreateDefault(): Creates a new config file and overwrites any existing config entries.
		ScriptConfig:GetParameter(parameter[,withDefault): Returns the loaded value for the given parameter. if withDefault is true then it will also return the default value.

	Metamethods:
		__index: Same function as GetParameter.
		__newindex: Same function as SetParameter (can't be used for hotkeys since no type can be specified).
		
	Notes:
		Changing config values in the script and saving them to the file is currently not possible!
		Hotkey ascii-keycodes MUST be as decimal values! Hexvalues are currently not supported.

	Attributes (please don't change them):
		ScriptConfig.TYPE_UNKNOWN: 	unknown value type, used for errors.
		ScriptConfig.TYPE_BOOL: 		boolean type for values may have "true" or "false"
		ScriptConfig.TYPE_STRING: 	string value
		ScriptConfig.TYPE_NUMBER:	number value
		ScriptConfig.TYPE_HOTKEY:	hotkey value might be a single UPPERCASE character or the ascii key code

	Example:
		require("libs.ScriptConfig")

		local config = ScriptConfig.new()
		config:SetParameter("Hello", "Ensage")
		config:SetParameter("myHotkey", "F", config.TYPE_HOTKEY)
		config:SetParameter("Some NUM", "13.37")
		config:SetParameter("A new parameter", "hihi") 
		config.directlySet = "directly set and created new"
		config.SomeFeature = true

		local loaded = config:Load()
		if loaded then
			print("Config has been loaded")
		else
			print("A new config file has been created")
		end

	Changelog:
		* Added TYPE_STRING_ARRAY to parse "string1, string2, string3" and return it as a table
		* Fixed a bug with CreateDefault
 ]]

ScriptConfig = {}
--ScriptConfig.__index = ScriptConfig
-- invalid data type
ScriptConfig.TYPE_UNKNOWN = 0
-- default lua types
ScriptConfig.TYPE_BOOL = 1
ScriptConfig.TYPE_STRING = 2
ScriptConfig.TYPE_NUMBER = 3
-- custom types
ScriptConfig.TYPE_HOTKEY = 4
ScriptConfig.TYPE_STRING_ARRAY = 5

-- index function to access config values directly
function ScriptConfig.__index(table, key)
	-- try to get our parameter entry
	local v = rawget(table.parameters, key)
	-- if it's a valid parameter
    if v then
    	if v[2] == ScriptConfig.TYPE_STRING_ARRAY then
    		--return as splitted table
    		return split(v[3],","), split(v[1],",")
    	else
    		-- return the value and default value of our parameter
    		return v[3],v[1]
    	end
    end
    -- we don't have a parameter with this name, so check our metatable
    return rawget(getmetatable(table),key)
end

-- index function to set new config values directly
function ScriptConfig.__newindex(table, key, value)
	table:SetParameter(key, value)
end

function ScriptConfig.new(filename)
	local result = {}
	setmetatable(result,ScriptConfig)

	rawset(result,"parameters",{})
	-- get the name of the caller script
	local caller = debug.getinfo(2).short_src
	caller = SubLast(caller,"\\")
	caller = SubLast(caller,".",true)

	if not filename then
		if CONFIG_PATH then
			filename = string.format("%s%s.txt", CONFIG_PATH, caller)
		else
			filename = string.format("%sconfig\\%s.txt", SCRIPT_PATH, caller)
		end
	end
	rawset(result,"filename",filename)

	return result
end

function ScriptConfig:SetParameters( parameterTable )
	for _,v in ipairs(parameterTable) do
		self:SetParameter(v[1],v[2],v[3])
	end
end

function ScriptConfig:SetParameter( parameter, defaultValue, parameterType )
	if defaultValue == nil then
		print("<<ScriptConfig:SetParameter>> no default value given for "..(parameter or "NO PARAMETER"))
		return
	end
	if not parameterType then
		parameterType = self:GetParameterType(type(defaultValue))
		if parameterType == ScriptConfig.TYPE_UNKNOWN then
			print("<<ScriptConfig:SetParameter>> invalid default value given for "..(parameter or "NO PARAMETER"))
			return
		end
	end
	-- [ Parameter ] = { [1] = default, [2] = type, [3] = actual value }
	self.parameters[ parameter ] = {defaultValue,parameterType,nil}
end

function ScriptConfig:GetParameterType(typeName)
	if typeName == "string" then
		return ScriptConfig.TYPE_STRING
	elseif typeName == "number" then
		return ScriptConfig.TYPE_NUMBER
	elseif typeName == "boolean" then
		return ScriptConfig.TYPE_BOOL
	else
		return ScriptConfig.TYPE_UNKNOWN
	end
end

-- Loads the given config and returns "true" if the file has been loaded or "false" if it has been created
function ScriptConfig:Load( )
	local file = io.open(self.filename, "r")
	-- if file doesn't exist, we'll create a new default one
	if not file then
		self:CreateDefault()
		return false
	end
	file:close()
	-- parse every line
	for line in io.lines(self.filename) do
		local key, value = line:match("([%s%w]+) *= *([%w%p%s]+)")
		-- check if we could parse the line correctly
		if key and value then
			-- remove spaces from our key and value
			key, value = trim5(key), trim5(value)
			local entry = self.parameters[key]
			-- ignore "invalid" lines
			if entry then
				-- update our entry
				if entry[2] == ScriptConfig.TYPE_BOOL then
					local bValue = value:lower()
					-- only accept true of false input
					if bValue == "true" then
						entry[3] = true
					elseif bValue == "false" then
						entry[3] = false
					end
				elseif entry[2] == ScriptConfig.TYPE_NUMBER then
					entry[3] = tonumber(value)
				elseif entry[2] == ScriptConfig.TYPE_HOTKEY then
					-- check if it's just a single Letter or directly the keycode
					local hotkey = value:match("%a")
					if hotkey then
						entry[3] = string.byte(hotkey)
					else
						entry[3] = tonumber(value)
					end
				elseif entry[2] == ScriptConfig.TYPE_STRING then
					entry[3] = value
				elseif entry[2] == ScriptConfig.TYPE_STRING_ARRAY then
					entry[3] = value -- we split it while returning
				end
				-- if we still got no value then use the default value
				if entry[3] == nil then
					entry[3] = entry[1]
				end
				-- update our parameter table
				self.parameters[ key ] = entry
			end
		end
	end
	-- check all uninitiliazed entries and add them to our config
	local file = io.open(self.filename, "a+")
	local newLine = false
	for k,v in pairs(self.parameters) do
		if v[3] == nil then
			-- initialize variable, if its an hotkey and the default value is a string, we must convert it to a keycode
			if v[2] == ScriptConfig.TYPE_HOTKEY and type(v[1]) == "string" then
				-- check if it's just a single Letter or directly the keycode
				local hotkey = v[1]:match("%a")
				if hotkey then
					v[3] = string.byte(hotkey)
				else
					v[3] = tonumber(v[1])
				end
			else
				v[3] = v[1]
			end
			self.parameters[k] = v

			-- create a new line first to seperate our old content from the new one
			if not newLine then
				newLine = true
				file:write("\n\n")
			end
			-- write our new config parameter
			file:write( string.format("%s = %s\n", k, v[1]) )
		end
	end
	-- close our config file
	file:flush()
	file:close()

	return true
end

function ScriptConfig:CreateDefault( )
	fileContent = {}

	local file = io.open(self.filename, "w+")
	if not file then
		print("<<ScriptConfig:CreateDefault>> can't create a new config file")
		return
	end
	-- write to file and initialize
	for k,v in pairs(self.parameters) do
		file:write( string.format("%s = %s\n", k, v[1]) )
		-- initialize variable, if its an hotkey and the default value is a string, we must convert it to a keycode
		if v[2] == ScriptConfig.TYPE_HOTKEY and type(v[1]) == "string" then
			-- check if it's just a single Letter or directly the keycode
			local hotkey = v[1]:match("%a")
			if hotkey then
				v[3] = string.byte(hotkey)
			else
				v[3] = tonumber(v[1])
			end
		else
			v[3] = v[1]
		end
		self.parameters[k] = v
	end
	file:flush()
	file:close()
end

-- returns the loaded value and the default value
function ScriptConfig:GetParameter( parameter, withDefault )
	local entry = self.parameters[ parameter ]
	if not entry then
		return nil
	end
	-- if we've got an array then we need to split before returning
	if entry[2] == ScriptConfig.TYPE_STRING_ARRAY then
		if withDefault then
			return split(entry[3]), split(entry[1])
		else
			return split(entry[3])
		end
	end
	-- else just return the value
	if withDefault then
		return entry[3], entry[1]
	else
		return entry[3]
	end
end

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

-- http://lua-users.org/wiki/StringTrim
function trim5(s)
  return s:match'^%s*(.*%S)' or ''
end

-- http://lua-users.org/wiki/SplitJoin
function split(text,sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    text:gsub(pattern, function(c) fields[#fields+1] = trim5(c) end)
    return fields
end
