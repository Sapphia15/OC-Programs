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
fs=gc("filesystem")
gpu=gc("gpu")
sc=gc("screen")
wnc.open(40)

function save()
  file=fs.open("/data.txt","w")
  for i=1,#lines do
    fs.write(file,lines[i].."\n")
  end
  fs.close(file)
end

function run() 
  wnc.close(40)
  if gpu and sc then
    graphics=true
    gpu.bind(sc.address)
  end
  beep(400,.5)
  if not fs.exists("/data.txt") then
    file=fs.open("/data.txt","w")
    fs.write(file,"")
    fs.close(file)
  end
  beep(400,.5)
  file=fs.open("/data.txt","r")
  data=fs.read(file,math.maxinteger or math.huge)
  fs.close(file)
  lines={}
  for ln in string.gmatch(data or "","([^\n]+)") do
    table.insert(lines,ln)
  end
  beep(400,.5)
  if graphics then
    gpu.set(1,1,"File exists: "..tostring(fs.exists("/data.txt")))
  end
  wnc.open(444)
  adr=wnc.address
  while true do
    bc(444,"server","infusion_recipe_db",adr)
    sig={pc.pullSignal(1)}
    if sig[1]=="modem_message" and sig[6]=="rq" and sig[7]==adr then
      retadr=sig[8]
      cmd=sig[9]
      data=sig[10]
      if cmd=="add" then
        lines[#lines+1]=data
        save()
      elseif cmd=="del" then
        if tonumber(data) then
          table.remove(lines,tonumber(data))
        else
          torm={}
          for i=1,#lines do
            if string.find(lines[i],data) then
              torm[#torm+1]=i
            end
          end
          for i=1,#torm do
            table.remove(lines,torm[i])
          end
        end
        save()
      elseif cmd=="select" then
        result=""
        for i=1,#lines do
          if string.find(lines[i],data) then
            result=result..lines[i].."\n"
          end
        end
        wnc.send(retadr,444,"rs",adr,retadr,result)
      end
    end
    --check if current recipe matches a recipe in the table
      --if it does, send the required essentia amount to computer B
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