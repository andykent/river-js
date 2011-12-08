exports.fn = (args...) -> 
  flat = []
  for a in args
    if a.constructor is Array
      flat.push(b) for b in a
    else
      flat.push(a)
  flat.join('')