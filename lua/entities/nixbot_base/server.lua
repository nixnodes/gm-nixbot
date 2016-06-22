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

hook.Add( "PlayerSpawnedNPC", "nixbot_spawned", function ( ply, ent )	
	if ( ent:IsNixBot() ) then
		ply:AddCount("nbs", ent)		
    ent:SetRelationship(ply, NIXBOT_RELATION_OWNER, 99)
	end
end )

hook.Add( "PlayerCanPickupWeapon", "nixbot_disable_weap_pickup", function( ply, wep )
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
		target:SetRelationship(attacker, math.Clamp(target:GetRelationship(attacker) - (dmg:GetDamage() / 4), NIXBOT_RELATION_ARCH_ENEMY, NIXBOT_RELATION_OWNER ))
				
    if ( !target:HaveEnemy() && attacker != target:GetEnemy() &&
		      target:GetRelationship(attacker) <= NIXBOT_RELATION_NEUTRAL &&
		      target:IsEntityVisible(attacker) && 		      
          target:GetPos():Distance(attacker:GetPos()) <= target:GetStatsVisRange() * 3 ) then
		  
		  target:SetInterrupt()
		  
		  local pos = attacker:GetPos()
		  		  
      target:AssignTask(target.PrioTasks, function(self)
        self:Goto(pos,
        {
          notask = true, force = true,
          activity = self:GetAnimAct("Run"),
          speed = self:GetStatsRunspeed() + 25,
          tolerance = 250, attack = true,
          cond = function(self) 
            if ( !IsValid(attacker) ) then
              return
            end
            
            if ( self:HaveEnemy() ) then
              return false
            end
             
            if ( self:TargetVisible(attacker) ) then
              if ( attacker:IsPlayer() and !attacker:Alive() ) then
                return false
              elseif ( attacker:IsNPC() and ( attacker:Health() < 1 ) ) then
                return false
              end 
            end
                 
          end
        })
      
      end, nil, "proc_hchase")
		end
				
		if ( target:InDanger() ) then
		  target:SetRelationship (attacker, NIXBOT_RELATION_FEAR)		
		  if ( target:GetRetreating() ) then
		    target:SetInterrupt("retreat")
		    timer.Create("NIXBOT.retreat."..target:EntIndex(), 5, 1, function()
		      if ( IsValid(target) && target:InDanger() ) then target:Flee() end
		    end)
		  else   
		    timer.Remove("NIXBOT.retreat."..target:EntIndex())
        target:Flee()			
		  end
		end
	end
	
	if ( target:IsPlayer() || target:IsNPC() ) then
		attacker.nixbot_last_attack_info = {
			time = RealTime(),
			target = target
		}
	end
	
end)

function ENT:InDanger()
  return (1 - self:Health() / self:GetMaxHealth() )  > self:GetStatsCourage()
end


function ENT:Flee()
  local pos = self:FindSpot( "far", {
     type = "hiding",
     pos = self:GetPos(),
     radius = 16000
  })
  
  if ( !pos ) then
    return false
  end
      
  self:SetEnemy(nil)
  self:SetInterrupt()
  self:SetInterrupt("combat")    
  
  self:AssignTask(self.PrioTasks, function(self)   
     if ( self:GetRangeTo(pos) > 50 ) then  
       --print("goto", self)
       self:SetRetreating(true)
       local res1, res2 = self:Goto(pos,
       {
         noint = true, notask = true, force = true,
         activity = self:GetAnimAct("Run"),
         speed = self:GetStatsRunspeed() + 45,
         tolerance = 35, attack = true,
         cond = function(self) 
           if ( self:Interrupt("retreat") || 
                !self:InDanger() ) then return false end 
         end
       })
     end
     
     self:SetEnemy(nil)
     
     if ( !self:InterruptClr("retreat") && res2 ) then
       print("idle", self)   
       self:PlaySequenceAndWaitE( "Fear_Reaction", nil , nil, 1)
     end
     
     self:SetRetreating(false)
     return true        
  end, nil, "proc_retreat")

  
