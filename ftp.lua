local shell = require("shell")
local component = require("component")
local computer = require("computer")
local filesystem = require("filesystem")
local event = require("event")
local modem = component.modem
local args,options = shell.parse(...)
local filename
local path
local function tableConcat(t1,t2)
  for i = 1,#t2 do
    t1[#t1+1] = t2[i]
  end
  return t1
end

if (#args<2) then
  print("Usage: ftp <push/pull> <file> <strength>")
  print("push will push a file over the network")
  print("pull will try to pull a file with a matching name")
  print("strength is an optional parameter that sets the signal strength.")
else
  if(#args>2 and tonumber(args[3])) then
    modem.setStrength(tonumber(args[3]))
  end
end
if (args[1]=="pull") then
  path=shell.resolve(args[2])
  filename=filesystem.name(path) 
  if (not filesystem.exists(filesystem.path(path))) then
    print "Output directory not found."
    return
  elseif (filesystem.isDirectory(path)) then
    print "Ouput location already exists as a directory."
  end
  print("Awaiting file signal for "..filename.."...")
  modem.open(21)
  local data={}
  local fdata={}
  local endOfFile=false
  print(string.rep("_",50))
  print("|"..string.rep(" ",17).."|"..string.rep(" ",10).."|"..string.rep(" ",19).."|")
  while not endOfFile do
    data={event.pull(10,"modem_message")}
    if data[6]==filename then
      if data[7] == "0" then
        endOfFile=true
        computer.beep(200,.5)
      elseif #fdata+1 < tonumber(data[7]) then
        print(string.rep("-",50))
        print("ERROR:")
        print("Transmition data corrupted!")
        print("Missing packet ID "..(#fdata+1).."!")
        computer.beep(400,1)
        return
      else
        fdata[#fdata+1] = data[8]
        local padding = string.rep(" ",4-string.len(tostring(#data[8])))
        local padding2 = string.rep(" ",4-string.len(data[7]))
        print("| Recieved packet | ID: "..padding2..data[7].." | SIZE(BYTES): "..padding..#data[8].." |")
        computer.beep(400,.1)
      end
    end
  end
  print("|"..string.rep("_",17).."|"..string.rep("_",10).."|"..string.rep("_",19).."|")
  modem.close(21)
  file = filesystem.open(path,"wb")
  for i=1,#fdata do
    file:write(fdata[i])
  end
  file:close()
  print("File received.")
elseif (args[1]=="push") then
  path=shell.resolve(args[2])
  filename=filesystem.name(path)
  if (not filesystem.exists(path)) then
    print("File not found.")
    return
  elseif (filesystem.isDirectory(path)) then
    print("File not found (provided path is a directory).")
    return
  end
  local size=filesystem.size(path)
  local kib=math.floor(size/102.4)*10
  if (size<1024) then
    print("Attempting to push "..size.." bytes of data.")
  else
    print("Attempting to push "..kib.." KiB ("..size.." bytes) of data.")
  end
  local file=filesystem.open(path,"rb")
  print(size)
  chunk=0
  local data={}
  while chunk * 2048 < size do
    chunk = chunk+1
    data[chunk]=file:read(2048)
  end
  file:close()
  print("Packets to be sent: "..#data)
  print("Broadcasing strength: "..modem.getStrength())
  print(string.rep("_",51))
  print("|"..string.rep(" ",16).."|"..string.rep(" ",10).."|"..string.rep(" ",21).."|")
  for i = 1,#data do
    local padding = string.rep(" ",4-string.len(tostring(#data[i])))
    local padding2 = string.rep(" ",4-string.len(tostring(i)))
    print("| Sending packet | ID: "..padding2..i.." | SIZE (BYTES) : "..padding..#data[i].." |")
    modem.broadcast(21,filename,tostring(i),data[i])
    computer.beep(200,.5)
  end
  print("|"..string.rep("_",16).."|"..string.rep("_",10).."|"..string.rep("_",21).."|")
  print("Declaring EOF...")
  modem.broadcast(21,filename,"0")
  print("Broadcast sequence complete.")
end