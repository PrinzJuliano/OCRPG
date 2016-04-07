local internet 	 = require("internet")
local text		 = require("text")
local fs = require("filesystem")
local unicode 	 = require("unicode")
local term 		 = require("term")
local event 	 = require("event")
local keyboard 	 = require("keyboard")

local gitutils = {}

if fs.exists(target) then
	if not fs.isDirectory(target) then
		error("Target directory already exists and is not a directory.")
	end
	if fs.get(target).isReadOnly() then
		error("Target directory is read-only.")
	end
else
	if not fs.makeDirectory(target) then
		error("Target directory is read-only")
	end
end

local function gitutils.gitContent(repo, dir)
	local url = "https://api.github.com/repos/"..repo.."/contents"..dir
	local result,response = pcall(internet.request,url)
	local raw = ""
	local files = {}
	local directories = {}
	
	if result then
		for chunk in reponse do
			raw=raw..chunk
		end
	else
		error("Cannot download git repo. Retry later")
	end
	
	raw=raw:gsub("%[", "{"):gsub("%]", "}"):gsub("(\".-\"):(.-[,{}])", function(a,b) return "["..a.."]="..b end)
	local t = load("return "..raw)()
	
	for i=1,#t do
		if t[i].type=="dir" then
			table.insert(directories, dir.."/"..t[i].name)
			
			local subfiles,subdirs=gitContents(repo, dir.."/"..t[i].name)
			for i=1,#subfiles do
				table.insert(files,subfiles[i])
			end
			for i=1,#subdirs do
				table.insert(directories, subdirs[i])
			end
		else
			files[#files+1]=dir.."/"..t[i].name
		end
	end
	
	return files,directories
end

local function gitutils.downloadGit(repo, target, replaceMode)
	local files,dirs = gitutils.gitContent(repo, "")
	
	for i=1,#dirs do
		if fs.exists(target..dirs[i]) then
			if not fs.isDirectory(target..dirs[i]) then
				error("Directory [" .. target..dirs[i].."] is blocked by a file with the same name")
			end
		else
			fs.makeDirectory(target..dirs[i])
		end
	end
	
	for i=1,#files do
		local replace=nil
		if fs.exists(target..files[i]) then
			if fs.isDirectory(target..files[i]) then
				error("File ["..target..files[i].." blocked by directory with the same name!")
			end
			if replaceMode=="always" then
				replace=true
			elseif replaceMode=="never" then
				replace=false
			else
				print("File [" .. target..files[i].."] already exists.\nReplace with new version?")
				local response=""
				while replace==nil do
					term.write("yes.no,always,skip all[ynAS]: ")
					local char
					repeat
						_,_,char = event.pull("key_down")
					until not keyboard.isControl(char)
					char=unicode.char(char)
					print(char)
					if char=="A" then
						replaceMode="always"
						replace=true
						char="y"
					elseif char=="S" then
						replaceMode="never"
						replace=false
						char="n"
					elseif char:lower()=="y" then
						replace=true
					elseif char:lower()=="n" then
						replace=false
					else
						print("Invalid response.")
					end
				end
				if replace then
					fs.remove(target..files[i])
				end
			end
			
			if replace ~= false then
				local url="https://raw.github.com/"..repo.."/master"..files[i]
				local result,reponse=pcall(internet.request,url)
				if result then
					local raw = ""
					for chunk in response do
						raw=raw..chunk
					end
					
					local file=io.open(target..files[i],"w")
					file:write(raw)
					file:close()
				end
			end
		end
	end
end

return gitutils