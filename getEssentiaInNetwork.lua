local component=require("component")
local me=component.list("me_interface")() or component.list("me_controller")()
me=component.proxy(me)
local essentia=me.getEssentiaInNetwork()
for k,v in pairs(essentia) do
  print(tostring(k).." : "..tostring(v))
end