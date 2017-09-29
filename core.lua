local oUF = bdCore.oUF
local grid = CreateFrame("frame", nil, UIParent)

local defaults = {}

defaults[#defaults+1] = {tab = {
	type = "tab",
	value = "Sizing & Display"
}}
defaults[#defaults+1] = {powerdisplay = {
	type = "dropdown",
	value = "None",
	options = {"None","Healers","All"},
	label = "Power Bar Display",
	tooltip = "Show mana/energy/rage bars on frames.",
	callback = function() bdCore:triggerEvent("bdGrid_update") end
}}
defaults[#defaults+1] = {num_groups = {
	type = "slider",
	value = 4,
	min = 1,
	max = 8,
	step = 1,
	label = "Default number of Groups",
	tooltip = "How many groups should be shown at a time",
	callback = function() grid:refresh() end
}}
defaults[#defaults+1] = {intel_groups = {
	type = "checkbox",
	value = true,
	label = "Automatically set group size.",
	tooltip = "When in LFR, show 5 groups, mythic show 4, etc.",
	callback = function() grid:refresh() end
}}
defaults[#defaults+1] = {width = {
	type = "slider",
	value = 60,
	min = 20,
	max = 100,
	step = 2,
	label = "Width",
	tooltip = "The width of each player in the raid frames",
	callback = function() grid:callback() end
}}
defaults[#defaults+1] = {height = {
	type = "slider",
	value = 50,
	min = 20,
	max = 100,
	step = 2,
	label = "Height",
	tooltip = "The height of each player in the raid frames",
	callback = function() grid:callback() end
}}
defaults[#defaults+1] = {hidetooltips = {
	type = "checkbox",
	value = true,
	label = "Hide Tooltips",
	tooltip = "Hide tooltips when mousing over each unit",
	callback = function() grid:refresh() end
}}
defaults[#defaults+1] = {invert = {
	type = "checkbox",
	value = false,
	label = "Invert Frame Colors",
	tooltip = "Make the main color of the frames a dark grey, and the backgrounds the class color.",
	callback = function() grid:refresh() end
}}
defaults[#defaults+1] = {roleicon = {
	type = "checkbox",
	value = false,
	label = "Show role icon for tanks and healers",
	tooltip = "Will only show icon for tanks/healers (only in groups)",
	callback = function() grid:callback() end
}}
defaults[#defaults+1] = {showsolo = {
	type = "checkbox",
	value = true,
	label = "Show raid frames when solo",
	callback = function() grid:refresh() end
}}

defaults[#defaults+1] = {tab = {
	type = "tab",
	value = "Growth & Grouping"
}}
defaults[#defaults+1] = {group_growth = {
	type = "dropdown",
	value = "Left",
	options = {"Left","Right","Upwards","Downwards"},
	label = "New group growth direction",
	tooltip = "Growth direction for when a new group is added.",
	callback = function() grid:refresh() end
}}
defaults[#defaults+1] = {new_player_reverse = {
	type = "checkbox",
	value = false,
	label = "Reverse new player growth.",
	tooltip = "When a new player is added the default growth direction is Downward or Right depending on your group growth.",
	callback = function() grid:refresh() end
}}
defaults[#defaults+1] = {group_sort = {
	type = "dropdown",
	value = "Group",
	options = {"Group","Role","Class","Name"},
	label = "Group By",
	tooltip = "Method by which the groups should be formed.",
	callback = function() grid:refresh() end
}}

-- if another bdAddon hasn't added auras to config, add them here
if (not bdCore.modules["Auras"]) then
	bdCore:addModule("Auras", bdCore.auraconfig, true)
end


bdCore:addModule("Grid", defaults)
local config = bdCore.config.profile['Grid']

