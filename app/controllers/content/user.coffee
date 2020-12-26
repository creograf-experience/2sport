router = require('express').Router()
mongoose = require('mongoose')
User = mongoose.model('User')
_ = require 'lodash'

router.use (req, res, next) ->
  return res.status(403).end() unless req.user && req.user._id

  User
    .findById(req.user._id)
    .select('-passwordHash -salt')
    .exec (err, user) ->
      return res.mongooseError(err) if err
      unless user
        return res.status(404).json(messages: ['user not found'])

      req.profile = user

      next()

router.get '/', (req, res) ->
  res.json req.profile

router.put '/', (req, res) ->
  _.extend req.profile, _.omit(req.body, ['photo'])

  req.profile.save res.handleData

router.post '/photo', (req, res) ->
  req.profile.attach 'photo', req.files.file, (err) ->
    return res.mongooseError err if err

    req.profile.save (err, updatedUser) ->
      return res.mongooseError err if err

      req.logIn updatedUser, (err) ->
        return res.mongooseError(err) if err

        res.json updatedUser

router.delete '/photo', (req, res) ->
  req.profile.photo = null

  req.profile.save res.handleData

module.exports = router
