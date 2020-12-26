mongoose = require 'mongoose'
Schema = mongoose.Schema
shortid = require 'shortid'
timestamps = require 'mongoose-timestamp'
notify = require '../services/notify'
{ObjectId} = mongoose.Types
_ = require 'lodash'

ChatSchema = new Schema {
  messages: [
    body:
      type: String
      required: true
    createdAt: Date
    sender: Schema.Types.ObjectId
  ]
  users: [Schema.Types.ObjectId]
}, {
  toObject: virtuals: true
  toJson: virtuals: true
}

ChatSchema.plugin timestamps

ChatSchema.virtual('lastMessage').get ->
  @messages[@messages.length - 1]

ChatSchema.path('users').validate(
  (value) -> value.length == 2
  'must be 2 users')

# find a chat with two users (the receiver is passed
# as his slug), or if there's none, create a chat
# with first message
ChatSchema.statics.start = (userId, receiverId, messageBody, next) ->
  unless userId && receiverId
    return next(message: 'require two users to start chat')
  User = mongoose.model('User')
  Chat = mongoose.model('Chat')

  Chat
    .findOne(users: $all: [userId, receiverId])
    .exec (err, chat) ->
      return next(err) if err

      saveCB = (err, chat) ->
        return next(err) if err

        return next(null, chat) unless messageBody

        message =
          createdAt: new Date()
          body: messageBody
          sender: userId
          _id: new ObjectId()

        Chat.update(
          {_id: chat.id},
          {$push: messages: message},
          (err) ->
            return next(err) if err

            chat = chat.toObject()
            chat.messages.push(message)
            notify.messageSent _.extend(message, chatId: chat._id), receiverId

            next(null, chat))

      if chat
        saveCB(null, chat)
      else
        chat = new Chat
          users: [ObjectId(userId), ObjectId(receiverId)]
        chat.save saveCB

ChatSchema.statics.send = (slug, sender, receiver, body, next) ->
  Chat = mongoose.model 'Chat'
  User = mongoose.model 'User'

  unless body
    return next(message: 'message is required')

  message =
    _id: new ObjectId()
    body: body
    createdAt: new Date()
    sender: sender
    slug: slug

  Chat.update(
    {slug: slug},
    {$push: messages: message},
    (err) ->
      return next(err) if err

      notify.messageSent message, receiver
      User.addUnreadChat(receiver._id, slug)
      User.removeUnreadChat(sender._id, slug)
      next())

module.exports = mongoose.model 'Chat', ChatSchema
