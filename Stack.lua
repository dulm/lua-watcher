Stack = {}

function Stack:new(o)
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	return o
end

function Stack:push(...)
	for _, v in ipairs{...} do
		self[#self+1] = v
	end
end

function Stack:pop(num)
	local num = num or 1
	if num > #self then
		print1("underflow in NewStack-created stack")
		print1(debug.traceback())
		return
	end
	local ret = {}
	for i = num, 1, -1 do
		ret[#ret+1] = table.remove(self)
	end
	return unpack(ret)
end
