--------------------------------------------------------------------------------------
-- Common signal functionality
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- GLOBALS

-- States
CLEAR = 0
WARNING = 1
BLOCKED = 2


-- LIGHT STATES - For UK Colour Lights
ANIMSTATE_GREEN									= 0
ANIMSTATE_YELLOW								= 1
ANIMSTATE_DOUBLE_YELLOW							= 2
ANIMSTATE_RED									= 3
-- 4-9 left clear to allow for any other non-flashing light states
ANIMSTATE_FLASHING_YELLOW						= 10
ANIMSTATE_FLASHING_DOUBLE_YELLOW				= 11


-- LIGHT STATES - For German Colour Lights
ANIMSTATE_HP0									= 0
ANIMSTATE_HP1									= 1
ANIMSTATE_HP2									= 2
ANIMSTATE_HPM									= 3		-- Hauptsignal showing white marker
ANIMSTATE_SH1									= 4
ANIMSTATE_VR0									= 5
ANIMSTATE_VR1									= 6
ANIMSTATE_VR2									= 7
ANIMSTATE_VRX									= 8		-- Vorsignal switched off
	
	
-- Signal Messages (0-9 are reserved by code)
RESET_SIGNAL_STATE								= 0
INITIALISE_SIGNAL_TO_BLOCKED 					= 1
JUNCTION_STATE_CHANGE							= 2
INITIALISE_TO_PREPARED							= 3
--REQUEST_TO_PASS_DANGER						= ?

-- Locally defined signal mesages
OCCUPATION_INCREMENT							= 10
OCCUPATION_DECREMENT							= 11

SIGNAL_BLOCKED									= 12
SIGNAL_CLEARED									= 13
SIGNAL_WARNING									= 14
SIGNAL_WARNING2									= 15

-- special signal messages only used by the signals that message the opposite facing signal
-- in the section of track where two single direction tracks converge to one dual direction track
	-- currently only used for UK Semaphore signals
OCCUPATION_REVERSE_INCREMENT 		 			= 16
OCCUPATION_REVERSE_DECREMENT 					= 17

-- UK / GERMAN SPECIFIC functionality: used to set preparedness of control signals (which default to red)
SIGNAL_UNPREPARED								= 18
SIGNAL_PREPARED									= 19
SIGNAL_PREPARED_VISIBLE							= 20	-- Special state for UK signals with approach control
SIGNAL_PREPARED_ALWAYS							= 20	-- Special state for German yard exit signals

-- UK SPECIFIC functionality: Approach Control status
SIGNAL_STRAIGHT									= 21
SIGNAL_DIVERGING_RED							= 22	-- Diverging at this junction			Approach Control from red
SIGNAL_DIVERGING_YELLOW							= 23	-- Diverging at next junction			Approach Control from red
SIGNAL_DIVERGING_DOUBLE_YELLOW					= 24	-- Diverging at next but one junction	Approach Control from red
SIGNAL_DIVERGING_FLASHING						= 25	-- Diverging at this junction			Approach Control with flashing yellows
SIGNAL_DIVERGING_FLASHING_YELLOW				= 26	-- Diverging at next junction			Approach Control with flashing yellows
SIGNAL_DIVERGING_FLASHING_DOUBLE_YELLOW			= 27	-- Diverging at next but one junction	Approach Control with flashing yellows

-- Signal Type - for UK Colour Lights
SIGNAL_TYPE_AUTO								= 28	-- Auto signal
SIGNAL_TYPE_CONTROL								= 29	-- Control signal
SIGNAL_TYPE_CONTROL_APPROACH_RED				= 30	-- Control signal using Approach Control from red
SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW	= 31	-- Control signal using Approach Control with flashing yellows

-- Signal Type - for German Colour Lights
SIGNAL_TYPE_HP									= 28	-- Hauptsignal
SIGNAL_TYPE_HPVR								= 29	-- Hauptsignal + Vorsignal combined
SIGNAL_TYPE_HPVRr								= 30	-- Hauptsignal + Vorsignal repeater combined
SIGNAL_TYPE_VR									= 31	-- Vorsignal
SIGNAL_TYPE_VRr									= 32	-- Vorsignal repeater

