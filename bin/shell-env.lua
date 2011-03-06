#!/usr/bin/env lua
require "lfs"
require "posix"

print ("lua shell-env")

read_env = function(filename)
  local f=io.open(filename)
  if f ~= nil then
    for line in f:lines() do
        print (line) 
    end
    f:close()
  end
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
