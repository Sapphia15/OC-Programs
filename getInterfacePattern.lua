local component=require("component")
local me=component.me_interface
local dcard=component.data
local nbt=require("nbt")
local hexdump=require("hexdump")
local deflate=require("deflate")
local byteOutputStream=require("byteOutputStream")

local pattern=me.getInterfacePattern(1)

if pattern["tag"] then
  local out=byteOutputStream()
  deflate.gunzip({input=pattern.tag, output=out.write, disable_crc=true})
  pattern.tag=nbt.readFromNBT(out.data)
end

function printTable(t,ind)
  ind=ind or ""
  for k,v in pairs(t) do
    k=tostring(k)
    if type(v)=="table" then
      print(ind..k.." {")
      printTable(v,ind.."  ")
      print(ind.."}")
    else
      print(ind..k.." : "..tostring(v))
    end
  end
end

printTable(pattern)  