AddCSLuaFile()

ENT.DefaultSoundsMale = {
	Level = 72,
	PitchOffset = 0,
	Hurt = {
		"nixbot_male_hurt_01",
		"nixbot_male_hurt_02",
		"nixbot_male_hurt_03",
		"nixbot_male_hurt_04",
		"nixbot_male_hurt_05",
		"nixbot_male_hurt_06",
		"nixbot_male_hurt_07",
		"nixbot_male_hurt_08",
		"nixbot_male_hurt_09"
	},
	AlertDanger = {
		"nixbot_male_alert_danger_01",
		"nixbot_male_alert_danger_02"
	},
	AlertTarget = {
		"nixbot_male_alert_target_01",
		"nixbot_male_alert_target_02"
	},
	AlertTargetDistant = {
		"nixbot_male_alert_target_distant_01",
		"nixbot_male_alert_target_distant_02"
	},
	FollowIdle = {
		"nixbot_male_follow_idle_01",
		"nixbot_male_follow_idle_02",
		"nixbot_male_follow_idle_03",
		"nixbot_male_follow_idle_04"
	},
	FollowConfirm = {
		"nixbot_male_follow_confirm_01",
		"nixbot_male_follow_confirm_02",
		"nixbot_male_follow_confirm_03"
	},
	OnKill = {
		"nixbot_male_onkill_01",
		"nixbot_male_onkill_02",
		"nixbot_male_onkill_03"
	},
	PlayerAvoid = {
		"nixbot_male_avoid_player_01",
		"nixbot_male_avoid_player_02",
		"nixbot_male_avoid_player_03",
		"nixbot_male_avoid_player_04",
		"nixbot_male_avoid_player_05"
	},
	Boast = {
		"nixbot_male_boast_01",
		"nixbot_male_boast_02",
		"nixbot_male_boast_03",
		"nixbot_male_boast_04",
		"nixbot_male_boast_05",
		"nixbot_male_boast_06",
		"nixbot_male_boast_07",
		"nixbot_male_boast_08",
		"nixbot_male_boast_09"
	}, 
	GreetPlayerFriend = {
		"nixbot_male_greet_01",
		"nixbot_male_greet_02"
	},
	GreetPlayerFoe = {
		"nixbot_male_foe_01",
		"nixbot_male_foe_02"
	},
	ReloadNormal = {
		"nixbot_male_reload_01"
	},
	ReloadCover = {
		"nixbot_male_reload_02"
	},
	PlayerBumpBot = {
		"nixbot_male_plybumpbot_01"
	},
	OnDie = {
		"nixbot_male_die_01",
		"nixbot_male_die_02"
	}
}

sound.Add( {
	name = "nixbot_male_die_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/ow01.wav")	
} )

sound.Add( {
	name = "nixbot_male_die_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/ow02.wav")	
} )

sound.Add( {
	name = "nixbot_male_hurt_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain01.wav")	
} )

sound.Add( {
	name = "nixbot_male_hurt_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain02.wav")	
} )

sound.Add( {
	name = "nixbot_male_hurt_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain03.wav")	
} )

sound.Add( {
	name = "nixbot_male_hurt_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain04.wav")	
} )

sound.Add( {
	name = "nixbot_male_hurt_05",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain05.wav")	
} )

sound.Add( {
	name = "nixbot_male_hurt_06",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain06.wav")	
} )

sound.Add( {
	name = "nixbot_male_hurt_07",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain07.wav")	
} )

sound.Add( {
	name = "nixbot_male_hurt_08",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain08.wav")	
} )

sound.Add( {
	name = "nixbot_male_hurt_09",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain09.wav")	
} )

sound.Add( {
	name = "nixbot_male_alert_danger_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/watchout.wav")	
} )

sound.Add( {
	name = "nixbot_male_alert_danger_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/getdown02.wav")	
} )


sound.Add( {
	name = "nixbot_male_follow_idle_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/getgoingsoon.wav")	
} )

sound.Add( {
	name = "nixbot_male_follow_idle_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/doingsomething.wav")	
} )

sound.Add( {
	name = "nixbot_male_follow_idle_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/question27.wav")	
} )

sound.Add( {
	name = "nixbot_male_follow_idle_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/waitingsomebody.wav")	
} )

sound.Add( {
	name = "nixbot_male_follow_confirm_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/answer13.wav")	
} )

sound.Add( {
	name = "nixbot_male_follow_confirm_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/leadtheway01.wav")	
} )

sound.Add( {
	name = "nixbot_male_follow_confirm_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/letsgo01.wav")	
} )


sound.Add( {
	name = "nixbot_male_alert_target_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/overhere01.wav")	
} )

sound.Add( {
	name = "nixbot_male_alert_target_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/headsup01.wav")	
} )

sound.Add( {
	name = "nixbot_male_alert_target_distant_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/overthere01.wav")	
} )

sound.Add( {
	name = "nixbot_male_alert_target_distant_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/overthere02.wav")	
} )

sound.Add( {
	name = "nixbot_male_onkill_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/gotone01.wav")	
} )

sound.Add( {
	name = "nixbot_male_onkill_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/gotone02.wav")	
} )

sound.Add( {
	name = "nixbot_male_onkill_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/nice01.wav")	
} )

sound.Add( {
	name = "nixbot_male_avoid_player_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/excuseme01.wav")	
} )

sound.Add( {
	name = "nixbot_male_avoid_player_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/excuseme02.wav")	
} )

sound.Add( {
	name = "nixbot_male_avoid_player_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/outofyourway02.wav")	
} )

sound.Add( {
	name = "nixbot_male_avoid_player_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/pardonme01.wav")	
} )

sound.Add( {
	name = "nixbot_male_avoid_player_05",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/pardonme02.wav")	
} )

sound.Add( {
	name = "nixbot_male_boast_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/question01.wav")	
} )


sound.Add( {
	name = "nixbot_male_boast_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/question02.wav")	
} )

sound.Add( {
	name = "nixbot_male_boast_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/question30.wav")	
} )

sound.Add( {
	name = "nixbot_male_boast_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level =8595,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/question29.wav")	
} )

sound.Add( {
	name = "nixbot_male_boast_05",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/question25.wav")	
} )

sound.Add( {
	name = "nixbot_male_boast_06",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/question20.wav")	
} )

sound.Add( {
	name = "nixbot_male_boast_07",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/question18.wav")	
} )

sound.Add( {
	name = "nixbot_male_boast_08",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/question09.wav")	
} )

sound.Add( {
	name = "nixbot_male_boast_09",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/question14.wav")	
} )

sound.Add( {
	name = "nixbot_male_greet_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/hi01.wav")	
} )

sound.Add( {
	name = "nixbot_male_greet_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/hi02.wav")	
} )

sound.Add( {
	name = "nixbot_male_foe_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/notthemanithought01.wav")	
} )

sound.Add( {
	name = "nixbot_male_foe_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/male01/vquestion01.wav")	
} )

sound.Add( {
	name = "nixbot_male_reload_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 93, 97 },
	sound = Sound("vo/npc/male01/gottareload01.wav")	
} )

sound.Add( {
	name = "nixbot_male_reload_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 93, 97 },
	sound = Sound("vo/npc/male01/coverwhilereload02.wav")	
} )

sound.Add( {
	name = "nixbot_male_plybumpbot_01",
	channel = CHAN_VOICE,
	volume = 1,
	level = 85,
	pitch = { 90, 94 },
	sound = Sound("vo/npc/male01/watchwhat.wav")	
} )


sound.Add( {
	name = "nixbot_male_hurt_06",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/male01/pain06.wav")
} )