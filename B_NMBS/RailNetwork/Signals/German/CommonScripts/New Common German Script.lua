-------------------------------------------------------------------------------------
-- Common signal functionality for German Colour Lights
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

-- DEFAULT INITIALISE
--
function DefaultInitialise ( lShuntSignal )
	
	-- Initialises common signal features
	BaseInitialise()
	
	-- Initialise German-specific global variables
	gInitialised			= false					-- has the route finished loading yet?
	gPreparedness			= SIGNAL_UNPREPARED		-- is a train approaching us?
	gShuntSignal			= lShuntSignal			-- can we show Sh1 aspect?
--	gShuntState				= false					-- if we can show Sh1, has it been activated?
	gSignalState			= CLEAR					-- overall state of signal, as used by PZB
	gBlockState				= SIGNAL_CLEARED		-- underlying block state of this signal (clear, blocked, warning etc)
	gAnimState				= { }					-- what's the current state of our lights?
	
	-- Initialise gAnimState - record separately for Hp and Vr heads, if present
	gAnimState[SIGNAL_TYPE_HP] = -1
	gAnimState[SIGNAL_TYPE_VR] = -1

	-- Tells the game to do an update tick once the route finishes loading
	-- This will initialise the lights on the signals, which can't be changed until the route is loaded
	Call( "BeginUpdate" )
end


--------------------------------------------------------------------------------------
-- SWITCH LIGHT
-- Turns the selected light node on (1) / off (0)
function SwitchLight( headName, lightNode, state )

	-- If this head and light node exist for this signal
	if headName ~= nil and lightNode ~= nil then
		Call ( headName .. "ActivateNode", lightNode, state )
	end
end


--------------------------------------------------------------------------------------
-- DEFAULT SET LIGHTS
-- Called by SetState to switch the appropriate lights for this signal type on/off according to its new state

function DefaultSetLights ( newState )
	
	-- Switch the appropriate lights on and off based on our new state

	if (newState == ANIMSTATE_HP0) then
	
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_GREEN,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_YELLOW,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED1,		1 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED2,		1 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE1,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE2,		0 )
		
		gAnimState[SIGNAL_TYPE_HP] = newState

	elseif (newState == ANIMSTATE_HP1) then
	
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_GREEN,		1 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_YELLOW,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED1,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED2,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE1,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE2,		0 )
		
		gAnimState[SIGNAL_TYPE_HP] = newState

	elseif (newState == ANIMSTATE_HP2) then
	
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_GREEN,		1 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_YELLOW,		1 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED1,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED2,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE1,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE2,		0 )
		
		gAnimState[SIGNAL_TYPE_HP] = newState

	elseif (newState == ANIMSTATE_HPM) then
	
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_GREEN,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_YELLOW,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED1,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED2,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE1,		1 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE2,		0 )
		
		gAnimState[SIGNAL_TYPE_HP] = newState

	elseif (newState == ANIMSTATE_SH1) then
	
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_GREEN,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_YELLOW,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED1,		1 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_RED2,		0 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE1,		1 )
		SwitchLight( HP_SIGNAL_HEAD_NAME, HP_LIGHT_NODE_WHITE2,		1 )
		
		gAnimState[SIGNAL_TYPE_HP] = newState

	elseif (newState == ANIMSTATE_VR0) then

		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_GREEN1,		0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_GREEN2,		0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_YELLOW1,	1 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_YELLOW2,	1 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_WHITE,		1 )
		
		gAnimState[SIGNAL_TYPE_VR] = newState
		
	elseif (newState == ANIMSTATE_VR1) then

		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_GREEN1,		1 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_GREEN2,		1 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_YELLOW1,	0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_YELLOW2,	0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_WHITE,		1 )
		
		gAnimState[SIGNAL_TYPE_VR] = newState

	elseif (newState == ANIMSTATE_VR2) then

		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_GREEN1,		1 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_GREEN2,		0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_YELLOW1,	0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_YELLOW2,	1 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_WHITE,		1 )
		
		gAnimState[SIGNAL_TYPE_VR] = newState

	elseif (newState == ANIMSTATE_VRX) then

		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_GREEN1,		0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_GREEN2,		0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_YELLOW1,	0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_YELLOW2,	0 )
		SwitchLight( VR_SIGNAL_HEAD_NAME, VR_LIGHT_NODE_WHITE,		0 )
		
		gAnimState[SIGNAL_TYPE_VR] = newState
		
	else
		Print( ("ERROR: SetLights trying to switch to invalid state " .. newState ) )
	end
