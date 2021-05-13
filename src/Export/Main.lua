-- Dat View
--
-- Module: Main
-- Main module of program.
--

USE_DAT64 = true

local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_ceil = math.ceil
local m_max = math.max
local m_min = math.min
local m_sin = math.sin
local m_cos = math.cos
local m_pi = math.pi

LoadModule("../Modules/Common.lua")

LoadModule("../Classes/ControlHost.lua")

main = new("ControlHost")

local classList = {
	"UndoHandler",
	"Tooltip",
	"TooltipHost",
	"SearchHost",
	-- Basic controls
	"Control",
	"LabelControl",
	"SectionControl",
	"ButtonControl",
	"CheckBoxControl",
	"EditControl",
	"DropDownControl",
	"ScrollBarControl",
	"SliderControl",
	"TextListControl",
	"ListControl",
	"PathControl",
	-- Misc
	"PopupDialog",
}
local ourClassList = {
	"ScriptListControl",
	"DatListControl",
	"RowListControl",
	"SpecColListControl",
	"DatFile",
	"Dat64File",
	"GGPKData",
}
for _, className in ipairs(classList) do
	LoadModule("../Classes/"..className..".lua", launch, main)
end
for _, className in ipairs(ourClassList) do
	LoadModule("Classes/"..className, launch, main)
end

local tempTable1 = { }
local tempTable2 = { }

