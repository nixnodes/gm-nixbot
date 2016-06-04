
function MODULE:HandleMaximize(base)
	base.btnMaxim.DoClick = function()
		if ( base.IsMaximized != true ) then
			local x, y, w, h = base:GetBounds()			
			base._last_bounds = {x = x, y = y, w = w, h = h}			
			base:SetPos(0, 0)
			base:SetSize(ScrW(), ScrH())
			
			base.IsMaximized = true
		else
			local bounds = base._last_bounds
			base:SetPos(bounds.x, bounds.y)
			base:SetSize(bounds.w, bounds.h)
			base.IsMaximized = false
		end
	end
end

local DERMA = {}

function DERMA:CreateCollapsibleCat(title, parent, expanded)
	local res = vgui.Create( "DCollapsibleCategory", parent )											
	res:SetSize( 0, 75 )										
	res:SetExpanded( expanded )		
	res:Dock(TOP)
	res:DockMargin(10,7,10,0)
	res:SetLabel( title )	
	return res
end

function DERMA:CreateSingleSlider(parent, onchange, default, text, tag, min, max, dec)

	local fp_base = vgui.Create( "DPanel", parent )
	fp_base:Dock(TOP)
	fp_base:SetSize( 350, 20 )
	fp_base:DockMargin(0,5,0,5)
	fp_base.Paint = function() end
	
	
	local slider = vgui.Create( "DNumSlider", fp_base )
	fp_base.slider = slider
	slider:Dock(LEFT)
	slider:DockMargin(7,0,0,0)
	slider:SetSize( 300, 15 )
	slider:SetText( text )	
	slider:SetMin( min || 0 )				
	slider:SetMax( max || 10 )	
	slider:SetDecimals( dec || 0 )		
	
	slider:SetValue(default)
	
	slider.TextArea:SetTextColor(Color(255,255,255))
	slider.TextArea:SetFont("NX_Default2")
	slider.Label:SetFont("NX_Default2")
	
	if ( onchange != nil ) then
		slider.OnValueChanged = function(s, value)		
			onchange(s, value, self.base_module, tag )
		end
	end

	return fp_base
end

function DERMA:CreateSingleInputText(parent, onchange, default, text, section)

	local fp_base = vgui.Create( "DPanel", parent )
	fp_base:Dock(TOP)
	fp_base:SetSize( 435, 20 )
	fp_base:DockMargin(0,10,0,10)
	fp_base.Paint = function() end
	
		
	local label = vgui.Create( "DLabel" , fp_base)

	label:SetText(text || "")
	label:Dock(LEFT)	
	label:CenterVertical(  )
	label.Paint = function() end
	label:SetFont("NX_Default2")
	label:DockMargin(7,0,7,0)
	
	local textarea = vgui.Create( "DTextEntry", fp_base )
	fp_base.textarea = textarea
	textarea:SetFont("NX_Default2")
	textarea:Dock(LEFT)
	textarea:DockMargin(7,0,7,0)
	textarea:SetValue(default || "")
	textarea:SetSize( 400, 20 )
	
	fp_base.PerformLayout = function(s,w,h)		
		label:SizeToContents()
	end
	
	if ( onchange != nil ) then
		textarea.OnEnter = function()	
			onchange(textarea, textarea:GetValue(), self.base_module, section )
		end
	end
	

	return fp_base
end

function DERMA:CreateCheckField(parent, unique_tag, text, onchange, default)
	local base = vgui.Create( "DPanel", parent )
		
	base.Paint = function(s, w, h) 
		
	end
		
	local check = vgui.Create( "DCheckBox" , base)
	base.CheckBox = check
	
	check:AlignLeft(4)
	check:AlignBottom(2)
	check:SetValue( default )	
	
	if ( onchange != nil ) then
		check.OnChange = function(s, bVal)		
			onchange(s, bVal, self.base_module, unique_tag )
		end
	end
	
	
	local label = vgui.Create( "DLabel" , base)

	label:SetText(text)

	label:AlignLeft(25)
	label:AlignTop(7)
	label.Paint = function() end
	label:SetFont("NX_Default2")

	base.PerformLayout = function(s,w,h)
		local tx_w, tx_h = label:GetTextSize()				
		base:SetSize(tx_w + 30, 25)				
		label:SizeToContents()
	end
	
	label:SetMouseInputEnabled( true )
	
	function label:DoClick()
		check:Toggle()
	end
	
	
	return base
