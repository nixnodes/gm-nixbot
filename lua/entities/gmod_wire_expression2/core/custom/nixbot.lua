E2Lib.RegisterExtension("nixbot", false)

local function ToVector(v)
	return Vector(v[1],v[2],v[3])
end

local function ExecuteEvent(self, bot, clk)
	if ( !IsValid(self.entity) ) then
		return
	end
	self.LastBot = bot
	self[clk] = 1
	self.entity:Execute()
	self[clk] = 0
end

local function Notify(ply, msg)
  ply:SendLua( 'hook.Run("NIXBOT.notify.player","' .. msg .. '")' )
end

e2function entity nbCreate(string class)
	if ( !class || !IsValid(self.player) || 
		hook.Run("PlayerSpawnNPC", self.player, class, nil ) == false ) then
		return NULL
	end
	
	local bot = ents.Create( class )
	
	if ( !IsValid(bot) ) then
		return NULL
	end
		
	if ( self.NB_SPC / math.Clamp(RealTime() - self.NBLastSpawned, 1, 5) >= 5 ) then
	  Notify(self.player, "NB spawn/time limit exceeded")
    return NULL
	end 
	
	self.NB_SPC = self.NB_SPC + 1	
	self.NBLastSpawned = RealTime()
	
	bot:CPPISetOwner(self.player)	
	local index = bot:EntIndex()
	self.RegisteredNBs[index] = bot
	bot.E2Controller = self
	
	bot:Spawn()
	bot:SetPos( self.entity:GetPos() + Vector(math.random(-1,1), math.random(-1,1), 0 ) * 20 )
						
	bot:RegisterHook("OnKilled", function()
		ExecuteEvent(self, bot, "CLK_Killed")
	end)
	
	bot:RegisterHook("OnOtherKilled", function(s, victim)
		self.LastKilled = victim
		ExecuteEvent(self, bot, "CLK_OnOtherKilled")
	end)
	
	bot:RegisterHook("DetectEnemy", function()
		ExecuteEvent(self, bot, "CLK_DetectEnemy")			
	end)
	
	bot:RegisterHook("EngageEnemy", function()
		ExecuteEvent(self, bot, "CLK_EngageEnemy")			
	end)
	
	bot:RegisterHook("LostEnemy", function()
		ExecuteEvent(self, bot, "CLK_LostEnemy")			
	end)
	
	bot:RegisterHook("GotoArrived", function(s, options)
		if ( options.e2docb ) then
			ExecuteEvent(self, bot, "CLK_GotoArrived")	
		end
	end)
	
	bot:RegisterHook("PickupWeapon", function(s, item)
		self.LastPickup = item
		ExecuteEvent(self, bot, "CLK_PickupWeapon")			
	end)
	
	bot:RegisterHook("Used", function(s, caller)	
		self.LastUser = caller
		ExecuteEvent(self, bot, "CLK_Used")			
	end)
	
	bot:RegisterHook("Initialized", function()
		ExecuteEvent(self, bot, "CLK_Initialized")				
	end)
	
	hook.Run("PlayerSpawnedNPC", self.player, bot )
		
	return bot
end

e2function number nbKilledClk()
	return self.CLK_Killed
end

e2function number nbInitClk()
	return self.CLK_Initialized
end

e2function number nbEnemyDetectedClk()
	return self.CLK_DetectEnemy
end

e2function number nbEngageEnemyClk()
	return self.CLK_EngageEnemy
end

e2function number nbLostEnemyClk()
	return self.CLK_LostEnemy
end

e2function number nbGotoArrivedClk()
	return self.CLK_GotoArrived
end

e2function number nbEnemyKilledClk()
	return self.CLK_OnOtherKilled
end

e2function number nbPickupWeaponClk()
	return self.CLK_PickupWeapon
end

e2function number nbUsedClk()
	return self.CLK_Used
end
	

e2function entity lastBot()
	return self.LastBot
end

e2function entity lastKilled()
	return self.LastKilled
end

e2function entity lastPickup()
	return self.LastPickup
end

e2function entity lastUser()	
	return self.LastUser
end

local function ValidateNixBot(self, bot)
	if ( bot:CPPIGetOwner() == self.player && 
			IsValid(bot) && bot:IsNixBot() ) then
		return true
	end
	return false
end

