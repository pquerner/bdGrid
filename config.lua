local ADDON_NAME, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, "bdGrid was unable to locate oUF install.")


local grid = CreateFrame("frame", nil, UIParent)

local config = {
	['number of groups'] = 6,
	['width'] = 60,
	['height'] = 50,
}




-- Load
function grid.layout(self, unit)
	self:RegisterForClicks('AnyDown')
	self:SetSize(config['width'], config['height'])
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
	
	-- raid icon
	self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY", nil, 1)
	self.RaidIcon:SetSize(12, 12)
	self.RaidIcon:SetPoint("TOP", self, "TOP", 0, -2)
	
	-- absorb
	self.TotalAbsorb = CreateFrame('StatusBar', nil, self.Health)
	self.TotalAbsorb:SetFrameLevel(20)
	self.TotalAbsorb:SetPoint("TOPLEFT", self.Health, "TOPLEFT", 0, 0)
	self.TotalAbsorb:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMRIGHT", 0, 0)
	self.TotalAbsorb:SetStatusBarTexture(bdCore.media.flat)
	self.TotalAbsorb:SetStatusBarColor(.1,.1,.1,.6)
	
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
	
	-- Tags
	self.Short = self.Health:CreateFontString(nil)
	self.Short:SetFont(bdCore.media.font, 13, "OUTLINE")
	self.Short:SetShadowOffset(0,0)
	self.Short:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 1)
	self.Short:SetJustifyH("RIGHT")
	self.Short:SetWidth(self.Health:GetWidth())
	oUF.Tags.Events["self.Short"] = "UNIT_NAME_UPDATE"
	oUF.Tags.Methods["self.Short"] = function(unit)
		local name = UnitName(unit)
		local class, claswasFileName = UnitClass(unit)
		return strtrim(string.sub(name, 1, 4))
	end
	self.Status = self:CreateFontString(nil, "OVERLAY")
	self.Status:SetFont(bdCore.media.font, 12, "OUTLINE")
	self.Status:SetPoint('BOTTOMLEFT', self.Health, "BOTTOMLEFT", 0, 0)
	
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
	self.ReadyCheck:SetSize(12, 12)
	
	-- ResurrectIcon
	self.ResurrectIcon = self:CreateTexture(nil, 'OVERLAY')
	self.ResurrectIcon:SetSize(16, 16)
	self.ResurrectIcon:SetPoint('CENTER', self, "CENTER", 0,0)
	
	-- Threat
	self.Threat = CreateFrame('frame', nil, self)
	self.Threat:SetSize(60, 50)
	self.Threat:SetFrameLevel(95)
	self.Threat:SetPoint('TOPRIGHT', self, "TOPRIGHT", 1, 1)
	self.Threat:SetPoint('BOTTOMLEFT', self, "BOTTOMLEFT", -1, -1)
	self.Threat:SetBackdrop({bgFile = bdCore.media.flat, edgeFile = bdCore.media.flat, edgeSize = 1})
	self.Threat:SetBackdropBorderColor(1, 0, 0,1)
	self.Threat:SetBackdropColor(0,0,0,0)
	self.Threat.SetVertexColor = function() return end
	
	self.Health.PostUpdate = function(s, unit, min, max)
		local r, g, b = self.Health:GetStatusBarColor()
		self.Health:SetStatusBarColor(r/2, g/2, b/2)
	end
	
	
	-- Buffs
	self.Buffs = CreateFrame("Frame", nil, self)
	self.Buffs:SetPoint("TOPLEFT", self.Health, "TOPLEFT")
	self.Buffs:SetFrameLevel(21)
	self.Buffs:SetSize(64, 16)
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
	
	-- Debuffs
	self.Debuffs = CreateFrame("Frame", nil, self)
	self.Debuffs:SetFrameLevel(21)
	self.Debuffs:SetPoint("CENTER", self.Health, "CENTER")
	self.Debuffs:SetSize(44, 22)
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
end

-- Enable
function grid.enable() 
	oUF:RegisterStyle("bdGrid", grid.layout)
	
	local raidpartyholder = CreateFrame('frame', "bdGrid", UIParent)
	raidpartyholder:SetSize(config['width'], config['height']*5-(5*2))
	raidpartyholder:RegisterEvent("GROUP_ROSTER_UPDATE")
	raidpartyholder:RegisterEvent("PLAYER_ENTERING_WORLD")
	raidpartyholder:EnableMouse()
	raidpartyholder:SetPoint("CENTER", UIParent, "CENTER",0,0)
	--bdCore:setBackdrop(raidpartyholder)
	raidpartyholder:SetScript("OnEvent", function(self, event, arg1)
		local num = GetNumGroupMembers()
		local size = math.floor(num/5);
		if (size == 0) then
			size = 1
		end
		if (size > config['number of groups']) then
			size = config['number of groups']
		end
		raidpartyholder:SetWidth(config['width']*size+(2*size)-2)
	end)
	
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
			"maxColumns", config['number of groups'],
			"unitsPerColumn", 5,
			"columnSpacing", 2,
			"columnAnchorPoint", "RIGHT",
			"point", "TOP"
		)
		party:SetPoint("TOPRIGHT", raidpartyholder, "TOPRIGHT", 0, 0)
	end)
	
	
end

grid:enable()

bdCore:hookScript("loaded_bdcore", function()
	print('loaded bdcore inside of bdgrid')
end)

-- Disable