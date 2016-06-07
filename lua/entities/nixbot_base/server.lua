if ( !SERVER ) then
	return
end

CreateConVar( "sbox_maxnbs", "4", bit.bor(FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE) )

NIXBOT_RELATION_FEAR = -8
NIXBOT_RELATION_ARCH_ENEMY = -6
NIXBOT_RELATION_ENEMY = -4
NIXBOT_RELATION_FOE = -2
NIXBOT_RELATION_NEUTRAL = 0
NIXBOT_RELATION_FRIEND = 2
NIXBOT_RELATION_ALLY = 4
NIXBOT_RELATION_OWNER = 8

NIXBOT_MOOD_RELAXED = 0
NIXBOT_MOOD_STIMULATED = 1
NIXBOT_MOOD_AGITATED = 2

local DEFAULT_ANIM_ACT = {
	Idle = ACT_IDLE,
	Run = ACT_RUN,
	RunChase = ACT_RUN_AIM,
	Walk = ACT_WALK,
	WalkAim = ACT_WALK_AIM,
	ShootStand = ACT_RANGE_ATTACK1
}

local DEFAULT_ANIM_SEQ = {}

local USABLE_PROPS = {
	["prop_door_rotating"] = true,
	["prop_physics"] = true,
}

hook.Add( "PlayerSpawnedNPC", "NX.policy.spawned.npc", function ( ply, ent )
	if ( ent.NixBot ) then
		ply:AddCount(ent:GetClass(), ent)
		ply:AddCount("nbs", ent)
	end
end )

local function CheckLimits(ply, class)
	if ( nil != cvars.Number( "sbox_max"..class ) && 
			ply:CheckLimit(class) == false ) then
		return false
	end
end

hook.Add( "PlayerSpawnNPC", "nixbot_spawn", function ( ply, npc_type, weapon )	
	if ( npc_type:match("^nixbot_") && 
			(CheckLimits(ply, npc_type) == false ||
			 CheckLimits(ply, "nbs") == false ) ) then
		return false
	end
end )

hook.Add( "PlayerSpawnedNPC", "NX.policy.spawned.npc", function ( ply, ent )
	ply:AddCount(ent:GetClass(), ent)
	if ( ent.NixBot ) then
		ply:AddCount("nbs", ent)
	end
end )

hook.Add( "PlayerCanPickupWeapon", "NX.m.disable_pickup", function( ply, wep )
	if ( wep.CanPickup == false ) then return false end
end )

hook.Add("EntityTakeDamage", "nixbot_skill_gain", function(target, dmg)
	local attacker = dmg:GetAttacker()	
		
	if ( !IsValid(attacker) || attacker == game.GetWorld() ) then
		return
	end
		
	if ( attacker.NixBot ) then		
	
		if ( target.NixBot ) then
			if ( attacker:GetRelationship(target) >= NIXBOT_RELATION_ALLY ) then
				return true
			end
		end
	
		attacker:SetAccuracy( math.Clamp(attacker:GetAccuracy() + 
								((0.20 * dmg:GetDamage()) * ((1/((attacker:GetAccuracy()+1)^40)^0.8) ) ) , 0, 0.94) )
	end
	
	if ( target.NixBot ) then
		--if ( attacker != target:CPPIGetOwner() ) then
		target:SetRelationship(attacker, math.Clamp(target:GetRelationship(attacker) - (dmg:GetDamage() / 8), NIXBOT_RELATION_ARCH_ENEMY, NIXBOT_RELATION_OWNER ))
		
		--print ((1 - target:Health() / target:GetMaxHealth() ) ,  target:GetStatsBravery() ,  target:GetMaxHealth(), target:Health() )
		
		if ( (1 - target:Health() / target:GetMaxHealth() )  > target:GetStatsBravery() ) then
			
			target:AssignTask(target.Tasks, function(s) 
				target:PlaySequenceAndWaitE( "fear_reaction" )
				return true
			end)
			target:SetInterrupt()
		end
		
		--end
	end
	
	if ( target:IsPlayer() || target:IsNPC() ) then
		attacker.nixbot_last_attack_info = {
			time = RealTime(),
			target = target
		}
	end
	
end)

local function ValidateEnemyDefault(self, enemy)
	if ( self:GetRelationship(enemy) > NIXBOT_RELATION_ENEMY ) then
		return false		
	elseif ( self:GetRangeTo( enemy:GetPos() ) > self.Stats.AbsoluteLoseTargetRange ) then
		return false
	elseif ( enemy:IsPlayer() and !enemy:Alive() ) then
		return false
	elseif ( enemy:IsNPC() and ( enemy:Health() < 1 ) ) then
		return false
	end	

	return true
end

function ENT:Initialize()
		
	if ( self.Options.Stats.Female == true ) then
		self.Sounds = setmetatable({}, {__index=setmetatable(table.Copy(self.Options.Sounds), {__index=self.DefaultSoundsFemale })})
	else
		self.Sounds = setmetatable({}, {__index=setmetatable(table.Copy(self.Options.Sounds), {__index=self.DefaultSoundsMale })})
	end
		
	self:SetModel( self.Model )
	
	self:AddFlags( bit.bor( FL_NPC, FL_AIMTARGET, FL_OBJECT, FL_SWIM, FL_FLY, FL_STEPMOVEMENT )  )
	
	self:SetPPDensity(400)

	self.IsAlive = true
	self.LastUsed = 0
	self.stuck_counter = 0
	self.ProtectDispThreshold = NIXBOT_RELATION_NEUTRAL
	self.Kills = 0
	self.PrevKills = 0
	self.Mood = 0
	self.EvadeProximityDistance = 0
	self.EnemyDetectTime = 0
	
	self:SetBusyTimeout(0)
	
	self.Tasks = {}
	self.TimedCombatTasks = {}
	self.TimedMovementTasks = {}
	self.TimedTasks = {}
	self.TimedTasksWander = {}
	self.PatrolPoints = {}
	self.Relationships = {}
	self.BurstRC = {}
	self.MovTypeProc = {}
	self.dump = {}
	self.dump.Ammo = {}
	self.dump.Weapon = {}
	self.dump._allowed = {
		Weapon = true,
		Entity = {
			["item_healthkit"] = true
		}
	}
	
	self.SELastPlayed = {}
	self.CSStart = 0
	self.CSDur = 0
	self.ActivityMoodTranslateAI = {}
	self.Stats = table.Copy(self.Options.Stats)
	
	self:Give(self.Options.Weapon.Class, "Weapon")
	
	self.AnimSeq = DEFAULT_ANIM_SEQ
	
	

		
	self.ValidateEnemy = ValidateEnemyDefault
	self.LastBurst = 0
	
	local AAAvg = (self.Options.Stats.Athletics + self.Options.Stats.Agility / 8 ) 
	
	self.Stats.AwarenessInv = math.Clamp(self.Options.Stats.Awareness, 0, 1)
	self.Stats.Awareness = math.Clamp(1 - self.Options.Stats.Awareness, 0, 1)
	 
	self.Stats.RunSpeed = self.Options.Stats.Athletics * 650
	self.Stats.WalkSpeed = self.Stats.RunSpeed * 0.384
	self.Stats.Accel = AAAvg * 400
	self.Stats.Decel = AAAvg * 400
	
	self.Stats.ReloadSpeed = self.Options.Stats.Athletics * 4.0
	
	self.Stats.Accuracy = self.Options.Combat.BaseAccuracy 
									* (1 + AAAvg / 4)
									
	self.Stats.CognitiveDetectRange = self.Options.Stats.Awareness * 6000
	self.Stats.VisibleDetectRange = self.Options.Stats.Awareness * 3750
	self.Stats.TargetFocusRange = self.Options.Stats.Awareness * 1500
	self.Stats.AbsoluteLoseTargetRange = self.Options.Stats.Awareness * 8000
	
	print (
		self:GetStatsAwareness(),
		self:GetAwareness(),
		self:GetStatsCogRange(),
		self:GetStatsVisRange(),
		self:GetStatsTFRange(),
		self:GetStatsRunspeed(),
		self:GetStatsWalkspeed(),
		self:GetStatsAccel()
	)
	
	self:SetMaxHealth(self.Options.Stats.Health)
	self:SetHealth(self.Options.Stats.Health)		
	self:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
	self:SetUseType(SIMPLE_USE)

	
	self:CallOnRemove( "nixbot_cleanup", function (ent)
		--[[local owner = self:CPPIGetOwner()
		if ( IsValid(owner) && owner.nixbot_refs ) then
			table.RemoveByValue(owner.nixbot_refs, self)
		end]]
		if ( IsValid(self.Weapon) ) then	
			SafeRemoveEntity(self.Weapon)	
		end
	end)
	
	
	if ( !self:SelectWeapon(self.Options.Weapon.Class) ) then		
		self:SayToOwner(self:EntIndex(), " no weapon available")
	end
	
	self.AnimAct = DEFAULT_ANIM_ACT
	
	local meta = getmetatable(self)
	
	function meta:Name()
		return "["..self:EntIndex().."] "..self:GetClass()
	end
	
	function meta:EyePos()
		return self:GetAttachment( self:LookupAttachment( "eyes" ) ).Pos
	end
		
	self:SetPatrol(true)	
	self:EnableItemPickup(true)
	
	self.Hooks = NIXBOT.hook:CreateContext()
	
end

function ENT:RegisterHook(...)
	self.Hooks:RegisterHook(...)
end

function ENT:UnregisterHook(...)
	self.Hooks:UnregisterHook(...)
end

function ENT:RunHook(...)
	self.Hooks:RunHook(...)
end

