#!/usr/bin/env lua

print ("lua shell-env")
print (">>>>>>>>>>>>>>>")


read_env = function(filename)
  local f=io.open(filename)
  if f ~= nil then
    for line in f:lines() do
        print (line) 
    end
    f:close()
  end
end

read_env(".envrc")
