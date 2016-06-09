AddCSLuaFile()

--DEFINE_BASECLASS( "nixbot_base" )

ENT.Base 			= "nixbot_base"
ENT.Spawnable		= true

ENT.Model = Model( "models/breen.mdl" )

ENT.Options = {
	Weapon = {
		Class = "weapon_xm1014",
		Attachement = "anim_attachment_RH",	
		BannedHoldtypes = { ["pistol"] = true }
	},
	Combat = {
		BaseAccuracy = 0.62
	},
	Stats = {
		Health = 175,
		Awareness = 0.61,		
		Athletics = 0.36,
		Agility = 0.31,
		Courage = 0.84,
		CommRange = 4000,	
	}, AnimHit = {
		"SWI_toDelivery"
	},Sounds = {
		PitchOffset = math.random(0,2)
	}
}

list.Set( "NPC", "nixbot_breen", {
	Name = "Breen",
	Class = "nixbot_breen",
	Category = "Nextbot"
} )
