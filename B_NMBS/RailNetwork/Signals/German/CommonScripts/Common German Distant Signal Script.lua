
--------------------------------------------------------------------------------------
-- UPDATE
-- This is now only called to initialise the signal lights when the route finishes loading
--
function Update (time)
	DefaultUpdate()
end

--------------------------------------------------------------------------------------
-- ON CONSIST PASS
-- VR signals handle Indusi messages (German equivalent to AWS / TPWS)
--
function OnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	-- if the consist is crossing the signal now
	if ( frontDist > 0 and backDist < 0 ) or ( frontDist < 0 and backDist > 0 ) then

		-- if the consist was previously before/after siganl then the crossing has just started
		if ( prevFrontDist < 0 and prevBackDist < 0 ) or ( prevFrontDist > 0 and prevBackDist > 0 ) then
			DebugPrint( ("DEBUG: OnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
		
			-- if a train has just started crossing in the normal direction...
			if (prevFrontDist > 0 and prevBackDist > 0) then
				
				-- if the train just started crossing link 0 in the normal direction...
				if (linkIndex == 0) then
					DebugPrint( "DEBUG: OnConsistPass: Started crossing link 0 forwards" )
				
					-- Send a message to the train depending on whether the next signal is blocked
					if (gSignalState == SIGNAL_BLOCKED or gSignalState == SIGNAL_WARNING) then
						DebugPrint("DEBUG: OnConsistPass: Indusi - Next signal state is BLOCKED or WARNING")
						Call( "SendConsistMessage", AWS_MESSAGE, "blocked" )
						
					else
						DebugPrint("DEBUG: OnConsistPass: Indusi - Next signal state is CLEAR")
						Call( "SendConsistMessage", AWS_MESSAGE, "clear" )		
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- JUNCTION STATE CHANGE
-- Called when a junction is changed.
--
function OnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: OnJunctionStateChange(" .. junction_state .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check junction has finished transition
	if junction_state == 0 then
		if linkIndex == 0 then
			if gLinkCount == 1 then
				DebugPrint( "WARNING: OnJunctionStateChange: Junction change message received by single link signal" )
			else
				-- this will be used as a search depth - it must be passed as a string
				linkCountAsString = "" .. (5 * (gLinkCount + 1))
				
				-- find the link that is now connected to the signal
				local newConnectedLink = Call( "GetConnectedLink", linkCountAsString, 1, 0 )
				
				if newConnectedLink == gConnectedLink then
					-- Don't waste time doing anything else if the connected link hasn't changed
					DebugPrint( ("DEBUG: OnJunctionStateChange: Activate connected link: " .. gConnectedLink .. " (no change)") )
				else				
					gConnectedLink = newConnectedLink
					
					DebugPrint( ("DEBUG: OnJunctionStateChange: Activate connected link: " .. gConnectedLink) )
				
					if gConnectedLink > 0 then					
						-- JB 26/04/07 - Fix for bug #3759 - Change signal based on state of connected link instead of just setting it to green
						if not gLinkPrepared[gConnectedLink] then
							SetLights( SIGNAL_BLOCKED )
							Call ("Set2DMapSignalState", WARNING)
						
						elseif gLinkState(gConnectedLink) == SIGNAL_CLEARED then
							NotOccupied(gConnectedLink)
							
						elseif gLinkState(gConnectedLink) == SIGNAL_WARNING then
							Warning(gConnectedLink)
							
						elseif gLinkState(gConnectedLink) == SIGNAL_BLOCKED then
							Occupied(gConnectedLink)
						end
						
					-- Set signal to OFF if there's no valid link connected
					elseif gConnectedLink == -1 then
						SetLights( 0 )
						Call ("Set2DMapSignalState", BLOCKED)
					end
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------
-- REACT TO SIGNAL MESSAGE
-- Subfunction to save duplicate code when handling pass back messages - just takes all the old scripting out of the OnSignalMessage function
--
function ReactToSignalMessage( message, parameter, direction, linkIndex )
	
--	DebugPrint( ("DEBUG: ReactToSignalMessage(" .. message .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- always check for a valid link index
	if (linkIndex >= 0) then
		-- set the signal to occupied or not occupied depending on what state the next home signal is in
		if ( message == SIGNAL_BLOCKED ) then
			Occupied( linkIndex )
			
		elseif ( message == SIGNAL_CLEARED ) then
			NotOccupied( linkIndex )
			
		elseif ( message == SIGNAL_WARNING ) then
			Warning( linkIndex )
			
		-- GERMAN SPECIFIC functionality: special message for when a train enters the previous signal block, so the signal can go green
		elseif (message == SIGNAL_PREPARE_FOR_TRAIN) then
			SignalPrepared( linkIndex, direction )
			
		-- GERMAN SPECIFIC functionality: special message for when the signal is passed backwards, so the signal can turn red again
		elseif (message == SIGNAL_RESET_AFTER_TRAIN_PASS) then
			SignalReset( linkIndex, direction )

		-- This message is to reset the signals after a scenario / route is reset
		elseif (message == RESET_SIGNAL_STATE) then
			ResetSignalState()

		-- JB 04/05/07 - New junction state change message added
		elseif (message == JUNCTION_STATE_CHANGE) then
			-- JB 24/05/07 - Forward on message, but only if signals are initialised, parameter is "0" and the message arrived at link 0
			if gInitialised and parameter == "0" and linkIndex == 0 then
				DebugPrint( ("DEBUG: OnSignalMessage: Forward message on to next signal!") )
				Call( "SendSignalMessage", message, parameter, -direction, 1, 0 )
				
				-- If this VR signal spans a junction, we also need to do our own junction state change check
				if gLinkCount > 1 then
					OnJunctionStateChange( 0, "", 1, 0 )
				end				
			end
			
		-- Occupation Increment / Decrement and Initialise to Blocked / Prepared
		-- Also ignore initialisation messages from trains straddling a link - these will have the "DoNotForward" parameter
		elseif (linkIndex == 0 and parameter ~= "DoNotForward")
			-- forward on all other messages received on link 0 (any other links handled by PASS_ messages in DefaultOnSignalMessage)
			DebugPrint( ("DEBUG: OnSignalMessage: Forward message on to next signal!") )
			Call( "SendSignalMessage", message, parameter, -direction, 1, 0 )
		end
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

	DebugPrint( ("DEBUG: Occupied(" .. linkIndex .. ")") )

	-- JB 01/05/07 - only change signal if message arrived on connected link
	if (gConnectedLink == linkIndex) then
	
		-- Set signal to newState
		SetState( SIGNAL_BLOCKED )

		-- Correct 2D map state
		Call ("Set2DMapSignalState", WARNING)
		
		-- Pass back a message if the signal has changed state
		if gSignalState ~= SIGNAL_BLOCKED then
			gSignalState = SIGNAL_BLOCKED
			Call( "SendSignalMessage", SIGNAL_BLOCKED, "", -1, 1, 0 )
		end
	end
	
	-- If we've got more than one link, set this link as Blocked (only do this for repeater signals!)
	if gLinkCount > 1 then
		DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Blocked" ) )
		gLinkState[linkIndex] = SIGNAL_BLOCKED
	end
end

--------------------------------------------------------------------------------------
-- NOTOCCUPIED
-- Tells the signal to display a clear track ahead
--
function NotOccupied( linkIndex )

	DebugPrint( ( "DEBUG: NotOccupied(" .. linkIndex .. ")" ) )

	-- JB 01/05/07 - only change signal if message arrived on connected link
	if (gConnectedLink == linkIndex) then
	
		-- Set signal to newState
		SetState( SIGNAL_CLEARED )
		
		-- Pass back a message if the signal has changed state
		if gSignalState ~= SIGNAL_CLEARED then
			gSignalState = SIGNAL_CLEARED
			Call( "SendSignalMessage", SIGNAL_CLEARED, "", -1, 1, 0 )
		end
	end
	
	-- If we've got more than one link, set this link as Cleared
	if gLinkCount > 1 then
		DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Cleared" ) )
		gLinkState[linkIndex] = SIGNAL_CLEARED
	end
end

--------------------------------------------------------------------------------------
-- WARNING
-- Tells the signal to display that there is a warning ahead
--
function Warning( linkIndex )

	DebugPrint( ( "DEBUG: Warning(" .. linkIndex .. ")" ) )

	-- JB 01/05/07 - only change signal if message arrived on connected link
	if (gConnectedLink == linkIndex) then
	
		-- Set signal to newState
		SetState( SIGNAL_WARNING )
		
		-- Pass back a message if the signal has changed state
		if gSignalState ~= SIGNAL_WARNING then
			gSignalState = SIGNAL_WARNING
			Call( "SendSignalMessage", SIGNAL_WARNING, "", -1, 1, 0 )
		end
	end
	
	-- If we've got more than one link, set this link as Warning
	if gLinkCount > 1 then
		DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now at Warning" ) )
		gLinkState[linkIndex] = SIGNAL_WARNING
	end
end

--------------------------------------------------------------------------------------
-- SIGNAL PREPARED
-- Tells the signal to prepare for a train approaching it
--
function SignalPrepared( linkIndex, direction )

	DebugPrint( ("DEBUG: SignalPrepared(" .. linkIndex .. ")") )
	
	local linkToUse = linkIndex

	-- If the message comes from behind us, prepare connected link
	if (linkToUse == 0 and direction == -1) then
		linkToUse = gConnectedLink
	end

	-- If this link wasn't already prepared
	if not gLinkPrepared[linkToUse] then
	
		-- Mark this link as prepared
		gLinkPrepared[linkToUse] = true
	
		-- JB 01/05/07 - only change signal if message arrived on connected link
		if (gConnectedLink == linkToUse) then

			gPrepared = true

			-- Switch signal lights based on state of line ahead
			SetState( gSignalState )

			-- Correct 2D map state if necessary
			if gSignalState == SIGNAL_BLOCKED then
				Call ("Set2DMapSignalState", WARNING)
			end
		end

		-- Pass on a Prepare message
		DebugPrint( "DEBUG: SignalPrepared: Send SIGNAL_PREPARE_FOR_TRAIN message" )
		Call( "SendSignalMessage", SIGNAL_PREPARE_FOR_TRAIN, "", -direction, 1, linkIndex )
	end
end

--------------------------------------------------------------------------------------
-- SIGNAL RESET
-- Tells the signal to reset to red because of train entering its block from wrong end
--
function SignalReset( linkIndex, direction )

	DebugPrint( ("DEBUG: SignalReset(" .. linkIndex .. ")") )
	
	local linkToUse = linkIndex

	-- If the message comes from behind us, reset connected link
	if (linkToUse == 0 and direction == -1) then
		linkToUse = gConnectedLink
	end

	-- If this link was prepared
	if gLinkPrepared[linkToUse] then
	
		-- Mark this link as not prepared
		gLinkPrepared[linkToUse] = false

		-- JB 01/05/07 - only change signal if message arrived on connected link
		if (gConnectedLink == linkToUse) then
		
			gPrepared = false
			
			-- Signal no longer prepared for an approaching train, so defaults back to red
			SetState( gSignalState )

			-- Correct 2D map state
			Call ("Set2DMapSignalState", WARNING)
		end

		-- Pass on a Reset message
		DebugPrint( "DEBUG: SignalReset: Send SIGNAL_RESET_AFTER_TRAIN_PASS message" )
		Call( "SendSignalMessage", SIGNAL_RESET_AFTER_TRAIN_PASS, "", -direction, 1, linkIndex )		
	end
end
