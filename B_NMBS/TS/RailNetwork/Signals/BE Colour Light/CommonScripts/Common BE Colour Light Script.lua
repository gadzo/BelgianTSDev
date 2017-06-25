-------------------------------------------------------------------------------------
-- Common signal functionality for UK Colour Lights
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

-- DEFAULT INITIALISE
--
function DefaultInitialise ( lSignalType )

	-- If we're a signal head, we don't need to know our own name to switch our lights on and off
	if (SIGNAL_HEAD_NAME == nil) then
		SIGNAL_HEAD_NAME = ""
	end
	
	-- Initialises common signal features
	BaseInitialise()
	
	-- Initialise UK-specific global variables
	gInitialised			= false					-- has the route finished loading yet?
	gPreparedness			= SIGNAL_UNPREPARED		-- is a train approaching us?
	gSignalType				= lSignalType			-- what type of signal are we?
	gSignalState			= CLEAR					-- overall state of signal, as used by AWS/TPWS
	gBlockState				= SIGNAL_CLEARED		-- underlying block state of this signal (clear, blocked, warning etc)
	gSwitchState			= SIGNAL_STRAIGHT		-- underlying switch state of this signal (straight, diverging etc)
	gAnimState				= -1					-- what's the current state of our lights?
	gRouteState				= { }					-- is there a diverging junction ahead?
	gFeather				= { }					-- if we have feathers, which route goes with which feather?

	-- How long to stay off/on in each flash cycle
	LIGHT_FLASH_OFF_SECS	= 0.5
	LIGHT_FLASH_ON_SECS		= 0.5

	-- State of flashing light
	gTimeSinceLastFlash		= 0
	gLightFlashOn			= false
	gFirstLightFlash		= true
	
	-- If we haven't been given a signal type...
	if gSignalType == nil then
	
		-- If we've only got one link, default to AUTO signal
		if gLinkCount == 1 then
			gSignalType = SIGNAL_TYPE_AUTO

		-- If we've only got two links, default to CONTROL signal
		elseif gLinkCount == 2 then
			gSignalType = SIGNAL_TYPE_CONTROL

		-- If we've got more than two links and we're 2 ASP, default to CONTROL signal
		elseif gAspect == 2 then
			gSignalType = SIGNAL_TYPE_CONTROL
			
		-- If we've got more than two links and we're 3 ASP, default to APPROACH CONTROL FROM RED
		elseif gAspect == 3 then
			gSignalType = SIGNAL_TYPE_CONTROL_APPROACH_RED

		-- If we've got more than two links and we're 4 ASP, default to APPROACH CONTROL WITH FLASHING YELLOW
		elseif gAspect == 4 then
			gSignalType = SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW
		end
	end

	-- If we're an auto signal, should always behave as PREPARED_VISIBLE
	if gSignalType == SIGNAL_TYPE_AUTO then
		gPreparedness = SIGNAL_PREPARED_VISIBLE
	end
	
	-- Initialise gRouteState
	for i = 0, gLinkCount - 1 do
		gRouteState[i] = SIGNAL_STRAIGHT
	end
	
	-- If we're a 4 ASP signal using APPROACH CONTROL WITH FLASHING YELLOW
	if gAspect == 4 and gSignalType == SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW then
	
		-- You can't have two signals in a row that use approach control with flashing yellows
		-- So send messages up all lines ahead of this signal to check the next signal isn't a flashing yellow control signal too
		for i = 1, gLinkCount - 1 do
			Call( "SendSignalMessage", SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW, "", 1, 1, i )
		end
	end

	-- Tells the game to do an update tick once the route finishes loading
	-- This will initialise the lights on the signals, which can't be changed until the route is loaded
	Call( "BeginUpdate" )
end


--------------------------------------------------------------------------------------
-- SWITCH LIGHT
-- Turns the selected light node on (1) / off (0)
function SwitchLight( lightNode, state )

	-- If this light node exists for this signal
	if lightNode ~= nil then
		Call ( SIGNAL_HEAD_NAME .. "ActivateNode", lightNode, state )
	end
