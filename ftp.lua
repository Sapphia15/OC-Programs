local shell = require("shell")
local component = require("component")
local filesystem = require("filesystem")
local event = require("event")
local modem = component.modem
local args,options = shell.parse(...)
local filename
local path
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
  local tries=0
  while #data==0 do
    if (tries>2) then
      print("Connection timed out")
    end
    data={event.pull(10,"modem_message")}
    if (data[6]~=filename) then
      data={}
      print("Continuing to await signal...")
    end
    tries=tries+1
  end
  modem.close(21)
  file = filesystem.open(path,"wb")
  file:write(data[7])
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
  local data=file:read(size)
  file:close()
  print("Broadcasting file at strength "..modem.getStrength()..".")
  modem.broadcast(21,filename,data)
end