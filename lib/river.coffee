Context = require('./context').Context

# createContext
# -------------
# Everything in River happens within a context.
# You can consider it a container much like a DataBase in an RDBMS
exports.createContext = () -> new Context()