function main:Init()
	self.inputEvents = { }
	self.popups = { }

	local f = io.open("spec.toml", "r")
	local data = f:read("*a")
	f:close()
	self.datSpecs = common.toml.parse(data, { strict = false })

	self.datFileList = { }
	self.datFileByName = { }

	self:LoadSettings()

	if USE_DAT64 then
		self:LoadDat64Files()
	else
		self:LoadDatFiles()
	end

	self.scriptList = { }
	local handle = NewFileSearch("Scripts/*.lua")
	while handle do
		t_insert(self.scriptList, (handle:GetFileName():gsub("%.lua","")))
		if not handle:NextFile() then
			break
		end
	end
	self.scriptOutput = { }

	function print(text)
		for line in text:gmatch("[^\r\n]+") do
			t_insert(self.scriptOutput, { "^7"..line, height = 14 })
		end
		self.controls.scriptOutput.controls.scrollBar.offset = 10000000
	end
	function printf(...)
		print(string.format(...))
	end
	function processTemplateFile(name, inDir, outDir, directiveTable)
		local state = { }
		local out = io.open(outDir..name..".lua", "w")
		out:write("-- This file is automatically generated, do not edit!\n")
		for line in io.lines(inDir..name..".txt") do
			local spec, args = line:match("#(%a+) ?(.*)")
			if spec then
				if directiveTable[spec] then
					directiveTable[spec](state, args, out)
				else
					printf("Unknown directive '%s'", spec)
				end
			else
				out:write(line, "\n")
			end
		end
		out:close()
	end
	function dat(name)
		if #self.datFileList == 0 then
			error("No .dat files loaded; set GGPK path first")
		end
		if not self.datFileByName[name] then
			error(name..".dat not found")
		end
		return self.datFileByName[name]
	end
	function getFile(name)
		if not self.ggpk then
			error("GGPK not loaded; set path first")
		end
		if not self.ggpk.txt[name] then
			local f = io.open(self.ggpk.oozPath .. name, 'rb')
			if f then
				self.ggpk.txt[name] = f:read("*all")
				f:close()
			else
				ConPrintf("Cannot Find File: %s", self.ggpk.oozPath .. name)
			end
		end
		return self.ggpk.txt[name]
	end

	self.typeDrop = { "Bool", "Int", "UInt", "Interval", "Float", "String", "Enum", "Key" }

	self.colList = { }

	self.controls.datSourceLabel = new("LabelControl", nil, 10, 10, 100, 16, "^7GGPK/Steam PoE path:")
	self.controls.datSource = new("EditControl", nil, 10, 30, 250, 18, self.datSource) {
		enterFunc = function(buf)
			self.datSource = buf
			if USE_DAT64 then
				self:LoadDat64Files()
			else
				self:LoadDatFiles()
			end
		end
	}

	self.controls.scripts = new("ButtonControl", nil, 160, 10, 100, 18, "Scripts >>", function()
		self:SetCurrentDat()
	end)

	self.controls.scriptList = new("ScriptListControl", nil, 270, 10, 100, 300) {
		shown = function()
			return not self.curDatFile
		end
	}
	self.controls.scriptOutput = new("TextListControl", nil, 380, 10, 800, 600, nil, self.scriptOutput) {
		shown = function()
			return not self.curDatFile
		end
	}

	self.controls.datList = new("DatListControl", nil, 10, 50, 250, function() return self.screenH - 60 end)

	self.controls.specEditToggle = new("ButtonControl", nil, 270, 10, 100, 18, function() return self.editSpec and "Done <<" or "Edit >>" end, function()
		self.editSpec = not self.editSpec
		if self.editSpec then
			self:SetCurrentCol(1)
		end
	end) {
		shown = function()
			return self.curDatFile
		end
	}
	self.controls.specColList = new("SpecColListControl", {"TOPLEFT",self.controls.specEditToggle,"BOTTOMLEFT"}, 0, 2, 200, 200) {
		shown = function()
			return self.editSpec
		end
	}

	self.controls.colName = new("EditControl", {"TOPLEFT",self.controls.specColList,"TOPRIGHT"}, 10, 0, 150, 18, nil, nil, nil, nil, function(buf)
		self.curSpecCol.name = buf
		self.curDatFile:OnSpecChanged()
		self.controls.rowList:BuildColumns()
	end) {
		shown = function()
			return self.curSpecCol
		end
	}

	self.controls.colType = new("DropDownControl", {"TOPLEFT",self.controls.colName,"BOTTOMLEFT"}, 0, 4, 90, 18, self.typeDrop, function(_, value)
		self.curSpecCol.type = value
		self.curDatFile:OnSpecChanged()
		self:UpdateCol()
	end)

	self.controls.colIsList = new("CheckBoxControl", {"TOPLEFT",self.controls.colType,"BOTTOMLEFT"}, 30, 4, 18, "List:", function(state)
		self.curSpecCol.list = state
		self.curDatFile:OnSpecChanged()
		self.controls.rowList:BuildColumns()
	end)

	self.controls.colRefTo = new("EditControl", {"TOPLEFT",self.controls.colType,"BOTTOMLEFT"}, 0, 26, 150, 18, nil, nil, nil, nil, function(buf)
		self.curSpecCol.refTo = buf
		self.curDatFile:OnSpecChanged()
	end)

	self.controls.colWidth = new("EditControl", {"TOPLEFT",self.controls.colRefTo,"BOTTOMLEFT"}, 0, 4, 100, 18, nil, nil, "%D", nil, function(buf)
		self.curSpecCol.width = m_max(tonumber(buf) or 150, 20)
		self.controls.rowList:BuildColumns()
	end) { numberInc = 10 }

	self.controls.colDelete = new("ButtonControl", {"BOTTOMRIGHT",self.controls.colName,"TOPRIGHT"}, 0, -4, 18, 18, "x", function()
		t_remove(self.curDatFile.spec, self.curSpecColIndex)
		self.curDatFile:OnSpecChanged()
		self.controls.rowList:BuildColumns()
		self:SetCurrentCol()
	end)
	
	self.controls.filter = new("EditControl", nil, 270, 0, 300, 18, nil, "^8Filter") {
		y = function()
			return self.editSpec and 240 or 30
		end,
		shown = function()
			return self.curDatFile
		end,
		enterFunc = function(buf)
			self.controls.rowList:BuildRows(buf)
			self.curDatFile.rowFilter = buf
		end,
	}
	self.controls.filterError = new("LabelControl", {"LEFT",self.controls.filter,"RIGHT"}, 4, 2, 0, 14, "")

	self.controls.rowList = new("RowListControl", nil, 270, 0, 0, 0) {
		y = function()
			return self.editSpec and 260 or 50
		end,
		width = function()
			return self.screenW - 280
		end,
		height = function()
			return self.screenH - (self.editSpec and 270 or 60)
		end,
		shown = function()
			return self.curDatFile
		end
	}

	self.controls.addCol = new("ButtonControl", {"LEFT",self.controls.specEditToggle,"RIGHT"}, 10, 0, 80, 18, "Add", function()
		self:AddSpecCol()
	end) {
		shown = function()
			return self.editSpec
		end,
		enabled = function()
			return self.curDatFile.specSize < self.curDatFile.rowSize
		end
	}
