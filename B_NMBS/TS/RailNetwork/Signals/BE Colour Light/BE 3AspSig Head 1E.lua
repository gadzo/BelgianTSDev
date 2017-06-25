--------------------------------------------------------------------------------------
-- UK 3 Aspect Signal Head with yard entry on last link
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

--include=Common BE 3AspSig.lua
--include=CommonScripts\Common BE Colour Light Script.lua
--include=..\CommonScripts\New Common Signal Script.lua

--------------------------------------------------------------------------------------
-- INITIALISE
--
function Initialise ()

	DefaultInitialise( )

	-- Only last link is a yard entry
	gYardEntry[gLinkCount - 1] = true
	
	-- The rest aren't
	for link = 1, gLinkCount - 2 do
		gYardEntry[link] = false
	end
end