-- Special query message used by UK Semaphore signals
SIGNAL_QUERY_PREPAREDNESS						= 32

-- Signal Messages 33-39 are available for later extension
-- Signal Messages 40-49 reserved for end user expansion


-- What you need to add to a signal message number to turn it into the equivalent PASS message
PASS_OFFSET										= 50


-- Pass on messages to handle overlapping links (eg for converging junctions / crossovers)
	-- Populated by BaseInitialise()
PASS = { }

	
-- UK-SPECIFIC AWS / TPWS WARNING MESSAGES
AWS_MESSAGE										= 11
TPWS_MESSAGE									= 12

-- GERMAN-SPECIFIC PZB WARNING MESSAGES
PZB_1000_MESSAGE								= 11
PZB_2000_MESSAGE								= 12

-- GENERIC "SIGNAL PASSED AT DANGER" MESSAGE
SPAD_MESSAGE 									= 14

-- CONSIST TYPES - USED BY GERMAN PZB SYSTEM
CONSIST_TYPE_SPECIAL						= 0
CONSIST_TYPE_LIGHT_ENGINE					= 1
CONSIST_TYPE_EXPRESS_PASSENGER				= 2
CONSIST_TYPE_STOPPING_PASSENGER				= 3
CONSIST_TYPE_HIGH_SPEED_FREIGHT				= 4
CONSIST_TYPE_EXPRESS_FREIGHT				= 5
CONSIST_TYPE_STANDARD_FREIGHT				= 6
CONSIST_TYPE_LOW_SPEED_FREIGHT				= 7
CONSIST_TYPE_OTHER_FREIGHT					= 8
CONSIST_TYPE_EMPTY_STOCK					= 9
CONSIST_TYPE_INTERNATIONAL					= 10

-- GENERIC CONSIST TYPES - PZB ONLY USES 3 CLASSES OF TRAIN
CONSIST_TYPE_FAST_PASSENGER					= 100
CONSIST_TYPE_SLOW_PASSENGER					= 101
CONSIST_TYPE_FREIGHT						= 102


-- Script global variables
gUpdating		= 0								-- are we updating?
gConnectedLink	= 0								-- which link is connected?



-- debugging stuff
DEBUG = false 									-- set to true to turn debugging on
function DebugPrint( message )
	if (DEBUG) then
		Print( message )
	end
end

--------------------------------------------------------------------------------------
-- BASE INITIALISE
-- initialise function used by all signal scripts
--
function BaseInitialise()

	-- Initialise PASS constants
	for i = 0, PASS_OFFSET do
		PASS[i] = i + PASS_OFFSET
	end

	-- Initialise global variables
	gLinkCount = Call( "GetLinkCount" )			-- number of links this signal has
	
	-- Initialise tables
	gLinkState = {}								-- state of line beyond this link
	gYardEntry = {}								-- is this link going inside a yard?
	gOccupationTable = {}						-- how many trains are in this part of our block?

	for link = 0, gLinkCount - 1 do
		gLinkState[link] = SIGNAL_CLEARED
		gYardEntry[link] = false
		gOccupationTable[link] = 0
	end
end

--------------------------------------------------------------------------------------
-- RESET SIGNAL STATE
-- Resets the signal when the route / scenario is reloaded
--
function ResetSignalState ( )
--[[
	DebugPrint( "DEBUG: ResetSignalState() started")
	
	-- Re-initialise the signal
	Initialise()
	
	DebugPrint( "DEBUG: ResetSignalState() ended")
]]
end
	
