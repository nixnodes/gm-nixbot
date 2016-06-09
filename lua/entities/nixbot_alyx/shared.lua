AddCSLuaFile()

CreateConVar( "sbox_maxnixbot_alyx", "1", bit.bor(FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE) )

--DEFINE_BASECLASS( "nixbot_base" )

ENT.Base 			= "nixbot_base"
ENT.Spawnable		= true

ENT.Model = Model( "models/alyx.mdl" )

ENT.Options = {
	Weapon = {
		Class = "weapon_deagle",
		Attachement = "anim_attachment_RH",		
	},
	Combat = {
		BaseAccuracy = 0.46
	},
	Stats = {
		Health = 125,
		Awareness = 0.45,		
		Athletics = 0.31,
		Agility = 0.34,
		Courage = 0.75,
		CommRange = 4800,	
		Female = true
	}, AnimHit = {
		"p_LeanFwdLeft_Rifleout"
	}, Sounds = {
		Hurt = {
			"nixbot_alyx_hurt_01",
			"nixbot_alyx_hurt_02",
			"nixbot_alyx_hurt_03",
			"nixbot_alyx_hurt_04"
		},
		AlertDanger = {
			"nixbot_alyx_alert_danger_01",
			"nixbot_alyx_alert_danger_02"
		},
		AlertTarget = {
			"nixbot_alyx_alert_target_01",
			"nixbot_alyx_alert_target_02",
			"nixbot_alyx_alert_target_03",
			"nixbot_female_alert_target_01",
			"nixbot_female_alert_target_02"
		}, 
		OnDie = {
			"nixbot_alyx_die_01",
			"nixbot_alyx_die_02"
		}
	}
}

sound.Add( {
	name = "nixbot_alyx_die_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 98, 104 },
	sound = Sound("vo/npc/alyx/uggh01.wav")
} )

sound.Add( {
	name = "nixbot_alyx_die_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 98, 104 },
	sound = Sound("vo/npc/alyx/uggh02.wav")
} )

sound.Add( {
	name = "nixbot_alyx_alert_target_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 98, 104 },
	sound = Sound("vo/npc/alyx/coverme01.wav")
} )

sound.Add( {
	name = "nixbot_alyx_alert_target_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 98, 104 },
	sound = Sound("vo/npc/alyx/coverme02.wav")
} )

sound.Add( {
	name = "nixbot_alyx_alert_target_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 98, 104 },
	sound = Sound("vo/npc/alyx/coverme03.wav")
} )

sound.Add( {
	name = "nixbot_alyx_alert_danger_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/alyx/lookout01.wav")
} )

sound.Add( {
	name = "nixbot_alyx_alert_danger_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/alyx/lookout03.wav")
} )

sound.Add( {
	name = "nixbot_alyx_hurt_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/alyx/hurt04.wav")
} )

sound.Add( {
	name = "nixbot_alyx_hurt_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/alyx/hurt05.wav")
} )

sound.Add( {
	name = "nixbot_alyx_hurt_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/alyx/hurt06.wav")
} )

sound.Add( {
	name = "nixbot_alyx_hurt_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/alyx/hurt08.wav")
} )


list.Set( "NPC", "nixbot_alyx", {
	Name = "Alyx",
	Class = "nixbot_alyx",
	Category = "Nextbot"
} )