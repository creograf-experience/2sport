mongoose = require 'mongoose'
Page = mongoose.model 'Page'
CmsModule = mongoose.model 'CmsModule'
async = require 'async'
clientRouter = require('express').Router()

secureApi = (req, res, next) ->
  if req.method == 'GET' || (req.isAuthenticated() && req.user.role == 'user')
    return next()

  res.status(403).end()

headers = (req, res, next) ->
  res.header('X-UA-Compatible', 'IE=10')
  res.header('Cache-Control', 'no-cache, no-store, must-revalidate')
  res.header('Pragma', 'no-cache')
  res.header('Expires', 0)

  next()

clientRouter.use headers

clientRouter.use '/api/auth', require('./auth')
clientRouter.use '/api/oauth', require('./oauth')

# block all POSTs and PUTs not routed into auth
clientRouter.all '/api/*', secureApi unless process.env.NODE_ENV == 'test'

clientRouter.use '/api/user', require('./user')
clientRouter.use '/api/users', require('./users')
clientRouter.use '/api/friends', require('./friends')
clientRouter.use '/api/chats', require('./chats')
clientRouter.use '/api/workouts', require('./workouts')
clientRouter.use '/api/payment', require('./payment')
clientRouter.use '/api/social', require('./social')

# не даем вываливать index.html на любой запрос
clientRouter.get '/api/*', (req, res) -> res.status(404).end()

clientRouter.use require('./pages')

# отдаем файл с энгуляром на все оставшиеся
# запросы, чтобы он сам решал и роутил
clientRouter.get '/*', (req, res, next) ->
  res.status(404).end()

module.exports = clientRouter