function ENT:PlaySound(event, cooldown)
		
	if ( RealTime() - self.CSStart < self.CSDur ) then
		return false
	end
			
	if ( cooldown ) then	
		local lp = self.SELastPlayed[event]
		
		if ( lp && os.time() - lp < cooldown ) then
			return false
		end
		
		self.SELastPlayed[event] = os.time()
	end
	
	local evs = self.Sounds[event]
	
	if ( !evs || !#evs ) then return true end
	
	local s = evs[math.random(1,#evs)]
	self.CSDur = 0.75
	self.CSStart = RealTime()
	
	local sp = sound.GetProperties(s)

			
	self:EmitSound(sp.sound, sp.level, 
						math.random(sp.pitch[1] + self.Sounds.PitchOffset, 
						sp.pitch[2] + self.Sounds.PitchOffset), 
						sp.volume, sp.channel )
	
	return true
end

function ENT:SayToPlayer(ply, ...)
	if ( !IsValid(ply) || !ply:IsPlayer() || !NX || !NX.chat ) then
		return
	end
	
	if ( NX && NX.chat ) then
		NX.chat:Print(ply, ...)
	end
end

function ENT:SayToOwner(...)
	self:SayToPlayer(self:CPPIGetOwner(), ...)
end

function ENT:GetRank()
	local stats = self.Stats
	return (self.Stats.Accuracy + 
			stats.Awareness + 
			self.Options.Stats.Athletics + 
			self.Options.Stats.Agility) / 4
end

function ENT:SetAccuracy(v)
	self.Stats.Accuracy = v
end

function ENT:GetAccuracy()
	return self.Stats.Accuracy
end

function ENT:GetAwareness()
	return self.Stats.AwarenessInv
end

function ENT:GetStatsAwareness()
	return self.Stats.Awareness
end

function ENT:GetStatsCommRange()
	return self.Options.Stats.CommRange
end

function ENT:GetStatsCogRange()
	return self.Stats.CognitiveDetectRange
end

function ENT:GetStatsReloadSpeed()
	return self.Stats.ReloadSpeed
end

function ENT:GetStatsVisRange()
	return self.Stats.VisibleDetectRange
end

function ENT:GetStatsTFRange()
	return self.Stats.TargetFocusRange
end

function ENT:GetStatsRunspeed()
	return self.Stats.RunSpeed
end 

function ENT:GetStatsWalkspeed()
	return self.Stats.WalkSpeed
end 

function ENT:GetStatsAccel()
	return self.Stats.Accel
end 

function ENT:GetStatsBravery()
	return self.Options.Stats.Bravery
end 

function ENT:GetAnimAct(act)	
	local activity = self.AnimAct[act]	
	local ml = self:TranslateActivityMood(activity) 
	
	ml = ml && ml + self.Mood || activity
		
	if ( !IsValid(self.Weapon) ) then
		return ml
	end
	
	local tl = self.Weapon:TranslateActivity(ml) 

	if ( tl != -1 ) then
		return tl
	else
		return ml
	end
end

function ENT:GetMood()
	return self.Mood
end

function ENT:SetMood(m)
	self.Mood = m
end

function ENT:GetAnimSeq(seq)
	return self.AnimSeq[seq]
end

function ENT:GetRandAnimHit()
	return self.Options.AnimHit[math.random(1, #self.Options.AnimHit)]
end

function ENT:GetAnimHit(i)
	return self.Options.AnimHit[i]
end

function ENT:GetViewModel()
	return self
end

function ENT:SetFOV(a,b)

end

function ENT:DoAnimationEvent(id)

end

function ENT:HasWeapon(class)
	if ( self.dump.Weapon[class] ) then
		return true
	end	
	return false
end

function ENT:SelectWeapon(class)

	if ( !self:HasWeapon(class) ) then
		return false
	end
	
	local pweap = self:GetActiveWeapon()
	
	if ( IsValid(pweap) && pweap:GetClass() == class ) then
		return false
	end
	
	local weap = ents.Create(class)
	
	if ( !IsValid(weap) ) then
		return false
	end
		
	local res = self:SetActiveWeapon(weap)
	
	if ( res ) then			
		if ( IsValid(pweap) ) then
			SafeRemoveEntity(pweap)
		end
	end

	return res
end

function ENT:StripWeapon(class)	
	local act = self:GetActiveWeapon()	
	
	if ( IsValid(act) ) then
		SafeRemoveEntity(act)
	end
	
	self:SetActiveWeapon(nil)
	self.dump.Weapon[class] = nil	
end

function ENT:SetActiveWeapon(weap)
	
	if ( IsValid(weap) ) then
		self.Weapon = weap
		local ret = self:EquipWeapon(weap)
		if ( !ret ) then
			self.Weapon = nil
		end
		return ret
	end
	
	return false
end

function ENT:SetupActivityMoodTranslateAI(ht)
	self.ActivityMoodTranslateAI = {}

	if ( ht == "ar2") then
		self.ActivityMoodTranslateAI [ ACT_IDLE ] = ACT_IDLE_RELAXED		
		self.ActivityMoodTranslateAI [ ACT_WALK  ] = ACT_WALK_RELAXED 
		self.ActivityMoodTranslateAI [ ACT_RUN ] = ACT_RUN_RELAXED  		
	end
end


function ENT:TranslateActivityMood( act )		
	return self.ActivityMoodTranslateAI[ act ]
end

function ENT:EquipWeapon(weap)		

	local atid = self:LookupAttachment(self.Options.Weapon.Attachement)
	local at = self:GetAttachment(atid)
	
	self.Weapon_AT = atid
	weap.CanPickup = false

	weap:Spawn()
		
	weap:SetCollisionGroup(COLLISION_GROUP_WORLD)
	weap:SetSolid(SOLID_NONE ) 
	weap:SetMoveType( MOVETYPE_NONE )
	
	local ht = weap:GetHoldType()

	if ( self.Options.Weapon.BannedHoldtypes && 
			self.Options.Weapon.BannedHoldtypes[ht] ) then
		return false
	end
		
	weap:SetupWeaponHoldTypeForAI(ht)	
	self:SetupActivityMoodTranslateAI(ht)
	
	if ( ht == "ar2" ) then
		self.AimAngleOffset = Angle(0,0,0)		
		self.AnimSeq.Reload = "reload_smg1"	
		
	else
		self.AimAngleOffset = Angle(0,0,0)
		self.AnimSeq.Reload = "reloadpistol"
	end
	
	function weap:TranslateActivity( act )
		if ( self.ActivityTranslateAI[ act ] ) then
			return self.ActivityTranslateAI[ act ]
		end
		return -1
	end
	
	weap:SetOwner(self)		
	weap:SetPos(at.Pos ) 

	weap:SetParent(self)
	weap:Fire("setparentattachment", self.Options.Weapon.Attachement) 
	weap:AddEffects(EF_BONEMERGE) 
	weap:AddEffects(EF_BONEMERGE_FASTCULL)
			
	weap:OwnerChanged()		
	weap:Deploy()
	
		
	if ( !weap.Primary ) then
		weap.Primary = {}
	end
	
	if ( weap.Primary.Automatic && weap:GetMaxClip1() > 10 ) then
		self.BurstRC = {2,4}
	else
		self.BurstRC = {1,1}
	end
	
	if ( weap.GetWeaponType && 
		weap:GetWeaponType() == CS_WEAPONTYPE_SNIPER_RIFLE ) then
		function weap:IsScoped()
			return true
		end	
	elseif ( !weap.IsScoped ) then
		function weap:IsScoped()
			return false
		end	
	end
		
	return true
end

function ENT:DecreaseEnemyTensionsStep()

	for _,v in pairs(self.Relationships) do
		if ( IsValid(v.ent) ) then	
			if ( v.persist == true ) then
				continue
			end
			if ( v.ent != self:GetEnemy() &&
				v.disp < NIXBOT_RELATION_NEUTRAL ) then
				v.disp = math.Clamp(v.disp + (1 / ((-1*v.disp)^2)) * 0.4, v.disp, NIXBOT_RELATION_NEUTRAL)
				--self:SayToOwner(self:EntIndex(), " relations toward ", v.ent, " :", v.disp)
			end			
		else
			if ( isstring(_) ) then
				self.Relationships[_] = nil
			else
				table.remove(self.Relationships, _)
			end
		end
	end
end


function ENT:SetRelationship(target, disposition, priority, persist)
	if ( !IsValid(target) ) then
		return false
	end
		
	if ( target:IsPlayer() ) then
	
		local orel = self.Relationships[target:SteamID()] || {}
			
		self.Relationships[target:SteamID()] = {
			ent = target,
			disp = disposition && math.Clamp(disposition, NIXBOT_RELATION_FEAR, NIXBOT_RELATION_OWNER) || orel.disp,
			prio = priority || orel.prio,
			persist = persist
		}
	elseif ( target:IsNPC() ) then
		
		for _, v in ipairs(self.Relationships) do
			if ( v.ent == target || !IsValid(v.ent) ) then
				table.remove(self.Relationships, _)
			end
		end
		table.insert(self.Relationships, {
			ent = target,
			disp = math.Clamp(disposition || NIXBOT_RELATION_NEUTRAL, NIXBOT_RELATION_FEAR, NIXBOT_RELATION_OWNER),
			prio = priority || 0,
			persist = persist
		})
	else
		return false
	end
	
	return true
end

local DEFAULT_REL_TABLE = {
	disp = NIXBOT_RELATION_NEUTRAL,
	prio = 0
}

function ENT:GetRelationshipTable(ent)
	if ( !IsValid(ent) ) then
		return DEFAULT_REL_TABLE
	end
	
	if ( ent:IsNPC() ) then
		
		for _, v in ipairs(self.Relationships) do
			if ( v.ent == ent ) then
				return v
			end
		end
		
		if ( ent.NixBot && self.NixBot ) then
			if ( self:CPPIGetOwner() == ent:CPPIGetOwner() ) then
				local t = table.Copy(DEFAULT_REL_TABLE)
				t.disp = NIXBOT_RELATION_ALLY
				t.prio = 75
				return t 
			end
		elseif ( IsEnemyEntityName(ent:GetClass()) || 
					ent:GetClass() == "npc_strider" ) then
			local t = table.Copy(DEFAULT_REL_TABLE)
			t.disp = NIXBOT_RELATION_ENEMY
			return t 
		end
	
		return DEFAULT_REL_TABLE
	end
	
	local classrel = self.Relationships[ent:GetClass()]	
	
	if ( classrel) then
		return classrel
	end
	
	if ( !ent:IsPlayer() ) then
		return DEFAULT_REL_TABLE
	end
	
	local entrel = self.Relationships[ent:SteamID()]
		
	if ( entrel ) then
		return entrel
	end
	
	return DEFAULT_REL_TABLE
end

function ENT:GetRelationship(ent)
	return self:GetRelationshipTable(ent).disp
end

function ENT:ComputePath( path, loc, f )
	path:Compute(self, loc , function( area, fromArea, ladder, elevator, length )
		if ( f ) then
			local r = f (self, area, fromArea, ladder, elevator, length)
			if ( r == -1 ) then
				return r
			end
		end
		
		if ( area:IsUnderwater() ) then
			return -1
		end

		if ( !IsValid( fromArea ) ) then

			// first area in path, no cost
			return 0

		else

			if ( !self.loco:IsAreaTraversable( area ) ) then
				// our locomotor says we can't move here
				return -1
			end
			
			// compute distance traveled along path so far
			local dist = 0

			if ( IsValid( ladder ) ) then
				dist = ladder:GetLength()
			elseif ( length > 0 ) then
				// optimization to avoid recomputing length
				dist = length
			else
				dist = ( area:GetCenter() - fromArea:GetCenter() ):GetLength()
			end

			local cost = dist + fromArea:GetCostSoFar()

			// check height change
			local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
			if ( deltaZ >= self.loco:GetStepHeight() ) then
				if ( deltaZ >= self.loco:GetMaxJumpHeight() ) then
					// too high to reach
					return -1
				end

				// jumping is slower than flat ground
				local jumpPenalty = 5
				cost = cost + jumpPenalty * dist
			elseif ( deltaZ < -self.loco:GetDeathDropHeight() ) then
				// too far to drop
				return -1
			end

			return cost
		end
	end)
end

function ENT:HasTask(tab)
	if ( table.Count(tab) > 0 ) then	
		return true
	else
		return false
	end	
end

function RollDice(chance)
	return math.Rand(0, 100) <= chance
end

function ENT:AssignTask(tab, func, args)
	table.insert(tab, {func = func, data = args || {} })
end

function ENT:AssignTimedTask(id, tab, i, args)
	tab[id] = {func = self[id], data = args || {}, interval = i || 0, last = 0}
end

function ENT:AssignTimedTaskH(id, tab, fn, i, args)
	tab[id] = {func = fn, data = args || {}, interval = i || 0, last = 0}
end

function ENT:RemoveTimedTask(id, tab)
	tab[id] = nil
end

function ENT:ProcessTimedTasks(tab, path)
	local c
	for _,t in pairs(tab) do		
		if ( os.time() - t.last < t.interval  ) then
			continue 
		end
						
		c = true
		self.path = path
		local ret = t.func(self, unpack(t.data))
		
		if ( ret == false ) then
			if ( isstring(_) ) then
				tab[_] = nil
			else
				table.remove(tab, _)	
			end
		else
			t.last = os.time()
		end
	end
	return c || false
end


function ENT:ProcessTask(tab)

	local t = tab[1]
		

	local ret, r2 = t.func(self, unpack(t.data))
	
	
	if ( ret == true ) then
		table.remove(tab, 1)	
	end
	
	return ret
end

local function UseAllowed(ent)
	if ( ( ent.nixbot_last_used && os.time() - ent.nixbot_last_used < 10 ) ||
			!USABLE_PROPS[ent:GetClass()]
			) then
		return false
	else
		return true
	end
end

function ENT:OnContact( ent )
	if ( !IsValid(ent) || ent:IsWorld() ) then
		return
	end
	
	if ( ent:IsPlayer() && ent:GetVelocity():Length2DSqr() > 170000 ) then
		if ( self:PlaySound("PlayerBumpBot", 4) ) then
			self:StartActivityE(self.CurrentActivity, 0, 0)
			local dur = self:PlaySequence(self:GetAnimHit(1) )
			self:SetBusyTimeout(dur)
		end
	end
		
	if ( UseAllowed(ent) ) then
		ent.nixbot_last_used = os.time()	
		ent:Use(self, self, USE_TOGGLE, 0)
		self:SayToOwner(self:EntIndex(), " contact, using", ent)
	elseif ( self:CheckValidPickup(ent) ) then
		self:PickupItem(ent)
	end
end

function ENT:Use( activator, caller, type, value )

	if ( RealTime() - self.LastUsed < 1 ) then
		return
	end
	
	
	
	self.LastUsed = RealTime()
	
	if ( !(caller:IsPlayer() && type == 1 && value == 0) ) then			
		return
	end
	
	self.LastUser = caller
	self:RunHook("Used", caller)
	
	if ( self.FollowTarget != caller ) then
		
		if ( self:SetFollowTarget(caller) ) then
	
			self:SetInterrupt()
			self:PlaySound("FollowConfirm")
			self:SayToPlayer(caller, self:Name(), ": Following you, sir.")
		end
	else
		self:SetFollowTarget(nil)
		self:SayToPlayer(caller, self:Name(), ": No longer following")
	end
end

function ENT:OnOtherKilled(victim, info)
	if (info:GetAttacker() != self ) then
		return
	end

	self.Kills = self.Kills + 1
	
	if ( RollDice(85) ) then
		self:PlaySound("OnKill")
	end
	
	self:RunHook("OnOtherKilled", victim)	
end

function ENT:SetEnemy( ent )
	self.Enemy = ent
end
function ENT:GetEnemy()
	return self.Enemy
end

function ENT:SetEyeAngles()
	
end

function ENT:Interrupt(n)	
	
	if ( n ) then
		if ( self["Interrupt"..n] == true) then
			--self["Interrupt"..n]  = false
			return true
		end
	else
		if ( self.InterruptF == true ) then
			--self.InterruptF = false		
			return true
		end	
	end
	
	return false
end

function ENT:ClearInterrupt(n)
	if ( n ) then
		self["Interrupt"..n]  = false
	else
		self.InterruptF = false
	end	
end

function ENT:InterruptClr(n)	
	local ret = self:Interrupt(n)
	if ( ret ) then
		self:ClearInterrupt(n)
	end
	return ret
end

function ENT:SetInterrupt(n)
	if ( n ) then
		self["Interrupt"..n]  = true
	else
		self.InterruptF = true
	end	
end

function ENT:HaveEnemy()
	
	if ( IsValid( self:GetEnemy() ) ) then
		
		if ( self:ValidateEnemy(self:GetEnemy()) == false ) then
	
			return self:DetectEnemy()
		end
		return true
	else
		-- The enemy isn't valid so lets look for a new one
		return self:DetectEnemy()
	end
end

function ENT:IsEntityVisible(entity)

	local tr = util.TraceLine( {
		start = self:EyePos(),
		endpos = entity:GetPos() + entity:OBBCenter() ,
		filter = {self, self.Weapon}
	} )
	
	if ( tr.Entity == entity ) then		
		
		return true
	else
		return false
	end		
end

function ENT:CalculateCognitionScore(v)
		
	local shm = RealTime() - v:GetNWFloat("LastShootTime") < 0.45 && 1 || 0
	local dist = self:GetPos():Distance(v:GetPos())
	local vispen = self:Visible(v) == false && 3 || 1
	local res = ((1 / dist) * (1 + (shm * (1500 / vispen)) + 
				(v:GetGroundSpeedVelocity():Length() / vispen))) *
				(( (v:OBBMaxs() - v:OBBMins()):LengthSqr() / 5625)^4)
	return res
end


function ENT:IsEntityValidTarget(v)
	-- v != self:CPPIGetOwner()
	-- && IsValid(v:GetPhysicsObject())
	return self != v &&
				((v:IsPlayer() && v:Alive()) || v:IsNPC() || (v.NixBot && v:Alive())) && 
				v:Health() > 0 
end

function ENT:ScanEntAttackingFriend(v)

	if ( !v.nixbot_last_attack_info ) then
		return 
	end
	
	local target = v.nixbot_last_attack_info.target
	
	if ( IsValid(target) && target != self &&
		RealTime() - v.nixbot_last_attack_info.time < 1.2 ) then			
		
		local trel = self:GetRelationship(target)
		local arel = self:GetRelationship(v)
		
		--print(self, target, v, trel, arel )
		
		if ( trel >= self.ProtectDispThreshold && trel > arel ) then
			self:SetRelationship(v, NIXBOT_RELATION_ARCH_ENEMY, 95)	
			self:PlaySound("AlertDanger", 120)
			if ( v.NixBot ) then
				v:SetRelationship(self, NIXBOT_RELATION_ENEMY + 1, 95)		
			end
		end
		
		
	end

	v.nixbot_last_attack_info = nil
	
end


function ENT:FindInCone(cone_origin, cone_direction, cone_radius, cone_angle)
	local entities = ents.FindInSphere(cone_origin, cone_radius)
	local result = {}

	cone_direction:Normalize()

	local cos = math.cos(cone_angle)

	for _, entity in pairs(entities) do
		if ( entity == self || entity:IsWorld() ) then
			continue
		end
		local pos = entity:GetPos()
		local dir = pos - cone_origin
		dir:Normalize()
		local dot = cone_direction:Dot(dir)

		if (dot > cos) then
			table.insert(result, entity)
		end
	end

	return result, entities
end


function ENT:IsFollowing()
	return self.FollowTarget && true || false
end

function ENT:DetectEnemyInView()
	local _ents = self:FindInCone( self:EyePos(), self:EyeAngles():Forward(), self:GetStatsVisRange(), math.pi / 2.25)

	local cres = {
		distance = 0,
		score = 0,
		ent = nil,		
		ally_disp = 0,
		ent_ally = nil
	}
		
	for k, v in ipairs( _ents ) do
		if ( !IsValid(v) || !self:Visible(v) ||
		      v == self:GetEnemy() ) then
			continue
		end
		
		if ( !self:IsEntityValidTarget(v) ) then			
			continue
		end
		
		self:ScanEntAttackingFriend(v)
		
		local distance = self:GetPos():Distance(v:GetPos())
		local disp = self:GetRelationship(v)
		
		if ( disp <= NIXBOT_RELATION_FOE ) then
			self.foe_in_view = true
		elseif (disp > NIXBOT_RELATION_ENEMY ) then	
			if ( v:IsPlayer() && distance < 500 && 
					disp > cres.ally_disp ) then
				cres.ent_ally = v
				cres.ally_disp = disp
			end
			continue
		end		
				
		local score = -(disp - math.abs(disp) ) * (distance) 
				
		if ( score > cres.score) then
			cres.score = score
			cres.ent = v
		end
		
	end
			
	if ( cres.ent_ally && !self:IsFollowing() ) then		
		if ( cres.ally_disp >= NIXBOT_RELATION_NEUTRAL ) then
			self:PlaySound("GreetPlayerFriend", 30)			
		elseif ( cres.ally_disp <= NIXBOT_RELATION_FOE ) then
			self:PlaySound("GreetPlayerFoe", 30)
		end
	end
		
	self.ally_in_view = cres.ent_ally	
	
	return cres.ent
end

function ENT:DetectEnemyCog()
	local _ents = ents.FindInSphere( self:EyePos(), self:GetStatsCogRange())
	
	local cres = {
		score = 0,
		ent = nil, 
		disp = 0,
		distance = 0
	}

	for k, v in ipairs( _ents ) do
		if ( !IsValid(v) || v == self:GetEnemy() ) then
			continue
		end
		
		if ( !self:IsEntityValidTarget(v) ) then
			continue
		end
		
		self:ScanEntAttackingFriend(v)
		local disp = self:GetRelationship(v)
		
		if ( disp <= NIXBOT_RELATION_FOE ) then
			self.foe_in_view = true
		elseif ( disp > NIXBOT_RELATION_ENEMY ) then
			continue
		end
			
		local cogscore = self:CalculateCognitionScore(v)
			
		if ( cogscore < self:GetStatsAwareness() ) then
			continue
		end
		
		local distance = self:GetPos():Distance(v:GetPos())
			
		local score = -(disp - math.abs(disp) ) * (cogscore/distance) 
		
		
		if ( score > cres.score ) then
			cres.ent = v
			cres.score = score
		end		
		
	end
	
	return cres.ent
end

function ENT:EnemyDetectAge()
	return RealTime() - self.EnemyDetectTime
end

function ENT:DetectEnemy()
	self.foe_in_view = nil
	
	local res = self:DetectEnemyInView()	
	
	if ( !IsValid(res) ) then
		res = self:DetectEnemyCog()	
	end
	
	if ( !IsValid(res) ) then
		if ( self.foe_in_view == true ) then
			self:SetMood(NIXBOT_MOOD_STIMULATED)
		else
			self:SetMood(NIXBOT_MOOD_RELAXED)
		end
		return false
	end
		
	self:SetEnemy(res)
	self.EnemyDetectTime = RealTime()
	
	--self:RunHook("DetectEnemy")		
	
	return true
end


function ENT:WaitAlert(t)
	local start = os.time()
	while ( !self:HaveEnemy() && !self:HasTask(self.Tasks) && !self:Interrupt() && os.time() - start < t ) do	
		self:LookIdle()
		coroutine.yield()
	end
end

function ENT:SetBusyTimeout(n)
	self.busy_timeout = RealTime() + n
end

function ENT:GetBusyTimeout()
	return self.busy_timeout
end

function ENT:OnInjured(dmginfo)
	if ( self.l_inj_event && RealTime() - self.l_inj_event < 1 ) then
		return
	end
	
	self.l_inj_event = RealTime()
	
	local seq = self:GetRandAnimHit()
		
	local len = self:SetSequence( seq )
	self:SetBusyTimeout(len)
	
	local speed = 1.25
	
	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( speed )
		
	self.CurrentActivity = nil
	
	timer.Create("nb_inj", len / speed, 1, function()
		if ( self.CurrentActivity != nil || !IsValid(self) ) then
			return
		end

		self:StartActivityE( self:GetAnimAct("Idle"), 0, 0 )	

	end)
	
	if (  self:Health() - dmginfo:GetDamage() > 0 ) then
		local dh = self:GetMaxHealth() - self:Health() 
		
		if ( dh >= 25 ) then			
			local use = self:PopItem("Entity", "item_healthkit", math.Round(dh / 25) ) 
			if ( use ) then
				timer.Simple(1 - self.Options.Stats.Agility, function()
					if ( IsValid(self) ) then
						self:SetHealth(math.Clamp(self:Health() + use*25,0,self:GetMaxHealth()) )
					end
				end)
			end
		end
		self:PlaySound("Hurt")		
	end
		
end

function ENT:Alive()
	return self.IsAlive
end

function ENT:OnKilled(dmginfo)
	hook.Call( "OnNPCKilled", GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor() )

	self:RunHook("OnKilled")	
	self:PlaySound("OnDie")
	self:BecomeRagdoll( dmginfo )
	
	self.IsAlive = false
	
	if ( IsValid(self.Weapon) ) then			
		SafeRemoveEntity(self.Weapon)	
	end
	
end

function ENT:AlertGotoWrapper(target, vec, locoff, option)
	if ( !IsValid(target) || !self:ValidateEnemy(target) ) then
		return true
	end
	
	self:Goto(vec + locoff, option)
	
	return true
end

function ENT:AlertNeighbors(target, vec)

	if ( !IsValid(target) || 
		!self:ValidateEnemy(target) || 
		!self:Visible(target) ||
		target == game.GetWorld()) then
		return true
	end
	
	vec = vec || target:GetPos()
	
	--print(self:EntIndex(), "alert", target)
	
	local neighs = ents.FindInSphere(self:GetPos(), self:GetStatsCommRange())
	local hit
	
	for _,v in pairs(neighs) do
		
		if (v != self && v.NixBot == true && 
			!v:HaveEnemy() && v:IsEntityValidTarget(target) && 
			v:GetRelationship(target) < v:GetRelationship(self) && 
			v:GetRelationship(target) > NIXBOT_RELATION_ENEMY - 1 ) then
			--v:SetEnemy(target)

			v:SetRelationship(target, NIXBOT_RELATION_ENEMY - 1, 25)
			v:SetMood(NIXBOT_MOOD_STIMULATED)
			
			v:AssignTask(v.Tasks, v.AlertNeighbors, {target, vec} )
			v:AssignTask(v.Tasks, v.AlertGotoWrapper, 
						{target, vec, Vector( 0,0,0 ) , 
						{speed = v:GetStatsRunspeed(), accel = v:GetStatsAccel(), 
						activity = v:GetAnimAct("RunChase"), noint = true, notask = true} })
			
			v:SetInterrupt()
			
			hit = true
		end
	end
	
	if ( hit ) then
		if ( self:GetPos():Distance(target:GetPos()) < 400 ) then
			self:PlaySound("AlertTarget", 120)
		else
			self:PlaySound("AlertTargetDistant", 150)
		end
	end
	
	return true
end

function ENT:ContinuousAlertNeighbors()
	self:AlertNeighbors(self:GetEnemy())	
	return true
end


function ENT:DoReload()		
	if ( IsValid(self.Weapon) ) then
		if ( self:HaveEnemy() && RollDice(80) ) then
			if ( self.ally_in_view ) then
				self:PlaySound("ReloadCover")	
			else			
				self:PlaySound("ReloadNormal")			
			end
		end
		self:PlaySequenceAndWaitE( self:GetAnimSeq("Reload"), self:GetStatsReloadSpeed() )
		self.Weapon:SetClip1(self.Weapon:GetMaxClip1())
	end
	return true
end

function ENT:PlaySequenceAndWaitE( name, speed )
	self:PlaySequenceAndWait( name, speed )
	self.CurrentActivity = nil
end

local function ValidateNavPoint(vec)
	if ( util.IsInWorld(vec) ) then
		return true
	else
		return false
	end
end

local function DoSurfaceTrace(origin)
	return util.TraceLine( {
		start = origin,
		endpos = origin - vector_up * 200000 ,
		filter = function(ent)
			if ( ent:IsPlayer() || ent:IsNPC() || ent:IsWeapon() ) then
				return false
			else
				return true
			end
		end
	} )
end

local function GetSurfacePoint(origin)
	local tr = DoSurfaceTrace(origin)
	
	if ( !tr.HitWorld ||
		tr.StartSolid ||
		!ValidateNavPoint(tr.HitPos) ||
		#ents.FindInBox(tr.HitPos - Vector(50,50,50), tr.HitPos + Vector(50,50,50)) != 0 ) then
		return false
	end
	
	for i = 1, 25 do
		local t = DoSurfaceTrace(origin +
				Vector(math.Rand(-1,1), math.Rand(-1,1), 0) * 100 )
	
		if ( t.HitPos.z != tr.HitPos.z || 
			!t.HitWorld || t.StartSolid || 
			!ValidateNavPoint(t.HitPos) ) then
			return false
		end
	end
	
	return tr.HitPos
end

local function CheckPatrolPointDistR(self, p)
	if ( self:GetPos():Distance(p) >  self.PatrolAreaSize:Length() ) then
		return false
	end

	for _,v in pairs(self.PatrolPoints) do
		if ( p:Distance(v) < self.PatrolMinIPDistance ) then
			return false
		end
	end
	
	return true
end

function ENT:ComputeNavPoint(area_start, area_size)
	local start = os.time()
	while ( os.time() - start < 120 ) do
		
		local randpos = area_start + (
				Vector(math.Rand(0,1), math.Rand(0,1), math.Rand(0,1))
				* area_size)
		
		
		if ( !ValidateNavPoint(randpos)  ) then

			coroutine.yield()
			continue
		end
		
		local finalpos = GetSurfacePoint(randpos)
		
		if ( !finalpos  ) then

			coroutine.yield()
			continue
		end

		local path = Path( "Follow" )	
		path:SetGoalTolerance(  20 )
		path:Compute( self, finalpos )		-- Compute the path towards the enemies position
		
		if ( !path:IsValid() ) then	
			coroutine.yield()
			continue
		end
		
		
		local lseg = path:LastSegment()
		
		if ( lseg.area:IsUnderwater() || 
				!self.loco:IsAreaTraversable(lseg.area) ) then
			coroutine.yield()
			continue
		end
				
		return lseg.pos
	end
	
	self:SayToOwner(self:EntIndex(), " WARNING: ComputeNavPoint failed", area_start ,area_size)
	
	return false
end

function ENT:SetPPRebuild(v)
	
	self:SetPPDensity(v)
	
	if ( self.AssemblyInProgress == true ) then
		self:SetInterrupt("asmpp")
	end
	
	self:AssignTimedTaskH("AssemblePatrolPoints"..tostring(SysTime())..tostring(v), self.TimedTasks, function(s)
		--print(123456, v, tostring(s))
		
		s:AssemblePatrolPoints()
		
		return false
	end, 0)
end

function ENT:LoadPatrolArea()
	if ( NX && NX.zoning ) then
		local zone = NX.zoning:GetPlayerZone(self)
		if ( zone ) then
			self.PatrolArea = zone.area 
			self.PatrolAreaSize = self.PatrolArea[2] - self.PatrolArea[1] 
			self.PatrolMaxPoints = 50

			if ( self.PatrolAreaSize:Length() == 0 ) then
				self.PatrolArea = { Vector(-10000, -10000, -10000), Vector(20000,20000,20000) }
				self.PatrolAreaSize = self.PatrolArea[2] - self.PatrolArea[1] 
			end
		end
	end
end

function ENT:AssemblePatrolPoints()
	self:LoadPatrolArea()

	if ( !self.PatrolArea ) then
		return
	end	
	
	self.AssemblyInProgress = true
	
	self:SayToOwner(self:EntIndex(), " Generating patrol points.." )
	
	self.PatrolPoints = {}
	
	self.PatrolMinIPDistance = self.PatrolMinIPDistance || 400
	self.PatrolMaxPoints = self.PatrolAreaSize:Length() / self:GetPPDensity()
	
	while ( #self.PatrolPoints < self.PatrolMaxPoints ) do
		if ( self:InterruptClr("asmpp") ) then
			break
		end
		
		local pos = self:ComputeNavPoint( self.PatrolArea[1], self.PatrolAreaSize)
		
		if ( pos == false || CheckPatrolPointDistR(self, pos) == false ) then
		
		else
			--print("found pos ", pos)
			table.insert(self.PatrolPoints ,pos)
		end
		
		coroutine.yield()
	end
	
	self:SayToOwner(self:EntIndex(), " "..#self.PatrolPoints.." patrol points found" )

	self:InterruptClr("asmpp")
	
	self.AssemblyInProgress = false
end

function ENT:GetNextPatrolPoint()

	local r = self.PatrolPoints[math.Round(math.Rand(1, #self.PatrolPoints))] 
	
	local rb =  Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 )
	
	if ( r ) then
		return r + rb * 75
	else
		return self:ComputeNavPoint(
					self:GetPos() - Vector(1000, 1000, 1000), Vector(2000, 2000, 2000)) || 
					self:GetPos() + rb * math.Rand(350,800)
	end

end

local function DoEvasion(self, tpos, subject, cond)

	
	if ( !ValidateNavPoint(tpos) ) then
		--return true
	end
	
	if ( self:HaveEnemy() ) then
		self:Goto(tpos, 
				{	noint=true, force=true, notask = true,
					activity = self:GetAnimAct("WalkAim"),
					speed = self:GetStatsWalkspeed(),
					accel = self:GetStatsAccel(),
					attack = true,
					maxage = 4,
					cond = cond
				})
	else
		if ( subject:IsPlayer() ) then			
			if ( RollDice(self:GetRelationship(subject) * 12 ) ) then
				self:PlaySound("PlayerAvoid", 10)
			end
		end
		self:Goto(tpos, 
				{	noint=true, notask = true,
					maxage = 10,
					cond = cond		
				})
	end
end

function ENT:AutoEvade()
		
	local eyepos = self:EyePos()
		
	local _ents, __ents = self:FindInCone( eyepos, self:EyeAngles():Forward(), self.EvadeProximityDistance, math.pi / 2.1 )

	if ( !#_ents ) then
		_ents = __ents
	end
	
	local subject
	
	for _,v in pairs(_ents) do
		if ( v:GetParent() != self && 
				!v:IsWeapon() && (IsValid(v:GetPhysicsObject()) || v.NixBot) ) then
			subject = v
			break
		end
	end
	
	if ( !IsValid(subject) ) then
		return true
	end
		
	local obbsz = subject:OBBMaxs() - subject:OBBMins() 
	local dist = obbsz.x + obbsz.y	
	
	if (dist + obbsz.z < 75 ) then
		return true
	end
	
	local spos = subject:GetPos() + subject:OBBCenter()	
	local pos = self:GetPos() + self:OBBCenter()	
	local tdist = spos:Distance(pos) 
	
	--print(tdist, dist, tdist/dist)
	
	if ( tdist > dist ) then
		return true
	end
	
	
	local pseg = self.path && self.path:GetCurrentGoal()
	
	if ( UseAllowed(subject) ) then
		subject.nixbot_last_used = os.time()	
		subject:Use(self, self, USE_TOGGLE, 0)
	end

		
	local dv = (spos - pos):Angle()
	dv.yaw = dv.yaw + (math.random(90, 150) -  math.Clamp((tdist * tdist/dist ) , 0, 45)) *
					((math.random(1,2)*2)-3)

	local path = self.path
	tdist = dist * 1.4
	local loc = pos + dv:Forward() * math.Clamp(tdist , 100, 10000)
	
	local ret = DoEvasion(self, loc , subject, function() 
								if ( IsValid(subject) && self:GetPos():Distance(subject:GetPos() ) > tdist ) then
									return false
								end
							end)
	
	if ( path && pseg ) then path:Compute(self, pseg.pos) end
	
	return ret
	
end

local function MovementDiscovery(self, w)
	self.loco:SetDesiredSpeed( 100 )

	self.loco:SetAcceleration( 100 )	
	
	local path = Path( "Follow" )
	
	path:SetMinLookAheadDistance(300 )
	path:SetGoalTolerance(  20 )
	path:Compute( self, self:CPPIGetOwner():GetPos() )		

	local l = 0
	local gg = {}
	
	local a = w
	for k, v in SortedPairs(self:GetSequenceList()) do
		
		local t = self:GetSequenceInfo(k)
		if ((string.lower(v):find(string.lower(a)) ||
			string.lower(t.activityname):find(string.lower(a)) ) ) then
			
			local n = false
			
			if ( n == false ) then
				
				table.insert(gg, t)
			end
		end
	end
	
	local lt = 0
		
	
	while ( true ) do
	
		--if ( os.time() - lt > 2 ) then
			if ( #gg == 0 ) then
				return
				
			end
			
			local t = gg[#gg]
			
			print(t.activity, t.activityname, t.label, k)
			--self:StartActivity( t.activity, 250, 400 )
			self:PlaySequenceAndWaitE(t.label)
			
			table.remove(gg, #gg)
			
			lt = os.time()
		--end
		path:Compute( self, self:CPPIGetOwner():GetPos() )
		path:Update(self)
	
		coroutine.wait(2)
	end
	
end

function ENT:UpdateRanks()
	self:SetNWFloat("nb_rank", self:GetRank())
	self:SetNWFloat("nb_acc", self:GetAccuracy())
end


function ENT:Main()	
	while ( true ) do
		xpcall( function()				
	
			local clip_reload_threshold = IsValid(self.Weapon) && self.Weapon:GetMaxClip1() / 4 || 0
			local nodelay = false
			local noactreset = false
			
			while ( true ) do
				self.InterruptF = false
				
				--self:UpdateRanks()								
				if ( IsValid(self.Weapon) && 
					self.Weapon:Clip1() < clip_reload_threshold ) then
					self:DoReload()
				end
								
				local wto = 2
				
				if ( self:HaveEnemy()  ) then

					self.loco:FaceTowards( self:GetEnemy():GetPos() )	
					self:StartActivityE( self:GetAnimAct("RunChase"), self:GetStatsAccel(), self:GetStatsRunspeed() )								
					self.EvadeProximityDistance = 30
					
					self:AlertNeighbors( self:GetEnemy() )								
					self:EngageEnemy()
					
					if ( self:HaveEnemy() ) then nodelay = true end	
					
					self:StartActivityE( self:GetAnimAct("Idle"), 0, 0 )		
				elseif ( self:HasTask(self.Tasks) ) then
					if ( self:GetEnemy()) then
						self:SetEnemy(nil)
					end
					
					self.EvadeProximityDistance = 60
					self:ProcessTask(self.Tasks)		

					self:StartActivityE( self:GetAnimAct("Idle"), 0, 0 )						
				elseif ( IsValid(self.FollowTarget) ) then		
					self:SetMood(NIXBOT_MOOD_RELAXED)
					self.EvadeProximityDistance = 30
					if ( self:Follow ( { 
							tolerance = 250, attack = true
						}) == false ) then
						self.SELastPlayed["GreetPlayerFriend"] = os.time()
						self.SELastPlayed["GreetPlayerFoe"] = os.time()
						self:SetFollowTarget(nil)
					end
					
					nodelay = true	
					noactreset = true
					self:StartActivityE( self:GetAnimAct("Idle"), 0, 0 )		

				else
					if ( self:GetEnemy()) then
						self:SetEnemy(nil)
					end
										
					if ( self:GetPatrol() ) then 
						self.EvadeProximityDistance = 200
						self:SetMood(NIXBOT_MOOD_RELAXED)									
						self:Goto( self:GetNextPatrolPoint() )
							
						if ( self:HaveEnemy() ) then nodelay = true end				
						if ( IsValid(self.FollowTarget) ) then wto = 0 else wto = 6 end	
					end
					
					self:StartActivityE( self:GetAnimAct("Idle"), 0, 0 )	
						
				end
						
				self.EvadeProximityDistance = 60
				self:ProcessTimedTasks(self.TimedTasks, path)
				
				if ( noactreset == true ) then
					noactreset = false
				else
					self.CurrentActivity = nil
				end
					
				if ( nodelay == true ) then
					nodelay = false			
					coroutine.yield()
					continue			
				end

				self:WaitAlert(wto)
				
				if ( RollDice((self.Kills - self.PrevKills) * 25)  ) then
					self:PlaySound("Boast")
				end
				
				self.PrevKills = self.Kills
				
				coroutine.yield()
			end
		end, function(err)
			print(self:EntIndex(), self, ".Main", self.Main, "error occured: ", err)
			print( debug.traceback() )
			print(self:EntIndex(), "restarting in 5 secs")
		end)
		coroutine.wait(5)
	end
end

function ENT:PlaySequence(name, speed, rt)
	local len = self:SetSequence( name )
	speed = speed || 1 
	
	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( speed )
	
	local dur = len / speed
	
	timer.Simple( dur , function()
		if ( IsValid(self) ) then
			self.CurrentActivity = nil
		end
	end)
	
	return dur
end

function ENT:GiveAmmo(amount, id)
	local ammo = self.dump.Ammo[id]			
	self.dump.Ammo[id] = ammo != nil && ammo + amount || amount
end

function ENT:GetAmmoCount(id)
	return self.dump.Ammo[id] || 0
end

function ENT:Give(class, t)

	if (!self.dump[t]) then
		self.dump[t] = {}
	end
		
	local count = self.dump[t][class]
		
	if ( count == nil ) then	
		self.dump[t][class] = 1
	else
		self.dump[t][class] = math.Clamp(count + 1, 1, 100000)
	end				
end

function ENT:HasItem(t, class)
	return (self.dump[t] && self.dump[t][class] && self.dump[t][class] > 0 ) && true || false
end

function ENT:PopItem(t, class, c)
	if ( !self.dump[t] ) then
		return false
	end
	
	local count = self.dump[t][class]
	
	if ( nil == count || count == 0 ) then
		return false
	end
	
	local take = math.Clamp(c,1,count)
	
	self.dump[t][class] = count - (take || 1)
	
	return take
end

function ENT:CheckValidPickup(ent)
	if ( IsValid(ent:GetParent()) || 
			IsValid(ent:GetOwner()) || 
			(ent:IsWeapon() && !ent:IsScripted()) ) then
		return false
	end
	
	if ( ent:IsWeapon() ) then
		if ( self.Options.Weapon.BannedHoldtypes && 
			self.Options.Weapon.BannedHoldtypes[ent:GetHoldType()] ) then
				return false
		end
	end
	
	--print(type(ent))
	local altype = self.dump._allowed[type(ent)]
	
	if ( !altype ) then
		return false
	end
	
	if ( isbool(altype)  ) then
		return altype
	else		
		return altype[ent:GetClass()] || false
	end
	
	return false
end

function ENT:PickupItem(item)
	self:Give(item:GetClass(), type(item))
	self.LastPickup = item
	
	if ( type(item) == "Weapon" ) then
		self:GiveAmmo(item:Clip1(), item:GetPrimaryAmmoType())
		--self:SelectWeapon(item:GetClass())
		self:RunHook("PickupWeapon", item)			
	elseif ( type(item) == "Entity" ) then
		if (item.AmmoType) then
			self:GiveAmmo(item.AmmoAmount || item.AmmoMax || 10, item.AmmoType)
		end
	else
		self:RunHook("PickupItem", item)
	end
	
	SafeRemoveEntity(item)
end

function ENT:CheckFollowTargetMinDistance()
	if (self:IsFollowing() && IsValid(self.FollowTarget) &&
		self:GetPos():Distance(self.FollowTarget:GetPos() ) > 500 ) then
		return false
	end
	return true
end

function ENT:LookForUsableItems()
	if ( self:HaveEnemy() || !self:CheckFollowTargetMinDistance() ) then
		return
	end
	
	local _ents = ents.FindInCone( self:EyePos(), self:EyeAngles():Forward(), self:GetStatsVisRange() / 6, 0 )
	local hit 
	
	for _,v in ipairs( _ents ) do
		if ( !IsValid(v)) then
			continue
		end
	
		if ( !self:CheckValidPickup(v) ) then
			continue
		end
		
		if ( v:IsWeapon() && 
			v:Clip1() == 0 && self:HasItem(type(v), v:GetClass() ) 
			  	  ) then
			continue
		end
		
		self:Goto(v:GetPos(), {
			noint = true, notask = true, tolerance = 10,
			cond = function() if ( !IsValid(v) ) then return false end end
		})
				
		--[[if ( IsValid(v) && self:GetPos():Distance(v:GetPos()) < 75 ) then
			self:PickupItem(v)
		end]]
		
		if ( self:Interrupt() ) then
			break
		end	
		
		if ( !self:CheckFollowTargetMinDistance() ) then
			break
		end
		
		hit = true
	end
	
	if ( hit ) then
		self:SetInterrupt()
	end
end

function ENT:EnableItemPickup(b)
	if ( b == true ) then
		self:AssignTimedTask("LookForUsableItems", self.TimedMovementTasks, 1)
		self:AssignTimedTask("LookForUsableItems", self.TimedTasks, 1)
	elseif ( b == false ) then
		self:RemoveTimedTask("LookForUsableItems", self.TimedMovementTasks)
		self:RemoveTimedTask("LookForUsableItems", self.TimedTasks)
	end
end

function ENT:RunBehaviour()
	
	--MovementDiscovery(self, "alert")
	--[[local a = "jump"
	for k, v in pairs(TD) do
	
		if (string.lower(k):find(string.lower(a))   ) then
			print(k)
			self:StartActivity( v )
			coroutine.wait(2)
		end
	end
	
	if ( true ) then return end ]]

	--[[local owner = self:CPPIGetOwner()
	if ( IsValid(owner) ) then
		if (!owner.nixbot_refs) then
			owner.nixbot_refs = {}
		end
		table.insert(owner.nixbot_refs, self)
	end]]
		
	self:SetRelationship(self:CPPIGetOwner(), NIXBOT_RELATION_OWNER, 99)
	
	self.loco:SetJumpHeight((self.Options.Stats.Athletics + self.Options.Stats.Agility / 8) * 255)
				
	self:AssignTimedTask("ContinuousAlertNeighbors", self.TimedCombatTasks, 5)
	self:AssignTimedTask("AutoEvade", self.TimedCombatTasks, 0.2)
	self:AssignTimedTask("UpdateRanks", self.TimedCombatTasks, 2)
	self:AssignTimedTask("DecreaseEnemyTensionsStep", self.TimedCombatTasks, 5)
	
	self:AssignTimedTask("AutoEvade", self.TimedMovementTasks, 0.2)
	self:AssignTimedTask("UpdateRanks", self.TimedMovementTasks, 2)
	self:AssignTimedTask("DecreaseEnemyTensionsStep", self.TimedMovementTasks, 5)	
		
	self:AssignTimedTask("DecreaseEnemyTensionsStep", self.TimedTasks, 5)	
	
		
	self.loco:SetStepHeight(50)
	self.loco:SetDeathDropHeight(400)
	self.loco:SetDeceleration(self.Stats.Decel)
	
	
	
	self:AssemblePatrolPoints()

	self.MovTypeProc[3] = function(self, seg) 
		self:SayToOwner(self:EntIndex(), " jumping across gap")
	end
	
	self.MovTypeProc[2] = function(self, seg) 
		if ( self.pseg_type_l != 0 && !self.loco:IsClimbingOrJumping() ) then			
			local dir = (seg.pos - self:GetPos()):GetNormalized()
			self.loco:SetVelocity(dir * 150)
			self.loco:Jump()
			--self:SayToOwner(self:EntIndex(), " jumping")
			self:PlaySequenceAndWaitE( "jump_holding_jump" )
		end
	end
	
	self.MovTypeProc[1] = function(self) 
		if ( self.pseg_type_l != 1 ) then
			self:PlaySequence( "jump_holding_glide" )
			--self:SayToOwner(self:EntIndex(), " falling")
		end
	end
	
	self.MovTypeProc[0] = function(self) 
		if ( self.pseg_type_l == 1 ) then
			self:PlaySequence( "jump_holding_land" )
			--self:SayToOwner(self:EntIndex(), " landed")
		end
	end
	
	self:SayToOwner(self:EntIndex(), " Initialization complete")
	
	self:RunHook("Initialized")
	
	self:DoReload()
		
	self:Main()

end


local function DoTrace(f, s, d, c)
	local tr = util.TraceLine( {
		start = s,
		endpos = d ,
		filter = f
	} )
	
	return c(tr) && true || false	
end

function ENT:DoAttackEvent()
	if ( self.attack_event_act ) then
		local pact = self.CurrentActivity
		self.CurrentActivity = nil
		self:StartActivity( self.attack_event_act, 0, 0 )
		self.CurrentActivity = pact
	end	
end

function ENT:GetActiveWeapon()
	return self.Weapon
end

local function GetTargetHitPosAbs(enemy)	
	return (enemy:GetPos() + 
			(enemy:OBBCenter() /2 * 3) )				
end

local function GetRandomHitboxBone(ent)
	local hbgc = ent:GetHitBoxGroupCount()
	
	if ( hbgc == nil ) then
		return
	end
	
	local group = math.random(0, hbgc - 1)
	local hitboxcount = ent:GetHitBoxCount( group )

	return ent:GetHitBoxBone( math.random(0, hitboxcount - 1), group )
end

function ENT:SetAimVector(v)
	self.c_aim_vector = v
end

function ENT:GetAimVector()
	return self.c_aim_vector
end

function ENT:GetAimOffset(enemy)
	local rv = VectorRand()
	local di = 1 - 1 / ((enemy:GetPos():Distance(self:GetPos())) / 125 + 1) 
	local k = (((enemy:GetVelocity():GetNormalized()
			+ self:GetVelocity():GetNormalized()) * 2 + rv )
			* (15 - 15 * self:GetAccuracy()) ) + 
			(rv * (10 - 10 * self:GetAccuracy())) * di

	return k
end

function ENT:CalculateEnemyHitpos(enemy, bone)	
	local hitpos 
			
	if ( bone ) then
		hitpos = enemy:GetBonePosition(bone) || GetTargetHitPosAbs(enemy)
	else
		hitpos = GetTargetHitPosAbs(enemy)
	end
					
	return hitpos
end

function ENT:GetViewPunchAngles()	
	return Angle(0,0,0)
end

function ENT:SetViewPunchAngles(a)	
	
end

function ENT:GetShootPos()
	return self:GetAttachment(self.Weapon_AT).Pos 
end

function ENT:Crouching()
	return false
end

function ENT:OnGround()
	return self:IsFlagSet( FL_ONGROUND )
end

function ENT:AimAt(ep)
	local dv = self:WorldToLocalAngles((ep - self:GetShootPos()):Angle()  )
	dv:Normalize()
	
	self:SetPoseParameter("aim_yaw", dv.yaw - self.AimAngleOffset.yaw ) 
	self:SetPoseParameter("aim_pitch", dv.pitch - self.AimAngleOffset.pitch )
	
	--self:InvalidateBoneCache()
		
	self:LookAt(ep)
	
end


function ENT:LookAt(ep)
	local dv = self:WorldToLocalAngles((ep - self:EyePos()):GetNormalized():Angle())
	dv:Normalize()	

	self:SetPoseParameter("head_yaw", dv.yaw)
	self:SetPoseParameter("head_pitch", dv.pitch ) 
	self:SetPoseParameter("head_roll", dv.roll)
	
	self:SetEyeTarget(ep)
	
	return dv
	--self:InvalidateBoneCache()	
end

function ENT:DischargeBurstNoAnim(...)
	local pa_ev = self.attack_event_act
	self.attack_event_act = nil					
	self:DischargeBurst(...) 				
	self.attack_event_act = pa_ev
end

function ENT:DischargeBurst (enemy, count, path)

	if ( !IsValid(self.Weapon) || os.time() - self.LastBurst < math.Rand(0.5,2)  ) then
		self:LookAt( self.last_bone && self:CalculateEnemyHitpos(enemy, self.last_bone) || GetTargetHitPosAbs(enemy))
		return false
	end
	
	if ( self.Weapon:Clip1() == 0 ) then
		self:DoReload()
		if ( !IsValid(enemy) ) then
			return false
		end
	end
	
	local tbone = GetRandomHitboxBone(enemy)			

	if ( !tbone ) then
		return false
	end
	
	self.last_bone = tbone
	
	if ( !DoTrace(		
		{self, self.Weapon}, self:GetShootPos(), self:CalculateEnemyHitpos(enemy, tbone),
		function (tr) if ( tr.Entity == enemy ) then return true else 
			if ( IsValid(tr.Entity) ) then
				local sp = self:GetPos()

				local dv = (tr.Entity:GetPos() - sp):Angle()
				dv.yaw = dv.yaw + ( math.Clamp( 150 - sp:Distance(tr.Entity:GetPos()),30,150)) * 
									((math.random(1,2)*2)-3)
				local obb_max = tr.Entity:OBBMaxs()
				local dist = obb_max.x + obb_max.y

				local tpos =  self:GetPos() + dv:Forward() * (dist * 4)
				if ( ValidateNavPoint(tpos) ) then
					self:Goto(tpos, 
						{	noint=true, notask = true, force = true,
							activity = self:GetAnimAct("WalkAim"),
							speed = self:GetStatsWalkspeed(),
							accel = self:GetStatsAccel(),
							maxage = 10				
						})
					if ( !IsValid(enemy) ) then
						return false
					end
				else
					return false
				end	
			end
			return true
		end end ) ) then		
		
		return false
		
	end
	
	self.LastBurst = os.time()	
	if ( self.Weapon.SetShotsFired ) then
		self.Weapon:SetShotsFired( 0 )
	end	
			
	while ( count > 0 && IsValid(enemy) ) do	
		self.loco:FaceTowards(enemy:GetPos() )
		
		local av = self:CalculateEnemyHitpos(enemy, tbone)
		
		self:SetAimVector((av - self:GetAimOffset(enemy)) - self:GetShootPos()) 
		self:AimAt(av)
				
		self.Weapon:PrimaryAttack()
				
		count = count - 1
		
		coroutine.wait(0.06)
		
		if ( path ) then
			path:Update(self)
		end
		
	end

	self:SetAccuracy( math.Clamp(self:GetAccuracy() + (0.0011 *  ((1/((self:GetAccuracy()+1)^40)^0.8) ) ) , 0, 0.94) )
			
	return true
end

function ENT:StartActivityE(act, speed, acc)	
	local apply
	
	if ( speed && self.CurrentSpeed != speed ) then		
		self.loco:SetDesiredSpeed( speed )
		self.CurrentSpeed = speed
		apply = true
	end
	
	if ( acc && self.CurrentAccel != acc ) then
		self.loco:SetAcceleration( acc )	
		self.CurrentAccel = acc
		apply = true
	end
	
	if ( act == self.CurrentActivity) then
		if ( apply && act ) then
			self:StartActivity( act )
		end
		return
	end
		
	self.CurrentActivity = act
	if ( act ) then
		self:StartActivity( act )
	end
end

function ENT:GetEnemyPos()
	local enemy = self:GetEnemy()
	return enemy:GetPos() + enemy:OBBCenter() 
end

function ENT:GetEyeTrace(target)
	local tr = util.TraceLine( {
		start = self:EyePos() + (self:GetForward() * 10),
		endpos = target:GetPos() + target:OBBCenter(),
		filter = function(ent) if (	ent != target && (ent:IsWeapon() || ent:IsPlayer() || ent:IsNPC() ) ) then return false else return true end end
	} )
	
	return tr.Entity
end

function ENT:EnemyVisible()
	local enemy = self:GetEnemy()
	
	if ( !IsValid(enemy) ) then
		return false
	end
	
	return self:GetEyeTrace(enemy) == enemy
end

local function inrange3(vec, min, max)
        if vec[1] < min[1] then return false end
        if vec[2] < min[2] then return false end
        if vec[3] < min[3] then return false end

        if vec[1] > max[1] then return false end
        if vec[2] > max[2] then return false end
        if vec[3] > max[3] then return false end

        return true
end

function ENT:HandleStuck()
	local tr = util.TraceLine( {
		start = self:EyePos(),
		endpos = self:EyePos() + self:GetForward() * 75,
		filter = function (ent)
			if (ent == self || !UseAllowed(ent) ) then
				return false
			else
				return true
			end					
		end
	} )
	
	local ent = tr.Entity
	
	if ( IsValid(ent) ) then
		ent:Use(self, self, USE_TOGGLE, 0)
		self:SayToOwner(self:EntIndex(), " stuck, using", ent)	
		ent.nixbot_last_used = os.time()
		coroutine.wait(1.25)
	end

	--local pseg = self.path:GetCurrentGoal()
		
	self:SetNotSolid(true)
	
	timer.Simple(3, function()
		if ( IsValid(self) && !self.loco:IsStuck() ) then
			self:SetNotSolid(false)
		end
	end)
		
	self.loco:ClearStuck()
		
	local cppos = self.path:GetPositionOnPath(self.path:GetCursorPosition())
	
	if ( self.last_path_pos && 
		inrange3(cppos, self.last_path_pos - Vector(50,50,50), self.last_path_pos + Vector(50,50,50) )
		) then
		self.stuck_counter = self.stuck_counter + 1
				
		if ( self.stuck_counter > 4 ) then
			self.path:Invalidate()
			self.stuck_counter = 0
		end
	else
		self.stuck_counter = 0
	end
	
	self.last_path_pos = cppos
		
	local pos = self.path:GetPositionOnPath(self.path:GetCursorPosition() + 200)

	self.path:MoveCursor(200)
	
	if ( pos != vector_origin ) then		
		self:SetPos(pos)	
	end
		
	return true
end

function ENT:ResolveStuck()
	
	if ( self.loco:IsStuck() ) then
		
		self:SayToOwner(self:EntIndex(), " stuck")
		
		--self.loco:JumpAcrossGap( self:GetPos() + self:GetForward() * 250, self:GetPos())
		
		return self:HandleStuck()

	end
	return true
end

function ENT:LookIdle()
	if ( IsValid(self.ally_in_view) ) then
		self:LookAt(self.ally_in_view:EyePos() )
	else
		self:LookAt((self:EyePos() + (self:GetForward() * 250)) - Vector(0,0,15) ) 
	end
end

function ENT:Goto(loc, options)
	local options = options or {}

	
	local actopts = {options.activity or self:GetAnimAct("Walk"), 
							options.speed or self:GetStatsWalkspeed(), 
							options.accel or self:GetStatsAccel() }
								
	--self.CurrentActivity = nil
	
	options.tolerance = options.tolerance or 25
	
	local path = Path( "Follow" )
	self.path = path
	path:SetMinLookAheadDistance( options.lookahead or 750 )
	path:SetGoalTolerance( options.tolerance )
	path:Compute( self, loc )	
	
	options.maxage = options.maxage || 900

	if ( !path:IsValid() ) then 
		self:SayToOwner(self:EntIndex(), " goto: invalid path")
		return false 
	end
		
	local fseg = path:FirstSegment()
		
	while ( path:IsValid() && (options.force || !self:HaveEnemy()) ) do
			
		if ( path:GetAge() > options.maxage ) then
			break
		end
								
		if ( self:Interrupt() && options.noint != true ) then
			self:SayToOwner(self:EntIndex(), " interrupting patrol")
			break
		end
		
		if ( options.cond && options.cond(self) == false ) then
			break
		end
		
		if ( self:GetBusyTimeout() > RealTime() ) then
			coroutine.yield()
			continue
		end
			
		if ( !options.notask ) then
			if ( self:ProcessTimedTasks(self.TimedMovementTasks, path) ) then	
								
				if ( !path:IsValid() ) then		
					path:Compute(self, loc)
					coroutine.yield()
					continue
				end
								
							
				self.path = path					
			end
		end
		
		local pseg = path:GetCurrentGoal()
		
		if ( pseg) then
			if ( pseg.area:IsUnderwater() && !fseg.area:IsUnderwater() ) then
				self:ComputePath(path, loc)
				coroutine.wait(1)
				continue
			end
			
			if (self.MovTypeProc[pseg.type]) then
				self.MovTypeProc[pseg.type](self, pseg)
			end
			
			self.pseg_type_l = pseg.type
			
			--print( path:FirstSegment().pos:Distance(self:GetPos()), pseg.pos:Distance(self:GetPos()) )
		end
			
		if ( !self:ResolveStuck() ) then
			if ( options.persist != true ) then
				return true
			else
				path:Compute(self, loc)
			end
		end
				
		--[[if ( path:GetAge() > 10 ) then
			path:Compute(self, loc)
		end]]
				
		self:StartActivityE( unpack(actopts) )
		
		self:LookIdle()
		
		path:Update( self )
		
		if ( options.attack && self:HaveEnemy() &&
				self:GetRangeTo( self:GetEnemy():GetPos()  ) < self:GetStatsTFRange() &&
				self:EnemyVisible()) then 
			
			local enemy = self:GetEnemy()
			self.loco:FaceTowards(enemy:GetPos())	
			self:DischargeBurstNoAnim(enemy, math.random(unpack(self.BurstRC)), path)
		end
			
		coroutine.yield()
	end	
	
	if ( self:GetRangeTo( loc ) <= options.tolerance + 25 ) then
		self:RunHook("GotoArrived", options)
	else
		self:RunHook("GotoFailed", options)
	end
	
	return true
end

function ENT:SetFollowTarget(target)	
	if ( IsValid(target) && 
		((self:CPPIGetOwner() != target && 
			self:GetRelationship(target) < NIXBOT_RELATION_FRIEND) ||
			self:HaveEnemy() ) ) then
		return false
	end
	self.FollowTarget = target
	self:SetFollow(target)
	return true
end

function ENT:GetFollowTarget()
	return self.FollowTarget
end

function ENT:Follow (options)
  local target = self.FollowTarget
  
	if ( !IsValid(target) ||
	     self:GetRelationship(target) < NIXBOT_RELATION_FRIEND ) then
		return false
	end

	local options = options or {}
	
	options.tolerance = options.tolerance or 250
			
	self.loco:FaceTowards(target:EyePos() )	
	local dv = self:LookAt(target:EyePos() )
	
	if ( self:GetPos():Distance(target:GetPos()) < options.tolerance ) then
		if ( !self.follow_idle_time ) then
			self.follow_idle_time = os.time()
			self.follow_idle_timeout = math.random(75,120)
		end
				
		if ( os.time() - self.follow_idle_time > self.follow_idle_timeout ) then
			self:PlaySound("FollowIdle")
			self.follow_idle_time = nil
			self.CurrentActivity = nil
		end
		
		self:ProcessTimedTasks(self.TimedMovementTasks, path)
		return
	else
		self.follow_idle_time = nil
	end
				
	local path = Path( "Follow" )
	self.path = path
	path:SetMinLookAheadDistance( options.lookahead or 1000 )
	path:SetGoalTolerance(  options.tolerance  )
	
	path:Compute(self, target:GetPos())
	
	if ( !path:IsValid()  ) then
		return
	end
	
	while ( path:IsValid() && 
			!( options.attack && self:HaveEnemy() )  ) do
		
		target = self.FollowTarget
										
		if ( !IsValid(target) ||
         self:GetRelationship(target) < NIXBOT_RELATION_FRIEND ) then
      return false
    end
		
		local dist = self:GetRangeTo(target:GetPos())
					
		if ( dist > 20000 ) then		
			if ( RealTime() - target.nixbot_last_ping > 10 ) then
				self:SayToOwner(self:EntIndex(), " target ", target, " lost")
				return false
			end
			
			break
		else
			target.nixbot_last_ping = RealTime()
		end
					
		if ( self:GetBusyTimeout() > RealTime() ) then
			coroutine.yield()
			continue
		end
			
		if ( !options.notask ) then
			if ( self:ProcessTimedTasks(self.TimedMovementTasks, path) ) then		
				self.path = path	

				if ( !IsValid(target) ) then
					break
				end
				
				if ( !path:IsValid() ) then
					path:Compute( self, target:GetPos() )	
					coroutine.yield()
					continue
				end
			end
		end
			
		if ( !self:ResolveStuck() ) then
			if ( options.persist != true ) then
				return true
			else
				path:Compute(self, target:GetPos())
			end
		end
				
		if ( path:GetAge() > 0.3 ) then
			path:Compute(self, target:GetPos())
		end
			
		path:Update(self)	
		
		local pseg = path:GetCurrentGoal()
				
		if ( dist > 500 ) then				
			self:StartActivityE( self:GetAnimAct("Run"), self:GetStatsRunspeed(), self:GetStatsAccel() )	
		else
			self:StartActivityE( self:GetAnimAct("Walk"), self:GetStatsWalkspeed(), self:GetStatsAccel() )	
			self.loco:FaceTowards(target:EyePos() )	
			self:LookAt(target:EyePos())
		end
			
		
		coroutine.yield()
	end	
	
	return true
end

function ENT:EngageEnemy( options )
	if ( !IsValid(self.Weapon) ) then
		return false
	end

	local options = options or {}

	local path = Path( "Follow" )
	self.path = path
	path:SetMinLookAheadDistance( options.lookahead or 750 )
	path:SetGoalTolerance( 25 )
	path:Compute( self, self:GetEnemy():GetPos() - self:GetEnemy():OBBCenter()  )	

	if ( !path:IsValid() ) then 
		self:SayToOwner(self:EntIndex(), " invalid path")
		return false 
	end
	
	self.target_last_seen = os.time()
	
	local tlost_c = 0
	local times_attacked = 0
	
	local base_attack_distance = math.Round(self:GetStatsTFRange() * 
			(( (self:GetEnemy():OBBMaxs() - self:GetEnemy():OBBMins()):LengthSqr() / 5625) ^ 1.4))
	
	local session_attack_distance = base_attack_distance
	local min_closein_dist = base_attack_distance / 4
	
	self.target_pos = self:GetEnemy():GetPos()
	
	local path_max_age = 0.4
	
	local p_target_pos = Vector(0,0,0)
	local recompute_path = true
	
	self:SetMood(NIXBOT_MOOD_AGITATED)
	self.attack_event_act = self:GetAnimAct("ShootStand") 
	
	local last_enemy = enemy
	
	while ( path:IsValid() && self:HaveEnemy() ) do
	
		if ( self:GetBusyTimeout() > RealTime() ) then
			coroutine.yield()
			continue
		end
				
		if ( self:ProcessTimedTasks(self.TimedCombatTasks, path) ) then
			self.path = path
			
			--[[if  (!path:IsValid()) then
				path:Compute( self, loc )	
				coroutine.yield()
				continue
			end]]
			
			if (!self:HaveEnemy()) then
				self:SetEnemy( nil )
				return false	
			end
		end
		
		if ( self:EnemyDetectAge() > 1 ) then
			self:DetectEnemy()
		end
		
		local enemy = self:GetEnemy()
		
		if ( enemy != last_enemy ) then
			self:RunHook("EngageEnemy", options)
			last_enemy = enemy
		end
		
		local target_visible = self:EnemyVisible()
		
		if ( target_visible == true )then
			self.target_last_seen = os.time()
			self.target_pos = enemy:GetPos() - enemy:OBBCenter()			
		else
						
			if ( self:CalculateCognitionScore(enemy ) 
					> self:GetStatsAwareness()) then
				self.target_last_seen = os.time()
				self.target_pos = enemy:GetPos() - enemy:OBBCenter()				
			end
		end
		
		if ( self.target_pos != p_target_pos ) then
			recompute_path = true
			p_target_pos = self.target_pos
		end
		
		local pseg = path:GetCurrentGoal()
		local fseg = path:FirstSegment()
							
		if ( pseg ) then
			if ( pseg.area:IsUnderwater() && !fseg.area:IsUnderwater() ) then
				self:SayToOwner(self:EntIndex(), " wont go underwater")
				self.target_pos = fseg.pos
				path:Compute( self, self.target_pos )	
				recompute_path = false
				--path_max_age = 10
			end
		end
		
		if ( recompute_path == true && 
			path:GetAge() > path_max_age ) then
			path:Compute( self, self.target_pos )
			recompute_path = false
		end
		
		path:Update( self )
						
		
		local dist =  self:GetRangeTo( self.target_pos  )
		
		if ( times_attacked > math.Rand(3,10) && dist > min_closein_dist ) then
			session_attack_distance = math.Clamp(session_attack_distance - 150, min_closein_dist, session_attack_distance)
			times_attacked = 0
			if ( session_attack_distance == min_closein_dist ) then
				session_attack_distance = base_attack_distance
			end
		end	
		
		if ( dist <= session_attack_distance &&
				 target_visible == true) then			
	
			self:StartActivityE( self.attack_event_act, 0, 0 )						
			self.loco:FaceTowards(enemy:GetPos() )	
			
			if ( self:DischargeBurst(enemy,math.random(unpack(self.BurstRC))) == true ) then
				times_attacked = times_attacked + 1			
			end	
			
		elseif ( target_visible == false ) then
			if ( dist > 25 ) then
				self:StartActivityE( self:GetAnimAct("RunChase"), self:GetStatsAccel(), self:GetStatsRunspeed() )		
			else
				self:StartActivityE( self.attack_event_act, 0, 0 )
			end
			
			self:LookAt(enemy:EyePos() )
	
			if ( os.time() - self.target_last_seen > 10) then				
				self:SayToOwner(self:EntIndex(), " target escaped")
				self:SetEnemy( nil )
				return false	
			end
		elseif ( dist >= min_closein_dist ) then
			self.loco:FaceTowards(enemy:GetPos() )	
			local scoped = self:GetActiveWeapon():IsScoped()
			
			if ( dist < base_attack_distance && !scoped ) then					
				self:StartActivityE(self:GetAnimAct("WalkAim"), 75, self:GetStatsAccel())			
				self:DischargeBurstNoAnim(enemy, math.random(unpack(self.BurstRC)), path) 				
			else
				self:StartActivityE( self:GetAnimAct("RunChase"), self:GetStatsAccel(), self:GetStatsRunspeed() )			
				if ( !scoped && RollDice(15) ) then					
					self:DischargeBurstNoAnim(enemy, math.random(unpack(self.BurstRC)), path) 	
				else
					self:LookAt(enemy:EyePos() )
				end
			end
			
		else			
			session_attack_distance = base_attack_distance
		end
		
		if ( !self:ResolveStuck() ) then
			self.CurrentActivity = nil 
		end		
		
		if ( options.draw ) then path:Draw() end
			
		coroutine.yield()
	end
		
	self:SetMood(NIXBOT_MOOD_STIMULATED)
	
	if ( !self:HaveEnemy()) then
		self:RunHook("LostEnemy", options)
		self:SayToOwner(self:EntIndex(), " target gone")	
		self:SetEnemy( nil )
	elseif ( !path:IsValid() ) then
		self:SayToOwner(self:EntIndex(), " invalid path")
		return true, true
	end

	--self:SetEnemy( NULL )
	
	return true
end

util.AddNetworkString("NIXBOT.net.plyctl")

local AllowedPCFunctions = {
	["SetPatrol"] = true,
	["SetInterrupt"] = true,
	["SetFollowTarget"] = true,
	["PPDensity"] = true,
	["SetPPRebuild"] = true
}

net.Receive("NIXBOT.net.plyctl", function(len, ply)
	local t = net.ReadTable()
	
	local nb = t.e
	local arg = t.a

	if ( !isstring(t.n) || !istable(arg) || !IsValid(nb) || 
			 !isentity(nb) || !nb:IsNixBot() || nb:CPPIGetOwner() != ply  ) then
		return
	end
	
	local fn = "Set"..t.n
	
	if ( !AllowedPCFunctions[fn] ) then
		return
	end
	
	local fp = nb[fn]
		
	if ( !isfunction(fp) ) then
		return
	end
	
	fp(nb, unpack(arg) )
end)