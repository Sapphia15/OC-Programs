local port=1403
local component=component or require("component")
local computer=computer or require("computer")
local netcards=component.list("modem")
local wnc --wireless network card
local nc --wired network card

--find a wireless network card and/or wired network card
for netcard in netcards do
  netcard=component.proxy(netcard)
  if netcard.isWireless() and not wnc then
    wnc=netcard
  elseif not netcard.isWireless() and not nc then
    nc=netcard
  elseif wnc and nc then
    break
  end
end

local error=error
if not error then
  if wnc then
    error=function(e) wnc.broadcast(404,"err",e) end
  elseif nc then
    error=function(e) nc.broadcast(404,"err",e) end
  else
    error=function()
      computer.beep(400,.5)
      computer.beep(400,.5)
    end
  end
end

if not wnc and not nc then
  error("No network card detected!")
  return nil
end



local netcomponent = {}
local drivers={}
local driverAssociations={}
local driverPATH={"/drivers","/usr/drivers","/home/drivers"}
local components={}--wired components
local wcomponents={}--wireless components

local filesystem
if computer.getBootAddress() then
  filesystem=component.proxy(computer.getBootAddress())
else
  filesystem=component.proxy(component.list("filesystem")())
end

local function send(address,port,...)
  if components[address] then
    nc.send(address,port,nc.address,...)
  elseif wcomponents[address] then
    wnc.send(address,port,wnc.address,...)
  end
end

local function listen(address,p)
  p=p or port
  while true do
    local sig={computer.pullSignal(1)}
    if sig[1]=="modem_message" and sig[4]==port and sig[6]==address then
      return sig
    end
  end
end

--api mainly for drivers
netcomponent.api = {
  wnc = function() return wnc end,
  nc = function() return nc end,
  get=function(address) return components[address] or wcomponents[address] end,
  port=function() return port end,
  fs=function() return filesystem end,
  error=function() return error end,
  send=function(address,port,...) return send(address,port,...) end,
  listen=function(address,port) return listen(address,port) end,
  getCard=function(address) if components[address] then return nc elseif wcomponents[address] then return wnc end end,
  getDrivers=function() return drivers end,
  getAssociations=function() return driverAssociations end,
}




