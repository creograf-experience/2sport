# service that restricts user's access to diffirent modules
express = require 'express'
accessRouter = express.Router()
ModuleAccess = require './cms-module'

# middleware for api calls
# checks if that passport user is admin (and not customer)
accessRouter.all '/cms/api/*', (req, res, next) ->
  if req.isAuthenticated() && req.user.role == 'admin'
    next()
  else
    res.status(401).json error: 'Not authenticated'

# middleware gives access to /cms/login page
accessRouter.all '/cms/*', (req, res, next) ->
  if (req.isAuthenticated() && req.user.role == 'admin') || req.path.match /^\/cms\/login/
    next()
  else
    res.status(401).redirect '/cms/login'

# hardcoded modules, each module restricts
# access to corresponding apis
modules =
  pages: ['pages']
  admins: ['admins', 'groups']
  leads: ['leads', 'statuses']
  settings: ['settings']
  files: ['files']
  forms: ['forms']
  news: ['news']
  feedback: ['feedback']

# setting up middlewares for each module.
# if req.user is not allowed to module, middleware returns
# code 403 on corresponding apis
Object.keys(modules).forEach (name) ->
  moduleAccess = new ModuleAccess name, modules[name]
  accessRouter.use moduleAccess.router

# export modules hash for futher use in Admin model where
# default accessess are defined
module.exports =
  middleware: accessRouter
  modules: modules
