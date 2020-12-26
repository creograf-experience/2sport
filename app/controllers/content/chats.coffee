chatsRouter = require('express').Router()
mongoose = require('mongoose')
Chat = mongoose.model('Chat')
User = mongoose.model('User')
_ = require 'lodash'
notify = require '../../services/notify'
{ObjectId} = mongoose.Types

chatsRouter.get '/*', (req, res, next) ->
  return res.status(403).json(message: 'access denied') unless req.user

  next()

chatsRouter.get '/', (req, res) ->
  Chat.find users: req.user._id, (err, chats) ->
    return res.mongooseError err if err

    chats = chats.map (chat) ->
      receiverId = _.find(
        chat.users
        (user) -> user.toString() != req.user._id.toString())

      chat = _.chain(chat.toObject())
        .extend(receiverId: receiverId)
        .omit(['messages', 'users'])
        .value()

    ids = chats.map (chat) -> chat.receiverId
    User.find(_id: $in: ids).select('name photo').lean().exec (err, users) ->
      return res.mongooseError(err) if err

      chats.forEach (chat) ->
        user = _.find users, (user) ->
          user._id.toString() == chat.receiverId.toString()

        if user
          chat.receiver = user

      sortedChats = _.sortBy chats, (chat) ->
        -chat.updatedAt

      res.json sortedChats

chatsRouter.post '/start', (req, res) ->
  Chat.start req.user._id, req.body.receiverId, req.body.message, res.handleData

chatsRouter.get '/lastmessages', (req, res) ->
  page = +req.query.page || 0
  pageSize = 20

  Chat.findOne(_id: req.query.chatId).lean().exec (err, chat) ->
    return res.mongooseError err if err
    return res.status(404).json message: 'not found' unless chat

    chat.messages = _(chat.messages)
      .dropRight(page * pageSize)
      .takeRight(pageSize)
      .value()

    User.removeUnreadChat(req.user._id, req.query.chatId)

    res.json chat

chatsRouter.post '/:slug', (req, res) ->
  Chat.send(
    req.params.slug
    req.user
    req.body.receiver
    req.body.body
    res.handleData)

chatsRouter.delete '/:slug', (req, res) ->
  Chat.remove slug: req.params.slug, res.handleData

module.exports = chatsRouter
