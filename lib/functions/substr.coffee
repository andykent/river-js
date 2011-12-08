exports.fn = (str, start, len=null) -> 
  str = str.toString()
  if len
    str.substr(start, len)
  else
    str.substr(start)