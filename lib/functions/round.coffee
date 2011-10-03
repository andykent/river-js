exports.fn = (n,dp=null) -> 
  if dp
    Math.round(n*Math.pow(10,dp))/Math.pow(10,dp)
  else
    Math.round(n)