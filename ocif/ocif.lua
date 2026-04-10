----------------------------

--Open Computers Interface--

      --(ocif)--

----------------------------

--Note: connecting to a private ip is disabled on most servers.
--This is code is intended for local play or on private servers.
--(for private servers, it is reccomended to be on the same local network)
--You may need to change your (or the server's) open computers config to allow your private ip connections.
--The relevant setting is internet.filteringRules.

--Change default ip to the your ip if you are not usually going to be connecting to localhost
--(e.g. if you are connected to a private server on a different computer,
-- then you will need to put you own computer's ip since your OC computer is actually connecting
-- from the computer hosting the server)

local defualtIP="127.0.0.1"
local defaultPort=26656

local fs=require("filesystem")
local io=require("io")
local shell=require("shell")
local component = require("component")
local internet = component.internet
local args,options=shell.parse(...)
local connectionIP=defualtIP

local function printUsage()
  print("Usage:")
  print("ocif <'get'/'put'> <file> <port=26656> <ip=defaultIP>")
end

local function connect(address,port)
  local socket=internet.connect(address,port)
  local ok=false
  if socket then
    socket.finishConnect()
    ok=true
  end
  return socket,ok
end

local function readData(socket,n)
  local data=""
  while #data<n do
    data=data..(socket.read(n-#data))
  end
  return data
end



if #args < 2 then
  printUsage()
  return
end
local port=tonumber(args[3])
if not port then
  print("Port not specified, defualting to port "..defaultPort..".")
  port=defaultPort
end
if args[4] then
  connectionIP=args[4]
end

if args[1]=="get" then
  
  local socket,ok=connect(connectionIP,port)
  if not ok then
    print("Connection failed!")
    return
  end
  print("Listening to localhost on port "..port.." .")
  local data=""
  local size=4
  while size>0 do
    print("Listening for next packet size...")
    local rdata=readData(socket,4)
    --convert bytes into an integer (decodes integer in little endian).
    size=string.byte(rdata,1) | (string.byte(rdata,2)<<8) | (string.byte(rdata,3)<<16) | (string.byte(rdata,4)<<24)
    print("Downloading "..size.." byte packet...")
    data=data..readData(socket,size);
  end
  print("Next packet size is 0 bytes.")
  print("All packets recieved.")
  socket.close()
  print("Disconnected.")
  print("Saving file...")
  local file=io.open(args[2],"wb")
  if file then
    file:write(data)
    file:close()
    print("File saved!")
  else
    print("Error: Could not write to file!")
  end
elseif args[1]=="put" then
  if (not fs.exists(shell.resolve(args[2]))) or fs.isDirectory(args[2]) then
    print("Error: File does not exist.")
    return
  end
  local file=fs.open(shell.resolve(args[2]),"rb")
  if not file then
    print("Error: could not open file.")
    return
  end
  local packets={}
  local rdata="init"
  while rdata do
    rdata=file:read(1024)
    packets[#packets+1]=rdata
  end
  local socket,ok=connect(connectionIP,port)
  if not ok then
    print("Connection failed!")
    return
  end
  for i=1,#packets do
    print("Sending packet "..i.." ("..#(packets[i]).." bytes)...")
    local size=#(packets[i])
    local sizeb=""
    for j=0,3 do --encode size into bytes in little endian
      sizeb=sizeb..string.char((size>>(j*8))&0xff)
    end
    socket.write(sizeb)
    socket.write(packets[i])
  end
  socket.write(string.char(0x00,0x00,0x00,0x00))
  print("All data sent.")
  socket.close()
  print("Disconnected")
elseif args[1]=="help" then
  printUsage()
else
  print("Error: Invalid operation. Expected 'get' or 'put' but got "..args[1]..".")
  printUsage()
  return
end