AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= false

ENT.NixBot = true

ENT.Type = "nextbot"
ENT.DisableDuplicator = true

include "sounds_female.lua"
include "sounds_male.lua"

hook.Add("EntityFireBullets", "NX.m.fb", function (ent, data)
	if ( ent:IsPlayer() || ent:IsNPC() || ent:IsNixBot() ) then
		ent:SetNWFloat("LastShootTime", RealTime())		
	elseif ( ent:IsWeapon() ) then
		if ( IsValid(ent.Owner) ) then
			ent.Owner:SetNWFloat("LastShootTime", RealTime())
		elseif ( IsValid(ent:CPPIGetOwner() ) ) then
			ent:CPPIGetOwner():SetNWFloat("LastShootTime", RealTime())		
		end
	end
end)


do

  local meta = FindMetaTable("Entity")
  
  function meta:IsNixBot()
    return self.NixBot == true
  end
  
  if ( !meta.CPPIGetOwner ) then
    function meta:CPPIGetOwner()
      return NULL
    end
  end
  
  if ( !meta.CPPISetOwner ) then
    function meta:CPPISetOwner()
      return NULL
    end
  end
  
  meta = FindMetaTable("Player")
  
  function meta:IsNixBot()
    return false
  end
  
  local meta_npc = FindMetaTable("NPC")
  
  function meta_npc:IsNixBot()
    return false
  end
  
  meta = FindMetaTable("NextBot")
  
  if ( meta ) then
    function meta:IsNPC()
      return true
    end       
  end
  
end

if (SERVER ) then
	include "server.lua"
else
	function ENT:Initialize()
		self:SetModel( self.Model )
		self:SetCollisionGroup(COLLISION_GROUP_NPC_SCRIPTED)
		
	end
	
	function ENT:SendCommand(v, d)
		local t = {
			e = self,
			n = v,
			a = {d}
		}
		
		net.Start("NIXBOT.net.plyctl")
		net.WriteTable(t)
		net.SendToServer()
	end
	
end

function ENT:SetupDataTables()

	self:NetworkVar( "Bool", 0, "Patrol" )
	self:NetworkVar( "Entity", 0, "Follow" )
	self:NetworkVar( "Float", 0, "PPDensity" )
	self:NetworkVar( "Bool", 1, "PickupItems" )
	self:NetworkVar( "Bool", 2, "SupplyAllies" )
	self:NetworkVar( "Bool", 3, "Retreating" )
	
end