--------------------------------------------------------------------------------------
-- BASE ON CONSIST PASS
-- Called when a train passes one of the signal's links
--
function BaseOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	local crossingStart = 0
	local crossingEnd = 0

	-- if the consist is crossing the signal now
	if ( frontDist > 0 and backDist < 0 ) or ( frontDist < 0 and backDist > 0 ) then
		-- if the consist was previously before/after siganl then the crossing has just started
		if ( prevFrontDist < 0 and prevBackDist < 0 ) or ( prevFrontDist > 0 and prevBackDist > 0 ) then
			DebugPrint( ("DEBUG: BaseOnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingStart = 1
		end
		
	-- otherwise the consist is not crossing the signal now
	else	
		-- the the consist was previously crossing the signal, then it has just finished crossing
		if ( prevFrontDist < 0 and prevBackDist > 0 ) or ( prevFrontDist > 0 and prevBackDist < 0 ) then
			DebugPrint( ("DEBUG: BaseOnConsistPass: Crossing cleared... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingEnd = 1
		end
	end

	-- a train has just started crossing a link!
	if (crossingStart == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the normal direction...
		if (prevFrontDist > 0 and prevBackDist > 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Started crossing forwards!" )
			
			-- if the train just started crossing link 0 in the normal direction, increment occupation table slot 0
			if (linkIndex == 0) then
			
				-- Check for SPADs first
				if (gSignalState == BLOCKED) then
					DebugPrint("SPAD")
					Call( "SendConsistMessage", SPAD_MESSAGE, "" )
				end
			
				gOccupationTable[0] = gOccupationTable[0] + 1
				DebugPrint( ("DEBUG: BaseOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				DetermineSignalState()

				-- If this is the only train in our block at the moment, and we're connected to a valid link
				if gOccupationTable[0] == 1 and gConnectedLink ~= -1 and (gConnectedLink == 0 or gOccupationTable[gConnectedLink] == 0) then

					-- Send a signal message up the connected track to tell the next signal it's got a train approaching it
					
					-- If we've got another link, send SIGNAL_PREPARE
					if gLinkCount > 1 then
						Call( "SendSignalMessage", SIGNAL_PREPARED, "", 1, 1, gConnectedLink )
						
					-- Otherwise send SIGNAL_PREPARE_VISIBLE, in case there isn't an AWS grid further up the line to set the next signal
					else
						Call( "SendSignalMessage", SIGNAL_PREPARED_VISIBLE, "", 1, 1, gConnectedLink )
					end
				end

			-- if the train just started crossing link 1, 2, 3 etc. increment the appropriate occupation table slot
			elseif (linkIndex > 0) then
			
				-- Ignore if this link is inside a yard - once a train gets into a yard, the yard's entry signal doesn't care about it anymore
				if not gYardEntry[linkIndex] then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
					DebugPrint( ("DEBUG: BaseOnConsistPass: INCREMENT... gOccupationTable[linkIndex]: " .. gOccupationTable[linkIndex]) )

					-- If this is the only train in that part of the block and it's the connected line
					if (linkIndex == gConnectedLink and gOccupationTable[linkIndex] == 1) then
						-- Send a signal message up the track to tell the next signal it's got a train approaching close to it
						Call( "SendSignalMessage", SIGNAL_PREPARED_VISIBLE, "", 1, 1, gConnectedLink )
					end
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the opposite direction...
		elseif (prevFrontDist < 0 and prevBackDist < 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Started crossing backwards!" )
			
			-- if the train just started crossing link 0 in reverse, send OCCUPATION_INCREMENT
			if (linkIndex == 0) then
				DebugPrint( "DEBUG: BaseOnConsistPass: A train starts passing link 0 in the opposite direction. Send OCCUPATION_INCREMENT." )
				Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )
				
			-- if the train just started crossing link 1, 2, 3 etc. in reverse, increment occupation table slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line, or exit signal for connected line
				if (gConnectedLink == linkIndex) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint( ("DEBUG: BaseOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
					
					-- If we're coming out of a yard, signal won't be red already because trains inside the yard are ignored
					if gYardEntry[linkIndex] then
						DetermineSignalState()
					end

				-- Otherwise  the train must be reversing onto another line
				else
					DebugPrint( "DEBUG: BaseOnConsistPass: Consist reversing down another line, don't increment occupation table for this line" )
				end
			end
		end
		
	-- a train has just finished crossing a link!
	elseif (crossingEnd == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing backwards...
		if (frontDist > 0 and backDist > 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Finished crossing backwards!" )
			
			-- if the train just finished crossing link 0 in reverse, decrement occupation table slot 0
			if (linkIndex == 0) then
				if gOccupationTable[0] > 0 then
					gOccupationTable[0] = gOccupationTable[0] - 1
					DebugPrint( ("DEBUG: BaseOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				else
					Print( "DEBUG: BaseOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
				end

				-- If we're a control signal and a train has just reversed past us, we now have a train "approaching" us
				if gSignalType ~= SIGNAL_TYPE_AUTO then
					gPreparedness = SIGNAL_PREPARED_VISIBLE
				end

				-- If nobody else is left in our block, and we're connected to a valid link...
				if (gOccupationTable[0] == 0 and gConnectedLink ~= -1 and gOccupationTable[gConnectedLink] == 0) then

					-- Update signal state
					DetermineSignalState()
				
					-- Send a message up the connected line to let the next signal know it no longer has a train approaching it
					Call( "SendSignalMessage", SIGNAL_UNPREPARED, "", 1, 1, gConnectedLink )
				end

			-- if the train just finished crossing link 1, 2, 3 etc. in reverse, decrement the appropriate occupation table slot
			elseif (linkIndex > 0) then

				-- Only count the train if this link isn't inside a yard - once a train gets into a yard, signals outside the yard don't care about it anymore
				if not gYardEntry[linkIndex] then
				
					if gOccupationTable[linkIndex] > 0 then
						gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
						DebugPrint( ("DEBUG: BaseOnConsistPass: DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )

						-- If nobody else is left in that part of our block, and that's the connected link
						if linkIndex == gConnectedLink and gOccupationTable[gConnectedLink] == 0 then
						
							-- Send a message up the connected line to let the next signal know it still has a train approaching it, but it's not close anymore
							Call( "SendSignalMessage", SIGNAL_PREPARED, "", 1, 1, gConnectedLink )
						end
					else
						Print( ( "DEBUG: BaseOnConsistPass: Attempting to DECREMENT... gOccupationTable[" .. linkIndex .. "] was already empty" ) )
					end
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing in the normal direction...
		elseif (frontDist < 0 and backDist < 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Finished crossing forwards!" )
			
			-- if the train just finished crossing link 0 in the normal direction, send OCCUPATION_DECREMENT
			if (linkIndex == 0) then

				-- If we're a control signal and a train has just gone past us, we (probably) no longer have a train approaching us
				-- If there was more than one train in the preceding block, we'll be corrected when the signal behind us gets the decrement message
				if gSignalType ~= SIGNAL_TYPE_AUTO then
					gPreparedness = SIGNAL_UNPREPARED
				end

				DebugPrint( "DEBUG: BaseOnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT." )
				Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
				
			-- if the train just finished crossing link 1, 2, 3 etc. in the normal direction, decrement occupation slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line
				if (gConnectedLink == linkIndex) then
					if gOccupationTable[0] > 0 then
						gOccupationTable[0] = gOccupationTable[0] - 1
						DebugPrint( ("DEBUG: BaseOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )

						-- If we're going into a yard, signal needs to go back to Restricted from Blocked, because trains in yard are ignored by signal
						if gYardEntry[linkIndex] then
							DetermineSignalState()
						end
					else
						Print( "DEBUG: BaseOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
					end
				else
					DebugPrint( "DEBUG: BaseOnConsistPass: Consist on another line, don't decrement occupation table for this line" )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- BASE ON JUNCTION STATE CHANGE
-- Called when a signal receives a message saying that a junction ahead of it has switched
--
function BaseOnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: BaseOnJunctionStateChange(" .. junction_state .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check junction has finished transition
	if junction_state == 0 then
		if linkIndex == 0 then
			if gLinkCount == 1 then
				DebugPrint( "DEBUG: BaseOnJunctionStateChange: Junction change message received by single link signal" )
			else
				-- this will be used as a search depth - it must be passed as a string
				linkCountAsString = "" .. (5 * (gLinkCount + 1))

				-- find the link that is now connected to the signal
				local newConnectedLink = Call( "GetConnectedLink", linkCountAsString, 1, 0 )
				
				-- Don't waste time doing anything else if the connected link hasn't changed
				if newConnectedLink == gConnectedLink then
					DebugPrint( ("WARNING: BaseOnJunctionStateChange triggered by message from junction that hasn't effected its state, still connected to " .. gConnectedLink ) )

				else
					-- If the previously connected route through our block is no longer occupied
					if gConnectedLink > 0 and gOccupationTable[0] > 0 and gOccupationTable[gConnectedLink] == 0 then

						-- Let the next signal on that line know it no longer has a train approaching it
						Call( "SendSignalMessage", SIGNAL_UNPREPARED, "", 1, 1, gConnectedLink )
					end

					-- If the newly connected route through our block wasn't occupied before but is now
					if newConnectedLink > 0 and gOccupationTable[0] > 0 and gOccupationTable[newConnectedLink] == 0 then

						-- Let the next signal on that line know it now has a train approaching it
						Call( "SendSignalMessage", SIGNAL_PREPARED, "", 1, 1, newConnectedLink )
					end
					
					gConnectedLink = newConnectedLink
					
					DebugPrint( ("DEBUG: BaseOnJunctionStateChange: Activate connected link: " .. gConnectedLink) )

					-- Switch the signal lights as necessary based on new state of junction
					DetermineSignalState()
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- BASE ON SIGNAL MESSAGE
-- Handles messages from other signals
--
function BaseOnSignalMessage( message, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: BaseOnSignalMessage(" .. message .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check for signal receiving a message it might need to forward, in case there are two overlapping signal blocks (eg for a converging junction or crossover)
	if (linkIndex > 0) then
	
		-- We've received a PASS message, so forward it on
		if message > PASS_OFFSET then
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
			
		-- Any message other than RESET_SIGNAL_STATE and JUNCTION_STATE_CHANGE should be forwarded as PASS messages
		-- Also ignore initialisation messages from trains straddling a link - these will have the "DoNotForward" parameter
		elseif message ~= RESET_SIGNAL_STATE and message ~= JUNCTION_STATE_CHANGE and parameter ~= "DoNotForward" then
			Call( "SendSignalMessage", message + PASS_OFFSET, parameter, -direction, 1, linkIndex )
		end
	end
	
	-- always check for a valid link index
	if (linkIndex >= 0) then

		-- If the message is a PASS message...
		if message > PASS_OFFSET then

			-- Only pay attention to it if we're not the base link of a signal
			if linkIndex > 0 then

				-- Knock PASS_OFFSET off the signal message number to convert it back to a normal message for processing
				ReactToSignalMessage( message - PASS_OFFSET, parameter, direction, linkIndex )

			-- Except for prepare and signal type messages, which are passed forwards until they reach the next link 0
			elseif direction == -1
			and (	message == PASS[SIGNAL_UNPREPARED]
				or	message == PASS[SIGNAL_PREPARED]
				or	message == PASS[SIGNAL_PREPARED_VISIBLE]
				or  message == PASS[REQUEST_TO_PASS_DANGER]
				or	message == PASS[SIGNAL_TYPE_CONTROL_APPROACH_RED]
				or	message == PASS[SIGNAL_TYPE_CONTROL_APPROACH_FLASHING_YELLOW]
				) then

				-- Knock PASS_OFFSET off the signal message number to convert it back to a normal message for processing
				ReactToSignalMessage( message - PASS_OFFSET, parameter, direction, linkIndex )
			end

		-- Otherwise, it's a normal signal so just process it as normal
		else
			ReactToSignalMessage( message, parameter, direction, linkIndex )		
		end
	end
end

--[[
--------------------------------------------------------------------------------------
-- PRINT OCCUPATION TABLE
-- Debugging function, used to print the current occupation table
--
function DebugPrintOccupationTable( occupationTable )

	occupation = "DebugPrintOccupationTable( table )"
	for i = 0, gLinkCount - 1 do
		occupation = (occupation .. ", " .. i .. "=" .. gOccupationTable[i])
	end
	
	DebugPrint( ("DEBUG: " .. occupation) )
end
--]]
