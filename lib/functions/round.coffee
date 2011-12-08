exports.fn = (n,dp=null) ->
  n = Number(n) unless n.constructor is Number
  if dp
    Math.round(n*Math.pow(10,dp))/Math.pow(10,dp)
  else
    Math.round(n)