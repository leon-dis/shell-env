#!/usr/bin/env lua

require "posix"

sys_config_name = ".envrc"
sys_env_path = "SHELLENV" -- store current config path
sys_env_backup = "SHELLENV_BACKUP"

read_conf = function(filename)
	--first test config for correct
	run_test = "/bin/sh -c \"set -e; . \'" .. filename .. "\'\""
	res = os.execute(run_test)
	if res == 0 then
		return ". \'" .. filename .. "\'"
	else
		return nil
	end
end

read_conf_old = function(filename) -- return variables table

	--Waring, this function wrong read variables  whose cosist \n
	local f=io.open(filename)
	envs = {}
  if f ~= nil then
    for line in f:lines() do
				k,v = line:match( "export[ ]+([A-Za-z_0-9]+)=(.*)" )
				if k and v then
					envs[k] = v
				end
		end
		f:close()
	end
	return envs
end

dump_table = function (vars) --debug function
	for k,v in pairs(vars) do 
  	if v == false then v = "not defined" end
		io.stderr:write("key=" .. k .. ", value=" .. v .. "\n") 
	end
end

diff_vars = function (origin, new) -- comparing vars
	diff_origin = {}
	diff_new = {}

	for k,v in pairs(origin) do

		if (k ~= "PWD" and k ~= "OLDPWD" and k ~= "SHLVL" and k ~= "SHELL" and k ~="PS1"  and k ~= sys_env_path and k ~= sys_env_backup) then
			if new[k] then
				if v ~= new[k] then
					diff_origin[k] = new[k]
				end
			else
					diff_origin[k] = false
			end
		end
	end
	return diff_origin
end

-- functions decoding/endcoding enc and dec
-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function enc(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end


serial_vars = function (env)
	res_str = ""
	for k,v in pairs(env) do
		if (k ~= "PWD" and k ~= "OLDPWD" and k ~="SHLVL" and  k ~= "SHELL"  and k ~="PS1"  and k ~= sys_env_path and k ~= sys_env_backup) then
			res_str = res_str .. k .. "," .. string.len(v) .. "," .. v .. ";" 
		end
	end

	str=enc(res_str)
	return str
end

deserial_vars = function (encstr) --TODO do it in C
	
	str=dec(encstr)
	start_pos = 1 
	pos = 0 
	end_pos = 0
	size_value = 0
	str_len = str:len()
	env = {}
	repeat
		end_pos = string.find(str,",",start_pos)
		var_name = str:sub(start_pos,end_pos-1)
		
		start_pos = end_pos + 1
		end_pos = string.find(str,",",start_pos)
		size_value = tonumber(string.sub(str,start_pos,end_pos-1))
		
		start_pos = end_pos + 1
		end_pos = start_pos + size_value - 1
		var_value = str:sub(start_pos,end_pos)
		start_pos = end_pos + 1 + 1
		env[var_name] = var_value
	until (start_pos >= str_len)
	return env
end

find_conf = function () --find directory of conf_file
	make_lev_up = function (path)
		if (path == "/") then return path end		--check for root path
			path = path:gsub("/[^/]+$","")
		return path
	end

  cur_dir = posix.getcwd ()
 	root_dir =  posix.getenv ("HOME") -- high level directory for searching config file
  max_dep = 10
	cur_dep = 0
	ready_path = nil
	repeat
  	finfo = posix.stat(cur_dir .. "/" .. sys_config_name)
	  if (finfo ~= nil and finfo.type == "regular") then  
			ready_path = cur_dir
		end
		-- go to level up
		cur_dir = make_lev_up(cur_dir)
		cur_dep = cur_dep + 1
  until (cur_dep == max_dep or cur_dir=="/" or ready_path ~= nil)
	return ready_path
end

restore_env = function()
	st = ""
	store_string = posix.getenv(sys_env_backup) -- FIXME check if broken
	
	new_env = deserial_vars(store_string)
	cur_env = posix.getenv()
	df = diff_vars(cur_env, new_env)
	for k,v in pairs(df) do
		if df[k] then
			st = st .. " export "  .. k .. "=" .. "\'" .. v .. "\'" .. ";"
		else 
			st = st .. "unset " .. k .. ";"
		end
	end
	return st
end

--main 
env_cur_dir =  posix.getenv (sys_env_path)
run_str = ""
if env_cur_dir == nil then		--if sys_env_path if not defined
 	cur_conf = find_conf() -- search it
	if cur_conf then -- if found then load
		io.stderr:write("load envrc from " .. cur_conf .. "\n")
		changed = true
		--save vars
		env = posix.getenv()
		str = serial_vars(env)


		run_str = " export " .. sys_env_backup .. "=\"" .. str .. "\"" .. ";" -- CHECKME
		run_str = run_str .. " export " .. sys_env_path .. "=\"" .. cur_conf .. "\";" --and define sys_env_path
		envrc_vars = read_conf(cur_conf .. "/" .. sys_config_name )
		--load new_env
		if envrc_vars ~= nil then
			run_str = run_str .. envrc_vars .. ";"
			print (run_str)

		else
			io.stderr:write (cur_conf .. "/" .. sys_config_name .. " is broken, abort\n")
		end
	end --else do nothing
else													--if sys_env_path is defined
	cur_conf = find_conf()
	if cur_conf == nil then --restore original environment and unset sys_env_path and sys_env_backup
		io.stderr:write("restore old environment after " .. env_cur_dir .. "\n")
		
		run_str = run_str .. restore_env()
		
		run_str = run_str .. "unset " .. sys_env_backup .. ";"
		run_str = run_str .. "unset " .. sys_env_path .. ";"
		--io.stderr:write (run_str .. "\n")
		print (run_str)
	else
		if  cur_conf ~= env_cur_dir  then -- setup new .envrc
			
			io.stderr:write("swithing env from " .. env_cur_dir .. " to " .. cur_conf .. "\n")

			run_str = run_str .. restore_env()

			envrc_vars = read_conf(cur_conf .. "/" .. sys_config_name)
			--load new_env
			if envrc_vars ~= nil then
				run_str = run_str .. envrc_vars .. ";"
				run_str = run_str .. " export " .. sys_env_path .. "=\"" .. cur_conf .. "\";" --and define sys_env_path
				print (run_str)
			else
				io.stderr:write (cur_conf .. "/" .. sys_config_name .. " is broken, abort\n")
			end
		end
	end
end

