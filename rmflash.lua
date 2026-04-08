local shell = require("shell")
local component = require("component")
local filesystem = require("filesystem")
local event = require("event")
local modem = component.modem
local args,options = shell.parse(...)
if (#args==0) then
  print("Usage: rmflash <'run'/file> <strength> <-t>")
  print("run will make the target run its main program and won't flash an image.")
  print("otherwise the file will be flashed onto the target and it will reboot.")
  print("strength is an optional parameter that sets the signal strength.")
  print("-t option will test the file without overwriting the eeprom.")
  print("Note: not all roms support -t, in that case -t will do nothing.")
elseif (args[1]=="run") then
  if (#args>1 and tonumber(args[2])) then
    modem.setStrength(tonumber(args[2]))
  end
  print("Broadcasting run message at strength "..modem.getStrength()..".")
  modem.broadcast(40,"run")
else
  if (#args>1 and tonumber(args[2])) then
    modem.setStrength(tonumber(args[2]))
  end
  if (not filesystem.exists(shell.resolve(args[1]))) then
    print("File not found.")
    return
  elseif (filesystem.isDirectory(shell.resolve(args[1]))) then
    print("File not found (provided path is a directory).")
    return
  end
  local size=filesystem.size(shell.resolve(args[1]))
  local kib=math.floor(size/102.4)/10
  if (size>4096) then
    print("Cannot flash more than 4KiB!")
    print("Your image is "..kib.." KiB ("..size.." bytes)!")
    return
  elseif (size<1024) then
    print("Attempting to flash "..size.." bytes of data.")
  else
    print("Attempting to flash "..kib.." KiB ("..size.." bytes) of data.")
  end
  local file=filesystem.open(shell.resolve(args[1]),"rb")
  local data=file:read(2048)
  if size>2048 then --for some reason it can only read 2048 bytes at a time...
    data=data..file:read(2048)
  end
  file:close()
  print("Broadcasting image at strength "..modem.getStrength()..".")
  if options["t"] then
    print("Testing mode. EEPROM will not be flashed.")
    modem.broadcast(40,"test",data)
    print("Scanning for errors...")
    print("Use Ctrl+Alt+C to stop scanning at any time.")
    modem.open(404)
    local data={}
    while #data==0 do
      data={event.pull(1,"modem_message")}
    end
    if #data>5 then
      if data[6]=="err" then
        print("\27[31m"..data[7])
      elseif data[6]=="scc" then
        print("\27[32mSuccess")
      end
    else
      print("Success")
    end
    modem.close(404)
  else
    modem.broadcast(40,"set",data)
  end
end