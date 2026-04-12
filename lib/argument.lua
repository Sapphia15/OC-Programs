local argument={}

local function findQuote(s,qt,off,esc)
  s=string.gsub(s,esc..esc,"["..esc..esc.."]") --isolate escaped escape characters
  while string.find(s,qt,off) do
    local qi = string.find(s,qt,off)
    if qi==off then
      return qi
    elseif string.sub(s,qi-string.len(esc),qi-1)==esc and string.sub(s,qi-(2*string.len(esc)),qi-string.len(esc)-1)~=esc then
      off=qi+1
    else
      return qi
    end
  end
end

--doesn't handle escaping quotes
--set dl to change delimeter (default is space)
--set qt to change quote character (default is ")
function argument.parse(s,dl,qt,esc)
  dl=dl or " "
  qt=qt or "\""
  esc=esc or "\\"
  local args={}
  while #s>0 do
    local si=string.find(s,dl)
    local arg
    if si then
      arg=string.sub(s,1,si-1)
    else
      arg=s
    end
    if string.sub(s,1,1)==qt and findQuote(s,qt,2,esc) then
      local qi=findQuote(s,qt,2,esc)
      arg=string.sub(s,2,qi-1)
      --replace \" with " and \\ with \
      arg=string.gsub(arg,esc..esc,"["..esc..esc.."]") --isolate escaped escape characters from quotes
      arg=string.gsub(arg,esc.."\"","\"") --replace escaped quotes with quotes
      arg=string.gsub(arg,"%["..esc..esc.."%]",esc) --replaces isolated escaped escape characters with escape character
      s=string.sub(s,qi)
      si=string.find(s,dl)
    end
    if si then
      s=string.sub(s,si+1)
    else
      s=""
    end
    args[#args+1] = arg
  end
  return args
end

return argument