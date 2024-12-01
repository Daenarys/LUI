--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: chat.lua
	Description: Chat Module
]]

-- External references.
local module = LUI:Module("Chat", "AceHook-3.0")

function module:OnEnable()
	TextToSpeechButtonFrame:Hide()
	QuickJoinToastButton:Hide()
	ChatFrameMenuButton:Hide()
	ChatFrameChannelButton:Hide()

	for i = 1, NUM_CHAT_WINDOWS do
		_G['ChatFrame'..i..'ButtonFrame']:Hide()
	end
end

function module:OnDisable()
	TextToSpeechButtonFrame:Show()
	QuickJoinToastButton:Show()
	ChatFrame1ButtonFrame:Show()
	ChatFrameMenuButton:Show()
	ChatFrameChannelButton:Show()

	for i = 1, NUM_CHAT_WINDOWS do
		_G['ChatFrame'..i..'ButtonFrame']:Show()
	end
end