-- make sizes outside of combat
function grid:frameSize(frame)
	if (InCombatLockdown()) then return end

	config = bdCore.config.profile['Grid']

	frame:SetSize(config.width, config.height)
	--frame.Health:SetSize(config.width, config.height)
	frame.Debuffs:SetSize(44, 22)
	frame.RaidTargetIndicator:SetSize(12, 12)
	frame.Short:SetWidth(config.width)
	frame.ReadyCheckIndicator:SetSize(12, 12)
	frame.ResurrectIcon:SetSize(16, 16)
	frame.ThreatIndicator:SetSize(60, 50)
	frame.Buffs:SetSize(64, 16)
	frame.Debuffs:SetSize(44, 22)
	frame.Dispel:SetSize(60, 50)
	frame.Buffs:SetPoint("TOPLEFT", frame.Health, "TOPLEFT")
	frame.Debuffs:SetPoint("CENTER", frame.Health, "CENTER")
	frame.Buffs:SetFrameLevel(27)
	frame.Debuffs:SetFrameLevel(27)
	
	if (config.powerdisplay == "None") then
		frame.Power:Hide()
	elseif (config.powerdisplay == "Healers" and role == "HEALER") then
		frame.Power:Show()
	elseif (config.powerdisplay == "All") then
		frame.Power:Show()
	end

	if (not config.roleicon) then
		frame.LFDRole:Hide()
	end
end

