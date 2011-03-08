#!/usr/bin/env lua
require "lfs"
require "posix"

sys_config_name = ".envrc"
sys_env_path = "SHELLENV"
sys_env_backup = "SHELLENV_BACKUP"

print ("lua shell-env")

read_conf = function(filename) -- return variables table
  local f=io.open(filename)
  envs = {}
  if f ~= nil then
    for line in f:lines() do
        k,v = line:match( "export[ ]+([A-Za-z_]+)=(.*)" )
        if k and v then
          envs[k] = v
        end
    end
    f:close()
  end
  return envs
end

export_vars = function(vars) --return result string to putting shell
  str = ""
  for k,v in pairs(vars) do
    str = str .. "export " .. k .. "=" .. v .. ";"
  end
  return str
end

serial_vars = function (env)
  res_str = ""
  for k,v in pairs(env) do
    res_str = res_str .. k .. "," .. string.len(v) .. "," .. v .. ";"
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

find_conf = function (conf_name)
	make_lev_up = function (path)
		if (path == "/") then return path end		--check for root path
		path = path:gsub("[^/]*/$","")
		return path
	end

  cur_dir = lfs.currentdir ()
	if (cur_dir ~= "/") then cur_dir = cur_dir .. "/" end

 	--root_dir =  posix.getenv ("HOME") .. "/" -- high level directory for searching config file
  root_dir = "/"
  max_dep = 10
	cur_dep = 0
	ready_path = nil
	repeat
		finfo = posix.stat(cur_dir .. conf_name)
	  if (finfo ~= nil and finfo.type == "regular") then
			ready_path = cur_dir .. conf_name
		end
		-- go to level up
		cur_dir = make_lev_up(cur_dir)
		cur_dep = cur_dep + 1
  until (cur_dep == max_dep or cur_dir=="/" or ready_path ~= nil)

	return ready_path
end

--read_env(".envrc")
a = find_conf(".envrc")
if a ~= nil then print ("path is " .. a) else print ("path not found") end
