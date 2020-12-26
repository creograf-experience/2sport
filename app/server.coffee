http = require 'http'
path = require 'path'
config = require 'nconf'

express = require 'express'
mongoose = require 'mongoose'
passport = require 'passport'
favicon = require 'serve-favicon'
bodyParser = require 'body-parser'
methodOverride = require 'method-override'
flash = require 'connect-flash'
multipart = require 'connect-multiparty'
compress = require 'compression'
session = require 'express-session'
MongoStore = require('connect-mongo')(session)

notify = require './services/notify'
access = require './services/access'
cacheManager = require './services/cache-manager'
viewHelpers = require './services/view-helpers'
controllerHelpers = require './services/controller-helpers'
mailer = require './services/mailer'
models = require './models'

app = express()
server = http.createServer(app)
io = require('socket.io')(server)

config.file(file: path.join __dirname, '../config/application.json')

app.set 'port', config.get('port')
app.set 'view engine', 'jade'
app.set 'views', path.join(__dirname, '../views')

# gzip and static files
app.use compress()
app.use express.static(path.join(__dirname, '../public'))

app.use '/docs',
  express.static(path.join(__dirname, '../public/docs'))
# serve compiled templates for angular
app.use '/cms/partials',
  express.static(path.join(__dirname, '../public/angular-templates/cms'))

app.use favicon(path.join(__dirname, '../public/favicon.ico'))

app.use /^\/(resources|partials|images|fonts)\/.*/, (req, res) -> res.status(404).end()

# handle rendered angular to bots
# app.use require('prerender-node')

# use projects ./tmp because nodejs doesn't
# work with fs on other partial.
# ./tmp doesn't get cleaned
app.use multipart(uploadDir: path.join(__dirname, '../tmp'))
app.use bodyParser.urlencoded(extended: false, limit: '50mb')
app.use bodyParser.json(limit: '50mb')

# for PUT, DELETE, PATCH
app.use methodOverride()

app.use session
  secret: config.get('sessionSecret')
  resave: true
  saveUninitialized: true
  store: new MongoStore
    url: config.get("database:#{app.get('env')}")
    autoRemove: 'native'
    touchAfter: 24 * 3600

app.use passport.initialize()
app.use passport.session()

# add controllers helpers
app.use controllerHelpers

# add template  helpers
app.locals = viewHelpers

# we don't use auth middleware and
# mailer in tests
if process.env.NODE_ENV != 'test'
  app.use access.middleware
  mailer.reinit()

# logger is hella slow.
# error handler displays errors
# on 500, only needed in dev
# chat is also run in the same process
# only in development
if process.env.NODE_ENV == 'development'
  app.use require('errorhandler')()
  app.use require('morgan')('dev')

notify.init(io)
app.use notify.socketMiddleware
require('./controllers')(app)
require('./services/passport')

unless app.get('env') == 'test'
  mongoose.connect config.get("database:#{app.get('env')}"), (err) ->
    return console.log err if err

    server.listen app.get('port'), ->
      console.log "MM server listening on port #{app.get('port')}"

module.exports = app
