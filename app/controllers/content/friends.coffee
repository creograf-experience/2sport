passport = require 'passport'
friendsRouter = require('express').Router()
mongoose = require('mongoose')
User = mongoose.model('User')
_ = require 'lodash'
notify = require '../../services/notify'

friendsRouter.post '/', (req, res) ->
  User.addFriend req.user.slug, req.body.slug, (err, data) ->
    return res.mongooseError(err) if err
    return res.status(400).json(message: 'ошибка') if !data

    if data.isInvite
      notify.inviteSent(data.user, req.user)
      res.json data
    else
      notify.friendAdded(data.user, req.user)
      req.user.friends.push data.user._id.toString()
      req.logIn req.user, (err) ->
        console.log err
        return res.mongooseError(err) if err

        res.json data

friendsRouter.post '/decline', (req, res) ->
  User.declineFriend req.user.slug, req.body.slug, (err, data) ->
    return res.mongooseError(err) if err
    return res.status(400).json(message: 'ошибка') if !data

    user = JSON.parse(req.session.passport.user)
    user.friendInvites = user.friendInvites.filter (invite) ->
      invite.slug != req.params.slug
    req.session.passport.user = JSON.stringify(user)

    res.json data

friendsRouter.delete '/:friendId', (req, res) ->
  User.removeFriend req.user._id, req.params.friendId, (err, data) ->
    return res.mongooseError(err) if err

    user = JSON.parse(req.session.passport.user)

    user.friends = user.friends.filter (friend) ->
      friend._id != req.body._id
    req.session.passport.user = JSON.stringify(user)

    res.json data

module.exports = friendsRouter
