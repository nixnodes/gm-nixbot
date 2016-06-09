AddCSLuaFile()

ENT.DefaultSoundsFemale = {
	Level = 72,
	PitchOffset = 0,
	Hurt = {
		"nixbot_female_hurt_01",
		"nixbot_female_hurt_02",
		"nixbot_female_hurt_03",
		"nixbot_female_hurt_04",
		"nixbot_female_hurt_05",
		"nixbot_female_hurt_06",
		"nixbot_female_hurt_07",
		"nixbot_female_hurt_08",
		"nixbot_female_hurt_09"
	},
	AlertDanger = {
		"nixbot_female_alert_danger_01",
		"nixbot_female_alert_danger_02"
	},
	AlertTarget = {
		"nixbot_female_alert_target_01",
		"nixbot_female_alert_target_02"
	},
	AlertTargetDistant = {
		"nixbot_female_alert_target_distant_01",
		"nixbot_female_alert_target_distant_02"
	},
	FollowIdle = {
		"nixbot_female_follow_idle_01",
		"nixbot_female_follow_idle_02",
		"nixbot_female_follow_idle_03",
		"nixbot_female_follow_idle_04"
	},
	FollowConfirm = {
		"nixbot_female_follow_confirm_01",
		"nixbot_female_follow_confirm_02",
		"nixbot_female_follow_confirm_03"
	},
	OnKill = {
		"nixbot_female_onkill_01",
		"nixbot_female_onkill_02",
		"nixbot_female_onkill_03"
	},
	PlayerAvoid = {
		"nixbot_female_avoid_player_01",
		"nixbot_female_avoid_player_02",
		"nixbot_female_avoid_player_03",
		"nixbot_female_avoid_player_04",
		"nixbot_female_avoid_player_05"
	},
	Boast = {
		"nixbot_female_boast_01",
		"nixbot_female_boast_02",
		"nixbot_female_boast_03",
		"nixbot_female_boast_04",
		"nixbot_female_boast_05",
		"nixbot_female_boast_06",
		"nixbot_female_boast_07",
		"nixbot_female_boast_08",
		"nixbot_female_boast_09"
	}, 
	GreetPlayerFriend = {
		"nixbot_female_greet_01",
		"nixbot_female_greet_02"
	},
	GreetPlayerFoe = {
		"nixbot_female_foe_01",
		"nixbot_female_foe_02"
	},
	ReloadNormal = {
		"nixbot_female_reload_01"
	},
	ReloadCover = {
		"nixbot_female_reload_02"
	},
	PlayerBumpBot = {
		"nixbot_female_plybumpbot_01"
	},
	OnDie = {
		"nixbot_female_die_01",
		"nixbot_female_die_02"
	},
	HealPlayer = {
   "nixbot_female_health_01",
   "nixbot_female_health_02",
   "nixbot_female_health_03",
   "nixbot_female_health_04",
   "nixbot_female_health_05",
   "nixbot_female_health_06"
  }
}

sound.Add( {
	name = "nixbot_female_die_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/ow01.wav")	
} )


sound.Add( {
	name = "nixbot_female_die_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/ow02.wav")	
} )


sound.Add( {
	name = "nixbot_female_hurt_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain01.wav")	
} )

sound.Add( {
	name = "nixbot_female_hurt_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain02.wav")	
} )

sound.Add( {
	name = "nixbot_female_hurt_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain03.wav")	
} )

sound.Add( {
	name = "nixbot_female_hurt_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain04.wav")	
} )

sound.Add( {
	name = "nixbot_female_hurt_05",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain05.wav")	
} )

sound.Add( {
	name = "nixbot_female_hurt_06",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain06.wav")	
} )

sound.Add( {
	name = "nixbot_female_hurt_07",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain07.wav")	
} )

sound.Add( {
	name = "nixbot_female_hurt_08",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain08.wav")	
} )

sound.Add( {
	name = "nixbot_female_hurt_09",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 75,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain09.wav")	
} )

sound.Add( {
	name = "nixbot_female_alert_danger_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/watchout.wav")	
} )

sound.Add( {
	name = "nixbot_female_alert_danger_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/getdown02.wav")	
} )

sound.Add( {
	name = "nixbot_female_follow_idle_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/getgoingsoon.wav")	
} )

sound.Add( {
	name = "nixbot_female_follow_idle_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/doingsomething.wav")	
} )

sound.Add( {
	name = "nixbot_female_follow_idle_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/question27.wav")	
} )

sound.Add( {
	name = "nixbot_female_follow_idle_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/waitingsomebody.wav")	
} )

sound.Add( {
	name = "nixbot_female_follow_confirm_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/answer13.wav")	
} )

sound.Add( {
	name = "nixbot_female_follow_confirm_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/leadtheway01.wav")	
} )

sound.Add( {
	name = "nixbot_female_follow_confirm_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/letsgo01.wav")	
} )


