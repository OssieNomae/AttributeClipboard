--!strict
--[[
	License: Licensed under the MIT License
	Version: 1.0.0
	Github: 
	Authors:
		OssieNomae - 2024

	AttributeClipboard: Adds simple clipboard functionality to object attributes with the ability to use customizable keyboard shortcuts
	
	--------------------------------
	
	Copy: Select an object that has attributes -> Open the Clipboard menu and select "Copy" -> Attributes of that object are now copied to the clipboard
	Paste: Select all the objects that you want to paste the previously copied attributes to -> Open the Clipboard menu and select "Paste" -> Attributes from the clipboard should now appear in selected objects
	Clear: Select all the objects that you want to clear all attributes from -> Open the Clipboard menu and select "Clear" -> All attributes from the selected objects should now disappear
	
	Keyboard shortcuts can be assigned under File → Advanced → Customize Shortcuts
	
--]]

----- Loaded Services -----
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

----- Types -----
type ClipboardActionType = "Copy" | "Paste" | "Clear"

----- Private Variables -----
local Toolbar = plugin:CreateToolbar("Attribute Clipboard") :: PluginToolbar
local AttributeClipboardButton = Toolbar:CreateButton("Open Attribute Clipboard Menu", "Open Attribute Clipboard Menu", "rbxassetid://76443890191204", "Open") :: PluginToolbarButton

-- these are for bindings, they can be assigned a keyboard shortcut under File → Advanced → Customize Shortcuts
local CopyAction = plugin:CreatePluginAction("Attribute Clipboard Copy", "Copy Attribute Clipboard", "Copy Object Attributes to Clipboard", "rbxassetid://96265482350413", true)
local PasteAction = plugin:CreatePluginAction("Attribute Clipboard Paste", "Paste Attribute Clipboard", "Paste Attributes from Clipboard to Objects", "rbxassetid://104603524910157", true)
local ClearAction = plugin:CreatePluginAction("Attribute Clipboard Clear", "Clear Attribute Clipboard", "Clear Attributes from Objects", "rbxassetid://128372145651723", true)

-- these are for the menu
local PluginMenu = plugin:CreatePluginMenu("Attribute Clipboard Menu")
PluginMenu:AddNewAction("Attribute Clipboard Copy Menu", "Copy", "rbxassetid://96265482350413")
PluginMenu:AddNewAction("Attribute Clipboard Paste Menu", "Paste", "rbxassetid://104603524910157") -- TODO: Replace these with their actual icons...
PluginMenu:AddNewAction("Attribute Clipboard Clear Menu", "Clear", "rbxassetid://128372145651723")

local Clipboard = {} :: {[string]: any}

----- Private Util -----

----- Private Methods -----
local function ClearAttributes()
	local Objects = Selection:Get()
	if not Objects[1] then
		warn("AttributeClipboard: Select all the objects you want to paste attributes to")
		return
	end

	local Recording = ChangeHistoryService:TryBeginRecording("AttributeClipboard: Clear Attributes")
	if not Recording then
		return
	end

	for _,Object in pairs(Objects) do
		if not Object:IsA("Instance") then continue end

		for Index,_ in pairs(Object:GetAttributes()) do
			Object:SetAttribute(Index, nil)
		end

		print(`AttributeClipboard: Cleared Attributes from {Object:GetFullName()}`)
	end

	ChangeHistoryService:FinishRecording(Recording, Enum.FinishRecordingOperation.Commit)
end

local function PasteAttributes()
	local Objects = Selection:Get()
	if not Objects[1] then
		warn("AttributeClipboard: Select all the objects you want to paste attributes to")
		return
	end

	local Recording = ChangeHistoryService:TryBeginRecording("AttributeClipboard: Pasted Attributes")
	if not Recording then
		return
	end

	for _,Object in pairs(Objects) do
		if not Object:IsA("Instance") then continue end

		for Index,Value in pairs(Clipboard) do
			Object:SetAttribute(Index, Value)
		end

		print("AttributeClipboard: Pasted Attributes", Clipboard, `to {Object:GetFullName()}`)
	end

	ChangeHistoryService:FinishRecording(Recording, Enum.FinishRecordingOperation.Commit)
end

local function CopyAttributes()
	local Object = Selection:Get()[1]
	if not Object then
		warn("AttributeClipboard: You must first select the object you want to copy attributes from!")
		return
	end

	local Attributes = Object:GetAttributes()
	if Attributes == {} then -- empty dictionary :shrug:
		warn("AttributeClipboard: Selected object doesn't have any attributes")
		return
	end

	Clipboard = Attributes
	print("AttributeClipboard: Copied Attributes", Attributes, `from {Object:GetFullName()}`)
end

----- Connections -----
local ClipboardActions = {
	Copy = CopyAttributes,
	Paste = PasteAttributes,
	Clear = ClearAttributes
}
AttributeClipboardButton.Click:Connect(function()
	AttributeClipboardButton:SetActive(false) -- visual thing

	local Selected = PluginMenu:ShowAsync() :: PluginAction & {Text: ClipboardActionType}
	if not Selected then return end

	local Func = ClipboardActions[Selected.Text]
	if not Func then return end

	Func()
end)

-- Bindings
CopyAction.Triggered:Connect(CopyAttributes)
PasteAction.Triggered:Connect(PasteAttributes)
ClearAction.Triggered:Connect(ClearAttributes)