--[[
    SlatHub v8, NotSlater#0999| Modded by Slater
    
    Thanks for using this shit softaim, atleast its UD and gud

]]

-- Character Patch (Stefanuk12 | Modded by HamstaGang) [Fixes teams/teamcolor/ect]
loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/ROBLOX/master/Games/Frontlines/CharacterPatch.lua", true))()


-- Extremly bad code starts below here

local DEBUG_MODE = false -- warnings, prints and profiles dont change idiot thanks

-- Ok I declare some variables here for micro optimization. I might declare again in the blocks because I am lazy to check here
local game, workspace = game, workspace

local cf, v3, v2, udim2 = CFrame, Vector3, Vector2, UDim2
local string, math, table, Color3, tonumber, tostring = string, math, table, Color3, tonumber, tostring

local cfnew = cf.new
local cf0 = cfnew()

local v3new = v3.new
local v30 = v3new()

local v2new = v2.new
local v20 = v2new()

local setmetatable = setmetatable
local getmetatable = getmetatable

local type, typeof = type, typeof

local Instance = Instance

local drawing = Drawing or drawing

local mousemoverel = mousemoverel or (Input and Input.MouseMove)

local readfile = readfile
local writefile = writefile
local appendfile = appendfile

local warn, print = DEBUG_MODE and warn or function() end, DEBUG_MODE and print or function() end


local required = {
	mousemoverel, drawing, readfile, writefile, appendfile, game.HttpGet, game.GetObjects
}

for i,v in pairs(required) do
	if v == nil then
		warn("Your exploit is not supported (may consider purchasing a better one?)!")
		return -- Only pros return in top-level function
	end
end

local servs
servs = setmetatable(
	{
		Get = function(self, serv)
			if servs[serv] then return servs[serv] end
			local s = game:GetService(serv)
			if s then servs[serv] = s end
			return s
		end;
	}, {
		__index = function(self, index)
			local s = game:GetService(index)
			if s then servs[index] = s end
			return s
		end;
	})

local connections = {}
local function bindEvent(event, callback) -- Let me disconnect in peace
	local con = event:Connect(callback)
	table.insert(connections, con)
	return con
end

local players = servs.Players
local runservice = servs.RunService
local http = servs.HttpService
local uis = servs.UserInputService

local function jsonEncode(t)
	return http:JSONEncode(t)
end
local function jsonDecode(t)
	return http:JSONDecode(t)
end

local function existsFile(name)
	return pcall(function()
		return readfile(name)
	end)
end

local function mergetab(a,b)
	local c = a or {}
	for i,v in pairs(b or {}) do 
		c[i] = v 
	end
	return c
end

local locpl = players.LocalPlayer
local mouse = locpl:GetMouse()
local camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() -- if a script changes currentcamera
	camera = workspace.CurrentCamera
end)


local findFirstChild = game.FindFirstChild
local findFirstChildOfClass = game.FindFirstChildOfClass
local isDescendantOf = game.IsDescendantOf

-- Just to check another aimhot instance is running and close it
local uid = tick() .. math.random(1,100000) .. math.random(1,100000)
if shared.ah8 and shared.ah8.close and shared.ah8.uid~=uid then shared.ah8:close() end

-- Main shitty script should start below here

warn("AH8_MAIN : Running script...")

local event = {} 
local utility = {}
local serializer = {}

local settings = {}

local hud = loadstring(game:HttpGet("https://pastebin.com/raw/3hREvLEU", DEBUG_MODE == false and true or DEBUG_MODE == true and false))()[1] -- Ugly ui do not care

local aimbot = {}

local run = {}
local ah8 = {enabled = true;}


