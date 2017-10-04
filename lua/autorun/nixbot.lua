include "nixbot/modules/modules.lua"

if ( NIXBOT == nil ) then 		
	print("NIXBOT: Initializing...")	
	NIXBOT = {
		paths = {
			base = "nixbot",
			modules = "modules",
			game = "game"
		}, 
		modules = {
		},
		game = {
		}
	}
		
	if ( SERVER ) then
		NIXBOT.server_start_time = os.time()	
	
--		pcall(require, "stdcap")
--		require("stdcap")
	end

else
	NIXBOT.reload = true
	print("NIXBOT: Reloading...")	
end	

MODULE = {}
include("nixbot/modules/debug.lua")
NIXBOT.debug = setmetatable(MODULE, { __index = NIXBOT})

if ( SERVER ) then 	
	AddCSLuaFile()
	AddCSLuaFile("nixbot/modules/modules.lua")
end

local function register_module(base, name, mod)
	baseclass.Set("nixbot_module_" .. name, mod)
	base[name] = mod
	base.modules[name] = mod
end

local function register_game_module(base, name, mod)
	baseclass.Set("nixbot_game_" .. name, mod)
	base.game[name] = mod
end


local function do_load_module(self, path, r_callback, table)
	local path_modules = self.paths.base .. "/" .. path .. "/"
			
	if ( table == nil ) then
		local f,d = file.Find( path_modules.."*", "LUA" )
		table = d
	end
	
	local i = 0
			
	for _,m in ipairs(table) do
		local base = path_modules .. m 
		
		if ( SERVER && !file.IsDir(base, "LUA") ) then
			NIXBOT.debug.print(m, "module doesn't exist",base)
			continue
		end
		
				
		local server = base .. "/server.lua"
		local client = base .. "/client.lua"
		local shared = base .. "/shared.lua"
		
		i = i + 1
		
		MODULE = {
			_name = m,
			__basepath = base
		}
		BasePath = base
		setmetatable( MODULE, { __index = self } )
		
		local lc = 0
						
		if ( SERVER && file.Exists(server, "LUA") ) then
			NIXBOT.debug.print("Loading: ", path.."/"..m )
			include(server)			
		end
				
		if ( file.Exists(client, "LUA") ) then
			if ( SERVER ) then
				AddCSLuaFile(client)
			else
				NIXBOT.debug.print("Loading: ", path.."/"..m )
				include(client)				
			end
		end
		
		if ( file.Exists(shared, "LUA") ) then
			AddCSLuaFile(shared)
			NIXBOT.debug.print("Loading: ", path.."/"..m, "[shared]" )
			include(shared)			
		end
				
		if ( MODULE._PostLoad ) then
			if ( MODULE:_PostLoad() == false ) then
				NIXBOT.debug.print("Error loading: ", path.."/"..m .. "")
				continue
			end
			
		end
		
		
		r_callback(self, m, MODULE)
		
		MODULE.___i = i
		
		if ( MODULE._PostRegister ) then
			if ( MODULE:_PostRegister() == false ) then
				NIXBOT.debug.print("Error loading module: '".. m .. "'")
				continue
			end
			
		end
		
		MODULE.__loaded = true	
		MODULE = {}
	end	
end


function NIXBOT:load_modules()

	if ( self.reload == true) then
		self:call_destructors(self.modules)
	end
	include "nixbot/modules/modules.lua"

	do_load_module(self, self.paths.modules, register_module, NIXBOT_MODULES_ENABLED || {})
end

function NIXBOT:load_game()
	if ( self.reload == true) then
		self:call_destructors(self.game)
	end
	do_load_module(self, self.paths.game, register_game_module)
--	print(stdcap.TestFunc())
end

function NIXBOT:master_load()

	MODULE = {}
	include("nixbot/modules/debug.lua")
	self.debug = setmetatable(MODULE, { __index = self})
	
	if ( SERVER ) then
		AddCSLuaFile("modules/modules.lua")
		AddCSLuaFile("autorun/nixbot.lua")
	end
		
	self:load_modules()
	self:load_game()	
	
end


function NIXBOT:reload_modules()
	self.reload = true	
	MODULE = {}
	include("nixbot/modules/debug.lua")
	NIXBOT.debug = setmetatable(MODULE, { __index = self})

	self:load_modules()
	self:load_game()	
	
end

function NIXBOT:reload_game()
	self.reload = true
	self:load_game()
end


function NIXBOT:master_reload()
	NIXBOT.reload = true
	self:master_load()
end

function NIXBOT:call_destructors(t)
	local items = {}
	for _,v in pairs(t) do
		table.insert(items, 1, v)
	end	
	
	table.sort(items, function(a,b)
		return a.___i > b.___i
	end)

	for _,mod in ipairs(items) do
		if (mod != nil && mod.Destroy != nil ) then
			self.debug.print("Calling destructor for:", mod._name)
			mod:Destroy()
		end
	end	
end

function NIXBOT:is_module_loaded(m)
	local mod = self[m]
	if ( !mod ) then
		return false
	end
	return mod.__loaded || false
end

NIXBOT:load_modules()

if ( NIXBOT.reload == true ) then
	NIXBOT:load_game()
else
	hook.Add("Initialize", "NIXBOT.init", function()
		NIXBOT:load_game()
				
		NIXBOT.debug.print("NIXBOT: Initialization finished succesfully")
	end)
end

concommand.Add("nb_reload", function (ply)		
	NIXBOT:reload_modules()
	
	if ( SERVER ) then
		timer.Simple(0.25, function()
			BroadcastLua("NIXBOT:master_reload()")
		end)
	end
end, nil, nil , FCVAR_SERVER_CAN_EXECUTE)

hook.Add("ShutDown", "NIXBOT.shutdown", function()	
	NIXBOT:call_destructors(NIXBOT.modules)
	NIXBOT:call_destructors(NIXBOT.game)
	NIXBOT = nil
end)



