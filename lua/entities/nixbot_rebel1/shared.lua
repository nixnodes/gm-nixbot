AddCSLuaFile()

ENT.Base 			= "nixbot_base"
ENT.Spawnable		= true

ENT.Model = Model( "models/humans/group03/male_05.mdl" )

ENT.Options = {
	Weapon = {
		Class = "weapon_m4a1",
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
		PitchOffset = math.random(-5,5)
	}
}

list.Set( "NPC", "nixbot_rebel1", {
	Name = "Rebel",
	Class = "nixbot_rebel1",
	Category = "Nextbot"
} )
