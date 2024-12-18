-- Author: Fetty42
-- Date: 14.12.2024
-- Version: 1.0.0.0


AutoLightOnOff = {}

AutoLightOnOff.updateDelta = 0    			-- time since the last update
AutoLightOnOff.updateRate = 200  			-- milliseconds until next update
AutoLightOnOff.lastAutomaticAction = ""     -- Values: "on", "off", ""
AutoLightOnOff.lastVehicleOrPlayer = nil


function AutoLightOnOff:update(dt)
	AutoLightOnOff.updateDelta = AutoLightOnOff.updateDelta + dt

	if AutoLightOnOff.updateDelta > AutoLightOnOff.updateRate then
		-- print("AutoLightOnOff:update")
		AutoLightOnOff.updateDelta = 0
		if g_currentMission:getIsClient() and g_gui.currentGui == nil then
    		local needLights = not g_currentMission.environment.isSunOn
			local curVehicle = g_localPlayer.getCurrentVehicle()


			-- print("***AutoLightOnOff:update: Light Control***")
			if curVehicle ~= nil and curVehicle.spec_lights ~= nil then

				if curVehicle.getIsAIActive == nil or not curVehicle:getIsAIActive() then
					local isLightActive = AutoLightOnOff:getIsLightTurnedOn(curVehicle)
                    AutoLightOnOff.lastAutomaticAction = AutoLightOnOff.lastVehicleOrPlayer == curVehicle and AutoLightOnOff.lastAutomaticAction or ""

					if not isLightActive and needLights then 	-- and AutoLightOnOff.lastAutomaticAction ~= "on" then
						-- turn light on
						curVehicle:setNextLightsState(curVehicle.spec_lights.numLightTypes)
						AutoLightOnOff.lastAutomaticAction = "on"
					end

					if isLightActive and not needLights and AutoLightOnOff.lastAutomaticAction ~= "off" then
                        -- turn light off
                        curVehicle:deactivateLights(true)
                        AutoLightOnOff.lastAutomaticAction = "off"
					end
				end
                AutoLightOnOff.lastVehicleOrPlayer = curVehicle
			elseif g_localPlayer ~= nil then
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