end


--------------------------------------------------------------------------------------
-- DEFAULT SET LIGHTS
-- Called by SetState to switch the appropriate lights for this signal type on/off according to its new state

function DefaultSetLights ( newState )

	-- Update light state
	gAnimState = newState
	
	-- Switch the appropriate lights on and off based on our new state
	
	if (newState == ANIMSTATE_GREEN) then
		SwitchLight( LIGHT_NODE_GREEN,		1 )
		SwitchLight( LIGHT_NODE_YELLOW,		0 )
		SwitchLight( LIGHT_NODE_YELLOW2,	0 )
		SwitchLight( LIGHT_NODE_RED,		0 )
		SwitchLight( LIGHT_NODE_RED,		0 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )

	elseif (newState == ANIMSTATE_DOUBLE_YELLOW) then
		SwitchLight( LIGHT_NODE_GREEN,		0 )
		SwitchLight( LIGHT_NODE_YELLOW,		1 )
		SwitchLight( LIGHT_NODE_YELLOW2,	1 )
		SwitchLight( LIGHT_NODE_RED, 		0 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )

	elseif (newState == ANIMSTATE_YELLOW) then
		SwitchLight( LIGHT_NODE_GREEN,		0 )
		SwitchLight( LIGHT_NODE_YELLOW,		1 )
		SwitchLight( LIGHT_NODE_YELLOW2,	0 )
		SwitchLight( LIGHT_NODE_RED, 		0 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )

	elseif (newState == ANIMSTATE_RED) then
		SwitchLight( LIGHT_NODE_GREEN,		0 )
		SwitchLight( LIGHT_NODE_YELLOW,		0 )
		SwitchLight( LIGHT_NODE_YELLOW2,	0 )
		SwitchLight( LIGHT_NODE_RED, 		1 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )
		
	elseif (newState >= ANIMSTATE_FLASHING_YELLOW) then
		-- Lights are flashing, turn them all off and then start update loop
		SwitchLight( LIGHT_NODE_GREEN,		0 )
		SwitchLight( LIGHT_NODE_YELLOW,		0 )
		SwitchLight( LIGHT_NODE_YELLOW2,	0 )
		SwitchLight( LIGHT_NODE_RED, 		0 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )
		Call( "BeginUpdate" )
	else
		Print( ("ERROR: SetLights trying to switch to invalid state " .. newState ) )
	end
end

