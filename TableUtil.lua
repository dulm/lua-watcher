TableUtil = {}

local function shadowClone(object)
	local target = {}
	for key, value in pairs(object) do
		target[key] = value
	end
	return setmetatable(target, getmetatable(object))
end

local function deepClone(object, refTable)
	if type(object) ~= "table" then
		return object
	elseif refTable[object] then
		return refTable[object]
	end

	local target = {}

	 -- set reference firstly, avoid recursived reference
	refTable[object] = target

	for key, value in pairs(object) do
		target[deepClone(key)] = deepClone(value, refTable)
	end
	return setmetatable(target, getmetatable(object))
end

local function dumpTable(object, space, name, cache)
	local contentTable = {}
	for key, value in pairs(object) do
		local stringKey = tostring(key)
		if cache[value] then
			table.insert(contentTable, "+" .. stringKey .. " {" .. cache[value] .. "}")
		elseif type(value) == "table" then
			local cacheName = name .. "." .. stringKey
			cache[value] = cacheName

			local nextSpace = (next(object, key) and "|" or " " ) .. string.rep(" ", #stringKey)
			local content = dumpTable(value , space .. nextSpace, cacheName, cache)
			table.insert(contentTable, "+" .. stringKey .. content)
		else
			table.insert(contentTable, "+" .. stringKey .. " [" .. tostring(value) .. "]")
		end
	end
	return table.concat(contentTable, "\n" .. space)
end

TableUtil.clone = function (object, deep)
	assert(type(object) == "table")

	if deep == true then
		local refTable = {}
		return deepClone(object, refTable)
	else
		return shadowClone(object)
	end
end

TableUtil.print = function(object, printer)
	if printer == nil then printer = print end
	assert(type(object) == "table")
	assert(type(printer) == "function", "Table printer must be a function")

	local cache = {  [ object ] = "." }
	local content = dumpTable(object, "", "", cache)
	printer(content)
end

TableUtil.pairsByKey = function(object, keySort)
	assert(type(object) == "table")
	assert(type(keySort) == "function", "Key sort must be a function")

	local keyArray = {}
	for key in pairs(object) do
		table.insert(keyArray, key)
	end
	table.sort(keyArray, keySort)

	local idx = 0			-- iterator variable
	local iter = function()	-- iterator function
		idx = idx + 1
		if keyArray[idx] == nil then
			return nil
		else
			return keyArray[idx], object[keyArray[idx]]
		end
	end
	return iter
end

TableUtil.pairsByValue = function(object, valueSort)
	assert(type(object) == "table")
	assert(type(valueSort) == "function", "Value sort must be a function")

	local valueArray, reversedObject = {}, {}
	for key, value in pairs(object) do
		table.insert(valueArray, value)
		reversedObject[value] = key
	end
	table.sort(valueArray, valueSort)

	local idx = 0
	local iter = function()
		idx = idx + 1
		if valueArray[idx] == nil then
			return nil
                else
                        return reversedObject[valueArray[idx]], valueArray[idx]
                end
        end
        return iter
end


-- bubble sort for in-place and stable
TableUtil.sortOn = function(arr, key)
	assert(type(arr) == "table")

	local n = #arr
	for i = 1, n do
		local m = i + 1
		for j = n, m, -1 do
			local obj1 = arr[j]
			local obj2 = arr[j - 1]
			if obj1[key] < obj2[key] then
				arr[j] = obj2
				arr[j - 1] = obj1
			end
		end
	end
end

TableUtil.sortOnFunc = function(arr, func, key)
	local n = #arr
	for i = 1, n do
		local m = i + 1
		for j = n, m, -1 do
			local obj1 = arr[j]
			local obj2 = arr[j - 1]
			if obj1[func](obj1, key) < obj2[func](obj2, key) then
				arr[j] = obj2
				arr[j - 1] = obj1
			end
		end
	end
end

TableUtil.reverse = function(arr)
	local n = #arr
	for i = 1, math.floor(n / 2) do
		local k = n - i + 1
		local tmp = arr[i]
		arr[i] = arr[k]
		arr[k] = tmp
	end
end

TableUtil.len = function(tbl)
	if tbl == nil then return nil end
	local i = 0
	for k,v in pairs(tbl) do
		i = i + 1
	end
	return i
end

TableUtil.keys = function(tbl)
	local kt = {}
	local i = 1
	for k,_ in pairs(tbl) do
		kt[i] = k
		i = i + 1
	end
	return unpack(kt)
end

TableUtil.indexOf = function(arr, obj)
	assert(type(arr) == "table")

	local n = #arr
	for i = 1, n do
		local value = arr[i]
		if value == obj then
			return i
		end
	end

	return -1
end
