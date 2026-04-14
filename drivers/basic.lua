local api=require("netcomponent").api
local port=api.port()

local driver = {
  name="Basic",
  assoc={
    redstone=1
  },

  invoke=function(address,method,...)
    api.send(address,port,method,...)
    return table.unpack(api.listen(address,port),7,13)
  end,

  proxy=function(address) return {
    address=address,
    call=function(method,...)
      api.send(address,port,method,...)
      return table.unpack(api.listen(address),7,13)
    end}
  end,

  --send a close signal to the component to shut it down / disconnect it nicely
  close=function(address)
    api.send(address,port,"CLOSE")
  end,
}
return driver