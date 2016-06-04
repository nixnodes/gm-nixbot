AddCSLuaFile()

--DEFINE_BASECLASS( "nixbot_base" )

ENT.Base 			= "nixbot_base"
ENT.Spawnable		= true

ENT.Model = Model( "models/barney.mdl" )

ENT.Options = {
	Weapon = {
		Class = "weapon_awp",
		Attachement = "anim_attachment_RH",		
		BannedHoldtypes = { ["pistol"] = true }
	},
	Combat = {
		BaseAccuracy = 0.58
	},
	Stats = {
		Health = 155,
		Awareness = 0.41,		
		Athletics = 0.33,
		Agility = 0.32,
		Bravery = 0.64,
		CommRange = 3500,
	}, AnimHit = {
		"SWI_toDelivery"
	},Sounds = {
		Hurt = {
			"nixbot_barney_hurt_01",
			"nixbot_barney_hurt_02",
			"nixbot_barney_hurt_03",
			"nixbot_barney_hurt_04",
			"nixbot_barney_hurt_05",
			"nixbot_barney_hurt_06",
			"nixbot_barney_hurt_07",
			"nixbot_barney_hurt_08",
			"nixbot_barney_hurt_09",
			"nixbot_barney_hurt_10"
		},
		AlertDanger = {
			"nixbot_barney_alert_danger_01",
			"nixbot_barney_alert_danger_02"
		},
		AlertTarget = {
			"nixbot_barney_alert_target_01",
			"nixbot_barney_alert_target_02",
			"nixbot_barney_alert_target_03",
			"nixbot_barney_alert_target_04"			
		},
		FollowConfirm = {
			"nixbot_barney_follow_confirm_01",
			"nixbot_barney_follow_confirm_02"
		},
		Boast = {
			"nixbot_barney_boast_01",	
			"nixbot_barney_boast_02",
			"nixbot_barney_boast_03"
		}, 
		OnDie = {
			"nixbot_barney_die_01",
			"nixbot_barney_die_02"
		},
		OnKill = {
			"nixbot_barney_onkill_01",
			"nixbot_barney_onkill_02"
		},
		PlayerAvoid = {
			"nixbot_barney_avoid_player_01"
		},
		PlayerBumpBot = {
			"nixbot_barney_plybumpbot_01"
		}
	}
}

sound.Add( {
	name = "nixbot_barney_plybumpbot_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 70,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_lookout.wav")
} )

sound.Add( {
	name = "nixbot_barney_avoid_player_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_getoutofway.wav")
} )

sound.Add( {
	name = "nixbot_barney_avoid_player_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_getoutofway.wav")
} )

sound.Add( {
	name = "nixbot_barney_onkill_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_gotone.wav")
} )

sound.Add( {
	name = "nixbot_barney_onkill_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_downyougo.wav")
} )

sound.Add( {
	name = "nixbot_barney_follow_confirm_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_letsgo.wav")
} )

sound.Add( {
	name = "nixbot_barney_follow_confirm_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_imwithyou.wav")
} )

sound.Add( {
	name = "nixbot_barney_die_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_no01.wav")
} )

sound.Add( {
	name = "nixbot_barney_die_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_ohshit03.wav")
} )

sound.Add( {
	name = "nixbot_barney_boast_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_losttouch.wav")
} )

sound.Add( {
	name = "nixbot_barney_boast_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_yell.wav")
} )

sound.Add( {
	name = "nixbot_barney_boast_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_ohyeah.wav")
} )

sound.Add( {
	name = "nixbot_barney_alert_target_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_heretheycome01.wav")
} )

sound.Add( {
	name = "nixbot_barney_alert_target_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_heretheycome02.wav")
} )

sound.Add( {
	name = "nixbot_barney_alert_target_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_bringiton.wav")
} )


sound.Add( {
	name = "nixbot_barney_alert_target_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_uhohheretheycome.wav")
} )

sound.Add( {
	name = "nixbot_barney_alert_danger_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_lookout.wav")
} )

sound.Add( {
	name = "nixbot_barney_alert_danger_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_getdown.wav")
} )


sound.Add( {
	name = "nixbot_barney_hurt_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain01.wav")
} )

sound.Add( {
	name = "nixbot_barney_hurt_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain02.wav")
} )

sound.Add( {
	name = "nixbot_barney_hurt_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain03.wav")
} )

sound.Add( {
	name = "nixbot_barney_hurt_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain04.wav")
} )

sound.Add( {
	name = "nixbot_barney_hurt_05",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain05.wav")
} )

sound.Add( {
	name = "nixbot_barney_hurt_06",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain06.wav")
} )

sound.Add( {
	name = "nixbot_barney_hurt_07",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain07.wav")
} )

sound.Add( {
	name = "nixbot_barney_hurt_08",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain08.wav")
} )


sound.Add( {
	name = "nixbot_barney_hurt_09",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain09.wav")
} )


sound.Add( {
	name = "nixbot_barney_hurt_10",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 100, 105 },
	sound = Sound("vo/npc/barney/ba_pain10.wav")
} )



list.Set( "NPC", "nixbot_barney", {
	Name = "Barney",
	Class = "nixbot_barney",
	Category = "Nextbot"
} )