local argument={}

--doesn't handle escaping quotes
--set dl to change delimeter (default is space)
--set qt to change quote character (default is ")
function argument.parse(s,dl,qt)
  dl=dl or " "
  qt=qt or "\""
  local args={}
  while string.find(s,dl) do
    local si=string.find(s,dl)
    local arg=string.sub(s,1,si-1)
    if string.sub(s,1,1)==qt and string.find(s,qt,2) then
      local qi=string.find(s,qt,2)
      arg=string.sub(s,1,qi)
      s=string.sub(s,qi)
      si=string.find(s,dl)
    end
    s=string.sub(s,si+1)
    args[#args+1] = arg
  end
  return args
end

return argument