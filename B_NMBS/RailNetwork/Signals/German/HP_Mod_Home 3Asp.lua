--------------------------------------------------------------------------------------
-- German Hauptsignal
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

-- include=Common German Hp Signal.lua
-- include=CommonScripts\New Common German Script.lua
-- include=..\CommonScripts\New Common Signal Script.lua

--------------------------------------------------------------------------------------
-- INITIALISE
--
function Initialise ( )

	-- This is a post signal, so need reference to the attached signal head to switch lights on and off
	HP_SIGNAL_HEAD_NAME = "HP Signal Head:"
	
	DefaultInitialise(false)

	-- AS 19/04/09 - add variants for exit signals in sidings plus marker light deployment
	gNeverHp1 = false		-- original standard configuration
	gNeverHp1Vr0 = false
	gNeverHp1Vr2 = false
	
	-- This signal doesn't have Sh1 lights
	HP_LIGHT_NODE_WHITE1	= nil
	HP_LIGHT_NODE_WHITE2	= nil
end
