--------------------------------------------------------------------------------------
-- UK 3 Aspect Signal Head with all links 1+ as yard entries
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
	
	-- All links are in yards
	for link = 1, gLinkCount - 1 do
		gYardEntry[link] = true
	end
end
