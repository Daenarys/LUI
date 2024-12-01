--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: hideblizzard.lua
	Description: Blizzard Frame Hider
]]

local addonname, LUI = ...
local Blizzard = {}
LUI.Blizzard = Blizzard

LibStub("AceHook-3.0"):Embed(Blizzard)

local argcheck = LUI.argcheck
local oocWrapper = LUI.OutOfCombatWrapper

local hidden = {}

local show, hide, hook, unhook
do
	Blizzard:SecureHook("OrderHall_LoadUI", function()
		LUI:Kill(OrderHallCommandBar)
	end)
	hook = setmetatable({}, {
		__call = function(t, type, hookto)
			if t[type] then return end
			t[type] = hookto

			Blizzard:SecureHook(hookto, hide[type])
		end
	})
	unhook = function(type)
		Blizzard:Unhook(hook[type])
		hook[type] = nil
	end
	
	local compact_raid

	hide = {
		party = function()
			for i = 1, 4 do
				local frame = _G["PartyMemberFrame"..i]
				frame:UnregisterAllEvents()
				frame:Hide()
				frame.Show = LUI.dummy
			end

			UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

			if CompactPartyFrame then
				CompactPartyFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
				CompactPartyFrame:Hide()

				if hook.party == "CompactPartyFrame_Generate" then
					hook.party = nil
				end
				if CompactPartyFrame_UpdateShown then
					hook("party", "CompactPartyFrame_UpdateShown")
				end
			else
				hook("party", "CompactPartyFrame_Generate")
			end
		end,
		raid = function()
			if CompactRaidFrameManager then
				CompactRaidFrameManager:UnregisterEvent("GROUP_ROSTER_UPDATE")
				CompactRaidFrameManager:UnregisterEvent("PLAYER_ENTERING_WORLD")
				CompactRaidFrameManager:Hide()
				compact_raid = CompactRaidFrameManager_GetSetting("IsShown")
				if compact_raid and compact_raid ~= "0" then
					CompactRaidFrameManager_SetSetting("IsShown", "0")
				end
				hook("raid", "CompactRaidFrameManager_UpdateShown")
			end
		end,
		arena = function()
			if IsAddOnLoaded("Blizzard_ArenaUI") then
				ArenaEnemyFrames:UnregisterAllEvents()
			else
				hook("arena", "Arena_LoadUI")
			end
		end,
		aura = function()
			BuffFrame:Hide()
			BuffFrame:UnregisterAllEvents()
		end,
	}
	show = {
		party = function()
			Blizzard:Unhook("CompactPartyFrame_Generate")
			for i = 1, 4 do
				local frame = _G["PartyMemberFrame"..i]
				frame.Show = nil -- reset access to the frame metatable's show function
				frame:GetScript("OnLoad")(frame)
				frame:GetScript("OnEvent")(frame, "GROUP_ROSTER_UPDATE")
				PartyMemberFrame_UpdateMember(frame)
			end
			UIParent:RegisterEvent("GROUP_ROSTER_UPDATE")
			if CompactPartyFrame then
				CompactPartyFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
				if GetDisplayedAllyFrames then
					if GetDisplayedAllyFrames() == "compact-party" then
						CompactPartyFrame:Show()
					end
				elseif GetCVarBool("useCompactPartyFrames") and GetNumSubgroupMembers() > 0 and GetNumGroupMembers() == 0 then
					CompactPartyFrame:Show()
				end
			end
		end,
		raid = function()
			CompactRaidFrameManager:RegisterEvent("GROUP_ROSTER_UPDATE")
			CompactRaidFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")
			if GetDisplayedAllyFrames then
				if GetDisplayedAllyFrames() == "raid" then
					CompactRaidFrameManager:Show()
				end
			elseif GetNumGroupMembers() > 0 then
				CompactRaidFrameManager:Show()
			end
			if compact_raid and compact_raid ~= "0" then
				CompactRaidFrameManager_SetSetting("IsShown", "1")
			end
		end,
		arena = function()
			if IsAddOnLoaded("Blizzard_ArenaUI") then
				ArenaEnemyFrames:GetScript("OnLoad")(ArenaEnemyFrames)
				ArenaEnemyFrames:GetScript("OnEvent")(ArenaEnemyFrames, "VARIABLES_LOADED")
			end
		end,
		aura = function()
			BuffFrame:Show()
			if GetCVarBool("consolidateBuffs") then
				ConsolidatedBuffs:Show()
			end
			TemporaryEnchantFrame:Show()

			-- Can't use OnLoad because doing so resets some variables which requires an update to get the frame back in the proper state, which in Cata causes taint.
			BuffFrame:RegisterEvent("UNIT_AURA")

		-- This isn't perfect.  It doesn't update the buffs till the next aura update.  However, in Cata it causes taint to force the update.
		-- However, it should work for 99% of peoples use cases, which is toggling it on and off to see what it does or setting it and leaving it set.
		-- BuffFrame:GetScript("OnEvent")(BuffFrame, "UNIT_AURA", PlayerFrame.unit)
		end
	}

	for k, v in pairs(hide) do
		hide[k] = oocWrapper(v)
	end
	for k, v in pairs(show) do
		show[k] = oocWrapper(v)
	end
end

function Blizzard:Hide(type)
	argcheck(type, "typeof", "string")
	type = type:lower()
	--argcheck(type, "isin", hide)

	if not hide[type] then return end
	if hidden[type] then return end

	hidden[type] = true
	hide[type]()

	return true -- inform that the object was hidden
end

function Blizzard:Show(type)
	argcheck(type, "typeof", "string")
	type = type:lower()
	--argcheck(type, "isin", show)

	if not show[type] then return end
	if not hidden[type] then return end

	hidden[type] = nil
	if hook[type] then
		unhook(type)
	end
	show[type]()

	return true -- inform that the object was shown
end

function Blizzard:IsHideable(type)
	argcheck(type, "typeof", "string")

	return hide[type:lower()] ~= nil
end
