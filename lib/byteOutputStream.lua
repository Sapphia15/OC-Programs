--creates a byteOutputStream
--
--byteOutputStream.data : an array of character representations of bytes
--
--byteOutputStream.write(b) : a function that writes one byte to the data array
return function()
  local stream={}
  stream.data={}
  stream.write = function(b)
    stream.data[#stream.data+1] = utf8.char(b)
  end
  return stream
end