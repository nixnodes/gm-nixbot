AddCSLuaFile()

function MODULE.print(...)
	print("NIXBOT: "..(SERVER and "[sv]" or "[cl]")..": ", ...)
end