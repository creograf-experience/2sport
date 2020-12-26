_ = require 'lodash'
passport = require 'passport'
userRouter = require('express').Router()
mongoose = require('mongoose')
{User, UserStat} = require('../../models')
{ObjectId} = mongoose.Types
{areFriends, isInvited, almostFriends} = require('../../services/model-helpers')

checkUser = (req, res, next) ->
  unless req.user && req.user.slug == req.params.slug
    return res.status(403).json message: 'Нет доступа'

  next()

userRouter.post '/', (req, res) ->
  UserStat.findOne(user: req.user._id)
  .populate('foundNeighbors', '-passwordHash -salt')
  .then (us) ->
    return res.json([]) unless us

    res.json us.foundNeighbors

  .catch(res.mongooseError)

userRouter.get '/', (req, res) ->
  UserStat.findOne(user: req.user._id)
  .populate('foundNeighbors', '-passwordHash -salt')
  .then (us) ->
    return Promise.resolve([]) unless us

    Promise.resolve us.foundNeighbors

  .then(res.json)
  .catch(res.mongooseError)

# provide a user object from DB for every action
# accepts slugs and userIds
userRouter.param 'userId', (req, res, next, slug) ->
  User.findById(req.params.userId)
  .select('-passwordHash -salt')
  .exec (err, user) ->
    return res.mongooseError err if err
    return res.status(404).json message: 'Пользователь не найден' unless user

    req.profile = user

    next()

userRouter.get '/:userId', (req, res) ->
  res.json req.profile

module.exports = userRouter
