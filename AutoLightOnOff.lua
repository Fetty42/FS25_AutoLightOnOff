-- Author: Fetty42

local dbPrintfOn = false
local dbInfoPrintfOn = false

local function dbInfoPrintf(...)
	if dbInfoPrintfOn then
    	print(string.format(...))
	end
end

local function dbPrintf(...)
	if dbPrintfOn then
    	print(string.format(...))
	end
end

local function dbPrint(...)
	if dbPrintfOn then
    	print(...)
	end
end

local function dbPrintHeader(funcName)
	if dbPrintfOn then
		if g_currentMission ~=nil and g_currentMission.missionDynamicInfo ~=nil then
			print(string.format("Call %s: isDedicatedServer=%s | isServer()=%s | isMasterUser=%s | isMultiplayer=%s | isClient()=%s | farmId=%s",
							funcName, tostring(g_dedicatedServer~=nil), tostring(g_currentMission:getIsServer()), tostring(g_currentMission.isMasterUser), tostring(g_currentMission.missionDynamicInfo.isMultiplayer), tostring(g_currentMission:getIsClient()), tostring(g_currentMission:getFarmId())))
		else
			print(string.format("Call %s: isDedicatedServer=%s | g_currentMission=%s",
							funcName, tostring(g_dedicatedServer~=nil), tostring(g_currentMission)))
		end
	end
end


AutoLightOnOff = {}

AutoLightOnOff.settings = {}
AutoLightOnOff.name = g_currentModName or "FS25_AutoLightOnOff"

AutoLightOnOff.updateDelta = 0    			-- time since the last update
AutoLightOnOff.updateRate = 1000  			-- milliseconds until next update
AutoLightOnOff.lastAutomaticAction = ""     -- Values: "on", "off", ""
AutoLightOnOff.lastVehicleOrPlayer = nil
AutoLightOnOff.isInitSettingUI = false



function AutoLightOnOff:loadMap()
	dbPrintHeader("AutoLightOnOff:loadMap")
	
	InGameMenu.onMenuOpened = Utils.appendedFunction(InGameMenu.onMenuOpened, AutoLightOnOff.initSettingUI)
	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, AutoLightOnOff.saveSettings)

	AutoLightOnOff:loadSettings()
end

function AutoLightOnOff:defaultSettings()
	dbPrintHeader("AutoLightOnOff:defSettings")
	AutoLightOnOff.settings.isPlayerAutoLight = true
end

function AutoLightOnOff:saveSettings()
	dbPrintHeader("AutoLightOnOff:saveSettings")

	local modSettingsDir = getUserProfileAppPath() .. "modSettings"
	local fileName = "AutoLightOnOff.xml"
	local createXmlFile = modSettingsDir .. "/" .. fileName

	local xmlFile = createXMLFile("AutoLightOnOff", createXmlFile, "AutoLightOnOff")
	setXMLBool(xmlFile, "AutoLightOnOff.settings#isPlayerAutoLight",AutoLightOnOff.settings.isPlayerAutoLight)
	
	saveXMLFile(xmlFile)
	delete(xmlFile)
end

function AutoLightOnOff:loadSettings()
	dbPrintHeader("AutoLightOnOff:loadSettings")
	
	local modSettingsDir = getUserProfileAppPath() .. "modSettings"
	local fileName = "AutoLightOnOff.xml"
	local fileNamePath = modSettingsDir .. "/" .. fileName
	
	if fileExists(fileNamePath) then
		local xmlFile = loadXMLFile("AutoLightOnOff", fileNamePath)
		
		if xmlFile == 0 then
			dbPrintf("  Could not read the data from XML file (%s), maybe the XML file is empty or corrupted, using the default!", fileNamePath)
			AutoLightOnOff:defaultSettings()
			return
		end

		local isPlayerAutoLight = getXMLBool(xmlFile, "AutoLightOnOff.settings#isPlayerAutoLight")

		if isPlayerAutoLight == nil or isPlayerAutoLight == 0 then
			dbPrintf("  Could not parse the correct 'isPlayerAutoLight' value from the XML file, maybe it is corrupted, using the default!")
			isPlayerAutoLight = true
		end
		
		AutoLightOnOff.settings.isPlayerAutoLight = isPlayerAutoLight
		
		delete(xmlFile)
	else
		AutoLightOnOff:defaultSettings()
		dbPrintf("  NOT any File founded!, using the default settings.")
	end
