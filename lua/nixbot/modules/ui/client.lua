
local PANEL = {}

function PANEL:Load()
	local base = vgui.Create( "DScrollPanel", base_plugin )
	base:MakePopup()
	base:ParentToHUD()
	
	base:SetFocusTopLevel( true )

	local w =  333
	local h = ScrH() / 2
	
	base:SetSize( w, h )
	base:SetPos(100,(ScrH() / 2) - h / 2)
					
	local op = base.Paint
			
	base.Paint = function(s, w, h)
		draw.RoundedBox(5, 0, 0, w , h, Color(45,45,45) )
	end
	
	local ent = self._target
	
	local general_opts = self:CreateCollapsibleCat(tostring(ent), base, 1)
			
	local opt = self:CreateCheckField(general_opts, "patrol", "Patrol area", function(s, bval) 
		if ( IsValid(ent) ) then 
			ent:WriteVar("Patrol", bval) 
			if ( bval == false ) then
				ent:WriteVar("Interrupt") 
			end
		end
	end, ent:GetPatrol() ) 	
	opt:Dock(TOP)
	
	opt = self:CreateCheckField(general_opts, "follow_me", "Follow me", function(s, bval) 
		if ( IsValid(ent) ) then		
			if ( bval == true ) then
				ent:WriteVar("FollowTarget", ent:CPPIGetOwner() ) 	
				ent:WriteVar("Interrupt") 
			elseif ( IsValid(ent:GetFollow()) && 
					 ent:GetFollow() == ent:CPPIGetOwner() ) then
				ent:WriteVar("FollowTarget", nil ) 
			end
		end
	end, ent:GetFollow() == ent:CPPIGetOwner() ) 	
	
	opt:Dock(TOP)

	local lid = LocalPlayer():UniqueID()
	
	opt = self:CreateSingleSlider(general_opts, function(s, val) 
		timer.Create("N_"..lid.."_APP", 1, 1, function()		
			if ( IsValid(ent) ) then		
				ent:WriteVar("PPRebuild", tonumber(val) ) 			
			end
		end)
	end,ent:GetPPDensity(), "PP Density", "ppd", 100, 2000, 1 ) 	
	
	opt:Dock(TOP)
	
	return base
end

function MODULE:_PostLoad()
	PANEL = setmetatable(PANEL, {__index=self.derma._default})
	
	local p = setmetatable({}, {__index=PANEL})
	
	self._panel = p
	
	hook.Add("OnContextMenuOpen", "NIXBOT.ui.ctx_open", function()

		local e = LocalPlayer():GetEyeTrace().Entity
			
		if ( !IsValid(e) || !e:GetClass():match("^nixbot_") || 
				e:CPPIGetOwner() != LocalPlayer() ) then return end
		
		p._target = e
		p._base = p:Load()
	end)
	
	hook.Add("OnContextMenuClose", "NIXBOT.ui.ctx_close", function()
		if ( IsValid(p._base) ) then
			p._base:Remove()					
		end
	end)
	
end