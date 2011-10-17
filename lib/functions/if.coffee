# IF(a>b, a, b)
# evaluates condition and returns one of the two arguments
exports.fn = (condition, trueValue, falseValue=null) -> 
  if condition
    trueValue
  else
    falseValue