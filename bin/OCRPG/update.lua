--[[
	updater
]]

package.loaded.gitutils = nil

local gitutils = require("OCRPG/gitutils")

local repo = "prinzjuliano/OCRPG"
local target = "/usr/"

gitutils.downloadGit(repo,target)

