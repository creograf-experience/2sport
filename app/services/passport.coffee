config = require 'nconf'
passport = require 'passport'
crypto = require 'crypto'
mongoose = require 'mongoose'
AuthLocalStrategy = require('passport-local').Strategy
require '../models'
_ = require 'lodash'
config = require('../../config/auth')[process.env.SERVER || 'test']

Admin = mongoose.model('Admin')
User = mongoose.model('User')

passport.use 'user', new AuthLocalStrategy
  usernameField: 'email'
  passwordField: 'password'
  (email, password, next) ->
    User.findOne(email: email).exec (err, user) ->
      return next(err) if err
      if !user || !user.authenticate(password)
        return next(message: 'Неверный логин или пароль', false)

      # if user.isBanned
      #   next(message: 'Вы забанены')

      user = _.omit user.toObject(virtuals: true), ['passwordHash', 'salt']

      next(null, user)

passport.use 'admin', new AuthLocalStrategy
  usernameField: 'login'
  passwordField: 'password'
  (login, password, next) ->
    Admin.findOne login: login, (err, admin) ->
      return next(err) if err
      if !admin || !admin.authenticate(password)
        return next(null, false, message: 'Неверный логин или пароль')

      next(null, _.extend admin.toObject(virtuals: true), role: 'admin')

passport.serializeUser (admin, next) ->
  next(null, JSON.stringify(admin))

passport.deserializeUser (data, next) ->
  try
    next null, JSON.parse(data)
  catch err
    next err

module.exports = passport
