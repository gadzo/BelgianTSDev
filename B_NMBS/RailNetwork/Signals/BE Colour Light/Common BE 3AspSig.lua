-- This is a three aspect signal
gAspect					= 3

-- Set our light node names
LIGHT_NODE_GREEN		= "mod_be_hd_3asp_green"
LIGHT_NODE_YELLOW		= "mod_be_hd_3asp_orange"
LIGHT_NODE_RED			= "mod_be_hd_3asp_red"



--------------------------------------------------------------------------------------
-- SET LIGHTS
-- Switches the lights on / off depending on state of signal
--
function SetLights( newState )
	DefaultSetLights( newState )
end

--------------------------------------------------------------------------------------
-- UPDATE
-- Initialises the signal when the route finishes loading, and handles flashing lights
--
function Update ( time )
	DefaultUpdate( time )
end

--------------------------------------------------------------------------------------
-- ON CONSIST PASS
-- Called when a train passes one of the signal's links
--
function OnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	-- Use DefaultOnConsistPass
	DefaultOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )
end

--------------------------------------------------------------------------------------
-- JUNCTION STATE CHANGE
-- Called when a junction is changed. Should only be handled by home signals.
--
function OnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	-- Use DefaultOnJunctionStateChange
	DefaultOnJunctionStateChange( junction_state, parameter, direction, linkIndex )
end

-------------------------------------------------------------------------------------
-- REACT TO SIGNAL MESSAGE
-- Subfunction to save duplicate code when handling pass back messages - just takes all the old scripting out of the OnSignalMessage function
--
function ReactToSignalMessage( message, parameter, direction, linkIndex )

	-- Use DefaultReactToSignalMessage
	DefaultReactToSignalMessage( message, parameter, direction, linkIndex )
end

-------------------------------------------------------------------------------------
-- ON SIGNAL MESSAGE
-- Handles messages from other signals. 
--
function OnSignalMessage( message, parameter, direction, linkIndex )

	-- Use DefaultOnSignalMessage
	DefaultOnSignalMessage( message, parameter, direction, linkIndex )
end
