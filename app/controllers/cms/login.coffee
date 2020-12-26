express = require 'express'
passport = require 'passport'
loginRouter = express.Router()

loginRouter.get '/cms/login', (req, res) ->
  if req.isAuthenticated() && req.user.role == 'admin'
    return res.redirect '/cms/'
  res.render 'cms/login'

loginRouter.post '/cms/login', passport.authenticate('admin',
  successRedirect: '/cms/'
  failureRedirect: '/cms/login')

loginRouter.get '/cms/logout', (req, res) ->
  req.logout()
  res.redirect '/'

module.exports.router = loginRouter
