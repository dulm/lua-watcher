---@auther lqk
---@email dulmdev@gmail.com

--Simply use debug.sethook with "crl" may print too many funcnames, with not intendation.
--Some times we just want to print funcs in some specifice files, and formate it with intendation.
--compatible with lua5.2

local dprint = print
require 'TableUtil'
require 'Stack'
require 'RequireDir'


local function capture_vars()
	local vars = {}
	local func = debug.getinfo(3, "f").func
	local i = 1
	while true do
		local name, value = debug.getupvalue(func, i)
		if not name then break end
		vars[name] = value
		i = i + 1
	end
	i = 1
	while true do
		local name, value = debug.getlocal(3, i)
		if not name then break end
		vars[name] = value
		i = i + 1
	end
	--setmetatable(vars, { __index = getfenv(func), __newindex = getfenv(func) })
	return vars
end


level = -1
callstack = Stack:new()


---use debug.sethook() to cancel hook, run in lua5.2
--@param fileContains filepath contains strings
--@param fileExclude filepath exclude strings
--@param breturn whether print info when func return
--@param lines at thease lines print all the watchVars
--@usage fileContains = {"FBManager", "FBMap"}; breturn = true ; lines={44,55} ; watchVars ={"var1" , "obj1.var2", "var1 + var2"}
--@usage debug.sethook(getHookFunc(fileContains, {"FBMapManager"},  funcExclude, true, lines, watchVars), 'crl')
function getHookFunc(fileContains, fileExclude, funcExclude, breturn, lines, watchVars)
	debug.sethook()
	--catched matched fileNames
	local matchedFiles = {}

	local lineSet = {}
	if lines ~= nil then
		for i, line in pairs(lines) do
			lineSet[line] = true
		end
	end

	local watchSet = {}
	if watchVars ~= nil then
		for i, varName in pairs(watchVars) do
			local func = loadstring("return (" .. varName .. ")")
			watchSet[varName] = func
		end
	end

	local function isMatch(fileName)
		if matchedFiles[fileName] == nil then
			local toCap = false
			for i, name in pairs(fileContains) do
				if fileName:find(name) then
					matchedFiles[fileName] = true
					toCap = true
					break
				end
			end
			if toCap == false then
				matchedFiles[fileName] = false
			end

			if toCap == true then
				for i, name in pairs(fileExclude) do
					if fileName:find(name) then
						matchedFiles[fileName] = false
						break
					end
				end
			end
		end
		return matchedFiles[fileName]
	end