--------------------------------------------------------------------------------------
-- DETERMINE SIGNAL STATE
-- Figures out what lights to show and messages to send based on the state of the signal
--
function DetermineSignalState()

	local newBlockState = gBlockState
	local newSwitchState = gSwitchState

	-- If line is blocked
	if gConnectedLink == -1 or gOccupationTable[0] > 0 or gOccupationTable[gConnectedLink] > 0 then
	
		-- New block state is BLOCKED, don't need to know anything else - signal is red
		newBlockState = SIGNAL_BLOCKED
		
	-- Otherwise
	else
		-- Update block and switch state according to state of connected link
		newBlockState = gLinkState[gConnectedLink]
		newSwitchState = gRouteState[gConnectedLink]

		-- If we're covering a junction and it's set to a diverging route
		if gConnectedLink > 1 then
		
			-- If we're using Approach Control from red...
			if gSignalType == SIGNAL_TYPE_CONTROL_APPROACH_RED then
				newSwitchState = SIGNAL_DIVERGING_RED
			
			-- If we're using Approach Control with flashing yellows...
			elseif gSignalType == SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW then
				newSwitchState = SIGNAL_DIVERGING_FLASHING
			end
		end
	end


	-- Next figure out what aspect to show based on new state
	local newAnimState = gAnimState


	-- If line is blocked
	if newBlockState == SIGNAL_BLOCKED then

		newAnimState = ANIMSTATE_RED
		gSignalState = BLOCKED

	-- If signal is a control signal and there's no train approaching
	elseif gPreparedness == SIGNAL_UNPREPARED then
	
		newAnimState = ANIMSTATE_RED
		gSignalState = BLOCKED
		
	-- In any other case, 2 Aspect signals show green
	elseif gAspect == 2 then

		newAnimState = ANIMSTATE_GREEN
		gSignalState = CLEAR

	-- If our junction is diverging, and there's a train approaching but it's not close yet...
	-- (and we're a control signal using approach control - otherwise we wouldn't be in this state of preparedness)
	elseif gPreparedness == SIGNAL_PREPARED and gConnectedLink > 1 then

		-- If we're using Approach Control from red...
		if gSignalType == SIGNAL_TYPE_CONTROL_APPROACH_RED then

			newAnimState = ANIMSTATE_RED
			gSignalState = BLOCKED

		-- If we're using Approach Control with flashing yellows...
		elseif gSignalType == SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW then

			newAnimState = ANIMSTATE_YELLOW
			gSignalState = WARNING
		end

	-- If line ahead is at warning, or next signal has line diverging and is using approach control from red
	elseif newBlockState == SIGNAL_WARNING
		or newSwitchState == SIGNAL_DIVERGING_YELLOW then

		newAnimState = ANIMSTATE_YELLOW
		gSignalState = WARNING

	-- If next signal  has line diverging and is using approach control with flashing yellows
	elseif newSwitchState == SIGNAL_DIVERGING_FLASHING_YELLOW then

		newAnimState = ANIMSTATE_FLASHING_YELLOW
		gSignalState = WARNING

	-- In any other case, 3 Aspect signals show green
	elseif gAspect == 3 then

		newAnimState = ANIMSTATE_GREEN
		gSignalState = CLEAR

	-- If line ahead is at warning2, or next but one signal has line diverging and is using approach control from red
	elseif newBlockState == SIGNAL_WARNING2
		or newSwitchState == SIGNAL_DIVERGING_DOUBLE_YELLOW then

		newAnimState = ANIMSTATE_DOUBLE_YELLOW
		gSignalState = WARNING

	-- If next but one signal has line diverging and is using approach control with flashing yellows
	elseif newSwitchState == SIGNAL_DIVERGING_FLASHING_DOUBLE_YELLOW then

		newAnimState = ANIMSTATE_FLASHING_DOUBLE_YELLOW
		gSignalState = WARNING

	-- If line ahead is clear
	elseif newBlockState == SIGNAL_CLEARED then
	
		newAnimState = ANIMSTATE_GREEN
		gSignalState = CLEAR
		
	else
		Print( ("ERROR - couldn't figure out what state " .. gAspect .. " aspect signal should be in with block state " .. newBlockState .. ", switch state " .. newSwitchState .. " and preparedness " .. gPreparedness) )
	end
	

	-- If we have an ActivateLink function (and therefore feathers)...
	if ActivateLink ~= nil then
	
		-- If lights are red, turn all feathers off
		if newAnimState == ANIMSTATE_RED then
		
			ActivateLink(1)
			
		-- Otherwise, activate the appropriate feather for the connected link
		else
			ActivateLink(gConnectedLink)
		end
	end
	
	-- Update anim state, switch lights and update 2D map
	if newAnimState ~= gAnimState then
		DebugPrint( ("DEBUG: DetermineSignalState() - lights changing from " .. gAnimState .. " to " .. newAnimState) )
		SetLights(newAnimState)
		Call ("Set2DMapSignalState", gSignalState)
	end

	-- If block state has changed
	if newBlockState ~= gBlockState then
		DebugPrint( ("DEBUG: DetermineSignalState() - block state changed from " .. gBlockState .. " to " .. newBlockState .. " - sending message" ) )
		gBlockState = newBlockState
		Call( "SendSignalMessage", newBlockState, "", -1, 1, 0 )
	end

	-- If switch state has changed
	if newSwitchState ~= gSwitchState then
		DebugPrint( ("DEBUG: DetermineSignalState() - switch state changed from " .. gSwitchState .. " to " .. newSwitchState .. " - sending message" ) )
		gSwitchState = newSwitchState
		Call( "SendSignalMessage", newSwitchState, "", -1, 1, 0 )
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT UPDATE
-- Initialises the signal when the route finishes loading, and handles flashing lights
--
function DefaultUpdate( time )

	-- If this is the initialisation pass for the signal...
	if not gInitialised then
	
		-- Remember that we've been initialised
		gInitialised = true
	
		-- If we're a junction signal, check which link is connected now
		if gLinkCount > 1 then
			OnJunctionStateChange( 0, "", 1, 0 )
		
		-- Otherwise, check signal state now if we haven't been setup yet
		elseif gAnimState == -1 then
			DetermineSignalState()
		end
		
		-- Let the signal ahead of us know if we've got a train in our block and we're connected
		if gConnectedLink >= 0 then
		
			-- If the train is beyond any junctions we cover (or we only have one link), send PREPARED_VISIBLE
			if gOccupationTable[gConnectedLink] > 0 then

				Call( "SendSignalMessage", SIGNAL_PREPARED_VISIBLE, "", 1, 1, gConnectedLink )
				
			-- If the train is just ahead of us, send PREPARED
			elseif gOccupationTable[0] > 0 then

				Call( "SendSignalMessage", SIGNAL_PREPARED, "", 1, 1, gConnectedLink )
			end
		end
	end

	-- Keep count of any flashing lights, in case they've all stopped flashing
	local newLightState = -1

	-- the first time that this is called, the time since the last update will be large - therefore we should ignore the first update
	if gFirstLightFlash then
	
		-- Reset flash state
		gTimeSinceLastFlash = 0
		gFirstLightFlash = false
		gLightFlashOn = false
		
	-- Otherwise increment the timer
	else	
		gTimeSinceLastFlash = gTimeSinceLastFlash + time
		
		-- If we're on and we've been on long enough, switch off
		if gLightFlashOn and gTimeSinceLastFlash >= LIGHT_FLASH_ON_SECS then
			newLightState = 0
			gLightFlashOn = false
			gTimeSinceLastFlash = 0
			
		elseif (not gLightFlashOn) and gTimeSinceLastFlash >= LIGHT_FLASH_OFF_SECS then
			newLightState = 1
			gLightFlashOn = true
			gTimeSinceLastFlash = 0
		end
	end	

	-- If the signal is flashing
	if gAnimState >= ANIMSTATE_FLASHING_YELLOW then

		-- Are we turning the lights on / off?
		if newLightState >= 0 then

			-- If so, switch on / off the appropriate light(s)
			if gAnimState == ANIMSTATE_FLASHING_YELLOW then
				SwitchLight( LIGHT_NODE_YELLOW, newLightState )
				
			elseif gAnimState == ANIMSTATE_FLASHING_DOUBLE_YELLOW then
				SwitchLight( LIGHT_NODE_YELLOW, newLightState )
				SwitchLight( LIGHT_NODE_YELLOW2, newLightState )
			end
		end
		
	-- If the signal isn't flashing anymore, stop updates and remember to reset everything if we start flashing again later
	else
		Call( "EndUpdate" )
		gFirstLightFlash = true
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT ON CONSIST PASS
-- Called when a train passes one of the signal's links
--
function DefaultOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	-- Use BaseOnConsistPass
	BaseOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )
