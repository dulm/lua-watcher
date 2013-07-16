---@auther lqk
---@email dulmdev@gmail.com
---Require all the scripts in specific directory recursively


local lfs = require 'lfs'
--require 'util.StringUtil'
local binPath = lfs.currentdir().."/"
local rootPath = binPath:sub(1, binPath:len()-11)
local scriptPath = rootPath.."script/"
print(binPath, rootPath, scriptPath)



RequireDir =
{
	---服务器主程序的相对位置，而不是此脚本的相对位置
	--root = "../script/"
}

--you need to change it to your script's root
RequireDir.root = scriptPath




--logPrint(lfs.attributes)

--root = "E:/Project/Tale/Server/trunk/script/"
--root = "../../"
-- local root = "../script/"

--lfs.chdir ("../../")
--root = lfs.currentdir()


--for file in lfs.dir(root) do
--	logPrint(file)
--end

--xx.xx 转成 path
local function RequireDir.resolvePath(dirstr)
	return RequireDir.root..dirstr:gsub("%.", "/")
end

--把字符串里的-替换为%-，防止find出错
local function encodeSpecString(str)
	local str = str:gsub('-', '%%-')
	return str
end

--文件path转成require用的 xxx.xx.xx
local function RequireDir.pathToPack(path)
	local root = RequireDir.root
	local i = path:find(encodeSpecString(root))
	if i ~= 1 then
		return nil
	end
	local p = path:sub(root:len() + 1):gsub('/', '.')
	--print(p)
	if p:sub(p:len()) == '.' then
		p = p:sub(1, p:len()-1)
	end
	--print(p)
	if p:sub(p:len() - 3) == '.lua' then
		p = p:sub(1, p:len() - 4)
	end
	return p
end


--print(scriptPath.."util/TemplateReader.lua")
--print(RequireDir.pathToPack(scriptPath.."util/TemplateReader.lua"))


local function RequireDir.reqDir(path)
	for file in lfs.dir(path) do
		if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            print ("\t "..f)
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                RequireDir.reqDir(f)
            else
				local i = f:find('%.lua')
				print(i)
				if i == nil then
					return
				end
				if f:sub(i+1) == 'lua' then
					local packname = RequireDir.pathToPack(f)
					--print1(packname)
					require(packname)
				end
            end
        end
	end
end


--@usage requireDir("util.bt")
--excludeList not implimented yet
function requireDir(dirstr, excludeList)
	--print1(debug.traceback())
	print1(dirstr, SceneId)
	RequireDir.reqDir(RequireDir.resolvePath(dirstr))
end
