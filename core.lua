local ADDON_NAME, ns = ...
local oUF = ns.oUF or oUF
local grid = CreateFrame("frame", nil, UIParent)

local defaults = {
	[1] = {num_groups = {
		type = "slider",
		value = 4,
		min = 1,
		max = 8,
		step = 1,
		label = "Number of Groups",
		tooltip = "How many groups should be shown at a time",
		callback = function() grid:enable() end
	}},
	[2] = {width = {
		type = "slider",
		value = 60,
		min = 20,
		max = 100,
		step = 2,
		label = "Width",
		tooltip = "The width of each player in the raid frames",
		callback = function() grid:callback() end
	}},
	[3] = {height = {
		type = "slider",
		value = 50,
		min = 20,
		max = 100,
		step = 2,
		label = "Height",
		tooltip = "The height of each player in the raid frames",
		callback = function() grid:callback() end
	}},
	[4] = {growth = {
		type = "dropdown",
		value = "LEFT",
		options = {"LEFT","RIGHT"},
		label = "Growth Direction",
		tooltip = "The direction that new groups should be shown.",
		callback = function() grid:enable() end
	}},
}

bdCore:addModule("Grid", defaults)
local config = bdCore.config["Grid"]

local raidpartyholder = CreateFrame('frame', "bdGrid", UIParent)
raidpartyholder:RegisterEvent("GROUP_ROSTER_UPDATE")
raidpartyholder:RegisterEvent("PLAYER_ENTERING_WORLD")
raidpartyholder:RegisterEvent("PLAYER_REGEN_ENABLED")
raidpartyholder:SetSize(config['width'], config['height']*5+8)
raidpartyholder:EnableMouse()
raidpartyholder:SetPoint("CENTER", UIParent, "CENTER", -200,40)
raidpartyholder:SetScript("OnEvent", function(self, event, arg1)
	grid:containerSize()
end)
bdCore:makeMovable(raidpartyholder)

-- make sizes outside of combat
function grid:frameSize(frame)
	frame:SetSize(config['width'], config['height'])
	frame.Health:SetSize(config['width'], config['height'])
	frame.Debuffs:SetSize(44, 22)
	frame.RaidIcon:SetSize(12, 12)
	frame.Short:SetWidth(config['width'])
	frame.ReadyCheck:SetSize(12, 12)
	frame.ResurrectIcon:SetSize(16, 16)
	frame.Threat:SetSize(60, 50)
	frame.Buffs:SetSize(64, 16)
	frame.Debuffs:SetSize(44, 22)
	frame.Dispel:SetSize(60, 50)
end

function grid:containerSize()
	local num = GetNumGroupMembers()
	local size = math.floor(num/5);
	if (size == 0) then
		size = 1
	end
	if (size > config['num_groups']) then
		size = config['num_groups']
	end
	
	if (not UnitAffectingCombat('player')) then
		raidpartyholder:SetWidth(config['width']*size+(2*size)-2)
	end
end

