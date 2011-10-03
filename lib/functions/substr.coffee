exports.fn = (str, start, len=null) -> 
  if len
    str.substr(start, len)
  else
    str.substr(start)