end

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
	
	--self:AddFlags( bit.bor( FL_NPC, FL_AIMTARGET, FL_OBJECT, FL_SWIM, FL_FLY, FL_STEPMOVEMENT )  )
	
	self:SetPPDensity(1000)
	
	self.CarryMass = 0
	
	--self.PrintDebug = true

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
	
	self.Interrupts = {}
	self.Tasks = {}
	self.PrioTasks = {}
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
	
	
	
	self.AnimSeq = DEFAULT_ANIM_SEQ
	
	

		
	self.ValidateEnemy = ValidateEnemyDefault
	self.LastBurst = 0
	
	local AAAvg = (self.Options.Stats.Athletics + self.Options.Stats.Agility / 8 ) 
	
	self.Stats.AwarenessInv = math.Clamp(self.Options.Stats.Awareness, 0, 1)
	self.Stats.Awareness = math.Clamp(1 - self.Options.Stats.Awareness, 0, 1)
	 
	self.Stats.RunSpeed = math.Round(self.Options.Stats.Athletics * 600)
	self.Stats.WalkSpeed = math.Round(self.Stats.RunSpeed * 0.384)
	self.Stats.Accel = AAAvg * 400
	self.Stats.Decel = AAAvg * 800
	
	self.Stats.ReloadSpeed = self.Options.Stats.Athletics * 4.0
	
	self.Stats.Accuracy = self.Options.Combat.BaseAccuracy 
									* (1 + AAAvg / 4)
									
	self.Stats.CognitiveDetectRange = self.Options.Stats.Awareness * 6000
	self.Stats.VisibleDetectRange = self.Options.Stats.Awareness * 7500
	self.Stats.TargetFocusRange = self.Options.Stats.Awareness * 1500
	self.Stats.AbsoluteLoseTargetRange = self.Options.Stats.Awareness * 15000
	
	self.Stats.MaxCarryWeight = 1000 * self.Options.Stats.Athletics
	
	--[[print (
		self:GetStatsAwareness(),
		self:GetAwareness(),
		self:GetStatsCogRange(),
		self:GetStatsVisRange(),
		self:GetStatsTFRange(),
		self:GetStatsRunspeed(),
		self:GetStatsWalkspeed(),
		self:GetStatsAccel()
	) ]]
	
	self:Give(self.Options.Weapon.Class, "Weapon")
	
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
	self:EnableSupplyAllies(true)
	
	self.Hooks = NIXBOT.hook:CreateContext()
	
	self:InitializePhysics()
	
	if ( self.PostInit ) then
	  self:PostInit()
	end
end


function ENT:InitializePhysics()
  self:PhysicsInitShadow(true, true)
    
  local phys = self:GetPhysicsObject()
  if ( !phys:IsValid() ) then
    return false
  end
     
  phys:SetMass(85)
  phys:SetBuoyancyRatio(1)
  
  phys:Wake()
  
  --print(phys:GetMass(), phys:IsMotionEnabled(), phys:IsAsleep(), phys:GetInertia())
  
  
  return true
  
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

function ENT:Debug(...)
  if ( self.PrintDebug ) then
    self:SayToPlayer(self:CPPIGetOwner(), ...)
  end
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

function ENT:GetStatsCourage()
	return self.Options.Stats.Courage
end 

function ENT:GetStatsAthletics()
  return self.Options.Stats.Athletics
end

function ENT:GetStatsMaxCarryWeight()
  return self.Stats.MaxCarryWeight
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
		self.AimAngleOffset = Angle(0,8,0)		
		self.AnimSeq.Reload = "reload_smg1"	
		self.CurrentShootSeq = "shoot_ar2"
	else
		self.AimAngleOffset = Angle(0,-8,0)
		self.AnimSeq.Reload = "reloadpistol"
		self.CurrentShootSeq = "shootp1"
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

function ENT:AssignTask(tab, func, args, id)
  local t = {func = func, data = args || {}, id = id }
		
	if ( id ) then	  	  
    for _,v in ipairs(tab) do
      if ( v.id == id ) then
        tab[_] = t
        return
      end
    end
  end
	table.insert(tab, t)
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
		if ( RealTime() - t.last < t.interval  ) then
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
			t.last = RealTime()
		end
	end
	return c || false
end


