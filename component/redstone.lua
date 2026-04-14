local G,Go,f,s,e
function gs(g,go)
  go={}
  for k,v in pairs(_G) do
    go[k]=v
    if not g[k] then _G[k]=nil end
  end
  for k,v in pairs(g) do _G[k]=v end
  return go
end
G=gs(_G)
cp=component
pc=computer
beep=pc.beep
function gc(c) return cp.proxy(cp.list(c)()) end
wnc=gc("modem")
function bc(p,...) return wnc.broadcast(p,...) end
rom=gc("eeprom")
rs=gc("redstone")
wnc.open(40)


component={
  CLOSE=function() host=nil end,
  getInput=function(side) return rs.getInput(side) end,
  getOutput=function(side) return rs.getOutput(side) end,
  setOutput=function(side,value) return rs.setOutput(side,value) end,
  getBundledInput=function(side, color)
    color=color or 0
    return rs.getBundledInput(side,color)
  end,
  getBundledOutput=function(side,color)
    color=color or 0
    return rs.getBundledOutput(side,color)
  end,
  setBundledOutput=function(side,color,value) return rs.setBundledOutput(side,color,value) end,
  getComparatorInput=function(side) return rs.getComparatorInput(side) end,
  getWirelessInput=function() return rs.getWirelessInput() end,
  getWirelessOutput=function() return rs.getWirelessOutput() end,
  setWirelessOutput=function(value) return rs.setWirelessOutput(value) end,
  getWirelessFrequency=function() return rs.getWirelessFrequency() end,
  getWakeThreshhold=function() return rs.getWakeThreshhold() end,
  setWakeThreshold=function() return rs.setWakeThreshold() end,
}

function run()
  wnc.close(40)

  nc=wnc
  port=1403
  nc.open(port)
  address=nc.address
  host=nil
  
  while true do
    while not host do
      sig={pc.pullSignal(1)}
      if sig[1]=="modem_message" and sig[4]==port and sig[6]=="component_controller" then
        host=sig[7]
        nc.send(host,port,"component",address,"redstone")
      end
    end
    func=""
    while func~="CLOSE" and host do
      sig={pc.pullSignal(1)}
      if sig[1]=="modem_message" and sig[4]==1403 and sig[6]==host then
        func=sig[7]
        result=component[func](table.unpack(sig,8,13))
        if type(result)=="table" then
          nc.send(host,port,address,table.unpack(result))
        else
          nc.send(host,port,address,result)
        end
      end
    end
  end
end

function set()
  rom.set(sig[7])
  beep(400,.5)
  pc.shutdown(true)
end
function test()
  f,e=load(sig[7])
  if e then
    bc(404,"err",e)
  elseif f then
    oG=gs(G)
    s,e=pcall(f)
    gs(oG)
    if e then bc(404,"err",e) else bc(404,"scc") end
  end
end
while true do
  sig={pc.pullSignal(1)}
  if #sig>5 and sig[1]=="modem_message" then
    if type(_G[sig[6]])=="function" then _G[sig[6]]() end
  end
end