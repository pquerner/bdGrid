local bUI, F, C = select(2, ...):unpack()
local media = bUI.media

local parent, ns = ...
local oUF = ns.oUF or oUF

local update = 0.1
local healrange = 10
local units = {}

local timer = 0
function round(num, idp)
	if idp and idp>0 then
		local mult = 10^idp
		return math.floor(num * mult + 0.5) / mult
	end
	return math.floor(num + 0.5)
end
local validUnit = function(unit)
	return UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) and not (UnitIsCharmed(unit) and not UnitIsEnemy("player", unit))
end
local function getDistance(x1, y1, x2, y2)
	local xx = (x2 - x1)
	local yy = (y2 - y1)
	
	return (xx*xx + yy*yy)^0.5
end

local clearDataid = function(id, id2)
	if units[id][id2] then
		units[id][id2] = nil
		units[id].numInRange = units[id].numInRange-1
	end
	if units[id2][id] then
		units[id2][id] = nil
		units[id2].numInRange = units[id2].numInRange-1
	end
end

local updatePos = function(self, elapsed)
	timer = timer + elapsed

	if(timer >= update) then
		for id, _ in next, units do
			local x, y = GetPlayerMapPosition(id)
			x = x*550
			y = y*550
			-- no idea why 550 is the magic number
			
			units[id].pos = ""..x.."\\"..y..""
		end

		for id, _ in next, units do
			local pos = units[id].pos

			for id2, _ in next, units do
				if validUnit(id2) and (id ~= id2) then
					local pos2 = units[id2].pos

					local x1, y1 = strsplit("\\", pos)
					local x2, y2 = strsplit("\\", pos2)
					local xxyy = x1 + x2 + y1 + y2

					local dist = getDistance(x1, y1, x2, y2)
					if dist < healrange and xxyy > 0 then
						if not units[id][id2] then
							units[id][id2] = true
							units[id].numInRange = units[id].numInRange+1
						end
						if not units[id2][id] then
							units[id2][id] = true
							units[id2].numInRange = units[id2].numInRange+1
						end
					else
						clearDataid(id, id2)
					end
				else
					clearDataid(id, id2)
				end
			end
		end

		timer = 0
	end
end

oUF.Tags.Methods['freebgrid:cluster'] = function(u)
	if units[u] then
		local num = units[u].numInRange
		--print(u..": "..num)
		if num > 2 then
			if num > 6 then
				num = "6"
			end

			return num
		end
	end
end

local fillroster = function(unit)
	if (validUnit(unit)) then
		units[unit] = {}
		units[unit].pos = ""
		units[unit].numInRange = 1
	else
		units[unit] = nil
	end
	--["pos"] = "", ["numInRange"] = 1
end

local updateRoster = function()
	units = {}
	local numRaid = GetNumGroupMembers()
	if numRaid > 1 then
		for i=1, numRaid do
			local name = GetRaidRosterInfo(i)
			if name then
				local unit = "raid"..i
				fillroster(unit)
			end
		end
	else
		fillroster("player")

		local numParty = GetNumSubgroupMembers()
		for i=1, numParty do
			local unit = "party"..i
			fillroster(unit)
		end
	end
end

local frame = CreateFrame"Frame"
frame:SetScript("OnEvent", function(self, event)
	updateRoster()
end)


local Enable = function(self)
	if self.clusterEnabled then

		self.freebCluster = self.Health:CreateFontString(nil, "OVERLAY")
		self.freebCluster:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		self.freebCluster:SetJustifyH("LEFT")
		self.freebCluster:SetFont(media.font, 12, "OUTLINE")
		self.freebCluster:SetTextColor(1,1,1)
		self.freebCluster:SetWidth(20)
		self.freebCluster.frequentUpdates = update
		self:Tag(self.freebCluster, "[freebgrid:cluster]")
		self.freebCluster:Show()
		
		self:HookScript("OnUpdate", function(self, elapsed) 
			local text = tonumber(self.freebCluster:GetText());
			if (text) then
				if (text < 4) then
					self.freebCluster:SetTextColor(.6,.6,.6)
				elseif (text == 5) then
					self.freebCluster:SetTextColor(.9,1,.9)
				elseif (text > 5) then
					self.freebCluster:SetTextColor(.6,1,.7)
				end
			end
		end)

		frame:RegisterEvent("GROUP_ROSTER_UPDATE")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		frame:SetScript("OnUpdate", updatePos)
		updateRoster()

		return true
	end

end



local Disable = function(self)
	if self.freebCluster then
		self.freebCluster.frequentUpdates = false
		self.freebCluster:Hide()
	end

	frame:UnregisterEvent("GROUP_ROSTER_UPDATE")
	frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	frame:SetScript("OnUpdate", nil)
	units = {}
end

oUF:AddElement('freebCluster', nil, Enable, Disable)
