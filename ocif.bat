::ocif is short for open computer interface
::
::Usage:
::ocif <'put'/'get'> <file> <port=26656>
::
::The point of this command is to send and recieve files directly to or from an open computers computer.
::This command should be run before the command on the OC computer because java ocif runs a server that
::the OC ocif program connects to as a client. So since the server has to be up before a client can connect,
::you have to run java ocif (what this command does) before running OC ocif (running ocif on your OC computer)
::no matter what operation you're doing

@ECHO OFF
java -jar ocif/ocif.jar %*