end

function DERMA:CreateColorSelector(parent, onchange, default, text, section)

	local BGPanel = vgui.Create( "DPanel", parent )
	BGPanel:SetSize( 250, 200 )
	BGPanel:DockMargin(5,10,0,0)
	BGPanel.Paint = function() end

	local color_label = Label( " "..(text || "").." ", BGPanel )
	color_label:SetPos( 5, 0 )
	
	color_label:SetSize( 115, 10 )
	color_label:SetHighlight( true )
	--color_label:SetColor( Color( 255, 255, 255 ) )
	color_label:SetFont("NX_Default2")
	color_label:Dock(LEFT)
	color_label:DockMargin(5,0,15,35)
	color_label:SizeToContents()
	
	local textarea = vgui.Create( "DTextEntry", BGPanel )

	textarea:SetFont("NX_Default2")
	
	textarea:SetText( istable(default) && 
			(default.r..", "..default.g..", "..default.b) ||
			"")
	textarea:SetSize( 105, 20 )
	textarea:SetPos( 5, 30 )
	
	local color_picker = vgui.Create( "DRGBPicker", BGPanel )
	--color_picker:SetPos( 5, 5 )
	color_picker:SetSize( 25, 0 )
	color_picker:Dock(LEFT)
	color_picker:DockMargin(0,0,0,1)
	
	local color_cube = vgui.Create( "DColorCube", BGPanel )
	--color_cube:SetPos( 40, 5 )
	color_cube:SetSize( 75, 125 )
	color_cube:Dock(LEFT)
	color_cube:DockMargin(5,0,0,0)
	
	function color_picker:SetColor( col, b )

		-- Get hue
		local h = ColorToHSV( col )

		-- Maximize saturation and vibrance
		col = HSVToColor( h, 1, 1 )

		-- Set color var
		self:SetRGB( col )

		-- Calculate position of color picker line
		local _, height = self:GetSize()
		self.LastY = height*( 1-( h/360 ) )

		-- Register that a change has occured
		self:OnChange( self:GetRGB(), b )

	end
			
	-- Updates display colors, label, and clipboard text
	local function UpdateColors( col, docb)
		
		BGPanel.SColor = Color( ( col.r ), ( col.g ), ( col.b ) )		
		color_label:SetColor( Color( ( 255-col.r ), ( 255-col.g ), ( 255-col.b ) ) )		
		textarea:SetText( col.r..", "..col.g..", "..col.b )

		if ( onchange && docb != false ) then
			onchange(s, col, self.base_module, section)
		end	
	end
	
	if ( istable(default) ) then
		UpdateColors( default, false )	
	end	
	
	color_label.Paint = function(s, w, h)
		local col = BGPanel.SColor
		
		surface.SetDrawColor(col.r, col.g, col.b)
		surface.DrawRect( 0,5, w, h -10 )
	end
	
	textarea.OnValueChange = function(s, value)	
		local r = string.Explode(",",value)
		if ( #r != 3) then
			return
		end
		
		for _,v in pairs(r) do		
			v = tonumber(v)
			if ( !isnumber(v) ) then
				return
			end
		end
		
		r = Color((r[1]), (r[2]), (r[3]))
		
		if ( !IsColor(r) ) then
			return
		end
		
		UpdateColors(r)
		color_cube:SetColor(r)		
		color_picker:SetColor(r)		
	end

	-- When the picked color is changed...
	color_picker.OnChange = function( s, col, b )
		local ocol = color_cube:GetRGB()
		
		if ( b != true && ocol.r == 0 && ocol.g == 0 && ocol.b == 0) then
			ocol = col
		end
		
		-- Get the hue of the RGB picker and the saturation and vibrance of the color cube
		local h = ColorToHSV( col )
		local _, s, v = ColorToHSV( ocol )

		-- Mix them together and update the color cube
		col = HSVToColor( h, s, v )
				
		color_cube:SetColor( col )
		
		-- Lastly, update the background color and label
		if ( b != true ) then
			UpdateColors( col )
		end
		
	end

	color_cube.OnUserChanged = function(s, col )
		UpdateColors( col )
		
		
	end
	
	BGPanel.PerformLayout = function(s,w,h)
		if ( istable(default) ) then
			color_cube:SetColor( default )
			color_picker:SetColor( default, true )		
		end			
	end
	
	return BGPanel
	
end

function MODULE:_PostLoad()
	self._default = DERMA
end