end

--------------------------------------------------------------------------------------
-- DETERMINE SIGNAL STATE
-- Figures out what lights to show and messages to send based on the state of the signal
--
function DetermineSignalState()

	-- Declare variables to record signal's new state
	local newBlockState = gBlockState
	local newSignalState = gSignalState
	
	local newAnimState = {  [SIGNAL_TYPE_HP] = gAnimState[SIGNAL_TYPE_HP],
							[SIGNAL_TYPE_VR] = gAnimState[SIGNAL_TYPE_VR] }

	-- Figure out underlying state of signal

	-- If line is blocked (or we're a signal with the Sh1 aspect and we're set to go into a yard)
	if gConnectedLink == -1 or gOccupationTable[0] > 0 or gOccupationTable[gConnectedLink] > 0 or
	  (gShuntSignal and gYardEntry[gConnectedLink]) then

		newAnimState[SIGNAL_TYPE_HP] = ANIMSTATE_HP0
		newAnimState[SIGNAL_TYPE_VR] = ANIMSTATE_VRX

		-- If we have an Sh1 aspect and there's a valid route ahead
		-- (ie, we're only blocked by a train, or we're going into a yard)
		if gShuntSignal and gConnectedLink >= 0 then
		
			newAnimState[SIGNAL_TYPE_HP] = ANIMSTATE_SH1
		end

		newBlockState = SIGNAL_BLOCKED
	
	-- If line is clear
	else
	
		-- If we have an Hp head and we're diverging, show Hp2
		-- AS 19/04/09 - add reference to gNeverHp1
		if HP_SIGNAL_HEAD_NAME ~= nil and (gConnectedLink > 1 or gNeverHp1) then

			newAnimState[SIGNAL_TYPE_HP] = ANIMSTATE_HP2
			newBlockState = SIGNAL_WARNING
		
		-- Otherwise signal should show Hp1
		else
		
			newAnimState[SIGNAL_TYPE_HP] = ANIMSTATE_HP1
			newBlockState = SIGNAL_CLEARED
		end

		-- If we have no Vorsignal head, treat as showing VrX (off)
		if VR_SIGNAL_HEAD_NAME == nil then
		
			newAnimState[SIGNAL_TYPE_VR] = ANIMSTATE_VRX
			
		-- If signal ahead is at STOP, Vr head should show Vr0
		elseif gLinkState[gConnectedLink] == SIGNAL_BLOCKED then

			newAnimState[SIGNAL_TYPE_VR] = ANIMSTATE_VR0
			
			-- If we're a Hp/Vr Repeater and signal ahead is at STOP
			-- AS 19/04/09 - replace reference Vr marker light by reference to gNeverHp1Vr0
			-- original JB line: if HP_SIGNAL_HEAD_NAME ~= nil and VR_LIGHT_NODE_WHITE ~= nil then
			if HP_SIGNAL_HEAD_NAME ~= nil and newAnimState[SIGNAL_TYPE_HP] == ANIMSTATE_HP1 and gNeverHp1Vr0 then
			
				-- We should show a special warning aspect on the Hp signal
				newAnimState[SIGNAL_TYPE_HP] = ANIMSTATE_HPM
			end

		-- If signal ahead is at PROCEED, Vr head should show Vr1
		elseif gLinkState[gConnectedLink] == SIGNAL_CLEARED then

			newAnimState[SIGNAL_TYPE_VR] = ANIMSTATE_VR1
			
		-- If signal ahead is at PROCEED AT REDUCED SPEED, Vr head should show Vr2
		elseif gLinkState[gConnectedLink] == SIGNAL_WARNING then

			newAnimState[SIGNAL_TYPE_VR] = ANIMSTATE_VR2
			
			-- AS 19/04/09 - added marker light logic for Vr2, too
			if HP_SIGNAL_HEAD_NAME ~= nil and newAnimState[SIGNAL_TYPE_HP] == ANIMSTATE_HP1 and gNeverHp1Vr2 then
			
				-- We should show a special warning aspect on the Hp signal
				newAnimState[SIGNAL_TYPE_HP] = ANIMSTATE_HPM
			end
		end
	end

	-- If there's no train approaching and we're not a pure Vr signal
	if gPreparedness == SIGNAL_UNPREPARED and HP_SIGNAL_HEAD_NAME ~= nil then
	
		-- Switch Hp head to RED and Vr head OFF
		newAnimState[SIGNAL_TYPE_HP] = ANIMSTATE_HP0
		newAnimState[SIGNAL_TYPE_VR] = ANIMSTATE_VRX
	end
	