function ENT:ProcessTask(tab)

  if ( 0 == #tab ) then return false end 
  local ret = false
  
  for _,t in ipairs(table.Copy(tab)) do

    table.remove(tab, _) 
    
  	local r, r2 = t.func(self, unpack(t.data))
  	
  	if ( r == true ) then
  	  ret = r  	  
  	end

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
		self:Debug(self:EntIndex(), " contact, using", ent)
	elseif ( self:GetPickupItems() && self:CheckValidPickup(ent) ) then
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
		if ( self.Interrupts[n] == true) then
			return true
		end
	else
		if ( self.InterruptF == true ) then
			return true
		end	
	end
	
	return false
end

function ENT:ClearInterrupt(n)
	if ( n ) then
		self.Interrupts[n]  = false
	else
		self.InterruptF = false
	end	
end

function ENT:ClearInterrupts(n)
  self.InterruptF = false
  self.Interrupts = {}  
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
		self.Interrupts[n]  = true
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

function ENT:IsInCone(pos, cone_origin, cone_direction, cone_radius, cone_angle)

  if ( cone_origin:Distance(pos) > cone_radius ) then
    return false
  end
  
  local cos = math.cos(cone_angle)
  
  cone_direction:Normalize()
  local dir = pos - cone_origin
  
  dir:Normalize()
  local dot = cone_direction:Dot(dir)

  if (dot > cos) then
    return true
  end
  
  return false
end

function ENT:FindInCone(cone_origin, cone_direction, cone_radius, cone_angle)
	local entities = ents.FindInSphere(cone_origin, cone_radius)
	local result = {}

	cone_direction:Normalize()

	local cos = math.cos(cone_angle)

	for _, entity in pairs(entities) do
		if ( entity == self || entity:IsWorld() || 
		      entity:GetParent() == self ) then
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

function ENT:GotoDoTrackTarget(lset, data) 
  if ( !IsValid(data.ent) ) then
    return false
  end
  lset.pos = data.ent:GetPos()
  if ( self.path:GetAge() > 1 ) then
    self.path:Compute(self, lset.pos)
    self.path:Update(self)
  end
end

function ENT:SupplyAllies()
  local _ents = ents.FindInSphere(self:GetPos(), 1000)
  
  local cres = {
    score = -0xFFFFFF,
    ent = nil
  }
  
  local delivery_list = {}
  
  for _,v in ipairs( _ents ) do
    if ( v == self || !IsValid(v) || !( v:IsPlayer() || v:IsNPC() ) ) then
      continue
    end
    
    local disp = self:GetRelationship(v)
    
    if ( disp < NIXBOT_RELATION_NEUTRAL ) then
      continue
    end
    
    local distance = self:GetPos():Distance(v:GetPos())    
    local score = disp * (100/distance)
    
    if ( self:HasItem("Entity", "item_healthkit") &&
          v:Health() < v:GetMaxHealth() - 25 &&
          self:GetItemCount("Entity", "item_healthkit") > 2 ) then
      score = score + 20000 - v:Health()
      delivery_list["Entity"] = {
            class = "item_healthkit"
          }
    end
    
    if ( score > cres.score) then
      cres.score = score
      cres.ent = v
    end
    
  end
  
  if ( !cres.ent || 0 == table.Count(delivery_list) ) then
    return true
  end
    
  self:Goto(cres.ent:GetPos(), 
    { 
      notask = true, maxage = 120,
      activity = self:GetAnimAct("Run"),
      speed = self:GetStatsRunspeed(),
      accel = self:GetStatsAccel(),
      tolerance = 100,
      cond = self.GotoDoTrackTarget,
      cond_data = { ent = cres.ent }
    })
            
  if ( !IsValid(cres.ent) || 
        self:GetPos():Distance(cres.ent:GetPos()) > 100 ) then
      return true
  end 
    
  
  for t,v in pairs(delivery_list) do
    if ( v.class == "item_healthkit" ) then
      v.num = math.Clamp(math.Round((cres.ent:GetMaxHealth() - cres.ent:Health()) / 25), 0, self:GetItemCount(t,v.class) / 1.75 )
      self:PlaySound("HealPlayer", 5)
    end
    self:Debug(self:EntIndex().."dropping ", t, v.class, v.num, cres.ent)
    self:DropItem(t, v.class, cres.ent:GetPos() + VectorRand() * 7, v.num)
  end
  
  return true
end

function ENT:IsFollowing()
	return self.FollowTarget && true || false
end

function ENT:DetectEnemyInView()
	local _ents = self:FindInCone( self:EyePos(), self:EyeAngles():Forward(), self:GetStatsVisRange(), math.pi / 2.25)

	local cres = {
		distance = 0,
		score = 0xFFFFFF,
		ent = nil,		
		ally_disp = 0,
		ent_ally = nil
	}
		
	for k, v in ipairs( _ents ) do
		if ( !IsValid(v) || !self:Visible(v)  ) then
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
				
		local score = (1/(distance/(disp*(math.abs(disp)+1))) )
		
		if ( score < cres.score) then
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
		score = 0xFFFFFF,
		ent = nil, 
		disp = 0,
		distance = 0
	}

	for k, v in ipairs( _ents ) do
		if ( !IsValid(v) ) then
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
		
		local score = (disp * (1/cogscore) )
		
		if ( score < cres.score ) then
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

function ENT:Heal()
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
		self:Heal()
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
		target == game.GetWorld() ||
		!self:TargetVisible(target) ) then
		return true
	end
	
	vec = vec || target:GetPos()
	
	if ( vec == nil ) then
	  return true
	end
	
	--print(self:EntIndex(), "alert", target)
	
	local neighs = ents.FindInSphere(self:GetPos(), self:GetStatsCommRange())
	local hit
	
	for _,v in pairs(neighs) do
		
		if (v != self && v:IsNixBot() && 
			!v:HaveEnemy() && v:IsEntityValidTarget(target) && 
			v:GetRelationship(target) < v:GetRelationship(self) && 
			v:GetRelationship(target) > NIXBOT_RELATION_ENEMY - 1 ) then
			--v:SetEnemy(target)

			v:SetRelationship(target, NIXBOT_RELATION_ENEMY - 1, 25)
			v:SetMood(NIXBOT_MOOD_STIMULATED)
			v:SetInterrupt()
			
			v:AssignTask(v.PrioTasks, v.AlertNeighbors, {target, vec}, "anei_alert" )
			v:AssignTask(v.PrioTasks, v.AlertGotoWrapper, 
						{target, vec, Vector( 0,0,0 ) , 
						{
						  speed = v:GetStatsRunspeed(), accel = v:GetStatsAccel(), 
						  activity = v:GetAnimAct("RunChase"), noint = true, notask = true},
						  cond = function(self)
						    if ( !IsValid(target) ) then
						      return false
						    end
						    
						    if ( self:TargetVisible(attacker) ) then
                  if ( attacker:IsPlayer() and !attacker:Alive() ) then
                    return false
                  elseif ( attacker:IsNPC() and ( attacker:Health() < 1 ) ) then
                    return false
                  end 
                end
						  end
						}, "anei_goto")
			
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