-- Load 
local index = 1;
function grid.layout(self, unit)
	self:RegisterForClicks('AnyDown')
	self.unit = unit
	
	if (unit == "raid" or unit == "party") then
		self.unit = "raid"..index
	else
		self.unit = unit
	end
	
	function self.configUpdate(self)
		local role = UnitGroupRolesAssigned(self.unit)
		self.Power:Hide()
		if (config.powerdisplay == "None") then
			self.Power:Hide()
		elseif (config.powerdisplay == "Healers" and role == "HEALER") then
			self.Power:Show()
		elseif (config.powerdisplay == "All") then
			self.Power:Show()
		end
	end
	
	-- Health
	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetStatusBarTexture(bdCore.media.flat)
	self.Health:SetAllPoints(self)
	self.Health.frequentUpdates = true
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.colorHealth = true
	bdCore:setBackdrop(self.Health)
	self.Health.PostUpdate = function(s, unit, min, max)
		local r, g, b = self.Health:GetStatusBarColor()
		
		if (config.invert) then
			self.Health:SetStatusBarColor(unpack(bdCore.media.backdrop))
			self.Health.background:SetVertexColor(r/2, g/2, b/2)
			self.Short:SetTextColor(r*1.1, g*1.1, b*1.1)
			--self.TotalAbsorb:SetStatusBarColor(1,1,1,.07)
		else
			self.Health:SetStatusBarColor(r/2, g/2, b/2)
			self.Health.background:SetVertexColor(unpack(bdCore.media.backdrop))
			self.Short:SetTextColor(1,1,1)
			--self.TotalAbsorb:SetStatusBarColor(.1,.1,.1,.5)
		end
	end
	
	-- Tags
	-- Status (offline/dead)
	self.Status = self.Health:CreateFontString(nil)
	self.Status:SetFont(bdCore.media.font, 12, "OUTLINE")
	self.Status:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", 0, 0)
	oUF.Tags.Events["status"] = "UNIT_HEALTH  UNIT_CONNECTION"
	oUF.Tags.Methods["status"] = function(unit)
		if not UnitIsConnected(unit) then
			return "offline"		
		elseif UnitIsDead(unit) then
			return "dead"		
		elseif UnitIsGhost(unit) then
			return "ghost"
		end
	end
	
	
	-- Absorb
	self.TotalAbsorb = CreateFrame('StatusBar', nil, self.Health)
	self.TotalAbsorb:SetAllPoints(self.Health)
	self.TotalAbsorb:SetStatusBarTexture(bdCore.media.flat)
	self.TotalAbsorb:SetStatusBarColor(.1,.1,.1,.6)
	
	self.HealAbsorb = CreateFrame('StatusBar', nil, self.Health)
	self.HealAbsorb:SetAllPoints(self.Health)
	self.HealAbsorb:SetStatusBarTexture(bdCore.media.flat)
	self.HealAbsorb:SetStatusBarColor(.2,0,0,.5)
	
	self.HealPredict = CreateFrame('StatusBar', nil, self.Health)
	self.HealPredict:SetAllPoints(self.Health)
	self.HealPredict:SetStatusBarTexture(bdCore.media.flat)
	self.HealPredict:SetStatusBarColor(0.6,1,0.6,.2)
	
	-- Power
	self.Power = CreateFrame("StatusBar", nil, self.Health)
	self.Power:SetStatusBarTexture(bdCore.media.flat)
	self.Power:ClearAllPoints()
	self.Power:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMLEFT", 0, 0)
	self.Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT",0,2)
	self.Power:SetAlpha(0.8)
	self.Power.frequentUpdates = true
	self.Power.colorPower = true
	self.Power.border = self.Health:CreateTexture(nil)
	self.Power.border:SetPoint("TOPRIGHT", self.Power, "TOPRIGHT", 0, 2)
	self.Power.border:SetPoint("BOTTOMLEFT", self.Power, "TOPLEFT", 0, 0)
	
	-- shortname
	self.nameAnchor = CreateFrame("frame",nil, self.Health) -- because frame level is acting bizare as hell
	self.nameAnchor:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMRIGHT", -1, 1)
	self.nameAnchor:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 1, 20)
	self.nameAnchor:SetFrameLevel(6)
	self.Short = self.nameAnchor:CreateFontString(nil,"OVERLAY")
	self.Short:SetFont(bdCore.media.font, 13)
	self.Short:SetShadowOffset(1,-1)
	self.Short:SetPoint("BOTTOMRIGHT", self.nameAnchor, "BOTTOMRIGHT", 0,0)
	self.Short:SetJustifyH("RIGHT")
	
	oUF.Tags.Events["self.Short"] = "UNIT_NAME_UPDATE"
	oUF.Tags.Methods["self.Short"] = function(unit)
		local name = UnitName(unit)
		--local class, classFileName = UnitClass(unit)
		return string.sub(name,1,4)
	end

	self:Tag(self.Short, '[self.Short]')
	self:Tag(self.Status, '[status]')
	
	-- Range
	self:SetScript("OnEnter", function()
		--[[self.arrowmouseover = true
		if (not self.OoR) then
			bdCore:arrow(self, self.unit)
		end--]]
		if (not config.hidetooltips) then
			UnitFrame_OnEnter(self)
		end
	end)
	self:SetScript("OnLeave", function()
		--self.freebarrow:Hide()
		--self.arrowmouseover = false
		UnitFrame_OnLeave(self)
	end)

	
	-- Raid Icon
	self.RaidTargetIndicator = self.Health:CreateTexture(nil, "OVERLAY", nil, 1)
	self.RaidTargetIndicator:SetSize(12, 12)
	self.RaidTargetIndicator:SetPoint("TOP", self, "TOP", 0, -2)
	
	-- roll icon
	self.LFDRole = self.Health:CreateTexture(nil, "OVERLAY")
	self.LFDRole:SetSize(12, 12)
	self.LFDRole:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMLEFT",2,2)
	self.LFDRole.Override = function(self,event)
		local role = UnitGroupRolesAssigned(self.unit)
		self.LFDRole:Hide()
		if (config.roleicon) then
			if (role and (role == "HEALER" or role == "TANK")) then
				self.LFDRole:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
				self.LFDRole:Show()
			end
		end
		
		self.Power:Hide()
		if (config.powerdisplay == "None") then
			self.Power:Hide()
		elseif (config.powerdisplay == "Healers" and role == "HEALER") then
			self.Power:Show()
		elseif (config.powerdisplay == "All") then
			self.Power:Show()
		end
	end
	
	-- range/pointer arrow
	local range = {
		insideAlpha = 1,
		outsideAlpha = .4,
	}
	--self.freebRange = range
	self.Range = range
	
	-- Readycheck
	self.ReadyCheckIndicator = self.Health:CreateTexture(nil, 'OVERLAY', nil, 7)
	self.ReadyCheckIndicator:SetPoint('BOTTOM', self, 'BOTTOM', 0, 2)
	
	-- ResurrectIcon
	self.ResurrectIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.ResurrectIcon:SetPoint('CENTER', self, "CENTER", 0,0)
	
	-- Threat
	self.ThreatIndicator = CreateFrame('frame', nil, self)
	self.ThreatIndicator:SetFrameLevel(95)
	self.ThreatIndicator:SetPoint('TOPRIGHT', self, "TOPRIGHT", 1, 1)
	self.ThreatIndicator:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", -1, -1)
	self.ThreatIndicator:SetBackdrop({bgFile = bdCore.media.flat, edgeFile = bdCore.media.flat, edgeSize = 1})
	self.ThreatIndicator:SetBackdropBorderColor(1, 0, 0,1)
	self.ThreatIndicator:SetBackdropColor(0,0,0,0)
	self.ThreatIndicator.SetVertexColor = function() return end
	
	-- Buffs
	self.Buffs = CreateFrame("Frame", nil, self.Health)
	self.Buffs:SetPoint("TOPLEFT", self.Health, "TOPLEFT")
	self.Buffs:SetFrameLevel(21)
	
	self.Buffs:EnableMouse(false)
	self.Buffs.initialAnchor  = "TOPLEFT"
	self.Buffs.size = 14
	self.Buffs.spacing = 1
	self.Buffs.num = 4
	self.Buffs.onlyShowPlayer = true
	self.Buffs['growth-y'] = "DOWN"
	self.Buffs['growth-x'] = "RIGHT"

	self.Buffs.CustomFilter = function(icons, unit, icon, name, rank, texture, count, dispelType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)
		return bdCore:filterAura(name,caster)
	end
	self.Buffs.PostUpdateIcon = function(buffs, unit, button) 
		button:SetAlpha(0.8)
		button:EnableMouse(false)
		button.cd:GetRegions():SetAlpha(0)
		button.cd:SetReverse(true)
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	
	-- Dispells
	self.Dispel = CreateFrame('frame', nil, self.Health)
	self.Dispel:SetFrameLevel(100)
	self.Dispel:SetPoint('TOPRIGHT', self, "TOPRIGHT", 1, 1)
	self.Dispel:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", -1, -1)
	self.Dispel:SetBackdrop({bgFile = bdCore.media.flat, edgeFile = bdCore.media.flat, edgeSize = 2})
	self.Dispel:SetBackdropBorderColor(1, 0, 0,1)
	self.Dispel:SetBackdropColor(0,0,0,0)
	self.Dispel:Hide()
	local dispelClass = {
		["PRIEST"] = { ["Disease"] = true, ["Magic"] = true, }, --Purify
		["SHAMAN"] = { ["Curse"] = true, ["Magic"] = true, }, --Purify Spirit
		["PALADIN"] = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true, }, --Cleanse
		["MAGE"] = { ["Curse"] = true, }, --Remove Curse
		["DRUID"] = { ["Curse"] = true, ["Poison"] = true, ["Magic"] = true, }, --Nature's Cure
		["MONK"] = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true, }, --Detox
	}
	local dispelColors = {
		['Magic'] = {.16, .5, .81, 1},
		['Poison'] = {.12, .76, .36, 1},
		['Disease'] = {.76, .46, .12, 1},
		['Curse'] = {.80, .33, .95, 1},
	}

	local _, class = UnitClass("player")
	local dispellist = dispelClass[class] or {}
	
	self.Dispel:RegisterEvent("UNIT_AURA")
	self.Dispel:SetScript("OnEvent", function(s, event, unitid)
		if unitid ~= self.unit then return end
		local dispel = nil
		local dispelName = nil
		
		for i = 1, 20 do
			if (not dispel) then
				dispel = select(5, UnitDebuff(unitid, i));
				dispelName = select(1, UnitDebuff(unitid, i));
			end
		end
		
		--if (dispel and (dispelClass[class][dispel] or debuffwhitelist[dispelName])) then
		if (dispel) then
			self.Dispel:Show()
			self.Dispel:SetBackdropBorderColor(unpack(dispelColors[dispel]))

			if (not dispelColors[dispel]) then
				self.Dispel:Hide()
			end
			
		else
			self.Dispel:Hide()
		end
	end)
	
	-- Debuffs
	self.Debuffs = CreateFrame("Frame", nil, self.Health)
	self.Debuffs:SetFrameLevel(21)
	self.Debuffs:SetPoint("CENTER", self.Health, "CENTER")
	
	self.Debuffs.initialAnchor  = "CENTER"
	self.Debuffs.size = 16
	self.Debuffs.spacing = 1
	self.Debuffs.num = 3
	self.Debuffs.onlyShowPlayer = true
	self.Debuffs['growth-y'] = "DOWN"
	self.Debuffs['growth-x'] = "RIGHT"

	self.Debuffs.CustomFilter = function(icons, unit, icon, name, rank, texture, count, dispelType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)
		return bdCore:filterAura(name,caster)
	end
	self.Debuffs.PostUpdateIcon = function(buffs, unit, button)
		button:SetAlpha(0.8)
		button:EnableMouse(false)
		button.cd:GetRegions():SetAlpha(0)
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end

	grid.frames[self] = self; 
	self.index = index
	self.unit = unit
	grid:frameSize(self)
	
	local main  = self
	bdCore:hookEvent("bdGrid_update",function()
		self.configUpdate(main)
	end)
	
	index = index + 1