e2function entity entity:getEnemy()
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	local enemy = this:GetEnemy()
	
	return IsValid(enemy) && enemy || NULL
end

e2function entity entity:haveEnemy()
  if ( !ValidateNixBot(self, this) ) then return 0 end
    
  return this:HaveEnemy() && 1 || 0
end

e2function number entity:setFollowTarget(entity target)
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	this:SetInterrupt()
	return this:SetFollowTarget(target) && 1 || 0
end

local function SetRelationship(self, target, disp, prio, persist)	
	if ( !IsValid(target) ) then return 0 end

	return self:SetRelationship(target, disp, prio, persist > 0 && true || false ) && 1 || 0
end

e2function number entity:setRelationship(entity target, number disp, number prio)
	if ( !ValidateNixBot(self, this) ) then return 0 end
	return SetRelationship(this, target, disp, prio, 0)
end

e2function number entity:setRelationship(entity target, number disp, number prio, number persist)
	if ( !ValidateNixBot(self, this) ) then return 0 end
	return SetRelationship(this, target, disp, prio, persist)
end

e2function number entity:setRelationship(entity target, string disposition, number prio)
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	local disp = _G[disposition]
	
	if ( !disp || !isnumber(disp) ) then return 0 end		
	
	return SetRelationship(this, target, disp , prio, 0)
end

e2function void entity:gotoPos(vector pos)
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	self:AssignTask(self.Tasks, self.Goto,{ToVector(pos), {e2docb=true} })
end

e2function void entity:doReload()
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	this:SetInterrupt()
	this:AssignTask(this.Tasks, this.DoReload,{})
end

e2function void entity:enableItemPickup(number switch)
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	this:EnableItemPickup(switch != 0 && true || false )
end

e2function void entity:enableSupplyAllies(number switch)
  if ( !ValidateNixBot(self, this) ) then return 0 end
  
  this:EnableSupplyAllies(switch != 0 && true || false )
end

e2function number entity:selectWeapon(string weap)
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	return this:SelectWeapon(weap) && 1 || 0
end

e2function void entity:setPPDensity(number density)
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	this:SetPPDensity(density)
end

e2function void entity:assemblePatrolPoints()
  if ( !ValidateNixBot(self, this) ) then return 0 end
  
  this:TriggerRemoteAPP()
end

e2function void entity:getPPCount()
  if ( !ValidateNixBot(self, this) ) then return 0 end
  
  return #this.PatrolPoints
end

e2function void entity:getCarryWeight()
  if ( !ValidateNixBot(self, this) ) then return 0 end
  
  return this:GetCarryMass()
end

e2function table entity:getWeapons()
	if ( !ValidateNixBot(self, this) ) then return 0 end
	local ret = {n={},ntypes={},s={},stypes={},size=0,istable=true}
	local size = 0
	
	for k,v in pairs(this.dump.Weapon) do
		size = size + 1
		ret.s[size] = k
		ret.stypes[size] = "s"
	end
	ret.size = size
	return ret
end

e2function table nbGetBots()
	local ret = {n={},ntypes={},s={},stypes={},size=0,istable=true}
	local size = 0
	
	for k,v in pairs(self.RegisteredNBs) do
		size = size + 1
		ret.s[size] = v
		ret.stypes[size] = "e"
	end
	ret.size = size
	return ret
end

e2function number entity:hasWeapon(string class)
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	return this:HasWeapon(class) && 1 || 0
end

e2function number entity:generatePPs()
	if ( !ValidateNixBot(self, this) ) then return 0 end
	
	return this:AssemblePatrolPoints() && 1 || 0
end



registerCallback("construct",function(self)
	self.RegisteredNBs = {}
	self.CLK_DetectEnemy = 0
	self.CLK_EngageEnemy = 0
	self.CLK_LostEnemy = 0
	self.CLK_Killed = 0
	self.CLK_OnOtherKilled = 0
	self.CLK_GotoArrived = 0
	self.CLK_Initialized = 0
	self.CLK_PickupWeapon = 0
	self.CLK_Used = 0
	self.LastBot = NULL
	self.LastKilled = NULL
	self.NBLastSpawned = RealTime()
	self.NB_SPC = 0
end)

registerCallback("destruct",function(self)
	for _,ent in pairs(self.RegisteredNBs) do
		if ( IsValid(ent) ) then
			SafeRemoveEntity(ent)
		end
	end
end)