function ENT:PlaySequenceAndWait( name, speed, dm, len )
  local l = self:SetSequence( name )

  len = len && len || l
  speed = speed or 1

  self:ResetSequenceInfo()
  self:SetCycle( 0 )
  self:SetPlaybackRate( speed )

  if ( !dm ) then
    coroutine.wait( len / speed )
  else
    coroutine.wait( (len * dm) / speed )
  end
end

function ENT:PlaySequenceAndWaitE( name, speed, dm, len )
	self:PlaySequenceAndWait( name, speed, dm, len )
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

function ENT:TriggerRemoteAPP()
  if ( self.AssemblyInProgress == true ) then
    self:SetInterrupt("asmpp")
  end
  
  self:AssignTimedTaskH("AssemblePatrolPoints"..tostring(SysTime())..tostring(v), self.TimedTasks, function(s)

    s:AssemblePatrolPoints()
    
    return false
  end, 0)
end

function ENT:SetPPRebuild(v)	
	self:SetPPDensity(v)
	self:TriggerRemoteAPP()	
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
	
	--self:SayToOwner(self:EntIndex(), " Generating patrol points.." )
	
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
			table.insert(self.PatrolPoints ,pos)
		end
		
		coroutine.yield()
	end
	
	--self:SayToOwner(self:EntIndex(), " "..#self.PatrolPoints.." patrol points found" )

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
	
	
	if ( tdist > dist ) then
		return true
	end
	
	
	local pseg = self.path && self.path:GetCurrentGoal()
	
	if ( UseAllowed(subject) ) then
		subject.nixbot_last_used = os.time()	
		subject:Use(self, self, USE_TOGGLE, 0)
	end

	local dv = (spos - pos):Angle()
	dv.yaw = dv.yaw + (90 - math.random(0, math.Clamp(tdist,0, 45) ) ) *
					((math.random(1,2)*2)-3)

	local path = self.path
	tdist = dist * 1.45
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
			
			while ( self:Alive() ) do		
				self:ClearInterrupts()
				
				--self:UpdateRanks()								
				if ( IsValid(self.Weapon) && 
					self.Weapon:Clip1() < clip_reload_threshold ) then
					self:DoReload()
				end
								
				local wto = 2
				
				self:ProcessTask(self.PrioTasks)   
				
				if ( self:HaveEnemy()  ) then
					self.loco:FaceTowards( self:GetEnemy():GetPos() )	
					self:StartActivityE( self:GetAnimAct("RunChase"), self:GetStatsRunspeed(), self:GetStatsAccel() )								
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
	
	if ( !rt ) then
  	timer.Simple( dur , function()
  		if ( IsValid(self) ) then
  			self.CurrentActivity = nil
  		end
  	end)
  end
	
	return dur
end

function ENT:GiveAmmo(amount, id)
	local ammo = self.dump.Ammo[id]			
	self.dump.Ammo[id] = ammo != nil && ammo + amount || amount
end

function ENT:GetAmmoCount(id)
	return self.dump.Ammo[id] || 0
end

function ENT:GetCarryMass()
  return self.CarryMass
end

function ENT:Give(class, t, item)
  local mass

  if ( IsValid(item) ) then
    mass = item:GetPhysicsObject():GetMass()
  else
    mass = 0
  end
  
  local newmass = self.CarryMass + mass
    
  if ( newmass > self:GetStatsMaxCarryWeight() ) then
    return false
  end
  
  self.CarryMass = newmass

  if (!self.dump[t]) then
  	self.dump[t] = {}
  end
  
  if ( !self.dump[t][class] ) then
    self.dump[t][class] = {}
  end
  	
  local data = self.dump[t][class]
  
  data.mass = mass 
  	
  if ( data.count == nil ) then	
  	data.count = 1
  else
  	data.count = math.Clamp(data.count + 1, 1, 100000)
  end				
  
  return true
end

function ENT:HasItem(t, class)
  if ( !self.dump[t] ) then
    return false
  end
  
  local data = self.dump[t][class]
  
  if ( !data ) then
    return false
  end
  
	return (data.count && data.count > 0) && true || false
end

function ENT:GetItemCount(t, class)
  if ( !self.dump[t] ) then
    return 0
  end
  
  local data = self.dump[t][class]
  
  if ( !data ) then
    return 0
  end
  
  return data.count && data.count || 0
end

function ENT:PopItem(t, class, c)
	if ( !self.dump[t] ) then
		return false
	end
	
	local data = self.dump[t][class]
	
	if ( nil == data || nil == data.count || data.count == 0 ) then
		return false
	end
	
	local take = math.Clamp(c || 1,1,data.count)
	
	data.count = data.count - take
	
	self.CarryMass = self.CarryMass - (data.mass * take)
	
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

function ENT:DropItem(t, class, pos, count)
  local c = self:PopItem(t, class, count)
  
  if ( c == false ) then
    return 0
  end
  
  local i
  local dropped = 0
  
  for i=1,c do 
    local ent = ents.Create(class)
    
    if ( ent ) then
      ent:Spawn()      
      ent:SetPos(pos)
      dropped = dropped + 1
    end
  end
  
  return dropped  
end

function ENT:PickupItem(item)
  
  if ( !self:Give(item:GetClass(), type(item), item) ) then
    return false
  end
  
	self.LastPickup = item
	
	if ( type(item) == "Weapon" ) then
		self:GiveAmmo(item:Clip1(), item:GetPrimaryAmmoType())
		--self:SelectWeapon(item:GetClass())
		self:RunHook("PickupWeapon", item)			
	elseif ( type(item) == "Entity" ) then
		if (item.AmmoType) then
			self:GiveAmmo(item.AmmoAmount || item.AmmoMax || 10, item.AmmoType)
		elseif ( item:GetClass() == "item_healthkit" ) then
		  self:Heal()
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
	
		if ( !IsValid(v) || !self:CheckValidPickup(v) ) then
			continue
		end
		
		if ( v:IsWeapon() && 
			v:Clip1() == 0 && self:HasItem(type(v), v:GetClass() ) 
			  	  ) then
			continue
		end
		
		self:Goto(v:GetPos(), {
			noint = true, notask = true, tolerance = 10,
			cond = function() 
			  if ( !IsValid(v) ) then return false end 
			  
			  local pseg = self.path:GetCurrentGoal()
       
        if ( !pseg ) then
          return 
        end
        
        if ( pseg.distanceFromStart > self:GetStatsVisRange() / 6 ) then   
          return false
        end
			end
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
	self:SetPickupItems(b)
end

ENT.SetEnableItemPickup = ENT.EnableItemPickup

function ENT:EnableSupplyAllies(b)
  if ( b == true ) then
    self:AssignTimedTask("SupplyAllies", self.TimedMovementTasks, 1)
    self:AssignTimedTask("SupplyAllies", self.TimedTasks, 1)
  elseif ( b == false ) then
    self:RemoveTimedTask("SupplyAllies", self.TimedMovementTasks)
    self:RemoveTimedTask("SupplyAllies", self.TimedTasks)
  end
  self:SetSupplyAllies(b)
end

ENT.SetEnableSupplyAllies = ENT.EnableSupplyAllies

function ENT:FlankEnemy()  
  if ( !RollDice(25) ) then
    return
  end

  if ( !self:HaveEnemy() || !self:EnemyVisible() ) then
    return
  end
  
  local enemy = self:GetEnemy()
  
  if ( !self:VisibleToTarget(enemy) ) then
    return
  end
    
  local pos = enemy:GetPos() + enemy:OBBCenter()  
  local dist = self:GetPos():Distance(pos)
  
  if ( dist > self:GetStatsTFRange() ) then
    return
  end
  
  local srand = ((math.random(1,2)*2)-3)
  
  local pos1 = pos + enemy:GetRight() * (dist * srand)
  
  if ( !util.IsInWorld(pos1) ) then
    return
  end
       
  local opts = {
     notask = true, maxage = 6, 
     force = true, attack = true,
     tolerance = 75,
     activity = self:GetAnimAct("RunChase"),
     speed = self:GetStatsRunspeed(),
     accel = self:GetStatsAccel(),
     cond = function(self) 
       if ( !self:HaveEnemy() ) then
         return false
       end
       
       local pseg = self.path:GetCurrentGoal()
       
       if ( !pseg ) then
         return 
       end
       
       if ( pseg.distanceFromStart > dist * 2 ) then   
         return false
       end
     end
   }
  
  local r1, r2 = self:Goto(pos1, table.Copy(opts))
  
  if ( !IsValid(enemy) ) then
    return
  end
  
  if ( r2 ) then
    pos = enemy:GetPos() + enemy:OBBCenter()
    dist = self:GetPos():Distance(pos)
  
    if ( dist > self:GetStatsTFRange() ) then
      return
    end
    
    pos1 = pos + -enemy:GetForward() * dist 
  
    if ( !util.IsInWorld(pos1) ) then
      return
    end
  
    self:Goto(pos1, table.Copy(opts))
  end
  
end

function ENT:RunBehaviour()

	--MovementDiscovery(self, "shoot")
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
		
	
	self.loco:SetJumpHeight((self.Options.Stats.Athletics + self.Options.Stats.Agility / 8) * 255)
				
	self:AssignTimedTask("ContinuousAlertNeighbors", self.TimedCombatTasks, 1)
	self:AssignTimedTask("AutoEvade", self.TimedCombatTasks, 0.2)
	self:AssignTimedTask("UpdateRanks", self.TimedCombatTasks, 2)
	self:AssignTimedTask("DecreaseEnemyTensionsStep", self.TimedCombatTasks, 5)
	self:AssignTimedTask("FlankEnemy", self.TimedCombatTasks, 10)
	
	self:AssignTimedTask("AutoEvade", self.TimedMovementTasks, 0.2)
	self:AssignTimedTask("UpdateRanks", self.TimedMovementTasks, 2)
	self:AssignTimedTask("DecreaseEnemyTensionsStep", self.TimedMovementTasks, 5)	
		
	self:AssignTimedTask("DecreaseEnemyTensionsStep", self.TimedTasks, 5)	
	
		
	self.loco:SetStepHeight(50)
	self.loco:SetDeathDropHeight(400)
	self.loco:SetDeceleration(self.Stats.Decel)
		
	self:AssemblePatrolPoints()

	self.MovTypeProc[3] = function(self, seg) 
		self:Debug(self:EntIndex(), " jumping across gap")
	end
	
	self.MovTypeProc[2] = function(self, seg) 
		if ( self.pseg_type_l != 0 && !self.loco:IsClimbingOrJumping() ) then			
			local dir = (seg.pos - self:GetPos()):GetNormalized()
			self.loco:SetVelocity(dir * 150)
			self.loco:Jump()
			--self:Debug(self:EntIndex(), " jumping")
			self:PlaySequenceAndWaitE( "jump_holding_jump" )
		end
	end
	
	self.MovTypeProc[1] = function(self) 
		if ( self.pseg_type_l != 1 ) then
			self:PlaySequence( "jump_holding_glide" )
			--self:Debug(self:EntIndex(), " falling")
		end
	end
	
	self.MovTypeProc[0] = function(self) 
		if ( self.pseg_type_l == 1 ) then
			self:PlaySequence( "jump_holding_land" )
			--self:Debug(self:EntIndex(), " landed")
		end
	end
	
	--self:Debug(self:EntIndex(), " Initialization complete")
	
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
	self:PlaySequence(self.CurrentShootSeq, 1, true)		
	self.CurrentActivity = nil
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
	return self:DischargeBurst(...) 				
end

function ENT:DischargeBurst (enemy, count, path)

	if ( !IsValid(self.Weapon) || os.time() - self.LastBurst < math.Rand(0.5,2)  ) then
		self:AimAt(self.last_bone && self:CalculateEnemyHitpos(enemy, self.last_bone) || self:GetPos() + self:GetForward() * 400 )  
		return false
	end
	
	if ( self.Weapon:Clip1() == 0 ) then
		self:DoReload()
		if ( !IsValid(enemy) ) then		
		  self:AimAt(self:GetPos() + self:GetForward() * 400 )    
			return false
		end
	end
	
	local tbone = GetRandomHitboxBone(enemy)			

	if ( !tbone ) then	 
	  self:AimAt(self.last_bone && self:CalculateEnemyHitpos(enemy, self.last_bone) || self:GetPos() + self:GetForward() * 400 )   
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
	  local ep = enemy:GetPos()
		self.loco:FaceTowards(ep )
		
		local av = self:CalculateEnemyHitpos(enemy, tbone)
		
		self:SetAimVector((av - self:GetAimOffset(enemy)) - self:GetShootPos()) 
		self:AimAt(av)
		
		if ( self:GetPos():Distance(ep) < 50 ) then
		  self:MeleeAttack(av, enemy)
		  return true
		else		  
		  self.Weapon:PrimaryAttack()
		end
		
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
		filter = function(ent) if ( ent != target && (ent:GetParent() == self || ent:IsNPC() || ent:IsPlayer())	) then return false else return true end end
	} )
	
	return tr.Entity
end

function ENT:EnemyVisible()
	local enemy = self:GetEnemy()
	
	if ( !IsValid(enemy) ) then
		return false
	end
	
	return self:TargetVisible(enemy)
end

function ENT:TargetVisible(ent)
  if ( !self:IsInCone( ent:GetPos() + ent:OBBCenter(), self:EyePos(), self:EyeAngles():Forward(), self:GetStatsVisRange(), 1.396263402) ) then
    return false
  end
  
  return self:GetEyeTrace(ent) == ent
end

function ENT:VisibleToTarget(ent)
  local range
  
  if ( ent:IsNixBot() ) then
    range = ent:GetStatsVisRange()
  else
    range = 5000
  end
  
  return self:IsInCone( self:GetPos() + self:OBBCenter(), ent:EyePos(), ent:EyeAngles():Forward(), range, 1.396263402)
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
		self:Debug(self:EntIndex(), " stuck, using", ent)	
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
	
	if ( self:GetVelocity():Length2D() > 25 && 
	     self.stuck_counter == 0 ) then
	  return true
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
		
		self:Debug(self:EntIndex(), " stuck")
		
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

  options.speed = options.speed or self:GetStatsWalkspeed()
	options.accel = options.accel or self:GetStatsAccel()
	
	local actopts = {options.activity or self:GetAnimAct("Walk"), 
							options.speed, 
							options.accel  }
								
	--self.CurrentActivity = nil
	
	options.tolerance = options.tolerance or 25
	
	local path = Path( "Follow" )
	self.path = path
	path:SetMinLookAheadDistance( options.lookahead or 750 )
	path:SetGoalTolerance( options.tolerance )
	path:Compute( self, loc )	
	
	options.maxage = options.maxage || 900

	if ( !path:IsValid() ) then 
		self:Debug(self:EntIndex(), " goto: invalid path")
		return false 
	end
	
	local lset = {
	   loc = loc
	}
		
	local fseg = path:FirstSegment()
		
	while ( path:IsValid() && (options.force || !self:HaveEnemy()) ) do
			
		if ( path:GetAge() > options.maxage ) then
			break
		end
								
		if ( self:Interrupt() && options.noint != true ) then
			self:Debug(self:EntIndex(), " interrupting patrol")
			break
		end
		
		if ( options.cond && options.cond(self, lset, options.cond_data) == false ) then
			break
		end
		
		if ( self:GetBusyTimeout() > RealTime() ) then
			coroutine.yield()
			continue
		end
			
		if ( !options.notask ) then
			if ( self:ProcessTimedTasks(self.TimedMovementTasks, path) ) then	
								
				if ( !path:IsValid() ) then		
					path:Compute(self, lset.loc)
					coroutine.yield()
					continue
				end
								
							
				self.path = path					
			end
		end
		
		local pseg = path:GetCurrentGoal()
		
		if ( pseg) then
			if ( pseg.area:IsUnderwater() && !fseg.area:IsUnderwater() ) then
				self:ComputePath(path, lset.loc)
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
				path:Compute(self, lset.loc)
			end
		end
				
		--[[if ( path:GetAge() > 10 ) then
			path:Compute(self, loc)
		end]]
		path:Update( self )   
		
		if ( options.attack && self:HaveEnemy() &&
				self:GetRangeTo( self:GetEnemy():GetPos()  ) < self:GetStatsTFRange() &&
				self:EnemyVisible()) then 
			
			self:StartActivityE( self:GetAnimAct("RunChase"), options.speed, options.accel )
			local enemy = self:GetEnemy()
			self.loco:FaceTowards(enemy:GetPos())	
			if ( self:DischargeBurstNoAnim(enemy, math.random(unpack(self.BurstRC)), path) == false ) then
			  self:AimAt(self:GetPos() + self:GetForward() * 400 ) 
			end
		else
		  self:StartActivityE( unpack(actopts) )
		  self:LookIdle()
		end
		
	
			
		coroutine.yield()
	end	
		
	if ( self:GetRangeTo( lset.loc ) <= options.tolerance + 25 ) then
		self:RunHook("GotoArrived", options)
		return true, true
	else
		self:RunHook("GotoFailed", options)		
	end
	
	return true
end


function ENT:SetFollowTarget(target)	
	if ( IsValid(target) && (target:IsPlayer() || target:IsNPC()) &&
		(self:GetRelationship(target) < NIXBOT_RELATION_FRIEND) 
			) then
		return false
	end
	self.FollowTarget = target
	self:SetFollow(target)
	return true
end

function ENT:GetFollowTarget()
	return self.FollowTarget
end

ENT.GetRunSpeed = ENT.GetStatsRunspeed
ENT.GetWalkSpeed = ENT.GetStatsWalkspeed

function ENT:Follow (options)
  local target = self.FollowTarget
  
	if ( !IsValid(target) ||
	     self:GetRelationship(target) < NIXBOT_RELATION_FRIEND ||
	     !target:Alive() ) then
		return false
	end

	local options = options or {}
	
	options.tolerance = options.tolerance or 250
			
	self.loco:FaceTowards(target:EyePos() )	
	local dv = self:LookAt(target:EyePos() )
	
	if ( self:GetPos():Distance(target:GetPos()) < options.tolerance ) then
		if ( !self.follow_idle_time ) then
			self.follow_idle_time = os.time()
			self.follow_idle_timeout = math.random(160,240)
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
	path:SetMinLookAheadDistance( options.lookahead or 650 )
	path:SetGoalTolerance(  options.tolerance  )
	
	path:Compute(self, target:GetPos())
	
	if ( !path:IsValid()  ) then
		return
	end
	
	local dtol = 50
	local dstate = 500
	
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
				self:Debug(self:EntIndex(), " target ", target, " lost")
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
		local walk
				
		if ( math.abs(dstate - dist) > dtol ) then
  		dstate = dist
  		if ( dist > 500 ) then
  			self:StartActivityE( self:GetAnimAct("Run"), math.Clamp(target:GetRunSpeed() , 0, self:GetStatsRunspeed()), self:GetStatsAccel() )	
  		else
  			self:StartActivityE( self:GetAnimAct("Walk"), math.Clamp( target:GetWalkSpeed() , 0, self:GetStatsWalkspeed()), self:GetStatsAccel() )	
  			walk = true
  		end	
  	end	
		
		if ( walk ) then
		  self.loco:FaceTowards(target:EyePos() ) 
      self:LookAt(target:EyePos())
    end
		
		coroutine.yield()
	end	
	
	return true
end

function ENT:MeleeAttack(hitpos, target)
  local tr = util.TraceLine { start = self:EyePos(), endpos = hitpos, mask = MASK_SOLID, filter = {self, self.Weapon} }
    
  if ( IsValid(tr.Entity) ) then
    local atspeed = 1 - self:GetStatsAthletics()
    self:PlaySequenceAndWaitE( "MeleeAttack01", atspeed, 0.5 )
    
    if ( self:GetPos():Distance(target:GetPos()) > 50 ) then
      tr = util.TraceLine { start = self:EyePos(), endpos = hitpos, mask = MASK_SOLID, filter = {self, self.Weapon} }
      
      if ( !IsValid(tr.Entity) ) then
        return
      end
    end
    
    local info = DamageInfo()
    info:SetAttacker( self )
    info:SetInflictor( self )
    info:SetDamage( 42 ) 
    info:SetDamageType( bit.bor( DMG_BULLET , DMG_NEVERGIB ) )  
  
    tr.Entity:DispatchTraceAttack( info, tr, tr.HitNormal )
  
    return true
  end

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

	self.target_last_seen = os.time()
	
	local tlost_c = 0
	local times_attacked = 0
	
	local base_attack_distance = math.Round(self:GetStatsTFRange() * 
			(( (self:GetEnemy():OBBMaxs() - self:GetEnemy():OBBMins()):LengthSqr() / 5625) ^ 1.5))
	
	local session_attack_distance = base_attack_distance
	local min_closein_dist = base_attack_distance / 4
	
	self.target_pos = self:GetEnemy():GetPos() 
	self:AimAt(self:GetPos() + self:GetForward() * 400 )  
	
	local path_max_age = 0.4
	
	local p_target_pos = Vector(0,0,0)
	local recompute_path = true
	
	self:SetMood(NIXBOT_MOOD_AGITATED)
	self.attack_event_act = self:GetAnimAct("ShootStand") 
	
	local last_enemy = enemy
	
	while ( path:IsValid() && self:HaveEnemy() && 
	        !self:Interrupt("combat") ) do
	
		if ( self:GetBusyTimeout() > RealTime() ) then
			coroutine.yield()
			continue
		end
				
		if ( self:ProcessTimedTasks(self.TimedCombatTasks, path) ) then
			self.path = path
			
			if (!self:HaveEnemy()) then			
				break
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
			self.target_pos = enemy:GetPos() 
			--self:AimAt(self.target_pos)				
		else
			
			if ( self:CalculateCognitionScore(enemy ) 
					> self:GetStatsAwareness()) then
				self.target_last_seen = os.time()
				self.target_pos = enemy:GetPos() 	
				--self:AimAt(self.target_pos) 				
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
				self:Debug(self:EntIndex(), " wont go underwater")
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
			else
			  
			end	
			
		elseif ( target_visible == false ) then
			if ( dist > 25 ) then
				self:StartActivityE( self:GetAnimAct("RunChase"), self:GetStatsRunspeed(), self:GetStatsAccel() )		
			else
				self:StartActivityE( self.attack_event_act, 0, 0 )
			end
			
			self:AimAt(self:GetPos() + self:GetForward() * 400 )  
	
			if ( os.time() - self.target_last_seen > 45) then		
				self:Debug(self:EntIndex(), " target escaped")
				break
			end
		elseif ( dist >= min_closein_dist ) then
			
			local scoped = self:GetActiveWeapon():IsScoped()
			
			if ( dist < base_attack_distance && !scoped ) then			
			  self.loco:FaceTowards(enemy:GetPos() ) 		
				self:StartActivityE(self:GetAnimAct("WalkAim"), 75, self:GetStatsAccel())			
				self:DischargeBurstNoAnim(enemy, math.random(unpack(self.BurstRC)), path) 				
			else
				self:StartActivityE( self:GetAnimAct("RunChase"), self:GetStatsRunspeed(), self:GetStatsAccel())			
				if ( dist < 4000 && !scoped && RollDice(5) ) then			
				  self.loco:FaceTowards(enemy:GetPos() ) 		
					if ( self:DischargeBurstNoAnim(enemy, math.random(unpack(self.BurstRC)), path) == false ) then
              
          end
				else
					self:AimAt(self:GetPos() + self:GetForward() * 400 )   
				end
			end
			
		else			
		  self:AimAt(self:GetForward() * 400 )  
			session_attack_distance = base_attack_distance
		end
		
		if ( !self:ResolveStuck() ) then
			self.CurrentActivity = nil 
		end		
		
		if ( options.draw ) then path:Draw() end
			
		coroutine.yield()
	end
		
	self:SetMood(NIXBOT_MOOD_STIMULATED)

  if ( !IsValid(self:GetEnemy()) ) then
    self:RunHook("LostEnemy", options)
    self:SetEnemy( nil )
	elseif ( !self:HaveEnemy()) then
	  self:RunHook("LostEnemy", options)
		self:Debug(self:EntIndex(), " target gone")	
		self:SetEnemy( nil )
		return false
	elseif ( !path:IsValid() ) then
		self:Debug(self:EntIndex(), " invalid path")	
		self:SetEnemy( nil )
	end

	--self:SetEnemy( NULL )
	
	return true
end

util.AddNetworkString("NIXBOT.net.plyctl")

local AllowedPCFunctions = {
	["Patrol"] = true,
	["Interrupt"] = true,
	["FollowTarget"] = true,
	["PPDensity"] = true,
	["PPRebuild"] = true,
	["EnableItemPickup"] = true,
	["EnableSupplyAllies"] = true
}

net.Receive("NIXBOT.net.plyctl", function(len, ply)
	local t = net.ReadTable()
	
	local nb = t.e
	local arg = t.a

	if ( !isstring(t.n) || !istable(arg) || !IsValid(nb) || 
			 !isentity(nb) || !nb:IsNixBot() || nb:CPPIGetOwner() != ply  ) then
		return
	end
	
	if ( !AllowedPCFunctions[t.n] ) then
		return
	end
		
	local fp = nb["Set"..t.n]
		
	if ( !isfunction(fp) ) then
		return
	end
	
	fp(nb, unpack(arg) )
end)