end


--------------------------------------------------------------------------------------
-- JUNCTION STATE CHANGE
-- Called when a signal receives a message saying that a junction ahead of it has switched
--
function DefaultOnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	-- Use BaseOnJunctionStateChange
	BaseOnJunctionStateChange( junction_state, parameter, direction, linkIndex )
end

-------------------------------------------------------------------------------------
-- DEFAULT REACT TO SIGNAL MESSAGE
-- Subfunction to save duplicate code when handling pass back messages - just takes all the old scripting out of the OnSignalMessage function
--
function DefaultReactToSignalMessage( message, parameter, direction, linkIndex )

	-- CHECK FOR YARD ENTRY - any messages arriving on a yard entry link should be ignored
	if gYardEntry[linkIndex] then
		-- Do nothing

		
	
	-- SIGNAL STATES

	elseif ( message == SIGNAL_CLEARED or message == SIGNAL_WARNING2 ) then
		-- Next signal's state is Clear or Warning2, so this link is Clear
		DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Cleared" ) )
		gLinkState[linkIndex] = SIGNAL_CLEARED
		DetermineSignalState()

	elseif ( message == SIGNAL_WARNING ) then
		-- Next signal's state is Warning, so this link is at Warning2
		DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Warning2" ) )
		gLinkState[linkIndex] = SIGNAL_WARNING2
		DetermineSignalState()

	elseif ( message == SIGNAL_BLOCKED ) then
		-- Next signal's state is Blocked, so this link is at Warning
		DebugPrint( ( "DEBUG: Link " .. linkIndex .. " is now Warning" ) )
		gLinkState[linkIndex] = SIGNAL_WARNING
		DetermineSignalState()



	-- ROUTE STATES

	-- No diverging approach control signal for at least two blocks ahead of us
	elseif message == SIGNAL_STRAIGHT
		or message == SIGNAL_DIVERGING_DOUBLE_YELLOW
		or message == SIGNAL_DIVERGING_FLASHING_DOUBLE_YELLOW then
		
		gRouteState[linkIndex] = SIGNAL_STRAIGHT

		-- If the message arrived on the connected link...
		if linkIndex == gConnectedLink then
			DetermineSignalState()
		end

	-- Next but one signal is diverging and using Approach Control from red
	elseif message == SIGNAL_DIVERGING_YELLOW and gAspect == 4 then

		gRouteState[linkIndex] = SIGNAL_DIVERGING_DOUBLE_YELLOW

		-- If the message arrived on the connected link...
		if linkIndex == gConnectedLink then
			DetermineSignalState()
		end

	-- Next but one signal is diverging and using Approach Control with flashing yellows
	elseif message == SIGNAL_DIVERGING_FLASHING_YELLOW and gAspect == 4 then

		gRouteState[linkIndex] = SIGNAL_DIVERGING_FLASHING_DOUBLE_YELLOW

		-- If the message arrived on the connected link...
		if linkIndex == gConnectedLink then
			DetermineSignalState()
		end

	-- Next signal is diverging and using Approach Control from red
	elseif message == SIGNAL_DIVERGING_RED then

		gRouteState[linkIndex] = SIGNAL_DIVERGING_YELLOW

		-- If the message arrived on the connected link...
		if linkIndex == gConnectedLink then
			DetermineSignalState()
		end

	-- Next signal is diverging and using Approach Control with flashing yellows
	elseif message == SIGNAL_DIVERGING_FLASHING then

		gRouteState[linkIndex] = SIGNAL_DIVERGING_FLASHING_YELLOW

		-- If the message arrived on the connected link...
		if linkIndex == gConnectedLink then
			DetermineSignalState()
		end



	-- OCCUPANCY

	elseif (message == OCCUPATION_DECREMENT) then
		-- update the occupation table for this signal given the information that a train has just left this block and entered the next block
		if gOccupationTable[linkIndex] > 0 then
			gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
			DebugPrint( ("DEBUG: DefaultReactToSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		else
			Print( ("ERROR: DefaultReactToSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "] was already 0!") )
		end

		-- If this isn't the connected link...
		if linkIndex ~= gConnectedLink then
		
			-- Do nothing
			
		-- If that part of the block is still occupied
		elseif gOccupationTable[linkIndex] > 0 then
		
			-- Signal ahead of us still has a train approaching it nearby
			Call( "SendSignalMessage", SIGNAL_PREPARED_VISIBLE, "", 1, 1, gConnectedLink )
			
		-- If our block is still occupied before the junction
		elseif gOccupationTable[0] > 0 then
		
			-- Signal ahead of us still has a train approaching it
			Call( "SendSignalMessage", SIGNAL_PREPARED, "", 1, 1, gConnectedLink )
		
		-- Otherwise...
		else
			-- Signal state should change now
			DetermineSignalState()
		end
		
	elseif (message == OCCUPATION_INCREMENT) then
		-- update the occupation table for this signal given the information that a train has just entered this block
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: DefaultReactToSignalMessage: OCCUPATION_INCREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )

		-- If this is the connected link, check the signal state
		if linkIndex == gConnectedLink then
			DetermineSignalState()
		end



	-- PREPARE FOR APPROACHING TRAIN
		-- These messages are sent forwards, so only pay attention to them if they're reaching link 0 from behind
		-- If they hit any other links on the way up first, they'll be forwarded as PASS messages
		-- Only control signals need to pay attention to them - auto signals should ignore them
	elseif (message == SIGNAL_UNPREPARED
		or	message == SIGNAL_PREPARED
		or	message == SIGNAL_PREPARED_VISIBLE)
		and gSignalType ~= SIGNAL_TYPE_AUTO
		and linkIndex == 0 then

		-- Control signals that don't use approach control (eg for converging junctions) should switch as soon as train passes preceding signal, NOT when within sight
		if message == SIGNAL_PREPARED and gSignalType == SIGNAL_TYPE_CONTROL then
			message = SIGNAL_PREPARED_VISIBLE
		end
		
		-- NOTE: SIGNAL_PREPARED_VISIBLE is sent forwards from a signal when a train passes its connected link
		-- The signal that receives it will then assume that the approaching train is within sight of it
		-- In existing routes, all auto signals have 1 link, so the control signal will switch to its clear state as soon as the train passes the preceding signal (unless the preceding signal is a control signal too)
		-- For future routes, users can add an extra link to the auto signal preceding a control signal to set exactly where the control signal will switch to it clear state for an approaching train
		if gPreparedness ~= message then
			gPreparedness = message
			DetermineSignalState()
		end
		


	-- INITIALISATION MESSAGES

	-- There's a train on the line ahead of us when the route first loads
	elseif (message == INITIALISE_SIGNAL_TO_BLOCKED) then
	
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: DefaultReactToSignalMessage: INITIALISE_SIGNAL_TO_BLOCKED received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )

		-- Only need to do this for single link signals - anything spanning a junction will initialise later when junctions are set
		if (gLinkCount == 1 and gOccupationTable[linkIndex] == 1) then
			DetermineSignalState()
		end

	-- There's a train on the line behind us when the route first loads
		-- This message is sent forwards, so only pay attention if they're reaching link 0 from behind
		-- Only control signals need to pay attention to this message - auto signals should ignore them
		-- NOTE: This message is required to handle signals that don't have another signal behind them
	elseif (message == INITIALISE_TO_PREPARED
		and gSignalType ~= SIGNAL_TYPE_AUTO
		and linkIndex == 0) then
		
		DebugPrint( ("DEBUG: DefaultReactToSignalMessage: INITIALISE_TO_PREPARED received on linkIndex 0") )

		-- If we don't already know we have a train approaching, set our state to PREPARED_VISIBLE
			-- on the assumption there's nothing else behind us to let us know when the train is close
		if gPreparedness == SIGNAL_UNPREPARED then
			gPreparedness = SIGNAL_PREPARED_VISIBLE
		end

	-- You can't have two consecutive 4 Aspect signals both set to use Approach Control using flashing yellows
	-- This is included to ensure signals in existing routes are setup correctly without requiring them all to be replaced
	elseif (message == SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW
		and gSignalType == SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW
		and linkIndex == 0 and gAspect == 4) then
		
		DebugPrint( ("DEBUG: DefaultReactToSignalMessage: SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW received by 4 Aspect signal - switching it to use Approach Control from red") )
		gSignalType = SIGNAL_TYPE_CONTROL_APPROACH_RED
		
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
	
	-- Use the base function for this
	BaseOnSignalMessage( message, parameter, direction, linkIndex )
end


--------------------------------------------------------------------------------------
-- GET SIGNAL STATE
-- Gets the current state of the signal - blocked, warning or clear. 
-- The state info is used for AWS/TPWS scripting.
--
function GetSignalState( )
	return gSignalState
end
