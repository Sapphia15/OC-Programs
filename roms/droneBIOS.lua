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
wnc.open(40)

function run()
  while true do
    for i=1,3 do beep(100*i,.5) end
    beep(200,.5)
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