end

function AutoLightOnOff:initSettingUI()
	if not AutoLightOnOff.isInitSettingUI then
		local uiSettings = AutoLightOnOffUISettings.new(AutoLightOnOff.settings,true)
		uiSettings:registerSettings()
		AutoLightOnOff.isInitSettingUI = true
	end
end


function AutoLightOnOff:update(dt)
	-- dbPrintHeader("AutoLightOnOff:update")
	AutoLightOnOff.updateDelta = AutoLightOnOff.updateDelta + dt

	if AutoLightOnOff.updateDelta > AutoLightOnOff.updateRate then
		dbPrintHeader("AutoLightOnOff:update")
		AutoLightOnOff.updateDelta = 0
		if g_currentMission:getIsClient() and g_gui.currentGui == nil then
    		local needLights = not g_currentMission.environment.isSunOn
			local curVehicle = g_localPlayer.getCurrentVehicle()


			-- print("***AutoLightOnOff:update: Light Control***")
			if curVehicle ~= nil and curVehicle.spec_lights ~= nil then
			local isMotorStarted = curVehicle.getMotorState == nil or curVehicle:getMotorState() ~= MotorState.OFF 
				-- print(string.format("  Vehicle: %s | motorState: %s | needLights: %s | isMotorStarted = %s" , curVehicle:getName(), tostring(curVehicle:getMotorState()), tostring(needLights), tostring(isMotorStarted)))

				if curVehicle.getIsAIActive == nil or not curVehicle:getIsAIActive() then
					local isLightActive = AutoLightOnOff:getIsLightTurnedOn(curVehicle)
                    AutoLightOnOff.lastAutomaticAction = AutoLightOnOff.lastVehicleOrPlayer == curVehicle and AutoLightOnOff.lastAutomaticAction or ""

					if not isLightActive and needLights and isMotorStarted then 	-- and AutoLightOnOff.lastAutomaticAction ~= "on" then
						-- turn light on
						curVehicle:setNextLightsState(curVehicle.spec_lights.numLightTypes)
						AutoLightOnOff.lastAutomaticAction = "on"
					end

					if isLightActive and ((not needLights or not isMotorStarted) and AutoLightOnOff.lastAutomaticAction ~= "off")  then
                        -- turn light off
                        curVehicle:deactivateLights(true)
                        AutoLightOnOff.lastAutomaticAction = "off"
					end
				end
                AutoLightOnOff.lastVehicleOrPlayer = curVehicle
			elseif g_localPlayer ~= nil and AutoLightOnOff.settings.isPlayerAutoLight then
                AutoLightOnOff.lastAutomaticAction = AutoLightOnOff.lastVehicleOrPlayer == g_localPlayer and AutoLightOnOff.lastAutomaticAction or ""

				if not g_localPlayer.isFlashlightActive and needLights and AutoLightOnOff.lastAutomaticAction ~= "on" then
                    -- turn light on
                    g_localPlayer:setFlashlightIsActive(true)
                    AutoLightOnOff.lastAutomaticAction = "on"
				end
				if g_localPlayer.isFlashlightActive and not needLights and AutoLightOnOff.lastAutomaticAction ~= "off" then
                    -- turn light off
                    g_localPlayer:setFlashlightIsActive(false)	-- todo: change hand tool to default or better to last active hand tool
                    AutoLightOnOff.lastAutomaticAction = "off"
				end
                AutoLightOnOff.lastVehicleOrPlayer = g_localPlayer
			end
		end
	end
end

function AutoLightOnOff:getIsLightTurnedOn(vehObj)
	dbPrintHeader("AutoLightOnOff:getIsLightTurnedOn")
	if vehObj.spec_lights ~= nil and vehObj.spec_lights.currentLightState > 0 then
		return true
	else
		return false
	end
end

-- function AutoLightOnOff:loadMap(name)end
-- function AutoLightOnOff:registerActionEvents() end
-- function AutoLightOnOff:onLoad(savegame)end
-- function AutoLightOnOff:onUpdate(dt)end
-- function AutoLightOnOff:deleteMap()end
-- function AutoLightOnOff:keyEvent(unicode, sym, modifier, isDown)end
-- function AutoLightOnOff:mouseEvent(posX, posY, isDown, isUp, button)end
-- function AutoLightOnOff:draw()end

addModEventListener(AutoLightOnOff)