end

function main:CanExit()
	return true
end

function main:Shutdown()
	local out = io.open("spec.toml", "w")
	out:write(common.toml.encode(self.datSpecs))
	out:close()

	self:SaveSettings()
end

function main:OnFrame()
	self.screenW, self.screenH = GetScreenSize()

	self.viewPort = { x = 0, y = 0, width = self.screenW, height = self.screenH }

	if self.popups[1] then
		self.popups[1]:ProcessInput(self.inputEvents, self.viewPort)
		wipeTable(self.inputEvents)
	else
		self:ProcessControlsInput(self.inputEvents, self.viewPort)
	end

	self:DrawControls(self.viewPort)

	wipeTable(self.inputEvents)
end

function main:OnKeyDown(key, doubleClick)
	t_insert(self.inputEvents, { type = "KeyDown", key = key, doubleClick = doubleClick })
end

function main:OnKeyUp(key)
	t_insert(self.inputEvents, { type = "KeyUp", key = key })
end

function main:OnChar(key)
	t_insert(self.inputEvents, { type = "Char", key = key })
end

function main:LoadDatFiles()
	wipeTable(self.datFileList)
	wipeTable(self.datFileByName)
	self:SetCurrentDat()
	self.ggpk = nil

	if not self.datSource then
		return
	elseif self.datSource:match("%.ggpk") or self.datSource:match("steamapps[/\\].+[/\\]Path of Exile") then
		local now = GetTime()
		self.ggpk = new("GGPKData", self.datSource)
		ConPrintf("GGPK: %d ms", GetTime() - now)

		now = GetTime()
		for i, record in ipairs(self.ggpk.dat) do
			if i == 1 then
				ConPrintf("DAT find: %d ms", GetTime() - now)
				now = GetTime()
			end
			local datFile = new("DatFile", record.name:gsub("%.dat$",""), record.data)
			t_insert(self.datFileList, datFile)
			self.datFileByName[datFile.name] = datFile
		end
		ConPrintf("DAT read: %d ms", GetTime() - now)
	end
end

function main:LoadDat64Files()
	wipeTable(self.datFileList)
	wipeTable(self.datFileByName)
	self:SetCurrentDat()
	self.ggpk = nil

	if not self.datSource then
		return
	elseif self.datSource:match("%.ggpk") or self.datSource:match("steamapps[/\\].+[/\\]Path of Exile") then
		local now = GetTime()
		self.ggpk = new("GGPKData", self.datSource)
		ConPrintf("GGPK: %d ms", GetTime() - now)

		now = GetTime()
		for i, record in ipairs(self.ggpk.dat) do
			if i == 1 then
				ConPrintf("DAT64 find: %d ms", GetTime() - now)
				now = GetTime()
			end
			local datFile = new("Dat64File", record.name:gsub("%.dat64$",""), record.data)
			t_insert(self.datFileList, datFile)
			self.datFileByName[datFile.name] = datFile
		end
		ConPrintf("DAT64 read: %d ms", GetTime() - now)
	end
end