end

local raidpartyholder = CreateFrame('frame', "bdGrid", UIParent)
raidpartyholder:SetSize(config['width']+2, config['height']*5+8)
raidpartyholder:EnableMouse()
raidpartyholder:SetPoint("TOPLEFT", UIParent, "CENTER", -250,200)
bdCore:makeMovable(raidpartyholder)

local frameHeader = false
local group_by
local group_sort
local sort_method
local yOffset
local xOffset
local new_group_anchor
local new_player_anchor
local hgrowth
local vgrowth
local num_groups

function grid:buildAttributes()

	config.spacing = 2
	
	-- sorting options
	if (config.group_sort == "Group") then
		group_by = "GROUP"
		group_sort = "1, 2, 3, 4, 5, 6, 7, 8"
		sort_method = "INDEX"
	elseif (config.group_sort == "Role") then
		group_by = "ROLE"
		group_sort = "TANK,DAMAGE,NONE,HEAL"
		sort_method = "NAME"
	elseif (config.group_sort == "Name") then
		group_by = nil
		group_sort = "1, 2, 3, 4, 5, 6, 7, 8"
		sort_method = "NAME"
	elseif (config.group_sort == "Class") then
		group_by = "CLASS"
		group_sort = "WARRIOR,DEATHKNIGHT,PALADIN,DRUID,MONK,ROGUE,DEMONHUNTER,HUNTER,PRIEST,WARLOCK,MAGE,SHAMAN"
		sort_method = "NAME"
	end
	
	-- group growth/spacing
	if (config.group_growth == "Upwards") then
		new_group_anchor = "BOTTOM"
		yOffset = config.spacing
	elseif (config.group_growth == "Downwards") then
		new_group_anchor = "TOP"
		xOffset = config.spacing
	elseif (config.group_growth == "Left") then
		new_group_anchor = "RIGHT"
		xOffset = -config.spacing
	elseif (config.group_growth == "Right") then
		new_group_anchor = "LEFT"
		xOffset = config.spacing
	end
	
	-- player growth/spacing
	if (not config.new_player_reverse) then
		if (config.group_growth == "Upwards" or config.group_growth == "Downwards") then
			new_player_anchor = "LEFT"
			xOffset = config.spacing
		elseif (config.group_growth == "Left" or config.group_growth == "Right") then
			new_player_anchor = "TOP"
			yOffset = -config.spacing
		end
	elseif (config.new_player_reverse) then
		if (config.group_growth == "Upwards" or config.group_growth == "Downwards") then
			new_player_anchor = "RIGHT"
			xOffset = -config.spacing
		elseif (config.group_growth == "Left" or config.group_growth == "Right") then
			new_player_anchor = "BOTTOM"
			yOffset = config.spacing
		end
	end
	
	-- group limit
	local difficultySize = {[3] = 1, [4] = 25, [5] = 10, [6] = 25, [7] = 25, [9] = 40, [14] = 30, [15] = 30, [16] = 20, [17] = 30, [18] = 40, [20] = 25}
	num_groups = config.num_groups
	if (config.intel_groups) then
		local difficulty = select(3, GetInstanceInfo()) -- maybe use maxPlayers instead?
		if (difficultySize[difficulty]) then
			num_groups = (difficultySize[difficulty] / 5)
		end
	end

