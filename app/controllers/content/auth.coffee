passport = require 'passport'
authRouter = require('express').Router()
mongoose = require('mongoose')
User = mongoose.model('User')
_ = require 'lodash'
locales = ['en', 'ru']

authRouter.post '/login', (req, res, next) ->
  ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress
  passport.authenticate('user', (err, user, info) ->
    return res.status(401).json err if err
    return res.status(403).json message: 'Вы забанены' if user.isBanned

    req.logInAndSave user, (err) ->
      return res.status(401).json err if err

      res.json _.omit user, ['passwordHash', 'salt']
  )(req, res, next)

authRouter.post '/register', (req, res) ->
  user = new User req.body
  user.save (err, user) ->
    return res.mongooseError err if err

    req.logInAndSave user, (err) ->
      return res.status(401).json err if err

      res.json _.omit user.toObject(), ['passwordHash', 'salt']

authRouter.post '/logout', (req, res) ->
  req.logout()
  res.end()

authRouter.post '/preparereset', (req, res) ->
  User.prepareReset req.body.email, (err) ->
    return res.mongooseError err if err

    res.end()

authRouter.post '/verifyreset', (req, res) ->
  User
    .findOne(email: req.body.email, resetPassCode: req.body.code)
    .exec (err, user) ->
      return res.mongooseError(err) if err
      return res.status(403).end() unless user

      res.end()


authRouter.post '/resetpass', (req, res) ->
  User.changePass req.body, (err, customer) ->
    return res.mongooseError err if err

    res.end()

authRouter.post '/setlocale', (req, res) ->
  unless req.user && _.includes(locales, req.body.locale)
    return res.end()

  User.update {_id: req.user._id}, {locale: req.body.locale}, res.handleData

module.exports = authRouter
