local hexdump={}

local hex={0,1,2,3,4,5,6,7,8,9,"a","b","c","d","e","f"}

function hexdump.dump(data,showIndex,showDec,showBin,showChar)
  local bytes={string.byte(data,1,#data)}
  local output=""
  for i=1,#bytes do
    local byte=bytes[i]
    local low=byte&0x0f
    local high=byte>>4
    if showIndex then
      output=output..string.rep(" ",#tostring(#bytes)-#tostring(i))..tostring(i).." | "
    end
    output=output.."0x"..hex[high+1]..hex[low+1]
    if showDec then
      output=output.." | "..string.rep(" ",3-#tostring(byte))..tostring(byte)
    end
    if showBin then
      output=output.." | "
      for j=7,0,-1 do
        output=output..tostring((byte>>j)&1)
      end
    end
    if showChar and utf8.char(byte) then
      output=output.." | "..utf8.char(byte)
    end
    output=output.."\n"
  end
  return output
end

return hexdump