-- Load
function grid.layout(self, unit)
	self:RegisterForClicks('AnyDown')
	
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
	self.Health.PostUpdate = function(s, unit, min, max)
		local r, g, b = self.Health:GetStatusBarColor()
		self.Health:SetStatusBarColor(r/2, g/2, b/2)
	end
	bdCore:setBackdrop(self.Health)
	
	-- raid icon
	self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY", nil, 1)
	self.RaidIcon:SetPoint("TOP", self, "TOP", 0, -2)
	
	-- absorb
	self.TotalAbsorb = CreateFrame('StatusBar', nil, self.Health)
	--self.TotalAbsorb:SetFrameLevel(20)
	self.TotalAbsorb:SetPoint("TOPLEFT", self.Health, "TOPLEFT", 0, 0)
	self.TotalAbsorb:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMRIGHT", 0, 0)
	self.TotalAbsorb:SetStatusBarTexture(bdCore.media.flat)
	self.TotalAbsorb:SetStatusBarColor(.1,.1,.1,.5)
	
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
	
	-- shortname
	self.Short = self.Health:CreateFontString(nil,"OVERLAY")
	self.Short:SetFont(bdCore.media.font, 13, "OUTLINE")
	self.Short:SetShadowOffset(0,0)
	self.Short:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 1)
	self.Short:SetJustifyH("RIGHT")
	
	oUF.Tags.Events["self.Short"] = "UNIT_NAME_UPDATE"
	oUF.Tags.Methods["self.Short"] = function(unit)
		local name = UnitName(unit)
		local class, classFileName = UnitClass(unit)
		return strtrim(string.sub(name, 1, 4))
	end

	self:Tag(self.Short, '[self.Short]')
	self:Tag(self.Status, '[status]')
	
	-- Range
	self:SetScript("OnEnter", function()
		self.arrowmouseover = true
		if (not self.OoR) then
			ns:arrow(self, self.unit)
		end
	end)
	self:SetScript("OnLeave", function()
		self.freebarrow:Hide()
		self.arrowmouseover = false
	end)
	
	-- Raid Icon
	self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY", nil, 1)
	self.RaidIcon:SetSize(12, 12)
	self.RaidIcon:SetPoint("TOP", self, "TOP", 0, -2)
	
	-- range/pointer arrow
	local range = {
		insideAlpha = 1,
		outsideAlpha = .4,
	}
	self.freebRange = range
	self.Range = false
	
	-- Readycheck
	self.ReadyCheck = self.Health:CreateTexture(nil, 'OVERLAY', nil, 7)
	self.ReadyCheck:SetPoint('BOTTOM', self, 'BOTTOM', 0, 2)
	
	-- ResurrectIcon
	self.ResurrectIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.ResurrectIcon:SetPoint('CENTER', self, "CENTER", 0,0)
	
	-- Threat
	self.Threat = CreateFrame('frame', nil, self)
	self.Threat:SetFrameLevel(95)
	self.Threat:SetPoint('TOPRIGHT', self, "TOPRIGHT", 1, 1)
	self.Threat:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", -1, -1)
	self.Threat:SetBackdrop({bgFile = bdCore.media.flat, edgeFile = bdCore.media.flat, edgeSize = 1})
	self.Threat:SetBackdropBorderColor(1, 0, 0,1)
	self.Threat:SetBackdropColor(0,0,0,0)
	self.Threat.SetVertexColor = function() return end
	
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

	self.Buffs.CustomFilter = function(unit, icon, button, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID)
		return bdCore:filterAura(name,caster)
	end
	self.Buffs.PostUpdateIcon = function(buffs, unit, button) 
		button:SetAlpha(0.8)
		button:EnableMouse(false)
		button.cd:GetRegions():SetAlpha(0)
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
	self.Debuffs.size = 22
	self.Debuffs.spacing = 1
	self.Debuffs.num = 2
	self.Debuffs.onlyShowPlayer = true
	self.Debuffs['growth-y'] = "DOWN"
	self.Debuffs['growth-x'] = "RIGHT"

	self.Debuffs.CustomFilter = function(unit, icon, blank, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID)
		return bdCore:filterAura(name,caster)
	end
	self.Debuffs.PostUpdateIcon = function(buffs, unit, button)
		button:SetAlpha(0.8)
		button:EnableMouse(false)
		button.cd:GetRegions():SetAlpha(0)
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

		button:SetBackdrop({bgFile = bdCore.media.flat, edgeFile = bdCore.media.flat, edgeSize = 2})
		button:SetBackdropColor(.11,.15,.18, 1)
		button:SetBackdropBorderColor(.06, .08, .09, 1)
	end

	grid.frames[self] = self; 

	if (not UnitAffectingCombat('player')) then
		grid:frameSize(self)
	end
end

-- Enable
function grid:enable()
	for k, frame in pairs(grid.frames) do
		bdCore:kill(frame)
	end
	grid.frames = {}
	oUF:Factory(function(self)
		self:SetActiveStyle("bdGrid")
		local party = self:SpawnHeader(nil, nil, 'raid,party,solo',
			'showParty', true, 
			'showPlayer', true, 
			'yOffset', -2,
			"xOffset", 2,
			"showParty", true,
			"showPlayer", true,
			"showSolo", true,
			"showRaid", true,
			"groupFilter", "1,2,3,4,5,6,7,8",
			"groupBy", "GROUP",
			"groupingOrder", "1,2,3,4,5,6,7,8",
			"maxColumns", config['num_groups'],
			"unitsPerColumn", 5,
			"columnSpacing", 2,
			"columnAnchorPoint", config.growth,
			"point", "TOP"
		)
		party:SetPoint("TOPRIGHT", raidpartyholder, "TOPRIGHT", 0, 0)
		if (config.growth == "RIGHT") then
			party:SetPoint("TOPLEFT", raidpartyholder, "TOPLEFT", 0, 0)
		end
	end)
	
	grid:callback()
end

grid.frames = {}
function grid:callback()
	if (not UnitAffectingCombat("player")) then
		for k, frame in pairs(grid.frames) do
			grid:frameSize(frame)
		end
	end
	grid:containerSize()
end

grid:RegisterEvent("PLAYER_REGEN_ENABLED")
grid:RegisterEvent("PLAYER_ENTERING_WORLD")
grid:SetScript("OnEvent", function(self, event, arg1)
	grid:callback()
end)

oUF:RegisterStyle("bdGrid", grid.layout)
grid:enable()


-- bdCore:hookEvent("loaded_bdcore", function()
	-- print('loaded bdcore inside of bdgrid')
-- end)

-- Disable
