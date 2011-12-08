exports.fn = (date) -> 
  date = new Date(Date.parse(date)) if typeof date is 'string'
  date = new Date(date) if typeof date is 'number'
  (1900 + date.getYear()).toString()