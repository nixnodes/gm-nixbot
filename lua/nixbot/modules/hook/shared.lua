function MODULE:RegisterHook( event, func, s)
	local hook_metadata = {}
	setmetatable(hook_metadata, {__call=func});
	
	if ( self[event] == nil ) then
		self[event] = {}
	end
	
	if ( !s ) then
		table.insert(self[event], hook_metadata)
	else
		self[event] = {hook_metadata}
	end
end

function MODULE:UnregisterHook( event)
	self[event] = {}	
end

function MODULE:RunHook( event, ...)
	local hooktable = self[event]
	
	if ( hooktable == nil ) then
		return
	end
		
	for _,__hookfunc in ipairs (hooktable) do
		PrintTable(__hookfunc)
		
		if ( __hookfunc(...) == false ) then
			return false
		end
	end
	return true
end

function MODULE:CreateContext()
	return setmetatable({}, {__index=self})
end
