--------------------------------------------------------------------------------------
-- Common signal functionality
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

-- DEFAULT INITIALISE
-- New globals have been added to cater for the German-specific "slow" state functionality
--
function DefaultInitialise ( )
	
	-- call the common functionality of the base initialisation. creates 
	-- gLinkCount and the table containing occupation information
	BaseInitialise()
	
	-- the different types of signal
	SIGNALTYPE_HOME			= 0
	SIGNALTYPE_DISTANCE		= 1
	
	-- Signal state defaults to clear (but signal will only turn green if there's a train approaching it)
	gSignalState = SIGNAL_CLEARED
	
	gInitialised = false

	-- Keep track of whether the signal's prepared for a train
	gPrepared = false
	
	-- Tells the game to do an update tick once the route finishes loading
	-- This will initialise the lights on the signals, which can't be changed until the route is loaded
	Call( "BeginUpdate" )
end

--------------------------------------------------------------------------------------
-- SET STATE
-- This is not so simple, as we have to keep track of all multiple arm states here
-- I added some bugfixing at the start of this function to set the correct arm number
--
function SetState( newState )

	-- If we're not prepared for a train, stay at red
	if not gPrepared then
		DebugPrint( ( "DEBUG: SetState: Set signal to " .. newState .. " from " .. gSignalState .. " (Not Prepared)" ) )
		Call ("Set2DMapSignalState", BLOCKED)
		SetLights(SIGNAL_BLOCKED)
		
	-- otherwise update the lights according to the new  state
	elseif (newState == SIGNAL_CLEARED) then
		DebugPrint( ( "DEBUG: SetState: Set signal to CLEARED from " .. gSignalState ) )
		Call ("Set2DMapSignalState", CLEAR)
		SetLights(SIGNAL_CLEARED)
		
	elseif (newState == SIGNAL_BLOCKED) then
		DebugPrint( ( "DEBUG: SetState: Set signal to BLOCKED from " .. gSignalState ) )
		Call ("Set2DMapSignalState", BLOCKED)
		SetLights(SIGNAL_BLOCKED)
		
	elseif (newState == SIGNAL_WARNING) then
		DebugPrint( ( "DEBUG: SetState: Set signal to WARNING from " .. gSignalState ) )
		Call ("Set2DMapSignalState", WARNING)
		SetLights(SIGNAL_WARNING)
	else
		Print( ("ERROR: SetState passed invalid newState " .. newState ) )
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT UPDATE
-- No animation needed, as there are no moving components in coloured lights
--
function DefaultUpdate( time )

	gInitialised = true
	
	-- If we're a junction signal, check which link is connected now
	if gLinkCount > 1 then
		OnJunctionStateChange( 0, "", 1, 0 )
	end

	-- If we've not been set to anything else yet, make sure lights are set to clear
	if gSignalState == SIGNAL_CLEARED then
		SetState(SIGNAL_CLEARED)
	end
	
	Call( "EndUpdate" )
end

--------------------------------------------------------------------------------------
-- JUNCTION STATE CHANGE
-- Called when a junction is changed. Should only be handled by home signals.
--
-- The message is received by all nodes near the junction, but is only picked up by the signal 
-- just before the start of the junction (which should be a home signal - if it's a dist then content
-- have likely put a dist signal in the wrong place (i.e. next to a junction). 
--
function DefaultOnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: DefaultOnJunctionStateChange(" .. junction_state .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check junction has finished transition
	if junction_state == 0 then
		if linkIndex == 0 then
			if gLinkCount == 1 then
				DebugPrint( "WARNING: DefaultOnJunctionStateChange: Junction change message received by single link signal" )
			else
				-- this will be used as a search depth - it must be passed as a string
				linkCountAsString = "" .. (5 * (gLinkCount + 1))
				
				-- find the link that is now connected to the signal
				local newConnectedLink = Call( "GetConnectedLink", linkCountAsString, 1, 0 )
				
				if newConnectedLink == gConnectedLink then
					-- Don't waste time doing anything else if the connected link hasn't changed
					DebugPrint( ("DEBUG: DefaultOnJunctionStateChange: Activate connected link: " .. gConnectedLink .. " (no change)") )
				else
					-- If we were connected, there's a train in the 0 link and nothing in the previously connected link, the signal was prepared but shouldn't be anymore
					if (gConnectedLink ~= - 1 and gOccupationTable[0] > 0 and gOccupationTable[gConnectedLink] == 0) then
						-- JB 03/05/07 - Fix for bug #3930 - Need to reset the next signal on the previously connected line
						Call( "SendSignalMessage", SIGNAL_RESET_AFTER_TRAIN_PASS, "", 1, 1, gConnectedLink )
					end
					
					gConnectedLink = newConnectedLink
					
					DebugPrint( ("DEBUG: DefaultOnJunctionStateChange: Activate connected link: " .. gConnectedLink) )
				
					if gConnectedLink > 0 then
						
						-- Update occupation
						DebugPrint( ("DEBUG: DefaultOnJunctionStateChange: Update occupation: gOccupationTable[" .. gConnectedLink .. "]: " .. gOccupationTable[gConnectedLink]) )

						-- If we're connected, there's a train in the 0 link and nothing in the connected link, the signal probably wasn't prepared but should be now
						if (gOccupationTable[0] > 0 and gOccupationTable[gConnectedLink] == 0) then
							-- JB 03/05/07 - Fix for bug #3930 - Need to prepare the next signal on the newly connected line
								-- Doesn't matter that this message is sent forwards from link 0, because anything other than link 0 just forwards it on anyway
								-- Need to send from link 0 to make sure it hits any repeater signals between here and the next home signal
							Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", 1, 1, 0 )
						end
						
						-- BUGFIX - Do additional check for gConnectedLink 0... If that is blocked, then the junction is blocked as well
						if (gOccupationTable[gConnectedLink] == 0) and (gOccupationTable[0] == 0) then					
							-- JB 26/04/07 - Fix for bug #3759 - Change signal based on state of connected link instead of just setting it to green
							CheckSignalState( )
							
							-- JB 02/05/07 - Need to pass back a message here, as German signals wouldn't send one otherwise
							-- JB 24/05/07 - No longer needed
--						DebugPrint( ( "DEBUG: HP_MOD_Home 3Asp OnJunctionStateChange: Send " .. gLinkState[gConnectedLink] .. " message" ) )
--						Call( "SendSignalMessage", gLinkState[gConnectedLink], "", -1, 1, 0 )
						else
							Occupied( gConnectedLink )
						end
						
					-- AEH 13/04/2007: set the junction to blocked if there's no valid exit from it (eg for crossover when points at other end of linking track are set against us)
					elseif gConnectedLink == -1 then
					       Occupied( 0 )
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- ON CONSIST PASS
--
function DefaultOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	local crossingStart = 0
	local crossingEnd = 0

	-- if the consist is crossing the signal now
	if ( frontDist > 0 and backDist < 0 ) or ( frontDist < 0 and backDist > 0 ) then
		-- if the consist was previously before/after siganl then the crossing has just started
		if ( prevFrontDist < 0 and prevBackDist < 0 ) or ( prevFrontDist > 0 and prevBackDist > 0 ) then
			DebugPrint( ("DEBUG: DefaultOnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingStart = 1
		end
		
	-- otherwise the consist is not crossing the signal now
	else	
		-- the the consist was previously crossing the signal, then it has just finished crossing
		if ( prevFrontDist < 0 and prevBackDist > 0 ) or ( prevFrontDist > 0 and prevBackDist < 0 ) then
			DebugPrint( ("DEBUG: DefaultOnConsistPass: Crossing cleared... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingEnd = 1
		end
	end
	
	-- a train has just started crossing a link!
	if (crossingStart == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the normal direction...
		if (prevFrontDist > 0 and prevBackDist > 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Started crossing forwards!" )
			
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
				
					DebugPrint(( "DEBUG: DefaultOnConsistPass: consistSpeed = " .. consistSpeed .. ", speedLimit = " .. speedLimit))
								
					if (consistSpeed > speedLimit) then
						DebugPrint("DEBUG: DefaultOnConsistPass: Consist is exceeding speed limit")
						Call( "SendConsistMessage", TPWS_MESSAGE, "overspeed" )					
					end
				end
					
				-- set signal to blocked if not already blocked (checked in Occupied function)
				Occupied( 0 )
				
				gOccupationTable[0] = gOccupationTable[0] + 1
				DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				
				-- send a signal message up the track to tell the next signal to turn green! (if it's not already prepared for another train)
				if gOccupationTable[0] == 1 and gConnectedLink ~= -1 and (gConnectedLink == 0 or gOccupationTable[gConnectedLink] == 0) then
					-- Doesn't matter that this message is sent forwards from link 0, because anything other than link 0 just forwards it on anyway
					-- Need to send from link 0 to make sure it hits any repeater signals between here and the next home signal
					Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", 1, 1, 0 )
				end
				
			-- if the train just started crossing link 1, 2, 3 etc. increment the appropriate occupation table slot
			elseif (linkIndex > 0) then
				gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
				DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the opposite direction...
		elseif (prevFrontDist < 0 and prevBackDist < 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Started crossing backwards!" )
			
			-- if the train just started crossing link 0 in reverse, send OCCUPATION_INCREMENT
			if (linkIndex == 0) then

				DebugPrint( "DEBUG: DefaultOnConsistPass: A train starts passing link 0 in the opposite direction." )
				
				-- If we're the only train in this signal's block(s) and the line is connected...
				if gOccupationTable[0] == 1 and gConnectedLink ~= -1 then

					-- Get this signal's link state
					local signalStateMessage = gLinkState[gConnectedLink]
				    DebugPrint( "DEBUG:DefaultOnConsistPass: Send signal message " .. signalStateMessage)
					Call( "SendSignalMessage", signalStateMessage, "", -1, 1, 0 )
				end

				DebugPrint( "DEBUG: DefaultOnConsistPass: Send OCCUPATION_INCREMENT." )
				Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )

			-- if the train just started crossing link 1, 2, 3 etc. in reverse, increment occupation table slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line, or exit signal for connected line
				if (gConnectedLink == linkIndex) or (gLinkCount == 2 and gConnectedLink ~= -1) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )

				-- Otherwise  the train must be reversing onto another line
				else
					DebugPrint( "DEBUG: DefaultOnConsistPass: Consist reversing down another line, don't increment occupation table for this line" )
				end
			end
		end
		
	-- a train has just finished crossing a link!
	elseif (crossingEnd == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing backwards...
		if (frontDist > 0 and backDist > 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Finished crossing backwards!" )
			
			-- if the train just finished crossing link 0 in reverse, decrement occupation table slot 0
			if (linkIndex == 0) then
			
				if not gPrepared then
					gPrepared = true
					DebugPrint( ( "DEBUG: DefaultOnConsistPass: Link " .. linkIndex .. " is now Prepared" ) )

					-- Send a signal back down the track to prepare any repeater signals (home signals will ignore PREPARE messages coming in this direction)
					Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", -1, 1, 0 )
				end
			
				if gOccupationTable[0] > 0 then
					gOccupationTable[0] = gOccupationTable[0] - 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				else
					Print( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
				end
			
				-- and also set signal to cleared if not blocked by another consist and junction is connected
				if (gOccupationTable[0] == 0 and gConnectedLink ~= -1 and gOccupationTable[gConnectedLink] == 0) then
					CheckSignalState( )
				
					-- the only train in this signal's block has just left, reset the next signal up the line to red!
						-- Doesn't matter that this message is sent forwards from link 0, because anything other than link 0 just forwards it on anyway
						-- Need to send from link 0 to make sure it hits any repeater signals between here and the next home signal
					Call( "SendSignalMessage", SIGNAL_RESET_AFTER_TRAIN_PASS, "", 1, 1, 0 )
				end
				
			-- if the train just finished crossing link 1, 2, 3 etc. in reverse, decrement the appropriate occupation table slot
			elseif (linkIndex > 0) then
				if gOccupationTable[linkIndex] > 0 then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
				else
					Print( ( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[" .. linkIndex .. "] was already empty" ) )
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing in the normal direction...
		elseif (frontDist < 0 and backDist < 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Finished crossing forwards!" )
			
			-- if the train just finished crossing link 0 in the normal direction, send OCCUPATION_DECREMENT
			if (linkIndex == 0) then
				if gPrepared then
					gPrepared = false
					DebugPrint( ( "DEBUG: DefaultOnConsistPass: Link " .. linkIndex .. " is now Not Prepared" ) )

					-- Send a signal back down the track to reset any repeater signals (home signals will ignore RESET messages coming in this direction)
					Call( "SendSignalMessage", SIGNAL_RESET_AFTER_TRAIN_PASS, "", -1, 1, 0 )
				end

				DebugPrint( "DEBUG: DefaultOnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT." )
				Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
				
			-- if the train just finished crossing link 1, 2, 3 etc. in the normal direction, decrement occupation slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line, or exit signal for connected line
				if (gConnectedLink == linkIndex) or (gLinkCount == 2 and gConnectedLink ~= -1) then
					if gOccupationTable[0] > 0 then
						gOccupationTable[0] = gOccupationTable[0] - 1
						DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
					else
						Print( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
					end
				else
					DebugPrint( "DEBUG: DefaultOnConsistPass: Consist on another line, don't decrement occupation table for this line" )
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------
-- DEFAULT REACT TO SIGNAL MESSAGE
-- Subfunction to save duplicate code when handling pass back messages - just takes all the old scripting out of the OnSignalMessage function
--
function DefaultReactToSignalMessage( message, parameter, direction, linkIndex )

--	DebugPrint( ("DEBUG: DefaultReactToSignalMessage(" .. message .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )

	-- set the signal to occupied or not occupied depending on what the next home signal has sent it
	if ( message == SIGNAL_CLEARED or message == SIGNAL_WARNING or message == SIGNAL_WARNING2 ) then
		NotOccupied( linkIndex )
		
	elseif ( message == SIGNAL_BLOCKED ) then
		Warning( linkIndex )
		
	elseif (message == OCCUPATION_DECREMENT) then
		-- update the occupation table for this signal given the information that a train has just left this block and entered the next block
		if gOccupationTable[linkIndex] > 0 then
			gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
			DebugPrint( ("DEBUG: DefaultReactToSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		else
			Print( ("DEBUG: DefaultReactToSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "] was already 0!") )
		end
		
		-- If there's another train still in this signal's block, then the next signal up the line has been reset by consist pass but should still be prepared
		if gOccupationTable[linkIndex] > 0 or (gConnectedLink == linkIndex and gOccupationTable[0] > 0) then
			Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", 1, 1, linkIndex )
		end
		
		-- Go to warning if all trains have left junction and line is connected (this is checked inside the Warning function)
		Warning( linkIndex )

	elseif (message == OCCUPATION_INCREMENT) then
		-- update the occupation table for this signal given the information that 
		-- a train has just entered this block and left the last block
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: DefaultReactToSignalMessage: OCCUPATION_INCREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		
		-- If this is the connected link, set the signal to blocked
		if (gConnectedLink == linkIndex) then
			Occupied( linkIndex )
		end
		
	-- added a special message for when the signal is initialised with a consist in its signal block (ignored by dist signals)				
	elseif (message == INITIALISE_SIGNAL_TO_BLOCKED) then
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: DefaultReactToSignalMessage: INITIALISE_SIGNAL_TO_BLOCKED received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )

		-- This is only required for single link signals - other signals will go to blocked if necessary once their junction initialises anyway
		if (gLinkCount == 1) then
			Occupied( 0 )
		end
		
	-- GERMAN SPECIFIC functionality: special message for when a train starts in the previous signal block, so the signal can go green
	elseif (message == INITIALISE_TO_PREPARED) then
		DebugPrint( ("DEBUG: DefaultReactToSignalMessage: INITIALISE_TO_PREPARED received on linkIndex " .. linkIndex) )

		-- if this message is received by any link other than 0, pass it on
		if linkIndex > 0 then
			-- This is handled by PASS_ messages!
--			Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", 1, 1, linkIndex )
		else
			SignalPrepared( linkIndex )
			
			-- Send a signal back down the track to prepare any repeater signals (home signals will ignore PREPARE messages coming in this direction)
			Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", -1, 1, 0 )
		end
		
	-- GERMAN SPECIFIC functionality: special message for when a train enters the previous signal block, so the signal can go green
		-- JB 01/05/07 - Only pay attention to this message if it's coming from behind us (because of a train going past the previous signal)
			-- All other SIGNAL_PREPARE_FOR_TRAIN messages are for distance signals only
	elseif (message == SIGNAL_PREPARE_FOR_TRAIN and direction == -1) then
		-- if this message is received by any link other than 0, pass it on
		if linkIndex > 0 then
			-- This is handled by PASS_ messages!
--			Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", 1, 1, linkIndex )
		else
			SignalPrepared( linkIndex )
		end
		
	-- GERMAN SPECIFIC functionality: special message for when the signal is passed backwards, so the signal can turn red again
		-- JB 01/05/07 - Only pay attention to this message if it's coming from behind us (because of a train reversing over a signal)
			-- All other SIGNAL_RESET_AFTER_TRAIN_PASS messages are for distance signals only
	elseif (message == SIGNAL_RESET_AFTER_TRAIN_PASS and direction == -1) then
		-- if this message is received by any link other than 0, pass it on
		if linkIndex > 0 then
			-- This is handled by PASS_ messages!
		else
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
-- DEFAULT ON SIGNAL MESSAGE
-- Handles messages from other signals. 
--
function DefaultOnSignalMessage( message, parameter, direction, linkIndex )
	
	DebugPrint( ("DEBUG: DefaultOnSignalMessage(" .. message .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check for signal receiving a message it might need to forward, in case there are two overlapping signal blocks (eg for a converging junction or crossover)
	if (linkIndex > 0) then

		-- We've received a PASS_ message, so forward it on
		if message > PASS_OFFSET then
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
			
		-- Any message other than RESET_SIGNAL_STATE and JUNCTION_STATE_CHANGE should be forwarded as PASS_ messages
		-- Also ignore initialisation messages from trains straddling a link - these will have the "DoNotForward" parameter
		elseif message ~= RESET_SIGNAL_STATE and message ~= JUNCTION_STATE_CHANGE and parameter ~= "DoNotForward" then
		
			-- Make sure we don't pass on messages that are only for REPEATER signals either
			if (not (message == SIGNAL_PREPARE_FOR_TRAIN and direction == 1)) and
				(not (message == SIGNAL_RESET_AFTER_TRAIN_PASS and direction == 1)) then
				Call( "SendSignalMessage", message + PASS_OFFSET, parameter, -direction, 1, linkIndex )
			end
		end
	end
	
	-- always check for a valid link index
	if (linkIndex >= 0) then

		-- If the message is a PASS_ message...
		if message >= PASS_INITIALISE_SIGNAL_TO_BLOCKED and message < PASS_OFFSET * 2 then

			-- Only pay attention to it if we're not the base link of a signal
			if linkIndex > 0 then

				-- Knock PASS_OFFSET off the signal message number to convert it back to a normal message for processing
				ReactToSignalMessage( message - PASS_OFFSET, parameter, direction, linkIndex )

			-- Except for prepare and reset messages, which should be passed forwards beyond a junction
			elseif direction == -1 and (message == PASS_SIGNAL_PREPARE_FOR_TRAIN or message == PASS_SIGNAL_RESET_AFTER_TRAIN_PASS) then

				-- Knock PASS_OFFSET off the signal message number to convert it back to a normal message for processing
				ReactToSignalMessage( message - PASS_OFFSET, parameter, direction, linkIndex )
			end

			-- Otherwise, it's a normal signal so just process it as normal
		else
			ReactToSignalMessage( message, parameter, direction, linkIndex )		
		end
	end
end

--------------------------------------------------------------------------------------
-- GET SIGNAL STATE
-- Gets the current state of the signal - blocked, warning or clear. 
-- The state info is used for AWS/TPWS scripting.
--
function GetSignalState( )

	-- initialise signal state to -1 (to signify an error)
	local signalState = -1

	-- JB 26/04/07 - Fix for bug #3777 - If the junction isn't connected, signal is red
	if gConnectedLink == -1 then
		signalState = BLOCKED

	elseif not gPrepared then
		signalState = BLOCKED
		
	-- JB 22/05/07 - Just check global gSignalState
	elseif (gSignalState == SIGNAL_CLEARED) then
		signalState = CLEAR
		
	elseif (gSignalState == SIGNAL_WARNING) then
		signalState = WARNING
		
	elseif (gSignalState == SIGNAL_BLOCKED) then
		signalState = BLOCKED

	else
		Print( "ERROR: GetSignalState: failed - invalid signal state" )
	end
	
	return signalState
end
