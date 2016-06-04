AddCSLuaFile()

CreateConVar( "sbox_maxnixbot_kleiner", "1", bit.bor(FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE) )

--DEFINE_BASECLASS( "nixbot_base" )

ENT.Base 			= "nixbot_base"
ENT.Spawnable		= true

ENT.Model = Model( "models/kleiner.mdl" )

ENT.Options = {
	Weapon = {
		Class = "weapon_tmp",
		Attachement = "anim_attachment_RH",		
		BannedHoldtypes = { ["pistol"] = true }	
	},
	Combat = {
		BaseAccuracy = 0.32
	},
	Stats = {
		Health = 90,
		Awareness = 0.35,		
		Athletics = 0.27,
		Agility = 0.25,
		Bravery = 0.64,
		CommRange = 3500,	
	}, AnimHit = {
		"p_LeanFwdLeft_Rifleout"
	}, Sounds = {
		PitchOffset = math.random(12,17)
	}
}

list.Set( "NPC", "nixbot_kleiner", {
	Name = "Kleiner",
	Class = "nixbot_kleiner",
	Category = "Nextbot"
} )