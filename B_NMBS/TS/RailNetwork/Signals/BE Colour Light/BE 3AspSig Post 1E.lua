--------------------------------------------------------------------------------------
-- UK 3 Aspect Signal Post with multiple links, last of which is a yard entry
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

--include=Common BE 3AspSig.lua
--include=CommonScripts\Common BE Colour Light Script.lua
--include=..\CommonScripts\New Common Signal Script.lua
 
--------------------------------------------------------------------------------------
-- INITIALISE
--
function Initialise ()

	-- This is a post signal, so need reference to the attached signal head to switch lights on and off
	SIGNAL_HEAD_NAME = "3 Aspect Signal Head:"
	
	DefaultInitialise( )

	-- Only last link (gLinkCount - 1) is a yard entry
	gYardEntry[gLinkCount - 1] = true
	
	-- The rest aren't
	for link = 1, gLinkCount - 2 do
		gYardEntry[link] = false
	end
end