end

function grid:resizeRaidHolder()
	-- move the container to the mover, set up for growth directions
	frameHeader:ClearAllPoints();
	if (config.group_growth == "Right") then
		raidpartyholder:SetSize(config.width, config.height*5+8)
		hgrowth = "LEFT"
		vgrowth = "TOP"
		if (config.new_player_reverse) then vgrowth = "BOTTOM" end
		
	elseif (config.group_growth == "Left") then
		raidpartyholder:SetSize(config.width, config.height*5+8)
		hgrowth = "RIGHT"
		vgrowth = "TOP"
		if (config.new_player_reverse) then vgrowth = "BOTTOM" end
		
	elseif (config.group_growth == "Upwards") then
		raidpartyholder:SetSize(config.width*5+8, config.height)
		hgrowth = "LEFT"
		vgrowth = "BOTTOM"
		if (config.new_player_reverse) then hgrowth = "RIGHT" end
		
	elseif (config.group_growth == "Downwards") then
		raidpartyholder:SetSize(config.width*5+8, config.height)
		hgrowth = "LEFT"
		vgrowth = "TOP"
		if (config.new_player_reverse) then hgrowth = "RIGHT" end
	end
	frameHeader:SetPoint(vgrowth..hgrowth, raidpartyholder, vgrowth..hgrowth, 0, 0)