local visiblekids = {} -- no need to check twice each frame yes? todo :(
-- Some libraries

do
	--/ Events : custom event system, bindables = gay

	local type = type;
	local coroutine = coroutine;
	local create = coroutine.create;
	local resume = coroutine.resume;

	local function spawn(f, ...)
		resume(create(f), ...)
	end

	function event.new(t)
		local self = t or {}

		local n = 0
		local connections = {}
		function self:connect(func)
			if type(func) ~= "function" then return end

			n = n + 1
			local my = n
			connections[n] = func

			local connected = true
			local function disconnect()
				if connected ~= true then return end
				connected = false

				connections[n] = nil
			end

			return disconnect
		end


		local function fire(...)
			for i,v in pairs(connections) do
				v(...)
			end
		end

		return fire, self
	end
end

do
	--/ Utility : To make it easier for me to edit

	local getPlayers = players.GetPlayers
	local getPartsObscuringTarget = camera.GetPartsObscuringTarget
	local worldToViewportPoint = camera.WorldToViewportPoint
	local worldToScreenPoint = camera.WorldToScreenPoint
	local raynew = Ray.new
	local findPartOnRayWithIgnoreList = workspace.FindPartOnRayWithIgnoreList
	local findPartOnRay = workspace.FindPartOnRay
	local findFirstChild = game.FindFirstChild

	local function raycast(ray, ignore, callback)
		local ignore = ignore or {}

		local hit, pos, normal, material = findPartOnRayWithIgnoreList(workspace, ray, ignore)
		while hit and callback do
			local Continue, _ignore = callback(hit)
			if not Continue then
				break
			end
			if _ignore then
				table.insert(ignore, _ignore)
			else
				table.insert(ignore, hit)
			end
			hit, pos, normal, material = findPartOnRayWithIgnoreList(workspace, ray, ignore)
		end
		return hit, pos, normal, material
	end

	local function badraycastnotevensure(pos, ignore) -- 1 ray > 1 obscuringthing | 100 rays < 1 obscuring thing
		local hitparts = getPartsObscuringTarget(camera, {pos}, ignore or {})
		return hitparts
	end

	local charshit = {}
	function utility.getcharacter(player) -- Change this or something if you want to add support for other games.
		if (player == nil) then return end
		if (charshit[player]) then return charshit[player] end

		local char = player.Character
		if (char == nil or isDescendantOf(char, game) == false) then
			char = findFirstChild(workspace, player.Name)
		end

		return char
	end

	utility.mychar = nil
	utility.myroot = nil

	local rootshit = {}
	function utility.getroot(player)
		if (player == nil) then return end
		if (rootshit[player]) then return rootshit[player] end

		local char
		if (player:IsA("Player")) then
			char = utility.getcharacter(player)
		else
			char = player
		end

		if (char ~= nil) then
			local root = (findFirstChild(char, "HumanoidRootPart") or char.PrimaryPart)
			if (root ~= nil) then -- idk
				--bindEvent(root.AncestryChanged, function(_, parent)
				--    if (parent == nil) then
				--        roostshit[player] = nil
				--    end
				--end)
			end

			--rootshit[player] = root
			return root
		end

		return
	end

	spawn(function()
		while ah8 and ah8.enabled do -- Some games are gay
			utility.mychar = utility.getcharacter(locpl)
			if (utility.mychar ~= nil) then
				utility.myroot = utility.getroot(locpl)
			end
			wait(.5)
		end
	end)
	utility.mychar = locpl.Character
	utility.myroot = utility.mychar and findFirstChild(utility.mychar, "HumanoidRootPart") or utility.mychar and utility.mychar.PrimaryPart
	bindEvent(locpl.CharacterAdded, function(char)
		utility.mychar = char
		wait(.1)
		utility.myroot = utility.mychar and findFirstChild(utility.mychar, "HumanoidRootPart") or utility.mychar.PrimaryPart
	end)
	bindEvent(locpl.CharacterRemoving, function()
		utility.mychar = nil
		utility.myroot = nil
	end)


	function utility.isalive(_1, _2)
		if _1 == nil then return end
		local Char, RootPart
		if _2 ~= nil then
			Char, RootPart = _1,_2
		else
			Char = utility.getcharacter(_1)
			RootPart = Char and (Char:FindFirstChild("HumanoidRootPart") or Char.PrimaryPart)
		end

		if Char and RootPart then
			local Human = findFirstChildOfClass(Char, "Humanoid")
			if RootPart and Human then
				if Human.Health > 0 then
					return true
				end
			elseif RootPart and isDescendantOf(Char, game) then
				return true
			end
		end

		return false
	end

	local shit = false
	function utility.isvisible(char, root, max, ...)
		local pos = root.Position
		if shit or max > 4 then
			local parts = badraycastnotevensure(pos, {utility.mychar, ..., camera, char, root})

			return parts == 0
		else
			local camp = camera.CFrame.p
			local dist = (camp - pos).Magnitude

			local hitt = 0
			local hit = raycast(raynew(camp, (pos - camp).unit * dist), {utility.mychar, ..., camera}, function(hit)

				if hit.CanCollide ~= false then-- hit.Transparency ~= 1 then¨
					hitt = hitt + 1
					return hitt < max
				end

				if isDescendantOf(hit, char) then
					return
				end
				return true
			end)

			return hit == nil and true or isDescendantOf(hit, char), hitt
		end
	end
	function utility.sameteam(player, p1)
		local p0 = p1 or locpl
		print("[SameTeam Check]| Plr: " .. tostring(player) .. " | TeamColor: " .. tostring(player.TeamColor));
		return (player.TeamColor~=nil and player.TeamColor==p0.TeamColor)
	end
	function utility.getDistanceFromMouse(position)
		local screenpos, vis = worldToViewportPoint(camera, position)
		if vis and screenpos.Z > 0 then
			return (v2new(mouse.X, mouse.Y) - v2new(screenpos.X, screenpos.Y)).Magnitude
		end
		return math.huge
	end


	local hashes = {}
	function utility.getClosestMouseTarget(settings)
		local closest, temp = nil, settings.fov or math.huge
		local plr

		for i,v in pairs(getPlayers(players)) do
			if (locpl ~= v and (settings.ignoreteam==true and utility.sameteam(v)==false or settings.ignoreteam == false)) then
				local character = utility.getcharacter(v)
				if character and isDescendantOf(character, game) == true then
					local hash = hashes[v]
					local part = hash or findFirstChild(character, settings.name or "HumanoidRootPart") or findFirstChild(character, "HumanoidRootPart") or character.PrimaryPart
					if hash == nil then hashes[v] = part end
					if part and isDescendantOf(part, game) == true then
						local legal = true

						local rp = part:GetRenderCFrame().p
						local distance = utility.getDistanceFromMouse(rp)
						if temp <= distance then
							legal = false
						end

						if legal then
							if settings.checkifalive then
								local isalive = utility.isalive(character, part)
								if not isalive then
									legal = false
								end
							end
						end

						if legal then
							local visible = true
							if settings.ignorewalls == false then
								local vis = utility.isvisible(character, part, (settings.maxobscuringparts or 0))
								if not vis then
									legal = false
								end
							end
						end

						if legal then
							local dist1
							temp = distance
							closest = part
							plr = v
						end
					end
				end
			end
		end -- who doesnt love 5 ends in a row?

		return closest, temp, plr
	end
	function utility.getClosestTarget(settings)

		local closest, temp = nil, math.huge
		--local utility.myroot = utility.mychar and (findFirstChild(utility.mychar, settings.name or "HumanoidRootPart") or findFirstChild(utility.mychar, "HumanoidRootPart"))

		if utility.myroot then
			for i,v in pairs(getPlayers(players)) do
				if (locpl ~= v) and (settings.ignoreteam==true and utility.sameteam(v)==false or settings.ignoreteam == false) then
					local character = utility.getcharacter(v)
					if character then
						local hash = hashes[v]
						local part = hash or findFirstChild(character, settings.name or "HumanoidRootPart") or findFirstChild(character, "HumanoidRootPart")
						if hash == nil then hashes[v] = part end

						if part then
							local visible = true
							if settings.ignorewalls == false then
								local vis, p = utility.isvisible(character, part, (settings.maxobscuringparts or 0))
								if p <= (settings.maxobscuringparts or 0) then
									visible = vis
								end
							end

							if visible then
								local distance = (utility.myroot.Position - part.Position).Magnitude
								if temp > distance then
									temp = distance
									closest = part
								end
							end
						end
					end
				end
			end
		end

		return closest, temp
	end

	spawn(function()
		while ah8 and ah8.enabled do
			for i,v in pairs(hashes) do
				hashes[i] = nil
				wait()
			end
			wait(4)
			--hashes = {}
		end
	end)
end


local serialize
local deserialize
do
	--/ Serializer : garbage : slow as fuck

	local function hex_encode(IN, len)
		local B,K,OUT,I,D=16,"0123456789ABCDEF","",0,nil
		while IN>0 do
			I=I+1
			IN,D=math.floor(IN/B), IN%B+1
			OUT=string.sub(K,D,D)..OUT
		end
		if len then
			OUT = ('0'):rep(len - #OUT) .. OUT
		end
		return OUT
	end
	local function hex_decode(IN) 
		return tonumber(IN, 16) 
	end

	local types = {
		["nil"] = "0";
		["boolean"] = "1";
		["number"] = "2";
		["string"] = "3";
		["table"] = "4";

		["Vector3"] = "5";
		["CFrame"] = "6";
		["Instance"] = "7";

		["Color3"] = "8";
	}
	local rtypes = (function()
		local a = {}
		for i,v in pairs(types) do
			a[v] = i
		end
		return a
	end)()

	local typeof = typeof or type
	local function encode(t, ...)
		local type = typeof(t)
		local s = types[type]
		local c = ''
		if type == "nil" then
			c = types[type] .. "0"
		elseif type == "boolean" then
			local t = t == true and '1' or '0'
			c = s .. t
		elseif type == "number" then
			local new = tostring(t)
			local len = #new
			c = s .. len .. "." .. new
		elseif type == "string" then
			local new = t
			local len = #new
			c = s .. len .. "." .. new
		elseif type == "Vector3" then
			local x,y,z = tostring(t.X), tostring(t.Y), tostring(t.Z)
			local new = hex_encode(#x, 2) .. x .. hex_encode(#y, 2) .. y .. hex_encode(#z, 2) .. z
			c = s .. new
		elseif type == "CFrame" then
			local a = {t:GetComponents()}
			local new = ''
			for i,v in pairs(a) do
				local l = tostring(v)
				new = new .. hex_encode(#l, 2) .. l
			end
			c = s .. new
		elseif type == "Color3" then
			local a = {t.R, t.G, t.B}
			local new = ''
			for i,v in pairs(a) do
				local l = tostring(v)
				new = new .. hex_encode(#l, 2) .. l
			end
			c = s .. new
		elseif type == "table" then
			return serialize(t, ...)
		end
		return c
	end
	local function decode(t, extra)
		local p = 0
		local function read(l)
			l = l or 1
			p = p + l
			return t:sub(p-l + 1, p)
		end
		local function get(a)
			local k = ""
			while p < #t do
				if t:sub(p+1,p+1) == a then
					break
				else
					k = k .. read()
				end
			end
			return k
		end
		local type = rtypes[read()]
		local c

		if type == "nil" then
			read()
		elseif type == "boolean" then
			local d = read()
			c = d == "1" and true or false
		elseif type == "number" then
			local length = tonumber(get("."))
			local d = read(length+1):sub(2,-1)
			c = tonumber(d)
		elseif type == "string" then
			local length = tonumber(get(".")) --read()
			local d = read(length+1):sub(2,-1)
			c = d
		elseif type == "Vector3" then
			local function getnext()
				local length = hex_decode(read(2))
				local a = read(tonumber(length))
				return tonumber(a)
			end
			local x,y,z = getnext(),getnext(),getnext()
			c = Vector3.new(x, y, z)
		elseif type == "CFrame" then
			local a = {}
			for i = 1,12 do
				local l = hex_decode(read(2))
				local b = read(tonumber(l))
				a[i] = tonumber(b)
			end
			c = CFrame.new(unpack(a))
		elseif type == "Instance" then
			local pos = hex_decode(read(2))
			c = extra[tonumber(pos)]
		elseif type == "Color3" then
			local a = {}
			for i = 1,3 do
				local l = hex_decode(read(2))
				local b = read(tonumber(l))
				a[i] = tonumber(b)
			end
			c = Color3.new(unpack(a))
		end
		return c
	end

	function serialize(data, p)
		if data == nil then return end
		local type = typeof(data)
		if type == "table" then
			local extra = {}
			local s = types[type]
			local new = ""
			local p = p or 0
			for i,v in pairs(data) do
				local i1,v1
				local t0,t1 = typeof(i), typeof(v)

				local a,b
				if t0 == "Instance" then
					p = p + 1
					extra[p] = i
					i1 = types[t0] .. hex_encode(p, 2)
				else
					i1, a = encode(i, p)
					if a then
						for i,v in pairs(a) do
							extra[i] = v
						end
					end
				end

				if t1 == "Instance" then
					p = p + 1
					extra[p] = v
					v1 = types[t1] .. hex_encode(p, 2)
				else
					v1, b = encode(v, p)
					if b then
						for i,v in pairs(b) do
							extra[i] = v
						end
					end
				end
				new = new .. i1 .. v1
			end
			return s .. #new .. "." .. new, extra
		elseif type == "Instance" then
			return types[type] .. hex_encode(1, 2), {data}
		else
			return encode(data), {}
		end
	end

	function deserialize(data, extra)
		if data == nil then return end
		extra = extra or {}

		local type = rtypes[data:sub(1,1)]
		if type == "table" then

			local p = 0
			local function read(l)
				l = l or 1
				p = p + l
				return data:sub(p-l + 1, p)
			end
			local function get(a)
				local k = ""
				while p < #data do
					if data:sub(p+1,p+1) == a then
						break
					else
						k = k .. read()
					end
				end
				return k
			end

			local length = tonumber(get("."):sub(2, -1))
			read()

			local new = {}

			local l = 0
			while p <= length do
				l = l + 1

				local function getnext()
					local i
					local t = read()
					local type = rtypes[t]

					if type == "nil" then
						i = decode(t .. read())
					elseif type == "boolean" then
						i = decode(t .. read())
					elseif type == "number" then
						local l = get(".")

						local dc = t .. l .. read()
						local a = read(tonumber(l))
						dc = dc .. a

						i = decode(dc)
					elseif type == "string" then
						local l = get(".")
						local dc = t .. l .. read()
						local a = read(tonumber(l))
						dc = dc .. a

						i = decode(dc)
					elseif type == "Vector3" then
						local function getnext()
							local length = hex_decode(read(2))
							local a = read(tonumber(length))
							return tonumber(a)
						end
						local x,y,z = getnext(),getnext(),getnext()
						i = Vector3.new(x, y, z)
					elseif type == "CFrame" then
						local a = {}
						for i = 1,12 do
							local l = hex_decode(read(2))
							local b = read(tonumber(l)) -- why did I decide to do this
							a[i] = tonumber(b)
						end
						i = CFrame.new(unpack(a))
					elseif type == "Instance" then
						local pos = hex_decode(read(2))
						i = extra[tonumber(pos)]
					elseif type == "Color3" then
						local a = {}
						for i = 1,3 do
							local l = hex_decode(read(2))
							local b = read(tonumber(l))
							a[i] = tonumber(b)
						end
						i = Color3.new(unpack(a))
					elseif type == "table" then
						local l = get(".")
						local dc = t .. l .. read() .. read(tonumber(l))
						i = deserialize(dc, extra)
					end
					return i
				end
				local i = getnext()
				local v = getnext()

				new[(typeof(i) ~= "nil" and i or l)] =  v
			end


			return new
		elseif type == "Instance" then
			local pos = tonumber(hex_decode(data:sub(2,3)))
			return extra[pos]
		else
			return decode(data, extra)
		end
	end
end


-- great you have come a far way now stop before my horrible scripting will infect you moron

do
	--/ Settings

	-- TODO: Other datatypes.
	settings.fileName = "SlatHub_FL_settings.txt" -- Lovely
	settings.saved = {}

	function settings:Get(name, default)
		local self = {}
		local value = settings.saved[name]
		if value == nil and default ~= nil then
			value = default
			settings.saved[name] = value
		end
		self.Value = value
		function self:Set(val)
			self.Value = val
			settings.saved[name] = val
		end
		return self  --value or default
	end

	function settings:Set(name, value)
		local r = settings.saved[name]
		settings.saved[name] = value
		return r
	end

	function settings:Save()
		local savesettings = settings:GetAll() or {}
		local new = mergetab(savesettings, settings.saved)
		local js = serialize(new)

		writefile(settings.fileName, js)
	end

	function settings:GetAll()
		if not existsFile(settings.fileName) then
			return
		end
		local fileContents = readfile(settings.fileName)

		local data
		pcall(function()
			data = deserialize(fileContents)
		end)
		return data
	end

	function settings:Load()
		if not existsFile(settings.fileName) then
			return
		end
		local fileContents = readfile(settings.fileName)

		local data
		pcall(function()
			data = deserialize(fileContents)
		end)

		if data then
			data = mergetab(settings.saved, data)
		end
		settings.saved = data
		return data
	end
	settings:Load()

	spawn(function()
		while ah8 and ah8.enabled do
			settings:Save()
			wait(5)
		end
	end)
end

-- Aiming aim bot aim aim stuff bot

do
	--/ Aimbot

	-- Do I want to make this decent?
	local aimbot_settings = {}
	aimbot_settings.ignoreteam = settings:Get("aimbot.ignoreteam", true)
	aimbot_settings.sensitivity = settings:Get("aimbot.sensitivity", .20)
	aimbot_settings.locktotarget = settings:Get("aimbot.locktotarget", true)
	aimbot_settings.checkifalive = settings:Get("aimbot.checkifalive", false)

	aimbot_settings.ignorewalls = settings:Get("aimbot.ignorewalls", true)
	aimbot_settings.maxobscuringparts = settings:Get("aimbot.maxobscuringparts", 1)


	aimbot_settings.enabled = settings:Get("aimbot.enabled", true)
	aimbot_settings.keybind = settings:Get("aimbot.keybind", "MouseButton2")
	aimbot_settings.presstoenable = settings:Get("aimbot.presstoenable", true)

	aimbot_settings.fovsize = settings:Get("aimbot.fovsize", 400)
	aimbot_settings.fovenabled = settings:Get("aimbot.fovenabled", false)
	aimbot_settings.fovsides = settings:Get("aimbot.fovsides", 10)
	aimbot_settings.fovthickness = settings:Get("aimbot.fovthickness", 1)

	aimbot.fovshow = aimbot_settings.fovenabled.Value

	setmetatable(aimbot, {
		__index = function(self, index)
			if aimbot_settings[index] ~= nil then
				local Value = aimbot_settings[index]
				if typeof(Value) == "table" then
					return typeof(Value) == "table" and Value.Value
				else
					return Value
				end
			end
			warn(("AH8_ERROR : AimbotSettings : Tried to index %s"):format(tostring(index)))
		end;
		__newindex = function(self, index, value)
			if typeof(value) ~= "function" then
				if aimbot_settings[index] then
					local v = aimbot_settings[index]
					if typeof(v) ~= "table" then
						aimbot_settings[index] = value
						return
					elseif v.Set then
						v:Set(value)
						return
					end
				end
			end
			rawset(self, index, value)
		end; -- ew
	})


	local worldToScreenPoint = camera.WorldToScreenPoint -- why did I start this
	local target, _, closestplr = nil, nil, nil;
	local completeStop = false

	local enabled = false
	bindEvent(uis.InputBegan, function(key,gpe)
		if aimbot.enabled == false then return end

		if aimbot.presstoenable then
			aimbot.fovshow = true
		else
			aimbot.fovshow = enabled == true
		end

		local keyc = key.KeyCode == Enum.KeyCode.Unknown and key.UserInputType or key.KeyCode
		if keyc.Name == aimbot.keybind then
			if aimbot.presstoenable then
				enabled = true
				aimbot.fovshow = true
			else
				enabled = not enabled
				aimbot.fovshow = enabled == true
			end
		end
	end)
	bindEvent(uis.InputEnded, function(key)
		if aimbot.enabled == false then enabled = false aimbot.fovshow = false end
		if aimbot.presstoenable then
			aimbot.fovshow = true
		else
			aimbot.fovshow = enabled == true
		end

		local keyc = key.KeyCode == Enum.KeyCode.Unknown and key.UserInputType or key.KeyCode
		if keyc.Name == aimbot.keybind then
			if aimbot.presstoenable then
				enabled = false
			end
		end
	end)


	local function calculateTrajectory()
		-- my math is a bit rusty atm
	end

	local function aimAt(vector)
		if completeStop then return end
		local newpos = worldToScreenPoint(camera, vector)
		mousemoverel((newpos.X - mouse.X) * aimbot.sensitivity, (newpos.Y - mouse.Y) * aimbot.sensitivity)
	end

	function aimbot.step()
		if completeStop or aimbot.enabled == false or enabled == false or utility.mychar == nil or isDescendantOf(utility.mychar, game) == false then 
			if target or closestplr then
				target, closestplr, _ = nil, nil, _
			end
			return 
		end

		if aimbot.locktotarget == true then
			local cchar = utility.getcharacter(closestplr)
			if target == nil or isDescendantOf(target, game) == false or closestplr == nil or closestplr.Parent == nil or cchar  == nil or isDescendantOf(cchar, game) == false then
				target, _, closestplr = utility.getClosestMouseTarget({ -- closest to mouse or camera mode later just wait
					ignoreteam = aimbot.ignoreteam;
					ignorewalls = aimbot.ignorewalls;
					maxobscuringparts = aimbot.maxobscuringparts;
					name = 'Head';
					fov = aimbot.fovsize;
					checkifalive = aimbot.checkifalive;
					-- mode = "mouse";
				})
			else
				--target = target
				local stop = false
				if stop == false and not (aimbot.ignoreteam==true and utility.sameteam(closestplr)==false or aimbot.ignoreteam == false) then
					stop = true
				end
				local visible = true

				if stop == false and aimbot.ignorewalls == false then
					local vis = utility.isvisible(target.Parent, target, (aimbot.maxobscuringparts or 0))
					if not vis then
						stop = true
					end
				end

				if stop == false and aimbot.checkifalive then
					local isalive = utility.isalive(character, part)
					if not isalive then
						stop = true
					end
				end

				if stop then
					-- getClosestTarget({mode = "mouse"}) later
					target, _, closestplr = utility.getClosestMouseTarget({
						ignoreteam = aimbot.ignoreteam;
						ignorewalls = aimbot.ignorewalls;
						maxobscuringparts = aimbot.maxobscuringparts;
						name = 'Head';
						fov = aimbot.fovsize;
						checkifalive = aimbot.checkifalive;
					})
				end
			end
		else
			target = utility.getClosestMouseTarget({
				ignoreteam = aimbot.ignoreteam;
				ignorewalls = aimbot.ignorewalls;
				maxobscuringparts = aimbot.maxobscuringparts;
				name = 'Head';
				fov = aimbot.fovsize;
				checkifalive = aimbot.checkifalive;
			})
		end

		if target then
			aimAt(target:GetRenderCFrame().Position)
			-- hot or not?
		end
	end

	function aimbot:End()
		completeStop = true
		target = nil
	end
end

-- / Task Scheduler Vars
local task_scheduler = require(game:GetService("ReplicatedStorage")["framework_shared"]["task_scheduler"])
local upvalues = getupvalues(task_scheduler.add_task)

-- // Task Hook Function
local function hook_return(INIT_ITEM)
	-- // Search upvalues from task_scheduler and look for the ID of INIT.
	table.foreach(upvalues[1][INIT_ITEM], function(i, v)
		-- // Confirm it's a function
		if type(v) == "function" then
			-- // Then we just replace it with empty function lmao
			hookfunction(v, function(...)
				return;
			end)
		end
	end)
end
-- end


-- Ok yes
do
	--/ Run

	local pcall = pcall;
	local tostring = tostring;
	local warn = warn;
	local debug = debug;
	local profilebegin = DEBUG_MODE and debug.profilebegin or function() end
	local profileend = DEBUG_MODE and debug.profileend or function() end

	local renderstep = runservice.RenderStepped
	local heartbeat = runservice.Heartbeat
	local stepped = runservice.Stepped
	local wait = renderstep.wait

	local function Warn(a, ...) -- ok frosty get to bed
		warn(tostring(a):format(...))
	end

	run.dt = 0
	run.time = tick()

	local engine = {
		{
			name = 'visuals.step',
			func = visuals.step
		};
	}
	local heartengine = {
		{
			name = 'aimbot.step',
			func = aimbot.step
		};
	}
	local whilerender = {
	}

	run.onstep = {}
	run.onthink = {}
	run.onrender = {}
	function run.wait()
		wait(renderstep)
	end

	local fireonstep = event.new(run.onstep)
	local fireonthink = event.new(run.onthink)
	local fireonrender = event.new(run.onrender)

	local rstname = "AH.Renderstep"
	bindEvent(renderstep, function(delta)
		profilebegin(rstname)
		local ntime = tick()
		run.dt = ntime - run.time
		run.time = ntime

		for i,v in pairs(engine) do

			profilebegin(v.name)
			xpcall(v.func, function(err)
				if (DEBUG_MODE == true) then
					Warn("AH8_ERROR (RENDERSTEPPED) : Failed to run %s! %s | %s", v.name, tostring(err), debug.traceback())
				end
				engine[i] = nil
			end, run.dt)
			profileend(v.name)

		end

		profileend(rstname)
	end)

	local hbtname = "AH.Heartbeat"
	bindEvent(heartbeat, function(delta)
		profilebegin(hbtname)

		for i,v in pairs(heartengine) do

			profilebegin(v.name)
			xpcall(v.func, function(err)
				if (DEBUG_MODE == true) then
					Warn("AH8_ERROR (HEARTBEAT) : Failed to run %s! %s | %s", v.name, tostring(err), debug.traceback())
				end
				heartengine[i] = nil
			end, delta)
			profileend(v.name)

		end

		profileend(hbtname)
	end)

	local stpname = "AH.Stepped"
	bindEvent(stepped, function(delta)

		profilebegin(stpname)

		for i,v in pairs(whilerender) do

			profilebegin(v.name)
			xpcall(v.func, function(err)
				if (DEBUG_MODE == true) then
					Warn("AH8_ERROR (STEPPED) : Failed to run %s! %s | %s", v.name, tostring(err), debug.traceback())
				end
				heartengine[i] = nil
			end, delta)
			profileend(v.name)

		end

		profileend(stpname)
	end)
end

do
	--/ Main or something I am not sure what I am writing anymore
	settings:Save()

	ah8.enabled = true
	function ah8:close()
		spawn(function() pcall(visuals.End, visuals) end)
		spawn(function() pcall(aimbot.End, aimbot) end)
		spawn(function() pcall(hud.End, hud) end)
		spawn(function()
			for i,v in pairs(connections) do
				pcall(function() v:Disconnect() end)
			end
		end)
		ah8 = nil
		shared.ah8 = nil -- k

		settings:Save()
	end

	ah8.visible = hud.Visible
	function ah8:show()
		hud:show()
		ah8.visible = hud.Visible
	end

	function ah8:hide()
		hud:hide()
		ah8.visible = hud.Visible
	end

	setmetatable(ah8, { -- ok safazi be happy now
		__newindex = function(self, index, value)
			if (index == "Keybind") then
				settings:Set("hud.keybind", value)
				hud.Keybind = value
				return
			end
		end;
	})

	shared.ah8 = ah8

	local players = game:GetService("Players")
	local loc = players.LocalPlayer
	bindEvent(players.PlayerRemoving, function(p)
		if p == loc then
			settings:Save()
		end
	end)

end


-- I didn't think this ui lib through
local Aiming = hud:AddTab({
	Text = "Aiming",
})


local AimbotToggle = Aiming:AddToggleCategory({
	Text = "Aimbot",
	State = aimbot.enabled,
}, function(state) 
	aimbot.enabled = state
end)


AimbotToggle:AddKeybind({
	Text = "keybind",
	Current = aimbot.keybind,
}, function(new)
	aimbot.keybind = new.Name 
end)


AimbotToggle:AddToggle({
	Text = "Press To Enable",
	State = aimbot.presstoenable,
}, function(state) 
	aimbot.presstoenable = state
end)

AimbotToggle:AddToggle({
	Text = "Lock To Target",
	State = aimbot.locktotarget,
}, function(state) 
	aimbot.locktotarget = state
end)


AimbotToggle:AddToggle({
	Text = "Check If Alive",
	State = aimbot.checkifalive,
}, function(state) 
	aimbot.checkifalive = state
end)

-- settings stuff
local AimbotSettings = Aiming:AddCategory({
	Text = "Settings",
})

AimbotSettings:AddLabel({
	Text = "decrease sens if aimbot is wobbly"
})

AimbotSettings:AddSlider({
	Text = "Sensitivity",
	Current = aimbot.sensitivity
}, {0.01, 10, 0.01}, function(new) 
	aimbot.sensitivity = new
end)

AimbotSettings:AddToggle({
	Text = "Ignore Team",
	State = aimbot.ignoreteam
}, function(new)
	aimbot.ignoreteam = new
end)


AimbotSettings:AddToggle({
	Text = "Ignore Walls",
	State = aimbot.ignorewalls
}, function(new)
	aimbot.ignorewalls = new
end)

AimbotSettings:AddSlider({
	Text = "Max Obscuring Parts",
	Current = aimbot.maxobscuringparts,
}, {0, 50, 1}, function(new)
	aimbot.maxobscuringparts = new
end)



local FieldOfView = Aiming:AddToggleCategory({
	Text = "fov",
	State = aimbot.fovenabled,
}, function(state) 
	aimbot.fovenabled = state
end)

FieldOfView:AddSlider({
	Text = "Radius",
	Current = aimbot.fovsize,
}, {1, 1000, 1}, function(new)
	aimbot.fovsize = new
end)

FieldOfView:AddSlider({
	Text = "Sides",
	Current = aimbot.fovsides,
}, {6, 40, 1}, function(new)
	aimbot.fovsides = new
end)


FieldOfView:AddSlider({
	Text = "Thickness",
	Current = aimbot.fovthickness,
}, {0.1, 50, 0.1}, function(new)
	aimbot.fovthickness = new
end)

local Hud = hud:AddTab({
	Text = "Hud",
})

hud.Keybind = settings:Get("hud.keybind", "LeftAlt").Value
Hud:AddKeybind({
	Text = "Toggle",
	Current = hud.Keybind,
}, function(new)
	settings:Set("hud.keybind", new.Name)
	hud.Keybind = new.Name
end)

Hud:AddButton({
	Text = "Exit"
}, function()
	ah8:close()
end)

warn("AH8_MAIN : Reached end of script")
