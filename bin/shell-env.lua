#!/usr/bin/env lua

require "posix"

sys_config_name = ".envrc"
sys_env_path = "SHELLENV" -- store current config path
sys_env_backup = "SHELLENV_BACKUP"

read_conf = function(filename) -- return variables table
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

serial_vars = function (env)
	res_str = ""
	for k,v in pairs(env) do
		if (k ~= "PWD" and k ~= "OLDPWD" and k ~="SHLVL" and  k ~= "SHELL"  and k ~="PS1"  and k ~= sys_env_path and k ~= sys_env_backup) then
			res_str = res_str .. k .. "," .. string.len(v) .. "," .. v .. ";" 
		end
	end
	return res_str
end

deserial_vars = function (str) --TODO do it in C
	
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
			st = st .. " export "  .. k .. "=" .. v .. ";"
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
		run_str = " export " .. sys_env_backup .. "=\"" .. str .. "\"" .. ";"
		run_str = run_str .. " export " .. sys_env_path .. "=" .. cur_conf .. ";" --and define sys_env_path
		env_new = read_conf(cur_conf .. "/" .. sys_config_name )
		--load new_env
		for k,v in pairs(env_new) do
			run_str = run_str .. " export "  .. k .. "=" .. v .. ";"
		end

		--io.stderr:write (run_str .. "\n")
		print (run_str)
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

			envrc_vars = read_conf(cur_conf .. "/" .. sys_config_name)
			run_str = run_str .. restore_env()

			--load new_env
			for k,v in pairs(envrc_vars) do
				run_str = run_str .. " export "  .. k .. "=" .. v .. ";"
			end
			run_str = run_str .. " export " .. sys_env_path .. "=" .. cur_conf .. ";" --and define sys_env_path
	
	--		io.stderr:write (run_str .. "\n")
			print (run_str)

		end
	end
end