--[[
	-- DEBUG - REMOVE!!!
	DebugPrint( ("DEBUG: DetermineSignalState() - gPreparedness = " .. gPreparedness ) )
	DebugPrint( ("DEBUG: DetermineSignalState() - block state = " .. newBlockState ) )
	DebugPrint( ("DEBUG: DetermineSignalState() - HP state = " .. newAnimState[SIGNAL_TYPE_HP] ) )
	DebugPrint( ("DEBUG: DetermineSignalState() - VR state = " .. newAnimState[SIGNAL_TYPE_VR] ) )
	DebugPrint( ("DEBUG: DetermineSignalState() - gConnectedLink = " .. gConnectedLink ) )
	DebugPrint( ("DEBUG: DetermineSignalState() - gOccupationTable[0] = " .. gOccupationTable[0] ) )
]]
	
	-- Next figure out overall signal state for 2D map, based on head states

	-- If we're at STOP, show RED on 2D map
	if newAnimState[SIGNAL_TYPE_HP] == ANIMSTATE_HP0 then

		newSignalState = BLOCKED
		
	-- If we're at SHUNT, show YELLOW on 2D map
	-- NOTE: gSignalState of WARNING allows train to pass signal without triggering a SPAD
	elseif newAnimState[SIGNAL_TYPE_HP] == ANIMSTATE_SH1 then

		newSignalState = WARNING
		
	-- If we're at PROCEED AT REDUCED SPEED, show YELLOW on 2D map
	elseif newAnimState[SIGNAL_TYPE_HP] == ANIMSTATE_HP2 then

		newSignalState = WARNING

	-- If we're a pure Hp signal, or our Vr head is at EXPECT PROCEED, show GREEN on 2D map
	elseif VR_SIGNAL_HEAD_NAME == nil
		or newAnimState[SIGNAL_TYPE_VR] == ANIMSTATE_VR1 then

		newSignalState = CLEAR
				
	-- If we have a Vr head which is at EXPECT STOP or EXPECT PROCEED AT REDUCED SPEED, show YELLOW on 2D map
	elseif newAnimState[SIGNAL_TYPE_VR] == ANIMSTATE_VR0
		or newAnimState[SIGNAL_TYPE_VR] == ANIMSTATE_VR2 then
	
		newSignalState = WARNING
	end
	
	-- If our overall signal state has changed, update 2D map
	if newSignalState ~= gSignalState then
		DebugPrint( ("DEBUG: DetermineSignalState() - signal state changing from " .. gSignalState .. " to " .. newSignalState) )
		gSignalState = newSignalState
		Call ("Set2DMapSignalState", newSignalState)
	end
	
	-- If we have a Vr head, and its state has changed, update lights
	if VR_SIGNAL_HEAD_NAME ~= nil and newAnimState[SIGNAL_TYPE_VR] ~= gAnimState[SIGNAL_TYPE_VR] then
		DebugPrint( ("DEBUG: DetermineSignalState() - VR lights changing from " .. gAnimState[SIGNAL_TYPE_VR] .. " to " .. newAnimState[SIGNAL_TYPE_VR]) )
		SetLights(newAnimState[SIGNAL_TYPE_VR])
	end
	
	-- If we have a Hp head, and its state has changed, update lights
	if HP_SIGNAL_HEAD_NAME ~= nil and newAnimState[SIGNAL_TYPE_HP] ~= gAnimState[SIGNAL_TYPE_HP] then
		DebugPrint( ("DEBUG: DetermineSignalState() - HP lights changing from " .. gAnimState[SIGNAL_TYPE_HP] .. " to " .. newAnimState[SIGNAL_TYPE_HP]) )
		SetLights(newAnimState[SIGNAL_TYPE_HP])
	end

	-- If we have a Hp head and block state has changed
	if HP_SIGNAL_HEAD_NAME ~= nil and newBlockState ~= gBlockState then
		DebugPrint( ("DEBUG: DetermineSignalState() - block state changed from " .. gBlockState .. " to " .. newBlockState .. " - sending message" ) )
		gBlockState = newBlockState
		Call( "SendSignalMessage", newBlockState, "", -1, 1, 0 )
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
		
		-- Otherwise, check signal state now
		else
		
			DetermineSignalState()
			
			-- If we have a train approaching us, let the signals ahead of us know
			if gPreparedness ~= SIGNAL_UNPREPARED then
			
				-- If we're a pure Vr signal...
				if ( HP_SIGNAL_HEAD_NAME == nil ) then

					-- Forward on our own preparedness
					Call( "SendSignalMessage", SIGNAL_PREPARED, "" .. gPreparedness, 1, 1, 0 )

				-- If we're an Hp or Hp/Vr signal and there are no trains ahead of us
				elseif gOccupationTable[0] == 0 then
					
					-- If we're a yard exit (always prepared)
					if gPreparedness == SIGNAL_PREPARED_ALWAYS then

						-- Act as if we had a train approaching us (because we might do!)
						Call( "SendSignalMessage", SIGNAL_PREPARED, "2", 1, 1, 0 )
					
					-- If we're a normal signal
					else

						-- Increment the preparedness by one and send it on
						Call( "SendSignalMessage", SIGNAL_PREPARED, "" .. (gPreparedness + 1), 1, 1, 0 )
					end
				end
			end
		end
		
		-- Ensure 2D map is initialised for this signal
		Call ("Set2DMapSignalState", gSignalState)
	end

	Call( "EndUpdate" )
