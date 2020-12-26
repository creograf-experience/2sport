mongoose = require 'mongoose'
Schema = mongoose.Schema
timestamps = require 'mongoose-timestamp'
{ObjectId} = Schema.Types
_ = require 'lodash'

WorkoutSchema = new Schema

  # photo, name, meanSpeed
  user:
    type: ObjectId
    ref: 'User'

  # running, cycling, skiing
  type:
    type: String
    default: 'running'

  # store separately?
  # получаем куски трека в массиве
  track: []
  startingLocation: [Number]
  currentLocation: [Number]

  #stats
  # m/s
  meanSpeed:
    type: Number
    default: 0
  maxSpeed:
    type: Number
    default: 0
  # meters
  distance:
    type: Number
    default: 0
  # ms
  time:
    type: Number
    default: 0

  isActive:
    type: Boolean
    default: true

  startedAt:
    type: Date
    default: Date.now
  finishedAt:
    type: Date

  # platform
  platform:
    type: String
    default: ""
  platformVer:
    type: String

# add createdAt, updatedAt
WorkoutSchema.plugin timestamps

WorkoutSchema.index createdAt: 1
WorkoutSchema.index(currentLocation: '2dsphere')
WorkoutSchema.index(startingLocation: '2dsphere')

WorkoutSchema.virtual('isFaster')
  .set((value) -> @_isFaster = !!value)
  .get(-> @_isFaster)

WorkoutSchema.pre 'save', (next) ->
  return next() if @startingLocation

  @startingLocation ?= @currentLocation
  mongoose.model('UserStat').updateUserStats(@user)

  next()

WorkoutSchema.pre 'save', (next) ->
  mongoose.model('User').updateStats(@user, ->)
  next()

WorkoutSchema.pre 'save', (next) ->
  return next() if @finishedAt || (@isModified('isActive') && !@isActive)

  @finishedAt = Date.now()

  next()

WorkoutSchema.statics.nearMe = (options, next) ->
  {Workout} = require('./index')

  radius = (options.radius || 10000)

  Workout.findOne user: options.userId, isActive: true, (err, ownWorkout) ->
    return next(err) if err
    return next(message: 'no active workout') unless ownWorkout

    Workout
    .find(
      _id: {$ne: ownWorkout._id}
      currentLocation:
        $near:
          $geometry:
            type: 'Point'
            coordinates: ownWorkout.currentLocation
          $maxDistance: radius)
    .select('-track')
    .populate('user', 'name photo dob gender city isVisible meanSpeed')
    .exec (err, workouts) ->
      return next(err) if err

      workouts = workouts.filter (wout) ->
        wout.user && wout.user.isVisible

      workouts.forEach (wout) ->
        wout.isFaster = ownWorkout.meanSpeed < wout.meanSpeed

      next(null, workouts)

WorkoutSchema.statics.cutTrack = (id, start, end) ->
  {Workout} = require('./index')

  Workout.findById(id)
  .then (workout) ->
    workout.track = workout.track.slice(start, end)

    if start > 0
      startingTime = workout.track[0][4]
      startingDistance = workout.track[0][5]
      startingHeight = workout.track[0][6]

      workout.track = workout.track.map (point) ->
        _.extend point.slice(),
          4: point[4] - startingTime
          5: point[5] - startingDistance
          6: point[6] - startingHeight

    workout.time = _.last(workout.track)[7]
    workout.distance = _.last(workout.track)[5]

    speed = _.map(workout.track, 8)
    workout.meanSpeed = _.mean(speed)
    workout.maxSpeed = _.max(speed)

    if _.last(workout.track)[7]
      workout.finishedAt = _.last(workout.track)[7] * 1000

    workout.save()

module.exports = mongoose.model 'Workout', WorkoutSchema
