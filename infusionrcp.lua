local component=require("component")
local computer=require("computer")
local shell=require("shell")
local fs=require("filesystem")
local term=require("term")
local io=require("io")
local argument=require("argument")
local wnc=component.modem
local event=require("event")
local args,options=shell.parse(...)
wnc.open(444)
print("Searching for infusion_recipe_db  server...")
local server
while not server do
  local data={event.pull(1,"modem_message")}
  if data[6]=="server" and data[7]=="infusion_recipe_db" then
    server=data[8]
  end
end
wnc.close(444)
print("Server found!")
print("Address: "..server)
local cmd=""
while not (cmd=="exit") do
  cmd=term.read({nowrap=true,dobreak=false})
  cmd=string.sub(cmd,1,#cmd-1) --this is to remove the /n at the end
  local cargs=argument.parse(cmd)
  for i=1,#cargs do
    print(tostring(i).." : "..tostring(cargs[i]))
  end
end