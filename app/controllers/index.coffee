module.exports = (app) ->
  app.use require('./cms')
  app.use require('./content')
