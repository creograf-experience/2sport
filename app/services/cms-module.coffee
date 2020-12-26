express = require 'express'

# module for restricting access to diffirent apis.
# there are 4 levels of access to module:
# undefined - access denied,
# 1 - allowed only watch (GET request allowed),
# 2 - to create new entries (POST request),
# 3 - to update and delete all entries (PUT and DELETE allowed).
# @param name {String} - the name of the module,
# @param apis {[String]} - apis to block.
# @returns a middleware meant to being applied globally
class ModuleAccess
  constructor: (@name, resourceNames) ->
    @router = express.Router()

    # if apis not provided we take the module's name
    # as api to block
    resourceNames ?= [@name]

    # setting up rules-middlewares for each verb
    resourceNames.forEach (resName) =>
      @accessCheck('get', "/cms/api/#{resName}/?*", 1)
      @accessCheck('post', "/cms/api/#{resName}/?", 2)
      @accessCheck('put', "/cms/api/#{resName}/?*", 3)
      @accessCheck('delete', "/cms/api/#{resName}/?*", 3)

  accessCheck: (method, route, level) =>
    # checking if verb is valid
    unless method in ['all', 'get', 'put', 'post', 'delete']
      return

    # setting middleware for a verb
    # user object that middleware is checking should look like
    # {access: [leads: 3, pages: 2, news: 1]}
    @router[method] route, (req, res, next) =>
      # chack if user
      # 1. is logged,
      # 2. has access array,
      # 3. his access level is sufficient
      if req.user && req.user.access &&
      req.user.access[@name] >= level
        next()
      else
        res.status(403).json(message: 'access denied')

module.exports = ModuleAccess
