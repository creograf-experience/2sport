_ = require('lodash')
{User, UserStat} = require('../models')
notify = require('./notify')

SPAM_INTERVAL = 432e5

assignSpam = (users) ->
  users.reduce ((p, user) ->
    p.then (spammedUsers) ->
      UserStat.nearestNeighbor(user._id)
      .then (nearestNeighbor) ->
        if nearestNeighbor
          spammedUsers = spammedUsers.concat([user])


        Promise.resolve(spammedUsers)
  ), Promise.resolve([])

sendSpam = (users) ->
  UserStat
  .find({
    lastRecommendationAt:
      $lt: Date.now() - SPAM_INTERVAL})
  .populate('user', '-passwordHash -salt')
  .populate('pushQueue', '-passwordHash -salt')
  .then (stats) ->
    Promise.all(stats.map (us) ->
      unless us.user.showSuggestions && (us.user.apnToken || us.user.gcmId) && us.pushQueue && us.pushQueue.length > 0
        return Promise.resolve(false)

      recommendation = _.first(us.pushQueue)
      notify.sendRecommendation(us.user, recommendation)

      us.lastRecommendationAt = Date.now()
      us.pushQueue = us.pushQueue.filter (user) ->
        recommendation._id.toString() != user._id.toString()

      us.save()
    )

module.exports = ->
  User.find()
  .then(assignSpam)
  .then(sendSpam)

# $where: ->
#   a = 1 - (this.utcOffset || 5)
#   b = 23 - (this.utcOffset || 5)
#   n = (new Date()).getUTCHours()

#   (b > a && n >= a && n <= b) || ((b <= a) && ((n <= b && n >= 0) || (n >= a && n <= 23))))