--	local level = -1
--	local callstack = Stack:new()

	function callPrint(funcLV)
		local callerLV = funcLV + 1
		if not isMatch(debug.getinfo(funcLV,"S").source) then
			return false
		end
		if funcExclude[tostring(debug.getinfo(funcLV,"n").name)] ~= nil then
			return false
		end

		level = level + 1
		local prefix = string.rep("\t", level)

		local fullFile1 = ((debug.getinfo(callerLV,"S") and debug.getinfo(callerLV,"S").source) or "22"):sub(2)
		local packName1 = RequireDir.pathToPack(fullFile1)
		if packName1 ~= nil then
			packName1 = packName1:split('%.')
			packName1 = packName1[#packName1]
		end

		local fullFile2 = debug.getinfo(funcLV,"S").source:sub(2)
		local packName2 = RequireDir.pathToPack(fullFile2)
		if packName2 ~= nil then
			packName2 = packName2:split('%.')
			packName2 = packName2[#packName2]
		end


		local callstr = ""
		debug.getinfo(funcLV, "n")
		local fullFile = debug.getinfo(funcLV,"S").source:sub(2)

		-- callstr = packName1.."."..(debug.getinfo(3,"n").name or "globle").." "..debug.getinfo(3,"l").currentline..
		-- 	"->"..tostring(packName2).."."..debug.getinfo(2,"n").name

		if level < 1 then
			callstr = tostring(packName1).."."..
						((debug.getinfo(callerLV,"n") and debug.getinfo(callerLV,"n").name) or "globle").." "
		end


		callstr = callstr..
			((debug.getinfo(callerLV,"l") and debug.getinfo(callerLV,"l").currentline) or "")..
			"->"..tostring(packName2).."."..tostring(debug.getinfo(funcLV,"n").name)

		local paramstr = "("
		local np = debug.getinfo(funcLV,"u").nparams
		if np > 0 then
			for i = 1, np do
				local pname, pvalue = debug.getlocal(funcLV, i)
				if pname ~= "self" and pvalue ~= "nil" then
					if type(pvalue) == "table" then
						pvalue = "{}"
					end
					paramstr = paramstr..pname.."="..tostring(pvalue)..","
				end
			end
		end
		paramstr = paramstr..")"
		callstr = callstr .. paramstr
		callstack:push(callstr)
		dprint(prefix..callstr)
	end

	function returnPrint(funcLV)
		if not isMatch(debug.getinfo(funcLV,"S").source) then
			return false
		end
		if funcExclude[tostring(debug.getinfo(funcLV,"n").name)] ~= nil then
			return false
		end

		local prefix = string.rep("\t", level)
		local retstr = debug.getinfo(funcLV,"l").currentline..":".."return"
		if debug.getinfo(funcLV,"l").currentline ~= -1 then
			local callstr = callstack:pop()
			if breturn == true then
				dprint(prefix .. (callstr or "") .. "->" ..retstr)
			end
		end

		level = level - 1
	end


	function hookFunc(mode, line)
		if mode == "call" then
			callPrint(3)
		elseif mode == "return" or mode == "tail return" then
			returnPrint(3)
		elseif mode == "tail call" then

			local bCaller = true
			if not isMatch(debug.getinfo(3,"S").source) then
				bCaller = false
			end
			if funcExclude[tostring(debug.getinfo(3,"n").name)] ~= nil then
				bCaller = false
			end

			local bTailFunc = true
			if not isMatch(debug.getinfo(2,"S").source) then
				bTailFunc = false
			end
			if funcExclude[tostring(debug.getinfo(2,"n").name)] ~= nil then
				bTailFunc = false
			end


			--tailFunc的return 作为caller的return，这里信息缩进一行输出，不做为任何方的call或return
			if (bCaller and bTailFunc) then
				level = level + 1
				local prefix = string.rep("\t", level)
				local retstr = debug.getinfo(3,"l").currentline..":".."tail call"
				if debug.getinfo(3,"l").currentline ~= -1 then
					local callstr = callstack:pop()
					callstack:push(callstr)
					if breturn == true then
						dprint(prefix .. (callstr or "") .. "->" ..retstr)
						dprint(prefix.."Real caller for belowe:",debug.getinfo(2,"S").source,
							debug.getinfo(2,"n").name,
							debug.getinfo(2,"l").currentline)
					end
				end

				level = level - 1
			end

			--tailFunc的return没了，所以这里的信息作为caller的return
			if bCaller == true and bTailFunc == false then
				returnPrint(4)
			end

			--这里作为tailFunc的调用处
			if bCaller == false and bTailFunc == true then
				callPrint(3)
			end


		elseif mode == "line" then
			if not isMatch(debug.getinfo(2,"S").source) then
				return false
			end
			if funcExclude[tostring(debug.getinfo(2,"n").name)] ~= nil then
				return false
			end

			local curLine = debug.getinfo(2,"l").currentline
			if lineSet[curLine] == nil then
				return false
			end
			local prefix = string.rep("\t", level)
			dprint(prefix.."Line matched", curLine, debug.getinfo(2,"S").source:sub(2))
			local vars = capture_vars()
			-- for varName, varValue in pairs(vars) do
			-- 	dprint(varName, varValue)
			-- end
			for exp, func in pairs(watchSet) do
				setfenv(func, vars)
				local status, res = xpcall(func, debug.traceback)
				if status == true then
					if type(res) ~= "table" then
						dprint(prefix..exp.."="..tostring(res))
					else
						dprint(prefix..exp.."=")
						TableUtil.print(res, dprint)
					end
				end
			end
		end
	end

	return hookFunc
end
