passport = require 'passport'
authRouter = require('express').Router()
mongoose = require('mongoose')
User = mongoose.model('User')

config = require('../../../config/auth')
VK = require('vksdk')
FB = require('fb')
TW = require("ntwitter")

#vk oauth
authRouter.post '/vkontakte', (req, res) ->
  vk = new VK
    appId: config.VKONTAKTE_APP_ID,
    appSecret: config.VKONTAKTE_APP_SECRET,
    language: 'ru'

  vk.setToken(req.body.accessToken)
  vk.request 'users.get', {'user_id' : req.body.user_id}, (data) ->
    User.getByVkId data, (err, user) ->
      return res.mongooseError(err) if err

      req.logInAndSave user, (err) ->
        return res.mongooseError(err) if err

        res.json user

authRouter.post '/vkontakte_reg', (req, res) ->
  vk = new VK
    appId: config.VKONTAKTE_APP_ID,
    appSecret: config.VKONTAKTE_APP_SECRET,
    language: 'ru'

  vk.setToken(req.body.accessToken)
  vk.request 'users.get', {'user_id' : req.body.user_id}, (data) ->

    data.email = req.body.email
    User.registerByVk data, (err, user) ->
      # console.log err
      return res.mongooseError(err) if err

      req.logInAndSave user, (err) ->
        return res.mongooseError(err) if err

        res.json user

#fb oauth
authRouter.post "/facebook", (req, res) ->
  FB.api 'me', { fields: ['id', 'name'], access_token: req.body.accessToken }, (data) ->
  	User.getByFbId data, (err, user) ->
      return res.mongooseError(err) if err

      req.logInAndSave user, (err) ->
        return res.mongooseError(err) if err

        res.json user

authRouter.post "/facebook_reg", (req, res) ->
  FB.api 'me', { fields: ['id', 'name'], access_token: req.body.accessToken }, (data) ->
    console.log data
    User.registerByFb data, req.body.email, (err, user) ->
      return res.mongooseError(err) if err

      req.logInAndSave user, (err) ->
        return res.mongooseError(err) if err

        res.json user

#tw oauth
authRouter.post "/twitter", (req, res) ->
  tw = new TW
    consumer_key: config.TWITTER_APP_ID,
    consumer_secret: config.TWITTER_APP_SECRET,
    access_token_key: req.body.accessToken,
    access_token_secret: req.body.secret

  tw.verifyCredentials (err, data) ->
    return res.mongooseError(err) if err

    User.getByTwId data, (err, user) ->
      return res.mongooseError(err) if err

      req.logInAndSave user, (err) ->
        return res.mongooseError(err) if err

        res.json user

authRouter.post "/twitter_reg", (req, res) ->
  tw = new TW
    consumer_key: config.TWITTER_APP_ID,
    consumer_secret: config.TWITTER_APP_SECRET,
    access_token_key: req.body.accessToken,
    access_token_secret: req.body.secret

  tw.verifyCredentials (err, data) ->
    return res.mongooseError(err) if err

    data.email = req.body.email
    User.registerByTw data, (err, user) ->
      return res.mongooseError(err) if err

      req.logInAndSave user, (err) ->
        return res.mongooseError(err) if err

        res.json user

module.exports = authRouter
