-- Author: Fetty42
-- Date: 02.03.2025
-- Version: 1.0.0.0

AutoLightOnOffUISettings = {}

-- Create a meta table to get basic Class-like behavior
local autoLightOnOffUISettings_mt = Class(AutoLightOnOffUISettings)

---Creates the settings UI object
---@return SettingsUI @The new object
function AutoLightOnOffUISettings.new(settings, debug)
    local self = setmetatable({}, autoLightOnOffUISettings_mt)

    self.controls = {}
	self.settings = settings
	self.debug = debug

    return self
end

---Register the UI into the base game UI
function AutoLightOnOffUISettings:registerSettings()
    -- Get a reference to the base game general settings page
    local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings
	
	-- Define the UI controls. For each control, a <prefix>_<name>_short and _long key must exist in the i18n values
    local controlProperties = {
        { name = "isPlayerAutoLight", autoBind = true, nillable = false }
    }

    UIHelper.createControlsDynamically(settingsPage, "aloo_setting_title", self, controlProperties, "aloo_")
    UIHelper.setupAutoBindControls(self, self.settings, AutoLightOnOffUISettings.onSettingsChange)

    -- Apply initial values
    self:updateUiElements()

    -- Update any additional settings whenever the frame gets opened
    InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, function()
        self:updateUiElements(true) -- We can skip autobind controls here since they are already registered to onFrameOpen
    end)
	
	-- Trigger to update the values when settings frame is closed
	InGameMenuSettingsFrame.onFrameClose = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameClose, function()
		self:onFrameClose();
   	end);

end

function AutoLightOnOffUISettings:onSettingsChange()
    self:updateUiElements()
end

---Updates the UI elements to reflect the current settings
---@param skipAutoBindControls boolean|nil @True if controls with the autoBind properties shall not be newly populated
function AutoLightOnOffUISettings:updateUiElements(skipAutoBindControls)
    if not skipAutoBindControls then
        -- Note: This method is created dynamically by UIHelper.setupAutoBindControls
        self.populateAutoBindControls()
    end

	local isAdmin = g_currentMission:getIsServer() or g_currentMission.isMasterUser

	for _, control in ipairs(self.controls) do
		control:setDisabled(not isAdmin)
	end
	
    -- Update the focus manager
    local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings
    settingsPage.generalSettingsLayout:invalidateLayout()
end

function AutoLightOnOffUISettings:onFrameClose()
	-- if AutoLightOnOff.settings.isPlayerAutoLight ~= AutoLightOnOff.settings.isPlayerAutoLight_OLD then
    -- 	AutoLightOnOff.settings.isPlayerAutoLight_OLD = AutoLightOnOff.settings.isPlayerAutoLight
    --     g_currentMission:showBlinkingWarning(g_i18n:getText("aloo_blink_warn"), 5000)
    -- end
end