function netcomponent.loadDriver(path,fs)
  fs=fs or filesystem
  --search driver paths
  if not fs.exists(path) then
    for i=1,#driverPATH do
      if fs.exists(driverPATH.."/"..path) then
        path=driverPATH.."/"..path
        break
      elseif fs.exists(driverPATH..path) then
        path=driverPATH..path
        break
      end
    end
  end
  local file=fs.open(path,"r")
  local data=fs.read(file,math.maxinteger or math.huge)
  fs.close(file)
  local f,e=load(data)
  if e then
    error(e)
  elseif f then
    local ok,driver=pcall(f) --should return a table representing the driver
    if not ok then
      error(driver)
      return
    end
    drivers[#drivers+1] = driver
    for k,v in pairs(driver.assoc) do
      --this should give association priority to the earliest loaded, highest priority driver.
      if driverAssociations[k] then
        --only set association if v is larger than the current priority
        --to yield to the earliest loaded driver if the priority is tied
        if v>driverAssociations[k].priority then 
          driverAssociations[k]={driver=driver,priority=v}
        end
      else
        --if there was no associations for this device name, then make the association with this driver
        driverAssociations[k]={driver=driver,priority=v}
      end
    end
  end
end

--recursively loads drivers from a list of directories (defaut is driverPATH list)
function netcomponent.loadDrivers(fs,directories)
  directories=directories or driverPATH
  fs=fs or filesystem
  for i=1,#directories do
    local path=directories[i]
    if fs.exists(path) and fs.isDirectory(path) then
      local list=fs.list(path)
      local subdirs={}
      for j=1,#list do
        local subpath=path
        if string.sub(path,#path,#path)~="/" then subpath=path.."/" end
        subpath=subpath..list[j]
        if fs.exists(subpath) then
          if fs.isDirectory(subpath) then
            subdirs[#subdirs+1] = subpath
          else
            netcomponent.loadDriver(subpath,fs)
          end
        end
      end
      if #subdirs>0 then netcomponent.loadDrivers(fs,subdirs) end
    end
  end
end

--default driver
drivers[1]={
  name="Default",

  dapi={},
  
  --driver associations
  --format: assoc[str: device]=int: priority
  --when interacting with a device, the driver with the highest priority association will be used.
  --(in the case of a tie, the earliest loaded tied driver will have priority)
  assoc={},

  --note: this driver can only handle up to to 6 arguments
  --additionally, those arguments can only be strings, integers, booleans, or nil
  --also, if the method name is invalid, no error will be thrown
  --this function blocks until it recieves a response from the component
  invoke=function(address,method,...)
    send(address,port,method,...)
    return listen(address)
  end,

  --usually, this would give you a nice table that lets you cleanly interface with the component
  --in this case though, it just gives you a 'call' function that does the same thing as invoke
  --(except you don't need to specify the address)
  proxy=function(address) return {
    address=address,
    call=function(method,...)
      send(address,port,method,...)
      return listen(address)
    end}
  end,

  --send a close signal to the component to shut it down / disconnect it nicely
  close=function(address)
    send(address,port,"CLOSE")
  end,

  --a general api exposed to the user which should pertain to the driver and/or the component(s)
  --that the driver was written for
  --if an api like this is unnessary then just return an empty table.
  --also, the reason this is a function that returns a table is so that,
  --if the user alters the returned table,then the driver's api table won't get modified
  api=function() return{
    send=send,
    listen=listen
  }end
}

function netcomponent.clearDrivers()
  drivers={}
  driverAssociations={}
end

function netcomponent.getDrivers()
  local names={}
  for _,v in pairs(drivers) do
    names[#names+1] = v.name
  end
  return names
end

--removes a component from the registry tables and attempts to shutdown / disconnect the component gracefully
--the gracefull shutdown / disconnection is handle by the component's driver (the driver.close function)
function netcomponent.unregisterComponent(address)
  local component=components[address] or wcomponents[address]
  components[address]=nil
  wcomponents[address]=nil
  if driverAssociations[component.name] then
    return driverAssociations[component.name].driver.close(address)
  else
    return drivers[1].close(address)
  end
end

--close component connections and close port
function netcomponent.close(p)
  p=p or port
  port=p
  --shutdown all components nicely
  for add,_ in pairs(components) do
    netcomponent.unregisterComponent(add)
  end
  for add,_ in pairs(wcomponents) do
    netcomponent.unregisterComponent(add)
  end
  --close port on applicable network cards
  if nc then nc.close(p) end
  if wnc then wnc.close(p) end
end

--adds a component to the registry tables
function netcomponent.registerComponent(address,name,wireless)
  if wireless then
    wcomponents[address]={
      name=name or "Wireless Net Component",
      address=address,
      wireless=true
    }
  else
    components[address]={
      name=name or "Wired Net Component",
      address=address,
      wireless=false
    }
  end
end

--opens port and registers components
--broadcasts ["component_controller", host address]
--accepts components when they respond with ["component",address,name]
function netcomponent.registerComponents(duration)
  duration=duration or 3

  local wirelessAddress
  if nc then
    nc.open(port)
    nc.broadcast(port,"component_controller",nc.address)
  end
  if wnc then
    wnc.open(port)
    wnc.broadcast(port,"component_controller",wnc.address)
    wirelessAddress=wnc.address
  end

  local startTime=computer.uptime()
  while computer.uptime() < startTime+duration do
    local sig={computer.pullSignal(1)}
    if sig[1]=="modem_message" and sig[4]==port and sig[6]=="component" and sig[7]~=nil then
      netcomponent.registerComponent(sig[7],sig[8],sig[2]==wirelessAddress)
    end
  end
end

--load drivers, register components, and open ports (ports are during component registry)
--set loadDrivers to false to disable automatically loading drivers from driverPATH directories
--set p to the disired port of leave nil for the default port (recommended)
--set scanDuration to designate the amount of time that is allowed to be spent scanning
--(note: total max scanDuration is scanDuration * 2 because both wireless and wired connections may be scanned)
--set fs to the desired filesystem component to load drivers from or leave nil for default
--(note: fs should a filesystem component proxy, not the filesystem api from openOS)
function netcomponent.open(loadDrivers,p,scanDuration,fs)
  p=p or port
  port=p
  fs=fs or filesystem
  if loadDrivers==nil or loadDrivers then netcomponent.loadDrivers(fs) end
  netcomponent.registerComponents(scanDuration)
end

--directly invoke a specified method on the specified component using the driver's invoke function.
function netcomponent.invoke(address,method,...)
  local component=components[address] or wcomponents[address]
  if driverAssociations[component.name] then
    return driverAssociations[component.name].driver.invoke(address,method)
  else
    return drivers[1].invoke(address,method,...)
  end
end

--get a proxy of the specified component
--results may vary depending on the driver implentation
--the Default driver just returns a table with the component address and a 'call' function
--which just calls the Default driver's invoke function without the component address needing to be specified
function netcomponent.proxy(address)
  local component=components[address] or wcomponents[address]
  if driverAssociations[component.name] then
    return driverAssociations[component.name].driver.proxy(address)
  else
    return drivers[1].proxy(address)
  end
end

--get the general api exposed by the driver for the specified component
function netcomponent.driverAPI(address)
  local component=components[address] or wcomponents[address]
  if driverAssociations[component.name] then
    return driverAssociations[component.name].driver.api()
  else
    return drivers[1].api()
  end
end

--get the name of the driver being used for the specified component
function netcomponent.getDriver(address)
  local component=components[address] or wcomponents[address]
  if driverAssociations[component.name] then
    return driverAssociations[component.name].driver.name
  else
    return drivers[1].name
  end
end

--get component iterator for components with specified name or all components if name is omitted/empty
--can filter based on weather component is wirless (defaults to both)
function netcomponent.list(name,wireless)
  local list={}
  
  local function check(component)
    if name==nil or name=="" or string.lower(component.name)==string.lower(name) then
      list[#list+1]={address=component.address,name=component.name,wireless=component.wireless}
    end
  end
  if not wireless then
    for _,v in pairs(components) do check(v) end
  end
  if wireless==nil or wireless then
    for _,v in pairs(wcomponents) do check(v) end
  end

  local index=0
  return function()
    index=index+1
    if index<=#list then return list[index].address,list[index].name,list[index].wireless end
  end
end

return netcomponent