sound.Add( {
	name = "nixbot_female_alert_target_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/overhere01.wav")	
} )

sound.Add( {
	name = "nixbot_female_alert_target_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/headsup01.wav")	
} )

sound.Add( {
	name = "nixbot_female_alert_target_distant_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/overthere01.wav")	
} )

sound.Add( {
	name = "nixbot_female_alert_target_distant_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/overthere02.wav")	
} )

sound.Add( {
	name = "nixbot_female_onkill_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/gotone01.wav")	
} )

sound.Add( {
	name = "nixbot_female_onkill_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/gotone02.wav")	
} )

sound.Add( {
	name = "nixbot_female_onkill_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/nice01.wav")	
} )

sound.Add( {
	name = "nixbot_female_avoid_player_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/excuseme01.wav")	
} )

sound.Add( {
	name = "nixbot_female_avoid_player_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/excuseme02.wav")	
} )

sound.Add( {
	name = "nixbot_female_avoid_player_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/outofyourway02.wav")	
} )

sound.Add( {
	name = "nixbot_female_avoid_player_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/pardonme01.wav")	
} )

sound.Add( {
	name = "nixbot_female_avoid_player_05",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/pardonme02.wav")	
} )

sound.Add( {
	name = "nixbot_female_boast_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/question01.wav")	
} )


sound.Add( {
	name = "nixbot_female_boast_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/question02.wav")	
} )

sound.Add( {
	name = "nixbot_female_boast_03",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/question30.wav")	
} )

sound.Add( {
	name = "nixbot_female_boast_04",
	channel = CHAN_VOICE,
	volume = 1.0,
	level =8595,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/question29.wav")	
} )

sound.Add( {
	name = "nixbot_female_boast_05",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/question25.wav")	
} )

sound.Add( {
	name = "nixbot_female_boast_06",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/question20.wav")	
} )

sound.Add( {
	name = "nixbot_female_boast_07",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/question18.wav")	
} )

sound.Add( {
	name = "nixbot_female_boast_08",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/question09.wav")	
} )

sound.Add( {
	name = "nixbot_female_boast_09",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 85,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/question14.wav")	
} )

sound.Add( {
	name = "nixbot_female_greet_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/hi01.wav")	
} )

sound.Add( {
	name = "nixbot_female_greet_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/hi02.wav")	
} )

sound.Add( {
	name = "nixbot_female_foe_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/notthemanithought01.wav")	
} )

sound.Add( {
	name = "nixbot_female_foe_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 90, 95 },
	sound = Sound("vo/npc/female01/vquestion01.wav")	
} )

sound.Add( {
	name = "nixbot_female_reload_01",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 93, 97 },
	sound = Sound("vo/npc/female01/gottareload01.wav")	
} )

sound.Add( {
	name = "nixbot_female_reload_02",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 95,
	pitch = { 93, 97 },
	sound = Sound("vo/npc/female01/coverwhilereload02.wav")	
} )

sound.Add( {
	name = "nixbot_female_plybumpbot_01",
	channel = CHAN_VOICE,
	volume = 1,
	level = 85,
	pitch = { 90, 94 },
	sound = Sound("vo/npc/female01/watchwhat.wav")	
} )


sound.Add( {
	name = "nixbot_female_hurt_06",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 90,
	pitch = { 95, 100 },
	sound = Sound("vo/npc/female01/pain06.wav")
} )



sound.Add( {
  name = "nixbot_female_health_01",
  channel = CHAN_VOICE,
  volume = 1.0,
  level = 90,
  pitch = { 95, 100 },
  sound = Sound("vo/npc/female01/health01.wav")
} )

sound.Add( {
  name = "nixbot_female_health_02",
  channel = CHAN_VOICE,
  volume = 1.0,
  level = 90,
  pitch = { 95, 100 },
  sound = Sound("vo/npc/female01/health02.wav")
} )

sound.Add( {
  name = "nixbot_female_health_03",
  channel = CHAN_VOICE,
  volume = 1.0,
  level = 90,
  pitch = { 95, 100 },
  sound = Sound("vo/npc/female01/health03.wav")
} )

sound.Add( {
  name = "nixbot_female_health_04",
  channel = CHAN_VOICE,
  volume = 1.0,
  level = 90,
  pitch = { 95, 100 },
  sound = Sound("vo/npc/female01/health04.wav")
} )

sound.Add( {
  name = "nixbot_female_health_05",
  channel = CHAN_VOICE,
  volume = 1.0,
  level = 90,
  pitch = { 95, 100 },
  sound = Sound("vo/npc/female01/health05.wav")
} )

sound.Add( {
  name = "nixbot_female_health_06",
  channel = CHAN_VOICE,
  volume = 1.0,
  level = 90,
  pitch = { 95, 100 },
  sound = Sound("vo/npc/female01/health06.wav")
} )