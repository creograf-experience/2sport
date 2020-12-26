router = require('express').Router()
mongoose = require('mongoose')
User = mongoose.model('User')
{ObjectId} = mongoose.Types
_ = require 'lodash'

Workout = mongoose.model 'Workout'

# GET /api/workouts?page=2
router.get '/', (req, res) ->
  page = req.query.page || 0
  pageSize = 70

  unless req.user
    res.status(404).json(message: 'not found')
  else
    Workout
      .find(user: req.user._id)
      .sort('-finishedAt')
      .skip(page * pageSize)
      .limit(pageSize)
      .exec res.handleData

router.get '/nearme', (req, res) ->
  unless req.user
    res.status(404).json(message: 'not found')
  else
    Workout.nearMe userId: req.user._id, res.handleData

router.get '/:id', (req, res) ->
  Workout.findById req.params.id, res.handleData

router.post '/', (req, res) ->
  Workout.remove(
    user: req.user._id
    $or: [
      {track: {$exists: false}},
      {track: []}
    ])
  .exec (err) ->
    workout = new Workout(req.body)
    workout.user = req.user._id

    workout.save (err, workout) ->
      return res.mongooseError(err) if err

      res.json _.omit workout, ['track']

router.put '/:id', (req, res) ->
  Workout.findById req.params.id, (err, workout) ->
    return res.mongooseError(err) if err
    return res.status(404).end() unless workout

    _.extend workout, _.clone(req.body)

    workout.save (err) ->
      return res.mongooseError(err) if err

      unless req.body.currentLocation
        return res.json []

      Workout.nearMe userId: req.user._id, res.handleData

router.delete '/:id', (req, res) ->
  Workout.remove _id: req.params.id, res.handleData

router.put '/:id/finish', (req, res) ->
  Workout.findById req.params.id, (err, workout) ->
    return res.mongooseError(err) if err

    _.extend workout, _.clone(req.body)

    workout.save (err, updatedWorkout) ->
      User.updateStats new ObjectId(req.user._id), (err, n) ->
        return res.mongooseError(err) if err

        res.json updatedWorkout

router.post '/:id/cuttrack', (req, res) ->
  if _.isUndefined(req.body.start) || _.isUndefined(req.body.end)
    message = 'provide start & end of the range'
    return res.status(400).json(message: message)

  Workout.cutTrack(req.params.id, req.body.start, req.body.end)
  .then((workout) -> res.json(workout))
  .catch(res.mongooseError)

router.delete '/:id', (req, res) ->
  Workout.update(
    {_id: req.params._id},
    {isVisible: false},
    res.handleData)

module.exports = router