end

function enable(self)
	self:SetActiveStyle("bdGrid")
	
	grid:buildAttributes()
	
	frameHeader = self:SpawnHeader(nil, nil, 'raid,party,solo',
		"showParty", true,
		"showPlayer", true,
		"showSolo", config.showsolo,
		"showRaid", true,
		"initial-scale", 1,
		"unitsPerColumn", 5,
		"columnSpacing", 2,
		"xOffset", xOffset,
		"maxColumns",config.num_groups,
		"groupingOrder",group_sort,
		"sortMethod",sort_method,
		"columnAnchorPoint",new_group_anchor,
		"initial-width",config.width,
		"initial-height",config.height,
		"point",new_player_anchor,
		"yOffset",yOffset,
		"groupBy",group_by
	);
	
	grid:resizeRaidHolder()
end

function grid:callback()
	for k, frame in pairs(grid.frames) do
		grid:frameSize(frame)
	end
end

grid.frames = {}
oUF:RegisterStyle("bdGrid", grid.layout)
oUF:Factory(enable)

function grid:refresh()
	if (InCombatLockdown()) then return end
	
	grid:buildAttributes()
	grid:resizeRaidHolder()
	
	for k, frame in pairs(grid.frames) do
		frame:ClearAllPoints()
	end
	
	-- growth/spacing
	frameHeader:SetAttribute("columnAnchorPoint",new_group_anchor)
	frameHeader:SetAttribute("point",new_player_anchor)
	frameHeader:SetAttribute("yOffset",yOffset)
	frameHeader:SetAttribute("xOffset",xOffset)
	
	-- when to show
	frameHeader:SetAttribute("showSolo",config.showsolo)
	frameHeader:SetAttribute("maxColumns", num_groups)
	
	-- width/height
	frameHeader:SetAttribute("initial-width",config.width)
	frameHeader:SetAttribute("initial-height",config.height)
	
	-- grouping/sorting
	frameHeader:SetAttribute("groupBy",group_by)
	frameHeader:SetAttribute("groupingOrder",group_sort)
	frameHeader:SetAttribute("sortMethod",sort_method)
end

grid:RegisterEvent("PLAYER_REGEN_ENABLED")
grid:RegisterEvent("PLAYER_ENTERING_WORLD")
bdCore:hookEvent("bd_reconfig",function() 
	grid:callback()
	grid:refresh()
end)
grid:SetScript("OnEvent", function(self, event, arg1)
	grid:callback()
	grid:refresh()
end)

-- disable blizzard raid frames
CompactRaidFrameManager:UnregisterAllEvents() 
CompactRaidFrameManager:Hide() 
CompactRaidFrameContainer:UnregisterAllEvents() 
CompactRaidFrameContainer:Hide() 

