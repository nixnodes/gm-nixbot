AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= false

ENT.NixBot = true
--ENT.Name = "NixBot Base"

ENT.Type = "nextbot"
--ENT.AutomaticFrameAdvance = true
ENT.DisableDuplicator = true

include "sounds_female.lua"
include "sounds_male.lua"

hook.Add("EntityFireBullets", "NX.m.fb", function (ent, data)
	if ( ent:IsPlayer() || ent:IsNPC() || ent.NixBot ) then
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
  
  meta = FindMetaTable("Player")
  
  function meta:IsNixBot()
    return false
  end
  
  local meta_npc = FindMetaTable("NPC")
  
  function meta_npc:IsNixBot()
    return false
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
	
end

if ( CLIENT ) then


	--[[hook.Add("HUDPaint", "lalalal2", function()

		local seqinfo, textpos = nil, nil

		local _ents = ents.FindInSphere(Vector(0,0,0), 100000)
		
		
		for p, ply in pairs( _ents ) do
			if ( ply:IsNPC() ) then 
				seqinfo = ply:GetSequenceInfo( ply:GetSequence() )
				textpos = ( ply:GetPos() + Vector( 0, 0, seqinfo.bbmax.z + 10 ) ):ToScreen()

				if ( textpos.visible ) then
					draw.SimpleText( seqinfo.label, "GModNotify", textpos.x, textpos.y, color_white, TEXT_ALIGN_CENTER )
					draw.SimpleText( seqinfo.activity..": "..seqinfo.activityname, "GModNotify", textpos.x, textpos.y+20, color_white, TEXT_ALIGN_CENTER )
				end
			end
		end

	end)

	hook.Add("HUDPaint", "lalalal", function()
		local seqinfo, textpos = nil, nil

		local _ents = ents.FindInSphere(Vector(0,0,0), 100000)
		
		for p, ply in pairs( _ents ) do
			if ( ply.NixBot ) then 
		
				--seqinfo = ply:GetSequenceInfo( ply:GetSequence() )
				textpos = ( ply:GetPos() + ply:GetUp() * 90 ):ToScreen()

				if ( textpos.visible ) then
					draw.SimpleText( "rank: "..ply:GetNWFloat("nb_rank"), "GModNotify", textpos.x, textpos.y, color_white, TEXT_ALIGN_CENTER )	
					draw.SimpleText( "acc: "..ply:GetNWFloat("nb_acc"), "GModNotify", textpos.x, textpos.y - 20, color_white, TEXT_ALIGN_CENTER )			
					
				end
			
			end

		end

	end)
]]
end