function main:SetCurrentDat(datFile)
	self.curDatFile = datFile
	if datFile then
		self.controls.filter.buf = datFile.rowFilter or ""
		self.controls.rowList:BuildRows(self.controls.filter.buf)
		self.controls.rowList:BuildColumns()
		self.controls.specColList.list = datFile.spec
		self:SetCurrentCol(1)
	end
end

function main:AddSpecCol()
	t_insert(self.curDatFile.spec, {
		name = "",
		type = "Int",
		list = false,
		refTo = "",
		width = 150,
	})
	self.curDatFile:OnSpecChanged()
	self:SetCurrentCol(#self.curDatFile.spec)
	self.controls.specColList:SelectIndex(self.curSpecColIndex)
end

function main:SetCurrentCol(index)
	self.curSpecColIndex = index
	self.curSpecCol = self.curDatFile.spec[index]
	if self.curSpecCol then
		self:UpdateCol()
	end
end

function main:UpdateCol()
	self.controls.colName:SetText(self.curSpecCol.name)
	self.controls.colType:SelByValue(self.curSpecCol.type)
	self.controls.colIsList.state = self.curSpecCol.list
	self.controls.colRefTo.enabled = self.curDatFile.cols[self.curSpecColIndex].isRef
	self.controls.colRefTo:SetText(self.curSpecCol.refTo)
	self.controls.colWidth:SetText(self.curSpecCol.width)
	self.controls.rowList:BuildColumns()
end

function main:LoadSettings()
	local setXML, errMsg = common.xml.LoadXMLFile("Settings.xml")
	if not setXML then
		return true
	elseif setXML[1].elem ~= "DatView" then
		launch:ShowErrMsg("^1Error parsing 'Settings.xml': 'DatView' root element missing")
		return true
	end
	for _, node in ipairs(setXML[1]) do
		if type(node) == "table" then
			if node.elem == "DatSource" then
				self.datSource = node.attrib.path
			end
		end
	end
end

function main:SaveSettings()
	local setXML = { elem = "DatView" }
	t_insert(setXML, { elem = "DatSource", attrib = { path = self.datSource } })
	local res, errMsg = common.xml.SaveXMLFile(setXML, "Settings.xml")
	if not res then
		launch:ShowErrMsg("Error saving 'Settings.xml': %s", errMsg)
		return true
	end
end

function main:DrawArrow(x, y, width, height, dir)
	local x1 = x - width / 2
	local x2 = x + width / 2
	local xMid = (x1 + x2) / 2
	local y1 = y - height / 2
	local y2 = y + height / 2
	local yMid = (y1 + y2) / 2
	if dir == "UP" then
		DrawImageQuad(nil, xMid, y1, xMid, y1, x2, y2, x1, y2)
	elseif dir == "RIGHT" then
		DrawImageQuad(nil, x1, y1, x2, yMid, x2, yMid, x1, y2)
	elseif dir == "DOWN" then
		DrawImageQuad(nil, x1, y1, x2, y1, xMid, y2, xMid, y2)
	elseif dir == "LEFT" then
		DrawImageQuad(nil, x1, yMid, x2, y1, x2, y2, x1, yMid)
	end
end

function main:DrawCheckMark(x, y, size)
	size = size / 0.8
	x = x - size / 2
	y = y - size / 2
	DrawImageQuad(nil, x + size * 0.15, y + size * 0.50, x + size * 0.30, y + size * 0.45, x + size * 0.50, y + size * 0.80, x + size * 0.40, y + size * 0.90)
	DrawImageQuad(nil, x + size * 0.40, y + size * 0.90, x + size * 0.35, y + size * 0.75, x + size * 0.80, y + size * 0.10, x + size * 0.90, y + size * 0.20)
end

do
	local cos45 = m_cos(m_pi / 4)
	local cos35 = m_cos(m_pi * 0.195)
	local sin35 = m_sin(m_pi * 0.195)
	function main:WorldToScreen(x, y, z, width, height)
		-- World -> camera
		local cx = (x - y) * cos45
		local cy = -5.33 - (y + x) * cos45 * cos35 - z * sin35
		local cz = 122 + (y + x) * cos45 * sin35 - z * cos35
		-- Camera -> screen
		local sx = width * 0.5 + cx / cz * 1.27 * height
		local sy = height * 0.5 + cy / cz * 1.27 * height
		return round(sx), round(sy)
	end
end

function main:RenderCircle(x, y, width, height, oX, oY, radius)
	local minX = wipeTable(tempTable1)
	local maxX = wipeTable(tempTable2)
	local minY = height
	local maxY = 0
	for d = 0, 360, 0.15 do
		local r = d / 180 * m_pi
		local px, py = main:WorldToScreen(oX + m_sin(r) * radius, oY + m_cos(r) * radius, 0, width, height)
		if py >= 0 and py < height then
			px = m_min(width, m_max(0, px))
			minY = m_min(minY, py)
			maxY = m_max(maxY, py)
			minX[py] = m_min(minX[py] or px, px)
			maxX[py] = m_max(maxX[py] or px, px)
		end
	end
	for ly = minY, maxY do
		if minX[ly] then
			DrawImage(nil, x + minX[ly], y + ly, maxX[ly] - minX[ly] + 1, 1)
		end
	end
end

function main:RenderRing(x, y, width, height, oX, oY, radius, size)
	local lastX, lastY
	for d = 0, 360, 0.2 do
		local r = d / 180 * m_pi
		local px, py = main:WorldToScreen(oX + m_sin(r) * radius, oY + m_cos(r) * radius, 0, width, height)
		if px >= -size/2 and px < width + size/2 and py >= -size/2 and py < height + size/2 and (px ~= lastX or py ~= lastY) then
			DrawImage(nil, x + px - size/2, y + py, size, size)
			lastX, lastY = px, py
		end
	end
end

function main:MoveFolder(name, srcPath, dstPath)
	-- Create destination folder
	local res, msg = MakeDir(dstPath..name)
	if not res then
		self:OpenMessagePopup("Error", "Couldn't move '"..name.."' to '"..dstPath.."' : "..msg)
		return
	end

	-- Move subfolders
	local handle = NewFileSearch(srcPath..name.."/*", true)
	while handle do
		self:MoveFolder(handle:GetFileName(), srcPath..name.."/", dstPath..name.."/")
		if not handle:NextFile() then
			break
		end
	end

	-- Move files
	handle = NewFileSearch(srcPath..name.."/*") 
	while handle do
		local fileName = handle:GetFileName()
		local srcName = srcPath..name.."/"..fileName
		local dstName = dstPath..name.."/"..fileName
		local res, msg = os.rename(srcName, dstName)
		if not res then
			self:OpenMessagePopup("Error", "Couldn't move '"..srcName.."' to '"..dstName.."': "..msg)
			return
		end
		if not handle:NextFile() then
			break
		end		
	end

	-- Remove source folder
	local res, msg = RemoveDir(srcPath..name)
	if not res then
		self:OpenMessagePopup("Error", "Couldn't delete '"..dstPath..name.."' : "..msg)
		return
	end
end

function main:CopyFolder(srcName, dstName)
	-- Create destination folder
	local res, msg = MakeDir(dstName)
	if not res then
		self:OpenMessagePopup("Error", "Couldn't copy '"..srcName.."' to '"..dstName.."' : "..msg)
		return
	end

	-- Copy subfolders
	local handle = NewFileSearch(srcName.."/*", true)
	while handle do
		local fileName = handle:GetFileName()
		self:CopyFolder(srcName.."/"..fileName, dstName.."/"..fileName)
		if not handle:NextFile() then
			break
		end
	end

	-- Copy files
	handle = NewFileSearch(srcName.."/*") 
	while handle do
		local fileName = handle:GetFileName()
		local srcName = srcName.."/"..fileName
		local dstName = dstName.."/"..fileName
		local res, msg = copyFile(srcName, dstName)
		if not res then
			self:OpenMessagePopup("Error", "Couldn't copy '"..srcName.."' to '"..dstName.."': "..msg)
			return
		end
		if not handle:NextFile() then
			break
		end		
	end
end

function main:OpenPopup(width, height, title, controls, enterControl, defaultControl, escapeControl)
	local popup = new("PopupDialog", width, height, title, controls, enterControl, defaultControl, escapeControl)
	t_insert(self.popups, 1, popup)
	return popup
end

function main:ClosePopup()
	t_remove(self.popups, 1)
end

function main:OpenMessagePopup(title, msg)
	local controls = { }
	local numMsgLines = 0
	for line in string.gmatch(msg .. "\n", "([^\n]*)\n") do
		t_insert(controls, new("LabelControl", nil, 0, 20 + numMsgLines * 16, 0, 16, line))
		numMsgLines = numMsgLines + 1
	end
	controls.close = new("ButtonControl", nil, 0, 40 + numMsgLines * 16, 80, 20, "Ok", function()
		main:ClosePopup()
	end)
	return self:OpenPopup(m_max(DrawStringWidth(16, "VAR", msg) + 30, 190), 70 + numMsgLines * 16, title, controls, "close")
end

function main:OpenConfirmPopup(title, msg, confirmLabel, onConfirm)
	local controls = { }
	local numMsgLines = 0
	for line in string.gmatch(msg .. "\n", "([^\n]*)\n") do
		t_insert(controls, new("LabelControl", nil, 0, 20 + numMsgLines * 16, 0, 16, line))
		numMsgLines = numMsgLines + 1
	end
	local confirmWidth = m_max(80, DrawStringWidth(16, "VAR", confirmLabel) + 10)
	controls.confirm = new("ButtonControl", nil, -5 - m_ceil(confirmWidth/2), 40 + numMsgLines * 16, confirmWidth, 20, confirmLabel, function()
		main:ClosePopup()
		onConfirm()
	end)
	t_insert(controls, new("ButtonControl", nil, 5 + m_ceil(confirmWidth/2), 40 + numMsgLines * 16, confirmWidth, 20, "Cancel", function()
		main:ClosePopup()
	end))
	return self:OpenPopup(m_max(DrawStringWidth(16, "VAR", msg) + 30, 190), 70 + numMsgLines * 16, title, controls, "confirm")
end

function main:OpenNewFolderPopup(path, onClose)
	local controls = { }
	controls.label = new("LabelControl", nil, 0, 20, 0, 16, "^7Enter folder name:")
	controls.edit = new("EditControl", nil, 0, 40, 350, 20, nil, nil, "\\/:%*%?\"<>|%c", 100, function(buf)
		controls.create.enabled = buf:match("%S")
	end)
	controls.create = new("ButtonControl", nil, -45, 70, 80, 20, "Create", function()
		local newFolderName = controls.edit.buf
		local res, msg = MakeDir(path..newFolderName)
		if not res then
			main:OpenMessagePopup("Error", "Couldn't create '"..newFolderName.."': "..msg)
			return
		end
		if onClose then
			onClose(newFolderName)
		end
		main:ClosePopup()
	end)
	controls.create.enabled = false
	controls.cancel = new("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
		if onClose then
			onClose()
		end
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, "New Folder", controls, "create", "edit", "cancel")	
end

do
	local wrapTable = { }
	function main:WrapString(str, height, width)
		wipeTable(wrapTable)
		local lineStart = 1
		local lastSpace, lastBreak
		while true do
			local s, e = str:find("%s+", lastSpace)
			if not s then
				s = #str + 1
				e = #str + 1
			end
			if DrawStringWidth(height, "VAR", str:sub(lineStart, s - 1)) > width then
				t_insert(wrapTable, str:sub(lineStart, lastBreak))
				lineStart = lastSpace
			end
			if s > #str then
				t_insert(wrapTable, str:sub(lineStart, -1))
				break
			end
			lastBreak = s - 1
			lastSpace = e + 1
		end
		return wrapTable
	end
end

return main
