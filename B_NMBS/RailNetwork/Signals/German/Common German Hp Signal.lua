-- Set Hp light node names
HP_LIGHT_NODE_GREEN		= "mod_be_hd_3asp_green"
HP_LIGHT_NODE_YELLOW	= "mod_be_hd_3asp_orange"
HP_LIGHT_NODE_RED1		= "mod_be_hd_3asp_red"
HP_LIGHT_NODE_RED2		= "mod_be_hd_3asp_red"
HP_LIGHT_NODE_WHITE1	= "mod_be_hd_3asp_white"
HP_LIGHT_NODE_WHITE2	= "mod_be_hd_3asp_white"

-- Set Vr light node names
VR_LIGHT_NODE_GREEN1	= "GR_Mod_Dist_Green_1"
VR_LIGHT_NODE_GREEN2	= "GR_Mod_Dist_Green_2"
VR_LIGHT_NODE_YELLOW1	= "GR_Mod_Dist_Orange_1"
VR_LIGHT_NODE_YELLOW2	= "GR_Mod_Dist_Orange_2"

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
