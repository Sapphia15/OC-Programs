local component=require("component")
local me=component.me_interface
local dcard=component.data
local nbt=require("nbt")
local hexdump=require("hexdump")
local deflate=require("deflate")
local byteOutputStream=require("byteOutputStream")

local pattern=me.getInterfacePattern(1)

if not pattern.tag then
  print("No NBT data.")
  return
end

local out=byteOutputStream()
deflate.gunzip({input=pattern.tag, output=out.write, disable_crc=true})
local data=nbt.readFromNBT(out.data)
local inputs=data["in"]
print("Input array size: "..#inputs)
local aspects={}
for i=1,#inputs do
  local item=inputs[i]
  if item.tag then if item.tag.Aspects then
    print("aspect found")
    aspects[#aspects+1] = {type=item.tag.Aspects[1].key,amount=item.tag.Aspects[1].amount}
  end end
end
for i=1,#aspects do
  print(string.rep(" ",3-#tostring(aspects[i].amount))..aspects[i].amount.." | "..aspects[i].type)
end