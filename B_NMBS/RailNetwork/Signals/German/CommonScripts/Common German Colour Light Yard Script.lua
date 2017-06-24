--------------------------------------------------------------------------------------
-- Common signal functionality for German Colour Light signals that guard yard entries and/or exits
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- SET LIGHTS
-- Called by SetState to switch the appropriate lights for this signal type on/off according to its new state

function SetLights ( newState )
	
	if (newState == SIGNAL_CLEARED) then
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Orange", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Green", 1 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_White01", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_White02", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Red01", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Red02", 0 )
	elseif (newState == SIGNAL_BLOCKED) then
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Orange", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Green", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_White01", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_White02", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Red01", 1 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Red02", 0 )
	elseif (newState == SIGNAL_WARNING) then
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Orange", 1 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Green", 1 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_White01", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_White02", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Red01", 0 )
		Call( "HP Signal Head:ActivateNode", "GR_Mod_Home_Red02", 0 )
	else
		Print( ("ERROR: SetLights trying to switch to invalid state " .. newState ) )
	end
end

--------------------------------------------------------------------------------------
-- UPDATE
-- This is now only called to initialise the signal lights when the route finishes loading
-- (Because you can't set the lights until the route finishes loading)
--
function Update (time)
	DefaultUpdate()
end

--------------------------------------------------------------------------------------
-- ON CONSIST PASS
-- OnConsistPass function used specifically by German home scripts.
-- Uses special signal messages to set signals to red by default, changing to green when the train enters the preceding block
--
function OnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	local crossingStart = 0
	local crossingEnd = 0

	-- if the consist is crossing the signal now
	if ( frontDist > 0 and backDist < 0 ) or ( frontDist < 0 and backDist > 0 ) then
		-- if the consist was previously before/after siganl then the crossing has just started
		if ( prevFrontDist < 0 and prevBackDist < 0 ) or ( prevFrontDist > 0 and prevBackDist > 0 ) then
			DebugPrint( ("DEBUG: OnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingStart = 1
		end
		
	-- otherwise the consist is not crossing the signal now
	else	
		-- the the consist was previously crossing the signal, then it has just finished crossing
		if ( prevFrontDist < 0 and prevBackDist > 0 ) or ( prevFrontDist > 0 and prevBackDist < 0 ) then
			DebugPrint( ("DEBUG: OnConsistPass: Crossing cleared... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingEnd = 1
		end
	end
		
	-- a train has just started crossing a link!
	if (crossingStart == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the normal direction...
		if (prevFrontDist > 0 and prevBackDist > 0) then
			
			DebugPrint( "DEBUG: OnConsistPass: Started crossing forwards!" )
			
			-- if the train just started crossing link 0 in the normal direction, increment occupation table slot 0
			if (linkIndex == 0) then
				
				-- Check for SPADs first
				if gSignalState == SIGNAL_BLOCKED then
					DebugPrint("SPAD")
					Call( "SendConsistMessage", SPAD_MESSAGE, "" )
					Call( "SendConsistMessage", TPWS_MESSAGE, "blocked" )					

				-- If we're at warning, check player has slowed to correct speed
				elseif gSignalState == SIGNAL_WARNING then
				
					-- Get consist speed and track speed limit (always 40km/h for warning signal)
					local consistSpeed = Call ( "GetConsistSpeed" )
					local speedLimit = 41 / 3.6			-- 40 km/h in m/s, plus 1 km/h leeway
				
					DebugPrint(( "DEBUG: OnConsistPass: consistSpeed = " .. consistSpeed .. ", speedLimit = " .. speedLimit))
								
					if (consistSpeed > speedLimit) then
						DebugPrint("DEBUG: OnConsistPass: Consist is exceeding speed limit")
						Call( "SendConsistMessage", TPWS_MESSAGE, "overspeed" )					
					end
				end
	
				-- set signal to blocked if not already blocked (checked in Occupied function)
				Occupied( 0 )
				
				gOccupationTable[0] = gOccupationTable[0] + 1
				DebugPrint( ("DEBUG: OnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				
				-- send a signal message up the track to tell the next signal to turn green! (if it's not already prepared for another train)
				if gOccupationTable[0] == 1 and gConnectedLink ~= -1 and (gConnectedLink == 0 or gOccupationTable[gConnectedLink] == 0) then
					-- Doesn't matter that this message is sent forwards from link 0, because anything other than link 0 just forwards it on anyway
					-- Need to send from link 0 to make sure it hits any repeater signals between here and the next home signal
					Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", 1, 1, 0 )
				end

			-- Ignore any links that are yard entries - once a train gets into a yard, the yard's entry signal doesn't care about it anymore
			elseif (linkIndex >= gLinkCount - gYardEntryLinks) then
				-- Do nothing
				
			elseif (linkIndex == 1 and gYardEntryLink1) then
				-- Do nothing
				
			-- if the train just started crossing another link. increment the appropriate occupation table slot
			elseif (linkIndex > 0) then
				gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
				DebugPrint( ("DEBUG: OnConsistPass: INCREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the opposite direction...
		elseif (prevFrontDist < 0 and prevBackDist < 0) then
			
			DebugPrint( "DEBUG: OnConsistPass: Started crossing backwards!" )
			
			-- if the train just started crossing link 0 in reverse, send OCCUPATION_INCREMENT
			if (linkIndex == 0) then

				DebugPrint( "DEBUG: OnConsistPass: A train starts passing link 0 in the opposite direction." )
				
				-- If we're the only train in this signal's block(s) and the line is connected...
				if gOccupationTable[0] == 1 and gConnectedLink ~= -1 then

					-- Get this signal's link state
					local signalStateMessage = gLinkState[gConnectedLink]
				    DebugPrint( "DEBUG: OnConsistPass: Send signal message " .. signalStateMessage)
					Call( "SendSignalMessage", signalStateMessage, "", -1, 1, 0 )
				end

				DebugPrint( "DEBUG: OnConsistPass: Send OCCUPATION_INCREMENT." )
				Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )

			-- if the train just started crossing link 1, 2, 3 etc. in reverse, increment occupation table slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line, or exit signal for connected line
				if (gConnectedLink == linkIndex) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint( ("DEBUG: OnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )

					-- If the train's coming out of a yard, need to set signal to blocked now
					if (linkIndex >= gLinkCount - gYardEntryLinks) then
						Occupied( linkIndex )
						
					elseif (linkIndex == 1 and gYardEntryLink1) then
						Occupied( linkIndex )
					end

				-- Otherwise  the train must be reversing onto another line
				else
					DebugPrint( "DEBUG: OnConsistPass: Consist reversing down another line, don't increment occupation table for this line" )
				end
			end
		end
		
	-- a train has just finished crossing a link!
	elseif (crossingEnd == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing backwards...
		if (frontDist > 0 and backDist > 0) then
			
			DebugPrint( "DEBUG: OnConsistPass: Finished crossing backwards!" )
			
			-- if the train just finished crossing link 0 in reverse, decrement occupation table slot 0
			if (linkIndex == 0) then
			
				if not (gPrepared or gYardExit) then
					gPrepared = true
					DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Prepared" ) )

					-- Send a signal back down the track to prepare any repeater signals (home signals will ignore PREPARE messages coming in this direction)
					Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", -1, 1, 0 )
				end
				
				if gOccupationTable[0] > 0 then
					gOccupationTable[0] = gOccupationTable[0] - 1
					DebugPrint( ("DEBUG: OnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				else
					Print( "DEBUG: OnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
				end
			
				-- and also set signal to cleared if not blocked by another consist and junction is connected
				if (gOccupationTable[0] == 0 and gConnectedLink ~= -1 and gOccupationTable[gConnectedLink] == 0) then
				
					-- If we're linked to the siding, we don't care about the state of the signal at the other end of the siding - always show green
					if gConnectedLink >= gLinkCount - gYardEntryLinks then
						NotOccupied( gConnectedLink )
						
					elseif linkIndex == 1 and gYardEntryLink1 then
						NotOccupied( gConnectedLink )
						
					-- Otherwise show the appropriate signal based on the state of the connected link
					else
						CheckSignalState()

						-- the only train in this signal's block has just left, reset the next signal up the line to red!
							-- Doesn't matter that this message is sent forwards from link 0, because anything other than link 0 just forwards it on anyway
							-- Need to send from link 0 to make sure it hits any repeater signals between here and the next home signal
						Call( "SendSignalMessage", SIGNAL_RESET_AFTER_TRAIN_PASS, "", 1, 1, 0 )
					end
				end
				
			-- Ignore any links that are yard entries - once a train gets into a yard, the yard's entry signal doesn't care about it anymore
			elseif (linkIndex >= gLinkCount - gYardEntryLinks) then
				-- Do nothing
				
			elseif (linkIndex == 1 and gYardEntryLink1) then
				-- Do nothing

			-- if the train just finished crossing link 1, 2, 3 etc. in reverse, decrement the appropriate occupation table slot
			elseif (linkIndex > 0) then
				if gOccupationTable[linkIndex] > 0 then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
					DebugPrint( ("DEBUG: OnConsistPass: DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
				else
					Print( ( "DEBUG: OnConsistPass: Attempting to DECREMENT... gOccupationTable[" .. linkIndex .. "] was already empty" ) )
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing in the normal direction...
		elseif (frontDist < 0 and backDist < 0) then
			
			DebugPrint( "DEBUG: OnConsistPass: Finished crossing forwards!" )
			
			-- if the train just finished crossing link 0 in the normal direction, send OCCUPATION_DECREMENT
			if (linkIndex == 0) then
			
				if gPrepared and not gYardExit then
					gPrepared = false
					DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Not Prepared" ) )

					-- Send a signal back down the track to reset any repeater signals (home signals will ignore RESET messages coming in this direction)
					Call( "SendSignalMessage", SIGNAL_RESET_AFTER_TRAIN_PASS, "", -1, 1, 0 )
				end

				DebugPrint( "DEBUG: OnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT." )
				Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
				
			-- if the train just finished crossing link 1, 2, 3 etc. in the normal direction, decrement occupation slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line, or exit signal for connected line
				if (gConnectedLink == linkIndex) then
					if gOccupationTable[0] > 0 then
						gOccupationTable[0] = gOccupationTable[0] - 1
						DebugPrint( ("DEBUG: OnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
						
						-- If we've gone into a siding, signal should go clear now
						if linkIndex >= gLinkCount - gYardEntryLinks or (linkIndex == 1 and gYardEntryLink1) then
							-- Junction state and occupation table checked in NotOccupied()
							NotOccupied(linkIndex)
						end
					else
						Print( "DEBUG: OnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
					end
				else
					DebugPrint( "DEBUG: BaseOnConsistPass: Consist on another line, don't decrement occupation table for this line" )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- JUNCTION STATE CHANGE
-- Called when a junction is changed. Should only be handled by home signals.
--
function OnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	-- Use the default function for this
	DefaultOnJunctionStateChange( junction_state, parameter, direction, linkIndex )
end

-------------------------------------------------------------------------------------
-- REACT TO SIGNAL MESSAGE
-- Subfunction to save duplicate code when handling pass back messages - just takes all the old scripting out of the OnSignalMessage function
--
function ReactToSignalMessage( message, parameter, direction, linkIndex )

--	DebugPrint( ("DEBUG: ReactToSignalMessage(" .. message .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )

	-- Only pay attention to this message if it didn't come from in a yard
	if (linkIndex >= gLinkCount - gYardEntryLinks) or (linkIndex == 1 and gYardEntryLink1) then
		-- Do nothing!
		DebugPrint( ("DEBUG: OnSignalMessage: message received on link " .. linkIndex .. " - yard entry signal ignoring it") )
	
	elseif ( message == SIGNAL_CLEARED or message == SIGNAL_WARNING or message == SIGNAL_WARNING2 ) then
		NotOccupied( linkIndex )
		
	elseif ( message == SIGNAL_BLOCKED ) then
		Warning( linkIndex )
		
	elseif (message == OCCUPATION_DECREMENT) then
		if gOccupationTable[linkIndex] > 0 then
			gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
			DebugPrint( ("DEBUG: HP_MOD_Home 3Asp OnSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		else
			Print( ("DEBUG: HP_MOD_Home 3Asp OnSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "] was already 0!") )
		end
	
		-- Go to warning if all trains have left junction and line is connected (this is checked inside the Warning function)
		Warning( linkIndex )

	elseif (message == OCCUPATION_INCREMENT) then
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: HP_MOD_Home 3Asp OnSignalMessage: OCCUPATION_INCREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		
		-- If this is the connected link, set the signal to blocked
		if (gConnectedLink == linkIndex) then
			Occupied( linkIndex )
		end
		
	-- added a special message for when the signal is initialised with a consist in its signal block (ignored by dist signals)				
	elseif (message == INITIALISE_SIGNAL_TO_BLOCKED) then
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: OnSignalMessage: INITIALISE_SIGNAL_TO_BLOCKED received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		
	-- GERMAN SPECIFIC functionality: special message for when a train starts in the previous signal block, so the signal can go green
	elseif (message == INITIALISE_TO_PREPARED) then
		DebugPrint( ("DEBUG: OnSignalMessage: INITIALISE_TO_PREPARED received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )

		-- only pay attention to messages arriving on link 0 - any other messages will be PASSed on
		if linkIndex == 0 and not gYardExit then
			SignalPrepared( linkIndex )
			
			-- Send a signal back down the track to prepare any repeater signals (home signals will ignore PREPARE messages coming in this direction)
			Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", -1, 1, 0 )
		end
		
	-- GERMAN SPECIFIC functionality: special message for when a train enters the previous signal block, so the signal can go green
		-- JB 01/05/07 - Only pay attention to this message if it's coming from behind us (because of a train going past the previous signal)
			-- All other SIGNAL_PREPARE_FOR_TRAIN messages are for distance signals only
	elseif (message == SIGNAL_PREPARE_FOR_TRAIN and direction == -1) then

		-- only pay attention to messages arriving on link 0 - any other messages will be PASSed on
		if linkIndex == 0 and not gYardExit then
			SignalPrepared( linkIndex )
		end
		
	-- GERMAN SPECIFIC functionality: special message for when the signal is passed backwards, so the signal can turn red again
		-- JB 01/05/07 - Only pay attention to this message if it's coming from behind us (because of a train reversing over a signal)
			-- All other SIGNAL_RESET_AFTER_TRAIN_PASS messages are for distance signals only
	elseif (message == SIGNAL_RESET_AFTER_TRAIN_PASS and direction == -1) then

		-- only pay attention to messages arriving on link 0 - any other messages will be PASSed on
		if linkIndex == 0 and not gYardExit then
			SignalReset( linkIndex )
		end

	-- JB 04/05/07 - New junction state change message added
	elseif (message == JUNCTION_STATE_CHANGE) then
		-- Only act on message if it arrived at link 0, junction_state parameter is "0", and this signal spans a junction (ie, has more than one link)
		if gInitialised and linkIndex == 0 and parameter == "0" and gLinkCount > 1 then
			OnJunctionStateChange( 0, "", 1, 0 )
			
			-- Pass on message in case junction is protected by more than one signal
				-- NB: this message is passed on when received on link 0 instead of link 1+
				-- When it reaches a link > 0 or a signal with only one link, it will be consumed
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
		end
				
	-- This message is to reset the signals after a scenario / route is reset
	elseif (message == RESET_SIGNAL_STATE) then
		ResetSignalState()
	end
end

-------------------------------------------------------------------------------------
-- ON SIGNAL MESSAGE
-- Handles messages from other signals. 
--
function OnSignalMessage( message, parameter, direction, linkIndex )
	-- Use default
	DefaultOnSignalMessage( message, parameter, direction, linkIndex )
end

--------------------------------------------------------------------------------------
-- OCCUPIED
--
function Occupied( linkIndex )

	DebugPrint( ("DEBUG: HP_MOD_Home 3Asp Occupied(" .. linkIndex .. ")") )

	SetState( SIGNAL_BLOCKED )

	-- Set signal to BLOCKED and pass back a message
	if gSignalState ~= SIGNAL_BLOCKED then
		gSignalState = SIGNAL_BLOCKED
		Call( "SendSignalMessage", SIGNAL_BLOCKED, "", -1, 1, 0 )
	end
	
	-- Don't want to keep track of whether a link is blocked, as that only comes from trains in the block or junctions disconnected (both of which we check for already)
	-- If we stored Blocked information, it would overwrite stuff we want to keep!
end

--------------------------------------------------------------------------------------
-- NOTOCCUPIED
--
function NotOccupied( linkIndex )

	DebugPrint( ( "DEBUG: HP_MOD_Home 3Asp NotOccupied(" .. linkIndex .. ")" ) )

	if (linkIndex == 0 and gConnectedLink > 0) then
		linkIndex = gConnectedLink
	end
	
	local newState = SIGNAL_CLEARED

	-- If we're going off-line, signal should be warning
	if gConnectedLink > 1 then
		newState = SIGNAL_WARNING
	end

	-- JB 01/05/07 - Double check that we're connected
	if (gConnectedLink == linkIndex) then
	
		-- Only change signal if the current link is cleared!
		if (gOccupationTable[linkIndex] ~= nil) and 
			(gOccupationTable[linkIndex] == 0) and
			(gOccupationTable[0] == 0) then

			SetState( newState )
			
			-- Set signal to newState and pass back a message
			if gSignalState ~= newState then	
				gSignalState = newState
				Call( "SendSignalMessage", newState, "", -1, 1, 0 )
			end
		end
	end
	
	-- Set this link as Clear (regardless of whether we're going off line or not - this is the state of the link, NOT the signal!)
	DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Cleared" ) )
	gLinkState[linkIndex] = SIGNAL_CLEARED
end

--------------------------------------------------------------------------------------
-- WARNING
-- Tells the signal to display that there is a warning ahead
--
function Warning( linkIndex )

	DebugPrint( ("DEBUG: HP_MOD_Home 3Asp Warning(" .. linkIndex .. ")") )

	if (linkIndex == 0 and gConnectedLink > 0) then
		linkIndex = gConnectedLink
	end

	-- JB 01/05/07 - Double check that we're connected
	if (gConnectedLink == linkIndex) then

		-- Only change signal if the current link is cleared!
		if (gOccupationTable[linkIndex] ~= nil) and 
			(gOccupationTable[linkIndex] == 0) and
			(gOccupationTable[0] == 0) then

			SetState( SIGNAL_WARNING )
		
			-- Set signal to WARNING and pass back a message
			if gSignalState ~= SIGNAL_WARNING then
				gSignalState = SIGNAL_WARNING
				Call( "SendSignalMessage", SIGNAL_WARNING, "", -1, 1, 0 )
			end
		end
	end

	-- Set this signal as Warning
--	DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Warning" ) )
	gLinkState[linkIndex] = SIGNAL_WARNING
end

--------------------------------------------------------------------------------------
-- SIGNAL PREPARED
-- Tells the signal to prepare for a train approaching it
--
function SignalPrepared( linkIndex )

	DebugPrint( ("DEBUG: HP_MOD_Home 3Asp SignalPrepared(" .. linkIndex .. ")") )
	
	if not gPrepared then
		local newState = -1
		
		-- This is always triggered by a message on linkIndex 0, so need to find correct link to use
		if gLinkCount <= 2 then
			linkIndex = gLinkCount - 1
		else
			linkIndex = gConnectedLink
		end	
		
		-- Switch signal based on state of signal
		if gConnectedLink == -1 then
			newState = SIGNAL_BLOCKED
		elseif gOccupationTable[0] > 0 or gOccupationTable[linkIndex] > 0 then
			newState = SIGNAL_BLOCKED
		else
			newState = gSignalState
		end

--		DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Prepared" ) )
		gPrepared = true
		SetState( newState )
	end
end

--------------------------------------------------------------------------------------
-- SIGNAL RESET
-- Tells the signal to reset to red because of train entering its block from wrong end
--
function SignalReset( linkIndex )

	DebugPrint( ("DEBUG: HP_MOD_Home 3Asp SignalReset(" .. linkIndex .. ")") )

	if gPrepared then
--		DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Not Prepared" ) )
		gPrepared = false
		SetState( gSignalState )
	end
end
