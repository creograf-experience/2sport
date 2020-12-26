fs = require 'fs'
path = require 'path'
_ = require 'lodash'
gcm = require 'node-gcm'
apn = require 'apn'
mongoose = require 'mongoose'

apnConnection = new apn.Connection(
  cert: path.resolve(__dirname, '../../config/cert.pem')
  key: path.resolve(__dirname, '../../config/key.pem')
)
gcmSender = new gcm.Sender('AIzaSyAwUujaHTUM68IK_eBucAfJkuPiE5X74iI')
io = null
sockets = {}

# feedback = new apn.Feedback
#   batchFeedback: true
#   interval: 300
#   cert: path.resolve(__dirname, '../../config/cert.pem')
#   key: path.resolve(__dirname, '../../config/key.pem')
#   production: false
# feedback.on "feedback", (devices) ->
#   devices.forEach (item) ->
#     console.log 'apn feedback:', item.device, item.time

findById = (userId) ->
  userId = userId

  return _.chain(sockets)
    .map((data) -> data)
    .find((data) -> data && data.user == userId)
    .value()

sendPush = ({gcmId, apnToken}, title, data) ->
  sendGcmPush(gcmId, title, data) if gcmId
  sendApnPush(apnToken, title, data) if apnToken

sendApnPush = (apnToken, title, data) ->
  userDevice = new apn.Device(apnToken)
  note = new apn.Notification()

  note.alert = title
  note.payload = data
  apnConnection.pushNotification(note, userDevice)

sendGcmPush = (gcmId, title, data) ->

sendGcmMessage = (gcmIds, title, body) ->
  message = new gcm.Message()

  message.addData('title', title)
  message.addData('message', body)

  gcmSender.send message, registrationTokens: gcmIds, (err, response) ->
    console.error(err) if err
    console.log(response) if response

# store connected socket in sockets objects,
# so at can be found by userId or socketId
init = (newIO) ->
  Chat = mongoose.model('Chat')
  io = newIO.of('/notify')
  io.on 'connection', (socket) ->
    console.log "client connected #{socket.id}"
    sockets[socket.id] = socket: socket

    socket.on 'init', (userId) ->
      console.log "init socket with userId=#{userId}"
      sockets[socket.id].user = userId

    socket.on 'chat:send',(data) ->
      userId = sockets[socket.id].user

      Chat.start userId, data.receiverId, data.messageBody, (err, smth) ->

    socket.on 'disconnect', (data) ->
      console.log 'disconnected socket'
      delete sockets[socket.id]

messageSent = (message, receiverId) ->
  return unless message

  message.type = 'message'

  senderSocket = findById(message.sender)
  receiverSocket = findById(receiverId)

  return unless senderSocket

  if senderSocket
    senderSocket.socket.emit 'chat:confirm'

  mongoose.model('User')
  .find(_id: $in: [message.sender, receiverId])
  .select('name photo gcmId apnToken')
  .exec (err, users) ->
    return next(err) if err

    sender = _.find users, id: message.sender
    receiver = _.find users, id: receiverId

    if receiverSocket
      message.sender = sender
      receiverSocket.socket.emit 'chat:receive', message
    else
      sendPush(receiver, sender.name, message)

sendRecommendation = (user, recommendedUser) ->
  recommendedUser = _.extend(
    recommendedUser.toObject(),
    type: 'recommendation')

  if user.locale == 'ru'
    title = 'Возможный напарник'
  else
    title = 'Possible partner'

  sendPush(user, title, recommendedUser)

socketMiddleware = (req, res, next) ->
  return next() unless req.user && req.user._id

  socket = findById(req.user._id)

  return next() unless socket

  req.sid = socket.socket.id

  next()

module.exports = {init, socketMiddleware, messageSent, sendRecommendation}
