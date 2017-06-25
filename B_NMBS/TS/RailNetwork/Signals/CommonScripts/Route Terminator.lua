--------------------------------------------------------------------------------------
-- Route Terminator Script - can be used on any route
-- Used for the end of a line, where we want the preceding signal(s) to show a warning aspect
-- RSDL / Rail Simulator
--------------------------------------------------------------------------------------

-- Included for constants only
--include=New Common Signal Script.lua
 
--------------------------------------------------------------------------------------
-- INITIALISE
--
function Initialise ()

	-- Tells the game to do an update tick once the route finishes loading
	-- This will ensure the other signals are loaded before the route terminator sends a blocked message to them
	Call( "BeginUpdate" )
end

--------------------------------------------------------------------------------------
-- UPDATE
--
function Update ( time )

	-- Send a Blocked message to set the preceding home signal to warning
	Call( "SendSignalMessage", SIGNAL_BLOCKED, "EndOfRoute", -1, 1, 0 )

	-- Set the signal to appear as blocked on the 2D map
	Call( "Set2DMapSignalState", BLOCKED )
	
	Call( "EndUpdate" )
end

--------------------------------------------------------------------------------------
-- ON CONSIST PASS
-- Called when a train passes one of the signal's links
--
function OnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )
	-- Do nothing!
end

-------------------------------------------------------------------------------------
-- ON SIGNAL MESSAGE
-- Handles messages from other signals. 
--
function OnSignalMessage( message, parameter, direction, linkIndex )

	-- SIGNAL RESET

	if (message == RESET_SIGNAL_STATE) then
	
		-- Resets signal state, if scenario is reset
		ResetSignalState()
	end
	
	-- Otherwise DO NOTHING!
end

--------------------------------------------------------------------------------------
-- GET SIGNAL STATE
-- Gets the current state of the signal - blocked, warning or clear
--
function GetSignalState( )

	-- We're always BLOCKED!
	return BLOCKED
end