end

--------------------------------------------------------------------------------------
-- DEFAULT ON CONSIST PASS
-- Called when a train passes one of the signal's links
-- Modified version for German signals, to handle preparing more than one signal ahead of a train
--
function DefaultOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	-- Quit out immediately if this signal has no Hp head!
	if HP_SIGNAL_HEAD_NAME == nil then
		return
	end

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
				if (gSignalState == BLOCKED) then
					DebugPrint("SPAD")
					Call( "SendConsistMessage", SPAD_MESSAGE, "" )
				end
			
				gOccupationTable[0] = gOccupationTable[0] + 1
				DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				DetermineSignalState()

				-- If this is the only train in our block at the moment, and we're connected to a valid link
				if gOccupationTable[0] == 1 and gConnectedLink ~= -1 and (gConnectedLink == 0 or gOccupationTable[gConnectedLink] == 0) then

					-- Send a signal message up the connected track to tell the next signal it's got a train approaching it
					Call( "SendSignalMessage", SIGNAL_PREPARED, "1", 1, 1, 0 )
				end

			-- if the train just started crossing link 1, 2, 3 etc. increment the appropriate occupation table slot
			elseif (linkIndex > 0) then
			
				-- Ignore if this link is inside a yard - once a train gets into a yard, the yard's entry signal doesn't care about it anymore
				if not gYardEntry[linkIndex] then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[linkIndex]: " .. gOccupationTable[linkIndex]) )
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the opposite direction...
		elseif (prevFrontDist < 0 and prevBackDist < 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Started crossing backwards!" )
			
			-- if the train just started crossing link 0 in reverse, send OCCUPATION_INCREMENT
			if (linkIndex == 0) then
				DebugPrint( "DEBUG: DefaultOnConsistPass: A train starts passing link 0 in the opposite direction. Send OCCUPATION_INCREMENT." )
				Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )
				
			-- if the train just started crossing link 1, 2, 3 etc. in reverse, increment occupation table slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line, or exit signal for connected line
				if (gConnectedLink == linkIndex) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
					
					-- If we're coming out of a yard, signal won't be red already because trains inside the yard are ignored
					if gYardEntry[linkIndex] then
						DetermineSignalState()
					end

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
				if gOccupationTable[0] > 0 then
					gOccupationTable[0] = gOccupationTable[0] - 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				else
					Print( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
				end

				-- If a train has just reversed past us and we're not a yard exit signal, remember we now have a train "approaching" us
				if gPreparedness ~= SIGNAL_PREPARED_ALWAYS then
					gPreparedness = 1
				end

				-- If nobody else is left in our block...
				if (gOccupationTable[0] == 0 and (gConnectedLink < 1 or gOccupationTable[gConnectedLink] == 0)) then

					-- Update signal state
					DetermineSignalState()
				
					-- Send a message up the connected line to let the next signal know the train is behind us now
					Call( "SendSignalMessage", SIGNAL_PREPARED, "2", 1, 1, 0 )
				end

			-- if the train just finished crossing link 1, 2, 3 etc. in reverse, decrement the appropriate occupation table slot
			elseif (linkIndex > 0) then

				-- Only count the train if this link isn't inside a yard - once a train gets into a yard, signals outside the yard don't care about it anymore
				if not gYardEntry[linkIndex] then
				
					if gOccupationTable[linkIndex] > 0 then
						gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
						DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
					else
						Print( ( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[" .. linkIndex .. "] was already empty" ) )
					end
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing in the normal direction...
		elseif (frontDist < 0 and backDist < 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Finished crossing forwards!" )
			
			-- if the train just finished crossing link 0 in the normal direction, send OCCUPATION_DECREMENT
			if (linkIndex == 0) then

				-- If a train has just gone past us, we (probably) no longer have a train approaching us (unless we're a yard exit!)
				-- If there are still trains approaching us, we'll be corrected when the signal behind us gets the decrement message
				if gPreparedness ~= SIGNAL_PREPARED_ALWAYS then
					gPreparedness = SIGNAL_UNPREPARED
				
					-- If we were showing Sh1, shut it off now
--					gShuntState = false

					-- Update signal state
					DetermineSignalState()
				end

				DebugPrint( "DEBUG: DefaultOnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT." )
				Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
				
			-- if the train just finished crossing link 1, 2, 3 etc. in the normal direction, decrement occupation slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line
				if (gConnectedLink == linkIndex) then
					if gOccupationTable[0] > 0 then
						gOccupationTable[0] = gOccupationTable[0] - 1
						DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )

						-- If we're going into a yard, signal needs to go back to Restricted from Blocked, because trains in yard are ignored by signal
						if gYardEntry[linkIndex] then
							DetermineSignalState()
						end
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


--------------------------------------------------------------------------------------
-- JUNCTION STATE CHANGE
-- Called when a signal receives a message saying that a junction ahead of it has switched
-- Modified version for German signals, to handle preparing more than one signal ahead of a train
--
function DefaultOnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: DefaultOnJunctionStateChange(" .. junction_state .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check junction has finished transition
	if junction_state == 0 then
		if linkIndex == 0 then
			if gLinkCount == 1 then
				DebugPrint( "DEBUG: DefaultOnJunctionStateChange: Junction change message received by single link signal" )
			else
				-- this will be used as a search depth - it must be passed as a string
				linkCountAsString = "" .. (5 * (gLinkCount + 1))

				-- find the link that is now connected to the signal
				local newConnectedLink = Call( "GetConnectedLink", linkCountAsString, 1, 0 )
				
				-- Don't waste time doing anything else if the connected link hasn't changed
				if newConnectedLink == gConnectedLink then
					DebugPrint( ("WARNING: DefaultOnJunctionStateChange triggered by message from junction that hasn't effected its state, still connected to " .. gConnectedLink ) )

				else
					-- Don't bother doing this for pure Vr signals and other non-Hp indicators
					if HP_SIGNAL_HEAD_NAME ~= nil then
					
						-- If the signal ahead on the previously connected route no longer has a train approaching it
						if gConnectedLink > 0 and gOccupationTable[gConnectedLink] == 0 and (gOccupationTable[0] > 0 or gPreparedness ~= SIGNAL_UNPREPARED) then

							-- Let the next signal on that line know it no longer has a train approaching it
							Call( "SendSignalMessage", SIGNAL_UNPREPARED, "", 1, 1, gConnectedLink )
						end

						-- If the signal ahead on the newly connected route now has a train approaching it
						if newConnectedLink > 0 and gOccupationTable[newConnectedLink] == 0 and (gOccupationTable[0] > 0 or gPreparedness ~= SIGNAL_UNPREPARED) then

							-- If there's a train in our block, let the signal ahead know
							if gOccupationTable[0] > 0 then
							
								Call( "SendSignalMessage", SIGNAL_PREPARED, "1", 1, 1, 0 )

							-- If we're a Vr signal, pass on our own preparedness
							elseif HP_SIGNAL_HEAD_NAME == nil then
							
								Call( "SendSignalMessage", SIGNAL_PREPARED, "" .. gPreparedness, 1, 1, 0 )

							-- If we're a yard exit, act as if we had a train approaching us (because we might do!)
							elseif gPreparedness == SIGNAL_PREPARED_ALWAYS then
							
								Call( "SendSignalMessage", SIGNAL_PREPARED, "2", 1, 1, 0 )
								
							-- If our preparedness is less than 3, pass on our preparedness + 1
							elseif gPreparedness < 3 then
							
								Call( "SendSignalMessage", SIGNAL_PREPARED, "" .. (gPreparedness + 1), 1, 1, 0 )
							end
						end
					end
					
					gConnectedLink = newConnectedLink
					
					DebugPrint( ("DEBUG: DefaultOnJunctionStateChange: Activate connected link: " .. gConnectedLink) )

					-- Switch the signal lights as necessary based on new state of junction
					DetermineSignalState()
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

	-- CHECK FOR YARD ENTRY - any messages arriving on a yard entry link should be ignored
	if gYardEntry[linkIndex] then
		-- Do nothing

		
	
	-- SIGNAL STATES - ONLY FOR SIGNALS WITH VR HEADS, CONSUMED BY HP SIGNAL HEADS

	elseif ( message == SIGNAL_CLEARED ) then

		if ( VR_SIGNAL_HEAD_NAME ~= nil ) then
		
			-- Next Hp signal on this link is at PROCEED
			DebugPrint( ( "DEBUG: DefaultReactToSignalMessage() - Link " .. linkIndex .. " is now at PROCEED" ) )
			gLinkState[linkIndex] = SIGNAL_CLEARED

			-- If this message arrived on our connected link...
			if ( linkIndex == gConnectedLink ) then
			
				DetermineSignalState()
			
				-- If we have no Hp head, or we're an Hp/Vr repeater with no train in its block
				if ( HP_SIGNAL_HEAD_NAME == nil
				or ( VR_LIGHT_NODE_WHITE ~= nil and gOccupationTable[0] == 0 and gOccupationTable[linkIndex] == 0)) then
			
					-- Pass the message back, in case there's another Vr signal behind us
					Call( "SendSignalMessage", message, "", -1, 1, 0 )
				end
			end
		end

	elseif ( message == SIGNAL_WARNING ) then

		if ( VR_SIGNAL_HEAD_NAME ~= nil ) then
		
			-- Next Hp signal on this link is at PROCEED AT REDUCED SPEED
			DebugPrint( ( "DEBUG: DefaultReactToSignalMessage() - Link " .. linkIndex .. " is now at WARNING" ) )
			gLinkState[linkIndex] = SIGNAL_WARNING

			-- If this message arrived on our connected link...
			if ( linkIndex == gConnectedLink ) then
			
				DetermineSignalState()
			
				-- If we have no Hp head, or we're an Hp/Vr repeater with no train in its block
				if ( HP_SIGNAL_HEAD_NAME == nil
				or ( VR_LIGHT_NODE_WHITE ~= nil and gOccupationTable[0] == 0 and gOccupationTable[linkIndex] == 0)) then
			
					-- Pass the message back, in case there's another Vr signal behind us
					Call( "SendSignalMessage", message, "", -1, 1, 0 )
				end
			end
		end

	elseif ( message == SIGNAL_BLOCKED ) then

		if ( VR_SIGNAL_HEAD_NAME ~= nil ) then
		
			-- Next Hp signal on this link is at STOP
			DebugPrint( ( "DEBUG: DefaultReactToSignalMessage() - Link " .. linkIndex .. " is now at STOP" ) )
			gLinkState[linkIndex] = SIGNAL_BLOCKED

			-- If this message arrived on our connected link...
			if ( linkIndex == gConnectedLink ) then
			
				DetermineSignalState()
			
				-- If we have no Hp head, or we're an Hp/Vr repeater with no train in its block
				if ( HP_SIGNAL_HEAD_NAME == nil
				or ( VR_LIGHT_NODE_WHITE ~= nil and gOccupationTable[0] == 0 and gOccupationTable[linkIndex] == 0)) then
			
					-- Pass the message back, in case there's another Vr signal behind us
					Call( "SendSignalMessage", message, "", -1, 1, 0 )
				end
			end
		end

		
		
	-- JUNCTION STATE
	
	elseif (message == JUNCTION_STATE_CHANGE) then
	
		-- Only act on message if -
			-- signal is initialised
			-- message arrived at link 0
			-- junction_state parameter is "0"
			-- AND this signal has more than one link
		if gInitialised and linkIndex == 0 and parameter == "0" and gLinkCount > 1 then
		
			OnJunctionStateChange( 0, "", 1, 0 )
			
			-- Pass on message in case junction is protected by more than one signal
				-- NB: this message is passed on when received on link 0 instead of link 1+
				-- When it reaches a link > 0 or a signal with only one link, it will be consumed
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
		end

		
		
	-- SIGNAL RESET

	elseif (message == RESET_SIGNAL_STATE) then
	
		-- Resets signal state, if scenario is reset
		ResetSignalState()



	-- PREPAREDNESS

	elseif (message == SIGNAL_PREPARED) then

		-- These messages are sent forwards, so only pay attention to them if they're reaching link 0
			-- (If they hit any other links on the way up first, they'll be forwarded as PASS messages)
		-- Ignore the message if we're a yard exit, as they should always be prepared
		if linkIndex == 0 and gPreparedness ~= SIGNAL_PREPARED_ALWAYS then
		
			local newPreparedness = gPreparedness

			-- Train is directly behind us
			if parameter == "1" then
			
				newPreparedness = 1

			-- Train is approaching the Hp signal behind us
			elseif parameter == "2" then
			
				newPreparedness = 2

			-- Train is approaching the Hp signal two behind us
			elseif parameter == "3" then
			
				newPreparedness = 3
			end
			
			-- If there's no longer a train directly behind us...
			if newPreparedness > 1 then
										
				-- If we were showing Sh1, shut it off now
--				gShuntState = false
			end
			
			DebugPrint( ("DEBUG: DefaultReactToSignalMessage() - SIGNAL_PREPARED received, gPreparedness changed from " .. gPreparedness .. " to " .. newPreparedness) )
			
			-- If preparedness has changed
			if newPreparedness ~= gPreparedness then

				gPreparedness = newPreparedness

				-- Check our state
				DetermineSignalState()

				-- If we're a pure Vr signal...
				if ( HP_SIGNAL_HEAD_NAME == nil ) then

					-- Pass the message on unchanged
					Call( "SendSignalMessage", message, parameter, -direction, 1, 0 )
				
				-- If we have an Hp head, and there's no train in our block (so the next signal isn't already "more" prepared)...
				elseif ( gOccupationTable[0] == 0 and (gConnectedLink < 1 or gOccupationTable[gConnectedLink] == 0) ) then
				
					-- We only want to prepare the first 3 signals ahead of the train, so...
					-- If the parameter is less than 3, increment the parameter and pass the message on
					if gPreparedness < 3 then
				
						-- Increment the parameter and pass the message on
						Call( "SendSignalMessage", message, "" .. (gPreparedness + 1), -direction, 1, 0 )
						
					else
				
						-- Send SIGNAL_UNPREPARED - train is too far away for next signal to prepare for it
						Call( "SendSignalMessage", SIGNAL_UNPREPARED, "", -direction, 1, 0 )
					end
				end
			end
		end
		
	elseif (message == SIGNAL_UNPREPARED) then

		-- These messages are sent forwards, so only pay attention to them if they're reaching link 0
			-- (If they hit any other links on the way up first, they'll be forwarded as PASS messages)
		-- Ignore the message if we're already unprepared, or if we're a yard exit, as they should always be prepared
		if linkIndex == 0 and gPreparedness ~= message and gPreparedness ~= SIGNAL_PREPARED_ALWAYS then

			DebugPrint( ("DEBUG: DefaultReactToSignalMessage() - SIGNAL_UNPREPARED received, gPreparedness changed from " .. gPreparedness .. " to " .. message) )

			-- We no longer have a train approaching us
			gPreparedness = message
			
			-- If we were showing Sh1, shut it off now
--			gShuntState = false

			-- Check our state
			DetermineSignalState()
			
			-- If there's no train in our block...
			if ( gOccupationTable[0] == 0 and (gConnectedLink < 1 or gOccupationTable[gConnectedLink] == 0) ) then

				-- Pass the message on unchanged
				Call( "SendSignalMessage", message, parameter, -direction, 1, 0 )
			end
		end

	elseif (message == INITIALISE_TO_PREPARED) then

		-- Received if there's a train on the line behind us when the route first loads
		-- This message is sent forwards, so only pay attention if they're reaching link 0 from behind
		-- Ignore the message if we're a yard exit, as they should always be prepared
		if linkIndex == 0 and gPreparedness ~= SIGNAL_PREPARED_ALWAYS then

			DebugPrint( ("DEBUG: DefaultReactToSignalMessage: INITIALISE_TO_PREPARED received on linkIndex 0") )

			-- Update preparedness
			gPreparedness = 1
			
			-- If we're a pure Vr signal, and the train isn't straddling our link 0, pass a message up the line
				-- This lets the Hp signal ahead of us know that it has a train approaching it
			if ( HP_SIGNAL_HEAD_NAME == nil and parameter ~= "DoNotForward" ) then
			
				Call( "SendSignalMessage", message, parameter, -direction, 1, 0 )
			end
		end
		

	-- ALL OTHER MESSAGES ARE IGNORED BY VR SIGNALS
	
	elseif ( HP_SIGNAL_HEAD_NAME == nil ) then

		-- Pass on any other messages Vr signals receive on their 0 link
		-- UNLESS the message is flagged as "DoNotForward" (eg, initialisation messages from a train straddling our link)
		if ( linkIndex == 0 and parameter ~= "DoNotForward" ) then

			Call( "SendSignalMessage", message, parameter, -direction, 1, 0 )
		end



	-- OCCUPANCY - ONLY FOR SIGNALS WITH HP HEADS, IGNORED BY VR SIGNALS

	elseif (message == OCCUPATION_DECREMENT) then

		-- A train has just left our block - update occupancy table
		if gOccupationTable[linkIndex] > 0 then
			gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
			DebugPrint( ("DEBUG: DefaultReactToSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		else
			Print( ("ERROR: DefaultReactToSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "] was already 0!") )
		end

		-- If this isn't the connected link...
		if linkIndex ~= gConnectedLink then
		
			-- Do nothing

		-- If there's still a train in our block
		elseif gOccupationTable[0] > 0 or gOccupationTable[linkIndex] > 0 then
		
			-- Let the signal ahead of us on that link know it still has a train approaching it
			Call( "SendSignalMessage", SIGNAL_PREPARED, "1", 1, 1, 0 )

		-- If we're a yard exit
		elseif gPreparedness == SIGNAL_PREPARED_ALWAYS then
		
			-- Let the signal ahead of us on that link know it might still have a train approaching it
			Call( "SendSignalMessage", SIGNAL_PREPARED, "2", 1, 1, 0 )
		
		-- If there's another train approaching us, and it's less than 3 signals behind us
		elseif gPreparedness < 3 then
		
			-- Let the signal ahead of us on that link know it still has a train approaching it
			Call( "SendSignalMessage", SIGNAL_PREPARED, "" .. (gPreparedness + 1), 1, 1, 0 )
		
		-- Otherwise...
		else
			-- Signal state should change now
			DetermineSignalState()
		
			-- Pass a SIGNAL_UNPREPARED message up the track to clear any Vr signals between us and the next Hp signal
			Call( "SendSignalMessage", SIGNAL_UNPREPARED, "", 1, 1, 0 )
		end
		
	elseif (message == OCCUPATION_INCREMENT) then

		-- A train has just entered our block - update occupancy table
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: DefaultReactToSignalMessage: OCCUPATION_INCREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )

		-- If this is the connected link...
		if linkIndex == gConnectedLink then
		
			-- Signal state should change now
			DetermineSignalState()
		
			-- Pass a SIGNAL_PREPARED message up the track to activate any Vr signals between us and the next Hp signal
			Call( "SendSignalMessage", SIGNAL_PREPARED, "1", 1, 1, 0 )
		end

	elseif (message == INITIALISE_SIGNAL_TO_BLOCKED) then
	
		-- There's a train on the line ahead of us when the route first loads
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: DefaultReactToSignalMessage: INITIALISE_SIGNAL_TO_BLOCKED received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		
		
		
	-- SPECIAL SIGNAL MESSAGE TO HANDLE REQUESTS TO PASS A SIGNAL THAT USES THE SH1 ASPECT
--[[	
	elseif (message == REQUEST_TO_PASS_DANGER) then
	
		-- If we support the Sh1 aspect and we're currently showing red...
		if (gShuntSignal and gSignalState == BLOCKED) then

			-- Activate the Sh1 aspect
			gShuntState = true
			DetermineSignalState()
		end
	]]
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
-- The state info is used for PZB scripting.
--
function GetSignalState( )

	DebugPrint(("GetSignalState() : " .. gSignalState))
	return gSignalState
end
