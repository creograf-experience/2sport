mongoose = require 'mongoose'
Schema = mongoose.Schema
timestamps = require 'mongoose-timestamp'
{ObjectId} = Schema.Types
_ = require 'lodash'

{clusterize, midpoint, minDistanceBetweenClusters} = require('../services/data-helpers')
{m2r, matchingAges, matchingGenders} = require('../services/model-helpers')

UserStatSchema = new Schema

  # photo, name, meanSpeed
  user:
    type: ObjectId
    ref: 'User'
    required: true

  # running, cycling, skiing
  clusters: [
    activity:
      type: String
      default: 'running'
    location: [Number]
  ]

  foundNeighbors: [
    type: ObjectId
    ref: 'User'
  ]

  pushQueue: [
    type: ObjectId
    ref: 'User'
  ]

  lastRecommendationAt:
    type: Date
    default: 0

# add createdAt, updatedAt
UserStatSchema.plugin timestamps

UserStatSchema.index(locations: '2dsphere')

UserStatSchema.virtual('distance')
.get(-> @_distance)
.set((value) -> @_distance = value)

UserStatSchema.statics.updateUserStats = (user) ->
  return Promise.reject(message: 'provide user id') unless user

  {Workout, UserStat} = require('./index')
  Workout.find({user})
  .then (wouts) ->
    return Promise.resolve() unless wouts.length > 0
    clustersOfWoutsByAct = (clusters, woutsByAct) ->
      return [] unless woutsByAct.length > 0
      locs = _.compact(_.map(woutsByAct, 'startingLocation'))

      locations = clusterize(locs).map(midpoint)
      locations = locs unless locations.length > 0

      locsWithAct = locations.map (loc) ->
        activity: woutsByAct[0].type
        location: loc

      return clusters.concat(locsWithAct)

    clusters = _(wouts)
      .groupBy('type')
      .values()
      .value()
      .reduce(clustersOfWoutsByAct, [])

    UserStat.findOneAndUpdate(
      {user},
      {clusters},
      {upsert: true}).exec()

UserStatSchema.statics.findNeighbors = (userStat) ->
  return Promise.reject(message: 'provide stat object') unless userStat

  {UserStat} = require('./index')

  return Promise.resolve([]) unless userStat.clusters.length > 0
  distanceQuery = $or: userStat.clusters.map (cluster) ->
    user:
      $ne: userStat.user._id
      $nin: userStat.foundNeighbors
    'clusters.activity': cluster.activity
    'clusters.location':
      $geoWithin:
        $centerSphere: [cluster.location, m2r(10000)]

  UserStat.find(distanceQuery)
  .populate('user', '-passwordHash -salt')

UserStatSchema.statics.nearestNeighbor = (user) ->
  {User, UserStat} = require('./index')
  userStat = nearestNeighbor = null

  project = (stat) ->
    _.extend(stat,
      distance: minDistanceBetweenClusters(
        userStat.clusters,
        stat.clusters))

  filter = (stat) ->
    matchingAges(userStat.user, stat.user) &&
    matchingGenders(userStat.user, stat.user)

  UserStat.findOne({user})
  .populate('user', '-passwordHash -salt')
  .then (us) ->
    return Promise.resolve([]) unless us

    userStat = us
    UserStat.findNeighbors(userStat)

  .then (stats) ->
    return Promise.resolve() unless stats.length > 0

    nearestNeighbor = _(stats)
      .filter(filter)
      .map(project)
      .sortBy('distance')
      .last()

    return Promise.resolve() unless nearestNeighbor

    userStat.foundNeighbors.push(nearestNeighbor.user._id)
    userStat.pushQueue.push(nearestNeighbor.user._id)
    userStat.save()

  .then (us) ->
    return Promise.resolve() unless us

    nearestNeighbor.foundNeighbors.push(user)
    nearestNeighbor.pushQueue.push(user)

    nearestNeighbor.save()

  .then ->
    Promise.resolve nearestNeighbor

module.exports = mongoose.model 'UserStat', UserStatSchema
